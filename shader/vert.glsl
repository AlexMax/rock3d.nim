#version 330 core

layout (location = 0) in vec3 lPos;
layout (location = 1) in vec2 lAtlasCoord;
layout (location = 2) in vec2 lTexCoord;

uniform mat4 uView;
uniform mat4 uProjection;

out vec2 fTexCoord;

void main()
{
    gl_Position = uProjection * uView * vec4(lPos, 1.0);
    fTexCoord = lAtlasCoord;
}
