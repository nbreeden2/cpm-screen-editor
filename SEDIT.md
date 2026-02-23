# SEDIT — Screen Editor Specification

**Platform:** CP/M 2.2, Intel 8080
**Assembler:** Microsoft M80.COM / L80.COM
**Terminal:** VT100 / ANSI
**Editing Model:** Full-screen, ESC-menu driven, WordStar-compatible escape sequences as baseline
**Version:** 0.2 (draft)

---

## 1. Overview

SEDIT is a full-screen plain-text editor for CP/M 2.2 written in Intel 8080 assembly language, assembled with M80 and linked with L80. It targets the VT100/ANSI terminal. Navigation and editing use WordStar-style Ctrl-key bindings as the default set; all bindings are user-configurable via an external key binding file. Pressing ESC opens an interactive menu for file, navigation, and block operations.

### 1.1 Goals

- Fast, responsive screen editing on a 2 MHz 8080 system
- Up to 2 named edit buffers open simultaneously
- ESC-driven command menu with keyboard navigation
- Find / Find-and-replace
- Block mark, copy, paste, and delete
- Syntax highlighting using ANSI SGR attributes for assembly language (`.MAC`) files
- User-configurable key bindings loaded from `SEDIT.KEY` on startup
- Clean return to CP/M on exit; no file corruption on abort

### 1.2 Non-Goals

- Files larger than available TPA RAM
- Mouse support
- Undo history (stretch goal)
- Binary file editing
- Subdirectory file paths (CP/M 2.2 is flat)

---

## 2. Screen Layout

80 columns × 24 rows, VT100 terminal. The screen is divided into five fixed zones.

```
Row  1  ┌─ Info bar ──────────────────────────────────────────────────────────────┐
Row  2  │  Tab stop ruler                                                          │
Row  3  │  ╔══ edit area top ═══════════════════════════════════════════════════╗  │
  ...   │  ║  text lines (rows 3–22)                                           ║  │
Row 22  │  ╚══ edit area bottom ══════════════════════════════════════════════╝  │
Row 23  │  ════════════════════════════════════════════════════════════════════   │
Row 24  └─ Status / operation bar ────────────────────────────────────────────────┘
```

### 2.1 Row 1 — Info Bar

Displays file metadata for the active buffer. All fields are separated by spaces.

```
A:MAIN.MAC   Lines:1024   Row:142   Col:35   [INS]   [MODIFIED]   SEDIT v1.0
```

| Field | Description |
|-------|-------------|
| Drive + filename | `A:MAIN.MAC` — CP/M drive letter and 8.3 filename |
| `Lines:n` | Total number of lines in the file |
| `Row:n` | Current cursor line (1-based) |
| `Col:n` | Current cursor column within the text (1-based, excludes line-number gutter) |
| `[INS]` / `[OVR]` | Insert or Overwrite mode indicator |
| `[MODIFIED]` | Shown only when the buffer has unsaved changes |
| Editor name/version | Right-aligned: `SEDIT v1.0` |

### 2.2 Row 2 — Tab Stop Ruler

A 74-character ruler showing tab stop positions within the text area (columns 5–78 of the terminal, corresponding to text columns 1–74).

```
    :    :    :    :    :    :    :    :    :    :    :    :    :    :    :
```

- Each `:` marks a tab stop (default every 4 columns)
- The ruler is always 74 characters wide, aligned with the text columns
- Tab stops are configurable; ruler updates whenever tab stops are changed

### 2.3 Rows 3–22 — Edit Area (20 lines)

Each row shows one line of text in the following fixed format:

```
COL:  1   2   3   4   5 ─────────────────────────────────────────────── 78
      │   │   │   │   │
      └─line no─┘ spc └──────── up to 74 characters of text ────────────┘
```

| Columns | Content |
|---------|---------|
| 1–3 | Line number, right-justified, space-padded (` 1`–`999`; see §2.3.1) |
| 4 | Single space separator |
| 5–78 | Text content — up to 74 characters per line |
| 79–80 | Unused (always blank) |

#### 2.3.1 Line Number Display

- Line numbers are right-justified in a 3-character field (columns 1–3)
- Lines 1–999 display as `  1`, ` 42`, `999`
- Lines 1000 and above: the line number field displays the low 3 digits only (e.g., line 1000 shows as `  0`, prefixed with a `+` overflow indicator in column 1 if space permits — exact overflow handling TBD at implementation)
- The current cursor line's number is displayed in **bold** (SGR 1)
- Lines within a marked block have their line numbers displayed in **reverse video** (SGR 7)

#### 2.3.2 Line Width Constraint

- Maximum stored line width: **74 characters** (excluding CR/LF)
- On disk, each line is stored as up to 74 printable characters followed by `0DH 0AH` (CR/LF), totalling a maximum of 76 bytes per line
- If the user attempts to type past column 74, the editor beeps (BEL, `07H`) and ignores the input
- Lines longer than 74 characters in files loaded from disk are truncated to 74 characters with a warning displayed in the status bar

