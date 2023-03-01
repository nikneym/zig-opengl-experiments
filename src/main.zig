const std = @import("std");
const glfw = @import("glfw");
const gl = @import("zgl");
const zstbi = @import("zstbi");

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

    zstbi.init(allocator);
    defer zstbi.deinit();
    zstbi.setFlipVerticallyOnLoad(true);

    // FIXME: do not handle nullables like this
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

    // Vertex Array Object
    var vao = gl.VertexArray.gen();
    defer vao.delete();
    vao.bind();

    // Vertex Buffer Object
    var vbo = gl.Buffer.gen();
    defer vbo.delete();
    vbo.bind(.array_buffer);
    vbo.data(f32, &[_]f32{
    // positions       // colors        // texture coords
     0.5,  0.5, 0.0,   1.0, 0.0, 0.0,   1.0, 1.0,   // top right
     0.5, -0.5, 0.0,   0.0, 1.0, 0.0,   1.0, 0.0,   // bottom right
    -0.5, -0.5, 0.0,   0.0, 0.0, 1.0,   0.0, 0.0,   // bottom left
    -0.5,  0.5, 0.0,   1.0, 1.0, 0.0,   0.0, 1.0    // top left 
    }, .static_draw);

    var ebo = gl.Buffer.gen();
    defer ebo.delete();
    ebo.bind(.element_array_buffer);
    ebo.data(u8, &[_]u8{
        0, 1, 3,
        1, 2, 3,
    }, .static_draw);

    // position attribute
    gl.vertexAttribPointer(0, 3, .float, false, 8 * @sizeOf(f32), 0);
    vao.enableVertexAttribute(0);

    // color attribute
    gl.vertexAttribPointer(1, 3, .float, false, 8 * @sizeOf(f32), 3 * @sizeOf(f32));
    vao.enableVertexAttribute(1);

    // tex coord attribute
    gl.vertexAttribPointer(2, 2, .float, false, 8 * @sizeOf(f32), 6 * @sizeOf(f32));
    vao.enableVertexAttribute(2);

    var texture = gl.genTexture();
    gl.activeTexture(.texture_0);
    texture.bind(.@"2d");

    // set wrapping parameters
    gl.texParameter(.@"2d", .wrap_s, .mirrored_repeat);
    gl.texParameter(.@"2d", .wrap_t, .mirrored_repeat);
    // set filtering parameters
    gl.texParameter(.@"2d", .min_filter, .linear_mipmap_linear);
    gl.texParameter(.@"2d", .mag_filter, .linear);

    var image = try zstbi.Image.loadFromFile("asset/wall.jpg", 3);
    gl.textureImage2D(.@"2d", 0, .rgb, image.width, image.height, .rgb, .unsigned_byte, @ptrCast([*]const u8, image.data));
    gl.generateMipmap(.@"2d");
    image.deinit();

    var texture2 = gl.genTexture();
    gl.activeTexture(.texture_1);
    texture2.bind(.@"2d");

    // set wrapping parameters
    gl.texParameter(.@"2d", .wrap_s, .mirrored_repeat);
    gl.texParameter(.@"2d", .wrap_t, .mirrored_repeat);
    // set filtering parameters
    gl.texParameter(.@"2d", .min_filter, .linear_mipmap_linear);
    gl.texParameter(.@"2d", .mag_filter, .linear);

    var image2 = try zstbi.Image.loadFromFile("asset/awesomeface.png", 0);
    defer image2.deinit();
    gl.textureImage2D(.@"2d", 0, .rgba, image2.width, image2.height, .rgba, .unsigned_byte, @ptrCast([*]const u8, image2.data));
    gl.generateMipmap(.@"2d");

    shaderProgram.use();
    gl.uniform1i(gl.getUniformLocation(shaderProgram, "texture1"), 0);
    gl.uniform1i(gl.getUniformLocation(shaderProgram, "texture2"), 1);

    while (!window.shouldClose()) {
        // render here
        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(.{
            .color = true,
            .depth = true,
            .stencil = true,
        });

        gl.activeTexture(.texture_0);
        texture.bind(.@"2d");
        gl.activeTexture(.texture_1);
        texture2.bind(.@"2d");

        shaderProgram.use();
        vao.bind();
        gl.drawElements(.triangles, 6, .u8, 0);

        // swap front end back buffers
        window.swapBuffers();

        // poll for and process events
        glfw.pollEvents();
    }
}
