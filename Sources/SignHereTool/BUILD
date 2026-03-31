load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_binary",
    "swift_library",
)
load(
    "@build_bazel_rules_apple//apple:macos.bzl",
    "macos_command_line_application",
)

swift_library(
    name = "SignHereToolMain",
    srcs = [
        "SignHereToolMain.swift",
    ],
    deps = [
        "//Sources/SignHereLibrary",
    ],
)

swift_binary(
    name = "sign-here",
    visibility = [
        "//visibility:public",
    ],
    deps = [
        ":SignHereToolMain",
    ],
)

macos_command_line_application(
    name = "sign-here-macos",
    minimum_os_version = "13.0.0",
    deps = [
        ":SignHereToolMain",
    ],
)