#### 2.3.3 Tab Character Display

- Tab characters in the stored file are displayed as spaces expanding to the next tab stop
- Tab stops apply within the 74-character text field (columns 1–74 of the text, displayed in terminal columns 5–78)
- Stored text contains literal `09H` tab characters; tab width is a display-only setting

### 2.4 Row 23 — Separator Line

A full 80-character line of `=` characters:

```
================================================================================
```

Drawn once at startup; redrawn only if overwritten by a scroll operation error.

### 2.5 Row 24 — Status / Operation Bar

Used for two purposes:

1. **Status messages** — transient informational text:
   ```
   Saving file...        File saved.        Not found.        Buffer full.
   ```

2. **Input prompts** — when a menu operation requires text input:
   ```
   Find text: _
   Replace with: _
   Open file: A:_
   Jump to line: _
   ```

Messages are displayed and remain until the next keypress or operation. Prompts wait for Enter or ESC. The bar is always cleared before displaying a new message or prompt.

---

## 3. ESC Menu System

Pressing `ESC` at any time (while not in a prompt) opens the command menu. The menu overlays rows 3–22 of the edit area with a bordered menu panel; the edit area is restored when the menu is dismissed.

### 3.1 Menu Panel Layout

```
Row  3  ╔══════════════════════════════╗
Row  4  ║         SEDIT  MENU          ║
Row  5  ╠══════════════════════════════╣
Row  6  ║  O  Open file                ║
Row  7  ║  S  Save file                ║
Row  8  ║  X  Exit editor              ║
Row  9  ╠══════════════════════════════╣
Row 10  ║  C  Copy marked block        ║
Row 11  ║  D  Delete marked block      ║
Row 12  ║  M  Mark block start/end     ║
Row 13  ║  P  Paste                    ║
Row 14  ╠══════════════════════════════╣
Row 15  ║  G  Jump to line number      ║
Row 16  ║  H  Jump to start of line    ║
Row 17  ║  E  Jump to end of line      ║
Row 18  ║  T  Jump to top of file      ║
Row 19  ║  B  Jump to end of file      ║
Row 20  ║  U  Page up                  ║
Row 21  ║  N  Page down                ║
Row 22  ╠══════════════════════════════╣
Row 23  ║  F  Find text                ║  (row 23 used for extended menu)
         ║  A  Find next               ║
         ║  R  Find and replace        ║
         ║  W  Next word               ║
         ║  Q  Previous word           ║
         ╚══════════════════════════════╝
```

Because all items do not fit in 20 rows, the menu scrolls or uses two columns. Exact visual layout is determined at implementation; the item list is fixed.

### 3.2 Menu Navigation

| Key | Action |
|-----|--------|
| Up / Down arrow or `^E` / `^X` | Move highlight |
| Enter or the shortcut letter | Execute highlighted item |
| ESC | Cancel menu, return to editing |

The shortcut letter is the bold letter shown in the menu (case-insensitive). Pressing the shortcut key immediately executes the item without needing Enter.

### 3.3 Menu Item Details

#### O — Open File
- Prompt on row 24: `Open file: A:_`
- User types drive + filename (8.3 format)
- If a free buffer slot exists, file is loaded into it and becomes active
- If all 2 slots are occupied, display `No free buffer slots`
- If file does not exist, open an empty buffer with the given name

#### S — Save File
- Save active buffer to its filename using BDOS F_DELETE + F_MAKE + sequential F_WRITE
- Display `Saving file...` then `File saved.` in status bar
- If filename is `[No Name]`, prompt for a filename first

#### X — Exit Editor
- Check all buffers for `MODIFIED` flag
- For each modified buffer, prompt:
  `Buffer n (filename) not saved. Save? (Y/N/A=all/Q=quit exit)`
- After all buffers resolved, clear screen and warm boot via `JMP 0000H`

#### M — Mark Block Start / End
- First invocation: places **block start** marker at cursor position; status shows `Block start marked`
- Second invocation: places **block end** marker; status shows `Block marked (n lines)`
- Third invocation: clears both markers; status shows `Block cleared`
- Marked region highlighted in reverse video in the edit area

#### C — Copy Marked Block
- Requires a marked block (see M)
- Copies marked text into the **paste buffer** (clipboard)
- Inserts clipboard content at the current cursor position
- Clears the block markers after copy
- Status: `Block copied (n lines)`

#### D — Delete Marked Block
- Requires a marked block
- Deletes the marked text; saves it in the paste buffer (last deleted block can be pasted)
- Status: `Block deleted (n lines)`

#### P — Paste
- Inserts the contents of the paste buffer at the current cursor position
- If paste buffer is empty, status: `Nothing to paste`
- Status: `Pasted (n lines)`

