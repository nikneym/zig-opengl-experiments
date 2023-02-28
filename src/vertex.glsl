#version 330 core
layout (location = 0) in vec3 aPos; // position variable has attribute position 0
layout (location = 1) in vec3 aColor; // color variable has attribute position 1
layout (location = 2) in vec2 aTexCoord; // tex coord variable has attribute position 2

out vec3 ourColor;
out vec2 TexCoord;

void main() {
   gl_Position = vec4(aPos, 1.0);
   ourColor = aColor;
   TexCoord = vec2(aTexCoord.x, aTexCoord.y);
};
