# render.nim
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

import glm, opengl

import atlas, camera

const ATLAS_SIZE = 512

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

type
  Vertex = object
    ## A vertex currently consists of its location in space and some texture
    ## coordinates.
    ##
    ## The atlas coordinates are used to select the proper texture out of
    ## the atlas.  The tex coordinates are relative to the actual texture
    ## itself, ignoring its position in the atlas.
    x: GLfloat
    y: GLfloat
    z: GLfloat
    uAtOrigin: GLfloat
    vAtOrigin: GLfloat
    uAtLen: GLfloat
    vAtLen: GLfloat
    uTex: GLfloat
    vTex: GLfloat
  RenderContext = object
    ## Holds everything related to the OpenGL renderer.
    worldProg: Program
    worldVAO: GLuint
    worldAtlas: Atlas
    worldTexAtlas: GLuint
    worldVerts: seq[Vertex]
    worldInds: seq[GLuint]
    worldProject: Mat4[GLfloat]

proc initWorldRenderer(ctx: var RenderContext) =
  # Initialize the renderer of the 3D world
  #
  # This is where anything having to do with rendering the 3D world is set
  # up.  It's called by newRenderContext, you will never need to call this
  # yourself.

  # 3D shader program, used for rendering walls, floors and ceilings.
  const vert: string = staticRead("shader/vert.glsl")
  var vs = newShader(GL_VERTEX_SHADER, vert)

  const frag: string = staticRead("shader/frag.glsl")
  var fs = newShader(GL_FRAGMENT_SHADER, frag)

  ctx.worldProg = newProgram(@[vs, fs])

  # We need a vertex array...
  glGenVertexArrays(1, addr ctx.worldVAO)
  glBindVertexArray(ctx.worldVAO)

  # ...a vertex buffer...
  var vbo: GLuint
  glGenBuffers(1, addr vbo)
  glBindBuffer(GL_ARRAY_BUFFER, vbo)
  ctx.worldVerts = @[]

  # ...and an index buffer.
  var ebo: GLuint
  glGenBuffers(1, addr ebo)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo)
  ctx.worldInds = @[]

  # Layout of our vertexes, as passed to the vertex shader.
  # x, y, and z positions.
  glVertexAttribPointer(0, 3, cGL_FLOAT, GL_FALSE, 9 * sizeof(GLfloat), cast[pointer](0))
  glEnableVertexAttribArray(0);
  # u and v texture coordinates for the texture atlas.
  glVertexAttribPointer(1, 4, cGL_FLOAT, GL_FALSE, 9 * sizeof(GLfloat), cast[pointer](3 * sizeof(GLfloat)))
  glEnableVertexAttribArray(1);
  # u and v texture coordinates for the texture itself.
  glVertexAttribPointer(2, 2, cGL_FLOAT, GL_FALSE, 9 * sizeof(GLfloat), cast[pointer](7 * sizeof(GLfloat)))
  glEnableVertexAttribArray(2);

  # Unbind the array so we don't change it on accident
  glBindVertexArray(0)

  # Set up the texture atlas texture
  glGenTextures(1, addr ctx.worldTexAtlas)
  glBindTexture(GL_TEXTURE_2D, ctx.worldTexAtlas)

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)

  # Assign the texture atlas to the world program
  glUseProgram(ctx.worldProg.GLuint)
  var textureLoc = glGetUniformLocation(ctx.worldProg.GLuint, "uTexture")
  glUniform1i(textureLoc, 0);

  # Upload a blank texture to the atlas
  var blankAtlasTex: array[ATLAS_SIZE * ATLAS_SIZE * 4, GLubyte]
  for i in countup(0, blankAtlasTex.len - 1, 4):
    blankAtlasTex[i] = 255;
    blankAtlasTex[i + 1] = 0;
    blankAtlasTex[i + 2] = 255;
    blankAtlasTex[i + 3] = 255;

  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.GLint, ATLAS_SIZE, ATLAS_SIZE, 0, GL_RGBA, GL_UNSIGNED_BYTE, addr blankAtlasTex[0])

proc setProject*(ctx: var RenderContext, fov: float) =
  # Setup the projection matrix
  ctx.worldProject = glm.perspective[GLfloat](glm.radians(fov), 800.0 / 500.0, 0.1, 1024.0)

  # Make sure our projection matrix goes into the shader program
  var projectionLoc = glGetUniformLocation(ctx.worldProg.GLuint, "uProjection")
  glUniformMatrix4fv(projectionLoc, 1, GL_FALSE, ctx.worldProject.caddr)

proc newRenderContext*(): RenderContext =
  var ctx: RenderContext

  opengl.loadExtensions()

  glEnable(GL_CULL_FACE)
  #glPolygonMode( GL_FRONT_AND_BACK, GL_LINE )

  glEnable(GL_DEPTH_TEST)

  ctx.initWorldRenderer()

  ctx.setProject(90.0)

  return ctx

