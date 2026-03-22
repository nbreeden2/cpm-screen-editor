# SEDIT — Screen Editor for CP/M 2.2

**Platform:** CP/M 2.2, Intel 8080
**Assembler:** Microsoft M80 / L80
**Terminal:** VT100 / ANSI
**Editing Model:** Full-screen, ESC-menu driven, WordStar-compatible control keys
**Version:** 1.06

---

## 1. Overview

SEDIT is a full-screen plain-text editor for CP/M 2.2 written in Intel 8080 assembly language, assembled with M80 and linked with L80. It targets VT100/ANSI terminals. Navigation and editing use WordStar-style Ctrl-key bindings as the default set; bindings are user-configurable via an external key binding file (`SEDIT.KEY`). Pressing ESC opens an interactive menu for file, navigation, and block operations.

### 1.1 Goals

- Fast, responsive screen editing on a 2 MHz 8080 system
- Single edit buffer with full TPA utilization
- ESC-driven command menu with keyboard navigation
- Find text search
- Block mark, copy, paste, and delete
- Optional syntax highlighting for assembly language (`.MAC`, `.ASM`, `.INC`) files (compile-time option)
- User-configurable key bindings loaded from `SEDIT.KEY` on startup
- Horizontal scrolling for lines wider than the visible text area
- Clean return to CP/M on exit; no file corruption on abort

### 1.2 Non-Goals

- Files larger than available TPA RAM
- Mouse support
- Undo history
- Binary file editing
- Subdirectory file paths (CP/M 2.2 is flat)

---

## 2. Screen Layout

80 columns x 24 rows, VT100 terminal. The screen is divided into five fixed zones.

```
Row  1  +-- Info bar ----------------------------------------------------------------+
Row  2  |  Tab stop ruler                                                             |
Row  3  |  +== edit area top ======================================================+  |
  ...   |  ||  text lines (rows 3-22)                                              ||  |
Row 22  |  +== edit area bottom ===================================================+  |
Row 23  |  ==========================================================================  |
Row 24  +-- Status / operation bar --------------------------------------------------+
```

### 2.1 Row 1 — Info Bar

Displays file metadata for the active buffer.

```
A:MAIN    .MAC  Lines:1024  Row: 142  Col:  35  [INS]  [MOD]
```

| Field | Description |
|-------|-------------|
| Drive + filename | `A:MAIN    .MAC` — CP/M drive letter and 8.3 filename (magenta if COLOR enabled) |
| `Lines:nnnn` | Total number of lines in the file (blue if COLOR enabled) |
| `Row:nnnn` | Current cursor line, 1-based (blue) |
| `Col:nnnn` | Current cursor column within the text, 1-based (blue) |
| `[INS]` / `[OVR]` | Insert mode (green) or Overwrite mode (red) |
| `[MOD]` | Shown only when the buffer has unsaved changes |

All numeric fields are 4-digit, right-justified with leading spaces (max 9999). If no file is loaded, the filename area shows `[No Name]`. Drive byte 0 (default) queries the current disk via BDOS.

### 2.2 Row 2 — Tab Stop Ruler

A ruler showing tab stop positions within the text area (rendered dim if COLOR enabled).

```
     :    :    :    :    :    :    :    :    :    :    :    :    :    :    :
```

- Each `:` marks a tab stop (every 4 columns, TABWID=4)
- Ruler starts at column TXTFCOL (6), aligned with the text area

### 2.3 Rows 3-22 — Edit Area (20 lines)

Each row shows one line of text in the following fixed format:

```
COL:  1  2  3  4  5  6 ---------------------------------------------------- 80
      |  |  |  |  |  |
      +--line no--+ sp +------------- up to 73 characters of text -----------+
```

| Columns | Content |
|---------|---------|
| 1-4 | Line number, right-justified, space-padded (4-digit field) |
| 5 | Single space separator |
| 6-80 | Text content — up to 73 visible characters per line (TXTCOLS=73) |

#### 2.3.1 Line Number Display

- Line numbers are right-justified in a 4-character field (columns 1-4)
- Lines 1-9999 display as `   1`, `  42`, `9999`
- The current cursor line's number is displayed in **bold** (SGR 1)
- Lines within a marked block have their line numbers displayed in **reverse video** (SGR 7)
- Line number gutter is green if COLOR is enabled

#### 2.3.2 Line Width and Horizontal Scrolling

