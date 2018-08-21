import tables

import texture

type
  AtlasEntry = object
    texture: Texture
    xPos: uint32
    yPos: uint32

type
  AtlasShelf = object
    width*: uint32
    height*: uint32

type
  Atlas = object
    atlas: Table[string, AtlasEntry] ## The actual texture atlas
    length: uint32 ## Length of one side of the texture atlas - it's square
    shelves: seq[AtlasShelf]

proc newAtlas*(size: uint): Atlas =
  return Atlas(atlas: initTable[string, AtlasEntry](),
    length: size.uint32, shelves: @[])

proc add*(atlas: var Atlas, t: Texture) =
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
        atlas.atlas[t.name] = AtlasEntry(texture: t)
        shelf.width += t.width

    # No room on this shelf, go to the next...
    y += shelf.height

  # We have no space in any of our existing shelves.  Do we have space for
  # a new shelf?
  if (t.height <= atlas.length - y):
    # We do!  Create the new shelf and put the atlas entry there.
    atlas.shelves.add(AtlasShelf(width: t.width, height: t.height))
    atlas.atlas[t.name] = AtlasEntry(texture: t, xPos: 0, yPos: y)

  echo "No space left in texture atlas"
  quit(QuitFailure)