proc addWall*(ctx: var RenderContext, x1, y1, z1, x2, y2, z2: float32, tex: string) =
  ## Add a wall to the set of things to render
  ##
  ## Note that we need a working texture atlas at this point, otherwise
  ## we have no clue what the texture coordinates need to be.

  # Find the texture of the wall in the atlas
  var texEntry = ctx.worldAtlas.find(tex)
  var ua1 = texEntry.xPos.GLfloat / ctx.worldAtlas.length.GLfloat
  var va1 = texEntry.yPos.GLfloat / ctx.worldAtlas.length.GLfloat
  var ua2 = GLfloat(texEntry.xPos + texEntry.texture.width) / ctx.worldAtlas.length.GLfloat
  var va2 = GLfloat(texEntry.yPos + texEntry.texture.height) / ctx.worldAtlas.length.GLfloat

  var hDist = glm.length(vec2(x1, y1) - vec2(x2, y2))
  var vDist = z2 - z1

  var ut1 = 0.0
  var vt1 = 0.0
  var ut2 = hDist / texEntry.texture.width.float32
  var vt2 = vDist / texEntry.texture.height.float32

  ## Draw a wall into the vertex and index buffers.
  ##
  ## Assuming you want to face the square head-on, xyz1 is the lower-left
  ## coordinate and xyz2 is the upper-right coordinate.
  var off = len(ctx.worldVerts).GLuint

  ctx.worldVerts.add(Vertex(x: x1.GLfloat, y: y1.GLfloat, z: z1.GLfloat,
    uAtOrigin: ua1, vAtOrigin: va1, uAtLen: ua2 - ua1, vAtLen: va2 - va1,
    uTex: ut1, vTex: vt2))
  ctx.worldVerts.add(Vertex(x: x2.GLfloat, y: y2.GLfloat, z: z1.GLfloat,
    uAtOrigin: ua1, vAtOrigin: va1, uAtLen: ua2 - ua1, vAtLen: va2 - va1,
    uTex: ut2, vTex: vt2))
  ctx.worldVerts.add(Vertex(x: x2.GLfloat, y: y2.GLfloat, z: z2.GLfloat,
    uAtOrigin: ua1, vAtOrigin: va1, uAtLen: ua2 - ua1, vAtLen: va2 - va1,
    uTex: ut2, vTex: vt1))
  ctx.worldVerts.add(Vertex(x: x1.GLfloat, y: y1.GLfloat, z: z2.GLfloat,
    uAtOrigin: ua1, vAtOrigin: va1, uAtLen: ua2 - ua1, vAtLen: va2 - va1,
    uTex: ut1, vTex: vt1))

  ctx.worldInds.add(off + 0)
  ctx.worldInds.add(off + 1)
  ctx.worldInds.add(off + 2)
  ctx.worldInds.add(off + 2)
  ctx.worldInds.add(off + 3)
  ctx.worldInds.add(off + 0)

proc addFlatTessellation*(ctx: var RenderContext, verts: seq[float32], inds: seq[int32],
                          z: float32, tex: string) =
  ## Add a flat floor or ceiling tessellation to the set of things to render

  # Find the texture of the wall in the atlas
  var texEntry = ctx.worldAtlas.find(tex)
  var ua1 = texEntry.xPos.GLfloat / ctx.worldAtlas.length.GLfloat
  var va1 = texEntry.yPos.GLfloat / ctx.worldAtlas.length.GLfloat
  var ua2 = GLfloat(texEntry.xPos + texEntry.texture.width) / ctx.worldAtlas.length.GLfloat
  var va2 = GLfloat(texEntry.yPos + texEntry.texture.height) / ctx.worldAtlas.length.GLfloat

  # Draw the triangle into the buffers.
  var off = len(ctx.worldVerts).GLuint

  for i in countup(0, verts.len - 1, 2):
    var ut = verts[i].GLfloat / texEntry.texture.width.GLfloat
    var vt = -(verts[i+1].GLfloat / texEntry.texture.height.GLfloat)

    ctx.worldVerts.add(Vertex(x: verts[i].GLfloat, y: verts[i+1].GLfloat, z: z.GLfloat,
      uAtOrigin: ua1, vAtOrigin: va1, uAtLen: ua2 - ua1, vAtLen: va2 - va1,
      uTex: ut, vTex: vt))

  for ind in inds:
    ctx.worldInds.add(off + ind.GLuint)

proc bakeAtlas*(ctx: var RenderContext, textures: Atlas) =
  # Copy the texture atlas into the render context
  ctx.worldAtlas = textures

  # Get the texture atlas onto the GPU
  persist(ctx.worldAtlas, proc (data: pointer, x, y, w, h: uint32) =
    glTexSubImage2D(GL_TEXTURE_2D, 0, x.GLint, y.GLint, w.GLint, h.GLint, GL_RGBA, GL_UNSIGNED_BYTE, data)
  )

proc render*(ctx: var RenderContext, cam: Camera) =
  # Render the world

  # Clear the buffer
  glClearColor(0.0, 0.4, 0.4, 1.0)
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

  # Use the world program
  glUseProgram(ctx.worldProg.GLuint)

  # Bind our camera data
  var view = cam.getViewMatrix
  var viewLoc = glGetUniformLocation(ctx.worldProg.GLuint, "uView")
  glUniformMatrix4fv(viewLoc, 1, GL_FALSE, view.caddr)

  # Bind the proper texture unit for our atlas
  glActiveTexture(GL_TEXTURE0)
  glBindTexture(GL_TEXTURE_2D, ctx.worldTexAtlas)

  # Load our data into the VAO
  glBindVertexArray(ctx.worldVAO)

  glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * 9 * len(ctx.worldVerts), addr ctx.worldVerts[0], GL_STATIC_DRAW)
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLuint) * len(ctx.worldInds), addr ctx.worldInds[0], GL_STATIC_DRAW)

  # Draw everything
  glDrawElements(GL_TRIANGLES, len(ctx.worldInds).GLsizei, GL_UNSIGNED_INT, nil)

proc eraseGeometry*(ctx: var RenderContext) =
  # Clear our vertexes and indexes
  ctx.worldVerts.setLen(0)
  ctx.worldInds.setLen(0)
