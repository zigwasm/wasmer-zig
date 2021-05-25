const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("wasmer-zig", "src/main.zig");
    lib.setBuildMode(mode);
    lib.install();

    var main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);

    const example = b.option([]const u8, "example", "Specify example to run from examples/ dir");
    const example_path = example_path: {
        const basename = example orelse "simple";
        const with_ext = try std.fmt.allocPrint(b.allocator, "{s}.zig", .{basename});
        const full_path = try std.fs.path.join(b.allocator, &[_][]const u8{ "examples", with_ext });
        break :example_path full_path;
    };

    const executable = b.addExecutable(example orelse "simple", example_path);
    executable.setBuildMode(mode);
    executable.addPackagePath("wasmer", "src/main.zig");
    executable.step.dependOn(b.getInstallStep());

    const run_executable = executable.run();
    const run_step = b.step("run", "Run an example specified with -Dexample (defaults to examples/simple.zig)");
    run_step.dependOn(&run_executable.step);
}
