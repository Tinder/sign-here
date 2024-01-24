load("//:repositories.bzl", "sign_here_dependencies")

def _non_module_dependencies_impl(_ctx):
    sign_here_dependencies()

non_module_dependencies = module_extension(
    implementation = _non_module_dependencies_impl,
)