#### G — Jump to Line Number
- Prompt: `Jump to line: _`
- User enters a decimal line number; cursor moves to column 1 of that line
- If line number exceeds file length, cursor moves to last line
- Status: `Jumped to line n`

#### H — Jump to Start of Line
- Moves cursor to text column 1 of the current line (position after the line-number gutter)

#### E — Jump to End of Line
- Moves cursor to the last non-space character of the current line, or to column 74 if line is full

#### T — Jump to Top of File
- Cursor to line 1, column 1; scroll edit area to show top of file

#### B — Jump to End of File
- Cursor to last line, last column; scroll to show end of file

#### U — Page Up
- Scroll edit area up by 20 lines; cursor moves to same relative position or top of screen

#### N — Page Down
- Scroll edit area down by 20 lines; cursor to same relative position or bottom of screen

#### F — Find Text
- Prompt: `Find: _`
- User enters search string (max 63 characters); Enter to search
- Search begins from cursor position, wraps to top of file if not found before EOF
- First match highlighted; cursor placed at match start
- Status: `Found at line n` or `Not found`

#### A — Find Next
- Repeats the last Find operation from the current cursor position
- If no previous search, behaves as F

#### R — Find and Replace
- Prompt sequence:
  1. `Find: _` (search string, max 63 chars)
  2. `Replace with: _` (replacement string, max 63 chars)
  3. `Options (G=global N=no-prompt W=whole-word U=case-fold): _`
- Without G: stops at each match, prompts `Replace? (Y/N/A=all/Q=quit)`
- With G + N: replaces all without prompting; reports count
- Status: `Replaced n occurrences`

#### W — Next Word
- Moves cursor to the first character of the next word (whitespace/punctuation boundary)

#### Q — Previous Word
- Moves cursor to the first character of the previous word

---

## 4. Default Key Bindings (WordStar-Style)

These bindings are active when no custom `.KEY` file overrides them. ESC always opens the menu and is not rebindable.

### 4.1 Cursor Movement (no prefix)

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

### 4.2 Editing

| Key | Action |
|-----|--------|
| Printable character | Insert (Insert mode) or Overwrite |
| `^H` / Backspace | Delete character left |
| `^G` / Delete | Delete character at cursor |
| `^T` | Delete word right |
| `^Y` | Delete current line |
| `^I` / Tab | Insert tab |
| `Enter` | Insert newline (if at or before col 74) |
| `^V` | Toggle Insert / Overwrite mode |
| `^P` | Insert next key as literal control character |

### 4.3 Shortcuts (bypass menu)

Frequently-used menu items may be assigned direct Ctrl-key shortcuts. The defaults:

| Key | Menu equivalent |
|-----|----------------|
| `^KS` | Save file |
| `^KQ` | Find (Quick Find) |
| `^L` | Find next |
| `^B` | Jump to start of line |
| `^N` | Jump to end of line |
| `^QB` | Jump to top of file |
| `^QC` | Jump to end of file |
| `^KB` | Mark block (toggle start/end) |
| `^KC` | Copy block |
| `^KD` | Delete block |
| `^KP` | Paste |

---

## 5. Key Binding File (`SEDIT.KEY`)

SEDIT loads `SEDIT.KEY` from the current drive/user at startup. If the file is not present, the default WordStar bindings (§4) are used.

### 5.1 Format

Plain text, one binding per line. Lines beginning with `;` are comments. Blank lines are ignored.

```
; SEDIT.KEY — Custom key bindings
; Format:  KEY  ACTION  [ACTION2  [ACTION3]]
; Up to 3 actions can be bound to a single key.

; Ctrl keys:  ^A  ^B  ...  ^Z
; Special:    UP  DN  LT  RT  PGUP PGDN HOME END
;             F1  F2  F3  F4  F5  F6  F7  F8  F9  F10  F11  F12
;             BS  DEL  ESC  TAB  ENTER
; Prefix seq: ^K^S  ^Q^F  etc.

; Actions: (names are case-insensitive)
;   CURSOR_UP  CURSOR_DOWN  CURSOR_LEFT  CURSOR_RIGHT
;   WORD_PREV  WORD_NEXT
;   PAGE_UP    PAGE_DOWN
;   SCROLL_UP  SCROLL_DOWN
;   LINE_START  LINE_END
;   FILE_TOP   FILE_END
;   GOTO_LINE
;   DELETE_LEFT  DELETE_RIGHT  DELETE_WORD  DELETE_LINE
;   INSERT_TAB  INSERT_NL
;   TOGGLE_INSERT
;   BLOCK_MARK  BLOCK_COPY  BLOCK_DELETE  BLOCK_PASTE
;   FIND  FIND_NEXT  FIND_REPLACE
;   FILE_SAVE  FILE_OPEN  FILE_EXIT
;   MENU  (open ESC menu)
;   LITERAL_NEXT  (next char inserted literally)

^E          CURSOR_UP
^X          CURSOR_DOWN
^S          CURSOR_LEFT
^D          CURSOR_RIGHT
UP          CURSOR_UP
DOWN        CURSOR_DOWN
LEFT        CURSOR_LEFT
RIGHT       CURSOR_RIGHT
^A          WORD_PREV
^F          WORD_NEXT
^R          PAGE_UP
^C          PAGE_DOWN
^W          SCROLL_UP
^Z          SCROLL_DOWN
^G          DELETE_RIGHT
^H          DELETE_LEFT
^T          DELETE_WORD
^Y          DELETE_LINE
^V          TOGGLE_INSERT
^I          INSERT_TAB
ENTER       INSERT_NL
^P          LITERAL_NEXT
^L          FIND_NEXT
^K^S        FILE_SAVE
^K^B        BLOCK_MARK
^K^C        BLOCK_COPY
^K^D        BLOCK_DELETE
^K^P        BLOCK_PASTE
```

