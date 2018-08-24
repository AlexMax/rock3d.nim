/*
 * vert.glsl
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
