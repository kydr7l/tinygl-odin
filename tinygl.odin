// Bindings for the C-Chads TinyGL library (https://github.com/C-Chads/tinygl).
// The names agree with gl.h, without the "gl" and "GL_" prefixes.
package tinygl

import "core:c"

// These values must agree with zfeatures.h at the time of the library build.
RENDER_BITS  :: #config(TINYGL_RENDER_BITS, 32)
TEXTURE_POW2 :: #config(TINYGL_TEXTURE_POW2, 8)
TEXTURE_DIM  :: 1 << TEXTURE_POW2
// Set to true when the library was built with the "openmp" build option.
OPENMP       :: #config(TINYGL_OPENMP, false)

#assert(RENDER_BITS == 32 || RENDER_BITS == 16, "TINYGL_RENDER_BITS must be 16 or 32")

when ODIN_OS == .Windows {
	when OPENMP {
		foreign import lib {"lib/tinygl.lib", "lib/libomp.lib"}
	} else {
		foreign import lib "lib/tinygl.lib"
	}
} else {
	when OPENMP {
		foreign import lib {"lib/libtinygl.a", "system:m", "system:gomp"}
	} else {
		foreign import lib {"lib/libtinygl.a", "system:m"}
	}
}

GLvoid     :: rawptr
GLboolean  :: u8
GLbyte     :: i8
GLshort    :: c.short
GLint      :: c.int
GLenum     :: GLint
GLsizei    :: GLint
GLubyte    :: u8
GLushort   :: c.ushort
GLuint     :: c.uint
GLfloat    :: f32
GLdouble   :: f64
GLTEXTSIZE :: c.int

// ZBuffer is opaque. Use it only through a pointer from ZB_open.
ZBuffer :: struct {}

PIXEL :: u32 when RENDER_BITS == 32 else u16

ZB_MODE_5R6G5B :: 1 // 16-bit pixels: use when RENDER_BITS == 16
ZB_MODE_INDEX  :: 2 // not supported by the C-Chads fork
ZB_MODE_RGBA   :: 3 // 32-bit pixels: use when RENDER_BITS == 32
ZB_MODE_RGB24  :: 4 // not supported by the C-Chads fork

when RENDER_BITS == 32 {
	GET_RED   :: #force_inline proc "contextless" (p: PIXEL) -> u8 { return u8((p >> 16) & 0xff) }
	GET_GREEN :: #force_inline proc "contextless" (p: PIXEL) -> u8 { return u8((p >> 8) & 0xff) }
	GET_BLUE  :: #force_inline proc "contextless" (p: PIXEL) -> u8 { return u8(p & 0xff) }
} else {
	GET_RED   :: #force_inline proc "contextless" (p: PIXEL) -> u8 { return u8((p & 0xF800) >> 8) }
	GET_GREEN :: #force_inline proc "contextless" (p: PIXEL) -> u8 { return u8((p & 0x07E0) >> 3) }
	GET_BLUE  :: #force_inline proc "contextless" (p: PIXEL) -> u8 { return u8((p & 31) << 3) }
}

PostProcessProc :: #type proc "c" (x, y: GLint, pixel: GLuint, z: GLushort) -> GLuint

@(default_calling_convention = "c")
foreign lib {
	ZB_open            :: proc(xsize, ysize, mode: c.int, frame_buffer: rawptr) -> ^ZBuffer ---
	ZB_close           :: proc(zb: ^ZBuffer) ---
	ZB_resize          :: proc(zb: ^ZBuffer, frame_buffer: rawptr, xsize, ysize: GLint) ---
	// linesize is in bytes.
	ZB_copyFrameBuffer :: proc(zb: ^ZBuffer, buf: rawptr, linesize: GLint) ---
}