### 5.2 Multiple Key Sequences Per Action (Input Aliasing)

Up to **3 different key sequences** may be bound to the same action on separate lines. All sequences are equivalent — any one of them triggers the action. This covers the common situation where different terminal emulators send different byte sequences for the same physical key.

```
; Cursor up — three common sequences that physical terminals
; and emulators send for the Up arrow key:
;   ^E          WordStar Ctrl-E
;   ESC [ A     VT100 ANSI cursor key (CSI A)
;   ESC O A     VT100 application cursor key mode (SS3 A)
^E          CURSOR_UP
CSI_A       CURSOR_UP
SS3_A       CURSOR_UP

; Cursor down
^X          CURSOR_DOWN
CSI_B       CURSOR_DOWN
SS3_B       CURSOR_DOWN

; Cursor right
^D          CURSOR_RIGHT
CSI_C       CURSOR_RIGHT
SS3_C       CURSOR_RIGHT

; Cursor left
^S          CURSOR_LEFT
CSI_D       CURSOR_LEFT
SS3_D       CURSOR_LEFT
```

The parser does not care how many lines map to the same action — any number of key sequences may share an action name. The limit of 3 is a **per-action guideline** for the built-in defaults; the file format imposes no hard limit.

#### Predefined Escape Sequence Names

Because raw escape sequences are not typeable in a plain text file, SEDIT.KEY uses symbolic names for multi-byte sequences:

| Symbolic Name | Bytes Sent | Common Source |
|---------------|-----------|---------------|
| `CSI_A` | `1B 5B 41` | VT100 ANSI mode Up arrow |
| `CSI_B` | `1B 5B 42` | VT100 ANSI mode Down arrow |
| `CSI_C` | `1B 5B 43` | VT100 ANSI mode Right arrow |
| `CSI_D` | `1B 5B 44` | VT100 ANSI mode Left arrow |
| `SS3_A` | `1B 4F 41` | VT100 application mode Up arrow |
| `SS3_B` | `1B 4F 42` | VT100 application mode Down arrow |
| `SS3_C` | `1B 4F 43` | VT100 application mode Right arrow |
| `SS3_D` | `1B 4F 44` | VT100 application mode Left arrow |
| `CSI_H` | `1B 5B 48` | xterm / Linux Home key |
| `CSI_F` | `1B 5B 46` | xterm / Linux End key |
| `CSI_1~` | `1B 5B 31 7E` | VT220-style Home |
| `CSI_4~` | `1B 5B 34 7E` | VT220-style End |
| `CSI_2~` | `1B 5B 32 7E` | Insert key |
| `CSI_3~` | `1B 5B 33 7E` | Delete key |
| `CSI_5~` | `1B 5B 35 7E` | Page Up |
| `CSI_6~` | `1B 5B 36 7E` | Page Down |
| `SS3_P` | `1B 4F 50` | VT100 F1 |
| `SS3_Q` | `1B 4F 51` | VT100 F2 |
| `SS3_R` | `1B 4F 52` | VT100 F3 |
| `SS3_S` | `1B 4F 53` | VT100 F4 |
| `CSI_15~` | `1B 5B 31 35 7E` | F5 |
| `CSI_17~` | `1B 5B 31 37 7E` | F6 |
| `CSI_18~` | `1B 5B 31 38 7E` | F7 |
| `CSI_19~` | `1B 5B 31 39 7E` | F8 |

Additional symbolic names may be added; unrecognised names produce a startup warning.

#### Default Cursor Key Aliasing (built-in)

The compiled-in defaults bind all three common variants for every cursor and navigation key so SEDIT works correctly regardless of whether the terminal is in ANSI or application cursor key mode:

