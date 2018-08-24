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
  Vertex = object
    ## A single point in the map.
    x*: int32
    y*: int32

type
  Sector = object
    ## A room.
    ##
    ## In a software renderer, these rooms are "projected" from the walls.
    ceilHeight*: int32
    floorHeight*: int32

type
  Side = object
    ## One side of a wall or border.
    sector*: ptr Sector

type
  Line = object
    ## A wall or border between two rooms.
    ##
    ## Lines can either be one-sided or two-sided.  One-sided lines have
    ## a room on one side and are void on the other, thus they are solid
    ## walls.  Two-sided lines have a room on both sides, thus they act
    ## as a border between the two.
    v1*: ptr Vertex
    v2*: ptr Vertex
    front*: ptr Side
    back*: ptr Side

# A basic room with two sectors in it.

var vertexes*: seq[Vertex] = @[
  Vertex(x: -256'i32, y :512'i32), # Upper-left corner, going clockwise
  Vertex(x: 256'i32, y: 512'i32),
  Vertex(x: 256'i32, y: 64'i32),
  Vertex(x: 256'i32, y: -64'i32), # Lower-right corner
  Vertex(x: -256'i32, y: -64'i32),
  Vertex(x: -256'i32, y: 64'i32),
]

var sectors*: seq[Sector] = @[
  Sector(ceilHeight: 128'i32, floorHeight: 0'i32), # Main room
  Sector(ceilHeight: 96'i32, floorHeight: 32'i32), # Platform
]

var sides*: seq[Side] = @[
  Side(sector: addr sectors[0]), # Northern wall
  Side(sector: addr sectors[0]), # Eastern walls
  Side(sector: addr sectors[1]),
  Side(sector: addr sectors[1]), # Southern wall
  Side(sector: addr sectors[1]), # Western walls
  Side(sector: addr sectors[0]),
  Side(sector: addr sectors[0]), # Dividing wall
  Side(sector: addr sectors[1]),
]

var lines*: seq[Line] = @[
  Line(
    v1: addr vertexes[0],
    v2: addr vertexes[1],
    front: addr sides[0],
  ), # Northern wall
  Line(
    v1: addr vertexes[1],
    v2: addr vertexes[2],
    front: addr sides[1],
  ), # Eastern wall
  Line(
    v1: addr vertexes[2],
    v2: addr vertexes[3],
    front: addr sides[2],
  ), # Eastern wall
  Line(
    v1: addr vertexes[3],
    v2: addr vertexes[4],
    front: addr sides[3],
  ), # Southern wall
  Line(
    v1: addr vertexes[4],
    v2: addr vertexes[5],
    front: addr sides[4],
  ), # Western wall
  Line(
    v1: addr vertexes[5],
    v2: addr vertexes[0],
    front: addr sides[5],
  ), # Western wall
  Line(
    v1: addr vertexes[2],
    v2: addr vertexes[5],
    front: addr sides[6],
    back: addr sides[7],
  ), # Dividing wall
]
