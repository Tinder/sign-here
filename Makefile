.PHONY: record_snapshots coverage coverage_tool_test generate_readme readme_tool_test

record_snapshots:
	bazel test //Tests/... \
		--config=record_snapshots \
		--test_env=BUILD_WORKSPACE_DIRECTORY=$$(pwd) \
		--test_env=SNAPSHOT_DIRECTORY="$$(pwd)/Tests/SignHereLibraryTests" \
		--test_env=RERECORD_SNAPSHOTS=TRUE

# Collect Swift line coverage and enforce the project threshold.
# Mirrors the `coverage` job in .github/workflows/ci.yaml.
coverage:
	python3 tools/coverage/check_coverage.py --threshold 90

# Self-tests for the coverage tool itself.
coverage_tool_test:
	python3 tools/coverage/check_coverage_test.py

# Regenerate README.md from tools/readme/README.template.md (live CLI help,
# module version, and the contributors table built from git log + GitHub API).
# Set GITHUB_TOKEN to avoid API rate limits. Commit the result.
generate_readme:
	bazel run //:generate_readme

# Self-tests for the README generator's contributor logic.
readme_tool_test:
	python3 tools/readme/generate_readme_test.py
