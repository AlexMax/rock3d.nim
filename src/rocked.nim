# rocked.nim
# (C) 2018 Alex Mayfield <alexmax2742@gmail.com>
#
# This software is provided 'as-is', without any express or implied
# warranty.  In no event will the authors be held liable for any damages
# arising from the use of this software.
#
# Permission is granted to anyone to use this software for any purpose,
# including commercial applications, and to alter it and redistribute it
# freely, subject to the following restrictions:
#
# 1. The origin of this software must not be misrepresented; you must not
#    claim that you wrote the original software. If you use this software
#    in a product, an acknowledgment in the product documentation would be
#    appreciated but is not required.
# 2. Altered source versions must be plainly marked as such, and must not be
#    misrepresented as being the original software.
# 3. This notice may not be removed or altered from any source distribution.

import strformat

import glm, sdl2, texture

import atlas, camera, level, render

const ATLAS_SIZE = 512

# Initialize SDL2
if sdl2.init(sdl2.INIT_VIDEO) == sdl2.SdlError:
  echo "sdl2.init: " & $sdl2.getError()
  quit(QuitFailure)

# Create the window
var window = sdl2.createWindow("RockED", sdl2.SDL_WINDOWPOS_CENTERED,
  sdl2.SDL_WINDOWPOS_CENTERED, 800, 500, sdl2.SDL_WINDOW_OPENGL)
if window == nil:
  echo "sdl2.createWindow: " & $sdl2.getError()
  quit(QuitFailure)

# Create the OpenGL context
discard sdl2.glSetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3)
discard sdl2.glSetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3)
discard sdl2.glSetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE)

var context = sdl2.glCreateContext(window)
if context == nil:
  echo "sdl2.glCreateContext: " & $sdl2.getError()
  quit(QuitFailure)

var
  major: cint
  minor: cint
  profile: cint

discard sdl2.glGetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, major)
discard sdl2.glGetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, minor)
discard sdl2.glGetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, profile)

if (major == 3 and minor < 3) or (major < 3):
  echo "sdl2.glCreateContext: Couldn't get OpenGL 3.3 context"
  quit(QuitFailure)

if profile != SDL_GL_CONTEXT_PROFILE_CORE:
  echo "sdl2.glCreateContext: Couldn't get core profile"
  quit(QuitFailure)

echo &"Initialized OpenGL {major}.{minor}"

# A new renderer context
var renderer = newRenderContext()

# Load up a texture atlas
var wall = texture.loadPNGFile("texture/STARTAN3.png")
var floor = texture.loadPNGFile("texture/FLOOR4_8.png")
var ceiling = texture.loadPNGFile("texture/RROCK18.png")
var textures = atlas.newAtlas(ATLAS_SIZE)
textures.add(wall)
textures.add(floor)
textures.add(ceiling)

# Bake the texutre atlas into our renderer context
renderer.bakeAtlas(textures)

# This should probably be a function...
for index, line in level.lines:
  if isNil(line.back):
    # Single-sided line
    renderer.addWall(
      line.v1.x.float32, line.v1.y.float32, line.front.sector.floorHeight.float32,
      line.v2.x.float32, line.v2.y.float32, line.front.sector.ceilHeight.float32)
  else:
    # Double-sided line, upper wall
    if (line.front.sector.ceilHeight > line.back.sector.ceilHeight):
      # Draw on the front side of the line
      renderer.addWall(
        line.v1.x.float32, line.v1.y.float32, line.back.sector.ceilHeight.float32,
        line.v2.x.float32, line.v2.y.float32, line.front.sector.ceilHeight.float32)
    elif (line.back.sector.ceilHeight > line.front.sector.ceilHeight):
      # Draw on the back side of the line
      renderer.addWall(
        line.v2.x.float32, line.v2.y.float32, line.front.sector.ceilHeight.float32,
        line.v1.x.float32, line.v1.y.float32, line.back.sector.ceilHeight.float32)

    # Double-sided line, lower wall
    if (line.front.sector.floorHeight < line.back.sector.floorHeight):
      # Draw on the front side of the line
      renderer.addWall(
        line.v1.x.float32, line.v1.y.float32, line.front.sector.floorHeight.float32,
        line.v2.x.float32, line.v2.y.float32, line.back.sector.floorHeight.float32)
    elif (line.back.sector.floorHeight < line.front.sector.floorHeight):
      # Draw on the back side of the line
      renderer.addWall(
        line.v2.x.float32, line.v2.y.float32, line.back.sector.floorHeight.float32,
        line.v1.x.float32, line.v1.y.float32, line.front.sector.floorHeight.float32)

# Actually render the world
for index in countup(0, 360):
  var i: float = 0.0 + index.float

  var cam =  Camera(x: 0.0'f32, y: 448.0'f32, z: 48'f32, yaw: glm.radians(i))

  # Render the world from the camera's perspective
  renderer.render(cam)

  sdl2.glSwapWindow(window)

  sdl2.delay(16)
