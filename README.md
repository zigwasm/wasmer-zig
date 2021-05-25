# wasmer-zig

Zig bindings for the [Wasmer] WebAssembly runtime.

[Wasmer]: https://github.com/wasmerio/wasmer

## Disclaimer

This is a work-in-progress library so things will change without notice! Furthermore, building
this library and examples requires the latest nightly version of Zig `0.8.0`.

## Building

This library consumes the Wasmer's C API which is auto-installed with each release of Wasmer.
The current stable release of Wasmer this embedding relies on is [v1.0.2]. Therefore, make sure
you have `wasmer` binary installed and in your `PATH`.

[v1.0.2]: https://github.com/wasmerio/wasmer/releases/tag/1.0.2

To build this library, simply run

```
zig build
```

Tests can be invoked as follows

```
zig build test
```

## Running examples

You can find a few examples of how this library can be used to embed Wasmer in your app and
instantiate Wasm modules in the `examples/` dir. You can run any example with

```
zig build run <example>
```

In particular, you will find there `examples/simple.zig` which is a Zig port of Wasmer's official
[C tutorial].

[C tutorial]: https://wasmerio.github.io/wasmer/c/

