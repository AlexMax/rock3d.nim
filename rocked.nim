import strformat, strutils

import opengl, glm, sdl2

import atlas, camera, level, texture

type Shader = distinct GLuint
type Program = distinct GLuint

proc newShader(stype: GLenum, source: string): Shader =
  var str: array[1, string] = [source]
  var cs = allocCStringArray(str)
  defer: deallocCStringArray(cs)

  var shader = glCreateShader(stype)
  glShaderSource(shader, GLsizei(1), cs, nil)
  glCompileShader(shader)

  var status: GLint
  glGetShaderiv(shader, GL_COMPILE_STATUS, addr status)

  if status == GL_FALSE.GLint:
    var len: GLint
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, addr len)

    var log: cstring = cast[cstring](alloc(len))
    glGetShaderInfoLog(shader, len, nil, log)
    var err = "Shader compile error\n" & $log
    dealloc(log)
    raise newException(Exception, err)

  return shader.Shader

proc newProgram(shaders: openArray[Shader]): Program =
  var program = glCreateProgram()
  for shader in shaders:
    glAttachShader(program, shader.GLuint)
  glLinkProgram(program)

  var status: GLint
  glGetProgramiv(program, GL_LINK_STATUS, addr status)

  if status == GL_FALSE.GLint:
    raise newException(Exception, "Link Error")

  return program.Program

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

opengl.loadExtensions()

#glEnable(GL_CULL_FACE)
#glPolygonMode( GL_FRONT_AND_BACK, GL_LINE )

# Put the shader together
const vert: string = staticRead("shader/vert.glsl")
var vs = newShader(GL_VERTEX_SHADER, vert)

const frag: string = staticRead("shader/frag.glsl")
var fs = newShader(GL_FRAGMENT_SHADER, frag)

var prog = newProgram(@[vs, fs])

# Assemble the texture atlas so we know which texture coordinates
# to point our vertex generator towards
const atlasSize = 512

var wall = texture.loadPNGFile("texture/STARTAN3.png")
var floor = texture.loadPNGFile("texture/FLOOR4_8.png")
var ceiling = texture.loadPNGFile("texture/RROCK18.png")
var textures = atlas.newAtlas(atlasSize)
textures.add(wall)
textures.add(floor)
textures.add(ceiling)

type
  Vertex = object
    x: GLfloat
    y: GLfloat
    z: GLfloat
    uAtlas: GLfloat
    vAtlas: GLfloat
    uTex: GLfloat
    vTex: GLfloat
## A vertex currently consists of its location in space and some texture
## coordinates.
##
## The atlas coordinates are used to select the proper texture out of the
## atlas.  The tex coordinates are relative to the actual texture itself,
## ignoring its position in the atlas.

var
  vertexes: seq[Vertex] = @[]
  indexes: seq[GLuint] = @[]

proc drawWall(verts: var seq[Vertex], inds: var seq[GLuint], x1, y1, z1, x2, y2, z2: GLfloat) =
  # Find the texture of the wall in the atlas
  var texEntry = textures.find("STARTAN3")
  var ua1 = texEntry.xPos.GLfloat / textures.length.GLfloat
  var va1 = texEntry.yPos.GLfloat / textures.length.GLfloat
  var ua2 = GLfloat(texEntry.xPos + texEntry.texture.width) / textures.length.GLfloat
  var va2 = GLfloat(texEntry.yPos + texEntry.texture.height) / textures.length.GLfloat

  ## Draw a wall into the passed vertex and index buffers.
  ##
  ## Assuming you want to face the square head-on, xyz1 is the lower-left
  ## coordinate and xyz2 is the upper-right coordinate.
  var off = len(verts).GLuint

  verts.add(Vertex(x: x1, y: y1, z: z1,
    uAtlas: ua1, vAtlas: va2, uTex: 0.0, vTex: 1.0))
  verts.add(Vertex(x: x2, y: y2, z: z1,
    uAtlas: ua2, vAtlas: va2, uTex: 1.0, vTex: 1.0))
  verts.add(Vertex(x: x2, y: y2, z: z2,
    uAtlas: ua2, vAtlas: va1, uTex: 1.0, vTex: 0.0))
  verts.add(Vertex(x: x1, y: y1, z: z2,
    uAtlas: ua1, vAtlas: va1, uTex: 0.0, vTex: 0.0))

  inds.add(off + 0)
  inds.add(off + 1)
  inds.add(off + 2)
  inds.add(off + 2)
  inds.add(off + 3)
  inds.add(off + 0)

