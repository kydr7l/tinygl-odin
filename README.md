# tinygl-odin

Odin bindings for [TinyGL](https://github.com/C-Chads/tinygl) (the C-Chads fork). TinyGL is a software rasterizer with an API like OpenGL 1.1. It draws into a memory buffer. You copy that buffer to a window, an image file, or a different output.

## Build

Clone the repository with its submodule:

```sh
git clone --recursive <this repository>
```

Build the C library into `lib/`:

```sh
.\build.bat     # Windows (needs clang from LLVM)
./build.sh      # Linux
```

The build scripts accept these options, in any order:

| Option   | Effect |
|----------|--------|
| `openmp` | Use OpenMP threads. Then pass `-define:TINYGL_OPENMP=true` to Odin. On Windows, `libomp.dll` (from LLVM) must be on the PATH. |
| `native` | Compile with `-march=native`. The library then works only on CPUs like the build machine. |
| `debug`  | Compile with `-O0 -g`. |

Set the `CC` environment variable to use a different C compiler. On Windows, the compiler must make objects in the MSVC format.

## Use

```odin
import tgl "path/to/tinygl-odin"

zb := tgl.ZB_open(640, 480, tgl.ZB_MODE_RGBA, nil) // the width must be a multiple of 4
tgl.Init(zb)
// ... draw with tgl.Begin, tgl.Vertex3f, tgl.End, and the other GL procedures ...
pixels := make([]tgl.PIXEL, 640 * 480)
tgl.ZB_copyFrameBuffer(zb, raw_data(pixels), 640 * size_of(tgl.PIXEL))
tgl.Close()
tgl.ZB_close(zb)
```

The names are the names in `gl.h` without the `gl` and `GL_` prefixes: `glBegin` is `tgl.Begin`, and `GL_TRIANGLES` is `tgl.TRIANGLES`. A name that starts with a digit gets a `_` prefix: `GL_2D` is `tgl._2D`. A 32-bit pixel is `0x00RRGGBB`.

TinyGL has one global context. Use it from one thread at a time.

## Examples

All examples draw the same gears.

```sh
odin run examples/image   # writes gears.png
odin run examples/sdl     # SDL3 window
odin run examples/gdi     # Win32 GDI window (Windows only)
odin run examples/x11     # X11 window (Linux only)
```

- On Windows, the SDL example needs `SDL3.dll` next to the executable. Copy it from the `vendor/sdl3` folder of your Odin installation.
- On Linux, the SDL example needs the SDL3 library of your system.
- On Linux, the image example needs the stb libraries of Odin. If `vendor/stb/lib` in your Odin installation is empty, run `vendor/stb/src/build_stb.sh` from your Odin installation.

## Feature options

TinyGL sets its features at compile time in `zfeatures.h`. To change a feature, edit `zfeatures.h` in the root of this repository, then build again. Do not edit the file in `tinygl/`. The build script puts your file over the upstream file.

Two features also change the Odin side. If you change one of them, pass the same value to Odin:

| `zfeatures.h`              | Odin flag |
|----------------------------|-----------|
| `TGL_FEATURE_RENDER_BITS`  | `-define:TINYGL_RENDER_BITS=<16 or 32>` |
| `TGL_FEATURE_TEXTURE_POW2` | `-define:TINYGL_TEXTURE_POW2=<n>` |

With 16-bit pixels, use `ZB_MODE_5R6G5B` in place of `ZB_MODE_RGBA`. To make sure that the values agree, run `odin test tests` with the same flags.

## Limits

`gl.h` declares 27 functions that the library does not define, for example `glVertex3d` and `glTexCoord3f`. These bindings do not include them. The list is in `tinygl.odin`. For the other limits of TinyGL, read `tinygl/README.md`.

## License

TinyGL: see `tinygl/LICENSE`.
