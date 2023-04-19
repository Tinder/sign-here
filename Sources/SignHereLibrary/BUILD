load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_library",
)

swift_library(
    name = "SignHereLibrary",
    srcs = glob(["**/*.swift"]),
    module_name = "SignHereLibrary",
    visibility = [
        "//Sources/SignHereTool:__pkg__",
    ],
    deps = [
        "@ArgumentParser",
    ],
)
