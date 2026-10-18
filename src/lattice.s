;-------------------------------------------------

; ---- v12 source-recovery notes (cross-referenced to original C) -----
; Function headings below were recovered from the surviving Atari .C files.
; the now completely misnamed "lattice.s": compiler
; support for our C compiler (currently gcc)
; plus various C utility functions
;-------------------------------------------------

		.text
	.include 'jaguar.inc'
	.include 'blit.inc'

	.globl	_msg
	.globl	_malloc
	.globl	_memzero
	.globl	_memcpy
	.globl	memcpy
	.globl	_bcopy
	.globl	_fatal

_fatal:
	link	a6,#0
	move.l	8(sp),d0		; record the type of fatality
	illegal
	unlk	a6
	rts

; ------------------------------------------------------------------
; ---- _memzero / V12 RECOVERY ANNOTATION ----
; ZERO BUFFER
; General-purpose 68000 memory-zeroing helper.
; NOTE: commentary added in v12 from surviving C source / build analysis.
;       Original machine-code order and historical labels are unchanged.
; ------------------------------------------------------------------
_memzero:
	move.l	4(sp),a0		; destination
	move.l	8(sp),d1		; length
	move.l	d2,-(sp)		; save d2, we'll be using it
	moveq.l	#0,d0			; value

	cmp.l	#128,d1			; zeroing only a small area?
	bmi	.oldway			; yes, just go do it


	move.l	a0,d2			; test for alignment
	btst	#0,d2			; odd?
	beq.b	.areeven
	move.b	d0,(a0)+		; set one byte, now we are even
	subq.l	#1,d1
	move.l	a0,d2
.areeven:
	btst	#1,d2			; on a long boundary?
	beq.b	.arelong
	move.w	d0,(a0)+		; set 2 bytes, now we're long aligned
	subq.l	#2,d1
	move.l	a0,d2
.arelong:
	btst	#2,d2			; on a phrase boundary?
	beq.b	.arephrase		; yes -- go do it
	move.l	d0,(a0)+
	subq.l	#4,d1
.arephrase:
;
; now, set up the blitter to zero big blocks (up to 16K at a time)
;
.blitloop:
	move.l	d1,d2
	cmp.l	#$4000,d2
	bmi.b	.smallenuf
		move.l	#$4000,d2
.smallenuf:
	sub.l	d2,d1
	move.l	a0,A1_BASE
	add.l	d2,a0
	move.l	#0,A1_PIXEL
	move.l	#0,A1_FPIXEL
	move.l	#PIXEL8|WID8|XADDPHR,A1_FLAGS

	move.l	d0,B_PATD
	move.l	d0,B_PATD+4
	swap	d2
	move.w	#1,d2			; outer loop counter = 1
	swap	d2
	move.l	d2,B_COUNT
	move.l	#PATDSEL,B_CMD

	cmp.l	#0,d1
	bne.b	.blitloop
	bra	.return
;
; the old, slow way to zero arbitrarily aligned memory
;
.oldway:
	move.b	d0,(a0)+
	subq.l	#1,d1
	bne.b	.oldway
.return:
	move.l	(sp)+,d2		; restore d2
	rts

_bcopy::
	move.l	4(sp),a0		; source
	move.l	8(sp),a1		; destination
	move.l	12(sp),d1		; length
	bra.b	memcpy

_memcpy::
	move.l	4(sp),a1		; destination
	move.l	8(sp),a0		; source
	move.l	12(sp),d1		; length

memcpy::
	cmp.l	#128,d1			; copying only a small area?
	bmi	.oldway			; yes, just go do it

	movem.l	d2-d7,-(sp)

;
; phrase align destination and source
;
	moveq.l	#7,d2
	move.l	d2,d3
	move.l	d2,d4
	move.l	d2,d5
	not.l	d2
	not.l	d3

	move.l	a1,d0
	and.l	d0,d2			; set d2 = phrase start of destination
	and.l	d0,d4			; set d4 = byte offset of destination
	move.l	a0,d0
	and.l	d0,d3			; set d3 = phrase start of source
	and.l	d0,d5			; set d5 = byte offset of source

;
; now, set up the blitter to copy big blocks (up to 32767 at a time)
;
	move.l	#PIXEL8|WID8|XADDPHR,d6	; flags for blitter windows
	move.l	#SRCEN|SRCENX|LFU_A|LFU_AN,d7	; blitter command
	cmp.w	#0,d5			; is source phrase aligned?
	bne.b	.blitloop
		move.l	#SRCEN|LFU_A|LFU_AN,d7	; if so, we don't need the extra read
.blitloop:
	move.l	B_CMD,d0
	btst	#0,d0
	beq.b	.blitloop

	move.l	d1,d0
	cmp.l	#$7ff0,d0
	bmi.b	.smallenuf
		move.l	#$7ff0,d0
