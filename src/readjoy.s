
	.include	'jaguar.inc'
	.include	'joypad.inc'
	.include 	'controlr.inc'


	.extern	steeropt


	.text

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; To read a controller, you do the following steps:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 1) Write the code for ROW you want to read into the JOYSTICK register
;    (High byte should be $81 to indicate that you are WRITING J0-J7 and
;     want the AUDIO enabled.  The low byte contains codes for the subset of
;     controller data to be read: low nybble = Port 1, high nybble = Port 2.)
;
; 2) Read back the JOYSTICK and/or JOYBUTS registers to get the data,
;
; 3) Decode the data appropriately for the type of controller.
;
; 4) Repeat steps 1-3 for each ROW you need to read.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; We're supposed to write our analog-input request, then wait 50us before
; reading result.  With a 13mhz clock on the 68000, there are 13 cycles per
; 1us, so that's about 650 cycles total.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Input:  Expects JOYSTICK write code in d1
; Output: JOYSTICK value in d1, JOYBUTS in d2

readstick:
	move.w	d1,JOYSTICK	; Write request, then wait about 600 cycles
	move.l	d7,-(sp)
	move.l	.delaycount,d7
.dloop:
	sub.l	#1,d7		; 3-4 cycles?
	bne.b	.dloop		; 1-2 cycles?	(maybe 4-6 cycles total?)
	move.l	(sp)+,d7
	move.w	JOYSTICK,d1
	move.w	JOYBUTS,d2
	rts

.delaycount:
	dc.l	100		; That should be 400-600 cycles (close enough)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Read controller type, merge the codes for sockets 0-3 into a
; single word value.

setsteeropt::
	clr	steeropt
	lea	socket_1,a0		; 4-controller adapter, socket 1
	bsr	read_controller_type
	cmpi.w	#4,d0		;special code for steering wheel-analog joy
	bne.b	.10
		move		#1,steeropt
	.10:
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_controller_type:
	lea	buttons,a1		; store results here
	moveq	#3,d0			; doing the loop 4 times
.0:
	move.w	(a0)+,d1		; Get the socket/row code
	bsr.b	readstick		; read it (results in d1 & d2)
	move.w	d2,(a1)+		; save the results for later
	dbra	d0,.0			; and loop

; If the last read was for a different port/socket, then some analog devices
; may need to resync themselves before they will output correct data (which
; includes the controller type code).  This is true of the Thrustmaster
; Formula 1 driving controller, for example.  Therefore, read the controller
; code again just to be safe.
.playitagainsam:
	sub.l	#8,a0			; Back up to start of port/socket codes
	lea	buttons,a1		; Store results here
	lea	sticks,a2		; Store results here
	moveq	#3,d0			; doing the loop 4 times
.1:
	move.w	(a0)+,d1		; Get the socket/row code
	bsr.b	readstick		; read it (results in d1 & d2)
	move.w	d2,(a1)+		; save the results for later
	move.w	d1,(a2)+		; save the results for later
	dbra	d0,.1			; and loop


.get_controller_code:
	lea	buttons,a1		; read the values from here
	moveq	#3,d2			; doing the loop 4 times
	clr.l	d0			; start out fresh
.2:
        move.w	(a1)+,d1		; Get a result
	andi.l	#$00000001,d1		; mask off all but b0
	rol	#1,d0			; make room and
	or.l	d1,d0			; Then combine bit 0 of d1 with d0.
	dbra	d2,.2			; decrement counter and loop
	move.w	d0,d1
	andi.w	#$0007,d0		; mask out bank code.
	cmpi.w	#4,d0		;steering
	bne	.50
		;this is an analog device
		btst		#3,d1		;check bank
		bne.b		.playitagainsam

		;center stick data
		lea	sticks,a1		; read the values from here
		lea	anacenterx,a2
		moveq	#1,d3
.40:		move.w	(a1)+,d2		; Get a result
		andi.w	#$0f00,d2		; mask off all but b0
		ror.w	#4,d2			; make room and
		move.w	(a1)+,d1		; Get a result
		andi.w	#$0f00,d1		; mask off all but b0
		or.w		d1,d2
		ror.w	#4,d2
		move.w	d2,(a2)+
		dbra		d3,.40			; decrement counter and loop

		;set some defaults
		move		#-$38,anaminx
		move		#$38,anamaxx
		move		#585,anascllx
		move		#585,anasclrx
	.50:	
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
socket_1:
	dc.w	read_p1s1r0,read_p1s1r1,read_p1s1r2,read_p1s1r3
	; Retail object boundary retains three NOP padding words.
	nop
	nop
	nop
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.bss
buttons::
	ds.w	16		; This is a bit more space than we need...
sticks::
	ds.w	16
anacenterx::
	ds.w	2
anaminx::
	ds.w	2
anamaxx::
	ds.w	2
anascllx::
	ds.w	2
anasclrx::
	ds.w	2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.end


