// Draw the rotating gears with TinyGL and show them in an SDL3 window.
// On Windows, put SDL3.dll from Odin's vendor/sdl3 folder next to the executable.
package main

import "core:fmt"
import "core:os"
import sdl "vendor:sdl3"
import tgl "../.."
import "../gears"

W :: gears.WIDTH
H :: gears.HEIGHT

fail :: proc(what: string) -> ! {
	fmt.eprintfln("%s failed: %s", what, sdl.GetError())
	os.exit(1)
}

main :: proc() {
	if !sdl.Init({.VIDEO}) do fail("SDL_Init")
	defer sdl.Quit()

	window := sdl.CreateWindow("TinyGL gears (SDL3)", W, H, {})
	if window == nil do fail("SDL_CreateWindow")
	defer sdl.DestroyWindow(window)

	renderer := sdl.CreateRenderer(window, nil)
	if renderer == nil do fail("SDL_CreateRenderer")
	defer sdl.DestroyRenderer(renderer)

	// XRGB8888 has the same layout as a 32-bit TinyGL pixel (0x00RRGGBB).
	texture := sdl.CreateTexture(renderer, .XRGB8888, .STREAMING, W, H)
	if texture == nil do fail("SDL_CreateTexture")
	defer sdl.DestroyTexture(texture)

	zb := tgl.ZB_open(W, H, tgl.ZB_MODE_RGBA, nil)
	if zb == nil {
		fmt.eprintln("ZB_open failed")
		os.exit(1)
	}
	tgl.Init(zb)
	defer {
		tgl.Close()
		tgl.ZB_close(zb)
	}
	gears.init(W, H)

	for running := true; running; {
		event: sdl.Event
		for sdl.PollEvent(&event) {
			#partial switch event.type {
			case .QUIT:
				running = false
			case .KEY_DOWN:
				if event.key.key == sdl.K_ESCAPE do running = false
			}
		}

		gears.draw(f32(sdl.GetTicks()) * 0.07)

		pixels: rawptr
		pitch: i32
		if sdl.LockTexture(texture, nil, &pixels, &pitch) {
			tgl.ZB_copyFrameBuffer(zb, pixels, pitch)
			sdl.UnlockTexture(texture)
		}
		sdl.RenderTexture(renderer, texture, nil, nil)
		sdl.RenderPresent(renderer)
	}
}
