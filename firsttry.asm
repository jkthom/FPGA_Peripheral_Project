
; ================== I/O addresses ==================
Switches  EQU 000
Key1      EQU &H096      ; <-- change if your KEY1 peripheral uses a different address
Hex0      EQU 004
Hex1      EQU 005

; ARITH_UNIT register map
OP_A      EQU &H090
OP_B      EQU &H091
CTRL      EQU &H092      ; write bit0: 0=multiply, 1=divide
RES_LO    EQU &H093
RES_HI    EQU &H094

; ================== Code ===========================
ORG 0

Main:
    ; ----- Latch A -----
    CALL  WaitAllDown
    CALL  WaitKey1Press
    CALL  WaitKey1Release
    IN    Switches
    AND   Low10Mask
    OUT   OP_A

    ; ----- Latch B -----
    CALL  WaitAllDown
    CALL  WaitKey1Press
    CALL  WaitKey1Release
    IN    Switches
    AND   Low10Mask
    OUT   OP_B

    ; ----- Start multiply (write 0 to CTRL) -----
    LOADI 0
    OUT   CTRL

PollDone:
    IN    CTRL
    AND   DoneMask        ; test DONE bit (bit7)
    JZERO PollDone

    ; ----- Read result and show on HEX -----
    IN    RES_LO
    OUT   Hex0
    IN    RES_HI
    OUT   Hex1

    JUMP  Main            ; repeat forever

; ----------------- Subroutines ---------------------

; Wait until all 10 lower switch bits are 0
WaitAllDown:
    IN    Switches
    AND   Low10Mask
    JNZ   WaitAllDown
    RETURN

; KEY1 is active-low via KEY1_PERIPH: bit0=1 (released), 0 (pressed)
WaitKey1Press:
    IN    Key1
    AND   Key1Mask
    JNZ   WaitKey1Press   ; keep waiting while not pressed (bit=1)
    RETURN

WaitKey1Release:
    IN    Key1
    AND   Key1Mask
    JZERO WaitKey1Release ; keep waiting while pressed (bit=0)
    RETURN

; ================== Data / Masks ===================
ORG &H0300
Low10Mask: DW &H03FF      ; mask to keep SW[9:0]
DoneMask:  DW &H0080      ; CTRL bit7 = DONE
Key1Mask:  DW &H0001      ; KEY1 bit0
