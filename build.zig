const std = @import("std");
const pkgs = @import("deps.zig").pkgs;
const mem = std.mem;

fn detectWasmerLibDir(b: *std.build.Builder) ?[]const u8 {
    const argv = &[_][]const u8{ "wasmer", "config", "--libdir" };
    const result = std.ChildProcess.exec(.{
        .allocator = b.allocator,
        .argv = argv,
    }) catch return null;

    if (result.stderr.len != 0 or result.term.Exited != 0) return null;

    const lib_dir = mem.trimRight(u8, result.stdout, "\r\n");
    return lib_dir;
}

pub fn build(b: *std.build.Builder) !void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    // Try detecting Wasmer lib dir.
    const wasmer_lib_dir = detectWasmerLibDir(b);

    const lib = b.addStaticLibrary("wasmer-zig", "src/main.zig");
    lib.setBuildMode(mode);
    lib.addPackage(pkgs.wasm);
    lib.install();

    var main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);
    main_tests.addPackage(pkgs.wasm);
    main_tests.linkSystemLibrary("wasmer");
    if (wasmer_lib_dir) |lib_dir| {
        main_tests.addLibPath(lib_dir);
    }
    main_tests.linkLibC();

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);

    const example = b.option([]const u8, "example", "Specify example to run from examples/ dir");
    const example_path = example_path: {
        const basename = example orelse "instance";
        const with_ext = try std.fmt.allocPrint(b.allocator, "{s}.zig", .{basename});
        const full_path = try std.fs.path.join(b.allocator, &[_][]const u8{ "examples", with_ext });
        break :example_path full_path;
    };

    const executable = b.addExecutable(example orelse "instance", example_path);
    executable.setBuildMode(mode);
    executable.addPackage(.{
        .name = "wasmer",
        .path = "src/main.zig",
        .dependencies = &.{pkgs.wasm},
    });
    executable.linkSystemLibrary("wasmer");
    if (wasmer_lib_dir) |lib_dir| {
        executable.addLibPath(lib_dir);
    }
    executable.linkLibC();
    executable.step.dependOn(b.getInstallStep());

    const run_executable = executable.run();
    const run_step = b.step("run", "Run an example specified with -Dexample (defaults to examples/instance.zig)");
    run_step.dependOn(&run_executable.step);
}
