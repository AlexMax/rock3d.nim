# camera.nim
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

type
  Camera* = object
    x*: GLfloat
    y*: GLfloat
    z*: GLfloat
    yaw*: GLfloat

proc getViewMatrix*(cam: Camera): Mat4[GLfloat] =
  var cameraMat = glm.lookAt[GLfloat](
    vec3[GLfloat](0, 0, 0), # Position
    vec3[GLfloat](0, 1, 0), # Target
    vec3[GLfloat](0, 0, 1), # Up
  )
  cameraMat = glm.rotateZ(cameraMat, cam.yaw)
  cameraMat = glm.translate(cameraMat, vec3[GLfloat](-cam.x, -cam.y, -cam.z))
  return cameraMat
