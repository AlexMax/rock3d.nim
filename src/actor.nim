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

import strformat

import glm

import camera

type
  Actor* = object
    pos*: Vec3[float]
    yaw*: float
    viewHeight*: int

proc `$`*(act: Actor): string =
  var yaw = glm.degrees(act.yaw)
  return &"x: {act.pos.x}, y: {act.pos.y}, z: {act.pos.z}, yaw: {yaw}"

proc move*(act: var Actor, vel: float) =
  # Move the actor forwards or backwards
  act.pos.x += sin(act.yaw) * vel
  act.pos.y += cos(act.yaw) * vel

proc strafe*(act: var Actor, vel: float) =
  # Move the actor side to side
  var angle90 = PI / 2.0
  act.pos.x += sin(act.yaw + angle90) * vel
  act.pos.y += cos(act.yaw + angle90) * vel

proc getCamera*(act: var Actor): Camera =
  var cam = Camera(pos: act.pos, yaw: act.yaw)
  cam.pos.z += act.viewHeight.float
  return cam
