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

var
  vertexes: seq[GLfloat] = @[]
  indexes: seq[GLuint] = @[]

proc drawWall(verts: var seq[GLfloat], inds: var seq[GLuint], x1, y1, z1, x2, y2, z2: GLfloat) =
  ## Draw a wall into the passed vertex and index buffers.
  ##
  ## Assuming you want to face the square head-on, xyz1 is the lower-left
  ## coordinate and xyz2 is the upper-right coordinate.
  var off = len(verts).GLuint div 5

  verts.add(x1); verts.add(y1); verts.add(z1)
  verts.add(0.0); verts.add(1.0)
  verts.add(x2); verts.add(y2); verts.add(z1)
  verts.add(1.0); verts.add(1.0)
  verts.add(x2); verts.add(y2); verts.add(z2)
  verts.add(1.0); verts.add(0.0)
  verts.add(x1); verts.add(y1); verts.add(z2)
  verts.add(0.0); verts.add(0.0)

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
glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * len(vertexes), addr vertexes[0], GL_STATIC_DRAW)

var ebo: GLuint
glGenBuffers(1, addr ebo)
glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo)
glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLuint) * len(indexes), addr indexes[0], GL_STATIC_DRAW)

glVertexAttribPointer(0, 3, cGL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), cast[pointer](0))
glEnableVertexAttribArray(0);
glVertexAttribPointer(1, 2, cGL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), cast[pointer](3 * sizeof(GLfloat)))
glEnableVertexAttribArray(1);

glBindVertexArray(0)

var wall = texture.loadPNGFile("texture/STARTAN3.png")
var floor = texture.loadPNGFile("texture/FLOOR4_8.png")
var ceiling = texture.loadPNGFile("texture/RROCK18.png")
var textures = atlas.newAtlas(2048)
textures.add(wall)
textures.add(floor)
textures.add(ceiling)

echo $textures

var texAtlas: GLuint;
glGenTextures(1, addr texAtlas)

var myTex: array[4 * 9, GLubyte] = [
    255'u8, 0'u8, 0'u8, 255'u8, 0'u8, 0'u8, 0'u8, 255'u8, 0'u8, 255'u8, 0'u8, 255'u8,
    0'u8, 0'u8, 0'u8, 255'u8, 0'u8, 0'u8, 0'u8, 255'u8, 0'u8, 0'u8, 0'u8, 255'u8,
    0'u8, 0'u8, 255'u8, 255'u8, 0'u8, 0'u8, 0'u8, 255'u8, 0'u8, 0'u8, 0'u8, 255'u8
]

# Upload a blank texture that we can use to apply our atlas to
glBindTexture(GL_TEXTURE_2D, texAtlas)

glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)

glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.GLint, 3, 3, 0, GL_RGBA, GL_UNSIGNED_BYTE, addr myTex[0])

glUseProgram(prog.GLuint)
var textureLoc = glGetUniformLocation(prog.GLuint, "uTexture")
glUniform1i(textureLoc, 0);

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
