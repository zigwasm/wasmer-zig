const std = @import("std");
const wasmer = @import("wasmer");

pub fn main() void {
    std.log.info("{}", .{wasmer.add(1, 1)});
}