| Action | Binding 1 | Binding 2 (CSI) | Binding 3 (SS3) |
|--------|-----------|-----------------|-----------------|
| CURSOR_UP | `^E` | `CSI_A` | `SS3_A` |
| CURSOR_DOWN | `^X` | `CSI_B` | `SS3_B` |
| CURSOR_RIGHT | `^D` | `CSI_C` | `SS3_C` |
| CURSOR_LEFT | `^S` | `CSI_D` | `SS3_D` |
| PAGE_UP | `^R` | `CSI_5~` | — |
| PAGE_DOWN | `^C` | `CSI_6~` | — |
| LINE_START | `^B` | `CSI_H` | `CSI_1~` |
| LINE_END | `^N` | `CSI_F` | `CSI_4~` |
| DELETE_RIGHT | `^G` | `CSI_3~` | — |

### 5.3 Binding Restrictions

- ESC is permanently bound to `MENU` and cannot be rebound
- Any number of key sequences may map to the same action
- Each key sequence may map to exactly **one** action (one-to-many is allowed; many-to-one within a sequence is not)
- Unknown action names produce a startup warning in the status bar and are ignored
- Unknown symbolic sequence names produce a startup warning and are ignored
- If the same key sequence is listed more than once, the last definition wins

### 5.4 Startup Load Sequence

1. Open `SEDIT.KEY` on the current drive (BDOS F_OPEN)
2. Read entire file into a parse buffer
3. Parse line by line: tokenize key/sequence name and action name
4. Build a **key dispatch table**: 256-entry array indexed by key code for single-byte keys, plus a trie or sequential scan table for multi-byte escape sequences
5. If `SEDIT.KEY` not found, initialize dispatch table from compiled-in defaults

---

## 6. Gap Buffer Architecture

Each edit buffer uses a **gap buffer**: a flat RAM array with a movable hole at the cursor position.

### 6.1 Buffer Descriptor (32 bytes each)

```
Offset  Size  Field       Description
------  ----  ----------  ---------------------------------------------------
  0      2    BSTART      Buffer base address in RAM
  2      2    BSIZE       Total buffer capacity in bytes
  4      2    GAPBEG      Offset: start of gap (first unused byte)
  6      2    GAPEND      Offset: end of gap (exclusive; first text byte after gap)
  8      2    TEXTEND     Offset: end of all text (= total chars in buffer)
 10      2    TOPLINE     Line number at top of visible screen (0-based)
 12      1    CURSROW     Cursor row on screen (0-based, 0 = row 3)
 13      1    CURSCOL     Cursor column within text (0-based, 0 = text col 1)
 14      2    CURSOFF     Absolute byte offset to cursor in logical text
 16      2    MARKBEG     Block mark start offset; 0FFFFH = no mark
 18      2    MARKEND     Block mark end offset; 0FFFFH = no mark
 20      1    MODIFIED    Non-zero if buffer has unsaved changes
 21      1    SYNTAXMODE  0=plain, 1=ASM/MAC
 22     10    FILENAME    Drive (1) + name (8) + ext (3) = 12 raw chars, 0-padded
```

### 6.2 Core Gap Buffer Operations

#### Insert character at cursor
1. If `GAPBEG = GAPEND` (gap size = 0): status `Buffer full`, ring BEL, return
2. Store character at `BSTART + GAPBEG`
3. Increment `GAPBEG`; set `MODIFIED`

#### Delete character at cursor (forward, Delete key / `^G`)
1. If `GAPEND = BSTART + BSIZE`: at end of buffer; return
2. Increment `GAPEND`; set `MODIFIED`

#### Delete character before cursor (backspace, `^H`)
1. If `GAPBEG = 0`: at beginning; return
2. Decrement `GAPBEG`; set `MODIFIED`

#### Move gap to position P (cursor motion)
1. If P < GAPBEG: copy bytes `[P .. GAPBEG-1]` rightward by gap size
2. If P > GAPBEG: copy bytes `[GAPEND .. GAPEND+(P-GAPBEG)-1]` leftward by gap size
3. Update GAPBEG = P; GAPEND = P + gap_size

---

## 7. Memory Map

Standard 64K CP/M 2.2 system.

```
FFFF ┌─────────────────────────────────────────┐
     │  CP/M (BIOS + BDOS + CCP)               │  ~8 KB
E800 ├─────────────────────────────────────────┤  (approximate)
     │  SEDIT stack                            │  256 bytes
     ├─────────────────────────────────────────┤
     │  Screen shadow buffer                   │  80 × 24 × 2 = 3,840 bytes
     │  (char + attribute per cell)            │
     ├─────────────────────────────────────────┤
     │  Paste (clipboard) buffer               │  2,048 bytes
     ├─────────────────────────────────────────┤
     │  Key dispatch table                     │  512 bytes
     ├─────────────────────────────────────────┤
     │  Find / replace string buffers          │  2 × 64 = 128 bytes
     ├─────────────────────────────────────────┤
     │  2 buffer descriptors                   │  2 × 32 = 64 bytes
     ├─────────────────────────────────────────┤
     │  2 edit gap buffers (equal split)       │  ~30–38 KB
     ├─────────────────────────────────────────┤
     │  SEDIT code (CSEG) + DSEG               │  ~10–12 KB estimated
0100 └─────────────────────────────────────────┘
```

