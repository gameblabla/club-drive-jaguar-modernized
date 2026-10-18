;-----------------------------------------------------------------------
;
;	blit.s
;
;
;
;-----------------------------------------------------------------------

	.include	'jaguar.inc'
	.include	'blit.inc'
	.include	'3dds.inc'

	.globl	blit_rect,blit_pic
	.extern	screen_addr
;-----------------------------------------------------------------------
	.phrase

blit_rect:
;d0 = long = A1_FLAGS
;a0 = long = "screen" address
;d5 = high = rectangle Y, low = rectangle X
;d6 = high = rectangle width, low = rectangle height
;d7 = low = rectangle color
;Set up the blitter to draw a rectangle
; This means set BLIT_A1FLAGS to 
;	Contiguous data
;	16 bit per pixel
;	window width of 320 pixels
;	add increment
;
; BLIT_A1FLAGS is passed
; in d0, so that the caller can decide whether (and how)
; Z buffering is to be perfomed, plus how big the
; blit should be
;

	move.l	d0,-(sp)
; first, wait for the blitter to finish
.01:
	move.l	B_CMD,d0
	btst.l	#0,d0
	beq.b	.01

	move.l	(sp)+,d0

.if 0
	move.l	#PITCH1|PIXEL16|WID320|XADDPHR,d0
.endif
	move.l	d0,A1_FLAGS

	move.l	a0,A1_BASE

; Set the coordinates of the top left corner
	move.l	d5,A1_PIXEL		;get rectangle Y,X

; Set fractional pixel pointer
	move.l	#0,A1_FPIXEL
	
; Set up the increment register to
; 1 in x and 0 in y
;	move.l	#$00010000,B_A1INC

; Set up the fractional increment register to
; 0 in x and 0 in y

;	move.l	#0,B_A1INCF

; Set up the step size in x
; 1 in y
	move.l	d6,d0				;get width (high word)
;	swap		d0					;move to width to low word
	neg.w	d0					;X
	swap		d0
	move.w	#1,d0				;Y
	swap		d0
	move.l	d0,A1_STEP

; Set up the fractional step size
; 0 in X, 0 in y

	move.l	#0,A1_FSTEP

; Set up Counters register to rectangle width, height+1
; rect width, height is in d6

	add.l	#$00010000,d6			;need height + 1
	move.l	d6,B_COUNT

; Use rectangle color in d7 for the data to write

;	swap		d7					;need color in high word
	move.l	d7,B_PATD	
	move.l	d7,B_PATD+4

; Now Turn IT ON !!!!!!!!!!!!!
; NO SOURCE DATA
; NO OUTER LOOP
; Turn on pattern data
; Allow outer loop update

	move.l	#PATDSEL|UPDA1,d0
;	swap		d0
	move.l	d0,B_CMD

	rts

;-----------------------------------------------------------------------
blit_pic:
;d0 is destination flags
;a0 is the destination address
;a1 is the source address
;d1 is source flags
;d5 is the top left corner Y,X
;d6 is the image height, width
;d7 is unused
;Set up the blitter to draw an image from memory
; Set B_A1FLAGS to 
;	Contiguous data
;	16 bit per pixel
;	window width of 320 pixels
;	add 1

; first, wait for the blitter to finish
.01:
	move.l	B_CMD,d7
	btst.l	#0,d7
	beq.b	.01

; clear is zero
	move.l	#0,B_PATD	
	move.l	#0,B_PATD+4
;DESTINATION INFO
;	move.l	#PITCH1|PIXEL16|WID320|XADDPIX,d0
	move.l	d0,A1_FLAGS

; Point A1BASE to where the data will be written
	move.l	a0,A1_BASE


;SOURCE INFORMATION
	move.l	d1,A2_FLAGS

;Point A2BASE to the source data
	move.l	a1,A2_BASE

;start at 0,0 of source image
	move.l	#0,A2_PIXEL

;Y,X position to write data
	move.l	d5,A1_PIXEL

; Set up Counters register to image width, height
; width,height is in d6
	move.l	d6,B_COUNT

; Set up the step size in x
; 1 in y
	move.l	d6,d0				;get width (low word)
	neg.w	d0				;X
	swap	d0
	move.w	#1,d0				;Y
	swap	d0
	move.l	d0,A1_STEP

	move.l	#0,A1_FSTEP

; set the pattern register to 0 (for the
; data comparator)
	move.l	#0,B_PATD
	move.l	#0,B_PATD+4

; turn on blitter
; the "DSTEN" is to allow DCOMPEN to work in phrase mode
	move.l	#UPDA1|SRCEN|DSTEN|DCOMPEN|LFU_A|LFU_AN,d0
	move.l	d0,B_CMD

	rts
