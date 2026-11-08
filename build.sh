#!/usr/bin/env sh
# Build the TinyGL static library into lib/libtinygl.a.
# Usage: ./build.sh [openmp] [native] [debug]
# Set the CC environment variable to select the compiler (default: cc).
set -eu

openmp=0
native=0
debug=0
for arg in "$@"; do
	case "$arg" in
		openmp) openmp=1 ;;
		native) native=1 ;;
		debug) debug=1 ;;
		*) echo "build.sh: unknown option \"$arg\". Use openmp, native, or debug." >&2; exit 1 ;;
	esac
done

cc="${CC:-cc}"

if [ ! -f tinygl/src/api.c ]; then
	echo "build.sh: tinygl/src is empty. Run \"git submodule update --init\"." >&2
	exit 1
fi

cflags="-std=c99 -Wall -Wno-unused-function"
if [ "$debug" = 1 ]; then cflags="$cflags -O0 -g"; else cflags="$cflags -O3 -DNDEBUG"; fi
if [ "$native" = 1 ]; then cflags="$cflags -march=native"; fi
if [ "$openmp" = 1 ]; then cflags="$cflags -fopenmp"; fi

# Compile a copy of the source, so that zfeatures.h can replace the upstream file.
rm -rf build
mkdir -p build/tinygl build/obj lib
cp -r tinygl/src tinygl/include build/tinygl/
cp zfeatures.h build/tinygl/include/zfeatures.h

for f in build/tinygl/src/*.c; do
	name=$(basename "$f" .c)
	$cc $cflags -c "$f" -o "build/obj/$name.o"
done

rm -f lib/libtinygl.a
ar rcs lib/libtinygl.a build/obj/*.o

echo "Built lib/libtinygl.a"
