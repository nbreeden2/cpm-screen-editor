;============================================================
; FILE:    SEDIT.INC
; PROJECT: SEDIT - Screen Editor for CP/M 2.2
; VERSION: 1.0
; DATE:    1984-01-01
; AUTHOR:
;------------------------------------------------------------
; DESCRIPTION:
;   Shared equates for all SEDIT modules.
;   INCLUDE this as the first statement of every .MAC file.
;------------------------------------------------------------
; REVISION HISTORY:
;   1.0  1984-01-01  Initial release
;============================================================

;--- CP/M system addresses ----------------------------
BDOS    EQU     0005H       ; BDOS call entry
WBOOT   EQU     0000H       ; warm boot / exit
DFTFCB  EQU     005CH       ; default FCB (arg 1)
CMDTAIL EQU     0080H       ; command tail buffer

;--- BDOS function numbers ----------------------------
BF_CONIN  EQU   1           ; console input (wait)
BF_CONOUT EQU   2           ; console output: E=char
BF_RAWIO  EQU   6           ; direct I/O: E=FFH->in
BF_PRTSTR EQU   9           ; print $-string: DE=addr
BF_RDLINE EQU   10          ; buffered line input
BF_CONST  EQU   11          ; console status
BF_FOPEN  EQU   15          ; open file: DE=FCB
BF_FCLOSE EQU   16          ; close file: DE=FCB
BF_FDEL   EQU   19          ; delete: DE=FCB
BF_FREAD  EQU   20          ; seq read: DE=FCB
BF_FWRITE EQU   21          ; seq write: DE=FCB
BF_FMAKE  EQU   22          ; create: DE=FCB
BF_SETDMA EQU   26          ; set DMA: DE=addr
BF_USRNUM EQU   32          ; get/set user: E=num

;--- ASCII control codes ------------------------------
NUL     EQU     00H
BEL     EQU     07H         ; bell
BS      EQU     08H         ; backspace
TAB     EQU     09H         ; horizontal tab
LF      EQU     0AH         ; line feed
CR      EQU     0DH         ; carriage return
ESC     EQU     1BH         ; escape
DEL     EQU     7FH         ; delete character
CPMEOF  EQU     1AH         ; CP/M EOF marker (Ctrl-Z)
CTRLK   EQU     0BH         ; Ctrl-K (prefix key)
CTRLQ   EQU     11H         ; Ctrl-Q (prefix key)

;--- Screen layout ------------------------------------
SCRROWS EQU     24          ; terminal row count
SCRCOLS EQU     80          ; terminal column count
EDITROW EQU     20          ; edit rows (rows 3-22)
EDITFR  EQU     3           ; first edit row (1-based)
INFOROW EQU     1           ; info bar row
RULRROW EQU     2           ; tab ruler row
SEPRROW EQU     23          ; separator (===) row
STATROW EQU     24          ; status/message row
LNUMWID EQU     4           ; gutter width (3+space)
TXTCOLS EQU     74          ; max text columns/line
TXTFCOL EQU     5           ; text start col (1-based)
TABWID  EQU     4           ; tab stop interval

;--- SGR attribute byte values ------------------------
ATTR_NRM EQU    00H         ; normal
ATTR_BLD EQU    01H         ; bold
ATTR_DIM EQU    02H         ; dim
ATTR_REV EQU    07H         ; reverse video
ATTR_CYN EQU    36H         ; cyan foreground
ATTR_GRN EQU    32H         ; green foreground
ATTR_YEL EQU    33H         ; yellow foreground
ATTR_MAG EQU    35H         ; magenta foreground

