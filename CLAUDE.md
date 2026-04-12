# SEDIT - CP/M 2.2 Screen Editor

## Project Rules

- **Intel 8080 assembly ONLY** — no Z80 instructions (no EX, DJNZ, JR, IX/IY, etc.)
- Assembler: **M80** (Microsoft Macro-80). Linker: **L80**.
- After every .MAC file edit, run: `python CPMFMT.PY <file>`
- CPMFMT.PY normalizes CR+LF, appends Ctrl-Z EOF (.MAC only, not .INC).
- SEDIT.INC is included via M80 `INCLUDE` directive (no Ctrl-Z in .INC files so M80 returns to parent).
- BDOS calls clobber ALL registers. Any value needed across CALL must be saved to memory or stack.
- When fixing off-by-one or boundary bugs, trace exact values at edges (0, 1, max-1, max) before writing the fix.
- Version shown via ESC menu -> "8. About". Update in SEMENU.MAC.
- Version also in: SEHELP.MAC (help header), SESCREEN.MAC/SEADM31.MAC/SEC3102.MAC (separator), SEDIT.md, README.md.

## Build

```
python CPMFMT.PY                    # preprocess all .MAC
M80 =<module>                       # assemble (one per .MAC)
L80 SEDIT,SESCREEN,SEKEY,SEGAPBUF,SEFILEIO,SEMENU,SESEARCH,SEBLOCK,SESYNTAX,SEKEYBND,SEVIRTIO,SEHELP,SEDIT/N/E
```

## Screen Layout (VT100/ANSI, 80/132 x 24-30+)

Terminal size auto-detected at startup via VT100 DSR. Column mode (80/132) and row count are dynamic. Runtime variables REROWS, RSEPR, RSTAT replace compile-time EDITROW, SEPRROW, STATROW.

```
Row  1: INFOBAR  — filename, line count, row, col, ins/ovr mode
Row  2: RULRDRAW — tab ruler (`:` every 4 cols), dim attribute
Row  3..N-2: EDIT AREA — REROWS lines (default 20, up to 26+)
         Cols 1-4: line number gutter (LNUMWID=4)
         Cols 5-78: text area (TXTCOLS=74, TXTFCOL=5)
Row N-1: SEPRDRAW — separator line (`=` chars), RSEPR
Row  N: STATROW  — status messages / prompts, RSTAT
```

## Selective Redraw System (SEDIT.MAC main loop)

| DIRTY | DRTLINE | Action                                          |
|-------|---------|-------------------------------------------------|
| 1     | *       | SCRDRAW (full 20 lines + ruler + separator + status clear) |
| 0     | 1       | SCREDCL (current line only)                     |
| 0     | 0       | No content redraw (cursor-only move)            |

INFOBAR and CURPOS always run at MLDONE regardless of flags.

## Module Map (12 linked modules + 2 standalone)

| File | Purpose | Key Exports |
|------|---------|-------------|
| SEDIT.MAC | Entry point, main loop, action dispatch | INSMODE, DIRTY, CURBDP, TPATOP, DOEXIT |
| SESCREEN.MAC | Terminal I/O, screen rendering | SCRINIT, SCRDRAW, SCREDCL, SCREDLN, INFOBAR, CURPOS, STATMSG, STATCLR, OUTSTR, OUTCHAR, CURGOTO |
| SEKEY.MAC | Key input, VT100 ESC decode | GETKEY, KBDTBL |
| SEGAPBUF.MAC | Gap buffer text engine | GBINIT, GBINSRT, GBDLFT, GBDELRT, GBMV*, GBPG*, GBDLLN, GBWRD*, GBGETLN, GBCNTLN, GBFNDCS, GBRDLNO, GBTMP |
| SEFILEIO.MAC | File load/save (FCB, BDOS) | FIOPEN, FISAVE, FIPROMPT, FISAVFN, FISMOD |
| SEMENU.MAC | ESC menu overlay | MNUSHOW |
| SESEARCH.MAC | Find / replace | SRFNDNX, SRREPL |
| SEBLOCK.MAC | Block mark, copy, delete, paste | BLMARK, BLCOPY, BLDEL, BLPASTE |
| SESYNTAX.MAC | ASM + C syntax highlighting, rainbow braces | SYNINIT, SYNLINE, SNTBL, SNCNT, SNCMST, BRDEPTH |
| SEKEYBND.MAC | Key binding init from SEDIT.KEY | KBINIT |
| SEVIRTIO.MAC | Virtual buffer I/O for large files | VIMODE, VISAVALL, VIGOTO, VAFLN, VAFCB, VAFEX, VIOVFL |
| SEHELP.MAC | Help screen overlay, BMDATEND | HLPSHOW |
| KEYCODE.MAC | Standalone key diagnostic (not linked) | — |
| GETSIZE.MAC | Standalone terminal size detection (not linked) | — |

