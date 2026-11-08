package tinygl_tests

import "core:sync"
import "core:testing"
import tgl ".."
import "../examples/gears"

SIZE :: 64

// TinyGL has one global context, so only one test at a time can use it.
gl_lock: sync.Mutex

// Open a SIZE×SIZE framebuffer and a GL context on it.
open :: proc() -> ^tgl.ZBuffer {
	sync.mutex_lock(&gl_lock)
	zb := tgl.ZB_open(SIZE, SIZE, tgl.ZB_MODE_5R6G5B when tgl.RENDER_BITS == 16 else tgl.ZB_MODE_RGBA, nil)
	tgl.Init(zb)
	tgl.Viewport(0, 0, SIZE, SIZE)
	return zb
}

close :: proc(zb: ^tgl.ZBuffer) {
	tgl.Close()
	tgl.ZB_close(zb)
	sync.mutex_unlock(&gl_lock)
}

copy_pixels :: proc(zb: ^tgl.ZBuffer, buf: ^[SIZE * SIZE]tgl.PIXEL) {
	tgl.ZB_copyFrameBuffer(zb, &buf[0], SIZE * size_of(tgl.PIXEL))
}

@(test)
test_pixel_channels :: proc(t: ^testing.T) {
	when tgl.RENDER_BITS == 32 {
		testing.expect_value(t, tgl.GET_RED(0x123456), 0x12)
		testing.expect_value(t, tgl.GET_GREEN(0x123456), 0x34)
		testing.expect_value(t, tgl.GET_BLUE(0x123456), 0x56)
	}
}

@(test)
test_clear_color_reaches_framebuffer :: proc(t: ^testing.T) {
	zb := open()
	defer close(zb)
	tgl.ClearColor(1, 0, 0, 0)
	tgl.Clear(tgl.COLOR_BUFFER_BIT | tgl.DEPTH_BUFFER_BIT)
	buf: [SIZE * SIZE]tgl.PIXEL
	copy_pixels(zb, &buf)
	p := buf[32 * SIZE + 32]
	testing.expectf(t, tgl.GET_RED(p) >= 0xF8, "red is %x", tgl.GET_RED(p))
	testing.expect_value(t, tgl.GET_GREEN(p), 0)
	testing.expect_value(t, tgl.GET_BLUE(p), 0)
}

@(test)
test_draw_text_writes_pixels :: proc(t: ^testing.T) {
	zb := open()
	defer close(zb)
	tgl.ClearColor(0, 0, 0, 0)
	tgl.Clear(tgl.COLOR_BUFFER_BIT)
	tgl.DrawText("HELLO", 0, 0, 0xFFFFFF)
	buf: [SIZE * SIZE]tgl.PIXEL
	copy_pixels(zb, &buf)
	lit := 0
	for p in buf[:8 * SIZE] do if p != 0 do lit += 1
	testing.expect(t, lit > 0, "DrawText did not write pixels in the top 8 rows")
}

@(test)
test_post_process_changes_pixels :: proc(t: ^testing.T) {
	zb := open()
	defer close(zb)
	tgl.ClearColor(0, 0, 0, 0)
	tgl.Clear(tgl.COLOR_BUFFER_BIT)
	tgl.PostProcess(proc "c" (x, y: tgl.GLint, pixel: tgl.GLuint, z: tgl.GLushort) -> tgl.GLuint {
		return 0x00FF00
	})
	buf: [SIZE * SIZE]tgl.PIXEL
	copy_pixels(zb, &buf)
	testing.expect_value(t, buf[10 * SIZE + 10], 0x00FF00)
}

