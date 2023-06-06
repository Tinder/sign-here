load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_binary",
)
load(
    "@build_bazel_rules_apple//apple:macos.bzl",
    "macos_command_line_application",
)

swift_binary(
    name = "sign-here",
    srcs = [
        "main.swift",
    ],
    visibility = [
        "//visibility:public",
    ],
    deps = [
        "//Sources/SignHereLibrary",
    ],
)

macos_command_line_application(
    name = "sign-here-macos",
    minimum_os_version = "13.0.0",
    deps = [
        ":sign-here",
    ],
)
