#+build linux
// Draw the rotating gears with TinyGL and show them in an X11 window.
package main

import "core:fmt"
import "core:os"
import x "vendor:x11/xlib"
import tgl "../.."
import "../gears"

W :: gears.WIDTH
H :: gears.HEIGHT

main :: proc() {
	display := x.OpenDisplay(nil)
	if display == nil {
		fmt.eprintln("XOpenDisplay failed: is DISPLAY set?")
		os.exit(1)
	}
	defer x.CloseDisplay(display)

	screen := x.DefaultScreen(display)
	window := x.CreateSimpleWindow(display, x.RootWindow(display, screen), 0, 0, W, H, 0, 0, x.BlackPixel(display, screen))
	defer x.DestroyWindow(display, window)
	x.StoreName(display, window, "TinyGL gears (X11)")
	x.SelectInput(display, window, {.KeyPress, .Exposure})

	// Equal minimum and maximum sizes: the user cannot resize the window.
	hints := x.AllocSizeHints()
	hints.flags = {.PMinSize, .PMaxSize}
	hints.min_width, hints.max_width = W, W
	hints.min_height, hints.max_height = H, H
	x.SetWMNormalHints(display, window, hints)
	x.Free(hints)

	wm_delete := x.InternAtom(display, "WM_DELETE_WINDOW", false)
	x.SetWMProtocols(display, window, &wm_delete, 1)
	x.MapWindow(display, window)

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

	pixels := make([]tgl.PIXEL, W * H)
	defer delete(pixels)

	// A 24-bit ZPixmap with 32 bits for each pixel has the same layout as a 32-bit TinyGL pixel (0x00RRGGBB).
	image := x.CreateImage(display, x.DefaultVisual(display, screen), 24, .ZPixmap, 0, raw_data(pixels), W, H, 32, 0)
	if image == nil {
		fmt.eprintln("XCreateImage failed")
		os.exit(1)
	}
	defer {
		// Odin owns the pixel memory, so XDestroyImage must not free it.
		image.data = nil
		x.DestroyImage(image)
	}
	gc := x.DefaultGC(display, screen)

	angle: f32 = 0
	for running := true; running; {
		for x.Pending(display) > 0 {
			event: x.XEvent
			x.NextEvent(display, &event)
			#partial switch event.type {
			case .KeyPress:
				if x.LookupKeysym(&event.xkey, 0) == .XK_Escape do running = false
			case .ClientMessage:
				if x.Atom(event.xclient.data.l[0]) == wm_delete do running = false
			}
		}
		if !running do break

		angle += 1
		gears.draw(angle)
		tgl.ZB_copyFrameBuffer(zb, raw_data(pixels), W * size_of(tgl.PIXEL))
		x.PutImage(display, window, gc, image, 0, 0, 0, 0, W, H)
		x.Flush(display)
	}
}
