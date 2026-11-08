@echo off
rem Build the TinyGL static library into lib\tinygl.lib.
rem Usage: build.bat [openmp] [native] [debug]
rem Set the CC environment variable to select the compiler (default: clang).
setlocal enabledelayedexpansion

set OPENMP=0
set NATIVE=0
set DEBUG=0

:args
if "%~1"=="" goto args_done
if /i "%~1"=="openmp" (set OPENMP=1& shift & goto args)
if /i "%~1"=="native" (set NATIVE=1& shift & goto args)
if /i "%~1"=="debug" (set DEBUG=1& shift & goto args)
echo build.bat: unknown option "%~1". Use openmp, native, or debug. 1>&2
exit /b 1
:args_done

if not defined CC set CC=clang

if not exist tinygl\src\api.c (
	echo build.bat: tinygl\src is empty. Run "git submodule update --init". 1>&2
	exit /b 1
)

set CFLAGS=-std=c99 -Wall -Wno-unused-function -D_CRT_SECURE_NO_WARNINGS
if %DEBUG%==1 (set CFLAGS=!CFLAGS! -O0 -g) else (set CFLAGS=!CFLAGS! -O3 -DNDEBUG)
if %NATIVE%==1 set CFLAGS=!CFLAGS! -march=native
if %OPENMP%==1 set CFLAGS=!CFLAGS! -fopenmp

rem Compile a copy of the source, so that zfeatures.h can replace the upstream file.
if exist build rmdir /s /q build
xcopy /e /i /q /y tinygl\src build\tinygl\src >nul || exit /b 1
xcopy /e /i /q /y tinygl\include build\tinygl\include >nul || exit /b 1
copy /y zfeatures.h build\tinygl\include\zfeatures.h >nul || exit /b 1
mkdir build\obj

for %%f in (build\tinygl\src\*.c) do (
	%CC% %CFLAGS% -c %%f -o build\obj\%%~nf.obj || exit /b 1
)

if not exist lib mkdir lib
if exist lib\tinygl.lib del lib\tinygl.lib
llvm-lib /nologo /out:lib\tinygl.lib build\obj\*.obj || exit /b 1

if %OPENMP%==1 (
	for /f "delims=" %%i in ('where clang') do set LLVM_BIN=%%~dpi
	copy /y "!LLVM_BIN!..\lib\libomp.lib" lib\libomp.lib >nul || exit /b 1
)

echo Built lib\tinygl.lib