TPA budget is determined at runtime (see §9 Startup). If TPA < 32 KB, reduce to 2 buffers. If TPA < 18 KB, refuse to run with an error message.

---

## 8. Syntax Highlighting

Rendered per visible line at draw time, not stored. Uses ANSI SGR.

### 8.1 ASM Mode (`.MAC`, `.ASM`, `.INC`)

| Token Type | SGR Code | Color/Style |
|------------|----------|-------------|
| Label (col 1, no leading space) | `1` | Bold |
| Mnemonic / opcode | `36` | Cyan |
| Directive (EQU DB DW DS ORG etc.) | `33` | Yellow |
| Register (A B C D E H L M SP PSW) | `32` | Green |
| Numeric literal | `35` | Magenta |
| String literal (`'...'`) | `33` | Yellow |
| Comment (`;` to EOL) | `2` | Dim |
| Default | `0` | Normal |

### 8.2 Plain Text Mode
No highlighting; all text in normal attribute (`SGR 0`). Used for `.TXT`, unknown extensions, and when highlighting is toggled off.

---

## 9. File I/O

### 9.1 Load File into Buffer
1. Open via BDOS F_OPEN (fn 15), FCB built from filename
2. Set DMA to gap buffer base (BDOS fn 26)
3. Read 128-byte records (fn 20) sequentially into gap buffer, tracking byte count
4. Strip trailing `1AH` (CP/M EOF) characters from last record
5. Place gap at end of text: `GAPBEG = byte_count`, `GAPEND = BSIZE`
6. Close file (fn 16)

Lines in the gap buffer are separated by `0DH 0AH` (CR/LF). Lines longer than 74 characters are truncated on load with a status bar warning.

### 9.2 Save Buffer to File
1. Delete existing file: BDOS F_DELETE (fn 19)
2. Create new file: BDOS F_MAKE (fn 22)
3. Write text before gap in 128-byte chunks; then text after gap
4. Pad final 128-byte record to full size with `1AH` (CP/M EOF convention)
5. Close (fn 16); clear `MODIFIED`

---

## 10. VT100 Terminal Interface

### 10.1 Initialization Sequence
```
ESC [ ? 25 l        ; hide cursor
ESC [ 2 J           ; erase entire screen
ESC [ H             ; cursor home
```
Draw info bar (row 1), tab ruler (row 2), separator (row 23), status bar (row 24), then the 20 edit lines. Then:
```
ESC [ ? 25 h        ; show cursor
```

### 10.2 Cursor Positioning
```
ESC [ row ; col H   ; rows and cols are 1-based
```

### 10.3 SGR Attributes
```
ESC [ 0 m           ; reset
ESC [ 1 m           ; bold
ESC [ 2 m           ; dim
ESC [ 7 m           ; reverse video
ESC [ 3n m          ; foreground color n (0–7)
```

### 10.4 Screen Shadow Buffer
A `80 × 24 × 2` byte array holds `(character, attribute)` for every cell currently displayed. Before writing, SEDIT compares the new cell against the shadow; only changed cells are transmitted. Consecutive changed cells with the same attribute are sent as one SGR followed by multiple characters.

### 10.5 Key Decoder State Machine

Reads BDOS fn 6 (C_RAWIO) in non-blocking mode in the main loop. State machine handles VT100 multi-byte sequences:

| Input | State | Event |
|-------|-------|-------|
| `1BH` (ESC) | Idle | → ESC_STATE; start timeout counter |
| `[` | ESC_STATE | → CSI_STATE |
| `A`/`B`/`C`/`D` | CSI_STATE | KEY_UP/DOWN/RIGHT/LEFT |
| `O` | ESC_STATE | → SS3_STATE |
| `P`–`S` | SS3_STATE | KEY_F1–KEY_F4 |
| `~` | CSI_STATE | decode param → KEY_F5..F12, INSERT, DELETE, HOME, END, PGUP, PGDN |
| Timeout | ESC_STATE | KEY_ESC → open menu |
| Any control | Idle | KEY_CTRL_x |
| Printable | Idle | KEY_CHAR |

Timeout for ESC disambiguation: poll C_STAT approximately 500 times (~1 ms at 2 MHz) before deciding ESC is standalone.

---

## 11. Module Structure

All source files follow the CP/M 8.3 naming convention. The root file is `SEDIT.MAC`;
all other module files are named `SE??????.MAC` where the six characters describe
the module's content. Each file must stay under **900 lines** and **20 KB** so that
SEDIT can open and edit its own source files.