.smallenuf:
	sub.l	d0,d1
	move.l	d2,A1_BASE		; set destination
	add.l	d0,d2
	move.l	d3,A2_BASE		; set source
	add.l	d0,d3
	move.l	d4,A1_PIXEL		; set dest. byte offset
	move.l	#0,A1_FPIXEL
	move.l	d5,A2_PIXEL		; set source byte offset
	move.l	d6,A1_FLAGS
	move.l	d6,A2_FLAGS

	swap	d0
	move.w	#1,d0			; outer loop counter = 1
	swap	d0
	move.l	d0,B_COUNT
	move.l	d7,B_CMD

	cmp.l	#0,d1
	bne.b	.blitloop
	movem.l	(sp)+,d2-d7
	bra	.return
;
; the old, slow way to copy arbitrarily aligned memory
;
.oldway:
	move.b	(a0)+,(a1)+
	subq.l	#1,d1
	bne.b	.oldway
.return:
	rts


	.extern	_alloc
; ------------------------------------------------------------------
; ---- _malloc / V12 RECOVERY ANNOTATION ----
; LATTICE COMPATIBILITY MALLOC
; Allocation entry exposed to the original C helper/runtime.
; NOTE: commentary added in v12 from surviving C source / build analysis.
;       Original machine-code order and historical labels are unchanged.
; ------------------------------------------------------------------
_malloc:
	jmp	_alloc

_msg:
	rts


;
; stuff taken from the MiNT library
;
	.text
	.even
	.globl	__mulsi3, ___mulsi3

; ------------------------------------------------------------------
; ---- __mulsi3 / V12 RECOVERY ANNOTATION ----
; SIGNED LONG MULTIPLICATION
; Compiler support function for 32-bit signed multiplication.
; NOTE: commentary added in v12 from surviving C source / build analysis.
;       Original machine-code order and historical labels are unchanged.
; ------------------------------------------------------------------
__mulsi3:
___mulsi3:
	move.l	d2, a0
	move.l	d3, a1
	movem.w	4(sp), d0-d3
	move.w	d0, -(sp)
	bpl	.LT1
	neg.w	d1
	negx.w	d0
.LT1:	tst.w	d2
	bpl	.LT2
	neg.w	d3
	negx.w	d2
	not.w	(sp)
.LT2:
	ext.l	d0
	beq	.LT3
	mulu	d3, d0
.LT3:	tst.w	d2
	beq	.LT4
	mulu	d1, d2
	add.w	d2, d0
.LT4:	swap	d0
	clr.w	d0
	mulu	d3, d1
	add.l	d1, d0
	move.l	a1, d3
	move.l	a0, d2
	tst.w	(sp)+
	bpl	.LT5
	neg.l	d0
.LT5:	rts

	.globl	__divsi3, ___divsi3
	.globl	__modsi3, ___modsi3

; ------------------------------------------------------------------
; ---- __divsi3 / V12 RECOVERY ANNOTATION ----
; SIGNED LONG DIVISION
; Compiler support function for 32-bit signed division.
; NOTE: commentary added in v12 from surviving C source / build analysis.
;       Original machine-code order and historical labels are unchanged.
; ------------------------------------------------------------------
__divsi3:
___divsi3:
	move.l	d2, a0
	move.l	d3, a1
	clr.w	-(sp)
	clr.l	d0
	move.l	10(sp), d2
	beq	.LT1
	bpl	.LT2
	neg.l	d2
	not.w	(sp)
.LT2:	move.l	6(sp), d1
	bpl	.LT3
	neg.l	d1
	not.w	(sp)
.LT3:

	cmp.l	d2, d1
	bcs	.LT4

	tst.w	10(sp)
	bne	.LT5
	move.w	d1, d3
	clr.w	d1
	swap	d1
	beq	.LT6
	divu	d2, d1
.LT6:	move.w	d1, d0
	swap	d0
	move.w	d3, d1
	divu	d2, d1
	move.w	d1, d0
	clr.w	d1
	swap	d1
	bra	.LT4

.LT5:
	moveq	#31, d3
.LT7:
	add.l	d1, d1
	addx.l	d0, d0
	cmp.l	d2, d0
	bcs	.LT8
	sub.l	d2, d0
	addq.w	#1, d1
.LT8:
	dbra	d3, .LT7
	exg	d0, d1
.LT4:
	tst.w	6(sp)
	bpl	.LT9
	neg.l	d1


.LT9:	tst.w	(sp)+
	bpl	.LT10
	neg.l	d0
.LT10:
	move.l	a1, d3
	move.l	a0, d2
	rts
.LT1:
	divu	d2, d1
	bra.b	.LT4


; ------------------------------------------------------------------
; ---- __modsi3 / V12 RECOVERY ANNOTATION ----
; SIGNED LONG REMAINDER
; Compiler support function for 32-bit signed remainder.
; NOTE: commentary added in v12 from surviving C source / build analysis.
;       Original machine-code order and historical labels are unchanged.
; ------------------------------------------------------------------
__modsi3:
___modsi3:
	move.l	8(sp), -(sp)
	move.l	8(sp), -(sp)
	jsr	__divsi3
	addq.l	#8, sp
	move.l	d1, d0
	rts

	.end
