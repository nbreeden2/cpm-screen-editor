# SEDIT User Manual

**SEDIT v1.26 — Screen Editor for CP/M 2.2**

A full-screen text editor for CP/M 2.2 systems with VT100/ANSI, VT52, ADM-31, or Cromemco 3102 terminals.
Uses WordStar-compatible control key conventions with ANSI arrow key support.

---

## Getting Started

### System Requirements

- CP/M 2.2 or compatible operating system
- VT100/ANSI compatible terminal (80 or 132 columns, 24-30+ rows, auto-detected)
- Also available: VT52, ADM-31, and Cromemco 3102 terminal variants (80x24 fixed)
- Minimum 9 KB free memory beyond the editor binary for the edit buffer

### Starting SEDIT

From the CP/M command prompt:

    A>SEDIT                    (start with empty buffer)
    A>SEDIT MYFILE.TXT         (open a file directly)
    A>SEDIT C:MYFILE.TXT       (open on drive C:)
    A>SEDIT B3:MYFILE.TXT      (open on drive B:, user area 3)
    A>SEDIT 11:MYFILE.TXT      (current drive, user area 11)
    A>SEDIT MYFILE.TXT F:      (virtual temp files on F:)

### Screen Layout

```
Row  1: Info bar — filename, line count, cursor position, INS/OVR mode
Row  2: Tab ruler — tick marks every 4 columns
Rows 3..N-2: Edit area — text with line numbers (rows scale with terminal height)
Row N-1: Separator bar
Row  N: Status / message line
```

The info bar (row 1) shows:

| Field | Description |
|-------|-------------|
| Drive + filename | Current file (e.g. `A:MYFILE.TXT` or `B3:MYFILE.TXT`) |
| Lines | Total line count in buffer |
| Row / Col | Cursor position (1-based) |
| INS or OVR | Current editing mode |
| Free / Virtual | Free buffer space or virtual mode line range |

---

## Editing Modes

**Insert mode** (default) — typed characters are inserted before the cursor,
pushing existing text to the right.

**Overwrite mode** — typed characters replace the character at the cursor.
At end of line or end of file, characters are inserted normally.

Toggle between modes with **Ctrl-V**. The current mode is shown in the info bar
as `[INS]` or `[OVR]`.

---

## Key Reference

SEDIT uses WordStar-style control keys. Most editing functions have both a
control key shortcut and (where applicable) a standard terminal key equivalent.

### Cursor Movement

| Key | Alternative | Action |
|-----|-------------|--------|
| ^E | Up arrow | Move cursor up one line (sticky column) |
| ^X | Down arrow | Move cursor down one line (sticky column) |
| ^S | Left arrow | Move cursor left one character |
| ^D | Right arrow | Move cursor right one character |
| ^A | | Move to previous word |
| ^F | | Move to next word |
| ^R | PgUp | Page up (scroll up 20 lines) |
| ^C | PgDn | Page down (scroll down 20 lines) |
| ^W | | Scroll screen up one line |
| ^Z | | Scroll screen down one line |

### Line and File Navigation

| Key | Alternative | Action |
|-----|-------------|--------|
| ^QS | Home | Jump to start of current line |
| ^QD | End | Jump to end of current line |
| ^QR | | Jump to top of file |
| ^QC | | Jump to end of file |

### Inserting Text

| Key | Action |
|-----|--------|
| ^M / Enter | Insert new line with auto-indent |
| ^I / Tab | Insert tab character (displayed as spaces to next 4-column stop) |
| ^V | Toggle insert / overwrite mode |

### Deleting Text

| Key | Alternative | Action |
|-----|-------------|--------|
| ^H | Backspace | Delete character to the left |
| ^G | Del | Delete character to the right |
| ^T | | Delete word to the right |
| ^Y | | Delete entire current line |

### Block Operations

Block operations use the **Ctrl-K** prefix. Press Ctrl-K first, then the
second key.

| Key | Alternative | Action |
|-----|-------------|--------|
| ^KB | F3 | Toggle block mark (start → end → clear) |
| ^KC | | Copy marked block to clipboard |
| ^KD | | Delete marked block |
| ^KP | | Paste clipboard at cursor |

**How block marking works:**

1. Position the cursor at the start of the text you want to select.
2. Press **^KB** — status shows "Mark start."
3. Move the cursor to the end of the selection. The selected region is shown
   in reverse video as you move.
4. Press **^KB** again — status shows "Mark end."
5. Use **^KC** (copy), **^KD** (delete), or both.
6. Press **^KB** a third time to clear the marks ("Mark clear.").

The clipboard holds up to 2048 bytes. Use **^KP** to paste the clipboard
contents at the current cursor position.

### File Operations

| Key | Alternative | Action |
|-----|-------------|--------|
| ^KS | F2 | Save file |
| ^KX | | Save (if modified) and exit to CP/M |
| ^KQ | | Save (if modified) and exit to CP/M |

When saving, SEDIT automatically creates a `.BAK` backup of the previous
version of the file.

If the file has no name (new buffer), you will be prompted to enter a filename.

On exit (^KX or ^KQ), if the buffer has been modified you will see:

    Save changes? (Y/N/Esc)

- **Y** — Save and exit (prompts for filename if unnamed)
- **N** — Discard changes and exit
- **Esc** — Cancel, return to editing

### Search

| Key | Alternative | Action |
|-----|-------------|--------|
| ^QF | | Find — prompts for search string |
| ^QA | | Find and replace — interactive (Y/N/A/Esc per match) |
| ^L | F1 | Find next — repeat last search |
| ^Q[ | ^Q] | Jump to matching `{`/`}` or `(`/`)` |

