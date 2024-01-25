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
        name = "com_github_apple_swift_argument_parser",
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
    copts = [
        "-suppress-warnings",
    ],
    features = [
        "-swift.treat_warnings_as_errors",
    ],
    visibility = ["//visibility:public"],
    deps = [
        ":ArgumentParserToolInfo"
    ]
)
    """,
    )

    PATHKIT_GIT_SHA = "2fcd4618d52869b342e208324d455131a48f9e9b"
    _maybe(
        http_archive,
        name = "com_github_kylef_pathkit",
        urls = ["https://github.com/kylef/PathKit/archive/%s.zip" % PATHKIT_GIT_SHA],
        sha256 = "837749e86a882d7486853c39d745fb21ffcf4e2e303d307bce2f25c3f756e194",
        build_file_content = """
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "PathKit",
    module_name = "PathKit",
    srcs = glob([
        "Sources/**/*.swift"
    ], allow_empty = False),
    copts = [
        "-suppress-warnings",
    ],
    features = [
        "-swift.treat_warnings_as_errors",
    ],
    visibility = ["//visibility:public"],
)
        """,
        strip_prefix = "PathKit-%s" % PATHKIT_GIT_SHA,
    )

    _maybe(
        http_archive,
        name = "com_github_kitura_blueecc",
        url = "https://github.com/Kitura/BlueECC/archive/b0983b04bcf3a571404392e4fee461cf3f17548b.zip",
        strip_prefix = "BlueECC-b0983b04bcf3a571404392e4fee461cf3f17548b",
        build_file_content = """
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "BlueECC",
    srcs = glob([
        "Sources/CryptorECC/**/*.swift",
    ]),
    copts = [
        "-suppress-warnings",
    ],
    features = [
        "-swift.treat_warnings_as_errors",
    ],
    module_name = "CryptorECC",
    visibility = [
        "//visibility:public",
    ],
)
        """,
        sha256 = "c708192350913e9fa9a412bde60dcf9cc2e90b58573c4f6af1298dd27e31c642",
    )

    MOCKOLO_VERSION = "519439fb550dc23e622897de0080ce8ba68ddd78"

    _maybe(
        http_archive,
        name = "mockolo",
        build_file_content = """
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_binary", "swift_library")

swift_library(
    name = "MockoloFramework",
    srcs = glob(
        [
            "Sources/MockoloFramework/**/*.swift",
        ],
        allow_empty = False,
    ),
    copts = ["-suppress-warnings"],
    module_name = "MockoloFramework",
    deps = [
        "@SwiftToolsSupportCore//:TSCUtility",
        "@com_github_apple_swift_argument_parser//:ArgumentParser",
        "@SwiftSyntax//:SwiftParser_opt",
        "@SwiftSyntax//:SwiftSyntax_opt",
    ],
)

swift_library(
    name = "Mockolo",
    srcs = glob(
        [
            "Sources/Mockolo/**/*.swift",
        ],
        allow_empty = False,
    ),
    copts = [
        "-suppress-warnings",
    ],
    module_name = "Mockolo",
    deps = [
        ":MockoloFramework",
    ],
)

swift_binary(
    name = "mockolo",
    visibility = ["//visibility:public"],
    deps = [
        ":Mockolo",
    ],
)
        """,
        sha256 = "",
        strip_prefix = "mockolo-%s" % MOCKOLO_VERSION,
        urls = ["https://github.com/uber/mockolo/archive/%s.zip" % MOCKOLO_VERSION],
    )

    SWIFT_TOOLS_SUPPORT_CORE_VERSION = "0.5.2"

    _maybe(
        http_archive,
        name = "SwiftToolsSupportCore",
        build_file_content = """
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

objc_library(
    name = "TSCclibc",
    srcs = glob(
        [
            "Sources/TSCclibc/*.c",
        ],
        allow_empty = False,
    ),
    hdrs = [
        "Sources/TSCclibc/include/TSCclibc.h",
        "Sources/TSCclibc/include/indexstore_functions.h",
        "Sources/TSCclibc/include/process.h",
    ],
    copts = [
        "-w",
    ],
    module_name = "TSCclibc",
)

