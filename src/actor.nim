# actor.nim
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

import glm

import camera

type
  Actor* = object
    pos*: Vec3[float]
    yaw*: float
    viewHeight*: int

proc move*(act: var Actor, vel: float) =
  act.pos.x += glm.sin(act.yaw) * vel
  act.pos.y += glm.cos(act.yaw) * vel

proc getCamera*(act: var Actor): Camera =
  var cam = Camera(pos: act.pos, yaw: act.yaw)
  cam.pos.z += act.viewHeight.float
  return cam