Search is **case-insensitive** by default. The search starts from the current
cursor position and moves forward. If the end of file is reached without a
match, the search wraps around from the top.

Find and replace (`^QA`) prompts for a search string, then a replacement
string. Each match is highlighted in reverse video. Press **Y** to replace,
**N** to skip, **A** to replace all remaining, or **Esc** to stop.

Maximum search string length: 64 characters.

### Menu and Help

| Key | Alternative | Action |
|-----|-------------|--------|
| ESC | F4 | Open command menu |

---

## The ESC Menu

Press **ESC** or **F4** to open the command menu. Navigate with:

- **Up/Down arrows** (or ^E/^X, or K/J) to highlight an option
- **1-9** to jump directly to an option by number
- **Enter** to select the highlighted option
- **ESC** or **Q** to cancel and return to editing

### Menu Options

| # | Option | Description |
|---|--------|-------------|
| 1 | Open File | Load a file into the buffer |
| 2 | Save File | Save the buffer to disk |
| 3 | Save As... | Save with a new filename |
| 4 | Find text... | Search for text from cursor position |
| 5 | Go To Line... | Jump to a specific line number |
| 6 | Help | Display key reference overlay |
| 7 | About | Show version information |
| 8 | Toggle 80/132 col | Switch between 80 and 132 column modes |
| 9 | Exit | Exit the editor (with save prompt if modified) |

---

## File Format

- Files are stored on disk in standard CP/M text format: CR+LF line endings
  with a Ctrl-Z (1AH) EOF marker.
- Internally, SEDIT uses LF-only line endings for efficiency.
- Tab characters are preserved in the file and displayed as spaces to the
  next 4-column tab stop.

---

## Filename Format

CP/M filenames follow the 8.3 convention:

    [d:]filename[.ext]

- **d:** — Optional drive letter (A:, B:, C:, etc.)
- **filename** — Up to 8 characters
- **.ext** — Optional extension, up to 3 characters

Examples: `MYFILE.TXT`, `B:PROGRAM.MAC`, `README`

Filenames are automatically converted to uppercase.

---

## Custom Key Bindings

SEDIT can load custom key bindings from a file named **SEDIT.KEY** in the
current directory. If this file is not present, the built-in defaults
(listed above) are used.

The file format is plain text with one binding per line. Lines starting with
`;` are comments.

### Binding Format

```
; This is a comment
CTRL <n> <action>       Bind Ctrl-<n> to an action (n = 0-31)
CSI  <byte> <param> <action>  Bind CSI escape sequence
SS3  <byte> <action>    Bind SS3 escape sequence
CTK  <char> <action>    Bind Ctrl-K + <char> to an action
CTQ  <char> <action>    Bind Ctrl-Q + <char> to an action
```

### Action Names

```
CURUP   CURDN   CURLT   CURRT   WRDPV   WRDNX
PGUP    PGDN    SCRUP   SCRDN   LINST   LINEN
FTOP    FEND    DELLF   DELRT   DELWD   DELLN
INSTB   INSNL   TOGIN   LITNX   FNDNX   FSAVE
FOPEN   FEXIT   BLKMK   BLKCP   BLKDL   BLKPS
MENU    FIND    REPL    JMPM
```

### Example SEDIT.KEY

```
; Custom key bindings
CTRL 5 CURUP       ; Ctrl-E = cursor up
CTRL 24 CURDN      ; Ctrl-X = cursor down
CTK S FSAVE        ; Ctrl-K S = save file
CTQ F MENU         ; Ctrl-Q F = open menu instead of find
```

---

## Limits

| Item | Limit |
|------|-------|
| Edit buffers | 1 (single buffer) |
| Clipboard size | 2,048 bytes |
| Search string | 64 characters |
| Max line length | 255 characters (MAXCOLS) |
| Visible line numbers | Up to 9999 (4-digit gutter) |
| Text columns per line | 73 (80 minus 5-column gutter and margins) |
| Tab stops | Every 4 columns |
| Minimum TPA | 9 KB |
| File size | Unlimited (virtual buffer mode for files larger than TPA) |

---

## Status Messages

During operation, SEDIT displays brief messages on row 24:

| Message | Meaning |
|---------|---------|
| Mark start. | Block mark beginning set |
| Mark end. | Block mark ending set |
| Mark clear. | Block marks cleared |
| Block copied | Block copied to clipboard |
| Block del. | Block deleted |
| Pasted. | Clipboard pasted at cursor |
| Clip empty. | Paste attempted with empty clipboard |
| No block. | Copy/delete attempted without complete block mark |
| Found. | Search match located |
| Not found. | Search string not found in file |
| Saving file, please wait... | File save in progress |
| File saved. | File saved successfully |
| File loaded. | File loaded successfully |
| Write error! | Disk error during save |
| Save changes? (Y/N/Esc) | Prompted on exit with unsaved changes |

---

## Quick Reference Card

```
 CURSOR MOVEMENT          EDITING              BLOCK / FILE
 ^E  Up         ^QS Home  ^H  Backspace        ^KB  Mark start/end
 ^X  Down       ^QD End   ^G  Delete right      ^KC  Copy block
 ^S  Left       ^QR Top   ^T  Delete word       ^KD  Delete block
 ^D  Right      ^QC End   ^Y  Delete line       ^KP  Paste
 ^A  Word left             ^V  Ins/Ovr toggle    ^KS  Save (F2)
 ^F  Word right            ^I  Tab               ^KX  Exit
 ^R  Page up               ^M  New line (auto-   ^KQ  Quit
 ^C  Page down                  indent)          ^QF  Find
 ^W  Scroll up             ESC Menu (F4)         ^QA  Find/Replace
 ^Z  Scroll down           F3  Block mark        ^L   Find next (F1)
```