- Maximum stored line width: **255 characters** (MAXCOLS=255, excluding line terminator)
- Visible text area: **73 columns** (TXTCOLS=73, terminal columns 6-78)
- Lines longer than the visible area are handled by horizontal scrolling (HSCROL variable)
- Horizontal scroll auto-adjusts as the cursor moves beyond the visible range
- On disk, each line is stored as characters followed by `0DH 0AH` (CR/LF)

#### 2.3.3 Tab Character Display

- Tab characters (`09H`) in the buffer are expanded to spaces at the next tab stop (TABWID=4)
- Tab expansion is display-only; the stored byte is a literal `09H`

### 2.4 Row 23 — Separator Line

A full 80-character line of `=` characters (drawn dim if COLOR enabled).

### 2.5 Row 24 — Status / Operation Bar

Used for two purposes:

1. **Status messages** — transient informational text:
   ```
   Saving file...        File saved.        Not found.        Buffer full.
   ```

2. **Input prompts** — when a menu operation requires text input:
   ```
   Find text: _
   Open file: _
   Save as: _
   Go to line: _
   ```

---

## 3. ESC Menu System

Pressing `ESC` at any time opens the command menu. The menu overlays the edit area with a bordered panel; the edit area is restored when the menu is dismissed.

### 3.1 Menu Panel Layout

```
         +==========================+
         |       SEDIT  MENU        |
         +==========================+
         |  1. Open File            |
         |  2. Save File            |
         |  3. Save As...           |
         |  4. Find text...         |
         |  5. Go To Line...        |
         |  6. Help                 |
         |  7. About                |
         |  8. Quit / Exit          |
         +==========================+
```

Menu geometry: top-left at row 6/col 28, bottom-right at row 17/col 54.

### 3.2 Menu Navigation

| Key | Action |
|-----|--------|
| Up / Down arrow, `^E` / `^X`, `K` / `J` | Move highlight |
| Enter or digit `1`-`8` | Execute item |
| Shortcut letter (O/S/A/F/G/H/B/X/Q) | Execute item directly |
| ESC | Cancel menu, return to editing |

### 3.3 Menu Item Details

#### 1. Open File (O)
- Prompt on row 24: `Open file: _`
- User types drive + filename (8.3 format)
- File is loaded into the buffer; if file does not exist, opens an empty buffer with the given name
- Status: `New file` if file not found

#### 2. Save File (S)
- Save active buffer to its filename
- Creates a `.BAK` backup of the previous version before saving
- Uses BDOS F_DELETE + F_MAKE + sequential F_WRITE
- Status: `Saving file...` then `File saved.`
- If filename is `[No Name]`, prompts for a filename first (Save As behavior)

#### 3. Save As (A)
- Prompt: `Save as: _`
- User enters a new filename; saves buffer under the new name
- Updates the buffer's filename after save

#### 4. Find Text (F)
- Prompt: `Find text: _`
- User enters search string (max 64 characters); Enter to search
- Search begins from cursor position, wraps to top of file if not found before EOF
- Cursor placed at match start if found
- Status: `Found at line n` or `Not found`

#### 5. Go To Line (G)
- Prompt: `Go to line: _`
- User enters a decimal line number; cursor moves to that line
- Uses GBGOTOL for fast bulk cursor movement

#### 6. Help (H)
- Displays a full-screen key reference overlay (see section 4)
- Press any key to return to editing

#### 7. About (B)
- Displays `SEDIT v1.06 CP/M Screen Editor` on the status bar
- Press any key to dismiss

#### 8. Quit / Exit (X/Q)
- If buffer is modified, prompts to save
- Clears screen and warm boots via `JMP 0000H`

---

## 4. Key Bindings

These bindings are active with the default configuration. ESC always opens the menu and is not rebindable.

### 4.1 Cursor Movement

| Key | Action |
|-----|--------|
| `^E` / Up arrow | Cursor up |
| `^X` / Down arrow | Cursor down |
| `^S` / Left arrow | Cursor left |
| `^D` / Right arrow | Cursor right |
| `^A` | Previous word |
| `^F` | Next word |
| `^R` / PgUp | Page up |
| `^C` / PgDn | Page down |
| `^W` | Scroll screen up one line |
| `^Z` | Scroll screen down one line |
| `^QS` / Home | Jump to start of line |
| `^QD` / End | Jump to end of line |
| `^QR` | Jump to top of file |
| `^QC` | Jump to end of file |

