#!/usr/bin/env python3
"""Unit tests for ``check_coverage``."""

from __future__ import annotations

import io
import json
import os
import sys
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_coverage as cc


SAMPLE_LCOV = """\
SF:/workspace/Sources/SignHereLibrary/Commands/Foo.swift
DA:1,1
DA:2,1
DA:3,0
DA:4,2
end_of_record
SF:/workspace/Sources/SignHereLibrary/Commands/Bar.swift
DA:10,0
DA:11,0
DA:12,0
end_of_record
SF:/workspace/Sources/SignHereLibrary/SignHereLibrary_GeneratedMocks.swift
DA:1,0
DA:2,0
end_of_record
SF:/workspace/Tests/SignHereLibraryTests/FooTests.swift
DA:1,1
end_of_record
"""


class ParseLcovTests(unittest.TestCase):
    def test_parses_per_file_line_counts(self):
        files = cc.parse_lcov(SAMPLE_LCOV)
        foo = files["/workspace/Sources/SignHereLibrary/Commands/Foo.swift"]
        self.assertEqual(foo.lines_found, 4)
        self.assertEqual(foo.lines_hit, 3)
        self.assertAlmostEqual(foo.percent, 75.0)

    def test_handles_empty_input(self):
        self.assertEqual(cc.parse_lcov(""), {})

    def test_skips_malformed_da_records(self):
        text = (
            "SF:/a.swift\n"
            "DA:not-a-number\n"
            "DA:1\n"
            "DA:2,3\n"
            "end_of_record\n"
        )
        files = cc.parse_lcov(text)
        self.assertEqual(files["/a.swift"].lines_found, 1)
        self.assertEqual(files["/a.swift"].lines_hit, 1)

    def test_merges_repeated_records_for_same_file(self):
        text = (
            "SF:/a.swift\nDA:1,0\nDA:2,0\nend_of_record\n"
            "SF:/a.swift\nDA:1,4\nDA:2,0\nDA:3,1\nend_of_record\n"
        )
        files = cc.parse_lcov(text)
        # Line 1 was hit in the second record, so the merged file shows 2/3.
        self.assertEqual(files["/a.swift"].lines_found, 3)
        self.assertEqual(files["/a.swift"].lines_hit, 2)


class NormalizePathsTests(unittest.TestCase):
    def test_strips_workspace_prefix(self):
        files = cc.parse_lcov(SAMPLE_LCOV)
        norm = cc.normalize_paths(files, Path("/workspace"))
        self.assertIn("Sources/SignHereLibrary/Commands/Foo.swift", norm)
        self.assertNotIn(
            "/workspace/Sources/SignHereLibrary/Commands/Foo.swift", norm
        )

    def test_strips_private_workspace_prefix(self):
        text = "SF:/private/tmp/ws/Sources/A.swift\nDA:1,1\nend_of_record\n"
        norm = cc.normalize_paths(cc.parse_lcov(text), Path("/tmp/ws"))
        self.assertIn("Sources/A.swift", norm)

    def test_leaves_unrelated_paths_alone(self):
        text = "SF:/elsewhere/B.swift\nDA:1,1\nend_of_record\n"
        norm = cc.normalize_paths(cc.parse_lcov(text), Path("/workspace"))
        self.assertIn("/elsewhere/B.swift", norm)


class FilterFilesTests(unittest.TestCase):
    def setUp(self):
        files = cc.parse_lcov(SAMPLE_LCOV)
        self.normalized = cc.normalize_paths(files, Path("/workspace"))

    def test_include_keeps_only_matching_paths(self):
        result = cc.filter_files(
            self.normalized,
            includes=[r"^Sources/SignHereLibrary/"],
            excludes=[],
        )
        self.assertNotIn("Tests/SignHereLibraryTests/FooTests.swift", result)
        self.assertIn(
            "Sources/SignHereLibrary/Commands/Foo.swift", result
        )

    def test_exclude_drops_matching_paths(self):
        result = cc.filter_files(
            self.normalized,
            includes=[r"^Sources/"],
            excludes=[r"_GeneratedMocks\.swift$"],
        )
        self.assertNotIn(
            "Sources/SignHereLibrary/SignHereLibrary_GeneratedMocks.swift",
            result,
        )

    def test_empty_includes_keeps_everything_not_excluded(self):
        result = cc.filter_files(self.normalized, includes=[], excludes=[])
        self.assertEqual(len(result), 4)


