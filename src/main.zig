const std = @import("std");
const wasm = @import("wasm");

// Re-exports
pub const ByteVec = wasm.ByteVec;
pub const Engine = wasm.Engine;
pub const Store = wasm.Store;
pub const Module = wasm.Module;
pub const Instance = wasm.Instance;
pub const Extern = wasm.Extern;
pub const Func = wasm.Func;

pub fn lastError(allocator: std.mem.Allocator) ![:0]u8 {
    const buf_len =  @intCast(usize, wasmer_last_error_length());
    const buf = try allocator.alloc(u8, buf_len);
    _ = wasmer_last_error_message(buf.ptr, @intCast(c_int, buf_len));
    return buf[0..buf_len-1:0];
}
pub extern "c" fn wasmer_last_error_length() c_int;
pub extern "c" fn wasmer_last_error_message([*]const u8, c_int) c_int;

// Helpers

pub fn watToWasm(wat: []const u8) !ByteVec {
    var wat_bytes = ByteVec.fromSlice(wat);
    defer wat_bytes.deinit();

    var wasm_bytes: ByteVec = undefined;
    wat2wasm(&wat_bytes, &wasm_bytes);

    if(wasm_bytes.size == 0) return error.WatParse;
    return wasm_bytes;
}

extern "c" fn wat2wasm(*const ByteVec, *ByteVec) void;

test "" {
    _ = std.testing.refAllDecls(@This());
}
