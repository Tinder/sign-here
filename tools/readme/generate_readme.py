#!/usr/bin/env python3
"""Generate README.md from README.template.md using live CLI output and repo metadata."""

from __future__ import annotations

import argparse
import html
import json
import os
import re
import shutil
import subprocess
import sys
import time
from collections import defaultdict
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

REPO_SLUG = "Tinder/sign-here"


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

# ---------------------------------------------------------------------------
# Contributors (ported from Tinder/bazel-diff tools/generate_readme.py)
#
# `git log` is the source of truth so every committer appears, including people
# whose commits were squashed or who pushed from several emails. Emails are
# resolved to GitHub logins via the commits API (for avatars and profile links),
# falling back to parsing `<id>+<login>@users.noreply.github.com` addresses.
# ---------------------------------------------------------------------------

CONTRIBUTOR_COLUMNS = 6


def _github_headers() -> dict[str, str]:
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "sign-here-readme-generator",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return headers


def _is_bot_account(name: str = "", login: str = "", account_type: str = "") -> bool:
    """Return True for GitHub Apps / Actions bots that should not appear as contributors."""
    if account_type == "Bot":
        return True
    # GitHub bot logins and commit author names conventionally end with "[bot]".
    return any(value.lower().endswith("[bot]") for value in (name, login))


def _resolve_noreply_username(email: str) -> str | None:
    """Extract a GitHub login from a noreply address as a last-resort fallback."""
    if not email.endswith("@users.noreply.github.com"):
        return None
    local = email.split("@", 1)[0]
    # Strip the leading numeric id: "12345+username" -> "username".
    return local.split("+")[-1] or None


def _fetch_github_email_map(repo: str = REPO_SLUG) -> dict[str, dict[str, str]]:
    """Page through the GitHub commits API and return email -> {login, avatar_url}."""
    email_map: dict[str, dict[str, str]] = {}
    page = 1
    while True:
        url = f"https://api.github.com/repos/{repo}/commits?per_page=100&page={page}"
        req = Request(url, headers=_github_headers())
        try:
            with urlopen(req, timeout=30) as resp:
                commits = json.loads(resp.read().decode("utf-8"))
        except (HTTPError, URLError, TimeoutError, OSError, json.JSONDecodeError) as exc:
            print(f"warning: GitHub commits API error on page {page}: {exc}", file=sys.stderr)
            break
        if not isinstance(commits, list):
            break

        for commit in commits:
            gh_author = commit.get("author") or {}
            email = ((commit.get("commit") or {}).get("author") or {}).get("email", "")
            login = gh_author.get("login")
            if not (login and email) or email in email_map:
                continue
            if _is_bot_account(login=login, account_type=gh_author.get("type", "")):
                continue
            email_map[email] = {"login": login, "avatar_url": gh_author.get("avatar_url", "")}

        if len(commits) < 100:
            break
        page += 1
        time.sleep(0.1)

    return email_map


def _git_author_log(root: Path) -> str:
    r = subprocess.run(
        ["git", "-C", str(root), "log", "--format=%aN\t%aE"],
        check=True,
        capture_output=True,
        text=True,
    )
    return r.stdout


def _roll_up_authors(log_text: str) -> list[tuple[str, str, int]]:
    """Aggregate `name<TAB>email` lines into (name, best_email, total_commits).

    Commits are rolled up by author name; the email with the most commits for
    that name is kept for GitHub resolution. Sorted by total commits, descending,
    then by name for a stable layout.
    """
    pair_counts: dict[tuple[str, str], int] = defaultdict(int)
    for line in log_text.splitlines():
        if "\t" not in line:
            continue
        name, email = (part.strip() for part in line.split("\t", 1))
        if name and not _is_bot_account(name=name):
            pair_counts[(name, email)] += 1

    totals: dict[str, int] = defaultdict(int)
    best_email: dict[str, str] = {}
    best_count: dict[str, int] = defaultdict(int)
    for (name, email), count in pair_counts.items():
        totals[name] += count
        if count > best_count[name]:
            best_count[name] = count
            best_email[name] = email

    ordered = sorted(totals.items(), key=lambda kv: (-kv[1], kv[0]))
    return [(name, best_email[name], total) for name, total in ordered]


def _build_contributors_table(
    authors: list[tuple[str, str, int]],
    email_map: dict[str, dict[str, str]],
    columns: int = CONTRIBUTOR_COLUMNS,
) -> str:
    cells: list[str] = []
    for name, email, _total in authors:
        user = email_map.get(email)
        if not user:
            login = _resolve_noreply_username(email)
            if login and not _is_bot_account(login=login):
                user = {"login": login, "avatar_url": f"https://avatars.githubusercontent.com/{login}"}

        safe_name = html.escape(name, quote=True)
        if user:
            login = user["login"]
            if _is_bot_account(name=name, login=login):
                continue
            avatar = (user.get("avatar_url") or f"https://avatars.githubusercontent.com/{login}").split("?", 1)[0]
            cells.append(
                f'<td align="center">'
                f'<a href="https://github.com/{login}">'
                f'<img src="{avatar}?s=64" width="64" alt="{safe_name}"/><br/>'
                f"<sub><b>{safe_name}</b></sub>"
                f"</a></td>"
            )
        else:
            print(f"warning: no GitHub login resolved for {name} <{email}>", file=sys.stderr)
            cells.append(f'<td align="center"><sub><b>{safe_name}</b></sub></td>')

    rows = ["<table>"]
    for i in range(0, len(cells), columns):
        rows.append("  <tr>")
        rows.extend(f"    {cell}" for cell in cells[i : i + columns])
        rows.append("  </tr>")
    rows.append("</table>")
    return "\n".join(rows)


def _contributors_section(root: Path, *, offline: bool) -> str:
    authors = _roll_up_authors(_git_author_log(root))
    email_map = {} if offline else _fetch_github_email_map()
    if offline:
        print("warning: --offline set; avatars only for noreply.github.com authors", file=sys.stderr)
    table = _build_contributors_table(authors, email_map)
    return "\n".join(
        [
            "## Contributors",
            "",
            "Thanks to everyone who has contributed:",
            "",
            table,
            "",
        ]
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--offline",
        action="store_true",
        help="Skip the GitHub API; contributors still come from git log (avatars only via noreply emails).",
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

    contributors_section = _contributors_section(root, offline=args.offline)

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
