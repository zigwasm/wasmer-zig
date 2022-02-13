const std = @import("std");
const wasmer = @import("wasmer");
const assert = std.debug.assert;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const wat =
    \\(module
    \\  (type $add_one_t (func (param i32) (result i32)))
    \\  (func $add_one_f (type $add_one_t) (param $value i32) (result i32)
    \\    local.get $value
    \\    i32.const 1
    \\    i32.add)
    \\  (export "add_one" (func $add_one_f)))
;

pub fn main() !void {
    run () catch |err| {
        const err_msg = try wasmer.lastError(std.heap.c_allocator);
        defer std.heap.c_allocator.free(err_msg);

        std.log.err("{s}", .{err_msg});

        return err;
    };
}

fn run() !void {
    var wasm_bytes = try wasmer.watToWasm(wat);
    defer wasm_bytes.deinit();

    std.log.info("creating the store...", .{});

    const engine = try wasmer.Engine.init();
    defer engine.deinit();
    const store = try wasmer.Store.init(engine);
    defer store.deinit();

    std.log.info("compiling module...", .{});

    const module = try wasmer.Module.init(store, wasm_bytes.toSlice());

    defer module.deinit();

    std.log.info("instantiating module...", .{});

    const instance = try wasmer.Instance.init(store, module, &.{});
    defer instance.deinit();

    std.log.info("retrieving exports...", .{});

    const add_one = instance.getExportFunc(module, "add_one") orelse {
        std.log.err("failed to retrieve \"add_one\" export from instance", .{});
        return error.ExportNotFound;
    };
    defer add_one.deinit();

    std.log.info("calling \"add_one\" export fn...", .{});

    const res = try add_one.call(i32, .{@as(i32, 1)});
    assert(res == 2);

    std.log.info("result of \"add_one(1)\" = {}", .{res});
}