// Refer to every bound foreign procedure, so that the linker must resolve each symbol.
@(test)
test_link_all_procs :: proc(t: ^testing.T) {
	procs := [?]rawptr {
		rawptr(tgl.AreTexturesResident),
		rawptr(tgl.ArrayElement),
		rawptr(tgl.Begin),
		rawptr(tgl.BindBuffer),
		rawptr(tgl.BindBufferAsArray),
		rawptr(tgl.BindTexture),
		rawptr(tgl.BlendEquation),
		rawptr(tgl.BlendFunc),
		rawptr(tgl.BufferData),
		rawptr(tgl.CallList),
		rawptr(tgl.CallLists),
		rawptr(tgl.Clear),
		rawptr(tgl.ClearColor),
		rawptr(tgl.ClearDepth),
		rawptr(tgl.Close),
		rawptr(tgl.Color3f),
		rawptr(tgl.Color3fv),
		rawptr(tgl.Color4f),
		rawptr(tgl.Color4fv),
		rawptr(tgl.ColorMaterial),
		rawptr(tgl.ColorPointer),
		rawptr(tgl.CopyTexImage2D),
		rawptr(tgl.CullFace),
		rawptr(tgl.Debug),
		rawptr(tgl.DeleteBuffers),
		rawptr(tgl.DeleteList),
		rawptr(tgl.DeleteLists),
		rawptr(tgl.DeleteTextures),
		rawptr(tgl.DepthMask),
		rawptr(tgl.Disable),
		rawptr(tgl.DisableClientState),
		rawptr(tgl.DrawArrays),
		rawptr(tgl.DrawBuffer),
		rawptr(tgl.DrawPixels),
		rawptr(tgl.DrawText),
		rawptr(tgl.EdgeFlag),
		rawptr(tgl.Enable),
		rawptr(tgl.EnableClientState),
		rawptr(tgl.End),
		rawptr(tgl.EndList),
		rawptr(tgl.FeedbackBuffer),
		rawptr(tgl.Finish),
		rawptr(tgl.Flush),
		rawptr(tgl.FrontFace),
		rawptr(tgl.Frustum),
		rawptr(tgl.GenBuffers),
		rawptr(tgl.GenLists),
		rawptr(tgl.GenTextures),
		rawptr(tgl.GetError),
		rawptr(tgl.GetFloatv),
		rawptr(tgl.GetIntegerv),
		rawptr(tgl.GetString),
		rawptr(tgl.GetTexturePixmap),
		rawptr(tgl.Hint),
		rawptr(tgl.Init),
		rawptr(tgl.InitNames),
		rawptr(tgl.IsBuffer),
		rawptr(tgl.IsList),
		rawptr(tgl.IsTexture),
		rawptr(tgl.LightModelfv),
		rawptr(tgl.LightModeli),
		rawptr(tgl.Lightf),
		rawptr(tgl.Lightfv),
		rawptr(tgl.ListBase),
		rawptr(tgl.LoadIdentity),
		rawptr(tgl.LoadMatrixf),
		rawptr(tgl.LoadName),
		rawptr(tgl.MapBuffer),
		rawptr(tgl.Materialf),
		rawptr(tgl.Materialfv),
		rawptr(tgl.MatrixMode),
		rawptr(tgl.MultMatrixf),
		rawptr(tgl.NewList),
		rawptr(tgl.Normal3f),
		rawptr(tgl.Normal3fv),
		rawptr(tgl.NormalPointer),
		rawptr(tgl.PassThrough),
		rawptr(tgl.PixelZoom),
		rawptr(tgl.PlotPixel),
		rawptr(tgl.PointSize),
		rawptr(tgl.PolygonMode),
		rawptr(tgl.PolygonOffset),
		rawptr(tgl.PolygonStipple),
		rawptr(tgl.PopMatrix),
		rawptr(tgl.PopName),
		rawptr(tgl.PostProcess),
		rawptr(tgl.PushMatrix),
		rawptr(tgl.PushName),
		rawptr(tgl.RasterPos2f),
		rawptr(tgl.RasterPos2fv),
		rawptr(tgl.RasterPos3f),
		rawptr(tgl.RasterPos3fv),
		rawptr(tgl.RasterPos4f),
		rawptr(tgl.RasterPos4fv),
		rawptr(tgl.ReadBuffer),
		rawptr(tgl.ReadPixels),
		rawptr(tgl.Rectf),
		rawptr(tgl.RenderMode),
		rawptr(tgl.Rotatef),
		rawptr(tgl.Scalef),
		rawptr(tgl.SelectBuffer),
		rawptr(tgl.SetEnableSpecular),
		rawptr(tgl.ShadeModel),
		rawptr(tgl.TexCoord2f),
		rawptr(tgl.TexCoord2fv),
		rawptr(tgl.TexCoord4f),
		rawptr(tgl.TexCoordPointer),
		rawptr(tgl.TexEnvi),
		rawptr(tgl.TexImage1D),
		rawptr(tgl.TexImage2D),
		rawptr(tgl.TexParameteri),
		rawptr(tgl.TextSize),
		rawptr(tgl.Translatef),
		rawptr(tgl.Vertex2f),
		rawptr(tgl.Vertex3f),
		rawptr(tgl.Vertex3fv),
		rawptr(tgl.Vertex4f),
		rawptr(tgl.VertexPointer),
		rawptr(tgl.Viewport),
		rawptr(tgl.ZB_open),
		rawptr(tgl.ZB_close),
		rawptr(tgl.ZB_resize),
		rawptr(tgl.ZB_copyFrameBuffer),
	}
	testing.expect_value(t, len(procs), 123)
	for p in procs do testing.expect(t, p != nil)
}

@(test)
test_gears_draws_pixels :: proc(t: ^testing.T) {
	zb := open()
	defer close(zb)
	gears.init(SIZE, SIZE)
	gears.draw(0)
	buf: [SIZE * SIZE]tgl.PIXEL
	copy_pixels(zb, &buf)
	lit := 0
	for p in buf do if p != 0 do lit += 1
	testing.expectf(t, lit >= 100, "gears drew only %d pixels", lit)
}
