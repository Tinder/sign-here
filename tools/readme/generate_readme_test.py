#!/usr/bin/env python3
"""Unit tests for the contributor logic in ``generate_readme``."""

from __future__ import annotations

import io
import sys
import unittest
from contextlib import redirect_stderr
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import generate_readme as gr


SAMPLE_LOG = "\n".join(
    [
        "Maxwell Elliott\tmaxwell.elliott@gotinder.com",
        "Maxwell Elliott\t56700854+tinder-maxwellelliott@users.noreply.github.com",
        "Maxwell Elliott\tmaxwell.elliott@gotinder.com",
        "Omar Zúñiga Lagunas\tomarzl@hotmail.es",
        "Omar Zúñiga Lagunas\tomarzl@hotmail.es",
        "dependabot[bot]\t49699333+dependabot[bot]@users.noreply.github.com",
        "Connor Wybranowski\t40372184+tinder-cwybranowski@users.noreply.github.com",
        "Ada <Lovelace> & Co\tada@example.com",
        "malformed line without a tab",
        "",
    ]
)


class BotDetectionTests(unittest.TestCase):
    def test_bot_type_is_bot(self) -> None:
        self.assertTrue(gr._is_bot_account(login="anything", account_type="Bot"))

    def test_bot_suffix_in_login_or_name(self) -> None:
        self.assertTrue(gr._is_bot_account(login="dependabot[bot]"))
        self.assertTrue(gr._is_bot_account(name="github-actions[BOT]"))

    def test_humans_are_not_bots(self) -> None:
        self.assertFalse(gr._is_bot_account(name="Maxwell Elliott", login="tinder-maxwellelliott", account_type="User"))


class NoreplyResolutionTests(unittest.TestCase):
    def test_strips_numeric_id(self) -> None:
        self.assertEqual(
            gr._resolve_noreply_username("56700854+tinder-maxwellelliott@users.noreply.github.com"),
            "tinder-maxwellelliott",
        )

    def test_plain_noreply(self) -> None:
        self.assertEqual(gr._resolve_noreply_username("omarzl@users.noreply.github.com"), "omarzl")

    def test_non_noreply_returns_none(self) -> None:
        self.assertIsNone(gr._resolve_noreply_username("maxwell.elliott@gotinder.com"))


class RollUpTests(unittest.TestCase):
    def test_rolls_up_by_name_and_keeps_best_email(self) -> None:
        authors = gr._roll_up_authors(SAMPLE_LOG)
        names = [name for name, _, _ in authors]
        self.assertEqual(
            names,
            ["Maxwell Elliott", "Omar Zúñiga Lagunas", "Ada <Lovelace> & Co", "Connor Wybranowski"],
        )
        maxwell = next(a for a in authors if a[0] == "Maxwell Elliott")
        self.assertEqual(maxwell, ("Maxwell Elliott", "maxwell.elliott@gotinder.com", 3))

    def test_bots_and_malformed_lines_are_dropped(self) -> None:
        names = [name for name, _, _ in gr._roll_up_authors(SAMPLE_LOG)]
        self.assertNotIn("dependabot[bot]", names)
        self.assertNotIn("malformed line without a tab", names)

    def test_ties_sort_by_name(self) -> None:
        authors = gr._roll_up_authors("Zed\tz@x.com\nAmy\ta@x.com\n")
        self.assertEqual([a[0] for a in authors], ["Amy", "Zed"])


class TableTests(unittest.TestCase):
    def setUp(self) -> None:
        self.authors = gr._roll_up_authors(SAMPLE_LOG)
        self.email_map = {
            "maxwell.elliott@gotinder.com": {
                "login": "tinder-maxwellelliott",
                "avatar_url": "https://avatars.githubusercontent.com/u/56700854?v=4",
            },
            "omarzl@hotmail.es": {
                "login": "omarzl",
                "avatar_url": "https://avatars.githubusercontent.com/u/6267487?v=4",
            },
        }

    def test_resolved_authors_get_avatar_and_link(self) -> None:
        with redirect_stderr(io.StringIO()):
            table = gr._build_contributors_table(self.authors, self.email_map)
        self.assertIn('<a href="https://github.com/tinder-maxwellelliott">', table)
        self.assertIn('src="https://avatars.githubusercontent.com/u/56700854?s=64"', table)
        self.assertIn("<sub><b>Maxwell Elliott</b></sub>", table)

    def test_noreply_fallback_without_api_map(self) -> None:
        with redirect_stderr(io.StringIO()):
            table = gr._build_contributors_table(self.authors, {})
        self.assertIn('<a href="https://github.com/tinder-cwybranowski">', table)
        self.assertIn('src="https://avatars.githubusercontent.com/tinder-cwybranowski?s=64"', table)

    def test_unresolved_author_is_name_only_and_escaped(self) -> None:
        err = io.StringIO()
        with redirect_stderr(err):
            table = gr._build_contributors_table(self.authors, self.email_map)
        self.assertIn('<td align="center"><sub><b>Ada &lt;Lovelace&gt; &amp; Co</b></sub></td>', table)
        self.assertNotIn("Ada <Lovelace>", table)
        self.assertIn("no GitHub login resolved for Ada <Lovelace> & Co", err.getvalue())

    def test_rows_wrap_at_column_count(self) -> None:
        with redirect_stderr(io.StringIO()):
            table = gr._build_contributors_table(self.authors, self.email_map, columns=3)
        self.assertEqual(table.count("<tr>"), 2)
        self.assertTrue(table.startswith("<table>"))
        self.assertTrue(table.endswith("</table>"))

    def test_bot_login_from_api_map_is_skipped(self) -> None:
        email_map = {"ada@example.com": {"login": "release-bot[bot]", "avatar_url": ""}}
        with redirect_stderr(io.StringIO()):
            table = gr._build_contributors_table(self.authors, email_map)
        self.assertNotIn("Ada", table)


if __name__ == "__main__":
    unittest.main()
