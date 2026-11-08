# TinyGL Odin Bindings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make an Odin package `tinygl` that binds the C-Chads TinyGL library, with build scripts and four example outputs (PNG, SDL3, GDI, X11).

**Architecture:** The C-Chads repository is a git submodule at `tinygl/`. A build script copies its source into `build/tinygl/`, puts the repository `zfeatures.h` over the upstream one, and compiles a static library into `lib/`. The repository root is the Odin package (`tinygl.odin`). A shared `examples/gears` package draws the scene, and each example copies the framebuffer to one output.

**Tech Stack:** Odin (dev-2026-10 nightly), C99, clang (Windows, target `x86_64-pc-windows-msvc`), cc/gcc (Linux), `vendor:stb/image`, `vendor:sdl3`, `core:sys/windows`, `vendor:x11/xlib`, `core:math/linalg`.

**Spec:** `docs/superpowers/specs/2026-11-08-tinygl-odin-bindings-design.md`

## Global Constraints

- Do not change any file in the `tinygl/` submodule.
- The package name is `tinygl`. Remove the `gl` prefix from functions and the `GL_` prefix from constants (`glBegin` → `Begin`, `GL_TRIANGLES` → `TRIANGLES`). Keep `ZB_` names as they are.
- GL constants are untyped Odin constants, the same as in `vendor:OpenGL`. GL types are Odin aliases: `GLint :: c.int`, `GLenum :: GLint`, `GLsizei :: GLint`, `GLuint :: c.uint`, `GLfloat :: f32`, `GLdouble :: f64`, `GLboolean :: u8`, `GLubyte :: u8`, `GLbyte :: i8`, `GLshort :: c.short`, `GLushort :: c.ushort`, `GLTEXTSIZE :: c.int`.
- Do not bind: the 27 functions that `gl.h` declares but the library does not define, `ZB_plot`, `ZB_line*`, `ZB_fillTriangle*`, `ZB_setTexture`, `ZB_clear`, the dither functions, `gl_malloc`, `gl_zalloc`, `gl_free`, and `TGL_BUILDT_*`.
- Do not bind `include-demo/` or GLU.
- Odin `#config` values: `TINYGL_RENDER_BITS` (default 32), `TINYGL_TEXTURE_POW2` (default 8), `TINYGL_OPENMP` (default false).
- Build options are words: `openmp`, `native`, `debug`. The `CC` environment variable selects the compiler. Defaults: no OpenMP, no `-march=native`, `-O3 -DNDEBUG`, `CC=clang` on Windows, `CC=cc` on Linux.
- Library names: `lib/tinygl.lib` (Windows) and `lib/libtinygl.a` (Linux).
- Do not commit `build/`, `lib/`, `*.png`, `*.exe`, `*.pdb`, or other build outputs.
- The framebuffer width must be a multiple of 4. All examples use a fixed 640×480 framebuffer and windows that the user cannot resize.
- Write the README and code comments in ASD-STE100 Simplified Technical English. Keep the README simple: what the repository is, how to build, how to run the examples, the build options, and the note about compile-time features and Linux dependencies. Do not add more.
- No Linux machine is available. On Windows, check Linux-only code with `odin check <dir> -target:linux_amd64`. Run `build.sh` in Git Bash to test its logic. If a Linux `odin check` reports that `lib/libtinygl.a` does not exist, run `CC=gcc sh build.sh` in Git Bash to make that file, then run the check again.

## Review Focus

1. A user changes `zfeatures.h` (for example to 16-bit pixels) but builds Odin without the matching `-define:`. Expected: the README tells them which `-define:` to pass, and `odin test tests` with the same defines fails if they do not agree. Pinned by `test_clear_color_reaches_framebuffer` in Task 2.
2. A user passes an Odin procedure to `PostProcess`. Expected: TinyGL calls it for each pixel and the result is in the framebuffer. Pinned by `test_post_process_changes_pixels` in Task 2.
3. A user builds with `openmp`. Expected: the library and the Odin tests link and pass with `-define:TINYGL_OPENMP=true`. Pinned by Task 1 Step 5 and Task 2 Step 6.
4. A user calls `DrawText` with an Odin string literal. Expected: the text is in the framebuffer. Pinned by `test_draw_text_writes_pixels` in Task 2.
5. A user calls `gears.init` with a width that is not a multiple of 4. Expected: an assertion failure with a clear message, not a corrupt image. Pinned by the `assert` in Task 3 Step 3.

---

### Task 1: Submodule and build scripts

