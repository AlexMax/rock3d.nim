import ospaths, strformat

import nimPNG

type
  Texture* = object
    name*: string ## Name of a texture, should be unique
    data*: string ## Data of the texture, stored in RGBA format
    width*: uint32 ## Width of the texture
    height*: uint32 ## Height of the texture

proc loadPNGFile*(filepath: string): Texture =
  let fileParts = ospaths.splitFile(filepath)
  let png = loadPNG32(filepath)
  var tex = Texture(name: fileParts.name, data: png.data,
    width: png.width.uint32, height: png.height.uint32)
  return tex

proc `$`*(tex: Texture): string =
  let dataLen = tex.data.len
  return &"(name: {tex.name}, data length:{dataLen}, " &
    &"width: {tex.width}, height: {tex.height})"
