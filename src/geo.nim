# geo.nim
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

import level

type
  Polygon* = seq[Vec2[int32]]
    ## A polygon is a sequence of vertexes that results in a closed shape
    ##
    ## The shape does not necessarily need to be convex, but a polygon object
    ## does not contain holes, and is not disjointed.  The first and last
    ## vertex are the same.
  Segment = object
    v1: Vec2[int32]
    v2: Vec2[int32]
    dirty: bool

proc newPolygon*(): Polygon =
  ## Create a new Polygon
  return @[]

proc toPolygons*(sec: level.Sector): seq[Polygon] =
  ## Turns sector data into a set seq of polygons
  ##
  ## TODO: Handle more than one polygon.  Need some map data for that.
  ##
  ## - The initial ordering of segments is expected to be random.
  ## - If there is more than one closed polygon found, return all polygons.
  ## - All polygons in the sector must be closed.  If there is a stray line
  ##   somewhere, you get nothing, you lose, good day sir.
  ## - The winding order of lines in map data is clockwise, since that's
  ##   how Doom was and it's easier for humans to reason about.  However,
  ##   the default winding order of both libtess2 and OpenGL are
  ##   counter-clockwise, so the traversal of lines has to be backwards.
  var ret: seq[Polygon] = @[]

  if sec.sideCache.len < 3:
    # There can't possibly be any polygons...
    return ret

  # Turn sides into segments.
  var segs: seq[Segment] = @[]
  for side in sec.sideCache:
    # Is this side on the front of the parent line?
    if side == side.lineCache.front:
      # Yep, flip the ordering so the segment is counter-clockwise.
      segs.add(Segment(
        v1: vec2(side.lineCache.v2.x, side.lineCache.v2.y),
        v2: vec2(side.lineCache.v1.x, side.lineCache.v1.y),
        dirty: false
      ))
    else:
      # Nope, the ordering is actually correct in this case.
      segs.add(Segment(
        v1: vec2(side.lineCache.v1.x, side.lineCache.v1.y),
        v2: vec2(side.lineCache.v2.x, side.lineCache.v2.y),
        dirty: false
      ))

  # Now that we have segments, turn them into polygons.

  var poly = newPolygon()
  poly.add(vec2(segs[0].v1.x, segs[0].v1.y))

  var origin = 0 # Where the origin is
  var where = 0 # Where our rover is right now
  while true:
    var started = where
    for index, seg in segs:
      if index == where:
        continue
      if seg.dirty == true:
        continue
      if seg.v1.x != segs[where].v2.x:
        continue
      if seg.v1.y != segs[where].v2.y:
        continue

      # Found the matching seg, add it to the polygon and stop.
      poly.add(vec2(seg.v1.x, seg.v1.y))
      segs[index].dirty = true
      where = index
      break

    # If we haven't gone anywhere, it must be an unclosed sector, so abort.
    if started == where:
      ret.setLen(0)
      return ret

    # If we're at the origin, we're done.
    if origin == where:
      break

  ret.add(poly)

  return ret
