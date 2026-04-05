cls
@echo off
REM ----------------------------------------------------------------
REM BUILD-ALL.BAT - Build all 4 SEDIT variants
REM
REM   SEDIT.COM    - Mono  (no color, no highlighting)
REM   SEDIT-CL.COM - Color (color, no highlighting)
REM   SEDIT-A.COM  - ASM   (color, ASM highlighting)
REM   SEDIT-C.COM  - Color (color, C highlighting)
REM   SEADM31.COM  - Mono  (no color, specific to the ADM-31)
REM   SEC3102.COM  - Mono  (no color, soecific to the Cromemco 3102)
REM
REM Requires: cpmulator.exe, M80.COM, L80.COM, Python (CPMFMT.PY)
REM ----------------------------------------------------------------

echo === SEDIT Multi-Variant Build ===

echo First cleanup
if exist SE*.COM del SE*.COM 2>nul
if exist *.REL   del *.REL   2>nul

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
python CPMFMT.PY COL80.MAC COL132.MAC CLS.MAC MEMTEST.MAC COLORS.MAC
if errorlevel 1 goto fail
REM Specific to the ADM 31 terminal
python CPMFMT.PY SEADM31 SEADM31K
if errorlevel 1 goto fail
REM Specific to the Cromemco 3102 terminal
python CPMFMT.PY SEC3102.MAC SEC3102K.MAC
if errorlevel 1 goto fail


echo Assembling shared modules...
for %%M in (SEDIT SEBLOCK SEFILEIO SEGAPBUF SEHELP SEKEY SEKEYBND SEMENU SESEARCH SEVIRTIO) do (
    cpmulator M80.COM =%%M
    if errorlevel 1 goto fail
)

echo Assembling standalone utilities...
for %%M in (GETWIDTH MEMTEST KEYCODE COL80 COL132 CLS COLORS) do (
    cpmulator M80.COM =%%M
    if errorlevel 1 goto fail
)

REM --- Build each variant ---
echo --- WordStar/VT100 Variants ---
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
echo --- End of WordStar/VT100 variants ---

REM --- Restore source to default (mono) ---
python SEBUILD.PY 0 0
python CPMFMT.PY SESCREEN.MAC SESYNTAX.MAC

echo --- Build ADM-31 Editor ---
cpmulator M80.COM =SESCREEN
if errorlevel 1 goto fail
cpmulator M80.COM =SESYNTAX
if errorlevel 1 goto fail
cpmulator M80.COM =SEADM31
if errorlevel 1 goto fail
cpmulator M80.COM =SEADM31K
if errorlevel 1 goto fail
cpmulator L80.COM SEDIT,SEADM31,SEADM31K,SEGAPBUF,SEFILEIO,SEMENU,SESEARCH,SEBLOCK,SESYNTAX,SEKEYBND,SEVIRTIO,SEHELP,SEADM31/N/E
echo Built SEADM31.COM
echo --- End of ADM-31 Editor ---

echo --- Build SEC3102 Editor ---
cpmulator M80.COM =SESCREEN
if errorlevel 1 goto fail
cpmulator M80.COM =SESYNTAX
if errorlevel 1 goto fail
cpmulator M80.COM =SEC3102
if errorlevel 1 goto fail
cpmulator M80.COM =SEC3102K
if errorlevel 1 goto fail
cpmulator L80.COM SEDIT,SEC3102,SEC3102K,SEGAPBUF,SEFILEIO,SEMENU,SESEARCH,SEBLOCK,SESYNTAX,SEKEYBND,SEVIRTIO,SEHELP,SEC3102/N/E
echo Built SEC3102.COM
echo --- End of Cromemco 3102 Editor ---

REM --- Link standalone utilities ---
echo.
echo Linking standalone utilities...
cpmulator L80.COM GETWIDTH,GETWIDTH/n/e
if errorlevel 1 goto fail
cpmulator L80.COM KEYCODE,KEYCODE/n/e
if errorlevel 1 goto fail
cpmulator L80.COM MEMTEST,MEMTEST/n/e
if errorlevel 1 goto fail
cpmulator L80.COM COL80,COL80/n/e
if errorlevel 1 goto fail
cpmulator L80.COM COL132,COL132/n/e
if errorlevel 1 goto fail
cpmulator L80.COM CLS,CLS/n/e
if errorlevel 1 goto fail
cpmulator L80.COM COLORS,COLORS/n/e
if errorlevel 1 goto fail

REM --- Clean up ---
REM del *.REL 2>nul

REM --- Rename mono back to SEDIT.COM ---
copy /y SEDIT-MONO.COM SEDIT.COM >nul
del SEDIT-MONO.COM 2>nul

echo.
echo === All variants built ===
echo   SEDIT.COM    - Mono  (WordStar/VT100, no color, no highlighting)
echo   SEDIT-CL.COM - Color (WordStar/VT100, color   , no highlighting)
echo   SEDIT-A.COM  - ASM   (WordStar/VT100, color + ASM highlighting)
echo   SEDIT-C.COM  - Color (WordStar/VT100, color + C highlighting)
echo   SEADM31.COM  - Mono  (ADM-31        , no color, no highlighting)
echo   SEC3102.COM  - Mono  (Cromemco 3102  ,no color, no highlighting)
goto end

:fail
echo === BUILD FAILED ===
exit /b 1

:end
