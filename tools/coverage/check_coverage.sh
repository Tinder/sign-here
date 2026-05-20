#!/usr/bin/env bash
# Convenience wrapper so `bazel run //tools/coverage:check_coverage_local --
# --threshold 90` works from any subdir. Bazel sets BUILD_WORKSPACE_DIRECTORY
# for `bazel run`, which the Python tool uses to anchor file paths.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec /usr/bin/env python3 "${SCRIPT_DIR}/check_coverage.py" "$@"
