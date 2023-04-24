load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_test",
)

swift_test(
    name = "SignHereUnitTests",
    srcs = glob(
        [
            "**/*.swift",
        ],
        allow_empty = False,
    ),
    data = glob(
        [
            "__Snapshots__/**/*",
        ],
        allow_empty = False,
    ),
    deps = [
        "//Sources/CoreLibrary:CoreLibrary_GeneratedMocks",
        "//Sources/CoreLibraryTestKit",
        "//Sources/SignHereLibrary",
        "//Sources/SignHereLibrary:SignHereLibrary_GeneratedMocks",
    ],
)
