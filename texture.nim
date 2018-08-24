# texture.nim
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
