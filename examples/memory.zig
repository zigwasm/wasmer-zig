const std = @import("std");
const wasmer = @import("wasmer");
const assert = std.debug.assert;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = &gpa.allocator;

const wat =
    \\(module
    \\   (type $mem_size_t (func (result i32)))
    \\   (type $get_at_t (func (param i32) (result i32)))
    \\   (type $set_at_t (func (param i32) (param i32)))
    \\   (memory $mem 1)
    \\   (func $get_at (type $get_at_t) (param $idx i32) (result i32)
    \\     (i32.load (local.get $idx)))
    \\   (func $set_at (type $set_at_t) (param $idx i32) (param $val i32)
    \\     (i32.store (local.get $idx) (local.get $val)))
    \\   (func $mem_size (type $mem_size_t) (result i32)
    \\     (memory.size))
    \\   (export \"get_at\" (func $get_at))
    \\   (export \"set_at\" (func $set_at))
    \\   (export \"mem_size\" (func $mem_size))
    \\   (export \"memory\" (memory $mem))
;

pub fn main() !void {
    var wat_bytes = wasmer.ByteVec.fromSlice(wat);
    defer wat_bytes.deinit();

    var wasm_bytes: wasmer.ByteVec = undefined;
    wasmer.wat2wasm(&wat_bytes, &wasm_bytes);
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

    const get_at = instance.getExportFunc(module, "get_at") orelse {
        std.log.err("failed to retrieve \"get_at\" export from instance", .{});
        return error.ExportNotFound;
    };
    defer get_at.deinit();
    const set_at = instance.getExportFunc(module, "set_at") orelse {
        std.log.err("failed to retrieve \"set_at\" export from instance", .{});
        return error.ExportNotFound;
    };
    defer set_at.deinit();
    const mem_size = instance.getExportFunc(module, "mem_size") orelse {
        std.log.err("failed to retrieve \"mem_size\" export from instance", .{});
        return error.ExportNotFound;
    };
    defer mem_size.deinit();

    const memory = instance.getExportMem(module, "memory") orelse {
        std.log.err("failed to retrieve \"memory\" export from instance", .{});
        return error.ExportNotFound;
    };
    defer memory.deinit();

    const pages = memory.pages();
    const data_size = memory.size();

    memory.grow(2) catch |err| {
        std.log.err("Error growing memory!", .{});
        return err;
    };

    const new_pages = memory.pages();
    std.log.info("New memory size (pages): {d}", .{new_pages});

    const mem_addr: i32 = 0x2220;
    const val: i32 = 0xFEFEFFE;

    set_at.call(void, .{ mem_addr, val }) catch |err| {
        std.log.err("Failed to call \"set_at\": {s}", .{err});
        return err;
    };

    const result = get_at.call(i32, .{mem_addr}) catch |err| {
        std.log.err("Failed to call \"get_at\": {s}", .{err});
        return err;
    };

    std.log.info("Vale at 0x{x:0>4}: {d}", .{ mem_addr, result });
}
