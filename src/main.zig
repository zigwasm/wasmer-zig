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

// Helpers
pub extern "c" fn wat2wasm(*const ByteVec, *ByteVec) void;

test "" {
    _ = std.testing.refAllDecls(@This());
}
