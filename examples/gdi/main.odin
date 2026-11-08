#+build windows
// Draw the rotating gears with TinyGL and show them in a Win32 window with GDI.
package main

import "core:fmt"
import "core:os"
import win "core:sys/windows"
import tgl "../.."
import "../gears"

W :: gears.WIDTH
H :: gears.HEIGHT

running := true

window_proc :: proc "system" (hwnd: win.HWND, msg: win.UINT, wparam: win.WPARAM, lparam: win.LPARAM) -> win.LRESULT {
	switch msg {
	case win.WM_DESTROY:
		running = false
		win.PostQuitMessage(0)
		return 0
	case win.WM_KEYDOWN:
		if wparam == win.VK_ESCAPE do win.DestroyWindow(hwnd)
		return 0
	}
	return win.DefWindowProcW(hwnd, msg, wparam, lparam)
}

main :: proc() {
	instance := win.HINSTANCE(win.GetModuleHandleW(nil))
	class_name: cstring16 = "TinyGLGears"
	class := win.WNDCLASSEXW {
		cbSize        = size_of(win.WNDCLASSEXW),
		lpfnWndProc   = window_proc,
		hInstance     = instance,
		hCursor       = win.LoadCursorA(nil, win.IDC_ARROW),
		lpszClassName = class_name,
	}
	if win.RegisterClassExW(&class) == 0 {
		fmt.eprintln("RegisterClassExW failed")
		os.exit(1)
	}

	// No WS_THICKFRAME and no WS_MAXIMIZEBOX: the user cannot resize the window.
	style := win.WS_OVERLAPPED | win.WS_CAPTION | win.WS_SYSMENU | win.WS_MINIMIZEBOX | win.WS_VISIBLE
	rect := win.RECT{0, 0, W, H}
	win.AdjustWindowRect(&rect, style, false)
	hwnd := win.CreateWindowExW(
		0, class_name, win.L("TinyGL gears (GDI)"), style,
		win.CW_USEDEFAULT, win.CW_USEDEFAULT, rect.right - rect.left, rect.bottom - rect.top,
		nil, nil, instance, nil,
	)
	if hwnd == nil {
		fmt.eprintln("CreateWindowExW failed")
		os.exit(1)
	}

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

	// 32-bit BI_RGB has the same layout as a 32-bit TinyGL pixel (0x00RRGGBB).
	// A negative height makes the rows go from top to bottom, as in TinyGL.
	info := win.BITMAPINFO {
		bmiHeader = {
			biSize        = size_of(win.BITMAPINFOHEADER),
			biWidth       = W,
			biHeight      = -H,
			biPlanes      = 1,
			biBitCount    = 32,
			biCompression = win.BI_RGB,
		},
	}

	angle: f32 = 0
	for running {
		msg: win.MSG
		for win.PeekMessageW(&msg, nil, 0, 0, win.PM_REMOVE) {
			win.TranslateMessage(&msg)
			win.DispatchMessageW(&msg)
		}
		if !running do break

		angle += 1
		gears.draw(angle)
		tgl.ZB_copyFrameBuffer(zb, raw_data(pixels), W * size_of(tgl.PIXEL))

		dc := win.GetDC(hwnd)
		win.StretchDIBits(dc, 0, 0, W, H, 0, 0, W, H, raw_data(pixels), &info, win.DIB_RGB_COLORS, win.SRCCOPY)
		win.ReleaseDC(hwnd, dc)
	}
}