for index, line in level.lines:
  if isNil(line.back):
    # Single-sided line
    drawWall(vertexes, indexes,
      line.v1.x.GLfloat, line.v1.y.GLfloat, line.front.sector.floorHeight.GLfloat,
      line.v2.x.GLfloat, line.v2.y.GLfloat, line.front.sector.ceilHeight.GLfloat)
  else:
    # Double-sided line, upper wall
    if (line.front.sector.ceilHeight > line.back.sector.ceilHeight):
      # Draw on the front side of the line
      drawWall(vertexes, indexes,
        line.v1.x.GLfloat, line.v1.y.GLfloat, line.back.sector.ceilHeight.GLfloat,
        line.v2.x.GLfloat, line.v2.y.GLfloat, line.front.sector.ceilHeight.GLfloat)
    elif (line.back.sector.ceilHeight > line.front.sector.ceilHeight):
      # Draw on the back side of the line
      drawWall(vertexes, indexes,
        line.v2.x.GLfloat, line.v2.y.GLfloat, line.front.sector.ceilHeight.GLfloat,
        line.v1.x.GLfloat, line.v1.y.GLfloat, line.back.sector.ceilHeight.GLfloat)

    # Double-sided line, lower wall
    if (line.front.sector.floorHeight < line.back.sector.floorHeight):
      # Draw on the front side of the line
      drawWall(vertexes, indexes,
        line.v1.x.GLfloat, line.v1.y.GLfloat, line.front.sector.floorHeight.GLfloat,
        line.v2.x.GLfloat, line.v2.y.GLfloat, line.back.sector.floorHeight.GLfloat)
    elif (line.back.sector.floorHeight < line.front.sector.floorHeight):
      # Draw on the back side of the line
      drawWall(vertexes, indexes,
        line.v2.x.GLfloat, line.v2.y.GLfloat, line.back.sector.floorHeight.GLfloat,
        line.v1.x.GLfloat, line.v1.y.GLfloat, line.front.sector.floorHeight.GLfloat)

var vao: GLuint
glGenVertexArrays(1, addr vao)
glBindVertexArray(vao)

var vbo: GLuint
glGenBuffers(1, addr vbo)
glBindBuffer(GL_ARRAY_BUFFER, vbo)
glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * 7 * len(vertexes), addr vertexes[0], GL_STATIC_DRAW)

var ebo: GLuint
glGenBuffers(1, addr ebo)
glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo)
glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLuint) * len(indexes), addr indexes[0], GL_STATIC_DRAW)

glVertexAttribPointer(0, 3, cGL_FLOAT, GL_FALSE, 7 * sizeof(GLfloat), cast[pointer](0))
glEnableVertexAttribArray(0);
glVertexAttribPointer(1, 2, cGL_FLOAT, GL_FALSE, 7 * sizeof(GLfloat), cast[pointer](3 * sizeof(GLfloat)))
glEnableVertexAttribArray(1);
glVertexAttribPointer(2, 2, cGL_FLOAT, GL_FALSE, 7 * sizeof(GLfloat), cast[pointer](5 * sizeof(GLfloat)))
glEnableVertexAttribArray(2);

glBindVertexArray(0)

echo $textures

var texAtlas: GLuint;
glGenTextures(1, addr texAtlas)

# Upload a blank texture that we can use to apply our atlas to
var blankAtlasTex: array[atlasSize * atlasSize * 4, GLubyte]
for i in countup(0, blankAtlasTex.len - 1, 4):
  blankAtlasTex[i] = 255;
  blankAtlasTex[i + 1] = 0;
  blankAtlasTex[i + 2] = 255;
  blankAtlasTex[i + 3] = 255;

glBindTexture(GL_TEXTURE_2D, texAtlas)

glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)

glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.GLint, atlasSize, atlasSize, 0, GL_RGBA, GL_UNSIGNED_BYTE, addr blankAtlasTex[0])

glUseProgram(prog.GLuint)
var textureLoc = glGetUniformLocation(prog.GLuint, "uTexture")
glUniform1i(textureLoc, 0);

# Get the texture atlas onto the GPU
persist(textures, proc (data: pointer, x, y, w, h: uint32) =
  glTexSubImage2D(GL_TEXTURE_2D, 0, x.GLint, y.GLint, w.GLint, h.GLint, GL_RGBA, GL_UNSIGNED_BYTE, data)
)

for index in countup(0, 360):
  var i: GLfloat = 0.0 + index.GLfloat

  var cam =  Camera(x: 0.0'f32, y: 448.0'f32, z: 48'f32, yaw: glm.radians(i))
  var view = cam.getViewMatrix

  var projection = glm.perspective[GLfloat](glm.radians(90.0), 800.0 / 500.0, 0.1, 1024.0)

  # Render
  glClearColor(0.0, 0.4, 0.4, 1.0)
  glClear(GL_COLOR_BUFFER_BIT)

  glUseProgram(prog.GLuint)

  var viewLoc = glGetUniformLocation(prog.GLuint, "uView")
  glUniformMatrix4fv(viewLoc, 1, GL_FALSE, view.caddr)

  var projectionLoc = glGetUniformLocation(prog.GLuint, "uProjection")
  glUniformMatrix4fv(projectionLoc, 1, GL_FALSE, projection.caddr)

  glActiveTexture(GL_TEXTURE0)
  glBindTexture(GL_TEXTURE_2D, texAtlas)

  glBindVertexArray(vao)
  glDrawElements(GL_TRIANGLES, len(indexes).GLsizei, GL_UNSIGNED_INT, nil)

  sdl2.glSwapWindow(window)

  sdl2.delay(16)