;--- Buffer descriptor field offsets -----------------
BD_BSTAR EQU    0           ; 2: buffer base address
BD_BSIZE EQU    2           ; 2: capacity in bytes
BD_GAPBG EQU    4           ; 2: gap start offset
BD_GAPEN EQU    6           ; 2: gap end offset
BD_TXEND EQU    8           ; 2: text end offset
BD_TOPLN EQU    10          ; 2: top visible line
BD_CSROW EQU    12          ; 1: cursor screen row
BD_CSCOL EQU    13          ; 1: cursor text column
BD_CSOFF EQU    14          ; 2: cursor byte offset
BD_MRKBG EQU    16          ; 2: block mark start
BD_MRKEN EQU    18          ; 2: block mark end
BD_MODIF EQU    20          ; 1: modified flag
BD_SYNMD EQU    21          ; 1: syntax mode
BD_FNAME EQU    22          ; 12: drive+name+ext
BD_SIZE  EQU    34          ; bytes per descriptor

;--- Number of edit buffers ---------------------------
MAXBUFS EQU     2           ; maximum open buffers
MINMEM  EQU     18*1024     ; minimum TPA required

;--- Syntax mode codes --------------------------------
SYN_NONE EQU    0           ; plain text
SYN_ASM  EQU    1           ; 8080/Z80 assembly

;--- Insert / overwrite mode --------------------------
MODE_INS EQU    0           ; insert mode (default)
MODE_OVR EQU    1           ; overwrite mode

;--- Key type codes (B reg from GETKEY) ---------------
KT_NONE EQU     0           ; no key available
KT_ACT  EQU     1           ; C = action code
KT_CHAR EQU     2           ; C = printable char

;--- Key action codes (C reg when B=KT_ACT) ----------
ACT_CURUP EQU   1           ; cursor up
ACT_CURDN EQU   2           ; cursor down
ACT_CURLT EQU   3           ; cursor left
ACT_CURRT EQU   4           ; cursor right
ACT_WRDPV EQU   5           ; previous word
ACT_WRDNX EQU   6           ; next word
ACT_PGUP  EQU   7           ; page up
ACT_PGDN  EQU   8           ; page down
ACT_SCRUP EQU   9           ; scroll screen up
ACT_SCRDN EQU   10          ; scroll screen down
ACT_LINST EQU   11          ; jump to line start
ACT_LINEN EQU   12          ; jump to line end
ACT_FTOP  EQU   13          ; jump to file top
ACT_FEND  EQU   14          ; jump to file end
ACT_DELLF EQU   15          ; delete left (BS)
ACT_DELRT EQU   16          ; delete right (Del)
ACT_DELWD EQU   17          ; delete word right
ACT_DELLN EQU   18          ; delete entire line
ACT_INSTB EQU   19          ; insert tab
ACT_INSNL EQU   20          ; insert newline
ACT_TOGIN EQU   21          ; toggle insert/overwrite
ACT_LITNX EQU   22          ; next char is literal
ACT_FNDNX EQU   23          ; find next
ACT_FSAVE EQU   24          ; save file
ACT_FOPEN EQU   25          ; open file
ACT_FEXIT EQU   26          ; exit editor
ACT_BLKMK EQU   27          ; toggle block mark
ACT_BLKCP EQU   28          ; copy block
ACT_BLKDL EQU   29          ; delete block
ACT_BLKPS EQU   30          ; paste clipboard
ACT_MENU  EQU   31          ; open ESC menu
ACT_MAX   EQU   31          ; highest action code

;--- Block mark sentinel ------------------------------
NO_MARK EQU     0FFFFH      ; marks absent/unset

;--- FCB field offsets --------------------------------
FCB_DR  EQU     0           ; drive (0=default)
FCB_FN  EQU     1           ; filename (8 bytes)
FCB_FT  EQU     9           ; extension (3 bytes)
FCB_EX  EQU     12          ; extent number
FCB_S2  EQU     14          ; extent high
FCB_RC  EQU     15          ; record count
FCB_CR  EQU     32          ; current record
FCB_SIZ EQU     36          ; total FCB size

;--- DMA record size ----------------------------------
RECSIZ  EQU     128         ; 128 bytes per record

;--- Clipboard buffer size ----------------------------
CLIPMAX EQU     2048        ; max paste buffer bytes

;--- Search string size limit -------------------------
SRCHMAX EQU     64          ; max find string length
