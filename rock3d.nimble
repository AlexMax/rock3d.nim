# Package

version       = "0.1.0"
author        = "Alex Mayfield"
description   = "A simple 3D engine with a 2.5D heart"
license       = "zlib"

srcDir = "src"
bin = @["rock3d", "rocked"]

# Dependencies

requires "nim >= 0.18.0", "glm", "nimPNG", "opengl", "sdl2",
  "https://github.com/genotrance/nimtess2.git"

# Tasks

task clean, "Clean up the tree":
  for b in bin:
    rmFile(toExe(b))

  rmDir("src/nimcache")
