	.include	'eq.s'
	.include	'externs.s'

SHRINK_TIME		equ	300			;when to start shrinking the tiles horizontally
CREDIT_TILES		equ	7			;number of objects that form the credits sign
TOTAL_CREDITS		equ	11			;total different credit text signs to display

SIGN_X			equ	185+16		;X position of left credit piece (moved over 16 because it starts with hscale at 0)

	.text
credloop::
	cmp.l	#MAX_CROSSCNT,crosscnt
	beq.b	.70						;don't need to double buffer any more after cross fade is done
	add.l	#1,crosscnt
	move.l	#backgr0,d0				;destination for cross fade
	cmp.l	#backgr1,c_scr+O_DATA
	bge.b	.30						;> if backgr1 is being used (address isn't exactly backgr1 for NTSC)
	move.l	#backgr1,d0				;destination for cross fade
.30:
	move.l	d0,d4					;leave backgr0 or backgr1 in D0 for do_cross
	move.l	#stonedta,d1				;source pic 1
	move.l	#stonedta+(448*288*2),d2		;end of source pic 1
	move.l	#credscr,d3				;source pic 2
	cmp.b	#NTSC,pal_ntsc
	bne.b	.50
	add.l	#(448*12*2),d4				;skip first 12 lines of credits background for NTSC
	add.l	#(448*20*2),d1				;data starts at line 20, plus the 12 lines skipped by object header for a total of 32
	move.l	d1,d2
	add.l	#(448*240*2),d2			;only need to do 240 lines for NTSC
.50:
	move.l	d4,c_scr+O_DATA
	bsr		do_cross					;needs D0,D1,D2 set
	bra.b	.80
.70:
	bsr		animcred				;make credit tiles scale and change when necessary
.80:
	lea		credobjs,a1			;address of first object header
	moveq	#CREDIT_OBJS,d6		;total objects in list
	lea		olist_ram,a2
	bsr		build				;build packed object list

	bsr		input
	bsr		crdinput				;input specific to credits screen

	rts


gocredit::
	lea		cinfntsc,a0
	cmp.b	#NTSC,pal_ntsc
	beq.b	.10
	lea		cinf_pal,a0
.10:
	move.w	(a0)+,c_scr+O_YPOS
	move.w	(a0)+,c_scr+O_HEIGHT
	move.l	(a0)+,c_scr+O_DATA
	move.w	(a0),d0					;ypos for credit tiles
	lea		c_sign0,a0				;first credit tile object
	moveq	#CREDIT_TILES-1,d6			;total credit tile objects - 1
.30:	move.w	d0,O_YPOS(a0)				;set ypos for each credit tile
	adda.l	#OBJ_SIZE,a0
	dbra		d6,.30
	move.w	#SIGN_X,c_sign0+O_XPOS		;xpos for left tile
	move.l	#$00202000,c_sign0+O_SCALE	;minimum horiz scale size for left tile
	bsr		settiles

	move.w	#CREDITS_MODE,gamemode

	bsr		ld_decmp
	bsr		load_q85

	lea		credbkg,a0			;table with decompression info
	moveq	#1,d0				;number of objects to decompress
	bsr		dodecomp

	moveq	#0,d0
	move.w	d0,ctxtcnt			;reset counter for credits text
	move.w	d0,ctxtnum			;which billboard is being displayed
	move.l	d0,crosscnt

	bsr		clrctxt
	move.l	credstrs,a0			;use first address in credstrs table
	move.l	#$00040002,d5			;Y,X position
	bsr		blitctxt				;draw text into buffer
	bsr		copycred				;copy pieces of text buffer into tiles

	lea		cross,a0				;starting address of cross.bin
	bsr		load_gpu
	rts	

cinf_pal::
	dc.w		P_SCRN_TOP				;c_scr+O_YPOS
	dc.w		287						;c_scr+O_HEIGHT
	dc.l		backgr0					;c_scr+O_DATA
.if 0
	dc.w		P_SCRN_TOP+74				;ypos for all credit tiles
.else
	dc.w		P_SCRN_TOP+128
.endif
cinfntsc::
	dc.w		N_SCRN_TOP				;c_scr+O_YPOS
	dc.w		240						;c_scr+O_HEIGHT
	dc.l		backgr0+(12*896)			;c_scr+O_DATA
	dc.w		N_SCRN_TOP+108				;ypos for all credit tiles

crdinput::
	move.l	joybothe,d0
	btst.l	#KEY_6,d0
	bne		gohiscor

	move.l	joybothe,d0
	and.l	#ANY_FIRE,d0
	beq.b	.90
	move.b	#1,keepmus					;don't restart music
	bra		gotitle						;any fire button goes to title screen
.90:	rts

animcred::
	addq.w	#1,ctxtcnt						;increase timer
	cmp.w	#SHRINK_TIME,ctxtcnt
	bge.b	.10
	cmp.b	#$20,c_sign0+O_HSCALE
	beq		.90								;exit if at full horiz size
	addq.b	#$01,c_sign0+O_HSCALE				;increase horiz size until at full size
	move.b	c_sign0+O_HSCALE,d0
	and.b	#1,d0
	bne.b	.90								;move left every other size increase
	subq.w	#1,c_sign0+O_XPOS
	bra.b	.90
.10:	cmp.b	#0,c_sign0+O_HSCALE
	beq.b	.20								;if at minimum size, go to next sign
	subq.b	#$01,c_sign0+O_HSCALE				;decrease horiz size
	move.b	c_sign0+O_HSCALE,d0
	and.b	#1,d0
	bne.b	.90								;move right every other size decrease
	addq.w	#1,c_sign0+O_XPOS
	bra.b	.90
.20:	move.w	#0,ctxtcnt						;reset timer
	addq.w	#1,ctxtnum						;next sign
	cmp.w	#TOTAL_CREDITS,ctxtnum
	blt.b	.30
	bra		gohiscor							;when credits are finished, go to high score screen
.30:
	bsr		clrctxt							;clear the text window
	move.w	ctxtnum,d0
	lsl.w	#2,d0
	lea		credstrs,a1
	move.l	(a1,d0.w),a0						;get address of string to print
	move.l	#$00070002,d5						;Y,X position for string
	bsr		blitctxt							;draw into text buffer
	bsr		copycred							;copy into separate pieces
.90:
settiles::
	move.w	c_sign0+O_XPOS,d1
	lea		c_sign0,a0						;first credit tile object
	moveq	#CREDIT_TILES-1,d6					;total credit tile objects - 1
.50:	move.w	d1,O_XPOS(a0)
	move.l	c_sign0+O_SCALE,O_SCALE(a0)
	add.w	#32,d1							;add width of 1 tile to X position
	adda.l	#OBJ_SIZE,a0
	dbra		d6,.50
	rts

copycred::
	move.l	#credtext,A2_BASE					;source address
	move.l	#PITCH1|PIXEL32|WID8|XADDPHR,A1_FLAGS	;description of destination area
	move.l	#PITCH1|PIXEL32|WID56|XADDPHR,A2_FLAGS	;description of source data
	move.l	#$0001FFF8,d0						;1 in Y step, negative width in X step size
	move.l	d0,A1_STEP
	move.l	d0,A2_STEP

	moveq	#CREDIT_TILES-1,d0
	lea		credaddr,a0
	moveq	#0,d1							;Y,X position in source
.10:
	move.l	(a0)+,A1_BASE						;destination address
	move.l	d1,A2_PIXEL						;Y,X in source
	move.l	#$00000000,A1_PIXEL					;Y,X in destination
	move.l	#$00570008,B_COUNT					;height, width of source image
	move.l	#UPDA1|UPDA2|SRCEN|LFU_A|LFU_AN,B_CMD	;turn on blitter
	add.w	#$0008,d1							;move to next piece X position
	dbra		d0,.10
	rts
credaddr::
	dc.l		credsgn0,credsgn1,credsgn2,credsgn3,credsgn4,credsgn5,credsgn6

clrctxt::
;erase whole credit window
	move.l	#PITCH1|PIXEL32|WID56|XADDPHR,A1_FLAGS	;destination
	move.l	#credtext,A1_BASE					;destination address
	move.l	#$0001FFC8,A1_STEP					;high = Y step, low = negative width
	move.l	#$00570038,B_COUNT					;high = height, low = width
	moveq	#0,d0
	move.l	d0,A1_PIXEL						;set rectangle Y,X
	move.l	d0,B_PATD
	move.l	d0,B_PATD+4
	move.l	#PATDSEL|UPDA1,B_CMD				;turn on blitter
	rts

blitctxt::
;A0 = address of string to print
	lea		letaddr,a5
	move.l	#credtext,A1_BASE					;destination address
	move.l	#PITCH1|PIXEL8|WID224|XADDPIX,A1_FLAGS	;description of destination area
	move.l	#PITCH1|PIXEL8|XADDPIX,A2_FLAGS		;description of source data
	lea		let_wid,a6						;width of each character for spacing
	lea		let_ht,a3							;height for blitter
	lea		let_wd,a4							;width for blitter
	clr.l	d1					;used for width of each character
	move.l	#$00010000,d2			;set Y step to 1
.10:
	move.w	#2,d5				;set left margin, leave Y position in high word
.20:
	clr.l	d0
	move.b	(a0)+,d0				;get the character
	beq.b	.90
	cmp.b	#']',d0				;return
	bne.b	.30
	add.l	#$00140000,d5			;move down 1 line
	bra.b	.10					;reset left margin
.30:	sub.b	#' ',d0				;address and width tables start with this character
	move.w	d0,d4
	lsl.w	#2,d0				;4 bytes per character address
	move.l	(a5,d0.w),A2_BASE		;address of current character data
	beq.b	.50					;if 0, it is some blank space
	clr.l	d3
	move.b	(a3,d4.w),d3			;get height for this character
	swap		d3					;move height to high word
	move.b	(a4,d4.w),d3			;get width for this character
	move.l	d3,B_COUNT			;height, width for this character
	neg.w	d3					;make the width negative
	move.w	d3,d2				;combine X step with Y step of 1
	move.l	d2,A1_STEP			;Y step, negative width
	move.l	#0,A2_PIXEL					;start at 0,0 of source image
	move.l	d5,A1_PIXEL					;Y,X position to write data in destination area
	move.l	#UPDA1|SRCEN|LFU_A|LFU_AN,B_CMD	;turn on blitter
.50:	move.b	(a6,d4.w),d1			;get width of this character
	add.l	d1,d5				;add width of character
	bra.b	.20
.90:	rts


letaddr::
	dc.l		0,0,0,0,0,0,0,0,0,0
	dc.l		0,0,0,0,let_per,0
	dc.l		0,0,0,0,0,0,0,0,0,0
	dc.l		0,0,0,0,0,0,0
	dc.l		let_A,let_B,let_C,let_D,let_E,let_F,let_G,let_H,let_I,let_J,let_K,let_L,let_M
	dc.l		let_N,let_O,let_P,let_Q,let_R,let_S,let_T,let_U,let_V,let_W,let_X,let_Y,let_Z
	dc.l		0,0,0,0,0,0
	dc.l		let_a,let_b,let_c,let_d,let_e,let_f,let_g,let_h,let_i,let_j,let_k,let_l,let_m
	dc.l		let_n,let_o,let_p,let_q,let_r,let_s,let_t,let_u,let_v,let_w,let_x,let_y,let_z

let_wid::
;width of each character used for spacing
;			    !  "  #  $  %  &  '  (  )
	dc.b		14, 1, 2, 4, 8,16, 0, 0, 0, 0
;			 *  +  ,  -  .  /
	dc.b		 0, 0, 0, 0, 6, 0
	dc.b		 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	dc.b		 0, 0, 0, 0, 0, 0, 0
	dc.b		14,14,14,14,14,13,15,14, 6,11,15,13,16
	dc.b		14,16,13,16,14,14,13,14,14,18,14,14,13
	dc.b		 0, 0, 0, 0, 0, 0
	dc.b		12,13,12,12,12, 8,12,12, 6, 6,12, 6,17
	dc.b		12,13,13,12, 9,12, 8,12,12,16,12,12,11
	.even
let_ht::
;height of each character used for B_COUNT
	dc.b		 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	dc.b		 0, 0, 0, 0,14, 0
	dc.b		 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	dc.b		 0, 0, 0, 0, 0, 0, 0
	dc.b		14,14,15,14,14,14,15,14,14,15,14,14,14
	dc.b		14,15,14,15,14,15,14,15,14,14,14,14,14
	dc.b		 0, 0, 0, 0, 0, 0
	dc.b		15,15,15,15,15,14,18,14,14,18,14,14,14
	dc.b		14,15,18,18,14,15,15,15,14,14,14,18,14
let_wd::
;width of each character used for B_COUNT
	dc.b		 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	dc.b		 0, 0, 0, 0, 8, 0
	dc.b		 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	dc.b		 0, 0, 0, 0, 0, 0, 0
	dc.b		16,16,16,16,16,16,16,16, 8,16,16,16,16
	dc.b		16,16,16,16,16,16,16,16,16,16,16,16,16
	dc.b		 0, 0, 0, 0, 0, 0
	dc.b		16,16,16,16,16, 8,16,16, 8, 8,16, 8,16
	dc.b		16,16,16,16, 8,16, 8,16,16,16,16,16,16

	.even
credstrs::
	dc.l		cred00,cred01,cred02,cred03,cred04,cred05,cred06a,cred06b,cred07,cred08,cred09
cred00::
	dc.b		'$     Lead]'
	dc.b		'$#"  Programmer]'
	dc.b		']'
	dc.b		'$" TODD POWERS'
	dc.b		0
cred01::
	dc.b		'$  Programmers]'
	dc.b		']'
	dc.b		'$"!  ERIC SMITH]'
	dc.b		'#!  ERIC GINNER'
	dc.b		0
cred02::
	dc.b		'!    Producers]'
	dc.b		']'
	dc.b		'$"  CRAIG SUKO]'
	dc.b		'$PURPLE HAMPTON]'
	dc.b		0
cred03::
	dc.b		'!!$#  Lead Artist]'
	dc.b		']'
	dc.b		'#"  ED PEARSON]'
	dc.b		0
cred04::
	dc.b		'!     Artists]'
	dc.b		'$ KEN SAUNDERS]'
	dc.b		'#JEFFREY GATRALL]'
	dc.b		'$   B.J. WEST'
	dc.b		0
cred05::
	dc.b		'"!  Music Director]'
	dc.b		']'
	dc.b		'$ JAMES GRUNKE]'
	dc.b		0
cred06a::
	dc.b		'$"Music and Sound]'
	dc.b		']'
	dc.b		'   M STEVENS]'
	dc.b		'  WILEY EVANS]'
	dc.b		0
cred06b::
	dc.b		'!$"Music and Sound]'
	dc.b		']'
	dc.b		'$ JAMES GRUNKE]'
	dc.b		'$! JERRY GERBER]'
	dc.b		0
cred07::
	dc.b		'#"!  Lead Testers]'
	dc.b		']'
	dc.b		'#  LANCE LEWIS]'
	dc.b		'  DAN MCNAMEE]'
	dc.b		0
cred08::
	dc.b		'#$    Testers]'
	dc.b		']'
	dc.b		'$"  HANK CAPPA]'
	dc.b		'$" SCOTT HUNTER]'
	dc.b		0
cred09::
	dc.b		'#$    Testers]'
	dc.b		']'
	dc.b		'$$ ANDREW KEIM]'
	dc.b		'$#"  JOE SOUSA]'
	dc.b		0

	.even

credolst::
;c_scr::
	dc.w		0			;xpos
	dc.w		0			;ypos
	dc.l		credscr		;data
	dc.w		287			;height
	dc.w		112			;dwidth
	dc.w		112			;iwidth
	dc.b		0			;flags
	dc.b		0			;firstpix
	dc.b		0			;type
	dc.b		4			;depth
	dc.b		1			;pitch
	dc.b		0			;index
	dc.w		0			;desc
	dc.l		$00202020		;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------
;c_sign0::
	dc.w		0,0					;xpos, ypos
	dc.l		credsgn0				;data
	dc.w		87,4,4				;height, dwidth, iwidth
	dc.b		TRANS_ON,0,1,3,1,0		;flags, firstpix, type, depth, pitch, index
	dc.w		0					;desc
	dc.l		$00202020				;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------
;c_sign1::
	dc.w		0,0					;xpos, ypos
	dc.l		credsgn1				;data
	dc.w		87,4,4				;height, dwidth, iwidth
	dc.b		TRANS_ON,0,1,3,1,0		;flags, firstpix, type, depth, pitch, index
	dc.w		0					;desc
	dc.l		$00202020				;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------
;c_sign2::
	dc.w		0,0					;xpos, ypos
	dc.l		credsgn2				;data
	dc.w		87,4,4				;height, dwidth, iwidth
	dc.b		TRANS_ON,0,1,3,1,0		;flags, firstpix, type, depth, pitch, index
	dc.w		0					;desc
	dc.l		$00202020				;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------
;c_sign3::
	dc.w		0,0					;xpos, ypos
	dc.l		credsgn3				;data
	dc.w		87,4,4				;height, dwidth, iwidth
	dc.b		TRANS_ON,0,1,3,1,0		;flags, firstpix, type, depth, pitch, index
	dc.w		0					;desc
	dc.l		$00202020				;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------
;c_sign4::
	dc.w		0,0					;xpos, ypos
	dc.l		credsgn4				;data
	dc.w		87,4,4				;height, dwidth, iwidth
	dc.b		TRANS_ON,0,1,3,1,0		;flags, firstpix, type, depth, pitch, index
	dc.w		0					;desc
	dc.l		$00202020				;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------
;c_sign5::
	dc.w		0,0					;xpos, ypos
	dc.l		credsgn5				;data
	dc.w		87,4,4				;height, dwidth, iwidth
	dc.b		TRANS_ON,0,1,3,1,0		;flags, firstpix, type, depth, pitch, index
	dc.w		0					;desc
	dc.l		$00202020				;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------
;c_sign6::
	dc.w		0,0					;xpos, ypos
	dc.l		credsgn6				;data
	dc.w		87,4,4				;height, dwidth, iwidth
	dc.b		TRANS_ON,0,1,3,1,0		;flags, firstpix, type, depth, pitch, index
	dc.w		0					;desc
	dc.l		$00202020				;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------

