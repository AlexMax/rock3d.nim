type
  Vertex = tuple
    ## A single point in the map.
    x: int32
    y: int32

type
  Sector = tuple
    ## A room.
    ##
    ## In a software renderer, these rooms are "projected" from the walls.
    ceilHeight: int32
    floorHeight: int32

type
  Side = tuple
    ## One side of a wall or border.
    sector: ptr Sector

type
  Line = tuple
    ## A wall or border between two rooms.
    ##
    ## Lines can either be one-sided or two-sided.  One-sided lines have
    ## a room on one side and are void on the other, thus they are solid
    ## walls.  Two-sided lines have a room on both sides, thus they act
    ## as a border between the two.
    v1: ptr Vertex
    v2: ptr Vertex
    front: ptr Side
    back: ptr Side

# A basic room with two sectors in it.

var vertexes*: seq[Vertex] = @[
  (-256'i32, 512'i32), # Upper-left corner, going clockwise
  (256'i32, 512'i32),
  (256'i32, 64'i32),
  (256'i32, -64'i32), # Lower-right corner
  (-256'i32, -64'i32),
  (-256'i32, 64'i32),
]

var sectors*: seq[Sector] = @[
  (ceilHeight: 128'i32, floorHeight: 0'i32), # Main room
  (ceilHeight: 128'i32, floorHeight: 32'i32), # Platform
]

var sides*: seq[Side] = @[
  (sector: addr sectors[0]), # Northern wall
  (sector: addr sectors[0]), # Eastern walls
  (sector: addr sectors[1]),
  (sector: addr sectors[1]), # Southern wall
  (sector: addr sectors[1]), # Western walls
  (sector: addr sectors[0]),
  (sector: addr sectors[0]), # Dividing wall
  (sector: addr sectors[1]),
]

var lines*: seq[Line] = @[
  (
    v1: addr vertexes[0],
    v2: addr vertexes[1],
    front: addr sides[0],
    back: cast[ptr Side](nil)
  ), # Northern wall
  (
    v1: addr vertexes[1],
    v2: addr vertexes[2],
    front: addr sides[1],
    back: cast[ptr Side](nil)
  ), # Eastern wall
  (
    v1: addr vertexes[2],
    v2: addr vertexes[3],
    front: addr sides[2],
    back: cast[ptr Side](nil)
  ), # Eastern wall
  (
    v1: addr vertexes[3],
    v2: addr vertexes[4],
    front: addr sides[3],
    back: cast[ptr Side](nil)
  ), # Southern wall
  (
    v1: addr vertexes[4],
    v2: addr vertexes[5],
    front: addr sides[4],
    back: cast[ptr Side](nil)
  ), # Western wall
  (
    v1: addr vertexes[5],
    v2: addr vertexes[0],
    front: addr sides[5],
    back: cast[ptr Side](nil)
  ), # Western wall
  (
    v1: addr vertexes[2],
    v2: addr vertexes[3],
    front: addr sides[6],
    back: addr sides[7],
  ), # Dividing wall
]