### 4.2 Editing

| Key | Action |
|-----|--------|
| Printable character | Insert (Insert mode) or Overwrite |
| `^H` / Backspace | Delete character left |
| `^G` / Delete | Delete character at cursor |
| `^Y` | Delete current line |
| `^I` / Tab | Insert tab |
| `^M` / Enter | Insert newline (CR+LF) |
| `^V` / Insert | Toggle Insert / Overwrite mode |

### 4.3 Block Operations

| Key | Action |
|-----|--------|
| `^KB` / F3 | Toggle block mark (start -> end -> clear) |
| `^KC` | Copy marked block to clipboard |
| `^O` | Copy marked block (alternate) |
| `^KD` | Delete marked block |
| `^KP` | Paste clipboard at cursor |

### 4.4 File and Search

| Key | Action |
|-----|--------|
| `^KS` / F2 | Save file |
| `^KX` | Exit (with save prompt) |
| `^KQ` | Quit (with save prompt) |
| `^QF` | Find text (prompt for search string) |
| `^L` / F1 | Find next occurrence |
| ESC / F4 | Open menu |

### 4.5 Function Keys

| Key | Action |
|-----|--------|
| F1 | Find next |
| F2 | Save file |
| F3 | Block mark |
| F4 | Open menu |

### 4.6 VT100/VT220 Escape Sequences

The key decoder handles both ANSI (CSI) and application (SS3) cursor key modes:

| Sequence | Action |
|----------|--------|
| `ESC [ A` / `ESC O A` | Cursor up |
| `ESC [ B` / `ESC O B` | Cursor down |
| `ESC [ C` / `ESC O C` | Cursor right |
| `ESC [ D` / `ESC O D` | Cursor left |
| `ESC [ H` / `ESC [ 1 ~` | Home (line start) |
| `ESC [ F` / `ESC [ 4 ~` | End (line end) |
| `ESC [ 2 ~` | Insert (toggle mode) |
| `ESC [ 3 ~` | Delete right |
| `ESC [ 5 ~` | Page up |
| `ESC [ 6 ~` | Page down |

ESC disambiguation: polls console status ~500 times (~1 ms at 2 MHz) before deciding a standalone ESC is a menu request.

---

## 5. Key Binding File (`SEDIT.KEY`)

SEDIT loads `SEDIT.KEY` from the current drive at startup. If the file is not present, the compiled-in default bindings (section 4) are used.

### 5.1 Format

Plain text, one binding per line. Lines beginning with `;` are comments. Blank lines are ignored.

```
; SEDIT.KEY - Custom key bindings
; Format: TYPE  PARAM  ACTION

; Control key bindings (0-31)
CTRL  5   CURUP       ; ^E = cursor up
CTRL  24  CURDN       ; ^X = cursor down
CTRL  19  CURLT       ; ^S = cursor left
CTRL  4   CURRT       ; ^D = cursor right
```

### 5.2 Binding Types

| Keyword | Format | Description |
|---------|--------|-------------|
| `CTRL` | `CTRL <n> <action>` | Bind Ctrl key (0-31) to action |
| `CSI` | `CSI <byte> <param> <action>` | Bind CSI escape sequence |
| `SS3` | `SS3 <byte> <action>` | Bind SS3 escape sequence |
| `CTK` | `CTK <char> <action>` | Bind Ctrl-K prefix sequence |
| `CTQ` | `CTQ <char> <action>` | Bind Ctrl-Q prefix sequence |

### 5.3 Action Names

Action names are case-insensitive. Supported names:

| Action | Description |
|--------|-------------|
| `CURUP` | Cursor up |
| `CURDN` | Cursor down |
| `CURLT` | Cursor left |
| `CURRT` | Cursor right |
| `WRDPV` | Previous word |
| `WRDNX` | Next word |
| `PGUP` | Page up |
| `PGDN` | Page down |
| `SCRUP` | Scroll screen up |
| `SCRDN` | Scroll screen down |
| `LINST` | Line start |
| `LINEN` | Line end |
| `FTOP` | File top |
| `FEND` | File end |
| `DELLF` | Delete left (backspace) |
| `DELRT` | Delete right |
| `DELWD` | Delete word right |
| `DELLN` | Delete line |
| `INSTB` | Insert tab |
| `INSNL` | Insert newline |
| `TOGIN` | Toggle insert/overwrite |
| `LITNX` | Literal next character |
| `FNDNX` | Find next |
| `FSAVE` | Save file |
| `FOPEN` | Open file |
| `FEXIT` | Exit editor |
| `BLKMK` | Block mark |
| `BLKCP` | Block copy |
| `BLKDL` | Block delete |
| `BLKPS` | Block paste |
| `MENU` | Open ESC menu |

