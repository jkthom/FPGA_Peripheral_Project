; ===========================
; SCOMP "Switch Match" Game
; ===========================
; I/O address labels
Switches  EQU &H000       ; IN  (10-bit switches)
LEDs      EQU &H001       ; OUT (LEDs mirror switches)
Timer     EQU &H002       ; IN/OUT (10 Hz: read ticks, write to reset)
Hex0      EQU &H004       ; OUT (right, 4 digits: show target)
Hex1      EQU &H005       ; OUT (left,  2 digits: show score)

; ---------------------------
; Program
; ---------------------------
            ORG   0

; --- Initialize: score = 0, random = nonzero seed ---
            LOAD  Zero
            STORE Score
            OUT   Hex1            ; show 0 on score display

; ===========================
; Main game loop
; ===========================
WaitForAllDown:
            ; Mirror switches to LEDs at all times
            IN    Switches
            OUT   LEDs
            STORE Sw

            ; Keep updating score display
            LOAD  Score
            AND   ScoreMask8
            OUT   Hex1

            ; Are all switches down?
            LOAD  Sw
            JNZ   WaitForAllDown   ; Not zero = still waiting for all down

; All switches just went down - generate random while they stay down
SpinRandomWhileDown:
            ; Call LFSR to generate random number
            LOAD  Random
            STORE value
            CALL  SubRoutine
            AND   TenBitMask       ; Keep low 10 bits
            STORE Random

            ; Keep UI responsive
            IN    Switches
            OUT   LEDs
            STORE Sw
            LOAD  Score
            AND   ScoreMask8
            OUT   Hex1

            ; Check if switches are still down
            LOAD  Sw
            JPOS  SpinRandomWhileDown  ; If any switch up, keep spinning

; All switches became down (or stayed down) - START THE ROUND
BeginRound:
            ; Show target number on right display
            LOAD  Random
            OUT   Hex0

            ; Reset and start timer
            LOAD  One
            OUT   Timer

; Wait for match OR timeout (>= 50 ticks = 5 seconds)
RoundLoop:
            ; Keep mirroring switches to LEDs
            IN    Switches
            OUT   LEDs
            STORE Sw

            ; Compare (switches masked to 10 bits) vs Random
            LOAD  Sw
            AND   TenBitMask
            SUB   Random
            JZERO PlayerWon        ; exact match - they won!

            ; No match yet - check for timeout
            IN    Timer
            SUB   Fifty            ; Check if >= 50 ticks (5 seconds)
            JNEG  RoundLoop        ; < 50 ticks - keep waiting

; Timeout reached - no point, start new round immediately
TimeoutNoPoint:
            ; Generate new random and restart
            LOAD  Random
            STORE value
            CALL  SubRoutine
            AND   TenBitMask
            STORE Random
            
            ; Show new target
            LOAD  Random
            OUT   Hex0
            
            ; Reset timer
            LOAD  One
            OUT   Timer
            
            JUMP  RoundLoop

; Player matched the number within 5 seconds - award point
PlayerWon:
            LOAD  Score
            ADDI  1
            STORE Score
            AND   ScoreMask8
            OUT   Hex1

            ; Generate new random and restart immediately
            LOAD  Random
            STORE value
            CALL  SubRoutine
            AND   TenBitMask
            STORE Random
            
            ; Show new target
            LOAD  Random
            OUT   Hex0
            
            ; Reset timer
            LOAD  One
            OUT   Timer
            
            JUMP  RoundLoop

; ===========================
; LFSR Subroutine
; Shifts value left and sets bit 0 as XOR of bits 5 and 9
; ===========================
SubRoutine:
            LOAD  value
            SHIFT 1
            STORE shifted

            LOAD  shifted
            STORE tmpval5
            LOAD  shifted
            STORE tmpval9

            CALL  ExtractBit5
            CALL  ExtractBit9

            LOAD  tmpval5
            XOR   tmpval9
            STORE xresult

            LOAD  shifted
            AND   maskto             ; Clear bit 0
            OR    xresult            ; Set bit 0 to XOR result
            STORE value              ; Save result and leave in AC
            LOAD  value
            RETURN

ExtractBit5:
            LOAD  tmpval5
            SHIFT -5
            AND   mask
            STORE tmpval5
            RETURN

ExtractBit9:
            LOAD  tmpval9
            SHIFT -9
            AND   mask
            STORE tmpval9
            RETURN

; ===========================
; Data & Constants
; ===========================
Score:      DW    0
Random:     DW    &H5A5A       ; Initial non-zero seed
Sw:         DW    0

; Subroutine variables
value:      DW    0
shifted:    DW    0
tmpval5:    DW    0
tmpval9:    DW    0
xresult:    DW    0

; Masks and constants
TenBitMask: DW    &H03FF       ; Keep low 10 bits
ScoreMask8: DW    &H00FF       ; Show low 8 bits on Hex1
maskto:     DW    &HFFFE       ; Clear bit 0
mask:       DW    &H0001       ; Isolate bit 0
Zero:       DW    0
One:        DW    1
Fifty:      DW    100

