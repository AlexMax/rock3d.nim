# level.nim
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

type
  Vertex = ref object
    ## A single point in the map.
    x*: int32
    y*: int32
    lineCache*: seq[Line]
  Sector = ref object
    ## A room.
    ##
    ## In a software renderer, these rooms are "projected" from the walls.
    ceilHeight*: int32
    floorHeight*: int32
    sideCache*: seq[Side]
  Side* = ref object
    ## One side of a wall or border.
    sector*: Sector
    lineCache*: Line
  Line = ref object
    ## A wall or border between two rooms.
    ##
    ## Lines can either be one-sided or two-sided.  One-sided lines have
    ## a room on one side and are void on the other, thus they are solid
    ## walls.  Two-sided lines have a room on both sides, thus they act
    ## as a border between the two.
    v1*: Vertex
    v2*: Vertex
    front*: Side
    back*: Side
  Level = object
    vertexes*: seq[Vertex]
    sectors*: seq[Sector]
    sides*: seq[Side]
    lines*: seq[Line]

proc newLevel*(): Level =
  return Level(vertexes: @[], sectors: @[], sides: @[],lines: @[])

proc addVertex*(level: var Level, x, y: int32) =
  level.vertexes.add(Vertex(x: x, y: y))

proc addSector*(level: var Level, ceilHeight, floorHeight: int32) =
  level.sectors.add(Sector(ceilHeight: ceilHeight, floorHeight: floorHeight))

proc addSide*(level: var Level, secNo: int) =
  if secNo >= level.sectors.len:
    raise newException(IndexError, "Sector does not exist in new Side")

  var s = Side(sector: level.sectors[secNo])
  s.sector.sideCache.safeAdd(s)

  level.sides.add(s)

proc addLine*(level: var Level, v1No, v2No, frontNo: int, backNo = -1) =
  if v1No >= level.vertexes.len:
    raise newException(IndexError, "Vertex 1 does not exist in new Line")
  if v2No >= level.vertexes.len:
    raise newException(IndexError, "Vertex 2 does not exist in new Line")
  if frontNo >= level.sides.len:
    raise newException(IndexError, "Frontside does not exist in new Line")

  var s2: Side = nil
  if backNo != -1:
    if backNo >= level.sides.len:
      raise newException(IndexError, "Backside does not exist in new Line")
    s2 = level.sides[backNo]

  var l = Line(
    v1: level.vertexes[v1No],
    v2: level.vertexes[v2No],
    front: level.sides[frontNo],
    back: s2)

  l.v1.lineCache.safeAdd(l)
  l.v2.lineCache.safeAdd(l)
  l.front.lineCache = l
  if not s2.isNil:
    l.back.lineCache = l

  level.lines.add(l)

# A basic room with two sectors in it.

var demo* = newLevel()

demo.addVertex(x = -256'i32, y = 512'i32) # Upper-left corner, going clockwise
demo.addVertex(x = 256'i32, y = 512'i32)
demo.addVertex(x = 256'i32, y = 64'i32)
demo.addVertex(x = 256'i32, y = -64'i32) # Lower-right corner
demo.addVertex(x = -256'i32, y = -64'i32)
demo.addVertex(x = -256'i32, y = 64'i32)

demo.addSector(ceilHeight = 128'i32, floorHeight = 0'i32) # Main room
demo.addSector(ceilHeight = 96'i32, floorHeight = 32'i32) # Platform

demo.addSide(secNo = 0) # Northern wall
demo.addSide(secNo = 0) # Eastern walls
demo.addSide(secNo = 1)
demo.addSide(secNo = 1) # Southern wall
demo.addSide(secNo = 1) # Western walls
demo.addSide(secNo = 0)
demo.addSide(secNo = 0) # Dividing wall
demo.addSide(secNo = 1)

demo.addLine(v1No = 0, v2No = 1, frontNo = 0) # Northern wall
demo.addLine(v1No = 1, v2No = 2, frontNo = 1) # Eastern wall
demo.addLine(v1No = 2, v2No = 3, frontNo = 2) # Eastern wall
demo.addLine(v1No = 3, v2No = 4, frontNo = 3) # Southern wall
demo.addLine(v1No = 4, v2No = 5, frontNo = 4) # Western wall
demo.addLine(v1No = 5, v2No = 0, frontNo = 5) # Western wall
demo.addLine(v1No = 2, v2No = 5, frontNo = 6, backNo = 7) # Dividing wall
