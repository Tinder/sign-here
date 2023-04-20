load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_library",
)

swift_library(
    name = "CoreLibrary",
    srcs = glob(["**/*.swift"]),
    module_name = "CoreLibrary",
    visibility = [
        "//Sources/SignHereLibrary:__pkg__",
    ],
    deps = [
        "@com_github_kylef_pathkit//:PathKit",
    ],
)