---

## 6. Gap Buffer Architecture

The edit buffer uses a **gap buffer**: a flat RAM array with a movable hole at the cursor position.

```
Memory:  [pre-gap text R1][---GAP---][post-gap text R2]
         base             GAPBG      GAPEN              base+BSIZE
```

- **R1** = base .. base+GAPBG-1 (text before cursor)
- **R2** = base+GAPEN .. base+BSIZE-1 (text after cursor)
- Cursor is always at the gap. Insert = write at GAPBG, advance GAPBG.
- Line delimiter: CR+LF (`0DH 0AH`) stored in the buffer. Newline insert writes CR then LF. Backspace over LF auto-absorbs the preceding CR.

### 6.1 Buffer Descriptor (34 bytes)

```
Offset  Size  Field       Description
------  ----  ----------  ---------------------------------------------------
  0      2    BD_BSTAR    Buffer base address in RAM
  2      2    BD_BSIZE    Total buffer capacity in bytes
  4      2    BD_GAPBG    Offset: start of gap (first unused byte)
  6      2    BD_GAPEN    Offset: end of gap (first text byte after gap)
  8      2    BD_TXEND    Logical text length (total chars in buffer)
 10      2    BD_TOPLN    Line number at top of visible screen (0-based)
 12      1    BD_CSROW    Cursor row on screen (0-based, 0-19)
 13      1    BD_CSCOL    Cursor column within text (0-based)
 14      2    BD_CSOFF    Cursor byte offset in logical text
 16      2    BD_MRKBG    Block mark start offset (FFFFH = no mark)
 18      2    BD_MRKEN    Block mark end offset (FFFFH = no mark)
 20      1    BD_MODIF    Non-zero if buffer has unsaved changes
 21      1    BD_SYNMD    Syntax mode: 0=plain, 1=ASM
 22     12    BD_FNAME    Drive (1) + name (8) + ext (3)
```

BD_FNAME layout: byte 0 = drive (0=default, 1=A, 2=B, etc.), bytes 1-8 = filename (space-padded), bytes 9-11 = extension (space-padded).

### 6.2 Core Gap Buffer Operations

| Function | Description |
|----------|-------------|
| GBINIT | Initialize empty buffer with base address and size |
| GBINSRT | Insert character at cursor; auto-increments line count on LF |
| GBDLFT | Delete character left (backspace); auto-absorbs preceding CR when deleting LF |
| GBDELRT | Delete character right |
| GBMVUP/DN/LT/RT | Move cursor one line/character |
| GBMLNS/GBMLNE | Move cursor to line start/end |
| GBMVTOP/GBMVEND | Move cursor to file top/end |
| GBPGUP/GBPGDN | Page up/down (EDITROW lines) |
| GBDLLN | Delete entire current line |
| GBWRDPV/GBWRDNX | Move to previous/next word boundary |
| GBCURLN | Get current line text (O(line_length), scans backward from gap) |
| GBGETLN | Get line N text (O(line_number), scans from offset 0) |
| GBCNTLN | Count total lines in buffer (cached) |
| GBGOTOL | Go to line N (fast bulk move: moves to top, then forward-scans for N LFs) |
| GBRDLNO | Read line at a given logical offset |
| GBLOGRD | Read logical byte at offset HL (handles gap transparently) |
| GBFNDCS | Find TOPLN offset via backward scan from cursor |

---

## 7. Memory Map

Single-buffer configuration. All available TPA is used for the edit buffer.

```
FFFF +-------------------------------------------+
     |  CP/M (BIOS + BDOS + CCP)                 |  ~8 KB
     +-------------------------------------------+  TPATOP (from 0006H)
     |                                           |
     |  Gap buffer (single edit buffer)           |  All remaining TPA
     |                                           |
     +-------------------------------------------+  BMDATEND
     |  SEDIT code (CSEG) + data (DSEG)          |  ~16 KB
0100 +-------------------------------------------+
```

