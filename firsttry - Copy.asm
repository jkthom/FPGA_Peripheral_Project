;===============================================================
; Split-the-middle-switches math using ARITH_UNIT
; - Leftmost switch (bit15): down=START, up=hold
; - Rightmost switch (bit0): up=multiply, down=divide
; - Operands: upper7 = switches[14..8], lower7 = switches[7..1]
;===============================================================

            ORG   0

; ---- I/O addresses (edit these if your board uses different ones) ----
SWITCHES    EQU   &H080         ; <- set to your Switches IN address
; LEDS      EQU   &H081         ; (optional) LEDs OUT address

; ARITH_UNIT (from your VHDL)
AR_A        EQU   &H090         ; OPERAND_A (W)
AR_B        EQU   &H091         ; OPERAND_B (W)
AR_CTRL     EQU   &H092         ; CTRL/STATUS (R/W)
AR_RESLO    EQU   &H093         ; RES_LO (R)
AR_RESHI    EQU   &H094         ; RES_HI (R)

; ---- constants / masks ----
Bit15       DW    &H8000        ; test leftmost switch
Bit0        DW    &H0001        ; test rightmost switch
MaskLow7    DW    &H00FE        ; bits [7..1]
MaskHigh7   DW    &H7F00        ; bits [14..8]
One         DW    &H0001
DoneMask    DW    &H0080        ; STATUS bit7 = DONE

; ---- scratch / outputs ----
SW_VAL      DW    0
A_VAL       DW    0
B_VAL       DW    0
P_LO        DW    0
P_HI        DW    0

;===============================================================
; Main loop
;===============================================================
Main:
WaitStart:
    IN      SWITCHES           ; read switches
    STORE   SW_VAL
    LOAD    SW_VAL
    AND     Bit15              ; if leftmost is up (1) → keep waiting
    JNZ     WaitStart

; -------- build operands from middle switches --------
; A = lower7 = switches[7..1]  = (SW & 0x00FE) >> 1
    LOAD    SW_VAL
    AND     MaskLow7
    SHIFT   -1
    STORE   A_VAL
    OUT     AR_A               ; write OPERAND_A

; B = upper7 = switches[14..8] = (SW & 0x7F00) >> 8
    LOAD    SW_VAL
    AND     MaskHigh7
    SHIFT   -8
    STORE   B_VAL
    OUT     AR_B               ; write OPERAND_B

; -------- decide operation from rightmost switch --------
; ARITH CTRL expects bit0: 0=multiply, 1=divide
; Our rule: switch0 up(1)=multiply, down(0)=divide
; So CTRL.bit0 = NOT switch0  => (switch0 XOR 1)
    LOAD    SW_VAL
    AND     Bit0               ; AC = 0 or 1 (switch0)
    XOR     One                ; invert -> 1 if down (divide), 0 if up (multiply)
    AND     One                ; keep it to 0/1 clean
    OUT     AR_CTRL            ; write CTRL (triggers the op)

; -------- poll DONE (bit7) --------
Poll:
    IN      AR_CTRL
    AND     DoneMask
    JZ      Poll               ; wait until DONE==1

; -------- read result --------
    IN      AR_RESLO
    STORE   P_LO
    IN      AR_RESHI
    STORE   P_HI

; (optional) push low 16 bits to LEDs
;   LOAD    P_LO
;   OUT     LEDS

; loop forever
    JUMP    Main
