# Fix Bug

Debug and fix the reported bug in SEDIT. The user will describe the symptom.

## Workflow

1. **Identify the code path.** Using the architecture in CLAUDE.md, determine which module(s) and routine(s) are involved. Do NOT grep broadly — go directly to the relevant file and routine.

2. **Read the relevant code.** Read only the specific routines involved. Trace the execution path from the trigger (key press, menu action, etc.) through to the screen output.

3. **Find the root cause.** Look for these common SEDIT failure modes:
   - **Register clobber**: BDOS calls (via OUTSTR, CURGOTO, OUTCHAR, CALL BDOS) destroy ALL registers. Any value held in a register across such a call is lost.
   - **Off-by-one in scans**: Backward LF scan of L LFs moves L-1 lines (because INX H after the final LF). Forward scan of L LFs moves L lines.
   - **Missing redraw**: SCRDRAW draws rows 3-22 + ruler (2) + separator (23) + clears status (24). INFOBAR draws row 1. SCREDCL draws one edit line only. Overlays (menu, help) clear the full screen — caller must set DIRTY=1 after return.
   - **DSEG variable placement**: In M80, define DSEG variables near the top of the DSEG section, before large data tables. Labels defined after large DW blocks may not resolve.
   - **Flag not set/cleared**: Check DIRTY, DRTLINE, BD_MODIF. Cursor-only moves set neither flag. Character edits set DRTLINE. Line-merging ops (delete LF, Enter) set DIRTY.

4. **Trace boundary values.** Before writing any fix involving index arithmetic, cursor positions, or scan counts, write out the concrete values at:
   - First element (position 0, line 1, top of file)
   - Last element (max position, last line, end of file)
   - Page/screen boundaries (EDITROW transitions)

5. **Apply the fix.** Make the minimal edit. Prefer memory variables over registers for values that survive BDOS calls.

6. **Run CPMFMT.PY** on every modified .MAC file.

7. **Summarize** the root cause, the fix, and which boundary conditions were verified.

$ARGUMENTS