| Source File | Lines (est.) | Responsibility |
|-------------|-------------|----------------|
| `SEDIT.MAC` | ~200 | Root: `START:` entry, TPA probe, main edit loop, build instructions |
| `SEDIT.INC` | ~150 | Shared equates, BDOS functions, structure offsets — INCLUDEd by all |
| `SESCREEN.MAC` | ~600 | VT100 cursor/SGR output, shadow buffer diff, full/partial redraw |
| `SEKEY.MAC` | ~350 | VT100 escape sequence decoder, key dispatch table lookup |
| `SEGAPBUF.MAC` | ~400 | Gap buffer engine: insert, delete, move, line/col tracking |
| `SEFILEIO.MAC` | ~350 | BDOS open/create/read/write/close, FCB management |
| `SEMENU.MAC` | ~400 | Menu draw, navigation, item dispatch, row 24 prompts |
| `SESEARCH.MAC` | ~350 | Find algorithm, replace loop, option parsing |
| `SEBLOCK.MAC` | ~300 | Block mark, copy, delete, paste, clipboard buffer |
| `SEBUFMGR.MAC` | ~250 | Buffer descriptor table, buffer switching, info bar update |
| `SESYNTAX.MAC` | ~350 | Per-line tokenizer, SGR span generation, ASM keyword table |
| `SEKEYBND.MAC` | ~400 | Parse `SEDIT.KEY`, build single-byte and escape-sequence dispatch tables |
| `SEHELP.MAC` | ~200 | Help screen text data and display routine |

### 11.1 File Header Block

Every `.MAC` and `.INC` file begins with a standard header comment block:

```asm
;============================================================
; FILE:    SESCREEN.MAC
; PROJECT: SEDIT - Screen Editor for CP/M 2.2
; VERSION: 1.0
; DATE:    1984-01-01
; AUTHOR:
;------------------------------------------------------------
; DESCRIPTION:
;   VT100/ANSI screen output. Manages the 80x24 shadow
;   buffer, cursor positioning, SGR attribute control,
;   and full/partial screen redraw.
;------------------------------------------------------------
; REVISION HISTORY:
;   1.0  1984-01-01  Initial version
;============================================================
        INCLUDE SEDIT.INC
```

The version number and date are updated with every change to that file.
`SEDIT.INC` is always the first INCLUDE in every module.

### 11.2 Root File — `SEDIT.MAC`

`SEDIT.MAC` is the only file assembled first. It contains:

- The standard file header (§11.1)
- A **build instructions block** — a comment section giving the complete
  assembly and link commands for the whole project (see §11.3)
- The `START:` entry point (the `.COM` load address at `0100H`)
- TPA size detection and memory allocation
- Main edit loop and top-level key dispatch
- `EXTRN` declarations for all cross-module entry points
- The `END START` assembler directive

### 11.3 Build Instructions Block (in `SEDIT.MAC`)

```asm
;============================================================
; BUILD INSTRUCTIONS
;
; Assemble all modules:
;   M80 =SEDIT
;   M80 =SESCREEN
;   M80 =SEKEY
;   M80 =SEGAPBUF
;   M80 =SEFILEIO
;   M80 =SEMENU
;   M80 =SESEARCH
;   M80 =SEBLOCK
;   M80 =SEBUFMGR
;   M80 =SESYNTAX
;   M80 =SEKEYBND
;   M80 =SEHELP
;
; Link:
;   L80 SEDIT,SESCREEN,SEKEY,SEGAPBUF,SEFILEIO,^
;       SEMENU,SESEARCH,SEBLOCK,SEBUFMGR,^
;       SESYNTAX,SEKEYBND,SEHELP,SEDIT/N/E
;
; Or use the batch script:
;   SUBMIT BUILD
;============================================================
```

### 11.4 Build Script (`BUILD.SUB`)

```
M80 =SEDIT
M80 =SESCREEN
M80 =SEKEY
M80 =SEGAPBUF
M80 =SEFILEIO
M80 =SEMENU
M80 =SESEARCH
M80 =SEBLOCK
M80 =SEBUFMGR
M80 =SESYNTAX
M80 =SEKEYBND
M80 =SEHELP
L80 SEDIT,SESCREEN,SEKEY,SEGAPBUF,SEFILEIO,SEMENU,SESEARCH,SEBLOCK,SEBUFMGR,SESYNTAX,SEKEYBND,SEHELP,SEDIT/N/E
```

Run with: `SUBMIT BUILD`

> **Note:** The L80 command line above is 74 characters wide — the exact
> maximum enforced by SEDIT itself. If it needs to grow, split it across
> two L80 invocations using an intermediate `.REL` library step.

---

## 12. Startup Sequence

1. Set own stack pointer to `SEDIT_STACK`
2. Save original SP for clean exit
3. Read `0002H` for current drive; read `0004H` to locate BDOS entry; compute TPA top
4. Compute available RAM; allocate 2 gap buffers; if TPA < 18 KB, refuse to run
5. Zero all buffer descriptors; mark all buffers as empty (`[No Name]`)
6. Load and parse `SEDIT.KEY` (§5); fall back to defaults if not found
7. Send VT100 terminal identification request (`ESC Z`); poll for response
8. Initialize screen: clear, draw info bar, ruler, separator, status bar
9. If a filename was passed on command line (FCB at `005CH`), load into buffer 1
10. Draw initial edit area; position cursor at line 1, col 1
11. Enter main edit loop