// gl.h declares 27 more functions that the library does not define:
// glColor3d, glColor3dv, glColor4d, glColor4dv, glNormal3d, glNormal3dv,
// glTexCoord1d to glTexCoord4d and their dv forms, glTexCoord1f, glTexCoord1fv,
// glTexCoord3f, glTexCoord3fv, glTexCoord4fv, glVertex2d to glVertex4d and their
// dv forms, glVertex2fv, and glVertex4fv. They are not bound, because a call to one cannot link.
@(default_calling_convention = "c", link_prefix = "gl")
foreign lib {
	AreTexturesResident :: proc(n: GLsizei, textures: [^]GLuint, residences: [^]GLboolean) -> GLboolean ---
	ArrayElement        :: proc(i: GLint) ---
	Begin               :: proc(type: GLint) ---
	BindBuffer          :: proc(target: GLenum, buffer: GLuint) ---
	BindBufferAsArray   :: proc(target: GLenum, buffer: GLuint, type: GLenum, size, stride: GLint) ---
	BindTexture         :: proc(target, texture: GLint) ---
	BlendEquation       :: proc(mode: GLenum) ---
	BlendFunc           :: proc(sfactor, dfactor: GLint) ---
	BufferData          :: proc(target: GLenum, size: GLsizei, data: rawptr, usage: GLenum) ---
	CallList            :: proc(list: GLuint) ---
	CallLists           :: proc(n: GLsizei, type: GLenum, lists: rawptr) ---
	Clear               :: proc(mask: GLint) ---
	ClearColor          :: proc(r, g, b, a: GLfloat) ---
	ClearDepth          :: proc(depth: GLdouble) ---
	Close               :: proc() ---
	Color3f             :: proc(r, g, b: GLfloat) ---
	Color3fv            :: proc(v: [^]GLfloat) ---
	Color4f             :: proc(r, g, b, a: GLfloat) ---
	Color4fv            :: proc(v: [^]GLfloat) ---
	ColorMaterial       :: proc(mode, type: GLint) ---
	ColorPointer        :: proc(size: GLint, type: GLenum, stride: GLsizei, pointer: rawptr) ---
	CopyTexImage2D      :: proc(target: GLenum, level: GLint, internalformat: GLenum, x, y: GLint, width, height: GLsizei, border: GLint) ---
	CullFace            :: proc(mode: GLint) ---
	Debug               :: proc(mode: GLint) ---
	DeleteBuffers       :: proc(n: GLsizei, buffers: [^]GLuint) ---
	DeleteList          :: proc(list: GLuint) ---
	DeleteLists         :: proc(list, range: GLuint) ---
	DeleteTextures      :: proc(n: GLint, textures: [^]GLuint) ---
	DepthMask           :: proc(flag: GLint) ---
	Disable             :: proc(code: GLint) ---
	DisableClientState  :: proc(array: GLenum) ---
	DrawArrays          :: proc(mode: GLenum, first: GLint, count: GLsizei) ---
	DrawBuffer          :: proc(mode: GLenum) ---
	DrawPixels          :: proc(width, height: GLsizei, format, type: GLenum, data: rawptr) ---
	DrawText            :: proc(text: cstring, x, y: GLint, pixel: GLuint) ---
	EdgeFlag            :: proc(flag: GLint) ---
	Enable              :: proc(code: GLint) ---
	EnableClientState   :: proc(array: GLenum) ---
	End                 :: proc() ---
	EndList             :: proc() ---
	FeedbackBuffer      :: proc(size: GLint, type: GLenum, buf: [^]GLfloat) ---
	Finish              :: proc() ---
	Flush               :: proc() ---
	FrontFace           :: proc(mode: GLint) ---
	Frustum             :: proc(left, right, bottom, top, near, far: GLdouble) ---
	GenBuffers          :: proc(n: GLsizei, buffers: [^]GLuint) ---
	GenLists            :: proc(range: GLint) -> GLuint ---
	GenTextures         :: proc(n: GLint, textures: [^]GLuint) ---
	GetError            :: proc() -> GLenum ---
	GetFloatv           :: proc(pname: GLint, v: [^]GLfloat) ---
	GetIntegerv         :: proc(pname: GLint, params: [^]GLint) ---
	GetString           :: proc(name: GLenum) -> cstring ---
	GetTexturePixmap    :: proc(text, level: GLint, xsize, ysize: ^GLint) -> rawptr ---
	Hint                :: proc(target, mode: GLint) ---
	Init                :: proc(zbuffer: rawptr) ---
	InitNames           :: proc() ---
	IsBuffer            :: proc(buffer: GLuint) -> GLboolean ---
	IsList              :: proc(list: GLuint) -> GLint ---
	IsTexture           :: proc(texture: GLuint) -> GLboolean ---
	LightModelfv        :: proc(pname: GLint, param: [^]GLfloat) ---
	LightModeli         :: proc(pname, param: GLint) ---
	Lightf              :: proc(light, type: GLint, v: GLfloat) ---
	Lightfv             :: proc(light, type: GLint, v: [^]GLfloat) ---
	ListBase            :: proc(n: GLint) ---
	LoadIdentity        :: proc() ---
	LoadMatrixf         :: proc(m: [^]GLfloat) ---
	LoadName            :: proc(name: GLuint) ---
	MapBuffer           :: proc(target, access: GLenum) -> rawptr ---
	Materialf           :: proc(mode, type: GLint, v: GLfloat) ---
	Materialfv          :: proc(mode, type: GLint, v: [^]GLfloat) ---
	MatrixMode          :: proc(mode: GLint) ---
	MultMatrixf         :: proc(m: [^]GLfloat) ---
	NewList             :: proc(list: GLuint, mode: GLint) ---
	Normal3f            :: proc(x, y, z: GLfloat) ---
	Normal3fv           :: proc(v: [^]GLfloat) ---
	NormalPointer       :: proc(type: GLenum, stride: GLsizei, pointer: rawptr) ---
	PassThrough         :: proc(token: GLfloat) ---
	PixelZoom           :: proc(x, y: GLfloat) ---
	PlotPixel           :: proc(x, y: GLint, pixel: GLuint) ---
	PointSize           :: proc(size: GLfloat) ---
	PolygonMode         :: proc(face, mode: GLint) ---
	PolygonOffset       :: proc(factor, units: GLfloat) ---
	PolygonStipple      :: proc(mask: rawptr) ---
	PopMatrix           :: proc() ---
	PopName             :: proc() ---
	PostProcess         :: proc(postprocess: PostProcessProc) ---
	PushMatrix          :: proc() ---
	PushName            :: proc(name: GLuint) ---
	RasterPos2f         :: proc(x, y: GLfloat) ---
	RasterPos2fv        :: proc(v: [^]GLfloat) ---
	RasterPos3f         :: proc(x, y, z: GLfloat) ---
	RasterPos3fv        :: proc(v: [^]GLfloat) ---
	RasterPos4f         :: proc(x, y, z, w: GLfloat) ---
	RasterPos4fv        :: proc(v: [^]GLfloat) ---
	ReadBuffer          :: proc(mode: GLenum) ---
	ReadPixels          :: proc(x, y: GLint, width, height: GLsizei, format, type: GLenum, data: rawptr) ---
	Rectf               :: proc(x1, y1, x2, y2: GLfloat) ---
	RenderMode          :: proc(mode: GLint) -> GLint ---
	Rotatef             :: proc(angle, x, y, z: GLfloat) ---
	Scalef              :: proc(x, y, z: GLfloat) ---
	SelectBuffer        :: proc(size: GLint, buf: [^]GLuint) ---
	SetEnableSpecular   :: proc(s: GLint) ---
	ShadeModel          :: proc(mode: GLint) ---
	TexCoord2f          :: proc(s, t: GLfloat) ---
	TexCoord2fv         :: proc(v: [^]GLfloat) ---
	TexCoord4f          :: proc(s, t, r, q: GLfloat) ---
	TexCoordPointer     :: proc(size: GLint, type: GLenum, stride: GLsizei, pointer: rawptr) ---
	TexEnvi             :: proc(target, pname, param: GLint) ---
	TexImage1D          :: proc(target, level, components, width, border, format, type: GLint, pixels: rawptr) ---
	TexImage2D          :: proc(target, level, components, width, height, border, format, type: GLint, pixels: rawptr) ---
	TexParameteri       :: proc(target, pname, param: GLint) ---
	TextSize            :: proc(mode: GLTEXTSIZE) ---
	Translatef          :: proc(x, y, z: GLfloat) ---
	Vertex2f            :: proc(x, y: GLfloat) ---
	Vertex3f            :: proc(x, y, z: GLfloat) ---
	Vertex3fv           :: proc(v: [^]GLfloat) ---
	Vertex4f            :: proc(x, y, z, w: GLfloat) ---
	VertexPointer       :: proc(size: GLint, type: GLenum, stride: GLsizei, pointer: rawptr) ---
	Viewport            :: proc(x, y, width, height: GLint) ---
}

