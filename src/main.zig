const std = @import("std");

pub const Result = extern enum {
    ok = 1,
    err,
};

pub const ByteArray = extern struct {
    bytes: [*]const u8,
    len: u32,

    pub fn from_slice(slice: []const u8) ByteArray {
        return .{
            .bytes = slice.ptr,
            .len = slice.len,
        };
    }
};

pub const Instance = opaque {
    pub fn new(bytes: []const u8, imports: []Import) !*Instance {
        const bytes_len = try std.math.cast(u32, bytes.len);

        var instance: *Instance = undefined;
        switch (wasmer_instantiate(&instance, bytes.ptr, bytes_len, imports.ptr, imports.len)) {
            .ok => return instance,
            .err => return error.InstanceInitError,
        }
    }

    pub fn call(instance: *Instance, name: []const u8, args: []Value) !Value {
        const args_len = try std.math.cast(u32, args.len);

        // TODO verify what is the maximum number of return values.
        var returns: [1]Value = undefined;
        switch (wasmer_instance_call(instance, name.ptr, args.ptr, args_len, &returns, 1)) {
            .ok => return returns[0],
            .err => return error.InstanceCallError,
        }
    }

    pub fn destroy(instance: *Instance) void {
        wasmer_instance_destroy(instance);
    }

    extern "c" fn wasmer_instantiate(**Instance, [*]const u8, u32, [*]Import, usize) Result;
    extern "c" fn wasmer_instance_call(*Instance, [*]const u8, [*]const Value, u32, [*]Value, u32) Result;
    extern "c" fn wasmer_instance_destroy(*Instance) void;
};

pub const ImportExportKind = extern enum {
    function = 0,
    global,
    memory,
    table,
};

pub const ImportFunc = opaque {};
pub const Table = opaque {};
pub const Memory = opaque {};
pub const Global = opaque {};

pub const ImportExportValue = extern union {
    function: ?*ImportFunc,
    table: ?*Table,
    memory: ?*Memory,
    global: ?*Global,
};

pub const Import = extern struct {
    module_name: ByteArray,
    import_name: ByteArray,
    tag: ImportExportKind,
    value: ImportExportValue,
};

pub const ValueTag = extern enum {
    I32,
    I64,
    F32,
    F64,
};

pub const Value = extern struct {
    tag: ValueTag,
    value: extern union {
        I32: i32,
        I64: i64,
        F32: f32,
        F64: f64,
    },

    pub fn from_i32(v: i32) Value {
        return .{
            .tag = .I32,
            .value = .{ .I32 = v },
        };
    }

    pub fn from_i64(v: i64) Value {
        return .{
            .tag = .I64,
            .value = .{ .I64 = v },
        };
    }

    pub fn from_f32(v: f32) Value {
        return .{
            .tag = .F32,
            .value = .{ .F32 = v },
        };
    }

    pub fn from_f64(v: f64) Value {
        return .{
            .tag = .F64,
            .value = .{ .F64 = v },
        };
    }

    pub fn as_i32(v: Value) ?i32 {
        if (v.tag != .I32) return null;
        return v.value.I32;
    }

    pub fn as_i64(v: Value) ?i64 {
        if (v.tag != .I64) return null;
        return v.value.I64;
    }

    pub fn as_f32(v: Value) ?f32 {
        if (v.tag != .F32) return null;
        return v.value.F32;
    }

    pub fn as_f64(v: Value) ?f64 {
        if (v.tag != .F64) return null;
        return v.value.F64;
    }
};