## Gap Buffer Architecture (SEGAPBUF.MAC)

```
Memory:  [pre-gap text R1][---GAP---][post-gap text R2]
         base             GAPBG      GAPEN              base+BSIZE
```

- **R1** = base .. base+GAPBG-1 (text before cursor)
- **R2** = base+GAPEN .. base+BSIZE-1 (text after cursor)
- Cursor is always at the gap. Insert = write at GAPBG, advance GAPBG. Delete = adjust gap boundaries.
- Line delimiter: LF (0x0A). Files stored as CR+LF on disk, CR+LF in buffer.

## Buffer Descriptor (BD_SIZE = 34 bytes, via CURBDP)

| Offset | Size | Field | Description |
|--------|------|-------|-------------|
| 0 | 2 | BD_BSTAR | Buffer base address |
| 2 | 2 | BD_BSIZE | Capacity in bytes |
| 4 | 2 | BD_GAPBG | Gap start offset |
| 6 | 2 | BD_GAPEN | Gap end offset |
| 8 | 2 | BD_TXEND | Logical text length |
| 10 | 2 | BD_TOPLN | Top visible line number |
| 12 | 1 | BD_CSROW | Cursor screen row (0-based) |
| 13 | 1 | BD_CSCOL | Cursor text column (0-based) |
| 14 | 2 | BD_CSOFF | Cursor byte offset |
| 16 | 2 | BD_MRKBG | Block mark start (FFFF=unset) |
| 18 | 2 | BD_MRKEN | Block mark end (FFFF=unset) |
| 20 | 1 | BD_MODIF | Modified flag |
| 21 | 1 | BD_SYNMD | Syntax mode (0=none, 1=asm, 2=C) |
| 22 | 12 | BD_FNAME | Drive + filename + ext |

## Key Action Dispatch (SEDIT.MAC)

Main loop calls GETKEY -> B=type, C=value. If B=KT_ACT, jumps via ACTTBL[C*2].
Action codes 1-31 (ACT_CURUP..ACT_MENU) map to DO_* handlers.

## Key Constants (SEDIT.INC)

- EDITROW=20, EDITFR=3, SCRROWS=24, SCRCOLS=80
- TXTCOLS=74, TXTFCOL=5, LNUMWID=4, TABWID=4
- INFOROW=1, RULRROW=2, SEPRROW=23, STATROW=24
- MAXBUFS=2, CLIPMAX=2048, SRCHMAX=64, RECSIZ=128

## Common Patterns

**Read buffer descriptor field:**
```asm
LHLD    CURBDP
MVI     A,BD_<field>
ADD     L
MOV     L,A
MVI     A,0
ADC     H
MOV     H,A         ; HL -> field
MOV     E,M         ; read low byte (or byte field)
INX     H
MOV     D,M         ; read high byte (word field)
```

**Set dirty flags:**
```asm
MVI     A,1
STA     DIRTY       ; full redraw
; or
STA     DRTLINE     ; current line only
```
