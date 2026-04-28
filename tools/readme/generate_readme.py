#!/usr/bin/env python3
"""Generate README.md from README.template.md using live CLI output and repo metadata."""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

REPO_SLUG = "Tinder/sign-here"
GITHUB_API = f"https://api.github.com/repos/{REPO_SLUG}/contributors"


def _workspace_root() -> Path:
    env = os.environ.get("BUILD_WORKSPACE_DIRECTORY")
    if env:
        return Path(env).resolve()
    cwd = Path.cwd().resolve()
    for p in [cwd, *cwd.parents]:
        if (p / "MODULE.bazel").is_file():
            return p
    return cwd


def _read_module_version(module_bazel: Path) -> str:
    text = module_bazel.read_text(encoding="utf-8")
    for line in text.splitlines():
        m = re.match(r'\s*version\s*=\s*"([^"]+)"\s*,?\s*$', line)
        if m:
            return m.group(1)
    raise ValueError("Could not parse module version from MODULE.bazel")


def _parse_bazel_dep_versions(module_bazel: Path) -> list[tuple[str, str]]:
    text = module_bazel.read_text(encoding="utf-8")
    out: list[tuple[str, str]] = []
    for m in re.finditer(
        r'bazel_dep\(\s*name\s*=\s*"([^"]+)"\s*,\s*version\s*=\s*"([^"]+)"',
        text,
    ):
        out.append((m.group(1), m.group(2)))
    return out


def _run_capture(argv: list[str]) -> str:
    r = subprocess.run(argv, check=True, capture_output=True, text=True)
    return r.stdout.rstrip() + ("\n" if r.stdout and not r.stdout.endswith("\n") else "")


def _which_bazel() -> str:
    """Prefer bazelisk so we do not invoke a broken `bazel` shim that shells out to workspace tooling."""
    override = os.environ.get("SIGN_HERE_BAZEL") or os.environ.get("BAZELISK_BIN")
    if override:
        return override

    extra_dirs = [
        Path.home() / "go/bin",
        Path("/opt/homebrew/bin"),
        Path("/usr/local/bin"),
    ]
    path_dirs = [p for p in os.environ.get("PATH", "").split(os.pathsep) if p]
    path_dirs = list(dict.fromkeys([*(str(d) for d in extra_dirs if d.is_dir()), *path_dirs]))

    def probe(names: tuple[str, ...]) -> str | None:
        for name in names:
            for d in path_dirs:
                candidate = Path(d) / name
                if candidate.is_file() and os.access(candidate, os.X_OK):
                    return str(candidate)
        return None

    found = probe(("bazelisk", "bazel"))
    if found:
        return found
    w = shutil.which("bazelisk") or shutil.which("bazel")
    return w or "bazelisk"


def _help_block(sign_here: Path, *subcommand: str) -> str:
    cmd = [str(sign_here), *subcommand, "--help"]
    inner = _run_capture(cmd).rstrip("\n")
    cmd_line = " ".join(["sign-here", *subcommand, "--help"])
    return f"{cmd_line}\n\n{inner}\n"


def _prerequisites_lines() -> str:
    bazel_bin = _which_bazel()
    try:
        ver_out = _run_capture([bazel_bin, "version"])
        label = None
        for line in ver_out.splitlines():
            if "Build label:" in line:
                label = line.split("Build label:", 1)[1].strip()
                break
        tool = Path(bazel_bin).name
        if label:
            bazel_line = f"* Bazel (tested with release `{label}` using `{tool}` on this machine)"
        else:
            first = ver_out.splitlines()[0].strip() if ver_out else "unknown"
            bazel_line = f"* Bazel (tested with `{first}` via `{tool}`)"
    except (subprocess.CalledProcessError, FileNotFoundError, IndexError):
        bazel_line = "* Bazel (see https://bazel.build/install)"

    try:
        ssl = _run_capture(["openssl", "version"]).strip()
        openssl_line = f"* OpenSSL (this machine: `{ssl}`)"
    except (subprocess.CalledProcessError, FileNotFoundError):
        openssl_line = "* OpenSSL (required for certificate operations)"

    deps = _parse_bazel_dep_versions(_workspace_root() / "MODULE.bazel")
    dep_bits = [f"`{n}` {v}" for n, v in deps]
    deps_line = "* Key Bazel module pins: " + ", ".join(dep_bits) if dep_bits else ""

    lines = [bazel_line, openssl_line]
    if deps_line:
        lines.append(deps_line)
    return "\n".join(lines)