class AggregateTests(unittest.TestCase):
    def test_returns_full_when_no_files(self):
        found, hit, pct = cc.aggregate([])
        self.assertEqual((found, hit, pct), (0, 0, 100.0))

    def test_sums_across_files(self):
        files = [
            cc.FileCoverage("a", lines_found=10, lines_hit=8),
            cc.FileCoverage("b", lines_found=10, lines_hit=4),
        ]
        found, hit, pct = cc.aggregate(files)
        self.assertEqual((found, hit, pct), (20, 12, 60.0))


class EvaluateTests(unittest.TestCase):
    def test_filters_and_aggregates(self):
        files, found, hit, pct = cc.evaluate(
            SAMPLE_LCOV,
            workspace=Path("/workspace"),
            includes=[r"^Sources/SignHereLibrary/"],
            excludes=[r"_GeneratedMocks\.swift$"],
        )
        self.assertEqual(found, 7)  # 4 + 3
        self.assertEqual(hit, 3)
        self.assertAlmostEqual(pct, 300.0 / 7)
        self.assertIn(
            "Sources/SignHereLibrary/Commands/Bar.swift", files
        )


class ReportFormattingTests(unittest.TestCase):
    def setUp(self):
        self.files = {
            "Sources/A.swift": cc.FileCoverage(
                "Sources/A.swift", lines_found=10, lines_hit=10
            ),
            "Sources/B.swift": cc.FileCoverage(
                "Sources/B.swift", lines_found=10, lines_hit=4
            ),
        }

    def test_text_report_sorts_worst_first_and_shows_status(self):
        report = cc.format_text_report(
            self.files, threshold=90.0, overall_pct=70.0,
            overall_found=20, overall_hit=14,
        )
        b_pos = report.index("Sources/B.swift")
        a_pos = report.index("Sources/A.swift")
        self.assertLess(b_pos, a_pos)
        self.assertIn("FAIL", report)
        self.assertIn("70.00%", report)

    def test_text_report_pass_when_at_threshold(self):
        report = cc.format_text_report(
            self.files, threshold=70.0, overall_pct=70.0,
            overall_found=20, overall_hit=14,
        )
        self.assertIn("PASS", report)

    def test_text_report_handles_no_files(self):
        report = cc.format_text_report(
            {}, threshold=90.0, overall_pct=100.0,
            overall_found=0, overall_hit=0,
        )
        self.assertIn("No files matched", report)

    def test_json_report_is_valid_and_contains_overall(self):
        out = cc.format_json_report(
            self.files, threshold=90.0, overall_pct=70.0,
            overall_found=20, overall_hit=14,
        )
        payload = json.loads(out)
        self.assertEqual(payload["overall"]["lines_hit"], 14)
        self.assertEqual(payload["overall"]["lines_found"], 20)
        self.assertFalse(payload["overall"]["passed"])
        self.assertEqual(len(payload["files"]), 2)


