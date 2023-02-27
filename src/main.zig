const std = @import("std");
const glfw = @import("glfw");
const gl = @import("zgl");

fn glLoader(_: @TypeOf(.{}), name: [:0]const u8) ?*const anyopaque {
    return glfw.getProcAddress(name);
}

const vertexShaderSource = @embedFile("./vertex.glsl");
const fragmentShaderSource = @embedFile("./frag.glsl");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    _ = glfw.init(.{});
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "OpenGL basics", null, null, .{
        .context_version_major = 3,
        .context_version_minor = 3,
        .opengl_profile = .opengl_core_profile,
        .opengl_forward_compat = true,
    }).?;
    defer window.destroy();

    glfw.makeContextCurrent(window);
    try gl.loadExtensions(.{}, glLoader);

    // compile vertex shader
    const vertexShader = gl.Shader.create(.vertex);
    vertexShader.source(1, &.{ vertexShaderSource });
    vertexShader.compile();

    const vertexShaderLog = try vertexShader.getCompileLog(allocator);
    std.debug.print("vertex log:\n{s}\n", .{vertexShaderLog});
    allocator.free(vertexShaderLog);

    // compile frag shader
    const fragShader = gl.Shader.create(.fragment);
    fragShader.source(1, &.{ fragmentShaderSource });
    fragShader.compile();

    const fragShaderLog = try fragShader.getCompileLog(allocator);
    std.debug.print("frag log:\n{s}\n", .{fragShaderLog});
    allocator.free(fragShaderLog);

    // link shaders
    const shaderProgram = gl.Program.create();
    defer shaderProgram.delete();
    shaderProgram.attach(vertexShader);
    shaderProgram.attach(fragShader);
    shaderProgram.link();

    const programLog = try shaderProgram.getCompileLog(allocator);
    std.debug.print("shader program log:\n{s}\n", .{programLog});
    allocator.free(programLog);

    // delete shaders
    vertexShader.delete();
    fragShader.delete();

    std.debug.print("{}\n", .{gl.getInteger(.max_vertex_attribs)});

    // Vertex Array Object
    var vao = gl.VertexArray.gen();
    defer vao.delete();
    vao.bind();

    // Vertex Buffer Object
    var vbo = gl.Buffer.gen();
    defer vbo.delete();
    vbo.bind(.array_buffer);
    vbo.data(f32, &[_]f32{
        // vertices     // colors
        0.0, 1.0, 0.0,  1.0, 0.0, 0.0,
        -0.5, 0.0, 0.0, 0.0, 1.0, 0.0,
        0.5, 0.0, 0.0,  0.0, 0.0, 1.0,
    }, .static_draw);

    // position attribute
    gl.vertexAttribPointer(0, 3, .float, false, 6 * @sizeOf(f32), 0);
    vao.enableVertexAttribute(0);

    // color attribute
    gl.vertexAttribPointer(1, 3, .float, false, 6 * @sizeOf(f32), 3 * @sizeOf(f32));
    vao.enableVertexAttribute(1);

    while (!window.shouldClose()) {
        // render here
        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(.{
            .color = true,
            .depth = true,
            .stencil = true,
        });

        shaderProgram.use();

        vao.bind();
        gl.drawArrays(.triangles, 0, 3);

        // swap front end back buffers
        window.swapBuffers();

        // poll for and process events
        glfw.pollEvents();
    }
}