def _bzlmod_section(version: str) -> str:
    return f"""Add to your `MODULE.bazel`:

```starlark
bazel_dep(name = "sign-here", version = "{version}")
```

The module is listed in the [Bazel Central Registry](https://registry.bazel.build/modules/sign-here). Then run:

```terminal
bazel mod tidy
```
"""


def _workspace_section(version: str) -> str:
    tag = f"v{version}"
    return f"""If you still use a `WORKSPACE` file, pin the tagged release (Git tags use `v*`):

```starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

_TAG = "{tag}"
http_archive(
    name = "com_github_tinder_sign_here",
    url = "https://github.com/{REPO_SLUG}/archive/refs/tags/%s.tar.gz" % _TAG,
    strip_prefix = "sign-here-%s" % _TAG,
)

load("@com_github_tinder_sign_here//:repositories.bzl", "sign_here_dependencies")

sign_here_dependencies()
```

Use the `sha256` / `integrity` values printed by [.github/workflows/release_prep.sh](.github/workflows/release_prep.sh) for the matching Git tag when cutting from an `http_archive` instead of git."""

def _fetch_contributors() -> str | None:
    req = Request(
        f"{GITHUB_API}?per_page=100",
        headers={
            "Accept": "application/vnd.github+json",
            "User-Agent": "sign-here-readme-generator",
            "X-GitHub-Api-Version": "2022-11-28",
        },
    )
    try:
        with urlopen(req, timeout=30) as resp:
            body = resp.read().decode("utf-8")
    except (HTTPError, URLError, TimeoutError, OSError):
        return None

    try:
        data = json.loads(body)
    except json.JSONDecodeError:
        return None

    if not isinstance(data, list) or not data:
        return None

    lines = [
        "## Contributors",
        "",
        "Thanks to everyone who has contributed:",
        "",
        '<p align="left">',
    ]
    for row in sorted(data, key=lambda x: (-int(x.get("contributions", 0)), x.get("login", ""))):
        login = row.get("login")
        if not login:
            continue
        avatar = row.get("avatar_url") or ""
        # Fixed size avatars for stable layout in Markdown renderers.
        img = f"{avatar.split('?', 1)[0]}?s=64&v=4" if avatar else ""
        lines.append(
            f'  <a href="https://github.com/{login}">'
            f'<img src="{img}" width="40" height="40" alt="@{login}" title="@{login}"></a>'
        )
    lines.append("</p>")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--offline",
        action="store_true",
        help="Skip GitHub contributors (no network).",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=None,
        help="Write README here (default: <workspace>/README.md).",
    )
    args = parser.parse_args()

    root = _workspace_root()
    os.chdir(root)

    module_path = root / "MODULE.bazel"
    version = _read_module_version(module_path)

    sign_here = root / "bazel-bin/Sources/SignHereTool/sign-here"
    if not sign_here.is_file():
        bazel = _which_bazel()
        subprocess.run([bazel, "build", "//Sources/SignHereTool:sign-here"], check=True)
    if not sign_here.is_file():
        print(f"error: missing binary at {sign_here}", file=sys.stderr)
        return 1

    template_path = root / "tools/readme/README.template.md"
    template = template_path.read_text(encoding="utf-8")

    contributors = "" if args.offline else _fetch_contributors()
    contributors_section = ""
    if contributors:
        contributors_section = contributors
    else:
        contributors_section = (
            "## Contributors\n\n"
            "_Contributor avatars are inserted when you regenerate with network access "
            "(`bazel run //:generate_readme`). Use `--offline` to skip._\n"
        )

    subs = {
        "PREREQUISITES": _prerequisites_lines(),
        "HELP_CREATE_KEYCHAIN": _help_block(sign_here, "create-keychain"),
        "HELP_DELETE_KEYCHAIN": _help_block(sign_here, "delete-keychain"),
        "HELP_CREATE_PROVISIONING_PROFILE": _help_block(sign_here, "create-provisioning-profile"),
        "HELP_DELETE_PROVISIONING_PROFILE": _help_block(sign_here, "delete-provisioning-profile"),
        "MODULE_VERSION": version,
        "BZLMODO_SECTION": _bzlmod_section(version),
        "WORKSPACE_SECTION": _workspace_section(version),
        "CONTRIBUTORS_SECTION": contributors_section,
    }

    out = template
    for key, val in subs.items():
        out = out.replace("{{" + key + "}}", val)

    if "{{" in out:
        print("error: unreplaced placeholders remain in template output", file=sys.stderr)
        return 1

    out_path = args.output or (root / "README.md")
    out_path.write_text(out, encoding="utf-8")
    print(f"Wrote {out_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
