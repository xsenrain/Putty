@echo off
rem ============================================================
rem  PuTTY Windows build script (MSVC + Ninja)
rem  Verified working on: VS 18 Community (MSVC 14.51) + CMake 4.3
rem
rem  Usage:
rem    contrib\build-windows-msvc.bat [build_dir]
rem
rem  Why this script exists (see PITFALLS.md P-016..P-019):
rem    1. CMake's "Visual Studio 18 2026" generator cannot find cl.exe
rem       -> we use Ninja + the MSVC environment instead.
rem    2. vcvars64.bat locates the Windows SDK via reg.exe. When reg.exe
rem       is unavailable (restricted sandbox / security policy), rc.exe,
rem       mt.exe and kernel32.lib go missing from PATH/INCLUDE/LIB
rem       -> we add the SDK paths explicitly.
rem    3. CMAKE_RC_COMPILER must use forward slashes, otherwise CMake
rem       writes an invalid escape sequence into CMakeRCCompiler.cmake.
rem ============================================================
setlocal enabledelayedexpansion

set SRC=%~dp0..
set BLD=%~1
if "%BLD%"=="" set BLD=%SRC%\..\putty-build

rem ---- locate Visual Studio ----
if "%VS%"=="" (
  for /d %%d in ("C:\Program Files\Microsoft Visual Studio\*" ) do (
    for /d %%e in ("%%~d\*") do set VS=%%~e
  )
)
if not exist "%VS%\VC\Auxiliary\Build\vcvars64.bat" (
  echo [ERROR] Visual Studio with C++ tools not found.
  echo         Set the VS environment variable to your VS install root, e.g.
  echo         set VS=C:\Program Files\Microsoft Visual Studio\2022\Community
  exit /b 1
)
set CMAKE=%VS%\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe
set NINJA=%VS%\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe
if not exist "%CMAKE%" set CMAKE=cmake

rem ---- locate newest Windows 10/11 SDK ----
set KITS=C:\Program Files (x86)\Windows Kits\10
set SDKVER=
for /d %%v in ("%KITS%\bin\10.*") do set SDKVER=%%~nxv
if "%SDKVER%"=="" (
  echo [ERROR] Windows SDK not found under "%KITS%".
  exit /b 1
)
set SDKDIR=%KITS%\bin\%SDKVER%\x64
set SDKFWD=%KITS%\bin\%SDKVER%\x64
set SDKFWD=%SDKFWD:\=/%

echo [1/3] MSVC environment ^(VS: %VS%^)
call "%VS%\VC\Auxiliary\Build\vcvars64.bat"
if errorlevel 1 exit /b 1

set PATH=%SDKDIR%;%PATH%
set INCLUDE=%KITS%\Include\%SDKVER%\um;%KITS%\Include\%SDKVER%\ucrt;%KITS%\Include\%SDKVER%\shared;%INCLUDE%
set LIB=%KITS%\Lib\%SDKVER%\um\x64;%KITS%\Lib\%SDKVER%\ucrt\x64;%LIB%
echo       SDK: %SDKVER%

echo [2/3] configure ^(build dir: %BLD%^)
"%CMAKE%" -S "%SRC%" -B "%BLD%" -G Ninja -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_MAKE_PROGRAM="%NINJA%" ^
  -DCMAKE_RC_COMPILER="%SDKFWD%/rc.exe" -DCMAKE_MT="%SDKFWD%/mt.exe"
if errorlevel 1 exit /b 1

echo [3/3] build
rem -j 1: parallel ninja occasionally stalls on one cl.exe (see PITFALLS P-019)
"%CMAKE%" --build "%BLD%" -- -j 1
if errorlevel 1 exit /b 1

echo.
echo BUILD OK -^> %BLD%
echo   putty.exe  pscp.exe  psftp.exe  plink.exe  puttygen.exe  pageant.exe
exit /b 0