**Files:**
- Create: `.gitmodules` (from `git submodule add`), `tinygl/` (submodule)
- Create: `zfeatures.h` (copy of `tinygl/include/zfeatures.h`, no changes)
- Create: `build.bat`, `build.sh`
- Create: `.gitignore`

**Interfaces:**
- Produces: `lib/tinygl.lib` (Windows) or `lib/libtinygl.a` (Linux), with the 119 `gl*` symbols and `ZB_open`, `ZB_close`, `ZB_resize`, `ZB_copyFrameBuffer`. With `openmp` on Windows, the script also copies `libomp.lib` from the LLVM `lib` folder into `lib/`.

- [ ] **Step 1: Add the submodule and the feature file**

Run: `git submodule add https://github.com/C-Chads/tinygl tinygl` and `cp tinygl/include/zfeatures.h zfeatures.h`.
Expected: `git diff --no-index tinygl/include/zfeatures.h zfeatures.h` prints nothing.

- [ ] **Step 2: Write `build.bat`**

Steps that the script does, in this order:
1. Read the words `openmp`, `native`, `debug` from the arguments, in any order. Stop with an error message for an unknown word.
2. Use `%CC%`, or `clang` if `CC` is not set.
3. Delete `build\tinygl`. Copy `tinygl\src` and `tinygl\include` into `build\tinygl\`. Copy `zfeatures.h` over `build\tinygl\include\zfeatures.h`.
4. Compile each `build\tinygl\src\*.c` to an object in `build\obj\` with `-std=c99 -Wall -Wno-unused-function` and `-O3 -DNDEBUG` (or `-O0 -g` with `debug`). Add `-march=native` with `native`. Add `-fopenmp` with `openmp`.
5. Make `lib\tinygl.lib` from the objects with `llvm-lib` (or `llvm-ar rcs`).
6. With `openmp`, copy `libomp.lib` from the LLVM install (`C:\Program Files\LLVM\lib`) into `lib\`.
7. Stop with a non-zero exit code if a step fails.

- [ ] **Step 3: Write `build.sh`**

The same steps as `build.bat`, with `CC` default `cc`, output `lib/libtinygl.a` made with `ar rcs`, and no `libomp` copy. Use `#!/usr/bin/env sh` and `set -eu`.

- [ ] **Step 4: Write `.gitignore`**

Content: `build/`, `lib/`, `*.png`, `*.exe`, `*.pdb`, `*.obj`, `*.o`, `*.a`, `*.lib`.

- [ ] **Step 5: Verify the build and the options**

Run: `build.bat` then `llvm-nm lib\tinygl.lib | findstr " T glInit"`.
Expected: exit code 0 and one `T glInit` line.

Run: `build.bat openmp debug native` then `llvm-nm lib\tinygl.lib | findstr __kmpc`.
Expected: exit code 0, `lib\libomp.lib` exists, and `__kmpc` symbols are listed (OpenMP is in use).

Run: `build.bat bogus`.
Expected: non-zero exit code and an error message that names `bogus`.

Run in Git Bash: `CC=gcc sh build.sh debug && ls lib/libtinygl.a && rm -rf build lib`.
Expected: the script finishes and `lib/libtinygl.a` exists. This tests the script logic only.

Run: `git status --short tinygl`.
Expected: no output (the submodule has no changes).

Run `build.bat` again to leave a default build for Task 2.

- [ ] **Step 6: Commit**

```bash
git add .gitmodules tinygl zfeatures.h build.bat build.sh .gitignore
git commit -m "build: add TinyGL submodule and build scripts"
```

### Task 2: Bindings and tests

**Files:**
- Create: `tinygl.odin` (package `tinygl`)
- Create: `tests/tinygl_test.odin` (package `tinygl_tests`, imports `tgl ".."`)

