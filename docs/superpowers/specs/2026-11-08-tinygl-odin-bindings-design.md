# TinyGL bindings for Odin: design

Date: 2026-11-08

## Intent

This repository gives Odin programs access to TinyGL. TinyGL is a software rasterizer with a GL 1.1-like API. The repository uses the C-Chads fork (https://github.com/C-Chads/tinygl) as a git submodule.

TinyGL draws into a memory buffer. The user copies that buffer to an output of their choice. Example outputs are an SDL window, an X11 window, or an image file. Thus the bindings must not depend on one output. The repository shows each output in a small example program.

## Goals

- Bind the public TinyGL API to an Odin package with the name `tinygl`.
- Build the C library from the submodule with one script on each platform.
- Supply four example programs that draw the same scene to four outputs: a PNG file, an SDL3 window, an X11 window, and a GDI window.
- Make the bindings and examples work on Windows and on Linux. The X11 example is for Linux only. The GDI example is for Windows only.

## Non-goals

- GLU. TinyGL does not supply it.
- The C-Chads demo headers in `include-demo/` (`3dMath.h`, `chadphys.h`, `api_audio.h`, `openimgui.h`, `chade.h`, `resweep.h`, `lockstepthread.h`, `stb_c_lexer.h`). These files are header-only and only the demos use them. They are not part of the library.
- A wrapper layer that makes the GL API "more like Odin". The bindings are thin.
- Multithreading by default. The build does not use OpenMP unless the user selects the `openmp` option.
- Built-in output helpers in the package. Output code stays in the examples.

## Anti-goals

- Changes to the C source in the submodule. The submodule stays as upstream supplies it.
- Bindings that do not agree with the compiled library. For example, a `PIXEL` type of the wrong size, or a texture size constant that is different from the compiled value.

## Decisions

### Math (Claude's call, the user gave this decision to Claude)

The C-Chads math library (`include-demo/3dMath.h`) is not part of the compiled library. The bindings do not include it. The examples use `core:math/linalg` for perspective, look-at, and other matrix operations. The results go to TinyGL through `LoadMatrixf` or `MultMatrixf`, or through `Frustum` directly.

### What the package binds

- `include/GL/gl.h`: all functions that the compiled library defines, and all constants. The header declares 146 `gl*` functions, but the library defines only 119 of them. This includes the C-Chads extras: `glInit`, `glClose`, the buffer functions, `glDrawText`, `glTextSize`, `glPlotPixel`, `glPostProcess`, `glGetString`, `glDebug`, and `glSetEnableSpecular`.
- `include/zbuffer.h`: only the public framebuffer API. That is `ZB_open`, `ZB_close`, `ZB_resize`, `ZB_copyFrameBuffer`, the `ZBuffer` type as an opaque pointer, the `PIXEL` type, and the `ZB_MODE_*` constants. Also bind the `GET_RED`, `GET_GREEN`, `GET_BLUE` macros as Odin procedures (or the equivalent), because the examples need them to convert pixels.
- Do not bind the rasterizer internals: `ZB_plot`, `ZB_line*`, `ZB_fillTriangle*`, `ZB_setTexture`, `ZB_clear`, the dither functions, `gl_malloc`, `gl_zalloc`, and `gl_free`.
- Do not bind the build-time test arrays (`TGL_BUILDT_*`).
- Do not bind the 27 functions that `gl.h` declares but the library does not define (Claude's call). These are all the double-precision forms (`glVertex2d`, `glColor3d`, `glNormal3d`, `glTexCoord1d` to `glTexCoord4d`, and their `dv` forms) and `glVertex2fv`, `glVertex4fv`, `glTexCoord1f`, `glTexCoord1fv`, `glTexCoord3f`, `glTexCoord3fv`, `glTexCoord4fv`. If the bindings declared them, a call to one of them would compile but fail at link time. Find the list again by a comparison of the header declarations with the symbols in the built library.
- Add a link test: a program that refers to every bound procedure. The test must link with the built library on each platform.

### Naming (Claude's call)

- The package name is `tinygl`.
- Remove the `gl` prefix from functions and the `GL_` prefix from constants. This agrees with `vendor:OpenGL`. Example: `tgl.Begin(tgl.TRIANGLES)`.
- Keep the `ZB_` names as they are (`ZB_open`, `ZB_MODE_RGBA`), because they have no `gl` prefix to remove.
- Use Odin types for pointer arguments, for example `[^]f32`, `cstring`, and `rawptr`. Use the GL type names (`GLenum`, `GLint`, and so on) as Odin aliases.

### Compile-time features

`include/zfeatures.h` sets options at compile time. Some options change the types and the behavior. The TinyGL sources include `zfeatures.h` by a fixed relative path (`../include/zfeatures.h`), and the header sets each value with no `#ifndef` guard. Thus a `-D` compiler flag cannot change a feature.

- The repository keeps its own `zfeatures.h` at the repository root. It starts as a copy of the upstream file, with no changes. The user edits this file to change features.
- The build script copies `tinygl/src` and `tinygl/include` into `build/tinygl/`. Then it puts the repository `zfeatures.h` over `build/tinygl/include/zfeatures.h`. Then it compiles the copy. The submodule stays as upstream supplies it.
- The upstream defaults are 32-bit pixels (`TGL_FEATURE_RENDER_BITS = 32`, `PIXEL` is a 32-bit unsigned integer) and 256×256 textures (`TGL_FEATURE_TEXTURE_POW2 = 8`). `TexImage2D` resizes a texture of a different size to 256×256. With 32-bit pixels, `ZB_open` works only with `ZB_MODE_RGBA`. With 16-bit pixels, it works only with `ZB_MODE_5R6G5B`.
- Two features change the Odin side: the pixel size and the texture size. The package reads them with Odin `#config` values: `TINYGL_RENDER_BITS` (default 32) and `TINYGL_TEXTURE_POW2` (default 8). A user who changes these features passes the same values with `-define:` when they build their program. The README tells users this (Claude's call; the user accepted this proposal).

### Build options (the user's decision)

The user wants OpenMP off by default, and wants users to be able to turn on OpenMP and to change other build options. The build scripts accept these options:

- `openmp`: off by default. It compiles with `-fopenmp`. The Odin package then must link the OpenMP runtime. The package reads `#config(TINYGL_OPENMP, false)` for this.
- `native`: off by default. It adds `-march=native`.
- `debug`: off by default. It compiles with `-O0 -g` in place of `-O3 -DNDEBUG`.
- The `CC` environment variable selects the C compiler. The default is `clang` on Windows and `cc` on Linux. On Windows, the compiler must make objects in the MSVC format. (Claude's call: an environment variable, not a `cc=` option, because a Windows batch file splits arguments at `=`.)
- The feature options are in the repository `zfeatures.h`, as the section above says.

### Build (Claude's call)

- Put the submodule at `tinygl/`.
- Supply `build.bat` (Windows) and `build.sh` (Linux). Each script compiles `build/tinygl/src/*.c` into a static library in `lib/`.
- By default, do not use `-march=native`, because it makes the library work only on CPUs like the build machine.
- By default, do not use OpenMP. Without OpenMP, TinyGL runs on one thread and gives correct results.
- On Windows, the library must link with the Odin compiler, which uses the MSVC object format. The installed tools on the user's machine are clang (LLVM, target `x86_64-pc-windows-msvc`), MinGW gcc, CMake, and make. There is no `cl.exe` on the PATH. LLVM supplies `libomp.lib`.
- On Linux, link the C math library (`-lm`).

### Repository layout (Claude's call)

```
tinygl/               C-Chads submodule, not changed
tinygl.odin           the bindings (package tinygl), at the repository root
zfeatures.h           the TinyGL feature options that the user edits
build.bat, build.sh   compile the C source into lib/
build/                the copy of the C source that the build compiles (do not commit)
lib/                  the built static library (do not commit the binaries)
examples/
  image/              draws gears, writes a PNG file (vendor:stb/image)
  sdl/                draws gears in an SDL3 window (vendor:sdl3)
  x11/                draws gears in an X11 window (vendor:x11/xlib), Linux only
  gdi/                draws gears in a Win32 window with GDI (core:sys/windows), Windows only
README.md
```

The bindings can be in more than one `.odin` file if that is clearer. The root of the repository must stay an importable package.

### Examples

- All four examples draw the same scene: a port of Bellard's gears demo (`tinygl/Raw_Demos/gears.c` is a reference).
- `examples/image` is also the smoke test. It needs nothing more than the Odin distribution. It must run on Windows and on Linux. It writes a PNG file. The pixel conversion must agree with `Raw_Demos/gears.c` (use `GET_RED`, `GET_GREEN`, `GET_BLUE` to make RGB bytes).
- `examples/sdl` opens a window and shows the animated gears. It copies the TinyGL framebuffer into an SDL texture each frame.
- `examples/x11` opens a window and shows the animated gears. It copies the framebuffer into an `XImage` each frame.
- `examples/gdi` opens a Win32 window and shows the animated gears. It draws the framebuffer with `StretchDIBits` each frame. The window is the X11 example's counterpart on Windows. The GDI example uses only `core:sys/windows`.
- The window width must be a multiple of 4. This is a TinyGL limit.

## Success

On Windows and on Linux, a user does these steps:

1. Clone the repository with its submodule.
2. Run the build script.
3. Run `odin run examples/image`. The program writes a PNG file of the gears.
4. Run `odin run examples/sdl`. A window opens and shows the gears.
5. On Linux, run `odin run examples/x11`. A window opens and shows the gears.
6. On Windows, run `odin run examples/gdi`. A window opens and shows the gears.

## Left to the builder

- The exact compiler flags (in addition to the build options above) and the method to make an MSVC-compatible `.lib` on Windows.
- The output file names in `lib/`.
- The procedure to bind `glPostProcess` (a C callback). Use `proc "c"` for the callback type.
- How to handle `TGL_FEATURE_ERROR_CHECK` and `glGetError`. The default is off.
- On Linux, the SDL example needs the system SDL3 library. The image example needs the stb libraries in Odin's `vendor/stb/lib`, which an Odin install from source may not have. Put both in the README.
- The README text, in addition to the items that this document names. The user wants a relatively simple README: what the repository is, how to build, how to run the examples, and the rebuild note for compile-time features. Do not add more.
- Small test procedures in addition to `examples/image`, if they are useful.
