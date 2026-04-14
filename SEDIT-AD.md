# SEDIT v1.24

## THE SCREEN EDITOR FOR CP/M

---

**TIRED OF LINE EDITORS?**
**TIRED OF COUNTING LINE NUMBERS?**
**TIRED OF TYPING "L" JUST TO SEE YOUR OWN CODE?**

Now there's **SEDIT** — the full-screen editor that turns your VT100 terminal into a real programming workstation.

```
 A:MAIN    .MAC   Lines: 342  Row:  17  Col:  12  [INS]
 ····:···:···:···:···:···:···:···:···:···:···:···:···:···:···:·
   1 ;========================================
   2 ; SEDIT - Screen Editor for CP/M 2.2
   3 ;========================================
   4         INCLUDE SEDIT.INC
   5
   6 START:  LXI     SP,STKTOP
   7         CALL    SCRINIT
   8         CALL    GBINIT
                         . . .
 ═══════════════════════════════ V1.24 ═════════════════════════
 File loaded.
```

---

## FEATURES THAT PUT YOU IN CONTROL

| Feature | Description |
|---------|-------------|
| **FULL-SCREEN EDITING** with line numbers | See your entire file — not just one line at a time. What you see is what you've got. |
| **WORDSTAR-COMPATIBLE** control keys | Already know WordStar? You already know SEDIT. `^E` `^X` `^S` `^D` and all the rest — they're all here. |
| **BUILT-IN FIND & REPLACE** with highlighting | Interactive search with Y/N/A per match. No more blind substitutions. |
| **SYNTAX HIGHLIGHTING**\* for ASM and C | Assembly AND C language coloring on color terminals. Keywords, strings, comments — all in living color. |
| **VIRTUAL BUFFER MODE** for large files | Edit files LARGER than your TPA. Automatic disk-backed paging. |
| **BLOCK OPERATIONS** | Mark, copy, delete, and paste. Just like the big boys. |
| **AUTO-DETECT TERMINAL** size at startup | 80 or 132 columns? 24 or 30 rows? SEDIT figures it out for you. |
| **CP/M USER AREA SUPPORT** built right in *(NEW)* | Access files across all 16 user areas. `SEDIT B3:MYFILE.MAC` — done. |
| **RUNS ON ANY 8080** or compatible CPU | No Z80 required! Works on 8080, 8085, Z80, and NSC800 systems. |
| **CONFIGURABLE KEY BINDINGS** | Load your own key map from disk. Make SEDIT work YOUR way. |

\* *Color features require VT100/ANSI color-capable terminal.*

---

## FOUR EDITIONS TO MATCH YOUR SYSTEM

| Edition | Description |
|---------|-------------|
| `SEDIT.COM` | Monochrome |
| `SEDIT-CL.COM` | Color |
| `SEDIT-A.COM` | ASM Highlighting |
| `SEDIT-C.COM` | C Highlighting |

---

## SYSTEM REQUIREMENTS

- CP/M 2.2 or compatible
- Intel 8080 or compatible CPU
- VT100/ANSI terminal
- 9 KB free TPA (minimum)
- One disk drive

## AVAILABLE NOW

Complete 8080 assembly source included — no secrets, no blobs.

Written in 13,500 lines of hand-crafted 8080 assembly.

---

> ### STOP EDITING THE HARD WAY.
> ### PUT A SCREEN EDITOR ON YOUR CP/M SYSTEM.
>
> ### *SEDIT — BECAUSE LIFE IS TOO SHORT FOR ED.*

**RetroTechReboot** · [github.com/nbreeden2/cpm-screen-editor](https://github.com/nbreeden2/cpm-screen-editor)
