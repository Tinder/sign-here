#!/usr/bin/env bash
# Wrapper so `bazel run //:generate_readme` executes from the workspace root with BUILD_WORKSPACE_DIRECTORY set.
set -euo pipefail
ROOT="${BUILD_WORKSPACE_DIRECTORY:-}"
if [[ -z "${ROOT}" ]]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
fi
if [[ -z "${ROOT}" ]]; then
  echo "error: set BUILD_WORKSPACE_DIRECTORY or run from a git checkout" >&2
  exit 1
fi
cd "${ROOT}"
exec python3 "${ROOT}/tools/readme/generate_readme.py" "$@"