**Interfaces:**
- Consumes: the library from Task 1.
- Produces (later tasks use these):
  - `ZBuffer :: struct {}` (opaque; use only as `^ZBuffer`)
  - `PIXEL :: u32 when RENDER_BITS == 32 else u16`
  - `RENDER_BITS :: #config(TINYGL_RENDER_BITS, 32)`, `TEXTURE_POW2 :: #config(TINYGL_TEXTURE_POW2, 8)`, `TEXTURE_DIM :: 1 << TEXTURE_POW2`
  - `ZB_MODE_5R6G5B :: 1`, `ZB_MODE_INDEX :: 2`, `ZB_MODE_RGBA :: 3`, `ZB_MODE_RGB24 :: 4`
  - `ZB_open :: proc(xsize, ysize, mode: c.int, frame_buffer: rawptr) -> ^ZBuffer`
  - `ZB_close :: proc(zb: ^ZBuffer)`
  - `ZB_resize :: proc(zb: ^ZBuffer, frame_buffer: rawptr, xsize, ysize: GLint)`
  - `ZB_copyFrameBuffer :: proc(zb: ^ZBuffer, buf: rawptr, linesize: GLint)` (linesize is in bytes)
  - `GET_RED`, `GET_GREEN`, `GET_BLUE :: proc "contextless" (p: PIXEL) -> u8`, with the formulas from `zbuffer.h` for the current `RENDER_BITS`
  - `Init :: proc(zbuffer: rawptr)`, `Close :: proc()`
  - `PostProcessProc :: #type proc "c" (x, y: GLint, pixel: GLuint, z: GLushort) -> GLuint`, `PostProcess :: proc(postprocess: PostProcessProc)`
  - `DrawText :: proc(text: cstring, x, y: GLint, pixel: GLuint)`
  - All other `gl.h` functions that the library defines, with the `gl` prefix removed, and all `GL_` constants with the prefix removed (including the `GL_TEXT_SIZE*` values and the `GL_*_BIT` values).

- [ ] **Step 1: Write the failing tests**

All tests use a 64×64 framebuffer: `zb := tgl.ZB_open(64, 64, tgl.ZB_MODE_RGBA, nil)`, then `tgl.Init(zb)`, then `tgl.Viewport(0, 0, 64, 64)`. At the end: `tgl.Close()` and `tgl.ZB_close(zb)`. Copy pixels out with `tgl.ZB_copyFrameBuffer(zb, &buf[0], 64 * size_of(tgl.PIXEL))` into `buf: [64*64]tgl.PIXEL`.

```odin
@(test) test_pixel_channels :: proc(t: ^testing.T) {
	when tgl.RENDER_BITS == 32 {
		testing.expect_value(t, tgl.GET_RED(0x123456), 0x12)
		testing.expect_value(t, tgl.GET_GREEN(0x123456), 0x34)
		testing.expect_value(t, tgl.GET_BLUE(0x123456), 0x56)
	}
}

// ClearColor(1, 0, 0, 0), Clear(COLOR_BUFFER_BIT | DEPTH_BUFFER_BIT), copy.
// Pixel (32, 32): red >= 0xFE, green == 0, blue == 0.
@(test) test_clear_color_reaches_framebuffer :: proc(t: ^testing.T)

// Clear to black. DrawText("HELLO", 0, 0, 0xFFFFFF). Copy.
// At least one pixel in the top 8 rows is not 0.
@(test) test_draw_text_writes_pixels :: proc(t: ^testing.T)

// Clear to black. PostProcess with a proc "c" that returns 0x00FF00. Copy.
// Pixel (10, 10) == 0x00FF00.
@(test) test_post_process_changes_pixels :: proc(t: ^testing.T)

// Put the address of every bound foreign procedure into one array:
// procs := [?]rawptr{ rawptr(tgl.Begin), rawptr(tgl.End), ... }
// Expect len(procs) > 0. This makes the linker resolve every bound symbol.
@(test) test_link_all_procs :: proc(t: ^testing.T)
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `odin test tests`
Expected: FAIL, because package `..` has no declarations.

- [ ] **Step 3: Write `tinygl.odin`**

- Foreign import: `lib/tinygl.lib` on Windows and `lib/libtinygl.a` plus `system:m` on Linux. When `TINYGL_OPENMP` is true, also import `lib/libomp.lib` on Windows and `system:gomp` on Linux.
- Use `@(link_prefix="gl")` on the `foreign` block for the `gl` functions, and a second `foreign` block for the `ZB_` functions.
- To get the list of functions to bind, compare the `gl*` declarations in `tinygl/include/GL/gl.h` (after the `PROTO_GL1..4` macro expansion) with `llvm-nm lib/tinygl.lib`. Bind the 119 functions that are in both. A comment in the file names the 27 that the bindings leave out, and tells why.
- Pointer arguments: `const GLfloat*` → `[^]GLfloat`, `void*` → `rawptr`, `const GLubyte*` that is text → `cstring`, `glGetString` returns `cstring`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `odin test tests`
Expected: 5 tests pass.

- [ ] **Step 5: Check that the link test is complete**

Run: count the `proc` declarations in the `foreign` blocks of `tinygl.odin`, and count the entries in `procs` in `test_link_all_procs`.
Expected: the two counts are the same (123: 119 `gl` + 4 `ZB_`).

- [ ] **Step 6: Run the tests with OpenMP**

Run: `build.bat openmp`, then `odin test tests -define:TINYGL_OPENMP=true`, then `build.bat`.
Expected: 5 tests pass.

- [ ] **Step 7: Check Linux type-check**

Run: `odin check tests -target:linux_amd64`
Expected: no errors.

- [ ] **Step 8: Commit**

```bash
git add tinygl.odin tests
git commit -m "feat: add TinyGL bindings and tests"
```

### Task 3: Gears scene and image example

**Files:**
- Create: `examples/gears/gears.odin` (package `gears`, imports `tgl "../.."` and `core:math/linalg`)
- Create: `examples/image/main.odin` (package `main`, imports `vendor:stb/image`)
- Modify: `tests/tinygl_test.odin` (add one test, import `"../examples/gears"`)

**Interfaces:**
- Consumes: Task 2 bindings.
- Produces:
  - `gears.WIDTH :: 640`, `gears.HEIGHT :: 480`
  - `gears.init :: proc(width, height: i32)`: the caller has already called `tgl.Init`. Sets the viewport, the projection, the lights, and makes the three gear display lists.
  - `gears.draw :: proc(angle: f32)`: clears the buffers and draws the three gears with rotation `angle` in degrees.

- [ ] **Step 1: Write the failing test**

```odin
// 64x64 framebuffer, Init, gears.init(64, 64), gears.draw(0), copy.
// At least 100 pixels are not the clear color.
@(test) test_gears_draws_pixels :: proc(t: ^testing.T)
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `odin test tests`
Expected: FAIL, because package `gears` does not exist.

