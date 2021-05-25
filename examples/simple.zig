const std = @import("std");
const wasmer = @import("wasmer");
const assert = std.debug.assert;
const fs = std.fs;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = &gpa.allocator;

pub fn main() !void {
    const file = try fs.cwd().openFile("examples/sum.wasm", .{});
    defer file.close();

    const bytes = try file.readToEndAlloc(allocator, std.math.maxInt(u64));
    defer allocator.free(bytes);

    // Create new instance.
    const instance = try wasmer.Instance.new(bytes, &.{});
    defer instance.destroy();

    // Prepare input args.
    const args = &[_]wasmer.Value{ wasmer.Value.from_i32(7), wasmer.Value.from_i32(8) };
    const result = (try instance.call("sum", args)).as_i32().?;

    assert(result == 15);

    std.log.info("sum.wasm: {} + {} == {}", .{ 7, 8, result });
}
