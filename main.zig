const std = @import("std");

extern fn enable(cap: u32) void;
extern fn disable(cap: u32) void;

extern fn clearColor(r: f32, g: f32, b: f32, a: f32) void;
extern fn clear(mask: u32) void;

extern fn createVertexArray() u32;
extern fn bindVertexArray(vao: u32) void;
extern fn enableVertexAttribArray(index: u32) void;
extern fn vertexAttribPointer(index: u32, size: i32, @"type": u32, normalized: bool, stride: i32, offset: i32) void;

extern fn createBuffer() u32;
extern fn bindBuffer(target: u32, vbo: u32) void;
extern fn bufferData(target: u32, data: *const c_void, length: usize, usage: u32) void;

extern fn compileProgram(vertCode: [*]const u8, vertCodeLength: usize, fragCode: [*]const u8, fragCodeLength: usize) u32;
extern fn getUniformLocation(program: u32, name: [*]const u8, nameLength: usize) u32;

extern fn useProgram(program: u32) void;
extern fn drawArrays(mode: u32, first: i32, count: i32) void;
extern fn drawElements(mode: u32, count: i32, @"type": u32, indices: i32) void;
extern fn uniformMatrix4fv(location: u32, transpose: bool, value: *const [16]f32) void;

// clearing buffers
const DEPTH_BUFFER_BIT = 0x00000100;
const COLOR_BUFFER_BIT = 0x00004000;

// rendering primitives
const TRIANGLES = 0x0004;
const TRIANGLE_STRIP = 0x0005;
const TRIANGLE_FAN = 0x0006;

// blending modes
const SRC_ALPHA = 0x0302;
const ONE_MINUS_SRC_ALPHA = 0x0303;

// buffers
const STATIC_DRAW = 0x88E4;
const STREAM_DRAW = 0x88E0;
const DYNAMIC_DRAW = 0x88E8;
const ARRAY_BUFFER = 0x8892;
const ELEMENT_ARRAY_BUFFER = 0x8893;

// culling
const CULL_FACE = 0x0B44;
const FRONT = 0x0404;
const BACK = 0x0405;
const FRONT_AND_BACK = 0x0408;

// enabling and disabling
const BLEND = 0x0BE2;
const DEPTH_TEST = 0x0B71;

// data types
const BYTE = 0x1400;
const UNSIGNED_BYTE = 0x1401;
const SHORT = 0x1402;
const UNSIGNED_SHORT = 0x1403;
const INT = 0x1404;
const UNSIGNED_INT = 0x1405;
const FLOAT = 0x1406;

const vertCode =
    \\#version 300 es
    \\layout(location = 0) in vec3 aPos;
    \\layout(location = 1) in vec3 aColor;
    \\uniform mat4 uModel;
    \\uniform mat4 uView;
    \\uniform mat4 uProjection;
    \\out vec3 vColor;
    \\void main() {
    \\    gl_Position = uProjection * (uView * (uModel * vec4(aPos, 1.0)));
    \\    vColor = aColor;
    \\}
;

const fragCode =
    \\#version 300 es
    \\precision mediump float;
    \\in vec3 vColor;
    \\out vec4 fColor;
    \\void main() {
    \\   fColor = vec4(vColor, 1.0);
    \\}
;

const verts = [_]f32 {
    -0.5, -0.5, -0.5, 0.0, 0.0, 0.0, // 0 ---
     0.5, -0.5, -0.5, 1.0, 0.0, 0.0, // 1 +--
    -0.5,  0.5, -0.5, 0.0, 1.0, 0.0, // 2 -+-
    -0.5, -0.5,  0.5, 0.0, 0.0, 1.0, // 3 --+
     0.5,  0.5, -0.5, 1.0, 1.0, 0.0, // 4 ++-
     0.5, -0.5,  0.5, 1.0, 0.0, 1.0, // 5 +-+
    -0.5,  0.5,  0.5, 0.0, 1.0, 1.0, // 6 -++
     0.5,  0.5,  0.5, 1.0, 1.0, 1.0, // 7 +++
};

