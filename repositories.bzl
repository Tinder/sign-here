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
        name = "ArgumentParser",
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
