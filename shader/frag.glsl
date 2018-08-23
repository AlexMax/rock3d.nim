#version 330 core

uniform sampler2D uTexture;

in vec2 fTexCoord;

out vec4 fragColor;

void main()
{
    fragColor = texture(uTexture, fTexCoord);
}
