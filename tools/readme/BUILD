sh_binary(
    name = "generate_readme",
    srcs = ["generate_readme.sh"],
    data = [
        "generate_readme.py",
        "README.template.md",
        "//:MODULE.bazel",
        "//Sources/SignHereTool:sign-here",
    ],
    visibility = ["//visibility:public"],
)