---

## 13. Exit Sequence

1. For each buffer slot: if `MODIFIED`, prompt user (Y/N/A/Q)
2. Save as directed
3. Send `ESC [ 2 J ESC [ H` (clear screen, cursor home)
4. Restore original SP
5. `JMP 0000H` (warm boot to CP/M)

---

## 14. Error Handling

| Condition | Response |
|-----------|----------|
| Buffer full (text col 74 exceeded) | BEL (`07H`); `Line full (74 chars max)` in status bar |
| File load: line > 74 chars | Truncate; `Warning: long lines truncated` in status bar |
| Disk full on save | `Disk full — file not saved` in status bar; buffer stays modified |
| File not found on open | Open empty buffer with that name; `New file` in status bar |
| BDOS error (0FFH) | `Disk error` in status bar |
| No free buffer slot | `No free buffer slots (max 2)` in status bar |
| Not found (search) | `Not found` in status bar; cursor unchanged |
| TPA too small (< 18 KB) | Print `Insufficient memory` to console; exit immediately |
| SEDIT.KEY parse error | `Key file error: line n ignored` shown briefly at startup |

---

## 15. Coding Standards

### 15.1 File Naming and Size

- Root file: `SEDIT.MAC` (contains `START:` and build instructions)
- All other modules: `SE??????.MAC` — 8.3 CP/M format, `SE` prefix,
  six descriptive characters (e.g. `SEFILEIO.MAC`, `SESCREEN.MAC`)
- Shared equates: `SEDIT.INC` — INCLUDEd by every module
- **Maximum 900 lines per file** — split into additional `SE??????.MAC`
  files if a module grows beyond this limit
- **Maximum 20 KB per file** — ensures SEDIT can open and edit its own source
- Maximum source line length: **74 characters** — SEDIT enforces this limit
  on all files it edits, including its own source

### 15.2 File Version Header

Every `.MAC` and `.INC` file carries the standard header block defined in
§11.1. The `VERSION` and `DATE` fields must be updated whenever the file
is modified. Version numbering: `major.minor` — increment minor for bug
fixes and small additions; increment major for structural changes.

### 15.3 Assembly and Linking

- Assembled with M80 3.x; linked with L80
- Intel 8080 instruction set only (no Z80 extensions in v1.0)
- Every module declares `PUBLIC` for all entry points called by other modules
- Every module declares `EXTRN` for all symbols defined in other modules
- `SEDIT.INC` is the first `INCLUDE` in every module

### 15.4 Register Usage Convention

| Register | Role |
|----------|------|
| `HL` | Primary address or 16-bit return value |
| `DE` | Secondary address or parameter |
| `BC` | Count or secondary parameter |
| `A` | 8-bit return code or scratch |

Any register modified by a routine must be listed in its header comment.
Routines that need to preserve registers must PUSH/POP them explicitly.

### 15.5 Subroutine Header Comment

Every subroutine begins with this comment block immediately before its label:

```asm
;--------------------------------------------------------------
; ROUTINE_NAME - Short one-line description
; Entry:  HL = ...   DE = ...   A = ...
; Exit:   HL = ...   A = 0 ok, 0FFH error
;         BC, DE destroyed; all others preserved
; Calls:  PUTCHAR, BDOS
; Size:   ~nn bytes
;--------------------------------------------------------------
```

### 15.6 General Rules

- All numeric constants defined as `EQU` in `SEDIT.INC`; no magic numbers
  in code
- Local labels within a subroutine use the module's two-letter prefix
  followed by a digit or short word (e.g. `SC1:`, `SCLP:` in SESCREEN)
- No line may exceed 74 characters including the newline
- Comments must fit on the same line as the code they describe; long
  explanations go in the subroutine header block above

---

## 16. Limitations (v1.0)

- Maximum stored line length: 74 characters
- Maximum file size: ~15–19 KB per buffer in 2-buffer configuration
- Maximum line count: limited only by buffer size (not by 3-digit display; see §2.3.1)
- No undo
- No split-window view
- CP/M 8.3 filenames only; no subdirectories
- No binary file support (`NUL` bytes not handled)
- Single display page only (no virtual terminal resizing)

---

## 17. Stretch Goals (Post v1.0)

| Feature | Notes |
|---------|-------|
| Single-level undo | Snapshot last operation into undo buffer |
| Column ruler toggling | `^OT` to show/hide row 2 ruler |
| Configurable tab width | `SET TAB n` in `SEDIT.KEY` |
| Word wrap | Soft-wrap at col 74 during typing |
| Z80 instruction optimization | Post-assembly replacement pass for speed |
| Additional syntax modes | C source, plain text word count mode |
| Block write to file | Save marked block as a separate file |
| Macro record/play | Record keystrokes, replay with one key |
