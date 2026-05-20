#!/usr/bin/env python3
"""Enforce a minimum line-coverage threshold for sign-here Swift sources.

Reads an LCOV report (running ``bazel coverage`` first when one is not
supplied), filters it to the source roots of interest, and prints a
per-file table sorted worst-first. Exits with a non-zero status if the
overall line coverage is below the configured threshold.

Typical use::

    tools/coverage/check_coverage.py --threshold 90

In CI the LCOV report is produced by ``bazel coverage --combined_report=lcov
//Tests/...`` and lives at ``bazel-out/_coverage/_coverage_report.dat``.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable


DEFAULT_THRESHOLD = 90.0
DEFAULT_TARGETS = ("//Tests/SignHereLibraryTests:SignHereUnitTests",)
DEFAULT_INCLUDE = (
    r"^Sources/SignHereLibrary/",
    r"^Sources/CoreLibrary/",
    r"^Sources/SignHereTool/",
)
DEFAULT_EXCLUDE = (
    r"_GeneratedMocks\.swift$",
    r"/__Snapshots__/",
)
LCOV_REPORT_RELATIVE = Path("bazel-out") / "_coverage" / "_coverage_report.dat"


@dataclass
class FileCoverage:
    """Line coverage for a single source file."""

    path: str
    lines_found: int = 0
    lines_hit: int = 0

    @property
    def percent(self) -> float:
        if self.lines_found == 0:
            return 100.0
        return 100.0 * self.lines_hit / self.lines_found

    @property
    def missed(self) -> int:
        return self.lines_found - self.lines_hit


def parse_lcov(text: str) -> dict[str, FileCoverage]:
    """Parse an LCOV-format string into a {path: FileCoverage} mapping.

    Multiple records for the same file (which happens when several test
    binaries cover the same source) are merged — a line is considered hit if
    *any* record reports a non-zero hit count for it.
    """
    line_hits: dict[str, dict[int, int]] = {}
    current: str | None = None
    for raw in text.splitlines():
        line = raw.strip()
        if line.startswith("SF:"):
            current = line[3:]
            line_hits.setdefault(current, {})
        elif line == "end_of_record":
            current = None
        elif line.startswith("DA:") and current is not None:
            payload = line[3:].split(",")
            if len(payload) < 2:
                continue
            try:
                ln = int(payload[0])
                hits = int(payload[1])
            except ValueError:
                continue
            prev = line_hits[current].get(ln, 0)
            line_hits[current][ln] = prev + hits

    files: dict[str, FileCoverage] = {}
    for path, hits in line_hits.items():
        cov = FileCoverage(path=path)
        cov.lines_found = len(hits)
        cov.lines_hit = sum(1 for h in hits.values() if h > 0)
        files[path] = cov
    return files


def _workspace_prefix_candidates(workspace_root: Path) -> list[str]:
    """Return every workspace-root prefix we should try to strip.

    Bazel may emit absolute paths anchored at the workspace root, at its
    resolved (symlinks-followed) form, or at the ``/private``-aliased form
    that macOS uses for ``/tmp``. We try all of them so the reported paths
    are stable regardless of how the tool was invoked.
    """
    candidates: set[str] = set()
    raw = str(workspace_root).rstrip("/") + "/"
    candidates.add(raw)
    try:
        resolved = str(workspace_root.resolve()).rstrip("/") + "/"
    except OSError:
        resolved = raw
    candidates.add(resolved)
    for c in list(candidates):
        if c.startswith("/private/"):
            candidates.add(c[len("/private"):])
        else:
            candidates.add("/private" + c)
    # Longest first so we don't match a parent prefix when a deeper one applies.
    return sorted(candidates, key=len, reverse=True)


def normalize_paths(
    files: dict[str, FileCoverage], workspace_root: Path
) -> dict[str, FileCoverage]:
    """Strip the workspace prefix from absolute paths so reports are stable.

    LCOV emitters in Bazel sometimes write absolute paths, sometimes paths
    relative to the workspace, and sometimes paths anchored at ``bazel-out``.
    We collapse everything to a path relative to the workspace root when
    possible.
    """
    prefixes = _workspace_prefix_candidates(workspace_root)
    out: dict[str, FileCoverage] = {}
    for path, cov in files.items():
        new_path = path
        for prefix in prefixes:
            if new_path.startswith(prefix):
                new_path = new_path[len(prefix):]
                break
        cov.path = new_path
        existing = out.get(new_path)
        if existing is None:
            out[new_path] = cov
        else:
            existing.lines_found = max(existing.lines_found, cov.lines_found)
            existing.lines_hit = max(existing.lines_hit, cov.lines_hit)
    return out


def filter_files(
    files: dict[str, FileCoverage],
    includes: Iterable[str],
    excludes: Iterable[str],
) -> dict[str, FileCoverage]:
    include_res = [re.compile(p) for p in includes]
    exclude_res = [re.compile(p) for p in excludes]
    selected: dict[str, FileCoverage] = {}
    for path, cov in files.items():
        if include_res and not any(r.search(path) for r in include_res):
            continue
        if any(r.search(path) for r in exclude_res):
            continue
        selected[path] = cov
    return selected


def aggregate(files: Iterable[FileCoverage]) -> tuple[int, int, float]:
    found = sum(f.lines_found for f in files)
    hit = sum(f.lines_hit for f in files)
    pct = 100.0 if found == 0 else 100.0 * hit / found
    return found, hit, pct


def format_text_report(
    files: dict[str, FileCoverage],
    threshold: float,
    overall_pct: float,
    overall_found: int,
    overall_hit: int,
) -> str:
    """Render a human-readable per-file coverage report, sorted worst first."""
    rows = sorted(files.values(), key=lambda f: (f.percent, -f.missed, f.path))
    if not rows:
        return "No files matched the include/exclude filters.\n"
    path_w = max(len("File"), max(len(r.path) for r in rows))
    header = f"{'File':<{path_w}}  {'Cov%':>7}  {'Hit':>6}  {'Total':>6}  {'Miss':>6}"
    sep = "-" * len(header)
    lines = [header, sep]
    for r in rows:
        lines.append(
            f"{r.path:<{path_w}}  {r.percent:>6.2f}%  "
            f"{r.lines_hit:>6d}  {r.lines_found:>6d}  {r.missed:>6d}"
        )
    lines.append(sep)
    status = "PASS" if overall_pct + 1e-9 >= threshold else "FAIL"
    lines.append(
        f"TOTAL: {overall_pct:.2f}% ({overall_hit}/{overall_found}) "
        f"threshold={threshold:.2f}% -> {status}"
    )
    return "\n".join(lines) + "\n"


def badge_color(percent: float) -> str:
    """Map a coverage percentage to a shields.io color name.

    Mirrors the common scheme used by codecov/shields presets so the colors
    feel familiar to anyone glancing at the README badge.
    """
    if percent >= 95:
        return "brightgreen"
    if percent >= 90:
        return "green"
    if percent >= 80:
        return "yellowgreen"
    if percent >= 70:
        return "yellow"
    if percent >= 60:
        return "orange"
    return "red"


def format_badge(percent: float, label: str = "coverage") -> str:
    """Render a shields.io endpoint-format badge JSON document."""
    payload = {
        "schemaVersion": 1,
        "label": label,
        "message": f"{percent:.2f}%",
        "color": badge_color(percent),
    }
    return json.dumps(payload, indent=2) + "\n"


def format_json_report(
    files: dict[str, FileCoverage],
    threshold: float,
    overall_pct: float,
    overall_found: int,
    overall_hit: int,
) -> str:
    payload = {
        "threshold": threshold,
        "overall": {
            "percent": overall_pct,
            "lines_hit": overall_hit,
            "lines_found": overall_found,
            "passed": overall_pct + 1e-9 >= threshold,
        },
        "files": [
            {
                "path": f.path,
                "percent": f.percent,
                "lines_hit": f.lines_hit,
                "lines_found": f.lines_found,
            }
            for f in sorted(files.values(), key=lambda f: f.path)
        ],
    }
    return json.dumps(payload, indent=2) + "\n"


def workspace_root(start: Path | None = None) -> Path:
    env = os.environ.get("BUILD_WORKSPACE_DIRECTORY")
    if env:
        return Path(env)
    cwd = (start or Path.cwd()).resolve()
    for p in [cwd, *cwd.parents]:
        if (p / "MODULE.bazel").is_file() or (p / "WORKSPACE").is_file():
            return p
    return cwd


def run_bazel_coverage(
    workspace: Path,
    targets: Iterable[str],
    bazel: str,
    extra_args: Iterable[str],
) -> Path:
    """Invoke ``bazel coverage`` and return the path to the combined LCOV file."""
    cmd = [bazel, "coverage", "--combined_report=lcov", *extra_args, *targets]
    print(f"[coverage] {' '.join(cmd)}", file=sys.stderr)
    proc = subprocess.run(cmd, cwd=workspace)
    if proc.returncode != 0:
        raise SystemExit(
            f"bazel coverage failed with exit code {proc.returncode}"
        )
    report = workspace / LCOV_REPORT_RELATIVE
    if not report.is_file():
        raise SystemExit(
            f"bazel finished but combined LCOV report not found at {report}"
        )
    return report


def _xcrun(args: Iterable[str], **kwargs) -> subprocess.CompletedProcess:
    return subprocess.run(["xcrun", *args], check=True, **kwargs)


def collect_swift_coverage(
    workspace: Path,
    target: str,
    bazel: str,
    extra_args: Iterable[str],
) -> Path:
    """Build a swift_test under coverage, run it, and produce an LCOV file.

    Bazel's stock coverage merger writes a zero-byte ``coverage.dat`` for
    rules_swift ``swift_test`` targets on macOS — the test binary is
    correctly instrumented, but the test wrapper does not capture the
    resulting ``.profraw`` files. We work around it by building under
    ``bazel coverage``, running the resulting xctest binary directly with
    ``LLVM_PROFILE_FILE`` set, then converting with llvm-profdata + llvm-cov.

    Returns the path to the generated LCOV file.
    """
    print(
        f"[coverage] bazel coverage --combined_report=lcov "
        f"--instrumentation_filter=//Sources/... --instrument_test_targets "
        f"--nocache_test_results {target}",
        file=sys.stderr,
    )
    proc = subprocess.run(
        [
            bazel,
            "coverage",
            "--combined_report=lcov",
            "--instrumentation_filter=//Sources/...",
            "--instrument_test_targets",
            "--nocache_test_results",
            *extra_args,
            target,
        ],
        cwd=workspace,
    )
    if proc.returncode != 0:
        raise SystemExit(
            f"`bazel coverage` failed with exit code {proc.returncode}"
        )

    binary_relpath = subprocess.check_output(
        [bazel, "cquery", "--output=files", target],
        cwd=workspace,
        text=True,
    ).strip()
    if not binary_relpath:
        raise SystemExit(f"bazel cquery returned no files for {target}")
    binary = workspace / binary_relpath
    if not binary.is_file():
        raise SystemExit(f"test binary not found at {binary}")

    runfiles = binary.with_suffix(binary.suffix + ".runfiles")
    main_runfiles = runfiles / "_main"
    if not main_runfiles.is_dir():
        # rules_swift older layouts use the workspace name; fall back to first dir.
        candidates = [p for p in runfiles.iterdir() if p.is_dir()]
        if not candidates:
            raise SystemExit(f"no runfiles directories under {runfiles}")
        main_runfiles = candidates[0]

    developer_dir = subprocess.check_output(
        ["xcode-select", "-p"], text=True
    ).strip()
    sdkroot = subprocess.check_output(
        ["xcrun", "--sdk", "macosx", "--show-sdk-path"], text=True
    ).strip()
    platform_dev = Path(developer_dir) / "Platforms" / "MacOSX.platform" / "Developer"
    framework_path = platform_dev / "Library" / "Frameworks"
    library_path = platform_dev / "usr" / "lib"

    profile_dir = workspace / "bazel-out" / "_sign_here_coverage"
    profile_dir.mkdir(parents=True, exist_ok=True)
    for old in profile_dir.glob("*.profraw"):
        old.unlink()
    profile_pattern = profile_dir / "cov_%m.profraw"
    profdata = profile_dir / "coverage.profdata"
    lcov_path = profile_dir / "coverage.lcov"

    env = os.environ.copy()
    env.update({
        "DEVELOPER_DIR": developer_dir,
        "SDKROOT": sdkroot,
        "DYLD_FRAMEWORK_PATH": str(framework_path),
        "DYLD_LIBRARY_PATH": str(library_path),
        "LLVM_PROFILE_FILE": str(profile_pattern),
        "RUNFILES_DIR": str(runfiles),
    })

    print(f"[coverage] running {binary} (cwd={main_runfiles})", file=sys.stderr)
    proc = subprocess.run([str(binary)], cwd=main_runfiles, env=env)
    if proc.returncode != 0:
        raise SystemExit(
            f"test binary exited with status {proc.returncode}; refusing to "
            "report coverage on a failing test run"
        )

    profraws = sorted(profile_dir.glob("*.profraw"))
    if not profraws:
        raise SystemExit(
            f"no .profraw files produced under {profile_dir}; was the binary "
            "compiled with coverage instrumentation?"
        )

    print(
        f"[coverage] merging {len(profraws)} profraw(s) into {profdata}",
        file=sys.stderr,
    )
    _xcrun(
        [
            "llvm-profdata",
            "merge",
            "-sparse",
            *(str(p) for p in profraws),
            "-o",
            str(profdata),
        ]
    )

    print(f"[coverage] exporting LCOV to {lcov_path}", file=sys.stderr)
    with lcov_path.open("wb") as out:
        subprocess.run(
            [
                "xcrun",
                "llvm-cov",
                "export",
                "-format=lcov",
                f"-instr-profile={profdata}",
                str(binary),
            ],
            check=True,
            stdout=out,
        )
    return lcov_path


def evaluate(
    lcov_text: str,
    workspace: Path,
    includes: Iterable[str],
    excludes: Iterable[str],
) -> tuple[dict[str, FileCoverage], int, int, float]:
    parsed = parse_lcov(lcov_text)
    normalized = normalize_paths(parsed, workspace)
    filtered = filter_files(normalized, includes, excludes)
    found, hit, pct = aggregate(filtered.values())
    return filtered, found, hit, pct


def build_arg_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description="Enforce a minimum Swift line-coverage threshold.",
    )
    p.add_argument(
        "--threshold",
        type=float,
        default=DEFAULT_THRESHOLD,
        help=f"Required overall line-coverage percentage (default: {DEFAULT_THRESHOLD}).",
    )
    p.add_argument(
        "--lcov",
        type=Path,
        default=None,
        help="Path to a pre-existing LCOV report. If omitted, `bazel coverage` is invoked.",
    )
    p.add_argument(
        "--target",
        dest="targets",
        action="append",
        default=None,
        help=f"Bazel target(s) to cover (repeatable). Default: {' '.join(DEFAULT_TARGETS)}.",
    )
    p.add_argument(
        "--mode",
        choices=("collect", "bazel-only", "lcov"),
        default="collect",
        help=(
            "How to obtain the LCOV report. "
            "`collect` (default) runs `bazel coverage` then drives xctest + "
            "llvm-cov directly to work around the rules_swift macOS coverage "
            "gap. `bazel-only` trusts bazel's combined report (fine on Linux "
            "but produces empty data for swift_test on macOS). `lcov` skips "
            "collection and reads --lcov."
        ),
    )
    p.add_argument(
        "--include",
        dest="includes",
        action="append",
        default=None,
        help="Regex of source paths to include (repeatable).",
    )
    p.add_argument(
        "--exclude",
        dest="excludes",
        action="append",
        default=None,
        help="Regex of source paths to exclude (repeatable).",
    )
    p.add_argument(
        "--format",
        choices=("text", "json"),
        default="text",
        help="Report format (default: text).",
    )
    p.add_argument(
        "--bazel",
        default=os.environ.get("BAZEL", "bazel"),
        help="Bazel executable to use (default: $BAZEL or `bazel`).",
    )
    p.add_argument(
        "--bazel-arg",
        dest="bazel_args",
        action="append",
        default=[],
        help="Extra argument forwarded to `bazel coverage` (repeatable).",
    )
    p.add_argument(
        "--workspace",
        type=Path,
        default=None,
        help="Override the workspace root (defaults to BUILD_WORKSPACE_DIRECTORY or auto-detected).",
    )
    p.add_argument(
        "--badge-output",
        type=Path,
        default=None,
        help=(
            "If set, also write a shields.io endpoint-format JSON badge "
            "document to this path (good for CI publishing)."
        ),
    )
    p.add_argument(
        "--badge-label",
        default="coverage",
        help="Label for the badge (default: `coverage`).",
    )
    return p


def main(argv: list[str] | None = None) -> int:
    args = build_arg_parser().parse_args(argv)
    workspace = args.workspace or workspace_root()
    includes = tuple(args.includes) if args.includes else DEFAULT_INCLUDE
    excludes = tuple(args.excludes) if args.excludes else DEFAULT_EXCLUDE
    targets = tuple(args.targets) if args.targets else DEFAULT_TARGETS

    if args.lcov is not None:
        lcov_path = args.lcov
        if not lcov_path.is_absolute():
            lcov_path = (workspace / lcov_path).resolve()
    elif args.mode == "bazel-only":
        lcov_path = run_bazel_coverage(
            workspace, targets, args.bazel, args.bazel_args
        )
    else:  # collect
        if len(targets) != 1:
            print(
                "ERROR: --mode collect requires exactly one --target "
                "(the swift_test binary to run directly).",
                file=sys.stderr,
            )
            return 2
        lcov_path = collect_swift_coverage(
            workspace, targets[0], args.bazel, args.bazel_args
        )

    if not lcov_path.is_file():
        print(f"LCOV report not found: {lcov_path}", file=sys.stderr)
        return 2

    lcov_text = lcov_path.read_text()
    files, found, hit, pct = evaluate(lcov_text, workspace, includes, excludes)

    if args.format == "json":
        sys.stdout.write(format_json_report(files, args.threshold, pct, found, hit))
    else:
        sys.stdout.write(
            format_text_report(files, args.threshold, pct, found, hit)
        )

    if args.badge_output is not None:
        badge_path = args.badge_output
        if not badge_path.is_absolute():
            badge_path = (workspace / badge_path).resolve()
        badge_path.parent.mkdir(parents=True, exist_ok=True)
        badge_path.write_text(format_badge(pct, label=args.badge_label))
        print(f"[coverage] wrote badge JSON to {badge_path}", file=sys.stderr)

    if found == 0:
        print(
            "ERROR: no covered files matched the include/exclude filters.",
            file=sys.stderr,
        )
        return 2
    return 0 if pct + 1e-9 >= args.threshold else 1


if __name__ == "__main__":
    sys.exit(main())
