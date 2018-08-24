import strformat, tables

import texture

type
  AtlasEntry = object
    texture*: Texture
    xPos*: uint32
    yPos*: uint32
  AtlasShelf = object
    width*: uint32
    height*: uint32
  Atlas = object
    atlas: Table[string, AtlasEntry] ## The actual texture atlas
    length*: uint32 ## Length of one side of the texture atlas - it's square
    shelves: seq[AtlasShelf]

proc newAtlas*(size: uint): Atlas =
  return Atlas(atlas: initTable[string, AtlasEntry](),
    length: size.uint32, shelves: @[])

proc `$`*(atlas: var Atlas): string =
  var ret = &"Atlas of size {atlas.length}\n"
  for index, shelf in atlas.shelves:
    ret &= &"  Shelf {index}: (width {shelf.width} height {shelf.height})"
  return ret

proc add*(atlas: var Atlas, t: Texture) =
  echo "Inserting " & t.name
  if t.width > atlas.length or t.height > atlas.length:
    echo "atlas.add: Texture is too big for the atlas"
    quit(QuitFailure)

  var y = 0'u32
  for shelf in atlas.shelves.mitems:
    # Can the shelf hold it?
    if (t.height <= shelf.height):
      # Is there space on the shelf?
      if (t.width <= atlas.length - shelf.width):
        # There is!  Put the altas entry there, then adjust the shelf.
        atlas.atlas[t.name] = AtlasEntry(texture: t, xPos: shelf.width, yPos: y)
        shelf.width += t.width

        return

    # No room on this shelf, go to the next...
    y += shelf.height

  # We have no space in any of our existing shelves.  Do we have space for
  # a new shelf?
  if (t.height <= atlas.length - y):
    # We do!  Create the new shelf and put the atlas entry there.
    atlas.shelves.add(AtlasShelf(width: t.width, height: t.height))
    atlas.atlas[t.name] = AtlasEntry(texture: t, xPos: 0, yPos: y)

    return

  echo "No space left in texture atlas"
  quit(QuitFailure)

type PersistProc* = proc(data: pointer, x, y, w, h: uint32)
## A proc used by persist that is called once for every texture to be inserted
## into the GPU
##
## data is an opaque pointer to the image data in RGBA format.
## x is the x position in the atlas where the image belongs.
## y is the y position in the atlas where the image belongs.
## w is the width of the image.
## h is the height of the image.

proc persist*(atlas: var Atlas, p: PersistProc) =
  ## Persist the atlas onto the GPU
  for tex in atlas.atlas.mvalues:
    p(addr tex.texture.data[0], tex.xPos, tex.yPos, tex.texture.width, tex.texture.height)

proc find*(atlas: Atlas, name: string):AtlasEntry =
  ## Find and return the atlas entry given the name
  return atlas.atlas[name]
