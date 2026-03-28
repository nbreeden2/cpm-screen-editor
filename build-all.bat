cls
@echo off
REM ---------------------------------------------------------------
REM BUILD-ALL.BAT - Build all 4 SEDIT variants
REM
REM   SEDIT.COM    - Mono  (no color, no highlighting)
REM   SEDIT-CL.COM - Color (color, no highlighting)
REM   SEDIT-A.COM  - ASM   (color, ASM highlighting)
REM   SEDIT-C.COM  - Color (color, C highlighting)
REM
REM Requires: cpmulator.exe, M80.COM, L80.COM, Python (CPMFMT.PY)
REM ---------------------------------------------------------------

echo === SEDIT Multi-Variant Build ===

REM --- Format and assemble all non-variant modules (once) ---
echo Formatting source files...
python CPMFMT.PY SEDIT.MAC SEBLOCK.MAC SEFILEIO.MAC
if errorlevel 1 goto fail
python CPMFMT.PY SEGAPBUF.MAC SEVIRTIO.MAC
if errorlevel 1 goto fail
python CPMFMT.PY SEHELP.MAC SEKEY.MAC SEKEYBND.MAC SEMENU.MAC
if errorlevel 1 goto fail
python CPMFMT.PY SESEARCH.MAC
if errorlevel 1 goto fail
python CPMFMT.PY COL80.MAC COL132.MAC CLS.MAC
if errorlevel 1 goto fail

echo Assembling shared modules...
for %%M in (SEDIT SEBLOCK SEFILEIO SEGAPBUF SEHELP SEKEY SEKEYBND SEMENU SESEARCH SEVIRTIO) do (
    cpmulator M80.COM =%%M
    if errorlevel 1 goto fail
)

echo Assembling standalone utilities...
for %%M in (GETWIDTH COL80 COL132 CLS) do (
    cpmulator M80.COM =%%M
    if errorlevel 1 goto fail
)

REM --- Build each variant ---

echo.
echo --- Variant 1/4: SEDIT.COM (mono, no highlight) ---
python SEBUILD.PY 0 0
if errorlevel 1 goto fail
python CPMFMT.PY SESCREEN.MAC SESYNTAX.MAC
if errorlevel 1 goto fail
cpmulator M80.COM =SESCREEN
if errorlevel 1 goto fail
cpmulator M80.COM =SESYNTAX
if errorlevel 1 goto fail
cpmulator L80.COM SEDIT,SESCREEN,SEKEY,SEGAPBUF,SEFILEIO,SEMENU,SESEARCH,SEBLOCK,SESYNTAX,SEKEYBND,SEVIRTIO,SEHELP,SEDIT/N/E
if errorlevel 1 goto fail
copy /y SEDIT.COM SEDIT-MONO.COM >nul
echo Built SEDIT.COM (mono)

echo.
echo --- Variant 2/4: SEDIT-CL.COM (color, no highlight) ---
python SEBUILD.PY 1 0
if errorlevel 1 goto fail
python CPMFMT.PY SESCREEN.MAC SESYNTAX.MAC
if errorlevel 1 goto fail
cpmulator M80.COM =SESCREEN
if errorlevel 1 goto fail
cpmulator M80.COM =SESYNTAX
if errorlevel 1 goto fail
cpmulator L80.COM SEDIT,SESCREEN,SEKEY,SEGAPBUF,SEFILEIO,SEMENU,SESEARCH,SEBLOCK,SESYNTAX,SEKEYBND,SEVIRTIO,SEHELP,SEDIT/N/E
if errorlevel 1 goto fail
copy /y SEDIT.COM SEDIT-CL.COM >nul
echo Built SEDIT-CL.COM (color)

echo.
echo --- Variant 3/4: SEDIT-A.COM (color + ASM highlight) ---
python SEBUILD.PY 1 1
if errorlevel 1 goto fail
python CPMFMT.PY SESCREEN.MAC SESYNTAX.MAC
if errorlevel 1 goto fail
cpmulator M80.COM =SESCREEN
if errorlevel 1 goto fail
cpmulator M80.COM =SESYNTAX
if errorlevel 1 goto fail
cpmulator L80.COM SEDIT,SESCREEN,SEKEY,SEGAPBUF,SEFILEIO,SEMENU,SESEARCH,SEBLOCK,SESYNTAX,SEKEYBND,SEVIRTIO,SEHELP,SEDIT/N/E
if errorlevel 1 goto fail
copy /y SEDIT.COM SEDIT-A.COM >nul
echo Built SEDIT-A.COM (ASM highlight)

echo.
echo --- Variant 4/4: SEDIT-C.COM (color + C highlight) ---
python SEBUILD.PY 1 2
if errorlevel 1 goto fail
python CPMFMT.PY SESCREEN.MAC SESYNTAX.MAC
if errorlevel 1 goto fail
cpmulator M80.COM =SESCREEN
if errorlevel 1 goto fail
cpmulator M80.COM =SESYNTAX
if errorlevel 1 goto fail
cpmulator L80.COM SEDIT,SESCREEN,SEKEY,SEGAPBUF,SEFILEIO,SEMENU,SESEARCH,SEBLOCK,SESYNTAX,SEKEYBND,SEVIRTIO,SEHELP,SEDIT/N/E
if errorlevel 1 goto fail
copy /y SEDIT.COM SEDIT-C.COM >nul
echo Built SEDIT-C.COM (C highlight)

REM --- Restore source to default (mono) ---
python SEBUILD.PY 0 0
python CPMFMT.PY SESCREEN.MAC SESYNTAX.MAC

REM --- Link standalone utilities ---
echo.
echo Linking standalone utilities...
cpmulator L80.COM GETWIDTH,GETWIDTH/n/e
if errorlevel 1 goto fail
cpmulator L80.COM COL80,COL80/n/e
if errorlevel 1 goto fail
cpmulator L80.COM COL132,COL132/n/e
if errorlevel 1 goto fail
cpmulator L80.COM CLS,CLS/n/e
if errorlevel 1 goto fail

REM --- Clean up ---
del *.REL 2>nul

REM --- Rename mono back to SEDIT.COM ---
copy /y SEDIT-MONO.COM SEDIT.COM >nul
del SEDIT-MONO.COM 2>nul

REM --- Copy resulting files to a disk image folder
REM --- These are specific to my build environment
goto ignore
copy sedit*.com D:\SDH\DISKS\hd-sedit.unpacked\0
copy *.mac      D:\SDH\DISKS\hd-sedit.unpacked\0
copy cls.com    D:\SDH\DISKS\hd-sedit.unpacked\0
copy col80.com  D:\SDH\DISKS\hd-sedit.unpacked\0
copy col132.com D:\SDH\DISKS\hd-sedit.unpacked\0
copy *.doc      D:\SDH\DISKS\hd-sedit.unpacked\0
copy *.sub      D:\SDH\DISKS\hd-sedit.unpacked\0
pushd D:\SDH\DISKS\
if exist hd-sedit.hdd del hd-sedit.hdd
python ..\pack.py hd-sedit.hdd
popd
:ignore

echo.
echo === All variants built ===
echo   SEDIT.COM    - Mono  (no color, no highlighting)
echo   SEDIT-CL.COM - Color (color, no highlighting)
echo   SEDIT-A.COM  - ASM   (color + ASM highlighting)
echo   SEDIT-C.COM  - Color (color + C highlighting)
goto end

:fail
echo === BUILD FAILED ===
exit /b 1

:end
