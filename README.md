**NOTE: I have halted work on this version of the engine, as I have rewritten and continued development of it in TypeScript.  Please see [this repository](https://github.com/AlexMax/rock3d.js/) for all future development.**

# ROCK3D

*"Let's Rock" -Duke Nukem*

A simple 3D engine with a 2.5D heart.

## Huh?

This is just a prototype for now.  It doesn't do anything useful.

## Building

You need a copy of Nim.  If you don't have it yet, [install][1] it.

Building it is pretty simple, even on Windows.  Clone the repository, and then run:

    nimble build

On Windows, you will need a copy of **SDL2.dll** sitting in the same directory as the executable.  You can download it from [here][2], under **Runtime Binaries**.

[1]: https://nim-lang.org/install.html
[2]: https://www.libsdl.org/download-2.0.php

## License

ROCK3D is distributed under the [zlib][3] license.

[3]: https://choosealicense.com/licenses/zlib/
