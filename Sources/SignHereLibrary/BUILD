load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_library",
)

srcs = glob(
    ["**/*.swift"],
    allow_empty = False,
)

swift_library(
    name = "SignHereLibrary",
    srcs = srcs,
    copts = [
        "-warnings-as-errors",
        "-Xfrontend",
        "-warn-long-expression-type-checking=2000",
        "-Xfrontend",
        "-warn-long-function-bodies=2000",
    ],
    module_name = "SignHereLibrary",
    visibility = [
        "//Sources/SignHereTool:__pkg__",
        "//Tests:__subpackages__",
    ],
    deps = [
        "//Sources/CoreLibrary",
        "@com_github_apple_swift_argument_parser//:ArgumentParser",
    ],
)

genrule(
    name = "SignHereLibrary_MockoloGeneratedMocks",
    testonly = True,
    srcs = srcs,
    outs = ["SignHereLibrary_GeneratedMocks.swift"],
    cmd = "$(location @mockolo//:mockolo) -srcs $(SRCS) -d $@ -i SignHereLibrary --enable-args-history > /dev/null",
    tools = [
        "@mockolo",
    ],
)

swift_library(
    name = "SignHereLibrary_GeneratedMocks",
    testonly = True,
    srcs = ["SignHereLibrary_GeneratedMocks.swift"],
    copts = [
        "-whole-module-optimization",  # ME: These modules cannot be built incrementally, WMO is faster in this use case and avoids incrementality issues
    ],
    module_name = "SignHereLibrary_GeneratedMocks",
    visibility = [
        "//Tests:__subpackages__",
    ],
    deps = [
        ":SignHereLibrary",
    ],
)
