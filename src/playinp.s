;================================================================================================
;
;  PLAYINP.S    - created 12/14/92  JS
;			 stripped and used by TP a little later
;
;  7/30/93 JS - modified the code such that...
;
;
;
;
;
;
;================================================================================================
;
;  This file contains functions which evaluate 'controller' input and performs
;  independent code for each individual button found on the 'controller'.
;
;     do_joypad:      - handle joypad input (UP,DOWN,LEFT,RIGHT)
;     do_firebuttons: - handle fire button input (A,B,C,OPTION,PAUSE)
;     do_keypad:      - handle keypad input (1,2,3,4,5,6,7,8,9,*,0,#)
;
;================================================================================================

	.include	'eq.s'
	.include	'externs.s'

	.include	"3dds.inc"
	.include	"controlr.inc"

FIRE_ABC	EQU	((1<<FIRE_A)|(1<<FIRE_B)|(1<<FIRE_C))
ANALOGJOY	equ	$F17c00
DEBUGKEYS	equ	1			; set to 0 to remove debugging keys

;================================================================================================
	.globl	do_joypad

	.extern	mkMatrix,pinput
	.extern	_free_bnd
	.extern	adj_skid, anajoy1
	.extern	joyeacc,joyehold,joyesem,joyeacc2,joyehol2,joyesem2,stufqueue
	.extern	speedvar
	.extern	anacenterx,anaminx,anamaxx,anascllx,anasclrx

;================================================================================================
;.data
.bss
joyph:	ds.w	1

.text

doalot:
;	movem.l	d3-d4,-(sp)

; >2600 cycles!!!!!!!!!
;	move.l	#100,d5		;12
;.dloop:
;	sub.l	#1,d5		; 3-4 cycles? 16
;	bne	.dloop		; 1-2 cycles?	(maybe 4-6 cycles total?) 10/8

	moveq	#5,d5	;number of divides >650 cycles
	moveq	#1,d3
.dloop:
	divs		d3,d4	;142-158
	subq.w	#1,d5	;4
	bne.b	.dloop	;10
;	movem.l	(sp)+,d3-d4
	rts

push_joypad::
	clr.l	d7		; CAR_STEER
	move.l	d7, d6	; CAR_GAS
	cmpi.l	#PLAYER1,chkPlayer	;only read the ports with player1's check
	bne		.notar
	tst.w	steeropt
	beq		.notar
		move.l	#$f0fffffc,d1		; d1 = Joypad data mask

		move.w	#read_p1s1r0,JOYOUT
		jsr		doalot
		move.l	JOYIN,d0			; Read joypad, pause button, A button
		move.w	#read_p1s1r1,JOYOUT
		or.l		d1,d0			; Mask off unused bits
		move.l	d0,d2			; d2 = xxAPxxxx 3210xxxx xxxxxxxx xxxxxxxx
		jsr		doalot
;	moveq	#1,d3
;	divs	d3,d4
		move.l	JOYIN,d0			; Read *741 keys, B button
		move.w	#read_p1s1r2,JOYOUT
		or.l		d1,d0			; Mask off unused bits
		rol.l	#4,d0
		and.l	d0,d2			; d2 = 76543210 xxxxxxxx xxxxxxxx xxB1xxAP
		jsr		doalot
;	divs	d3,d4
		swap		d2
		move.l	JOYIN,d0			; Read 2580 keys, C button
		move.w	#read_p1s1r3,JOYOUT
		or.l		d1,d0			; Mask off unused bits
		and.l	d0,d2			; d2 = xxAPxxB1 01234567 xxC0xxxx 0123xxxx
		jsr		doalot
;	divs	d3,d4
		move.l	JOYIN,d0			; Read 369# keys, Option button
		or.l		d1,d0			; Mask off unused bits
		rol.l	#4,d0
		and.l	d0,d2			; d2 = YYYYYYYY xxB1xxAP XXXXXXXX xxC0xxD0 <== inputs active low


		btst.l	#16,d2
		bne.b	.4
			move.l	d2,anajoy1
		.3:
;once again -----------------------------------------------------
		move.w	#read_p1s1r0,JOYOUT
		jsr		doalot
		move.l	JOYIN,d0			; Read joypad, pause button, A button
		move.w	#read_p1s1r1,JOYOUT
		or.l		d1,d0			; Mask off unused bits
		move.l	d0,d2			; d2 = xxAPxxxx 3210xxxx xxxxxxxx xxxxxxxx
		jsr		doalot
		move.l	JOYIN,d0			; Read *741 keys, B button
		move.w	#read_p1s1r2,JOYOUT
		or.l		d1,d0			; Mask off unused bits
		rol.l	#4,d0
		and.l	d0,d2			; d2 = 76543210 xxxxxxxx xxxxxxxx xxB1xxAP
		jsr		doalot
		swap		d2
		move.l	JOYIN,d0			; Read 2580 keys, C button
		move.w	#read_p1s1r3,JOYOUT
		or.l		d1,d0			; Mask off unused bits
		and.l	d0,d2			; d2 = xxAPxxB1 01234567 xxC0xxxx 0123xxxx
		jsr		doalot
		move.l	JOYIN,d0			; Read 369# keys, Option button
		or.l		d1,d0			; Mask off unused bits
		rol.l	#4,d0
		and.l	d0,d2			; d2 = YYYYYYYY xxB1xxAP XXXXXXXX xxC0xxD0 <== inputs active low
;-----------------------------------------------------------------
		btst.l	#16,d2
		bne.b	.4
			move.l	d2,anajoy1
		.4:

		move.l	anajoy1,d2
		;process raw analog data ------
			ror.l	#8,d2

			move.l	d2,d7	;split to CAR_STEER
			swap		d2
			and.w	#$ff,d2
			and.w	#$ff,d7
			sub.w	anacenterx+2,d2	;center
			sub.w	anacenterx,d7
			;scale it here
			muls		#3,d2	;more GAS (beans)
			cmpi.w	#$7f,d2
			ble		.names
				move.w	#$7f,d2
			.names:
			cmpi.w	#-$7f,d2
			bge		.leftok
				move.w	#-$7f,d2
			.leftok:
			;do x part
			cmpi		#0,d7
			bmi		.ckleftx
				;right x
				cmp.w	anamaxx,d7
				ble		.maxxok
					move.w	d7,anamaxx
					move.l	#$8000,d3
					divu		d7,d3
					move.w	d3,anasclrx
				.maxxok:
				muls		anasclrx,d7
				asr.l	#8,d7
				bra		.didrightx
			.ckleftx:
				;right x
				cmp.w	anaminx,d7
				bge		.minxok
					move.w	d7,anaminx
					move.w	d7,d4
					neg		d4
					move.l	#$8000,d3
					divu		d4,d3
					move.w	d3,anascllx
				.minxok:
				muls		anascllx,d7
				asr.l	#8,d7
			.didrightx:	
			;to car vars
			muls		#-192, d7	;CAR_STEER	PUT A NEGATIVE SIGN FOR PRODUTION VERSION
			asr.l	#7, d7
			move.w	d2, d6	;CAR_GAS

	.notar:
	cmpi.l	#PLAYER1,chkPlayer	;only read the ports with player2's check
	bne		.donmesswit
		jsr		input			;read controller
		; load joy bits in d0 d1
		move.l	joycur, d0

		move.w	cont_opt,d2		; get which controller remapping option is in effect
		lsl.w	#2,d2
		lea		remapfuncs,a2		; table of mapping functions
		move.l	(a2,d2.w),a2
		jsr	(a2)			; remap the A,B,C keys

		;give remapped joycur back
		move.l	d0,joycur
		; do player2
		move.l	joycur2, d0

		move.w	cont_opt,d2		; get which controller remapping option is in effect
		lsl.w	#2,d2
		lea		remapfuncs,a2		; table of mapping functions
		move.l	(a2,d2.w),a2
		jsr	(a2)			; remap the A,B,C keys

		;give remapped joycur2 back
		move.l	d0,joycur2

		tst.w	steeropt
		beq		.6
			move.w	#read_p1s1r0,JOYOUT
			jsr		doalot
			move.w	#read_p1s1r1,JOYOUT
			jsr		doalot
			move.w	#read_p1s1r2,JOYOUT
			jsr		doalot
			move.w	#read_p1s1r3,JOYOUT
			jsr		doalot
			move.w	#read_p1s1r0,JOYOUT
			jsr		doalot
			move.w	#read_p1s1r1,JOYOUT
			jsr		doalot
			move.w	#read_p1s1r2,JOYOUT
			jsr		doalot
			move.w	#read_p1s1r3,JOYOUT
		.6:
		move.l	joyedge,d0		;hang on to the previous edges
		move.l	joyedge2,d1
		or.l		d0,joyehold
		or.l		d1,joyehol2
		tst.b	joyesem			;move edge bits into joyacc?
		bne		.donmesswit
			move.l	joyehold,d0
			move.l	joyehol2,d1
			or.l		d0,joyeacc
			or.l		d1,joyeacc2
			clr.l	joyehold
			clr.l	joyehol2
	.donmesswit:

	addi.w	#1, joyph
	lsr.w	d3
	addi.w	#4, d3
	move.w	d3,ANALOGJOY		; We want to read x-pos of Analog Joystick 0
;--------------------------------------------------------------
;  Evaluate each fire button status and execute code
;  independent to each fire button.
;--------------------------------------------------------------

	move.l	chkPlayer, a0		; which player to read
;	clr.l	d7		; CAR_STEER
;	move.l	d7, d6	; CAR_GAS

	; load joy bits in d0 d1
	lea		joycur, a1
	cmp.l	#PLAYER1, a0		; but note "modem" check below...
	beq		.10
		lea	joycur2, a1
.10:	move.l	(a1), d0

;	move.w	cont_opt,d2		; get which controller remapping option is in effect
;	lsl.w	#2,d2
;	;add.w	d2,d2
;;	;add.w	d2,d2			; multiply by 4
;	lea		remapfuncs,a2		; table of mapping functions
;	move.l	(a2,d2.w),a2
;	jsr	(a2)			; remap the A,B,C keys
;
;	;give remapped joycur back
;	move.l	d0,(a1)

	; allow either player to jump in with pause or mute
	move.l	joybothe,d1

	cmp.l	#PLAYER1, a0
	bne		.ck_left
.if 0
	move.w	steeropt, d3
	beq		.ck_left
		; analog stuf(verb)
		move.w	anajoy1+2, d2	; x-input
		sub.w	#$80, d2
		muls		#-192, d2
		asr.l	#7, d2
		move.w	d2, d7	;CAR_STEER

		move.w	anajoy1, d2	; y-input
		sub.w	#$80, d2
		move.w	d2, d6
	
		bra		.ck_Option
.endif
	; powerpad stuf
	.ck_left:
	btst.l	#JOY_LEFT, d0
	beq		.ck_right
		move.w	#96, d7	; CAR_STEER
		bra		.ck_up

	.ck_right:
	btst.l	#JOY_RIGHT, d0
	beq		.ck_Option

		move.w	#-96, d7	; CAR_STEER

	.ck_up:
	btst.l	#JOY_UP, d0
	beq		.ck_down
		asr.w	d7	; CAR_STEER
		bra	.ck_Option
	.ck_down:
	btst.l	#JOY_DOWN, d0
	beq		.ck_Option
		asl.w	d7	; CAR_STEER

	.ck_Option:
	;ck_fireB:
	btst.l	#FIRE_B,d0
	beq		.ck_fireC
	;(reactionary code goes here)
		move.w	#$7f, d6		;CAR_GAS(a0)

	.ck_fireC:
	btst.l	#FIRE_C,d0
	beq		.ck_Pause
	;(reactionary code goes here)
		move.w	#-$7f, d6		;CAR_GAS(a0)

	.ck_Pause:
	; first modify CAR_GAS for speed option
	move.w	speedvar, d3
	muls		d3, d6		;CAR_GAS(a0)
	asr.w	#2,d6		;speedvar has two bit fractional precicion
;	beq.b	.20
; 		add.w	#1, d3
; 		muls		d3, d6		;CAR_GAS(a0)
;	.20:

	; now enter the data into the queue
	move.w	CAR_QUEUE(a0),d0	;tail
	lea		CAR_QUEUE+4(a0),a4
	move.w	d7,(a4,d0.w)
	move.w	d6,2(a4,d0.w)
	addq		#4,d0
	bclr		#5,d0			;wrap
	cmp.w	CAR_QUEUE+2(a0),d0	;head - check for full queue
	beq		.full			;if full, abandon enter
		move.w d0,CAR_QUEUE(a0)	;new tail
	.full:
	rts	

;================================================================================================
;	do_joypad - done at the frame rate - handles everything that doesn't
;			  go into the input queue (ie CAR_TURN,CAR_GAS)
;---------------------------------------------------------------------
do_joypad:
	move.l	player,a0
	; load joy bits in d0
	lea	joycur, a1
	lea	joyeacc, a2
	cmp.l	#PLAYER1, a0		; but note "modem" check below...
	beq		.10
		lea	joycur2, a1
		lea	joyeacc2, a2
.10:	move.l	(a1), d0
	move.l	d0,CAR_CTRL(a0)	;give it to the car struct

	;get edge bits
	move.b	#1,joyesem		;don't let anyone else mess w'em
	move.l	(a2),d1			;get'em
	clr.l	(a2)				;got'em
	clr.b	joyesem			;coast is clear

	; now check pause
	btst.l	#PAUSE,d1			; only check the edge
	beq		.fire_done
	;(reactionary code goes here)
		bsr	do_pause

.fire_done:

;  Evaluate each 12-key button from the keypad and execute
;  code independent to each button.

ck_key1:
	btst.l	#KEY_1, d0
	beq		ck_key2
;	(reactionary code goes here)
;	bail out the user, by stopping us and setting us upright
stabilize:
		movem.l	d0-d1/a0,-(sp)
		lea	CAR_MATRIX(a0),a1
		move.w	#0,alpha
		move.w	CAR_HEAD+2(a0),beta		; get angle of rotation
		move.w	#0,gamma
		jsr	mkMatrix
		movem.l	(sp)+,d0-d1/a0
		lea	CAR_VELOCITY(a0),a1
		clr.l	(a1)+			; clear velocity
		clr.l	(a1)+
		clr.l	(a1)+
		clr.l	(a1)+			; clear rotations
		clr.l	(a1)+
		clr.l	(a1)+
		bra	ck_key4
ck_key2:
	btst.l	#KEY_2, d0
	beq.b		ck_key3
;	(reactionary code goes here)
.if 0
		btst.l	#KEY_3,d0		;  2 & 3 together turn on debugflg
		beq.b	stabilize
		move.b	#1,debugflg		; crash the system after next draw
.endif
		bra.b	stabilize

ck_key3:
	btst.l	#KEY_3, d0
	beq		ck_key4
;	(reactionary code goes here)
		bra.b	stabilize

ck_key4:
	btst.l	#KEY_4, d1
	beq		ck_key5
;	(reactionary code goes here)
		move.w	#$84,CAMERA_FLAG(a0)

ck_key5:
	btst.l	#KEY_5, d1
	beq		ck_key6
;	(reactionary code goes here)
		move.w	#$85,CAMERA_FLAG(a0)		; set camera on a stick

ck_key6:
	btst.l	#KEY_6, d1
	beq		ck_key7
;	(reactionary code goes here)
.if DEBUGKEYS
		btst.l	#KEY_8,d0			; debugging coordinates if 7 is held down too
		beq.b	.normal
		movem.l	d0-d1/a0, -(sp)
		move.b	#1,d2
	; V15 RECOVERY (2026): retail uses TABLES.S showcoord, not a second BSS flag.
		sub.b	showcoord,d2
		move.b	d2,showcoord
	; clear the HUDs
		move.l	#$001f0040,d6			; 64x32
		moveq	#0,d5				; top left corner
		moveq	#0,d7
		move.l	#PITCH1|PIXEL16|WID64|XADDPHR,d0
		move.l	#HUD1,a0
		jsr	blit_rect
		move.l	#$001f0040,d6			; 64x32
		moveq	#0,d5				; top left corner
		moveq	#0,d7
		move.l	#PITCH1|PIXEL16|WID64|XADDPHR,d0
		move.l	#HUD2,a0
		jsr	blit_rect
		movem.l	(sp)+, d0-d1/a0
		bra.b	ck_key7
.endif
.normal:
.if DEBUGKEYS
	tst.b	showcoord				; always drop a camera if coordinates are on
	bne.b	.10					; otherwise:
.endif
	cmp.w	#1,gametype				; if a racing game...
	beq.b	chasecam				; ... substitute chase camera
.10:
	move.w	#6,CAMERA_FLAG(a0)

ck_key7:
	btst.l	#KEY_7, d1
	beq		ck_key8
;	(reactionary code goes here)
		move.w	#0,CAMERA_FLAG(a0)

ck_key8:
	btst.l	#KEY_8, d1
	beq		ck_key9
;	(reactionary code goes here)
chasecam:
		move.w	CAMERA_FLAG(a0),d3
		bclr.l	#7,d3
		cmp.w	#$1,d3
		beq	ck_key9
		move.w	#$81,CAMERA_FLAG(a0)
		move.l	FLOOR_MODEL(a0),a2
		lea	NEW_CAMERA(a0),a3
		move.l	a2,(a3)+
		lea	4(a3),a3		; skip CAMERA_MODEL
ck_key9:
	btst.l	#KEY_9, d1
	beq		hi_end
;	(reactionary code goes here)
.if DEBUGKEYS
		tst.b	showcoord			; if we're showing coordinates
		bne.b	.10				; always accept camera 9
.endif
		bclr.l	#KEY_9,d1
		cmp.w	#1,gametype			; if a racing game ...
		beq.b	chasecam			; ... substitute cahse camera
.10:
		move.w	CAMERA_FLAG(a0),d0
		cmp.w	#2,d0				; are we already at the fixed position?
		beq.b	.20				; yes == don't change camera mode
			move.w	#3,d0			; go to "swoop" mode
.20:
		move.w	d0,CAMERA_FLAG(a0)

hi_end:								;handle input end
	rts


;=================================================================================================================
; pause code
;=================================================================================================================
	.extern	snd_hdr_tbl,skid_snd
do_pause:
	clr.b	stufqueue				;not while paused
	moveq	#PLAY_OBJS,d6
	lea	playobjs,a1
	lea	olist_pau,a2
	jsr	build

	tst.w	splitscreen
	bne.b	.nohood
		lea	olist_pau,a1
		move.l	32+12(a1),d0		; get second long of second phrase of bitmapped object
		and.l	#$FFFFF000,d0		; zero out X position
		move.l	player,a0
		tst.w	CAMERA_FLAG(a0)		; check for inside the car view
		beq.b	.05
			or.w	#$0400,d0	; if not inside the car, shove the hood off-screen
	.05:
		move.l	d0,32+12(a1)
.nohood:
	move.l	timestamp,d0
.10:
	cmp.l	timestamp,d0
	beq.b	.10
	move.l	d0,-(sp)				; save current time stamp

	move.l	listAddr,-(sp)			; save current object list
	move.l	#olist_pau,listAddr
	move.w	#P1ENGV,d2			; voice
	jsr		eng_off
	tst.w	twoplayer
	beq.b	.15
	move.w	#P2ENGV,d2			; voice
	jsr		eng_off
.15:
	;turn off sfx voices
	lea		tablestart+(taboff*P1SNDV),a0	;radio sound uses 6th voice
	move.l	#-4, (a0)
	move.l	#-4, (taboff,a0)

	move.b	muteflag,d0
	move.w	d0,-(sp)
	tst.b	d0
	bne	waitloop
		jsr	mute					; toggle sound off
waitloop:
		move.l	timestamp,d0		; wait for a vblank
.10:
		cmp.l	timestamp,d0
		beq.b	.10

		jsr	pinput
		move.l	joybothe,d0
		btst.l	#KEY_1,d0		; check for 1 & 3 keys being held down
		beq	.not13
		btst.l	#KEY_3,d0
		beq	.not13
			move.l	#olist_pau,a0	; erase the pause icon...
			lea	5*32+12(a0),a0	; which is the 6th bitmapped object in 1 player mode
			tst.w	splitscreen
			beq.b	.11
				lea	32(a0),a0		; and the 7th in 2 player mode
.11:
			move.l	(a0),d1		; get second long of second phrase of object
			and.l	#$FFFFF000,d1	; zero out X position
			or.w	#$0400,d1	; set it to a big X value
			move.l	d1,(a0)		; and store it (thus erasing the pause icon)

.not13:		btst.l	#PAUSE,d0
		beq.b	waitloop

	move.w	(sp)+,d0				; get old mute flag
	tst.b	d0
	bne	.20
		jsr	mute					; toggle sound back on
.20:
;restart the engine sounds
	lea		PLAYER1,a0
	bsr		get_espeed				;set D3 to engine speed
	move.w	#PLAYER1_ENG_SOUND,d0		; engine sound
	move.l	#$3fff,d1	; xposn
	move.w	#P1ENGV,d2				; voice
	jsr		eng_on
	tst.w	twoplayer
	beq.b	.60
	lea		PLAYER2,a0
	bsr		get_espeed				;set D3 to engine speed
	move.w	#PLAYER2_ENG_SOUND,d0		; engine sound
	move.l	#$3fff,d1	; xposn
	move.w	#P2ENGV,d2	; voice
	jsr		eng_on
.60:
	;turn back on skid snds
	lea		snd_hdr_tbl,a1
	move.w	PLAYER1+CAR_SKD_VCE, d2
	beq		.70
		asl.w	#2, d2
		move.l	(a1,d2.w),a1			;a1 is now the [tablestart + (n * taboff)]
		move.l	skid_snd,(a1)			;turn back on voice
	.70:
	move.w	PLAYER2+CAR_SKD_VCE, d2
	beq		.75
		asl.w	#2, d2
		move.l	(a1,d2.w),a1			;a1 is now the [tablestart + (n * taboff)]
		move.l	skid_snd,(a1)			;turn back on voice
	.75:

	move.l	(sp)+,listAddr				; restore object list
	move.l	(sp)+,timestamp			; restore time stamp
	move.b	#1,stufqueue				;OK, you can play now.
	rts


get_espeed::
;A0 = PLAYER1 or PLAYER2
	lea		CAR_VELOCITY(a0),a1		; engine speed is based on velocity
	move.l	(a1)+,d3
	bpl.b	.20
	neg.l	d3
.20:
	move.l	(a1)+,d0
	bpl.b	.30
	neg.l	d0
.30:
	add.l	d0,d3
	move.l	(a1)+,d0
	bpl.b	.40
	neg.l	d0
.40:
	add.l	d0,d3
	asr.l	#5,d3
	asr.l	#5,d3
	rts

; table of remapping functions
; each remapping function should change d0 so that
; it reflects the way keys would be in the
; "default" configuration, i.e. if the user has
; swapped the meanings of A and B, the mapping
; function should swap the corresponding bits
; registers a0-a1/d0-d1 must be preserved
;
remapfuncs:
	dc.l	fnull, facb,fbac,fcab,fbca,fcba

facb:
	move.l	d0,d2
	and.l	#~(FIRE_ABC),d0		; clear out the bits
	btst.l	#FIRE_A,d2
	beq	.10
		bset	#FIRE_A,d0
.10:
	btst.l	#FIRE_B,d2
	beq	.20
		bset	#FIRE_C,d0
.20:
	btst.l	#FIRE_C,d2
	beq	.30
		bset	#FIRE_B,d0
.30:
fnull:
	rts

fbac:
	move.l	d0,d2
	and.l	#~(FIRE_ABC),d0		; clear out the bits
	btst.l	#FIRE_A,d2
	beq	.10
		bset.l	#FIRE_B,d0
.10:
	btst.l	#FIRE_B,d2
	beq	.20
		bset.l	#FIRE_A,d0
.20:
	btst.l	#FIRE_C,d2
	beq	.30
		bset.l	#FIRE_C,d0
.30:
	rts

fbca:
	move.l	d0,d2
	and.l	#~(FIRE_ABC),d0		; clear out the bits
	btst.l	#FIRE_A,d2
	beq	.10
		bset.l	#FIRE_B,d0
.10:
	btst.l	#FIRE_B,d2
	beq	.20
		bset.l	#FIRE_C,d0
.20:
	btst.l	#FIRE_C,d2
	beq	.30
		bset.l	#FIRE_A,d0
.30:
	rts

fcab:
	move.l	d0,d2
	and.l	#~(FIRE_ABC),d0		; clear out the bits
	btst.l	#FIRE_A,d2
	beq	.10
		bset.l	#FIRE_C,d0
.10:
	btst.l	#FIRE_B,d2
	beq	.20
		bset.l	#FIRE_A,d0
.20:
	btst.l	#FIRE_C,d2
	beq	.30
		bset.l	#FIRE_B,d0
.30:
	rts

fcba:
	move.l	d0,d2
	and.l	#~(FIRE_ABC),d0		; clear out the bits
	btst.l	#FIRE_A,d2
	beq	.10
		bset.l	#FIRE_C,d0
.10:
	btst.l	#FIRE_B,d2
	beq	.20
		bset.l	#FIRE_B,d0
.20:
	btst.l	#FIRE_C,d2
	beq	.30
		bset.l	#FIRE_A,d0
.30:
	rts

	.phrase