swift_library(
    name = "TSCLibc",
    srcs = glob(
        [
            "Sources/TSCLibc/**/*.swift",
        ],
        allow_empty = False,
    ),
    copts = [
        "-suppress-warnings",
    ],
    module_name = "TSCLibc",
    deps = [
        ":TSCclibc",
    ],
)

swift_library(
    name = "TSCBasic",
    srcs = glob(
        [
            "Sources/TSCBasic/**/*.swift",
        ],
        allow_empty = False,
    ),
    copts = [
        "-suppress-warnings",
    ],
    module_name = "TSCBasic",
    visibility = ["//visibility:public"],
    deps = [
        ":TSCLibc",
        "@com_github_apple_swift_system//:SystemPackage",
    ],
)

swift_library(
    name = "TSCUtility",
    srcs = glob(
        [
            "Sources/TSCUtility/**/*.swift",
        ],
        allow_empty = False,
    ),
    copts = [
        "-suppress-warnings",
    ],
    module_name = "TSCUtility",
    visibility = ["//visibility:public"],
    deps = [
        ":TSCBasic",
    ],
)

        """,
        sha256 = "3b07acf24ad49bf72f2825a39c542396880e89ab7e840ec2eed2cdb75696a17c",
        strip_prefix = "swift-tools-support-core-%s" % SWIFT_TOOLS_SUPPORT_CORE_VERSION,
        url = "https://github.com/apple/swift-tools-support-core/archive/refs/tags/%s.tar.gz" % SWIFT_TOOLS_SUPPORT_CORE_VERSION,
    )

    SWIFT_SYSTEM_VERSION = "1.2.1"

    _maybe(
        http_archive,
        name = "com_github_apple_swift_system",
        build_file_content = """
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

objc_library(
    name = "CSystem",
    srcs = glob(
        [
            "Sources/CSystem/*.c",
        ],
        allow_empty = False,
    ),
    copts = [
        "-w",
    ],
    module_name = "CSystem",
)

swift_library(
    name = "SystemPackage",
    srcs = glob(
        [
            "Sources/System/**/*.swift",
        ],
        allow_empty = False,
    ),
    defines = [
        "SYSTEM_PACKAGE",
    ],
    copts = [
        "-suppress-warnings",
    ],
    module_name = "SystemPackage",
    visibility = ["//visibility:public"],
    deps = [
        ":CSystem",
    ],
)
        """,
        sha256 = "ab771be8a944893f95eed901be0a81a72ef97add6caa3d0981e61b9b903a987d",
        strip_prefix = "swift-system-%s" % SWIFT_SYSTEM_VERSION,
        url = "https://github.com/apple/swift-system/archive/refs/tags/%s.tar.gz" % SWIFT_SYSTEM_VERSION,
    )

    SWIFT_SNAPSHOT_TESTING_GIT_SHA = "c466812aa2e22898f27557e2e780d3aad7a27203"

    http_archive(
        name = "SwiftSnapshotTesting",
        build_file_content = """
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "SnapshotTesting",
    testonly = True,
    srcs = glob(
        [
            "Sources/**/*.swift",
        ],
        allow_empty = False,
    ),
    copts = [
        "-suppress-warnings",
    ],
    module_name = "SnapshotTesting",
    visibility = ["//visibility:public"],
)
        """,
        sha256 = "fc37a90810c9ea402ab5612b4942ad1a22ae8105bbdd36cc64e0912343ad4a90",
        strip_prefix = "swift-snapshot-testing-%s" % SWIFT_SNAPSHOT_TESTING_GIT_SHA,
        url = "https://github.com/pointfreeco/swift-snapshot-testing/archive/%s.zip" % SWIFT_SNAPSHOT_TESTING_GIT_SHA,
    )

    SWIFT_SYNTAX_VERSION = "509.0.0"
    _maybe(
        http_archive,
        name = "SwiftSyntax",
        sha256 = "1cddda9f7d249612e3d75d4caa8fd9534c0621b8a890a7d7524a4689bce644f1",
        strip_prefix = "swift-syntax-%s" % SWIFT_SYNTAX_VERSION,
        url = "https://github.com/apple/swift-syntax/archive/refs/tags/%s.tar.gz" % SWIFT_SYNTAX_VERSION,
    )