class MainCLITests(unittest.TestCase):
    def _write_lcov(self, tmpdir: Path) -> Path:
        path = tmpdir / "report.dat"
        path.write_text(SAMPLE_LCOV.replace("/workspace", str(tmpdir)))
        return path

    def test_exits_zero_when_threshold_met(self):
        import tempfile
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            lcov = self._write_lcov(tmp)
            stdout, stderr = io.StringIO(), io.StringIO()
            with redirect_stdout(stdout), redirect_stderr(stderr):
                rc = cc.main([
                    "--lcov", str(lcov),
                    "--threshold", "40",
                    "--include", r"^Sources/SignHereLibrary/Commands/Foo\.swift$",
                    "--exclude", r"_GeneratedMocks\.swift$",
                    "--workspace", str(tmp),
                ])
            self.assertEqual(rc, 0, msg=stdout.getvalue() + stderr.getvalue())
            self.assertIn("PASS", stdout.getvalue())

    def test_exits_one_when_below_threshold(self):
        import tempfile
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            lcov = self._write_lcov(tmp)
            stdout, stderr = io.StringIO(), io.StringIO()
            with redirect_stdout(stdout), redirect_stderr(stderr):
                rc = cc.main([
                    "--lcov", str(lcov),
                    "--threshold", "90",
                    "--include", r"^Sources/SignHereLibrary/",
                    "--exclude", r"_GeneratedMocks\.swift$",
                    "--workspace", str(tmp),
                ])
            self.assertEqual(rc, 1)
            self.assertIn("FAIL", stdout.getvalue())

    def test_exits_two_when_filters_match_nothing(self):
        import tempfile
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            lcov = self._write_lcov(tmp)
            stdout, stderr = io.StringIO(), io.StringIO()
            with redirect_stdout(stdout), redirect_stderr(stderr):
                rc = cc.main([
                    "--lcov", str(lcov),
                    "--include", r"^nothing-matches/",
                    "--workspace", str(tmp),
                ])
            self.assertEqual(rc, 2)

    def test_json_output_round_trips(self):
        import tempfile
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            lcov = self._write_lcov(tmp)
            stdout, stderr = io.StringIO(), io.StringIO()
            with redirect_stdout(stdout), redirect_stderr(stderr):
                cc.main([
                    "--lcov", str(lcov),
                    "--threshold", "0",
                    "--include", r"^Sources/SignHereLibrary/",
                    "--exclude", r"_GeneratedMocks\.swift$",
                    "--workspace", str(tmp),
                    "--format", "json",
                ])
            payload = json.loads(stdout.getvalue())
            self.assertTrue(payload["overall"]["passed"])
            self.assertGreater(payload["overall"]["lines_found"], 0)


class BadgeTests(unittest.TestCase):
    def test_color_thresholds(self):
        self.assertEqual(cc.badge_color(100.0), "brightgreen")
        self.assertEqual(cc.badge_color(95.0), "brightgreen")
        self.assertEqual(cc.badge_color(94.99), "green")
        self.assertEqual(cc.badge_color(90.0), "green")
        self.assertEqual(cc.badge_color(89.99), "yellowgreen")
        self.assertEqual(cc.badge_color(80.0), "yellowgreen")
        self.assertEqual(cc.badge_color(79.99), "yellow")
        self.assertEqual(cc.badge_color(70.0), "yellow")
        self.assertEqual(cc.badge_color(69.99), "orange")
        self.assertEqual(cc.badge_color(60.0), "orange")
        self.assertEqual(cc.badge_color(59.99), "red")
        self.assertEqual(cc.badge_color(0.0), "red")

    def test_format_badge_is_valid_shields_endpoint_payload(self):
        payload = json.loads(cc.format_badge(95.14))
        self.assertEqual(payload["schemaVersion"], 1)
        self.assertEqual(payload["label"], "coverage")
        self.assertEqual(payload["message"], "95.14%")
        self.assertEqual(payload["color"], "brightgreen")

    def test_format_badge_respects_label(self):
        payload = json.loads(cc.format_badge(82.3, label="line cov"))
        self.assertEqual(payload["label"], "line cov")

    def test_main_writes_badge_file_when_requested(self):
        import tempfile
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            lcov = tmp / "report.dat"
            lcov.write_text(SAMPLE_LCOV.replace("/workspace", str(tmp)))
            badge = tmp / "out" / "coverage.json"
            stdout, stderr = io.StringIO(), io.StringIO()
            with redirect_stdout(stdout), redirect_stderr(stderr):
                rc = cc.main([
                    "--lcov", str(lcov),
                    "--threshold", "0",
                    "--include", r"^Sources/SignHereLibrary/Commands/Foo\.swift$",
                    "--exclude", r"_GeneratedMocks\.swift$",
                    "--workspace", str(tmp),
                    "--badge-output", str(badge),
                ])
            self.assertEqual(rc, 0)
            self.assertTrue(badge.is_file())
            payload = json.loads(badge.read_text())
            # Foo.swift is 75%, so the color should be yellow.
            self.assertEqual(payload["message"], "75.00%")
            self.assertEqual(payload["color"], "yellow")

    def test_badge_is_written_even_when_threshold_fails(self):
        import tempfile
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            lcov = tmp / "report.dat"
            lcov.write_text(SAMPLE_LCOV.replace("/workspace", str(tmp)))
            badge = tmp / "badge.json"
            stdout, stderr = io.StringIO(), io.StringIO()
            with redirect_stdout(stdout), redirect_stderr(stderr):
                rc = cc.main([
                    "--lcov", str(lcov),
                    "--threshold", "99",
                    "--include", r"^Sources/SignHereLibrary/",
                    "--exclude", r"_GeneratedMocks\.swift$",
                    "--workspace", str(tmp),
                    "--badge-output", str(badge),
                ])
            self.assertEqual(rc, 1)  # failed threshold
            self.assertTrue(badge.is_file())  # but badge still written


