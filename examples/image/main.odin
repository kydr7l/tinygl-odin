// Draw the gears into a TinyGL framebuffer and write the result to gears.png.
package main

import "core:fmt"
import "core:os"
import stbi "vendor:stb/image"
import tgl "../.."
import "../gears"

W :: gears.WIDTH
H :: gears.HEIGHT

main :: proc() {
	zb := tgl.ZB_open(W, H, tgl.ZB_MODE_RGBA, nil)
	if zb == nil {
		fmt.eprintln("ZB_open failed")
		os.exit(1)
	}
	tgl.Init(zb)
	gears.init(W, H)
	gears.draw(20)

	pixels := make([]tgl.PIXEL, W * H)
	defer delete(pixels)
	tgl.ZB_copyFrameBuffer(zb, raw_data(pixels), W * size_of(tgl.PIXEL))

	rgb := make([]u8, W * H * 3)
	defer delete(rgb)
	for p, i in pixels {
		rgb[3 * i + 0] = tgl.GET_RED(p)
		rgb[3 * i + 1] = tgl.GET_GREEN(p)
		rgb[3 * i + 2] = tgl.GET_BLUE(p)
	}

	tgl.Close()
	tgl.ZB_close(zb)

	if stbi.write_png("gears.png", W, H, 3, raw_data(rgb), W * 3) == 0 {
		fmt.eprintln("could not write gears.png")
		os.exit(1)
	}
	fmt.println("gears.png")
}
