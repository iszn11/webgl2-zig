# WebGL 2 with Zig
Spinning cube in WebGL 2 made with Zig programming language compiled to
WebAssembly.

To compile run:

`zig build-lib -target wasm32-freestanding -O ReleaseSmall main.zig`

*NOTE For current version of Zig (0.8.0-dev.1417+9f722f43a) I encountered a
problem where output .wasm file is very large (tens of KB). If that's still the
case you may want to run with `--link-verbose`, like so:*

`zig build-lib --verbose-link -target wasm32-freestanding -O ReleaseSmall main.zig`

*You should see a single command. You can rerun it (you need `wasm-ld`) ommiting
arguments that end with `c.o.wasm` and `compiler_rt.o.wasm`.*