class ModeFlagTests(unittest.TestCase):
    def test_lcov_path_takes_precedence_over_mode_collect(self):
        # If --lcov is given, no collection is attempted regardless of mode.
        import tempfile
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            lcov = tmp / "report.dat"
            lcov.write_text(SAMPLE_LCOV.replace("/workspace", str(tmp)))
            stdout, stderr = io.StringIO(), io.StringIO()
            with redirect_stdout(stdout), redirect_stderr(stderr):
                rc = cc.main([
                    "--lcov", str(lcov),
                    "--threshold", "0",
                    "--include", r"^Sources/SignHereLibrary/",
                    "--exclude", r"_GeneratedMocks\.swift$",
                    "--workspace", str(tmp),
                    "--mode", "collect",
                ])
            self.assertEqual(rc, 0)

    def test_collect_mode_rejects_multiple_targets(self):
        stdout, stderr = io.StringIO(), io.StringIO()
        with redirect_stdout(stdout), redirect_stderr(stderr):
            rc = cc.main([
                "--mode", "collect",
                "--target", "//a:b",
                "--target", "//c:d",
                "--workspace", "/tmp",
            ])
        self.assertEqual(rc, 2)
        self.assertIn("exactly one --target", stderr.getvalue())


class WorkspaceRootTests(unittest.TestCase):
    def test_uses_env_var_when_set(self):
        old = os.environ.get("BUILD_WORKSPACE_DIRECTORY")
        os.environ["BUILD_WORKSPACE_DIRECTORY"] = "/tmp/explicit"
        try:
            self.assertEqual(cc.workspace_root(), Path("/tmp/explicit"))
        finally:
            if old is None:
                del os.environ["BUILD_WORKSPACE_DIRECTORY"]
            else:
                os.environ["BUILD_WORKSPACE_DIRECTORY"] = old

    def test_walks_up_for_module_file(self):
        import tempfile
        old = os.environ.pop("BUILD_WORKSPACE_DIRECTORY", None)
        try:
            with tempfile.TemporaryDirectory() as raw:
                root = Path(raw).resolve()
                (root / "MODULE.bazel").write_text("module(name='x')")
                nested = root / "a" / "b"
                nested.mkdir(parents=True)
                self.assertEqual(cc.workspace_root(nested), root)
        finally:
            if old is not None:
                os.environ["BUILD_WORKSPACE_DIRECTORY"] = old


if __name__ == "__main__":
    unittest.main()