- [ ] **Step 3: Write `examples/gears/gears.odin`**

Port the scene from `tinygl/Raw_Demos/gears.c` (the `gear` procedure, the three gears, their colors, positions, and the light setup). Make the projection with `linalg.matrix4_perspective_f32` and pass it to `tgl.LoadMatrixf`. This shows the native Odin math in place of the C-Chads math. The first line of `init` is `assert(width % 4 == 0, "TinyGL needs a framebuffer width that is a multiple of 4")`.

- [ ] **Step 4: Run the test to verify it passes**

Run: `odin test tests`
Expected: 6 tests pass.

- [ ] **Step 5: Write `examples/image/main.odin`**

Open a `gears.WIDTH`×`gears.HEIGHT` framebuffer, call `tgl.Init`, `gears.init`, and `gears.draw(20)`. Copy the framebuffer. Convert each pixel to 3 RGB bytes with `GET_RED`, `GET_GREEN`, `GET_BLUE`. Write `gears.png` with `stbi.write_png(..., comp = 3, stride = WIDTH * 3)`. Print the file name. Close the GL context and the framebuffer.

- [ ] **Step 6: Run the example**

Run: `odin run examples/image`
Expected: the program prints `gears.png` and the file exists. Open the PNG with the Read tool. Expected: three colored gears (red, green, blue) on a black background.

- [ ] **Step 7: Commit**

```bash
git add examples/gears examples/image tests
git commit -m "feat: add gears scene and image example"
```

### Task 4: SDL3 example

**Files:**
- Create: `examples/sdl/main.odin` (package `main`, imports `vendor:sdl3`)

**Interfaces:**
- Consumes: `gears.init`, `gears.draw`, `gears.WIDTH`, `gears.HEIGHT`, Task 2 bindings.

- [ ] **Step 1: Write `examples/sdl/main.odin`**

Make a window that the user cannot resize (`gears.WIDTH`×`gears.HEIGHT`), a renderer, and a streaming texture with format `.XRGB8888`. Each frame: process events (quit on window close or Escape), increase the angle, call `gears.draw`, call `ZB_copyFrameBuffer` into the locked texture memory with the texture pitch as `linesize`, unlock, render the texture, present. On Windows, `SDL3.dll` must be next to the executable: the example's README line says to copy it from Odin's `vendor/sdl3`.

- [ ] **Step 2: Build and run**

Run: `odin build examples/sdl -out:examples/sdl/sdl.exe`, copy `SDL3.dll` from `<odin root>/vendor/sdl3/` next to it, and run it.
Expected: a window opens and shows the rotating gears. Escape closes it with exit code 0. If no person is present to look, run it for 3 seconds and confirm it did not exit with an error.

- [ ] **Step 3: Check Linux type-check**

Run: `odin check examples/sdl -target:linux_amd64`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add examples/sdl
git commit -m "feat: add SDL3 example"
```

### Task 5: GDI example

**Files:**
- Create: `examples/gdi/main.odin` (package `main`, imports `core:sys/windows`). Put `#+build windows` at the top.

