#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

TAG=$1
PREFIX="sign-here-${TAG:1}"
ARCHIVE="sign-here-${TAG}.tar.gz"

git archive --format=tar --prefix=${PREFIX}/ ${TAG} | gzip > $ARCHIVE
SHA=$(shasum -a 256 $ARCHIVE | awk '{print $1}')

bazelisk build //Sources/SignHereTool:sign-here -c opt --macos_cpus=arm64
cp bazel-bin/Sources/SignHereTool/sign-here "sign-here-${TAG}-darwin-arm64"

cat << EOF
## Using Bzlmod with Bazel 6 or greater

Add to your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "sign-here", version = "${TAG:1}")
\`\`\`

## Using WORKSPACE

Paste this snippet into your \`WORKSPACE.bazel\` file:

\`\`\`starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "com_github_tinder_sign_here",
    sha256 = "${SHA}",
    strip_prefix = "${PREFIX}",
    url = "https://github.com/Tinder/sign-here/releases/download/${TAG}/${ARCHIVE}",
)
\`\`\`
EOF
