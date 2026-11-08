// The gears scene from tinygl/Raw_Demos/gears.c, for the examples.
package gears

import "core:math"
import "core:math/linalg"
import tgl "../.."

WIDTH  :: 640
HEIGHT :: 480

@(private)
lists: [3]tgl.GLuint

@(private)
gear :: proc(inner_radius, outer_radius, width: f32, teeth: int, tooth_depth: f32) {
	r0 := inner_radius
	r1 := outer_radius - tooth_depth / 2
	r2 := outer_radius + tooth_depth / 2
	da := 2 * math.PI / f32(teeth) / 4
	hw := width * 0.5

	tgl.Normal3f(0, 0, 1)

	// Front face.
	tgl.Begin(tgl.QUAD_STRIP)
	for i in 0 ..= teeth {
		a := f32(i) * 2 * math.PI / f32(teeth)
		tgl.Vertex3f(r0 * math.cos(a), r0 * math.sin(a), hw)
		tgl.Vertex3f(r1 * math.cos(a), r1 * math.sin(a), hw)
		tgl.Vertex3f(r0 * math.cos(a), r0 * math.sin(a), hw)
		tgl.Vertex3f(r1 * math.cos(a + 3 * da), r1 * math.sin(a + 3 * da), hw)
	}
	tgl.End()

	// Front sides of the teeth.
	tgl.Begin(tgl.QUADS)
	for i in 0 ..< teeth {
		a := f32(i) * 2 * math.PI / f32(teeth)
		tgl.Vertex3f(r1 * math.cos(a), r1 * math.sin(a), hw)
		tgl.Vertex3f(r2 * math.cos(a + da), r2 * math.sin(a + da), hw)
		tgl.Vertex3f(r2 * math.cos(a + 2 * da), r2 * math.sin(a + 2 * da), hw)
		tgl.Vertex3f(r1 * math.cos(a + 3 * da), r1 * math.sin(a + 3 * da), hw)
	}
	tgl.End()

	tgl.Normal3f(0, 0, -1)

	// Back face.
	tgl.Begin(tgl.QUAD_STRIP)
	for i in 0 ..= teeth {
		a := f32(i) * 2 * math.PI / f32(teeth)
		tgl.Vertex3f(r1 * math.cos(a), r1 * math.sin(a), -hw)
		tgl.Vertex3f(r0 * math.cos(a), r0 * math.sin(a), -hw)
		tgl.Vertex3f(r1 * math.cos(a + 3 * da), r1 * math.sin(a + 3 * da), -hw)
		tgl.Vertex3f(r0 * math.cos(a), r0 * math.sin(a), -hw)
	}
	tgl.End()

	// Back sides of the teeth.
	tgl.Begin(tgl.QUADS)
	for i in 0 ..< teeth {
		a := f32(i) * 2 * math.PI / f32(teeth)
		tgl.Vertex3f(r1 * math.cos(a + 3 * da), r1 * math.sin(a + 3 * da), -hw)
		tgl.Vertex3f(r2 * math.cos(a + 2 * da), r2 * math.sin(a + 2 * da), -hw)
		tgl.Vertex3f(r2 * math.cos(a + da), r2 * math.sin(a + da), -hw)
		tgl.Vertex3f(r1 * math.cos(a), r1 * math.sin(a), -hw)
	}
	tgl.End()

	// Outward faces of the teeth.
	tgl.Begin(tgl.QUAD_STRIP)
	for i in 0 ..< teeth {
		a := f32(i) * 2 * math.PI / f32(teeth)
		tgl.Vertex3f(r1 * math.cos(a), r1 * math.sin(a), hw)
		tgl.Vertex3f(r1 * math.cos(a), r1 * math.sin(a), -hw)
		u := r2 * math.cos(a + da) - r1 * math.cos(a)
		v := r2 * math.sin(a + da) - r1 * math.sin(a)
		l := math.sqrt(u * u + v * v)
		tgl.Normal3f(v / l, -u / l, 0)
		tgl.Vertex3f(r2 * math.cos(a + da), r2 * math.sin(a + da), hw)
		tgl.Vertex3f(r2 * math.cos(a + da), r2 * math.sin(a + da), -hw)
		tgl.Normal3f(math.cos(a), math.sin(a), 0)
		tgl.Vertex3f(r2 * math.cos(a + 2 * da), r2 * math.sin(a + 2 * da), hw)
		tgl.Vertex3f(r2 * math.cos(a + 2 * da), r2 * math.sin(a + 2 * da), -hw)
		u = r1 * math.cos(a + 3 * da) - r2 * math.cos(a + 2 * da)
		v = r1 * math.sin(a + 3 * da) - r2 * math.sin(a + 2 * da)
		tgl.Normal3f(v, -u, 0)
		tgl.Vertex3f(r1 * math.cos(a + 3 * da), r1 * math.sin(a + 3 * da), hw)
		tgl.Vertex3f(r1 * math.cos(a + 3 * da), r1 * math.sin(a + 3 * da), -hw)
		tgl.Normal3f(math.cos(a), math.sin(a), 0)
	}
	tgl.Vertex3f(r1, 0, hw)
	tgl.Vertex3f(r1, 0, -hw)
	tgl.End()

	// Inside radius cylinder.
	tgl.Begin(tgl.QUAD_STRIP)
	for i in 0 ..= teeth {
		a := f32(i) * 2 * math.PI / f32(teeth)
		tgl.Normal3f(-math.cos(a), -math.sin(a), 0)
		tgl.Vertex3f(r0 * math.cos(a), r0 * math.sin(a), -hw)
		tgl.Vertex3f(r0 * math.cos(a), r0 * math.sin(a), hw)
	}
	tgl.End()
}

