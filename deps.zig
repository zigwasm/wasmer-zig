const std = @import("std");
pub const pkgs = struct {
    pub const wasm = std.build.Pkg{
        .name = "wasm",
        .path = ".gyro/wasm-zig-kubkon-9c42564835bd97ec0e8edf3f93411a1a52b49cc9/pkg/src/main.zig",
    };

    pub fn addAllTo(artifact: *std.build.LibExeObjStep) void {
        @setEvalBranchQuota(1_000_000);
        inline for (std.meta.declarations(pkgs)) |decl| {
            if (decl.is_pub and decl.data == .Var) {
                artifact.addPackage(@field(pkgs, decl.name));
            }
        }
    }
};

pub const base_dirs = struct {
    pub const wasm = ".gyro/wasm-zig-kubkon-9c42564835bd97ec0e8edf3f93411a1a52b49cc9/pkg";
};