- BMDATEND is defined at the end of SEHELP.MAC's CSEG (the last linked module)
- Buffer base = BMDATEND, buffer size = TPATOP - BMDATEND
- Minimum required TPA: 9 KB (MINMEM = 9*1024); refuses to run if less
- Typical usable buffer: ~30-38 KB on a 64K system

---

## 8. Assembly-Time Options

Two compile-time options control feature inclusion:

| Option | Values | Effect |
|--------|--------|--------|
| `COLOR` | 0 or 1 | Color SGR strings for info bar, gutter, ruler, separator |
| `SYNHI` | 0 or 1 | Syntax highlighting for ASM files (tokenizer + SGR rendering) |

These are defined as EQU constants in the inlined SEDIT.INC within SESCREEN.MAC and SESYNTAX.MAC. Code is conditionally assembled with `IF COLOR`, `IF SYNHI`, and `IF COLOR+SYNHI` guards.

When SYNHI=1, the following ASM token classes are highlighted:

| Token Type | SGR | Color/Style |
|------------|-----|-------------|
| Label (col 1 identifier) | bold | Bold white |
| Opcode / mnemonic | 36 | Cyan |
| Directive (EQU, DB, DW, DS, ORG, etc.) | 33 | Yellow |
| Register (A B C D E H L M SP PSW HL DE BC AF) | 32 | Green |
| Numeric literal | 35 | Magenta |
| String literal (`'...'` or `"..."`) | 35 | Magenta |
| Comment (`;` to EOL) | 2 | Dim |
| Normal text | 0 | Normal |

Syntax mode is set automatically by SYNINIT based on file extension (`.MAC`, `.ASM`, `.INC` -> SYN_ASM; all others -> SYN_NONE).

---

## 9. File I/O

### 9.1 Load File

1. Build FCB from filename; save filename into BD_FNAME
2. Initialize gap buffer to empty
3. Open via BDOS BF_FOPEN
4. If not found: proceed as new empty file with `New file` status
5. Read 128-byte records (BF_FREAD) sequentially into buffer:
   - Skip CPMEOF (`1AH`) markers
   - CR stored as-is (invisible in display)
   - LF marks line boundary
   - Lines wider than MAXCOLS (255) chars generate a warning
6. Close file; move cursor to top; clear MODIFIED flag
7. Call SYNINIT to detect syntax mode from extension

### 9.2 Save File

1. Check BD_MODIF — skip if buffer is clean
2. Build FCB from BD_FNAME
3. Rename existing file to `.BAK` (delete old .BAK first)
4. Create new file via BDOS BF_FMAKE
5. Write buffer contents record-by-record (bytes written verbatim from gap buffer):
   - No CR+LF conversion needed — buffer already stores CR+LF pairs
   - Pad final 128-byte record with zeros
   - Append CPMEOF marker
6. Close file; clear MODIFIED flag

---

## 10. VT100 Terminal Interface

### 10.1 Cursor Positioning
```
ESC [ row ; col H       (rows and cols are 1-based)
```

### 10.2 SGR Attributes
```
ESC [ 0 m               reset
ESC [ 1 m               bold
ESC [ 2 m               dim
ESC [ 7 m               reverse video
ESC [ 3n m              foreground color n (0-7)
```

### 10.3 Selective Redraw System

The main loop uses a two-flag dirty system to minimize screen updates:

| DIRTY | DRTLINE | Action |
|-------|---------|--------|
| 1 | * | SCRDRAW: full 20-line redraw + ruler + separator + status clear |
| 0 | 1 | SCREDCL: current line only (uses GBCURLN for O(line_length) access) |
| 0 | 0 | No content redraw (cursor-only move) |

INFOBAR and CURPOS always run regardless of dirty flags.

### 10.4 Key Decoder State Machine

Reads BDOS BF_RAWIO in non-blocking mode. Seven states:

| State | Description |
|-------|-------------|
| KST_IDL (0) | Idle — no prefix active |
| KST_ESC (1) | Received ESC — waiting for `[`, `O`, or timeout |
| KST_CSI (2) | Received `ESC [` — waiting for final byte |
| KST_SS3 (3) | Received `ESC O` — waiting for final byte |
| KST_CSP (4) | CSI with parameter digits accumulating |
| KST_CTK (5) | Ctrl-K prefix active — waiting for second key |
| KST_CTQ (6) | Ctrl-Q prefix active — waiting for second key |

Returns: B = key type (KT_NONE, KT_ACT, KT_CHAR), C = action code or ASCII character.

---

## 11. Module Structure

