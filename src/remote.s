	.include		'eq.s'
	.include		'externs.s'
	.include		'3dds.inc'

;*************************************************************************
; Support functions for modem stuff in packet.c
;*************************************************************************

;
; set the other car's position relative to its current band
;
_setrelposn::
	move.l	#PLAYER2,a0		; "other player" is always player 2
	move.l	FLOOR_MODEL(a0),a1	; get band
	lea	XORIG(a1),a1		; ...then band origin
	move.w	4(sp),d0		; get deltax
	ext.l	d0
	lsl.l	#8,d0			; convert to 20.12 format
	lsl.l	#4,d0
	add.l	(a1)+,d0		; add band X
	move.l	d0,CAR_POSN(a0)		; save X position

	move.w	6(sp),d0		; get deltay
	ext.l	d0
	lsl.l	#8,d0			; convert to 20.12 format
	lsl.l	#4,d0
	add.l	(a1)+,d0		; add band Y
	move.l	d0,CAR_POSN+4(a0)	; save Y position

	move.w	8(sp),d0		; get deltaz
	ext.l	d0
	lsl.l	#8,d0			; convert to 20.12 format
	lsl.l	#4,d0
	add.l	(a1)+,d0		; add band Z
	move.l	d0,CAR_POSN+8(a0)	; save Z position
	rts
;
; set the other car's band
;
_setband::
	move.l	#PLAYER2,a0
	move.l	4(sp),d0
	btst	#0,d0			; addresses can't be odd!
	bne.b	.10
	move.l	d0,FLOOR_MODEL(a0)
.10:
	rts
;
; set the other car's matrix
;
_setangles::
	move.l	#PLAYER2,a0
	move.w	4(sp),d0
	add.w	d0,d0			; convert from 0-255 to 0-2047 notation
	add.w	d0,d0
	add.w	d0,d0
	move.w	d0,alpha
	move.w	6(sp),d0
	add.w	d0,d0			; convert from 0-255 to 0-2047 notation
	add.w	d0,d0
	add.w	d0,d0
	move.w	d0,beta
	ext.l	d0
	move.l	d0,CAR_HEAD(a0)
	move.w	8(sp),d0
	add.w	d0,d0			; convert from 0-255 to 0-2047 notation
	add.w	d0,d0
	add.w	d0,d0
	move.w	d0,gamma
	lea	CAR_MATRIX(a0),a1
	jsr	mkMatrix
	rts

;
; return our car's band
;
_getband::
	move.l	#PLAYER1,a0
	move.l	FLOOR_MODEL(a0),d0
	rts
;
; return a pointer to our car's position
;
_getposn::
	move.l	#PLAYER1,d0
	add.l	#CAR_POSN,d0
	rts

;
; get our 3 alpha,beta,gamma angles (0-255, NOT 0-2048)
; passed a pointer to a 3 byte storage area for
; the angles
;
_getangles::
	move.l	4(sp),a1		; here's a pointer
	move.l	#PLAYER1,a0
	move.w	CAR_ANGLE(a0),d0	; get alpha angle
	lsr.w	#3,d0
	move.b	d0,(a1)+
	move.l	CAR_HEAD(a0),d0		; get beta angle
	lsr.w	#3,d0
	move.b	d0,(a1)+
	move.w	CAR_ANGLE+2(a0),d0
	lsr.w	#3,d0
	move.b	d0,(a1)			; get gamma angle
	rts

;
; make a score packet
; tag game: byte 1 is 0 (itCar == me) or 1 (itCar == you), bytes 2 and 3 are score (hi), score (lo)
; race game: byte 1 is 0, bytes 2 and 3 are score (hi), score (lo)
; crash and score game: byte 1 (will be) an indicator of the power ball
; upper 3 bits of byte 1 must always be 101, i.e. byte 1 should be $ax or $bx
;
_getscore::
	move.l	#PLAYER1,a0
	moveq.l	#0,d0
	move.w	GAME_DATA(a0),d0
	cmp.w	#0,gametype
	bne	.nottag
		cmp.l	itCar,a0
		beq	.ret
		bset	#16,d0
		bra	.ret
.nottag:
	cmp.w	#1,gametype
	bne	.notrace
	bra	.ret
.notrace:
.ret:
	or.l	#$00a00000,d0
	rts

;
; set the other player's score
; byte 1 AND $e0 should always be $a
; for valid scores
;
_setscore::
	move.l	#PLAYER2,a0
	move.l	4(sp),d0
	move.l	d2,-(sp)
	move.l	d0,d1
	and.l	#$00e00000,d1			; check score magic
	cmp.l	#$00a00000,d1
	bne	.ret
	move.w	d0,GAME_DATA(a0)
	tst.w	gametype			; tag game?
	bne	.07
	move.l	d0,CAR_TIMER(a0)		; if so, time == score
.07:
	move.w	scoreinc,d1			; get the score increment: hi word in d1, low in d2
	move.w	scoreinc+2,d2
	mulu	d0,d1
	mulu	d0,d2
	swap	d1				; shift hi word left by 16
	move.w	#0,d1
	add.l	d2,d1
	move.l	d1,SCORE(a0)
.ret:
	move.l	(sp)+,d2
	rts


