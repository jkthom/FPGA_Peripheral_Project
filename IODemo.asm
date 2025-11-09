; IODemo.asm
; Produces a "bouncing" animation on the LEDs.
; The LED pattern is initialized with the switch state.
; Modified to ensure at most 2 switches are raised initially.
ORG 0
	; Get and store the switch values
CheckSwitches:
	IN     Switches
	STORE  Pattern
	; Count the number of raised switches
	LOAD   Zero
	STORE  Count
	LOAD   Pattern
	STORE  TempPattern
	
CountLoop:
	LOAD   TempPattern
	JZERO  DoneCounting    ; If pattern is 0, we're done counting
	AND    Bit0            ; Check if rightmost bit is 1
	JZERO  NoIncrement
	LOAD   Count
	ADDI   1
	STORE  Count
NoIncrement:
	LOAD   TempPattern
	SHIFT  -1              ; Shift right to check next bit
	STORE  TempPattern
	JUMP   CountLoop
	
DoneCounting:
	; Check if count > 2
	LOAD   Count
	ADDI   -3              ; Subtract 3 (count - 3)
	JNEG   ValidInput      ; If negative, count <= 2, so valid
	; Too many switches raised, display pattern and wait
	LOAD   Pattern
	OUT    LEDs
	CALL   Delay
	JUMP   CheckSwitches   ; Check again
	
ValidInput:
	; Valid input: display and continue
	LOAD   Pattern
	OUT    LEDs
	
Left:
	; Slow down the loop so humans can watch it.
	CALL   Delay
	; Check if the left place is 1 and if so, switch direction
	LOAD   Pattern
	AND    Bit9         ; bit mask
	JNZ    Right        ; bit9 is 1; go right
	
	LOAD   Pattern
	SHIFT  1
	STORE  Pattern
	OUT    LEDs
	JUMP   Left
	
Right:
	; Slow down the loop so humans can watch it.
	CALL   Delay
	; Check if the right place is 1 and if so, switch direction
	LOAD   Pattern
	AND    Bit0         ; bit mask
	JNZ    Left         ; bit0 is 1; go left
	
	LOAD   Pattern
	SHIFT  -1
	STORE  Pattern
	OUT    LEDs
	
	JUMP   Right
	
; To make things happen on a human timescale, the timer is
; used to delay for half a second.
Delay:
	OUT    Timer
WaitingLoop:
	IN     Timer
	ADDI   -5
	JNEG   WaitingLoop
	RETURN
	
; Variables
Pattern:     DW 0
Count:       DW 0
TempPattern: DW 0
Zero:        DW 0
; Useful values
Bit0:      DW &B0000000001
Bit9:      DW &B1000000000
; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
