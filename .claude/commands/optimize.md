# Optimize 8080 Assembly

Optimize the specified routine or code section in SEDIT for size and/or speed on the Intel 8080. The user will name the routine or describe what to optimize.

## Workflow

1. **Read the target code.** Go directly to the named routine. Understand what it does before changing anything.

2. **Identify optimization opportunities.** Look for these common 8080 patterns:

   ### Redundant loads/stores
   - Back-to-back `STA`/`LDA` to the same address
   - Re-reading a descriptor field that was just read (cache in a register or on the stack)
   - `MOV A,M` immediately after `MOV M,A` to the same address

   ### Cheaper equivalents
   - `MVI A,0` → `XRA A` (saves 1 byte, also clears carry)
   - `LXI H,0 / CALL GBSETxxx` when value is already in HL
   - `MOV A,L / ORA A` when H is known to be 0 → just `ORA L` if A is free
   - `CPI 0` → `ORA A` (saves 1 byte)
   - `MOV A,B / ORA C / JNZ` for BC != 0 check (standard pattern)
   - `DAD D` instead of `MOV A,L / ADD E / MOV L,A / MOV A,H / ADC D / MOV H,A` when carry flag side-effect is acceptable (saves 4 bytes)

   ### Loop optimizations
   - Counting down to zero with `DCR` + `JNZ` instead of `INR` + `CPI limit`
   - Moving invariant loads out of the loop body
   - Using `PUSH`/`POP` for saving a value across a single call vs `STA`/`LDA` (PUSH/POP = 2 bytes vs STA+LDA = 6 bytes, but PUSH/POP pairs must balance)

   ### Accessor call reduction
   - Multiple reads from the same descriptor: compute base pointer once, read fields at known offsets via `MOV r,M / INX H` chains
   - GBBASE, GBBSIZ return in DE and clobber A,HL. GBGAPEN, GBGAPBG etc. return in HL and clobber A only. Sequence calls to minimize re-reads.

   ### Control flow
   - Tail calls: `CALL sub / RET` → `JMP sub` (saves 1 byte + return overhead)
   - Common exit paths: multiple branches that do the same cleanup → single shared exit label
   - Fall-through instead of JMP when code can be reordered

   ### Register allocation
   - Use B,C for values that survive accessor calls (accessors preserve B,C)
   - Use D,E for values only needed before the next accessor call
   - On 8080 there is no XCHG BC,HL — to move HL to BC use `MOV B,H / MOV C,L`

3. **Verify correctness.** For each change:
   - Confirm register liveness: which registers are live at each point?
   - Confirm flag side-effects: does the optimization change carry/zero flags at a point where they matter?
   - Confirm stack balance: every PUSH has a matching POP on all code paths
   - Confirm no 8080/Z80 confusion: no Z80-only instructions (JR, DJNZ, EX, IX/IY, etc.)

4. **Apply the changes.** Edit the file(s). Prefer incremental, testable changes over wholesale rewrites.

5. **Run CPMFMT.PY** on every modified .MAC file.

6. **Summarize** what was changed, bytes/cycles saved where estimable, and any trade-offs made.

## Constraints

- **Intel 8080 ONLY** — no Z80 instructions
- **M80/L80 toolchain** — respect PUBLIC/EXTRN boundaries
- **Never change the external interface** of a PUBLIC routine (entry registers, exit registers, side effects) unless the user explicitly requests it
- **Correctness over speed** — do not introduce bugs for marginal gains

$ARGUMENTS
