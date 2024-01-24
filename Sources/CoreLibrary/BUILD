load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_library",
)

srcs = glob(
    ["**/*.swift"],
    allow_empty = False,
)

swift_library(
    name = "CoreLibrary",
    srcs = srcs,
    module_name = "CoreLibrary",
    visibility = [
        "//Sources:__subpackages__",
        "//Tests:__subpackages__",
    ],
    deps = [
        "@com_github_kylef_pathkit//:PathKit",
    ],
)

genrule(
    name = "CoreLibrary_MockoloGeneratedMocks",
    testonly = True,
    srcs = srcs,
    outs = ["CoreLibrary_GeneratedMocks.swift"],
    cmd = "$(location @mockolo//:mockolo) -srcs $(SRCS) -d $@ -i CoreLibrary --enable-args-history > /dev/null",
    tools = [
        "@mockolo",
    ],
)

swift_library(
    name = "CoreLibrary_GeneratedMocks",
    testonly = True,
    srcs = ["CoreLibrary_GeneratedMocks.swift"],
    copts = [
        "-whole-module-optimization",  # ME: These modules cannot be built incrementally, WMO is faster in this use case and avoids incrementality issues
    ],
    module_name = "CoreLibrary_GeneratedMocks",
    visibility = [
        "//Tests:__subpackages__",
    ],
    deps = [
        ":CoreLibrary",
    ],
)
