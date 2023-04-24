load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_library",
)

srcs = glob(
    ["**/*.swift"],
    allow_empty = False,
)

swift_library(
    name = "CoreLibraryTestKit",
    testonly = True,
    srcs = srcs,
    copts = [
        "-warnings-as-errors",
        "-Xfrontend",
        "-warn-long-expression-type-checking=2000",
        "-Xfrontend",
        "-warn-long-function-bodies=2000",
    ],
    module_name = "CoreLibraryTestKit",
    visibility = [
        "//Tests:__subpackages__",
    ],
    deps = [
        "//Sources/CoreLibrary",
        "@SwiftSnapshotTesting//:SnapshotTesting",
    ],
)
