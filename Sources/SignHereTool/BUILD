load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_binary",
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
