/*
 * frag.glsl
 * (C) 2018 Alex Mayfield <alexmax2742@gmail.com>
 *
 * This software is provided 'as-is', without any express or implied
 * warranty.  In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 */

#version 330 core

uniform sampler2D uTexture;

in vec4 fAtlasInfo;
in vec2 fTexCoord;

out vec4 fragColor;

float wrap(float coord, float origin, float len)
{
    // Scale the fragment up to a 0.0 through 1.0 range
    float x = (coord - origin) / len;

    // Get the fractional part
    x = fract(x);

    // Scale the fragment back down to its original range
    return (x * len) + origin;
}

void main()
{
    float uAtOrigin = fAtlasInfo.x;
    float vAtOrigin = fAtlasInfo.y;
    float uAtLen = fAtlasInfo.z;
    float vAtLen = fAtlasInfo.w;

    vec2 texCord;
    texCord.x = wrap(fTexCoord.x, uAtOrigin, uAtLen);
    texCord.y = wrap(fTexCoord.y, vAtOrigin, vAtLen);

    fragColor = texture(uTexture, texCord);
}