All source files follow CP/M 8.3 naming. SEDIT is built from 11 modules plus a shared include file.

| Source File | Purpose |
|-------------|---------|
| `SEDIT.MAC` | Entry point, main loop, action dispatch, memory allocation |
| `SEDIT.INC` | Shared equates (inlined by CPMFMT.PY into each .MAC file) |
| `SESCREEN.MAC` | VT100 output, screen rendering, info bar, cursor positioning |
| `SEKEY.MAC` | Key input, VT100 escape sequence decoder, dispatch tables |
| `SEGAPBUF.MAC` | Gap buffer text engine |
| `SEFILEIO.MAC` | File load/save, FCB management, .BAK backup |
| `SEMENU.MAC` | ESC menu overlay, item dispatch, row 24 prompts |
| `SESEARCH.MAC` | Find text search |
| `SEBLOCK.MAC` | Block mark, copy, delete, paste, clipboard buffer |
| `SESYNTAX.MAC` | Syntax highlighting tokenizer, ASM keyword tables |
| `SEKEYBND.MAC` | Key binding init from `SEDIT.KEY` |
| `SEHELP.MAC` | Help screen overlay, BMDATEND marker |

Additionally: `KEYCODE.MAC` is a standalone key diagnostic tool (not linked into SEDIT).

### 11.1 Build Process

```
; Preprocess (inlines SEDIT.INC, normalizes CR+LF, appends Ctrl-Z EOF):
python CPMFMT.PY *.MAC

; Assemble each module:
M80 =SEDIT
M80 =SESCREEN
M80 =SEKEY
M80 =SEGAPBUF
M80 =SEFILEIO
M80 =SEMENU
M80 =SESEARCH
M80 =SEBLOCK
M80 =SESYNTAX
M80 =SEKEYBND
M80 =SEHELP

; Link (SEHELP must be last — BMDATEND is at end of its CSEG):
L80 SEDIT,SESCREEN,SEKEY,SEGAPBUF,SEFILEIO,SEMENU,SESEARCH,SEBLOCK,SESYNTAX,SEKEYBND,SEHELP,SEDIT/N/E
```

Or use `SUBMIT BUILD` with `BUILD.SUB` on CP/M.

### 11.2 Link Order Constraint

SEHELP must be the **last** module in the link order. `BMDATEND EQU $` is defined at the end of SEHELP's CSEG section. L80 lays out `[DSEG][CSEG]` per module in link order, so BMDATEND must be in CSEG of the last module to capture all code and data. The gap buffer starts at BMDATEND.

---

## 12. Startup Sequence

1. Save incoming stack pointer; set local stack
2. Read BDOS address from `0006H`; compute TPA top
3. Calculate available RAM (TPATOP - BMDATEND); if < 9 KB, refuse to run
4. Initialize single gap buffer (base = BMDATEND, size = available RAM)
5. Set up buffer descriptor (BDESC0); fill BD_FNAME with spaces
6. Load and parse `SEDIT.KEY`; fall back to compiled-in defaults if not found
7. Initialize screen: clear, draw info bar, ruler, separator
8. If a filename was passed on command line (FCB at `005CH`), load file
9. Draw initial edit area; position cursor at line 1, col 1
10. Enter main edit loop

---

## 13. Exit Sequence

1. If buffer is modified, prompt user to save
2. Save as directed
3. Clear screen (`ESC [ 2 J ESC [ H`)
4. Warm boot via `JMP 0000H`

---

## 14. Error Handling

| Condition | Response |
|-----------|----------|
| Buffer full | BEL; status message |
| File load: line > 255 chars | Warning in status bar |
| Disk full on save | `Disk error` in status bar; buffer stays modified |
| File not found on open | Open empty buffer; `New file` in status bar |
| TPA too small (< 9 KB) | Print message to console; exit immediately |
| Not found (search) | `Not found` in status bar; cursor unchanged |
| SEDIT.KEY parse error | Ignored; uses defaults |

---

## 15. Limitations

- Maximum stored line length: 255 characters (MAXCOLS)
- Maximum visible line width: 73 characters without scrolling (TXTCOLS)
- Maximum file size: limited by available TPA (~30-38 KB typical)
- Single edit buffer (no split view or buffer switching)
- No undo
- No find-and-replace (find only)
- CP/M 8.3 filenames only; no subdirectories
- No binary file support (NUL bytes not handled)
- Line numbers display up to 9999