// Set up the view, the light, and the three gears. Call tgl.Init first.
init :: proc(width, height: i32) {
	assert(width % 4 == 0, "TinyGL needs a framebuffer width that is a multiple of 4")

	tgl.ClearColor(0, 0, 0, 0)
	tgl.Viewport(0, 0, width, height)
	tgl.ShadeModel(tgl.SMOOTH)
	tgl.Enable(tgl.LIGHTING)
	tgl.Enable(tgl.DEPTH_TEST)
	tgl.Enable(tgl.CULL_FACE)

	// The same view volume as glFrustum(-1, 1, -h, h, 5, 60) in gears.c, made with core:math/linalg.
	h := f32(height) / f32(width)
	projection := linalg.matrix4_perspective_f32(2 * math.atan(h / 5), f32(width) / f32(height), 5, 60)
	tgl.MatrixMode(tgl.PROJECTION)
	tgl.LoadMatrixf(cast([^]f32)&projection)
	tgl.MatrixMode(tgl.MODELVIEW)
	tgl.LoadIdentity()
	tgl.Translatef(0, 0, -45)

	pos   := [4]f32{5, 5, 10, 0}
	red   := [4]f32{1, 0, 0, 0}
	green := [4]f32{0, 1, 0, 0}
	blue  := [4]f32{0, 0, 1, 0}
	white := [4]f32{1, 1, 1, 0}
	shininess: f32 = 5
	tgl.Lightfv(tgl.LIGHT0, tgl.POSITION, &pos[0])
	tgl.Lightfv(tgl.LIGHT0, tgl.DIFFUSE, &white[0])
	tgl.Lightfv(tgl.LIGHT0, tgl.SPECULAR, &white[0])
	tgl.Enable(tgl.LIGHT0)

	colors := [3][4]f32{blue, red, green}
	shapes := [3][5]f32{{1.0, 4.0, 1.0, 20, 0.7}, {0.5, 2.0, 2.0, 10, 0.7}, {1.3, 2.0, 0.5, 10, 0.7}}
	for &l, i in lists {
		l = tgl.GenLists(1)
		tgl.NewList(l, tgl.COMPILE)
		tgl.Materialfv(tgl.FRONT, tgl.DIFFUSE, &colors[i][0])
		tgl.Materialfv(tgl.FRONT, tgl.SPECULAR, &white[0])
		tgl.Materialfv(tgl.FRONT, tgl.SHININESS, &shininess)
		tgl.Color3fv(&colors[i][0])
		s := shapes[i]
		gear(s[0], s[1], s[2], int(s[3]), s[4])
		tgl.EndList()
	}
}

// Clear the buffers and draw the gears. angle is in degrees.
draw :: proc(angle: f32) {
	tgl.Clear(tgl.COLOR_BUFFER_BIT | tgl.DEPTH_BUFFER_BIT)
	tgl.PushMatrix()
	tgl.Rotatef(20, 1, 0, 0)
	tgl.Rotatef(30, 0, 1, 0)

	positions := [3][2]f32{{-3.0, -2.0}, {3.1, -2.0}, {-3.1, 4.2}}
	rotations := [3]f32{angle, -2 * angle - 9, -2 * angle - 25}
	for l, i in lists {
		tgl.PushMatrix()
		tgl.Translatef(positions[i].x, positions[i].y, 0)
		tgl.Rotatef(rotations[i], 0, 0, 1)
		tgl.CallList(l)
		tgl.PopMatrix()
	}

	tgl.PopMatrix()
}
