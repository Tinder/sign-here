""" Loads necessary dependencies when tooling tools are executed from other repositories """

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _maybe(repo_rule, name, **kwargs):
    """Executes the given repository rule if it hasn't been executed already.

    Args:
    repo_rule: The repository rule to be executed (e.g., `http_archive`.)
    name: The name of the repository to be defined by the rule.
    **kwargs: Additional arguments passed directly to the repository rule.
    """
    if not native.existing_rule(name):
        repo_rule(name = name, **kwargs)

def sign_here_dependencies():
    """Sets up all necessary transitive dependencies."""

    _maybe(
        http_archive,
        name = "com_github_apple_swift-argument-parser",
        url = "https://github.com/apple/swift-argument-parser/archive/refs/tags/1.2.2.tar.gz",
        strip_prefix = "swift-argument-parser-1.2.2",
        sha256 = "44782ba7180f924f72661b8f457c268929ccd20441eac17301f18eff3b91ce0c",
        build_file_content = """
load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_library",
)

load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "ArgumentParserToolInfo",
    module_name = "ArgumentParserToolInfo",
    srcs = glob([
        "Sources/ArgumentParserToolInfo/**/*.swift"
    ], allow_empty = False),
)

swift_library(
    name = "ArgumentParser",
    module_name = "ArgumentParser",
    srcs = glob([
        "Sources/ArgumentParser/**/*.swift"
    ], allow_empty = False),
    visibility = ["//visibility:public"],
    deps = [
        ":ArgumentParserToolInfo"
    ]
)
    """,
    )

    PATHKIT_GIT_SHA = "2fcd4618d52869b342e208324d455131a48f9e9b"
    _maybe(
        http_archive,
        name = "com_github_kylef_pathkit",
        urls = ["https://github.com/kylef/PathKit/archive/%s.zip" % PATHKIT_GIT_SHA],
        sha256 = "837749e86a882d7486853c39d745fb21ffcf4e2e303d307bce2f25c3f756e194",
        build_file_content = """
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "PathKit",
    module_name = "PathKit",
    srcs = glob([
        "Sources/**/*.swift"
    ], allow_empty = False),
    visibility = ["//visibility:public"],
)
        """,
        strip_prefix = "PathKit-%s" % PATHKIT_GIT_SHA,
    )

    _maybe(
        http_archive,
        name = "com_github_kitura_blueecc",
        url = "https://github.com/Kitura/BlueECC/archive/b0983b04bcf3a571404392e4fee461cf3f17548b.zip",
        strip_prefix = "BlueECC-b0983b04bcf3a571404392e4fee461cf3f17548b",
        build_file_content = """
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "BlueECC",
    srcs = glob([
        "Sources/CryptorECC/**/*.swift",
    ]),
    copts = ["-suppress-warnings"],
    module_name = "CryptorECC",
    visibility = [
        "//visibility:public",
    ],
)
        """,
        sha256 = "c708192350913e9fa9a412bde60dcf9cc2e90b58573c4f6af1298dd27e31c642",
    )