// Constants from gl.h. A name that starts with a digit after the prefix removal gets a "_" prefix (GL_2D is _2D).
FALSE                                :: 0
TRUE                                 :: 1
BYTE                                 :: 0x1400
UNSIGNED_BYTE                        :: 0x1401
SHORT                                :: 0x1402
UNSIGNED_SHORT                       :: 0x1403
INT                                  :: 0x1404
UNSIGNED_INT                         :: 0x1405
FLOAT                                :: 0x1406
DOUBLE                               :: 0x140A
_2_BYTES                             :: 0x1407
_3_BYTES                             :: 0x1408
_4_BYTES                             :: 0x1409
UNSIGNED_SHORT_5_6_5                 :: 0x140A
UNSIGNED_INT_8_8_8_8                 :: 0x140B
LINES                                :: 0x0001
POINTS                               :: 0x0000
LINE_STRIP                           :: 0x0003
LINE_LOOP                            :: 0x0002
TRIANGLES                            :: 0x0004
TRIANGLE_STRIP                       :: 0x0005
TRIANGLE_FAN                         :: 0x0006
QUADS                                :: 0x0007
QUAD_STRIP                           :: 0x0008
POLYGON                              :: 0x0009
EDGE_FLAG                            :: 0x0B43
STATIC_DRAW                          :: 0x88E4
VERTEX_ARRAY                         :: 0x8074
VERTEX_BUFFER                        :: 0x8074
NORMAL_ARRAY                         :: 0x8075
NORMAL_BUFFER                        :: 0x8075
COLOR_ARRAY                          :: 0x8076
COLOR_BUFFER                         :: 0x8076
INDEX_ARRAY                          :: 0x8077
TEXTURE_COORD_ARRAY                  :: 0x8078
TEXTURE_COORD_BUFFER                 :: 0x8078
EDGE_FLAG_ARRAY                      :: 0x8079
VERTEX_ARRAY_SIZE                    :: 0x807A
VERTEX_ARRAY_TYPE                    :: 0x807B
VERTEX_ARRAY_STRIDE                  :: 0x807C
VERTEX_ARRAY_COUNT                   :: 0x807D
NORMAL_ARRAY_TYPE                    :: 0x807E
NORMAL_ARRAY_STRIDE                  :: 0x807F
NORMAL_ARRAY_COUNT                   :: 0x8080
COLOR_ARRAY_SIZE                     :: 0x8081
COLOR_ARRAY_TYPE                     :: 0x8082
COLOR_ARRAY_STRIDE                   :: 0x8083
COLOR_ARRAY_COUNT                    :: 0x8084
INDEX_ARRAY_TYPE                     :: 0x8085
INDEX_ARRAY_STRIDE                   :: 0x8086
INDEX_ARRAY_COUNT                    :: 0x8087
TEXTURE_COORD_ARRAY_SIZE             :: 0x8088
TEXTURE_COORD_ARRAY_TYPE             :: 0x8089
TEXTURE_COORD_ARRAY_STRIDE           :: 0x808A
TEXTURE_COORD_ARRAY_COUNT            :: 0x808B
EDGE_FLAG_ARRAY_STRIDE               :: 0x808C
EDGE_FLAG_ARRAY_COUNT                :: 0x808D
VERTEX_ARRAY_POINTER                 :: 0x808E
NORMAL_ARRAY_POINTER                 :: 0x808F
COLOR_ARRAY_POINTER                  :: 0x8090
INDEX_ARRAY_POINTER                  :: 0x8091
TEXTURE_COORD_ARRAY_POINTER          :: 0x8092
EDGE_FLAG_ARRAY_POINTER              :: 0x8093
V2F                                  :: 0x2A20
V3F                                  :: 0x2A21
C4UB_V2F                             :: 0x2A22
C4UB_V3F                             :: 0x2A23
C3F_V3F                              :: 0x2A24
N3F_V3F                              :: 0x2A25
C4F_N3F_V3F                          :: 0x2A26
T2F_V3F                              :: 0x2A27
T4F_V4F                              :: 0x2A28
T2F_C4UB_V3F                         :: 0x2A29
T2F_C3F_V3F                          :: 0x2A2A
T2F_N3F_V3F                          :: 0x2A2B
T2F_C4F_N3F_V3F                      :: 0x2A2C
T4F_C4F_N3F_V4F                      :: 0x2A2D
MATRIX_MODE                          :: 0x0BA0
MODELVIEW                            :: 0x1700
PROJECTION                           :: 0x1701
TEXTURE                              :: 0x1702
POINT_SMOOTH                         :: 0x0B10
POINT_SIZE                           :: 0x0B11
POINT_SIZE_GRANULARITY               :: 0x0B13
POINT_SIZE_RANGE                     :: 0x0B12
LINE_SMOOTH                          :: 0x0B20
LINE_STIPPLE                         :: 0x0B24
LINE_STIPPLE_PATTERN                 :: 0x0B25
LINE_STIPPLE_REPEAT                  :: 0x0B26
LINE_WIDTH                           :: 0x0B21
LINE_WIDTH_GRANULARITY               :: 0x0B23
LINE_WIDTH_RANGE                     :: 0x0B22
POINT                                :: 0x1B00
LINE                                 :: 0x1B01
FILL                                 :: 0x1B02
CCW                                  :: 0x0901
CW                                   :: 0x0900
FRONT                                :: 0x0404
BACK                                 :: 0x0405
CULL_FACE                            :: 0x0B44
CULL_FACE_MODE                       :: 0x0B45
POLYGON_SMOOTH                       :: 0x0B41
POLYGON_STIPPLE                      :: 0x0B42
FRONT_FACE                           :: 0x0B46
POLYGON_MODE                         :: 0x0B40
POLYGON_OFFSET_FACTOR                :: 0x3038
POLYGON_OFFSET_UNITS                 :: 0x2A00
POLYGON_OFFSET_POINT                 :: 0x2A01
POLYGON_OFFSET_LINE                  :: 0x2A02
POLYGON_OFFSET_FILL                  :: 0x8037
COMPILE                              :: 0x1300
COMPILE_AND_EXECUTE                  :: 0x1301
LIST_BASE                            :: 0x0B32
LIST_INDEX                           :: 0x0B33
LIST_MODE                            :: 0x0B30
POLYGON_MAX_VERTEX                   :: 0xf001
MAX_BUFFERS                          :: 0xf002
TEXTURE_HASH_TABLE_SIZE              :: 0xf003
MAX_TEXTURE_LEVELS                   :: 0xf004
MAX_SPECULAR_BUFFERS                 :: 0xf005
MAX_DISPLAY_LISTS                    :: 0xf006
ERROR_CHECK_LEVEL                    :: 0xf007
IS_SPECULAR_ENABLED                  :: 0xf008
NEVER                                :: 0x0200
LESS                                 :: 0x0201
GEQUAL                               :: 0x0206
LEQUAL                               :: 0x0203
GREATER                              :: 0x0204
NOTEQUAL                             :: 0x0205
EQUAL                                :: 0x0202
ALWAYS                               :: 0x0207
DEPTH_TEST                           :: 0x0B71
DEPTH_BITS                           :: 0x0D56
DEPTH_CLEAR_VALUE                    :: 0x0B73
DEPTH_FUNC                           :: 0x0B74
DEPTH_RANGE                          :: 0x0B70
DEPTH_WRITEMASK                      :: 0x0B72
DEPTH_COMPONENT                      :: 0x1902
LIGHTING                             :: 0x0B50
LIGHT0                               :: 0x4000
LIGHT1                               :: 0x4001
LIGHT2                               :: 0x4002
LIGHT3                               :: 0x4003
LIGHT4                               :: 0x4004
LIGHT5                               :: 0x4005
LIGHT6                               :: 0x4006
LIGHT7                               :: 0x4007
LIGHT8                               :: 0x4008
LIGHT9                               :: 0x4009
LIGHT10                              :: 0x400A
LIGHT11                              :: 0x400B
LIGHT12                              :: 0x400C
LIGHT13                              :: 0x400D
LIGHT14                              :: 0x400E
LIGHT15                              :: 0x400F
SPOT_EXPONENT                        :: 0x1205
SPOT_CUTOFF                          :: 0x1206
CONSTANT_ATTENUATION                 :: 0x1207
LINEAR_ATTENUATION                   :: 0x1208
QUADRATIC_ATTENUATION                :: 0x1209
AMBIENT                              :: 0x1200
DIFFUSE                              :: 0x1201
SPECULAR                             :: 0x1202
SHININESS                            :: 0x1601
EMISSION                             :: 0x1600
POSITION                             :: 0x1203
SPOT_DIRECTION                       :: 0x1204
AMBIENT_AND_DIFFUSE                  :: 0x1602
COLOR_INDEXES                        :: 0x1603
LIGHT_MODEL_TWO_SIDE                 :: 0x0B52
LIGHT_MODEL_LOCAL_VIEWER             :: 0x0B51
LIGHT_MODEL_AMBIENT                  :: 0x0B53
FRONT_AND_BACK                       :: 0x0408
SHADE_MODEL                          :: 0x0B54
FLAT                                 :: 0x1D00
SMOOTH                               :: 0x1D01
COLOR_MATERIAL                       :: 0x0B57
COLOR_MATERIAL_FACE                  :: 0x0B55
COLOR_MATERIAL_PARAMETER             :: 0x0B56
NORMALIZE                            :: 0x0BA1
CLIP_PLANE0                          :: 0x3000
CLIP_PLANE1                          :: 0x3001
CLIP_PLANE2                          :: 0x3002
CLIP_PLANE3                          :: 0x3003
CLIP_PLANE4                          :: 0x3004
CLIP_PLANE5                          :: 0x3005
ACCUM_RED_BITS                       :: 0x0D58
ACCUM_GREEN_BITS                     :: 0x0D59
ACCUM_BLUE_BITS                      :: 0x0D5A
ACCUM_ALPHA_BITS                     :: 0x0D5B
ACCUM_CLEAR_VALUE                    :: 0x0B80
ACCUM                                :: 0x0100
ADD                                  :: 0x0104
LOAD                                 :: 0x0101
MULT                                 :: 0x0103
RETURN                               :: 0x0102
ALPHA_TEST                           :: 0x0BC0
ALPHA_TEST_REF                       :: 0x0BC2
ALPHA_TEST_FUNC                      :: 0x0BC1
BLEND                                :: 0x0BE2
BLEND_SRC                            :: 0x0BE1
BLEND_DST                            :: 0x0BE0
ZERO                                 :: 0
ONE                                  :: 1
SRC_COLOR                            :: 0x0300
ONE_MINUS_SRC_COLOR                  :: 0x0301
DST_COLOR                            :: 0x0306
ONE_MINUS_DST_COLOR                  :: 0x0307
SRC_ALPHA                            :: 0x0302
ONE_MINUS_SRC_ALPHA                  :: 0x0303
DST_ALPHA                            :: 0x0304
ONE_MINUS_DST_ALPHA                  :: 0x0305
SRC_ALPHA_SATURATE                   :: 0x0308
CONSTANT_COLOR                       :: 0x8001
ONE_MINUS_CONSTANT_COLOR             :: 0x8002
CONSTANT_ALPHA                       :: 0x8003
ONE_MINUS_CONSTANT_ALPHA             :: 0x8004
FEEDBACK                             :: 0x1C01
RENDER                               :: 0x1C00
SELECT                               :: 0x1C02
_2D                                  :: 0x0600
_3D                                  :: 0x0601
_3D_COLOR                            :: 0x0602
_3D_COLOR_TEXTURE                    :: 0x0603
_4D_COLOR_TEXTURE                    :: 0x0604
POINT_TOKEN                          :: 0x0701
LINE_TOKEN                           :: 0x0702
LINE_RESET_TOKEN                     :: 0x0707
POLYGON_TOKEN                        :: 0x0703
BITMAP_TOKEN                         :: 0x0704
DRAW_PIXEL_TOKEN                     :: 0x0705
COPY_PIXEL_TOKEN                     :: 0x0706
PASS_THROUGH_TOKEN                   :: 0x0700
FOG                                  :: 0x0B60
FOG_MODE                             :: 0x0B65
FOG_DENSITY                          :: 0x0B62
FOG_COLOR                            :: 0x0B66
FOG_INDEX                            :: 0x0B61
FOG_START                            :: 0x0B63
FOG_END                              :: 0x0B64
LINEAR                               :: 0x2601
EXP                                  :: 0x0800
EXP2                                 :: 0x0801
LOGIC_OP                             :: 0x0BF1
LOGIC_OP_MODE                        :: 0x0BF0
CLEAR                                :: 0x1500
SET                                  :: 0x150F
COPY                                 :: 0x1503
COPY_INVERTED                        :: 0x150C
NOOP                                 :: 0x1505
INVERT                               :: 0x150A
AND                                  :: 0x1501
NAND                                 :: 0x150E
OR                                   :: 0x1507
NOR                                  :: 0x1508
XOR                                  :: 0x1506
EQUIV                                :: 0x1509
AND_REVERSE                          :: 0x1502
AND_INVERTED                         :: 0x1504
OR_REVERSE                           :: 0x150B
OR_INVERTED                          :: 0x150D
STENCIL_TEST                         :: 0x0B90
STENCIL_WRITEMASK                    :: 0x0B98
STENCIL_BITS                         :: 0x0D57
STENCIL_FUNC                         :: 0x0B92
STENCIL_VALUE_MASK                   :: 0x0B93
STENCIL_REF                          :: 0x0B97
STENCIL_FAIL                         :: 0x0B94
STENCIL_PASS_DEPTH_PASS              :: 0x0B96
STENCIL_PASS_DEPTH_FAIL              :: 0x0B95
STENCIL_CLEAR_VALUE                  :: 0x0B91
STENCIL_INDEX                        :: 0x1901
KEEP                                 :: 0x1E00
REPLACE                              :: 0x1E01
INCR                                 :: 0x1E02
DECR                                 :: 0x1E03
NONE                                 :: 0
LEFT                                 :: 0x0406
RIGHT                                :: 0x0407
FRONT_LEFT                           :: 0x0400
FRONT_RIGHT                          :: 0x0401
BACK_LEFT                            :: 0x0402
BACK_RIGHT                           :: 0x0403
AUX0                                 :: 0x0409
AUX1                                 :: 0x040A
AUX2                                 :: 0x040B
AUX3                                 :: 0x040C
COLOR_INDEX                          :: 0x1900
RED                                  :: 0x1903
GREEN                                :: 0x1904
BLUE                                 :: 0x1905
ALPHA                                :: 0x1906
LUMINANCE                            :: 0x1909
LUMINANCE_ALPHA                      :: 0x190A
ALPHA_BITS                           :: 0x0D55
RED_BITS                             :: 0x0D52
GREEN_BITS                           :: 0x0D53
BLUE_BITS                            :: 0x0D54
INDEX_BITS                           :: 0x0D51
SUBPIXEL_BITS                        :: 0x0D50
AUX_BUFFERS                          :: 0x0C00
READ_BUFFER                          :: 0x0C02
DRAW_BUFFER                          :: 0x0C01
DOUBLEBUFFER                         :: 0x0C32
STEREO                               :: 0x0C33
BITMAP                               :: 0x1A00
COLOR                                :: 0x1800
DEPTH                                :: 0x1801
STENCIL                              :: 0x1802
DITHER                               :: 0x0BD0
RGB                                  :: 0x1907
RGBA                                 :: 0x1908
MAX_LIST_NESTING                     :: 0x0B31
MAX_ATTRIB_STACK_DEPTH               :: 0x0D35
MAX_MODELVIEW_STACK_DEPTH            :: 0x0D36
MAX_NAME_STACK_DEPTH                 :: 0x0D37
MAX_PROJECTION_STACK_DEPTH           :: 0x0D38
MAX_TEXTURE_STACK_DEPTH              :: 0x0D39
MAX_EVAL_ORDER                       :: 0x0D30
MAX_LIGHTS                           :: 0x0D31
MAX_CLIP_PLANES                      :: 0x0D32
MAX_TEXTURE_SIZE                     :: 0x0D33
MAX_PIXEL_MAP_TABLE                  :: 0x0D34
MAX_VIEWPORT_DIMS                    :: 0x0D3A
MAX_CLIENT_ATTRIB_STACK_DEPTH        :: 0x0D3B
ATTRIB_STACK_DEPTH                   :: 0x0BB0
COLOR_CLEAR_VALUE                    :: 0x0C22
COLOR_WRITEMASK                      :: 0x0C23
CURRENT_INDEX                        :: 0x0B01
CURRENT_COLOR                        :: 0x0B00
CURRENT_NORMAL                       :: 0x0B02
CURRENT_RASTER_COLOR                 :: 0x0B04
CURRENT_RASTER_DISTANCE              :: 0x0B09
CURRENT_RASTER_INDEX                 :: 0x0B05
CURRENT_RASTER_POSITION              :: 0x0B07
CURRENT_RASTER_TEXTURE_COORDS        :: 0x0B06
CURRENT_RASTER_POSITION_VALID        :: 0x0B08
CURRENT_TEXTURE_COORDS               :: 0x0B03
INDEX_CLEAR_VALUE                    :: 0x0C20
INDEX_MODE                           :: 0x0C30
INDEX_WRITEMASK                      :: 0x0C21
MODELVIEW_MATRIX                     :: 0x0BA6
MODELVIEW_STACK_DEPTH                :: 0x0BA3
NAME_STACK_DEPTH                     :: 0x0D70
PROJECTION_MATRIX                    :: 0x0BA7
PROJECTION_STACK_DEPTH               :: 0x0BA4
RENDER_MODE                          :: 0x0C40
RGBA_MODE                            :: 0x0C31
TEXTURE_MATRIX                       :: 0x0BA8
TEXTURE_STACK_DEPTH                  :: 0x0BA5
VIEWPORT                             :: 0x0BA2
AUTO_NORMAL                          :: 0x0D80
MAP1_COLOR_4                         :: 0x0D90
MAP1_GRID_DOMAIN                     :: 0x0DD0
MAP1_GRID_SEGMENTS                   :: 0x0DD1
MAP1_INDEX                           :: 0x0D91
MAP1_NORMAL                          :: 0x0D92
MAP1_TEXTURE_COORD_1                 :: 0x0D93
MAP1_TEXTURE_COORD_2                 :: 0x0D94
MAP1_TEXTURE_COORD_3                 :: 0x0D95
MAP1_TEXTURE_COORD_4                 :: 0x0D96
MAP1_VERTEX_3                        :: 0x0D97
MAP1_VERTEX_4                        :: 0x0D98
MAP2_COLOR_4                         :: 0x0DB0
MAP2_GRID_DOMAIN                     :: 0x0DD2
MAP2_GRID_SEGMENTS                   :: 0x0DD3
MAP2_INDEX                           :: 0x0DB1
MAP2_NORMAL                          :: 0x0DB2
MAP2_TEXTURE_COORD_1                 :: 0x0DB3
MAP2_TEXTURE_COORD_2                 :: 0x0DB4
MAP2_TEXTURE_COORD_3                 :: 0x0DB5
MAP2_TEXTURE_COORD_4                 :: 0x0DB6
MAP2_VERTEX_3                        :: 0x0DB7
MAP2_VERTEX_4                        :: 0x0DB8
COEFF                                :: 0x0A00
DOMAIN                               :: 0x0A02
ORDER                                :: 0x0A01
FOG_HINT                             :: 0x0C54
LINE_SMOOTH_HINT                     :: 0x0C52
PERSPECTIVE_CORRECTION_HINT          :: 0x0C50
POINT_SMOOTH_HINT                    :: 0x0C51
POLYGON_SMOOTH_HINT                  :: 0x0C53
DONT_CARE                            :: 0x1100
FASTEST                              :: 0x1101
NICEST                               :: 0x1102
SCISSOR_TEST                         :: 0x0C11
SCISSOR_BOX                          :: 0x0C10
MAP_COLOR                            :: 0x0D10
MAP_STENCIL                          :: 0x0D11
INDEX_SHIFT                          :: 0x0D12
INDEX_OFFSET                         :: 0x0D13
RED_SCALE                            :: 0x0D14
RED_BIAS                             :: 0x0D15
GREEN_SCALE                          :: 0x0D18
GREEN_BIAS                           :: 0x0D19
BLUE_SCALE                           :: 0x0D1A
BLUE_BIAS                            :: 0x0D1B
ALPHA_SCALE                          :: 0x0D1C
ALPHA_BIAS                           :: 0x0D1D
DEPTH_SCALE                          :: 0x0D1E
DEPTH_BIAS                           :: 0x0D1F
PIXEL_MAP_S_TO_S_SIZE                :: 0x0CB1
PIXEL_MAP_I_TO_I_SIZE                :: 0x0CB0
PIXEL_MAP_I_TO_R_SIZE                :: 0x0CB2
PIXEL_MAP_I_TO_G_SIZE                :: 0x0CB3
PIXEL_MAP_I_TO_B_SIZE                :: 0x0CB4
PIXEL_MAP_I_TO_A_SIZE                :: 0x0CB5
PIXEL_MAP_R_TO_R_SIZE                :: 0x0CB6
PIXEL_MAP_G_TO_G_SIZE                :: 0x0CB7
PIXEL_MAP_B_TO_B_SIZE                :: 0x0CB8
PIXEL_MAP_A_TO_A_SIZE                :: 0x0CB9
PIXEL_MAP_S_TO_S                     :: 0x0C71
PIXEL_MAP_I_TO_I                     :: 0x0C70
PIXEL_MAP_I_TO_R                     :: 0x0C72
PIXEL_MAP_I_TO_G                     :: 0x0C73
PIXEL_MAP_I_TO_B                     :: 0x0C74
PIXEL_MAP_I_TO_A                     :: 0x0C75
PIXEL_MAP_R_TO_R                     :: 0x0C76
PIXEL_MAP_G_TO_G                     :: 0x0C77
PIXEL_MAP_B_TO_B                     :: 0x0C78
PIXEL_MAP_A_TO_A                     :: 0x0C79
PACK_ALIGNMENT                       :: 0x0D05
PACK_LSB_FIRST                       :: 0x0D01
PACK_ROW_LENGTH                      :: 0x0D02
PACK_SKIP_PIXELS                     :: 0x0D04
PACK_SKIP_ROWS                       :: 0x0D03
PACK_SWAP_BYTES                      :: 0x0D00
UNPACK_ALIGNMENT                     :: 0x0CF5
UNPACK_LSB_FIRST                     :: 0x0CF1
UNPACK_ROW_LENGTH                    :: 0x0CF2
UNPACK_SKIP_PIXELS                   :: 0x0CF4
UNPACK_SKIP_ROWS                     :: 0x0CF3
UNPACK_SWAP_BYTES                    :: 0x0CF0
ZOOM_X                               :: 0x0D16
ZOOM_Y                               :: 0x0D17
TEXTURE_ENV                          :: 0x2300
TEXTURE_ENV_MODE                     :: 0x2200
TEXTURE_1D                           :: 0x0DE0
TEXTURE_2D                           :: 0x0DE1
TEXTURE_WRAP_S                       :: 0x2802
TEXTURE_WRAP_T                       :: 0x2803
TEXTURE_MAG_FILTER                   :: 0x2800
TEXTURE_MIN_FILTER                   :: 0x2801
TEXTURE_ENV_COLOR                    :: 0x2201
TEXTURE_GEN_S                        :: 0x0C60
TEXTURE_GEN_T                        :: 0x0C61
TEXTURE_GEN_MODE                     :: 0x2500
TEXTURE_BORDER_COLOR                 :: 0x1004
TEXTURE_WIDTH                        :: 0x1000
TEXTURE_HEIGHT                       :: 0x1001
TEXTURE_BORDER                       :: 0x1005
TEXTURE_COMPONENTS                   :: 0x1003
NEAREST_MIPMAP_NEAREST               :: 0x2700
NEAREST_MIPMAP_LINEAR                :: 0x2702
LINEAR_MIPMAP_NEAREST                :: 0x2701
LINEAR_MIPMAP_LINEAR                 :: 0x2703
OBJECT_LINEAR                        :: 0x2401
OBJECT_PLANE                         :: 0x2501
EYE_LINEAR                           :: 0x2400
EYE_PLANE                            :: 0x2502
SPHERE_MAP                           :: 0x2402
DECAL                                :: 0x2101
MODULATE                             :: 0x2100
NEAREST                              :: 0x2600
REPEAT                               :: 0x2901
CLAMP                                :: 0x2900
S                                    :: 0x2000
T                                    :: 0x2001
R                                    :: 0x2002
Q                                    :: 0x2003
TEXTURE_GEN_R                        :: 0x0C62
TEXTURE_GEN_Q                        :: 0x0C63
PROXY_TEXTURE_1D                     :: 0x8063
PROXY_TEXTURE_2D                     :: 0x8064
TEXTURE_PRIORITY                     :: 0x8066
TEXTURE_RESIDENT                     :: 0x8067
TEXTURE_1D_BINDING                   :: 0x8068
TEXTURE_2D_BINDING                   :: 0x8069
ALPHA4                               :: 0x803B
ALPHA8                               :: 0x803C
ALPHA12                              :: 0x803D
ALPHA16                              :: 0x803E
LUMINANCE4                           :: 0x803F
LUMINANCE8                           :: 0x8040
LUMINANCE12                          :: 0x8041
LUMINANCE16                          :: 0x8042
LUMINANCE4_ALPHA4                    :: 0x8043
LUMINANCE6_ALPHA2                    :: 0x8044
LUMINANCE8_ALPHA8                    :: 0x8045
LUMINANCE12_ALPHA4                   :: 0x8046
LUMINANCE12_ALPHA12                  :: 0x8047
LUMINANCE16_ALPHA16                  :: 0x8048
INTENSITY                            :: 0x8049
INTENSITY4                           :: 0x804A
INTENSITY8                           :: 0x804B
INTENSITY12                          :: 0x804C
INTENSITY16                          :: 0x804D
R3_G3_B2                             :: 0x2A10
RGB4                                 :: 0x804F
RGB5                                 :: 0x8050
RGB8                                 :: 0x8051
RGB10                                :: 0x8052
RGB12                                :: 0x8053
RGB16                                :: 0x8054
RGBA2                                :: 0x8055
RGBA4                                :: 0x8056
RGB5_A1                              :: 0x8057
RGBA8                                :: 0x8058
RGB10_A2                             :: 0x8059
RGBA12                               :: 0x805A
RGBA16                               :: 0x805B
VENDOR                               :: 0x1F00
RENDERER                             :: 0x1F01
VERSION                              :: 0x1F02
EXTENSIONS                           :: 0x1F03
LICENSE                              :: 0x1F04
NO_ERROR                             :: 0x0
INVALID_VALUE                        :: 0x0501
INVALID_ENUM                         :: 0x0500
INVALID_OPERATION                    :: 0x0502
STACK_OVERFLOW                       :: 0x0503
STACK_UNDERFLOW                      :: 0x0504
OUT_OF_MEMORY                        :: 0x0505
CONSTANT_COLOR_EXT                   :: 0x8001
ONE_MINUS_CONSTANT_COLOR_EXT         :: 0x8002
CONSTANT_ALPHA_EXT                   :: 0x8003
ONE_MINUS_CONSTANT_ALPHA_EXT         :: 0x8004
BLEND_EQUATION_EXT                   :: 0x8009
BLEND_EQUATION                       :: 0x8009
MIN_EXT                              :: 0x8007
MAX_EXT                              :: 0x8008
FUNC_ADD_EXT                         :: 0x8006
FUNC_ADD                             :: 0x8006
FUNC_SUBTRACT_EXT                    :: 0x800A
FUNC_SUBTRACT                        :: 0x800A
FUNC_REVERSE_SUBTRACT_EXT            :: 0x800B
FUNC_REVERSE_SUBTRACT                :: 0x800B
BLEND_COLOR_EXT                      :: 0x8005
POLYGON_OFFSET_EXT                   :: 0x8037
POLYGON_OFFSET_FACTOR_EXT            :: 0x8038
POLYGON_OFFSET_BIAS_EXT              :: 0x8039
ARRAY_BUFFER                         :: 0x8892
VERTEX_ARRAY_EXT                     :: 0x8074
NORMAL_ARRAY_EXT                     :: 0x8075
COLOR_ARRAY_EXT                      :: 0x8076
INDEX_ARRAY_EXT                      :: 0x8077
TEXTURE_COORD_ARRAY_EXT              :: 0x8078
EDGE_FLAG_ARRAY_EXT                  :: 0x8079
VERTEX_ARRAY_SIZE_EXT                :: 0x807A
VERTEX_ARRAY_TYPE_EXT                :: 0x807B
VERTEX_ARRAY_STRIDE_EXT              :: 0x807C
VERTEX_ARRAY_COUNT_EXT               :: 0x807D
NORMAL_ARRAY_TYPE_EXT                :: 0x807E
NORMAL_ARRAY_STRIDE_EXT              :: 0x807F
NORMAL_ARRAY_COUNT_EXT               :: 0x8080
COLOR_ARRAY_SIZE_EXT                 :: 0x8081
COLOR_ARRAY_TYPE_EXT                 :: 0x8082
COLOR_ARRAY_STRIDE_EXT               :: 0x8083
COLOR_ARRAY_COUNT_EXT                :: 0x8084
INDEX_ARRAY_TYPE_EXT                 :: 0x8085
INDEX_ARRAY_STRIDE_EXT               :: 0x8086
INDEX_ARRAY_COUNT_EXT                :: 0x8087
TEXTURE_COORD_ARRAY_SIZE_EXT         :: 0x8088
TEXTURE_COORD_ARRAY_TYPE_EXT         :: 0x8089
TEXTURE_COORD_ARRAY_STRIDE_EXT       :: 0x808A
TEXTURE_COORD_ARRAY_COUNT_EXT        :: 0x808B
EDGE_FLAG_ARRAY_STRIDE_EXT           :: 0x808C
EDGE_FLAG_ARRAY_COUNT_EXT            :: 0x808D
VERTEX_ARRAY_POINTER_EXT             :: 0x808E
NORMAL_ARRAY_POINTER_EXT             :: 0x808F
COLOR_ARRAY_POINTER_EXT              :: 0x8090
INDEX_ARRAY_POINTER_EXT              :: 0x8091
TEXTURE_COORD_ARRAY_POINTER_EXT      :: 0x8092
EDGE_FLAG_ARRAY_POINTER_EXT          :: 0x8093
TEXT_SIZE8x8                         :: 1
TEXT_SIZE16x16                       :: 2
TEXT_SIZE24x24                       :: 3
TEXT_SIZE32x32                       :: 4
TEXT_SIZE40x40                       :: 5
TEXT_SIZE48x48                       :: 6
TEXT_SIZE56x56                       :: 7
TEXT_SIZE64x64                       :: 8
TEXT_SIZE72x72                       :: 9
TEXT_SIZE80x80                       :: 10
TEXT_SIZE88x88                       :: 11
TEXT_SIZE96x96                       :: 12
TEXT_SIZE104x104                     :: 13
TEXT_SIZE112x112                     :: 14
TEXT_SIZE120x120                     :: 15
TEXT_SIZE128x128                     :: 16
MAX_TEXT_SIZE                        :: 16
CURRENT_BIT                          :: 0x00000001
POINT_BIT                            :: 0x00000002
LINE_BIT                             :: 0x00000004
POLYGON_BIT                          :: 0x00000008
POLYGON_STIPPLE_BIT                  :: 0x00000010
PIXEL_MODE_BIT                       :: 0x00000020
LIGHTING_BIT                         :: 0x00000040
FOG_BIT                              :: 0x00000080
DEPTH_BUFFER_BIT                     :: 0x00000100
ACCUM_BUFFER_BIT                     :: 0x00000200
STENCIL_BUFFER_BIT                   :: 0x00000400
VIEWPORT_BIT                         :: 0x00000800
TRANSFORM_BIT                        :: 0x00001000
ENABLE_BIT                           :: 0x00002000
COLOR_BUFFER_BIT                     :: 0x00004000
HINT_BIT                             :: 0x00008000
EVAL_BIT                             :: 0x00010000
LIST_BIT                             :: 0x00020000
TEXTURE_BIT                          :: 0x00040000
SCISSOR_BIT                          :: 0x00080000
ALL_ATTRIB_BITS                      :: 0x000fffff
