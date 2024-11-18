# rubberband

This is [rubberband](https://breakfastquay.com/rubberband/),
packaged for [Zig](https://ziglang.org/).

## How to use it

First, update your `build.zig.zon`:

```
zig fetch --save https://github.com/myQwil/rubberband/archive/refs/tags/v0.1.0.tar.gz
```

Next, add this snippet to your `build.zig` script:

```zig
const rubberband_dep = b.dependency("rubberband", .{
    .target = target,
    .optimize = optimize,
});
```

From here, you can add it to `your_compilation`, either as a library or a module.

### As a library
```zig
your_compilation.linkLibrary(rubberband_dep.artifact("rubberband"));
```

### As a module
```zig
your_compilation.root_module.addImport("rubberband", rubberband_dep.module("rubberband")),
```
