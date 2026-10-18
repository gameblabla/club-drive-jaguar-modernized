
; Codes to write to Jaguar JOYSTICK register in order to read back
; a particular socket & row from the controller port.  These are 
; set up to do both PORT #1 and PORT #2 at the same time.

read_s0_row0	equ	$817e		; 4 controller socket 0, row 0
read_s0_row1	equ	$81bd		; 4 controller socket 0, row 1
read_s0_row2	equ	$81db		; 4 controller socket 0, row 2
read_s0_row3	equ	$81e7		; 4 controller socket 0, row 3

read_s1_row0	equ	$8100		; 4 controller socket 1, row 0
read_s1_row1	equ	$8181		; 4 controller socket 1, row 1
read_s1_row2	equ	$8142		; 4 controller socket 1, row 2
read_s1_row3	equ	$81c3		; 4 controller socket 1, row 3

read_s2_row0	equ	$81f4		; 4 controller socket 2, row 0
read_s2_row1	equ	$81f5		; 4 controller socket 2, row 1
read_s2_row2	equ	$81f6		; 4 controller socket 2, row 2
read_s2_row3	equ	$81f8		; 4 controller socket 2, row 3

read_s3_row0	equ	$81f9		; 4 controller socket 3, row 0
read_s3_row1	equ	$81fa		; 4 controller socket 3, row 1
read_s3_row2	equ	$81fc		; 4 controller socket 3, row 2
read_s3_row3	equ	$81ff		; 4 controller socket 3, row 3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Jaguar Controller Port #1

read_p1s0r0	equ	$81fe		; 4 controller socket 0, row 0
read_p1s0r1	equ	$81fd		; 4 controller socket 0, row 1
read_p1s0r2	equ	$81fb		; 4 controller socket 0, row 2
read_p1s0r3	equ	$81f7		; 4 controller socket 0, row 3

read_p1s1r0	equ	$81f0		; 4 controller socket 1, row 0
read_p1s1r1	equ	$81f1		; 4 controller socket 1, row 1
read_p1s1r2	equ	$81f2		; 4 controller socket 1, row 2
read_p1s1r3	equ	$81f3		; 4 controller socket 1, row 3

read_p1s2r0	equ	$81f4		; 4 controller socket 2, row 0
read_p1s2r1	equ	$81f5		; 4 controller socket 2, row 1
read_p1s2r2	equ	$81f6		; 4 controller socket 2, row 2
read_p1s2r3	equ	$81f8		; 4 controller socket 2, row 3

read_p1s3r0	equ	$81f9		; 4 controller socket 3, row 0
read_p1s3r1	equ	$81fa		; 4 controller socket 3, row 1
read_p1s3r2	equ	$81fc		; 4 controller socket 3, row 2
read_p1s3r3	equ	$81ff		; 4 controller socket 3, row 3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Jaguar Controller Port #2

read_p2s0r0	equ	$817f		; 4 controller socket 0, row 0
read_p2s0r1	equ	$81bf		; 4 controller socket 0, row 1
read_p2s0r2	equ	$81df		; 4 controller socket 0, row 2
read_p2s0r3	equ	$81ef		; 4 controller socket 0, row 3

read_p2s1r0	equ	$810f		; 4 controller socket 1, row 0
read_p2s1r1	equ	$818f		; 4 controller socket 1, row 1
read_p2s1r2	equ	$814f		; 4 controller socket 1, row 2
read_p2s1r3	equ	$81cf		; 4 controller socket 1, row 3

read_p2s2r0	equ	$814f		; 4 controller socket 2, row 0
read_p2s2r1	equ	$815f		; 4 controller socket 2, row 1
read_p2s2r2	equ	$816f		; 4 controller socket 2, row 2
read_p2s2r3	equ	$818f		; 4 controller socket 2, row 3

read_p2s3r0	equ	$819f		; 4 controller socket 3, row 0
read_p2s3r1	equ	$81af		; 4 controller socket 3, row 1
read_p2s3r2	equ	$81cf		; 4 controller socket 3, row 2
read_p2s3r3	equ	$81ff		; 4 controller socket 3, row 3