const elements = [_]u16 {
    0, 3, 2, 2, 3, 6, // -X
    5, 1, 7, 7, 1, 4, // +X
    5, 3, 1, 1, 3, 0, // -Y
    6, 7, 2, 2, 7, 4, // +Y
    1, 0, 4, 4, 0, 2, // -Z
    3, 5, 6, 6, 5, 7, // +Z
};

var programID: u32 = undefined;
var vaoID: u32 = undefined;
var vboID: u32 = undefined;
var eboID: u32 = undefined;

var mLocation: u32 = undefined;
var vLocation: u32 = undefined;
var pLocation: u32 = undefined;

var m = [_] f32 {
    1.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0,
    0.0, 0.0, 0.0, 1.0,
};

const v = blk: {
    const s2 = @as(f32, std.math.sqrt2);
    const s3 = std.math.sqrt(@as(f32, 3.0));

    break :blk [_] f32 {
        0.5 * s2, -0.25 * s3, 0.25 * s3, 0.0,
        0.0, 0.5 * s3, 0.5 * s3, 0.0,
        -0.5 * s2, -0.25 * s3, 0.25 * s3, 0.0,
        0.0, 0.0, -2.0, 1.0,
    };
};

const p = blk: {
    const ar = 720.0 / 480.0;
    const fovDeg = 60.0;
    const fovRad = fovDeg * std.math.tau / 360.0;
    const n = 0.1;
    const f = 10.0;

    const t = std.math.tan(@as(f32, 0.5 * fovRad));

    break :blk [_] f32 {
        1.0 / (ar * t), 0.0, 0.0, 0.0,
        0.0, 1.0 / t, 0.0, 0.0,
        0.0, 0.0, (n + f) / (n - f), -1.0,
        0.0, 0.0, 2.0 * n * f / (n - f), 0.0,
    };
};

pub export fn init() void {

    enable(DEPTH_TEST);
    enable(CULL_FACE);
    clearColor(0.1, 0.1, 0.1, 1.0);

    programID = compileProgram(vertCode, vertCode.len, fragCode, fragCode.len);
    const uModel = "uModel";
    const uView = "uView";
    const uProjection = "uProjection";
    mLocation = getUniformLocation(programID, uModel, uModel.len);
    vLocation = getUniformLocation(programID, uView, uView.len);
    pLocation = getUniformLocation(programID, uProjection, uProjection.len);

    vaoID = createVertexArray();
    bindVertexArray(vaoID);

    vboID = createBuffer();
    bindBuffer(ARRAY_BUFFER, vboID);
    bufferData(ARRAY_BUFFER, &verts, @sizeOf(@TypeOf(verts)), STATIC_DRAW);

    eboID = createBuffer();
    bindBuffer(ELEMENT_ARRAY_BUFFER, eboID);
    bufferData(ELEMENT_ARRAY_BUFFER, &elements, @sizeOf(@TypeOf(elements)), STATIC_DRAW);

    vertexAttribPointer(0, 3, FLOAT, false, 6 * @sizeOf(f32), 0);
    vertexAttribPointer(1, 3, FLOAT, false, 6 * @sizeOf(f32), 3 * @sizeOf(f32));
    enableVertexAttribArray(0);
    enableVertexAttribArray(1);
}

pub export fn update(timestamp: i32) void {

    const time = @intToFloat(f32, timestamp) * 0.001;

    clear(COLOR_BUFFER_BIT);

    const c = std.math.cos(time);
    const s = std.math.sin(time);
    m[0] = c;  // ix
    m[2] = -s; // iz
    m[8] = s;  // kx
    m[10] = c; // kz

    bindVertexArray(vaoID);
    useProgram(programID);
    uniformMatrix4fv(mLocation, false, &m);
    uniformMatrix4fv(vLocation, false, &v);
    uniformMatrix4fv(pLocation, false, &p);
    drawElements(TRIANGLES, elements.len, UNSIGNED_SHORT, 0);
}