**Interfaces:**
- Consumes: `gears.init`, `gears.draw`, `gears.WIDTH`, `gears.HEIGHT`, Task 2 bindings.

- [ ] **Step 1: Write `examples/gdi/main.odin`**

Register a window class and make a window with `WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX` (no resize), with a client area of `gears.WIDTH`×`gears.HEIGHT` (use `AdjustWindowRect`). The window procedure handles `WM_DESTROY` (`PostQuitMessage`) and Escape. The main loop uses `PeekMessageW`. Each frame: increase the angle, call `gears.draw`, copy the framebuffer into a `[WIDTH*HEIGHT]u32` buffer, and draw it with `StretchDIBits` and a `BITMAPINFO` of 32 bits, `BI_RGB`, and a negative `biHeight` (top-down rows).

- [ ] **Step 2: Build and run**

Run: `odin run examples/gdi`
Expected: a window opens and shows the rotating gears, with the same colors as `gears.png` and not upside down. Escape closes it with exit code 0. If no person is present to look, run it for 3 seconds and confirm it did not exit with an error.

- [ ] **Step 3: Commit**

```bash
git add examples/gdi
git commit -m "feat: add GDI example"
```

### Task 6: X11 example

**Files:**
- Create: `examples/x11/main.odin` (package `main`, imports `vendor:x11/xlib`). Put `#+build linux` at the top.

**Interfaces:**
- Consumes: `gears.init`, `gears.draw`, `gears.WIDTH`, `gears.HEIGHT`, Task 2 bindings.

- [ ] **Step 1: Write `examples/x11/main.odin`**

Open the display, make a `gears.WIDTH`×`gears.HEIGHT` window, set `WM_NORMAL_HINTS` with equal minimum and maximum size (no resize), and select `KeyPressMask | ExposureMask`. Register `WM_DELETE_WINDOW`. Make an `XImage` with `CreateImage` (depth 24, `ZPixmap`, 32 bits for each pixel) over a `[WIDTH*HEIGHT]u32` buffer. Each frame: process the pending events (quit on Escape or `WM_DELETE_WINDOW`), increase the angle, call `gears.draw`, call `ZB_copyFrameBuffer` into the buffer, and call `PutImage`, then `Flush`. Before `DestroyImage`, set the image data pointer to nil, because Odin owns the buffer.

- [ ] **Step 2: Type-check for Linux**

Run: `odin check examples/x11 -target:linux_amd64`
Expected: no errors. Report that no run test was possible on this machine.

- [ ] **Step 3: Commit**

```bash
git add examples/x11
git commit -m "feat: add X11 example"
```

### Task 7: README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Write `README.md`**

Sections, in this order, each short:
1. What this is: Odin bindings for the C-Chads TinyGL fork, a software rasterizer.
2. Build: `git clone --recursive`, then `build.bat` (Windows) or `./build.sh` (Linux). The build options `openmp`, `native`, `debug`, and the `CC` variable. With `openmp`, pass `-define:TINYGL_OPENMP=true` to Odin. On Windows, `libomp.dll` must be on the PATH (LLVM puts it there).
3. Use: `import tgl "path/to/tinygl-odin"` and a minimal 8-line sequence: `ZB_open`, `Init`, draw, `ZB_copyFrameBuffer`, `Close`, `ZB_close`.
4. Examples: one line for each of `image`, `sdl`, `gdi` (Windows), `x11` (Linux), with the `odin run` command. The SDL example needs `SDL3.dll` next to the executable on Windows and the system SDL3 library on Linux. On Linux, the image example needs the stb libraries: run `make -C <odin root>/vendor/stb/src` if `vendor/stb/lib` is empty.
5. Feature options: edit `zfeatures.h`, run the build again. If you change `TGL_FEATURE_RENDER_BITS` or `TGL_FEATURE_TEXTURE_POW2`, pass `-define:TINYGL_RENDER_BITS=<n>` or `-define:TINYGL_TEXTURE_POW2=<n>` to Odin. Run `odin test tests` with the same defines to check that they agree. With 16-bit pixels, use `ZB_MODE_5R6G5B`.
6. Limits: 27 functions in `gl.h` have no definition in the library and are not bound. Other limits are in `tinygl/README.md`.
7. License: TinyGL license in `tinygl/LICENSE`.

- [ ] **Step 2: Verify the README commands**

Run each command in the README sections 2 and 4 that works on Windows.
Expected: each command works as the README says.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: add README"
```
