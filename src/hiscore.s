;player 1 uses red cursor
;player 2 uses blue cursor

;set bit 0 in highedit if player 1 is editing a high score name
;set bit 1 in highedit if player 2 is editing a high score name
;highedit = 0 if neither player is editing a name

;A,B,C button exits screen if neither player is editing
;when editing:
;	left, right to edit a different letter
;	up, down, to change the letter
;	A,B,C to stop editing

;**** temporary stuff ****
;9 key goes into editing mode for each player
;1 key moves up one row
;4 key moves down one row
;press 3 key to reset all high scores and initials
;press 6 key on title screen or credits screen to get to high score screen

DEBUGKEYS	EQU	0		; nonzero to include debugging info

	.include	'eq.s'
	.include	'externs.s'
	.include	'3dds.inc'

HEADER_CHECK		equ	'CD'			;write default settings and scores if this is not the first word in the eeprom

END_JOY_DELAY		equ	14			;delay for holding down joypad to change high score names

HIGHINFO_TIME		equ	400			;how long to display each high score billboard
TOTAL_HIGHINFOS	equ	5			;total number of high score billboards

NAME_X			equ	48			;xpos of name letters from left side of text box
SCORE_X			equ	112			;xpos of score numbers
SCORE_Y			equ	25			;ypos of top score

; for "game over" box
GONAME_X			equ	24			;xpos of name letters from left side of text box
GOSCORE_X			equ	88			;xpos of score numbers
GOSCORE_Y			equ	25			;ypos of top score

RANK_Y			equ	7			;ypos of ranking from top of map on dash
RANK_X			equ	3			;xpos of ranking from left side of map on dash

	.text
highloop::
	bsr		animhigh				;do the scaling if necessary
	cmp.w	#TITLE_MODE,gamemode
	beq.b	.90					;exit if it just switched to the title screen
	bsr		setcurs				;set position of cursors for high score names

	lea		highobjs,a1			;address of first object header
	moveq	#HISCORE_OBJS,d6		;total objects in list
	lea		olist_ram,a2
	move.l	a2,listAddr
	bsr		build				;build packed object list

	bsr		input
	bsr		hiinput
.90:	rts

gohiscor::
	move.b	#0,gmovrhs
	bsr		set_hinf				;initialize the objects to be displayed
	add.w	#96,h_text+O_YPOS		;starts at 0 size, will move up 48 pixels as it scales
	add.w	#128,h_text+O_XPOS		;starts at 0 size, will move left 128 pixels as it scales

	moveq	#0,d0
	move.l	d0,h_text+O_SCALE
	move.w	d0,htxtcnt			;reset counter for high score info
	move.w	d0,htxtnum			;which high score info is being displayed
	move.w	d0,curs0row			;row number for player 1 cursor
	move.w	d0,curs0col			;column number for player 1 cursor
	move.w	d0,curs1row			;row number for player 2 cursor
	move.w	d0,curs1col			;column number for player 2 cursor
	move.b	d0,highedit			;not in editing mode
	move.b	d0,joydel0			;reset joypad delay for player 1
	move.b	d0,joydel1			;reset joypad delay for player 2
	move.l	hlists,hilstptr		;set hilstptr to first address in hlists table

	bsr		drawhinf				;draw high score names and numbers

;	move.w	#$4C7,VMODE
	move.w	gamemode,oldgmode
	move.w	#HISCORE_MODE,gamemode
	rts	

; display hi scores at end of game
eoghiscores::
	move.b	#1,gmovrhs
	bsr	drawhinf
	rts

set_hinf::
	lea		cinfntsc,a0
	move.w	#N_SCRN_TOP+106,d1			;h_text+O_YPOS
	move.l	#credscr+(448*12*2),d2
	cmp.b	#NTSC,pal_ntsc
	beq.b	.10
	lea		cinf_pal,a0
;	move.w	#P_SCRN_TOP+106,d1			;h_text+O_YPOS
	move.w	#P_SCRN_TOP+127,d1			;h_text+O_YPOS
	move.l	#credscr,d2
.10:
	move.w	(a0)+,h_scr+O_YPOS
	move.w	(a0)+,h_scr+O_HEIGHT
	move.l	d2,h_scr+O_DATA
	move.w	d1,h_text+O_YPOS			;ypos when at full size
	move.w	#185,h_text+O_XPOS			;xpos when at full size
	rts

gohiedit::
	move.b	#0,gmovrhs
	bsr		clearscr
	move.l	#CONGA_MUSIC,songnum
	bsr		playmus				;start music

	bsr.b		set_hinf		; retail short backward call				;initialize the objects to be displayed
	move.l	#$00202020,h_text+O_SCALE

	bsr		ld_decmp
	bsr		load_q85
	lea		credbkg,a0			;table with decompression info
	moveq	#1,d0				;number of objects to decompress
	bsr		dodecomp
	lea		titlebkg,a0			;table with decompression info
	moveq	#1,d0				;number of objects to decompress
	bsr		dodecomp				;load title screen so cross fade with it can be done

	clr.w	htxtcnt				;reset counter for high score info
	bsr		drawhinf				;draw high score names and numbers

	lea		palette,a0			;get address of palette
	bsr		set_palette			;copy palette into

	move.w	#$4C7,VMODE
	move.w	gamemode,oldgmode
	move.w	#HISCORE_MODE,gamemode

	moveq	#0,d0
	move.w	d0,curs0col			;column number for player 1 cursor
	move.w	d0,curs1col			;column number for player 2 cursor
	move.b	d0,joydel0			;reset joypad delay for player 1
	move.b	d0,joydel1			;reset joypad delay for player 2
	move.l	#stacktop, a7			; re-init stack
	jmp		mainloop
;	rts	

setcurs::
	moveq	#0,d5						;bit 0 set in highedit if player 1 is editing high score name
	lea		curs0row,a3
	lea		curs0col,a4
	lea		cursor0,a1					;player 1 cursor object header
	bsr		curs_xy
;setcurs1
	moveq	#1,d5						;bit 1 set in highedit if player 2 is editing high score name
	lea		curs1row,a3
	lea		curs1col,a4
	lea		cursor1,a1					;player 2 cursor object header
curs_xy::
;a3 = pointer to curs0row or curs1row (for set_letr)
;a4 = pointer to curs0col or curs1col (for set_letr)
;a1 = cursor0 or cursor1 object header
	btst.b	d5,highedit					;bit set if player is editing high score name
	bne.b	.05							;if editing, turn on cursor
.02:	or.b		#DELETE_OBJ,O_TYPE(a1)			;turn off cursor if not editing
	bra.b	.10
.05:	cmp.l	#$00202020,h_text+O_SCALE
	bne.b	.02							;don't turn on cursor until finished scaling
	and.b	#$7F,O_TYPE(a1)				;turn on cursor if editing
.10:
	clr.w	d1
	lea		curs_y,a0						;cursor Y positions for each row
	move.w	(a3),d4						;get row number
	move.b	(a0,d4.w),d1					;get amount to add to text object ypos
	add.w	h_text+O_YPOS,d1
	move.w	d1,O_YPOS(a1)					;set cursor ypos

	bsr		set_letr						;set A5 to letter being edited
	move.w	(a4),d3						;get column number
	and.l	#$FFFF,d3						;clear high word of column number
	sub.l	d3,a5						;go back to first letter in row
	lea		font_wid,a0
	move.w	#185+NAME_X,d2					;starting x position (xpos of text box + NAME_X)
	subq.w	#1,d3						;column number - 1
	bmi.b	.30							;skip adding width for each letter if cursor is at first letter
	clr.w	d1
.20:	move.b	(a5)+,d1						;get letter
	sub.b	#' ',d1
	move.b	(a0,d1.w),d1					;get letter width
	add.w	d1,d2						;add to xpos
	dbra		d3,.20						;continue until at cursor column
.30:
	move.w	d2,O_XPOS(a1)					;set cursor xpos
	rts

curs_y::
;cursor y position for each high score name
;add to text ypos
	dc.b		44
	dc.b		68
	dc.b		92
	dc.b		116
	dc.b		140
	.even

hiinput::
	bsr		hikey
	tst.b	highedit
	bne.b	.10
	move.l	joybothe,d0
	and.l	#ANY_FIRE,d0
	beq.b	.90

	cmp.l	#CONGA_MUSIC,songnum
	beq.b	.05							;go to title screen after all high score lists have been shown
	move.b	#1,keepmus
.05:
	bra		gotitle						;any fire button goes to title screen
.10:

.15:	btst		#0,highedit					;bit for player 1
	beq.b	.20
	bsr		hiedinp0						;input for player 1 editing name
.20:
	btst		#1,highedit					;bit for player 2
	beq.b	.90
	bsr		hiedinp1						;input for player 2 editing name
.90:	rts

hikey::
.if DEBUGKEYS
	move.l	joyedge,d0
	btst.l	#KEY_9,d0
	beq.b	.30
	or.b		#1,highedit					;9 key puts player 1 into editing mode
.30:
	move.l	joyedge2,d0
	btst.l	#KEY_9,d0
	beq.b	.40
	or.b		#2,highedit					;9 key puts player 2 into editing mode
.40:
	move.l	joybothe,d0
	btst.l	#KEY_3,d0
	beq.b	.60
	bsr		sv_defhi						;reset high scores
	bsr		drawhinf						;redraw the scores after they get reset
.60:
.endif
	rts

hiedinp0::
;input while editing high score name
	lea		joyedge,a0
	lea		joycur,a1
	lea		joydel0,a2
	lea		curs0row,a3
	lea		curs0col,a4
	bra.b	doedinp
hiedinp1::
	lea		joyedge2,a0
	lea		joycur2,a1
	lea		joydel1,a2
	lea		curs1row,a3
	lea		curs1col,a4
doedinp::
	move.l	(a0),d0						;get joyedge for player
	and.l	#ANY_JOY,d0
	bne.b	.10							;always accept joyedge
	move.l	(a1),d0
	and.l	#ANY_JOY,d0
	beq		.40
	addq.b	#1,(a2)						;add to joydel counter
	cmp.b	#END_JOY_DELAY,(a2)
	blt		.40							;only accept joycur if delay has been long enough
	move.b	#0,(a2)						;reset joydel counter
	move.l	(a1),d0
	bra.b	.12
.10:
	move.b	#0,(a2)						;reset joydel counter
	move.l	(a0),d0						;get joyedge for player
.12:
	btst.l	#JOY_LEFT,d0
	beq.b	.15
	cmp.w	#0,(a4)						;see if column number is at minimum
	beq.b	.15
	subq.w	#1,(a4)						;move left one column
	bra.b	.20
.15:
	btst.l	#JOY_RIGHT,d0
	beq.b	.20
	cmp.w	#2,(a4)						;see if column number is at maximum
	beq.b	.20
	addq.w	#1,(a4)						;move right one column
.20:
	btst.l	#JOY_UP,d0
	beq.b	.30
	bsr		letr_up						;change the letter being edited
	bra.b	.40
.30:
	btst.l	#JOY_DOWN,d0
	beq.b	.40
	bsr		letr_dn						;change the letter being edited
.40:
	move.l	(a0),d0						;get joyedge for player
	and.l	#ANY_FIRE,d0
	beq.b	.45
	move.b	highedit,d1
	cmpa.l	#joyedge,a0					;see which player this is
	bne.b	.42
	bclr		#0,d1						;clear bit for player 1 editing
	bra.b	.43
.42:	bclr		#1,d1						;clear bit for player 2 editing
.43:
	move.b	d1,highedit
	cmp.b	#0,d1
	bne.b	.60							;if a player is still editing, don't save scores yet
	move.w	htxtnum,d0					;update scores in eeprom when both players are finished editing
	lea		hs_eebeg,a1
	clr.l	d1
	move.b	(a1,d0.w),d1					;offset for eeprom, start writing scores here
	move.l	hilstptr,a0					;get address of scores to save
	bra		pack_scr						;A0 = score list, D1 = eeprom start offset
.45:
.if DEBUGKEYS
	move.l	(a0),d0						;get joyedge for player
	btst.l	#KEY_1,d0
	beq.b	.50
	subq.w	#1,(a3)						;move up one row
	cmp.w	#-1,(a3)						;check row number
	bne.b	.60
	move.w	#TOTAL_HI_SCORES-1,(a3)
.50:
	btst.l	#KEY_4,d0
	beq.b	.60
	addq.w	#1,(a3)						;move down one row
	cmp.w	#TOTAL_HI_SCORES,(a3)
	bne.b	.60
	move.w	#0,(a3)
.endif
.60:
	rts

letr_dn::
	moveq	#'A',d2				;letter after space
	moveq	#'Z',d3				;letter before space
	dc.w	$183C,$FFFF			;retail opcode for MOVE.B #-1,D4; original assembler sign-extends immediate
	bra.b	new_letr
letr_up::
	move.b	#'Z',d2				;letter after space
	move.b	#'A',d3				;letter before space
	move.b	#1,d4				;move forward one letter
new_letr::
	bsr		set_letr				;set A5 to the letter being edited
	cmp.b	(a5),d2				;letter before space
	bne.b	.10
	move.b	#' ',(a5)				;go from a letter to space
	bra.b	redrwnam
.10:	cmp.b	#' ',(a5)
	bne.b	.30
	move.b	d3,(a5)				;go from space to a letter
	bra.b	redrwnam
.30:	add.b	d4,(a5)				;add 1 or -1 to move to next letter
redrwnam::
	move.w	(a3),d6				;get row number
	movem.l	a0-a4,-(sp)
	bsr		blitname				;draw name again
	movem.l	(sp)+,a0-a4
	rts

set_letr::
;set A5 to the letter that is being edited
	move.l	hilstptr,a5		;get address of current scores and names
	adda.l	#4,a5			;skip 4 bytes of score, start at name
	clr.l	d1
	move.w	(a3),d1			;need row number * 8 bytes per score
	lsl.w	#3,d1			;multiply row number by 8
	add.l	d1,a5			;set pointer to beginning of current name
	move.w	(a4),d1			;get column number
	add.l	d1,a5			;move to the current letter
	rts

animhigh::
	cmp.l	#$00202020,h_text+O_SCALE
	bne.b	.05							;continue anim count during scaling
	cmp.b	#0,highedit					;1 if editing high score name
	bne		.90							;don't change counter if either player is editing
.05:	addq.w	#1,htxtcnt
	cmp.w	#HIGHINFO_TIME,htxtcnt			;time limit for each screen
	bge.b	.10							;if > highinfo time, increase size until full size
	cmp.l	#$00202020,h_text+O_SCALE
	beq		.90							;exit if at maximum size
	add.l	#$00010101,h_text+O_SCALE		;increase size
	subq.w	#4,h_text+O_XPOS				;adjust position to make it look like scaling from center
	subq.w	#3,h_text+O_YPOS				;adjust position to make it look like scaling from center
	bra		.90
.10:	cmp.b	#0,h_text+O_HSCALE				;minimum size
	beq.b	.20							;if at minimum size, draw new names and scores
	sub.l	#$00010101,h_text+O_SCALE		;decrease size
	addq.w	#4,h_text+O_XPOS				;adjust position to make it look like scaling from center
	addq.w	#3,h_text+O_YPOS				;adjust position to make it look like scaling from center
	bra.b	.90
.20:
	cmp.w	#PLAY_MODE,oldgmode
	beq.b	.25							;go to title screen after coming here from a game
	clr.w	htxtcnt						;reset timer
	addq.w	#1,htxtnum					;next high score list
	cmp.w	#TOTAL_HIGHINFOS,htxtnum
	blt.b	.30
.25:
	cmp.l	#CONGA_MUSIC,songnum
	beq		gotitle						;go to title screen after all high score lists have been shown
	move.b	#1,keepmus					;don't restart music if conga music is already playing
	bra		gotitle
.30:
	lea		hlists,a0						;list of high score screens
	move.w	htxtnum,d0					;current screen being displayed
	lsl.w	#2,d0
	move.l	(a0,d0.w),hilstptr				;get address of scores and names
	bsr		drawhinf						;draw new names and scores while at 0 size
.90:	rts

drawhinf::
	tst.b	gmovrhs						; is this an end of game hi score?
	bne	.gameovr					; if so, set things up differently

	move.l	#PITCH1|PIXEL8|WID224|XADDPHR,A1_FLAGS	;destination
	move.l	#hitxtdta,A1_BASE					;destination address
	move.l	#$0001FF20,A1_STEP					;high = Y step, low = negative width
	move.l	#$005700E0,B_COUNT					;high = height, low = width
	moveq	#0,d0
	move.l	d0,A1_PIXEL						;set rectangle Y,X
	move.l	d0,B_PATD							;write 0's to clear the screen
	move.l	d0,B_PATD+4
	move.l	#PATDSEL|UPDA1,B_CMD				;turn on blitter

	lea		fontaddr,a5
	lea		font_wid,a6
	move.l	#PITCH1|PIXEL8|WID224|XADDPIX,A1_FLAGS	;description of destination area
	move.l	#PITCH1|PIXEL8|XADDPIX,A2_FLAGS		;description of source data
	bra	.drawtitle

.gameovr:
	move.l	#PITCH1|PIXEL16|WID160|XADDPHR,A1_FLAGS	;destination
	move.l	#PAUSECRY,A1_BASE					;destination address
	move.l	#$0001FF60,A1_STEP					;high = Y step, low = negative width
	move.l	#$006800A0,B_COUNT					;high = height, low = width
	moveq	#0,d0
	move.l	d0,A1_PIXEL						;set rectangle Y,X
	move.l	d0,B_PATD							;write 0's to clear the screen
	move.l	d0,B_PATD+4
	move.l	#PATDSEL|UPDA1,B_CMD				;turn on blitter to clear area

	move.l	#PITCH1|PIXEL16|WID160|XADDPIX,A1_FLAGS	;description of destination area
	move.l	#PITCH1|PIXEL16|XADDPIX,A2_FLAGS		;description of source data
	lea	f16addr,a5
	lea	f16_wid,a6

.drawtitle:
;draw title on billboard

	move.l	#$0001FFF8,A1_STEP					;1 in Y step, negative width in X step size

	move.w	htxtnum,d0			;which billboard is being displayed
	lsl.w	#2,d0
	lea		htitles,a1
	move.l	(a1,d0.w),a0			;get address of string to print
	lea		httlpos,a1
	tst.b	gmovrhs
	beq.b	.billboard
		lea	eoghttl,a1
.billboard:
	move.l	(a1,d0.w),d5			;Y,X position of title
	move.w	d5,d6				;save left margin in d6
	clr.l	d1					;used for width of each character
.01:
	clr.l	d0
	move.b	(a0)+,d0				;get the character
	beq	.04					;finished with title if 0
	cmp.b	#']',d0				;return
	bne.b	.02
	add.l	#$000A0000,d5			;move down 1 line
	move.w	d6,d5				;reset X pos to left margin
	bra.b	.01					;reset left margin
.02:	sub.b	#' ',d0				;the first valid character
	move.b	(a6,d0.w),d1			;get width of this character
	lsl.w	#2,d0				;4 bytes per character address
	move.l	(a5,d0.w),A2_BASE		;address of current character data
	beq.b	.03
	bsr		blit_chr
.03:	add.l	d1,d5				;add width of character
	bra.b	.01


.04:
	moveq	#0,d6
.08:	bsr		blitname
	addq.w	#1,d6
	cmp.w	#TOTAL_HI_SCORES,d6
	blt.b	.08

	clr.w	d6								;count scores
	move.l	#(SCORE_Y*$10000)+SCORE_X,d5			;Y,X position of first score
	tst.b	gmovrhs
	beq.b	.09
	move.l	#(GOSCORE_Y*$10000)+GOSCORE_X,d5		;game over scores are in a different place
.09:

	move.l	hilstptr,a0			;get address of current scores and names
.10:
	bsr		draw_hi				;draw 1 name and 1 score
	add.l	#$000C0000,d5			;move down 1 line
	move.w	#SCORE_X,d5			;reset X position, leave Y position alone in high word
	tst.b	gmovrhs
	beq.b	.11
	move.w	#GOSCORE_X,d5
.11:
	adda.l	#8,a0				;move to next score
	addq.w	#1,d6
	cmp.w	#TOTAL_HI_SCORES,d6
	blt.b	.10
	rts

drawrank::
;A0 = prevscr0 or prevscr1

.00:	move.l	B_CMD,d7
	btst.l	#0,d7
	beq.b	.00								;wait until blitter is finished

;replace the level map with the rank sign
	move.l	#PITCH1|PIXEL32|WID48|XADDPHR,d0
	move.l	d0,A1_FLAGS						;destination
	move.l	d0,A2_FLAGS						;source
	move.l	#mapWorld,A1_BASE					;destination address
	move.l	#rankbox,A2_BASE					;source address
	move.l	#$0001FFD0,d0
	move.l	d0,A1_STEP						;high = Y step, low = negative width
	move.l	d0,A2_STEP						;high = Y step, low = negative width
	move.l	#$00180030,B_COUNT					;96 x 24, 16 bit
	moveq	#0,d0
	move.l	d0,A1_PIXEL						;set rectangle Y,X
	move.l	d0,A2_PIXEL						;set rectangle Y,X
	move.l	#UPDA1|UPDA2|SRCEN|LFU_A|LFU_AN,B_CMD	;turn on blitter

.01:	move.l	B_CMD,d7
	btst.l	#0,d7
	beq.b	.01								;wait until blitter is finished

;erase the dots on the dash
	move.l	#PITCH1|PIXEL8|WID320|XADDPHR,A1_FLAGS	;use phrase mode
	move.l	#PITCH1|PIXEL8|WID80|XADDPHR,A2_FLAGS	;use phrase mode
	move.l	#dash,A1_BASE						;destination address
	move.l	#$0001FFB0,d0
	move.l	d0,A1_STEP						;Y step = 1, X step = negative width
	move.l	d0,A2_STEP						;Y step = 1, X step = negative width
	move.l	#$00030070,A1_PIXEL					;Y,X position
	moveq	#0,d0
	move.l	d0,B_PATD
	move.l	d0,B_PATD+4
	move.l	#$00180050,B_COUNT					;80 x 24, 8 bit
	move.l	#PATDSEL|UPDA1|UPDA2,B_CMD			;settings to start the blitter

.02:	move.l	B_CMD,d7
	btst.l	#0,d7
	beq.b	.02								;wait until blitter is finished

	move.l	#mapWorld,A1_BASE					;destination address
	lea		f16addr,a5						;use 16 bit font
	move.l	#PITCH1|PIXEL16|WID96|XADDPIX,A1_FLAGS	;description of destination area
	move.l	#PITCH1|PIXEL16|XADDPIX,A2_FLAGS		;description of source data
	move.l	#$0001FFF8,A1_STEP					;1 in Y step, negative width in X step size
	move.l	#0,A1_FPIXEL

	moveq	#0,d0
	move.l	d0,B_PATD							;the color that will not be written if found in the source data
	move.l	d0,B_PATD+4						;the color that will not be written if found in the source data

	move.l	#(RANK_Y*$10000)+RANK_X,d5		;Y,X position for rank
	move.w	d5,d6				;save left margin
	lea		rankplr0,a2			;assume that rank for player 1 will be displayed
	cmp.l	#prevscr0,a0
	beq.b	.20
	lea		rankplr1,a2			;show rank for player 2
.20:
	lea		rankstrs,a1
	move.w	(a2),d0				;get rank number
	lsl.w	#2,d0
	move.l	(a1,d0.w),a0			;get the rank to print
	clr.l	d1
	lea		f16_wid,a6			;widths for 16 bit font
.30:
	move.l	B_CMD,d7
	btst.l	#0,d7
	beq.b	.30					;wait until blitter is finished
.35:
	clr.l	d0
	move.b	(a0)+,d0				;get the character
	beq.b	.60					;finished with title if 0
	cmp.b	#']',d0				;return
	bne.b	.40
	add.l	#$00080000,d5			;move down 1 line
	move.w	d6,d5				;reset X pos to left margin
	bra.b	.35
.40:	sub.b	#' ',d0				;the first valid character
	move.b	(a6,d0.w),d1			;get width of this character
	lsl.w	#2,d0				;4 bytes per character address
	move.l	(a5,d0.w),A2_BASE		;address of current character data
	beq.b	.50

	move.l	#0,A2_PIXEL					;start at 0,0 of source image
	move.l	d5,A1_PIXEL					;Y,X position to write data in destination area
	move.l	#$00070008,B_COUNT				;height, width of source image
	move.l	#UPDA1|SRCEN|LFU_A|LFU_AN|DCOMPEN,B_CMD		;start blitter

.50:	add.l	d1,d5				;add width of character
	bra.b	.30
.60:
	rts

draw_hi::
;d5 is set to X,Y position
;A0 is the address of the score to convert
	lea		high_dec,a1
	move.l	(a0),d0				;get time to convert
	divu		#18000,d0				;divide by 3, then 6000 to get minutes
	move.l	d0,d1
	swap		d1
	and.l	#$FFFF,d1
	and.l	#$FFFF,d0
	divu		#10,d0
	add.b	#'0',d0
	move.b	d0,(a1)+				;tens digit for minutes
	swap		d0
	add.b	#'0',d0
	move.b	d0,(a1)+				;ones digit for minutes

	move.b	#':',(a1)+

	move.l	d1,d0				;get remainder
	divu		#300,d0				;divide by 3, then 100 to get seconds
	move.l	d0,d1
	swap		d1
	and.l	#$FFFF,d1
	and.l	#$FFFF,d0
	divu		#10,d0
	add.b	#'0',d0
	move.b	d0,(a1)+				;tens digit for seconds
	swap		d0					;get the remainder
	add.b	#'0',d0
	move.b	d0,(a1)+				;ones digit for seconds

	move.b	#'.',(a1)+

	divu		#30,d1				;divide remainder by 3, then 10 to get tenths of seconds
	add.b	#'0',d1
	move.b	d1,(a1)				;tenths of seconds

;now high_dec bytes are set to XX:XX.X
;find the first digit that is not 0 so leading 0's are not displayed
	lea		high_dec,a3			;first decimal score digit
.40:	cmp.b	#'1',(a3)				;see if this digit is 1-9
	blt.b	.50
	cmp.b	#'9'+1,(a3)
	blt.b	.60					;this is the first non zero digit, so start printing digits
	bra.b	.55					;skip colon
.50:	add.l	#$00000005,d5
.55:	add.l	#$00000004,d5			;move starting x position to next digit
	adda.l	#1,a3				;point to next score digit
	cmpa.l	#high_dec+HISCORE_DIGITS+2-1,a3	;see if we're at the last digit
	bne.b	.40					;if score is 0, print the last digit
.60:								;now d5 is X,Y of first digit to print, a3 points to first digit
	tst.b	gmovrhs
	bne.b	.65
	lea		fontaddr,a5
	lea		font_wid,a6
	bra.b	.69
.65:
	lea		f16addr,a5
	lea		f16_wid,a6
.69:
	clr.l	d1
.70:	clr.l	d0
	move.b	(a3)+,d0				;get digit, increase pointer
	sub.b	#' ',d0
	bne.b	.75
	add.l	#$00000009,d5			;just move over to make a space
	bra.b	.80
.75:	move.b	(a6,d0.w),d1			;get width of this character
	lsl.w	#2,d0				;4 bytes per character address
	move.l	(a5,d0.w),A2_BASE		;address of current character data
	bsr		blit_chr
	add.l	d1,d5				;add width of character
.80:	cmpa.l	#high_dec+HISCORE_DIGITS+2,a3		;numbers, colon, decimal point
	bne.b	.70
	rts

name_y::
;Y,X position of high score names within text window
	dc.l		($19*$10000)+NAME_X
	dc.l		($25*$10000)+NAME_X
	dc.l		($31*$10000)+NAME_X
	dc.l		($3D*$10000)+NAME_X
	dc.l		($49*$10000)+NAME_X
goname_y:
;Y,X position of high score names within game over window
	dc.l		($19*$10000)+GONAME_X
	dc.l		($25*$10000)+GONAME_X
	dc.l		($31*$10000)+GONAME_X
	dc.l		($3D*$10000)+GONAME_X
	dc.l		($49*$10000)+GONAME_X

blitname::
;d6 = row number for name to print
	clr.l	d0
	move.w	d6,d0
	lsl.w	#2,d0
	tst.b	gmovrhs
	bne.b	.govr1
	lea		name_y,a1
	move.l	(a1,d0.w),d5
	move.l	#hitxtdta,A1_BASE					;destination address
	move.l	#PITCH1|PIXEL8|WID224|XADDPHR,A1_FLAGS	;destination
	bra	.doit1
.govr1:
	lea		goname_y,a1
	move.l	(a1,d0.w),d5
	move.l	#PAUSECRY,A1_BASE					;destination address
	move.l	#PITCH1|PIXEL16|WID160|XADDPHR,A1_FLAGS	;destination
.doit1:
	move.l	d5,d4							;get name Y,X position
	and.w	#$F8,d4							;phrase align x position for erasing each name
	move.l	d4,A1_PIXEL						;get rectangle Y,X
	move.l	#$0001FFD0,A1_STEP					;high = Y step, low = negative width
	move.l	#$00070030,B_COUNT					;high = height, low = width
	moveq	#0,d7
	move.l	d7,B_PATD							;write 0's to clear
	move.l	d7,B_PATD+4
	move.l	#PATDSEL|UPDA1,B_CMD				;turn on blitter


	tst.b	gmovrhs
	bne.b	.govr2
	lea		fontaddr,a5						;data addresses for each font character
	lea		font_wid,a6
	move.l	#PITCH1|PIXEL8|WID224|XADDPIX,A1_FLAGS	;description of destination area
	move.l	#PITCH1|PIXEL8|XADDPIX,A2_FLAGS		;description of source data
	bra.b	.doit2
.govr2:
	lea		f16addr,a5						;data addresses for each font character
	lea		f16_wid,a6
	move.l	#PITCH1|PIXEL16|WID160|XADDPIX,A1_FLAGS	;description of destination area
	move.l	#PITCH1|PIXEL16|XADDPIX,A2_FLAGS		;description of source data

.doit2:
	move.l	#$0001FFF8,A1_STEP					;1 in Y step, negative width in X step size
	move.l	hilstptr,a0			;get address of current scores and names
	adda.l	#4,a0				;skip score, go to name
	lsl.w	#1,d0				;d0 is already name number * 4, need name number * 8
	add.l	d0,a0
	move.l	a0,d4
	addq.l	#3,d4				;maximum number of characters in name
;
; check for a "magic" score+name
; if present, and if we are at the end of game display, we will want to
; "intensify" the hi score
;
	move.l	(a0),d1
	cmp.l	#'AAAA',d1
	bne.b	.nomagic
	tst.b	gmovrhs
	bne.b	.intensify
	move.l	#'AAA ',(a0)			;replace with a default string
	bra.b	.nomagic
.intensify:
	rts
.nomagic:
	clr.l	d1
.10:
	cmp.l	a0,d4				;print 4 characters
	beq.b	.90
	clr.l	d0
	move.b	(a0)+,d0				;get the character
	beq.b	.90
	sub.b	#' ',d0				;the first valid character
	move.b	(a6,d0.w),d1			;get width of this character
	lsl.w	#2,d0				;4 bytes per character address
	move.l	(a5,d0.w),A2_BASE		;address of current character data
	beq.b	.50
	bsr.b	blit_chr
.50:	add.l	d1,d5				;add width of character
	bra.b	.10
.90:
	rts

blit_chr::
;d5 is the top left corner Y,X
;A2_BASE is the address of the image data
;if we are doing end of game hi score display, we want to replace
;$7800 with $7740
	move.l	#0,A2_PIXEL					;start at 0,0 of source image
	move.l	d5,A1_PIXEL					;Y,X position to write data in destination area
	move.l	#$00070008,B_COUNT				;height, width of source image
	tst.b	gmovrhs
	bne.b	.replace
	move.l	#UPDA1|SRCEN|LFU_A|LFU_AN,B_CMD	;turn on blitter
	rts
.replace:
	move.l	#$78007800,B_PATD
	move.l	#$78007800,B_PATD+4
	move.l	#$77707770,B_DSTD
	move.l	#$77707770,B_DSTD+4
	move.l	#UPDA1|SRCEN|LFU_A|LFU_AN|DCOMPEN|BKGWREN,B_CMD	;turn on blitter
	rts

addhiscr::
;set the temp score in the high score list to the previous score
	move.w	#0,showrank				;assume no ranking will be shown
	move.b	#0,gothiscore				;assume no hi score was achieved
	cmp.w	#COLL2PLR,cur_act			;don't use scores from 2 player powerball
	beq		.80
	cmp.w	#TAG2PLR,cur_act			;don't use scores from 2 player tag
	beq		.80
	cmp.w	#RACE2PLR,cur_act			;don't use scores from 2 player race, either
	beq		.80

	move.w	#1,showrank				;show ranking before showing best scores
	move.b	#0,highedit				;initialize to neither player editing
	moveq	#0,d0					;init offset for hlist table
	cmp.w	#COLL1PLR,cur_act
	beq.b	.10						;use first list in hlist table
	addq.w	#1,d0					;move to 2nd score list (the first list for racing)
	add.w	curlevel,d0				;get racing list for current world
.10:
	move.w	d0,htxtnum
	lea		hlists,a1
	lsl.w	#2,d0
	move.l	(a1,d0.w),hilstptr			;get address of score list

	moveq	#-1,d0
	move.l	d0,prevscr0				;initialize to 'don't use this score'
	move.l	d0,prevscr1				;initialize to 'don't use this score'
	lea		prevscr0,a2
	move.l	PLAYER1+CAR_TIMER,d0		;get timer used during the game
	tst.w	twoplayer
	beq.b	.15						;if it was a 1 player game, don't need to check player 2 score
	cmp.l	#PLAYER2,winner
	bne.b	.15						;if player 1 won a two player game, use player 1 score
	lea		prevscr1,a2
	move.l	PLAYER2+CAR_TIMER,d0		;use player 2 score
.15:
	divu		#30,d0					;divide score by 30
	bvc	.17
		move.w	#$ffff,d0				;if an overflow happens, saturate score
.17:
	mulu		#30,d0					;round off score to multiple of 30
	move.l	d0,(a2)					;save previous score
	move.l	hilstptr,a2				;get address of score list
	adda.l	#(TOTAL_HI_SCORES*2)*4,a2	;get address of the temp score for this list ((scores * 2) * 4 bytes for each score)
	move.l	d0,(a2)+					;put previous score in temp position
	move.l	#'AAAA',(a2)				;set initials so the previous score can be found
.20:
	bsr		sort_hi
	move.l	hilstptr,a1				;get address of current list of scores
	moveq	#0,d0					;start checking at first name
	adda.l	#4,a1					;move pointer to first name in score list
.30:	cmp.l	#'AAAA',(a1)				;find the score from the previous game
	beq.b	.40
	addq.w	#1,d0					;next name
	cmp.w	#TOTAL_HI_SCORES,d0			;stop if name is not there or in temp spot
	beq.b	.70
	adda.l	#8,a1					;move pointer to next name
	bra.b	.30
.40:
	move.b	#1,gothiscore				;we got a hi score
	cmp.l	#PLAYER2,winner
	beq.b	.60
	move.w	d0,curs0row
	or.b		#1,highedit				;player 1 editing
	bra.b	.70
.60:
	move.w	d0,curs1row
	or.b		#2,highedit				;player 2 editing
.70:
	bsr		get_rank					;rank the previous score
.80:
	rts

sort_hi::
;hilstptr = address of score list to sort
	clr.w	d0						;flag that is set when order of scores changes during sort
	move.l	hilstptr,a0				;get address of scores and names
	move.l	a0,a6
	suba.l	#8,a6
	moveq	#((TOTAL_HI_SCORES-1)*8),d1	;8 bytes for each score (4 for score, 4 for name)
	adda.l	d1,a0					;set pointer to the next to last score
.30:	move.l	(a0),d2					;get a score
	move.l	8(a0),d3					;get the score after it
	cmp.l	d3,d2					;compare score to the score above it
	beq.b	.50
	bcs.b	.50						;if score above <= score below, leave them alone
	moveq	#1,d0					;set flag
	move.l	d3,(a0)					;move better score 1 spot higher
	move.l	d2,8(a0)					;move score above 1 spot lower
	move.l	4(a0),d5					;get name
	move.l	12(a0),4(a0)				;move name
	move.l	d5,12(a0)
.50:	suba.l	#8,a0					;move pointer up 1 score
	cmpa.l	a6,a0					;see if pointer went past the first score
	bne.b	.30						;if not, keep sorting
	tst.w	d0						;check the flag to see if order changed
	bne.b	sort_hi					;something changed, need to sort again
.90:
	rts

get_rank::
	move.l	prevscr0,d0
	cmp.l	#-1,d0
	beq.b	.50
	bsr		ck_rank					;returns rank number in D7
	move.w	d7,rankplr0
	move.w	#-1,rankplr1				;no ranking for losing player
	rts
.50:	move.l	prevscr1,d0
	cmp.l	#-1,d0
	beq.b	.90
	bsr		ck_rank					;returns rank number in D7
	move.w	d7,rankplr1
	move.w	#-1,rankplr0				;no ranking for losing player
.90:	rts

ck_rank::
;D0 = score from previous game
;returns rank number in d7
	cmp.w	#RACE1PLR,cur_act
	bne.b	.10
	move.w	rac1laps,d1				;divide time by number of laps
	addq.w	#1,d1					;convert index to actual number of laps
	bra.b	.40
.10:
	cmp.w	#RACE2PLR,cur_act
	bne.b	.20
	move.w	rac2laps,d1				;divide time by number of laps
	addq.w	#1,d1					;convert index to actual number of laps
	bra.b	.40
.20:
	cmp.w	#COLL1PLR,cur_act
	bne.b	.45
	move.w	col1dots,d1
	beq.b	.45
	addq.w	#1,d1					;convert index to 5*number of powerballs
	lsl.w	#1,d1					;divide time by index * 2 (comes out to approx. time per 5 dots)
.40:
	divu		d1,d0					;divide time by number of laps
	bvc.b	.43						;if result of division was $FFFF or less, continue
	move.w	#$FFFF,d0					;put in maximum value, so lowest rank will be given
.43:
	and.l	#$FFFF,d0					;clear remainder
.45:
	move.w	htxtnum,d2
	lsl.w	#2,d2
	lea		ranktbls,a0
	move.l	(a0,d2.w),a0
	moveq	#0,d7
.50:	move.l	(a0)+,d1					;get score from rank table
	cmp.l	d1,d0
	bcs.b	.90
	addq.w	#1,d7
	cmp.w	#MAX_RANK-1,d7
	blt.b	.50
.90:	rts

defhighs::
;set the high scores to the defaults
;only if the header is not in the eeprom
;if the first 2 characters in eeprom are HEADER_CHECK, stuff has been saved already
;if not, write the header and default scores into eeprom
	moveq	#EE_HEADER,d1				;offset for eeread
	bsr		eegetw
	cmp.w	#HEADER_CHECK,d0			;check this word
	bne		savedefs					;if it doesn't match, write header and defaults into eeprom

	moveq	#EE_CONTROL,d1				;offset in eeprom
	bsr		eegetw
	move.w	d0,d1
	lsr.w	#8,d1					;move high byte to low byte
	and.w	#7,d0
	cmp.b	#MAX_CONTROL+1,d0			;cont_opt must be 0 - MAX_CONTROL
	blt.b	.20
	moveq	#DEFAULT_CONT,d0
.20:	move.w	d0,cont_opt

	move.w	d1, d0
	and.w	#7,d1
	cmp.b	#MAX_ENGOPT+1,d1			;engoffopt must be 0 - MAX_ENGOPT
	blt.b	.30
	moveq	#DEFAULT_ENGOPT,d1
.30:	move.w	d1,engoffopt

	lsr.w	#4, d0
	cmp.b	#MAX_OPTSPEED+1, d0
	blt.b	.40
		moveq	#DEFAULT_SPEED, d0
.40:	move.w	d0,speedopt

	moveq	#EE_MVOLUME,d1				;offset for eeprom
	bsr		eegetw
	and.w	#$7F,d0					;volume must be 0-127
	move.w	d0,mus_vol
	bsr		set_mvol
	moveq	#EE_SVOLUME,d1				;offset for eeprom
	bsr		eegetw
	and.w	#$7F,d0					;volume must be 0-127
	move.w	d0,snd_vol
	bsr		set_svol

	bsr		unpkscrs					;get the high scores from the eeprom, read into ram
	rts

savedefs::
;if stuff has not been saved in eeprom before, save the defaults
	moveq	#EE_HEADER,d1				;offset for eewrite
	move.w	#HEADER_CHECK,d0			;the header to save
	bsr		eeputw					;write header into eeprom

	bsr.b	sv_defhi					;save the default scores, read into ram

	move.w	#DEFAULT_ENGOPT,engoffopt		;steering setting to save
	move.w	#DEFAULT_SPEED,speedopt		;speed setting to save
	move.w	#DEFAULT_CONT,cont_opt		;controller setting to save
	move.w	#DEFAULT_MVOL,mus_vol		;music volume to save
	move.w	#DEFAULT_SVOL,snd_vol
	bsr		save_opt
	bsr		set_mvol
	bsr		set_svol
	rts

sv_defhi::
;compress and save the default scores and names
	lea		pbscrdef,a0				;default high scores for powerballs
	moveq	#EE_PBSCORE_START,d1		;start writing scores here
	bsr		pack_scr
	lea		r0scrdef,a0				;default high scores for racing
	moveq	#EE_R0SCORE_START,d1		;start writing scores here
	bsr		pack_scr
	lea		r1scrdef,a0				;default high scores for racing
	moveq	#EE_R1SCORE_START,d1		;start writing scores here
	bsr		pack_scr
	lea		r2scrdef,a0				;default high scores for racing
	moveq	#EE_R2SCORE_START,d1		;start writing scores here
	bsr		pack_scr
	lea		r3scrdef,a0				;default high scores for racing
	moveq	#EE_R3SCORE_START,d1		;start writing scores here
	bsr		pack_scr
	lea		rSscrdef,a0				;default high scores for racing
	moveq	#EE_RSSCORE_START,d1		;start writing scores here
	bsr		pack_scr

	bsr		unpkscrs					;get the high scores from the eeprom, read into ram
	rts

savecont:
	moveq	#EE_CONTROL,d1				;offset for eeprom
	move.w	speedopt,d0
	lsl.w	#4, d0					;next nyble
	add.w	engoffopt,d0
	lsl.w	#8,d0					;move to high byte
	add.w	cont_opt,d0				;get control option
	bsr		eeputw
savemvol:
	moveq	#EE_MVOLUME,d1				;offset for eeprom
	move.w	mus_vol,d0				;get music volume
	bra		eeputw
savesvol:
	moveq	#EE_SVOLUME,d1				;offset for eeprom
	move.w	snd_vol,d0				;get sound volume
	bra		eeputw

save_opt::
	moveq	#EE_CONTROL,d1				;offset for control option
	bsr		eegetw
	move.w	speedopt,d2
	lsl.w	#4, d2					;next nyble
	add.w	engoffopt,d2
	lsl.w	#8,d2					;move to high byte
	add.w	cont_opt,d2				;get control option
	cmp.w	d2,d0					;check this word
	beq.b	.10						;don't save it if it didn't change
	bsr.b		savecont
.10:
	moveq	#EE_MVOLUME,d1				;offset for music volume
	bsr		eegetw
	cmp.w	mus_vol,d0				;check this word
	beq.b	.20						;don't save it if it didn't change
	bsr.b		savemvol
.20:
	moveq	#EE_SVOLUME,d1				;offset for sound volume
	bsr		eegetw
	cmp.w	snd_vol,d0				;check this word
	beq.b	.30						;don't save it if it didn't change
	bsr.b		savesvol
.30:	rts

pack_scr::
;A0 = list of scores and names
;D1 = starting word in eeprom
	move.w	d1,d6			;get start offset
	add.w	#10,d6			;end offset is 10 words later
.10:
;packtime
	move.l	(a0)+,d0			;score to write
	divu		#18000,d0			;divide by 3, then 6000 to get minutes
	and.w	#$3F,d0			;6 bits for minutes
	lsl.w	#6,d0			;move over 6 bits
	move.l	d0,d2
	swap		d2				;get remainder
	and.l	#$FFFF,d2
	divu		#300,d2			;divide by 3, then 100 to get seconds
	and.w	#$3F,d2			;6 bits for seconds
	or.w		d2,d0
	lsl.w	#4,d0			;move over 4 more bits
	swap		d2
	and.l	#$FFFF,d2
	divu		#30,d2			;divide remainder by 3, then 10 to get tenths of seconds
	and.b	#$F,d2			;4 bits for tenths of seconds
	or.b		d2,d0
	bsr		eeputw
	bmi.b	.90				;exit if writing error occurs

	addq.w	#1,d1			;go to next word in eeprom
	clr.l	d0
	bsr.b	pack_ltr			;do 1st character in name
	bsr.b	pack_ltr			;do 2nd character in name
	bsr.b	pack_ltr			;do 3rd character in name
	adda.l	#1,a0			;skip last byte in the long for the name
	bsr		eeputw
	bmi.b	.90				;exit if writing error occurs
	addq.w	#1,d1			;go to next word in eeprom
	cmp.w	d6,d1			;compare end to current
	bcs.b	.10
.90:	rts
pack_ltr::
;A0 = address of current character in high score name
;D1 = two words to write in eeprom
	lsl.l	#5,d0			;shift 5 bits to make room for character in name
	move.b	(a0)+,d3			;get character in name
	cmp.b	#' ',d3
	bne.b	.50
	moveq	#26,d3			;must be 0-31
	bra.b	.70
.50:	sub.b	#'A',d3			;must be 0-31
.70:	or.b		d3,d0
	rts

unpkscrs::
	lea		pbhighs,a0				;powerball high scores in ram
	moveq	#EE_PBSCORE_START,d1
	bsr		unpk1lst
	lea		rac0high,a0				;racing high scores in ram
	moveq	#EE_R0SCORE_START,d1
	bsr		unpk1lst
	lea		rac1high,a0				;racing high scores in ram
	moveq	#EE_R1SCORE_START,d1
	bsr		unpk1lst
	lea		rac2high,a0				;racing high scores in ram
	moveq	#EE_R2SCORE_START,d1
	bsr		unpk1lst
	lea		rac3high,a0				;racing high scores in ram
	moveq	#EE_R3SCORE_START,d1
	bsr		unpk1lst
	lea		racShigh,a0				;racing high scores in ram
	moveq	#EE_RSSCORE_START,d1
;	bsr		unpk1lst
unpk1lst::
	move.w	d1,d6					;get start offset
	add.w	#10,d6					;end offset is 10 words later
.20:	bsr		eegetw
;unpack time
	move.b	d0,d5
	and.l	#$F,d5					;4 bits for tenths
	mulu		#30,d5					;tenths * 30
	lsr.w	#4,d0					;shift out the 4 bits for tenths
	move.w	d0,d4
	and.l	#$3F,d4					;6 bits for seconds
	mulu		#300,d4					;seconds * 300
	lsr.w	#6,d0					;shift out the 6 bits for seconds
	move.w	d0,d3
	and.l	#$3F,d3					;6 bits for minutes
	mulu		#18000,d3					;minute * 18000
	add.l	d4,d3					;add seconds to minutes
	add.l	d5,d3					;add tenths to minutes and seconds
	move.l	d3,(a0)					;save the time in the high score list

	addq.w	#1,d1					;next word in eeprom
	bsr		eegetw
	move.w	d0,d2					;save 15 bits of name
	bsr.b	unpckltr					;get 3rd name character
	move.b	d3,6(a0)					;set 3rd character in name
	lsr.l	#5,d2
	bsr.b	unpckltr					;get 2nd name character
	move.b	d3,5(a0)					;set 2nd character in name
	lsr.l	#5,d2
	bsr.b	unpckltr					;get 1st name character
	move.b	d3,4(a0)					;set 1st character in name

	addq.w	#1,d1					;next word in eeprom
	adda.l	#8,a0					;next score and name
	cmp.w	d6,d1					;compare end to current
	bcs.b	.20
	rts

unpckltr::
;D2 = 15 bits for name characters
	move.b	d2,d3					;get the byte with the 5 bits for current character
	and.b	#$1F,d3					;only 5 bits for each name character
	cmp.b	#26,d3					;space character
	bne.b	.20
	moveq	#' ',d3
	rts
.20:	add.b	#'A',d3
.60:	rts

;timer = (minutes * 18000) + (seconds * 300) + (tenths * 30)
pbscrdef::
;default high scores for powerballs (scores must be 0-131071)
	dc.l		(30*18000)+(01*300)+(5*30),	'ATC '
	dc.l		(35*18000)+(00*300)+(0*30),	'EP  '
	dc.l		(40*18000)+(00*300)+(0*30),	'CS  '
	dc.l		(45*18000)+(00*300)+(0*30),	'ABC '
	dc.l		(50*18000)+(00*300)+(0*30),	'DEF '
	dc.l		(55*18000)+(00*300)+(0*30),	'GHI '					;bottom score holds latest score before sorting
r0scrdef::
;default high scores for racing velocity park (scores must be 0-131071)
	dc.l		(30*18000)+(00*300)+(0*30),	'TSP '
	dc.l		(35*18000)+(00*300)+(0*30),	'KES '
	dc.l		(40*18000)+(00*300)+(0*30),	'DDD '
	dc.l		(45*18000)+(00*300)+(0*30),	'BCD '
	dc.l		(50*18000)+(00*300)+(0*30),	'EFG '
	dc.l		(55*18000)+(00*300)+(0*30),	'DJF '					;bottom score holds latest score before sorting
r1scrdef::
;default high scores for racing san francisco (scores must be 0-131071)
	dc.l		(30*18000)+(00*300)+(0*30),	'EG  '
	dc.l		(35*18000)+(00*300)+(0*30),	'JG  '
	dc.l		(40*18000)+(00*300)+(0*30),	'GHI '
	dc.l		(45*18000)+(00*300)+(0*30),	'JKL '
	dc.l		(50*18000)+(00*300)+(0*30),	'JPH '
	dc.l		(55*18000)+(00*300)+(0*30),	'CJG '					;bottom score holds latest score before sorting
r2scrdef::
;default high scores for racing old west (scores must be 0-131071)
	dc.l		(30*18000)+(00*300)+(0*30),	'ERS '
	dc.l		(35*18000)+(00*300)+(0*30),	'BJW '
	dc.l		(40*18000)+(00*300)+(0*30),	'MNO '
	dc.l		(45*18000)+(00*300)+(0*30),	'PQR '
	dc.l		(50*18000)+(00*300)+(0*30),	'CD  '
	dc.l		(55*18000)+(00*300)+(0*30),	'HMK '					;bottom score holds latest score before sorting
r3scrdef::
;default high scores for racing jerome's pad (scores must be 0-131071)
	dc.l		(30*18000)+(00*300)+(0*30),	'JAS '
	dc.l		(35*18000)+(00*300)+(0*30),	'LMN '
	dc.l		(40*18000)+(00*300)+(0*30),	'OPQ '
	dc.l		(45*18000)+(00*300)+(0*30),	'RST '
	dc.l		(50*18000)+(00*300)+(0*30),	'UVW '
	dc.l		(55*18000)+(00*300)+(0*30),	'DM  '					;bottom score holds latest score before sorting
rSscrdef::
;default high scores for racing jerome's pad (scores must be 0-131071)
	dc.l		(30*18000)+(00*300)+(0*30),	'TNT '
	dc.l		(35*18000)+(00*300)+(0*30),	'WOO '
	dc.l		(40*18000)+(00*300)+(0*30),	'MMM '
	dc.l		(45*18000)+(00*300)+(0*30),	'NNN '
	dc.l		(50*18000)+(00*300)+(0*30),	'QQQ '
	dc.l		(55*18000)+(00*300)+(0*30),	'SH  '					;bottom score holds latest score before sorting

;16 bit 8x7 font
f16addr::
	dc.l		f16_sp,0,0,0,0,0,f16_sp,f16_apos,0,0
	dc.l		0,0,f16_com,0,f16_per,0
	dc.l		num16_0,num16_1,num16_2,num16_3,num16_4,num16_5,num16_6,num16_7,num16_8,num16_9
	dc.l		f16_col,0,0,0,0,0,0
	dc.l		f16_a,f16_b,f16_c,f16_d,f16_e,f16_f,f16_g,f16_h,f16_i,f16_j,f16_k,f16_l,f16_m
	dc.l		f16_n,f16_o,f16_p,f16_q,f16_r,f16_s,f16_t,f16_u,f16_v,f16_w,f16_x,f16_y,f16_z
f16_wid::
;			   !  "  #  $  %  &  '  (  )
	dc.b		7, 1, 2, 4, 8,16, 9, 4, 0, 0
	dc.b		0,0,3,0,3,0
	dc.b		8,8,8,8,8,8,8,8,8,8
	dc.b		3,0,0,0,0,0,0
	dc.b		8,8,8,8,8,8,8,8,3,8,8,8,9
	dc.b		9,9,8,9,8,8,7,8,8,9,9,9,9
	.even

;8 bit 8x7 font
fontaddr::
	dc.l		fnt_sp,0,0,0,0,0,fnt_sp,fnt_apos,0,0
	dc.l		0,0,fnt_com,0,fnt_per,0
num_addr::
	dc.l		num0,num1,num2,num3,num4,num5,num6,num7,num8,num9
	dc.l		fnt_col,0,0,0,0,0,0
	dc.l		fnt_a,fnt_b,fnt_c,fnt_d,fnt_e,fnt_f,fnt_g,fnt_h,fnt_i,fnt_j,fnt_k,fnt_l,fnt_m
	dc.l		fnt_n,fnt_o,fnt_p,fnt_q,fnt_r,fnt_s,fnt_t,fnt_u,fnt_v,fnt_w,fnt_x,fnt_y,fnt_z
font_wid::
;			   !  "  #  $  %  &  '  (  )
	dc.b		8, 1, 2, 4, 8,16, 9, 5, 0, 0
	dc.b		0,0,4,0,4,0
	dc.b		9,9,9,9,9,9,9,9,9,9
	dc.b		4,0,0,0,0,0,0
	dc.b		9,9,9,9,9,9,9,9,4,9,9,9,10
	dc.b		10,10,9,10,9,9,8,9,9,10,10,9,9
	.even

hlists::
;high score tables in ram for each high score screen
	dc.l		pbhighs					;powerballs
	dc.l		rac0high					;racing future
	dc.l		rac1high					;racing sf
	dc.l		rac2high					;racing west
	dc.l		rac3high					;racing house
	dc.l		racShigh					;racing secret world
hs_eebeg::
;offsets for score lists in eeprom
	dc.b		EE_PBSCORE_START			;powerballs
	dc.b		EE_R0SCORE_START			;racing future
	dc.b		EE_R1SCORE_START			;racing sf
	dc.b		EE_R2SCORE_START			;racing west
	dc.b		EE_R3SCORE_START			;racing house
	dc.b		EE_RSSCORE_START			;racing secret world
	.even

httlpos::
;Y,X position of each high score screen title
	dc.l		$00050015					;powerballs
	dc.l		$00030029					;racing future
	dc.l		$00030029					;racing sf
	dc.l		$00030029					;racing west
	dc.l		$00030029					;racing house
	dc.l		$00030029					;racing secret world
eoghttl::
;Y,X position of each end of game title
	dc.l		$00050000					;powerballs
	dc.l		$00030014					;racing future
	dc.l		$00030014					;racing sf
	dc.l		$00030014					;racing west
	dc.l		$00030014					;racing house
	dc.l		$00030014					;racing secret world
htitles::
	dc.l		pbtitle					;powerballs
	dc.l		rac0ttl					;racing future
	dc.l		rac1ttl					;racing sf
	dc.l		rac2ttl					;racing west
	dc.l		rac3ttl					;racing house
	dc.l		racSttl					;racing secret world
pbtitle::
	dc.b		'BEST POWERBALL TIMES',0
rac0ttl::
	dc.b		'BEST RACE TIMES]'
	dc.b		' VELOCITY PARK'
	dc.b		0
rac1ttl::
	dc.b		'BEST RACE TIMES]'
	dc.b		' SAN FRANCISCO'
	dc.b		0
rac2ttl::
	dc.b		'BEST RACE TIMES]'
	dc.b		' THE OLD WEST'
	dc.b		0
rac3ttl::
	dc.b		'BEST RACE TIMES]'
	dc.b		'  JEROME',39,'S PAD'
	dc.b		0
racSttl::
	dc.b		'BEST RACE TIMES]'
	dc.b		' PLANET TODD'
	dc.b		0

	.even
ranktbls::
	dc.l		pbranks					;powerballs
	dc.l		rc0ranks					;racing future
	dc.l		rc1ranks					;racing sf
	dc.l		rc2ranks					;racing west
	dc.l		rc3ranks					;racing house
	dc.l		rcSranks					;racing secret world
pbranks::
	dc.l		(00*18000)+(25*300)+(0*30)
	dc.l		(00*18000)+(28*300)+(0*30)
	dc.l		(00*18000)+(31*300)+(0*30)
	dc.l		(00*18000)+(34*300)+(0*30)
	dc.l		(00*18000)+(38*300)+(0*30)
	dc.l		(00*18000)+(42*300)+(0*30)
	dc.l		(00*18000)+(48*300)+(0*30)
	dc.l		(00*18000)+(52*300)+(0*30)
	dc.l		(00*18000)+(55*300)+(0*30)
	dc.l		(01*18000)+(00*300)+(0*30)
	dc.l		(01*18000)+(10*300)+(0*30)
	dc.l		(01*18000)+(25*300)+(0*30)
	dc.l		(01*18000)+(40*300)+(0*30)
	dc.l		(01*18000)+(55*300)+(0*30)
	dc.l		(02*18000)+(10*300)+(0*30)
rc0ranks::							;future
	dc.l		(03*18000)+(00*300)+(0*30)
	dc.l		(03*18000)+(05*300)+(0*30)
	dc.l		(03*18000)+(10*300)+(0*30)
	dc.l		(03*18000)+(15*300)+(0*30)
	dc.l		(03*18000)+(20*300)+(0*30)
	dc.l		(03*18000)+(30*300)+(0*30)
	dc.l		(03*18000)+(40*300)+(0*30)
	dc.l		(03*18000)+(50*300)+(0*30)
	dc.l		(04*18000)+(00*300)+(0*30)
	dc.l		(04*18000)+(20*300)+(0*30)
	dc.l		(04*18000)+(40*300)+(0*30)
	dc.l		(05*18000)+(00*300)+(0*30)
	dc.l		(05*18000)+(00*300)+(0*30)
	dc.l		(06*18000)+(00*300)+(0*30)
	dc.l		(08*18000)+(00*300)+(0*30)
rc1ranks::							;sf
	dc.l		(03*18000)+(00*300)+(0*30)
	dc.l		(03*18000)+(05*300)+(0*30)
	dc.l		(03*18000)+(10*300)+(0*30)
	dc.l		(03*18000)+(15*300)+(0*30)
	dc.l		(03*18000)+(20*300)+(0*30)
	dc.l		(03*18000)+(30*300)+(0*30)
	dc.l		(03*18000)+(40*300)+(0*30)
	dc.l		(03*18000)+(50*300)+(0*30)
	dc.l		(04*18000)+(00*300)+(0*30)
	dc.l		(04*18000)+(20*300)+(0*30)
	dc.l		(04*18000)+(40*300)+(0*30)
	dc.l		(05*18000)+(00*300)+(0*30)
	dc.l		(05*18000)+(00*300)+(0*30)
	dc.l		(06*18000)+(00*300)+(0*30)
	dc.l		(08*18000)+(00*300)+(0*30)
rc2ranks::							;west
	dc.l		(02*18000)+(00*300)+(0*30)
	dc.l		(02*18000)+(05*300)+(0*30)
	dc.l		(02*18000)+(10*300)+(0*30)
	dc.l		(02*18000)+(15*300)+(0*30)
	dc.l		(02*18000)+(20*300)+(0*30)
	dc.l		(02*18000)+(30*300)+(0*30)
	dc.l		(02*18000)+(40*300)+(0*30)
	dc.l		(02*18000)+(50*300)+(0*30)
	dc.l		(03*18000)+(00*300)+(0*30)
	dc.l		(03*18000)+(10*300)+(0*30)
	dc.l		(03*18000)+(20*300)+(0*30)
	dc.l		(03*18000)+(40*300)+(0*30)
	dc.l		(04*18000)+(00*300)+(0*30)
	dc.l		(05*18000)+(00*300)+(0*30)
	dc.l		(08*18000)+(00*300)+(0*30)
rc3ranks::							;house
	dc.l		(00*18000)+(45*300)+(0*30)
	dc.l		(00*18000)+(48*300)+(0*30)
	dc.l		(00*18000)+(51*300)+(0*30)
	dc.l		(00*18000)+(54*300)+(0*30)
	dc.l		(00*18000)+(57*300)+(0*30)
	dc.l		(01*18000)+(00*300)+(0*30)
	dc.l		(01*18000)+(07*300)+(0*30)
	dc.l		(01*18000)+(15*300)+(0*30)
	dc.l		(01*18000)+(30*300)+(0*30)
	dc.l		(01*18000)+(40*300)+(0*30)
	dc.l		(01*18000)+(50*300)+(0*30)
	dc.l		(02*18000)+(00*300)+(0*30)
	dc.l		(02*18000)+(20*300)+(0*30)
	dc.l		(02*18000)+(40*300)+(0*30)
	dc.l		(03*18000)+(00*300)+(0*30)
rcSranks::							;secret world
	dc.l		(00*18000)+(45*300)+(0*30)
	dc.l		(00*18000)+(48*300)+(0*30)
	dc.l		(00*18000)+(51*300)+(0*30)
	dc.l		(00*18000)+(54*300)+(0*30)
	dc.l		(00*18000)+(57*300)+(0*30)
	dc.l		(01*18000)+(00*300)+(0*30)
	dc.l		(01*18000)+(07*300)+(0*30)
	dc.l		(01*18000)+(15*300)+(0*30)
	dc.l		(01*18000)+(30*300)+(0*30)
	dc.l		(01*18000)+(40*300)+(0*30)
	dc.l		(01*18000)+(50*300)+(0*30)
	dc.l		(02*18000)+(00*300)+(0*30)
	dc.l		(02*18000)+(20*300)+(0*30)
	dc.l		(02*18000)+(40*300)+(0*30)
	dc.l		(03*18000)+(00*300)+(0*30)

;equate for MAX_RANK is in EQ.S
rankstrs:
	dc.l		rnkstr00,rnkstr01,rnkstr02,rnkstr03,rnkstr04,rnkstr05,rnkstr06,rnkstr07,rnkstr08,rnkstr09
	dc.l		rnkstr10,rnkstr11,rnkstr12,rnkstr13,rnkstr14

rnkstr00:
	dc.b		' PIZZA GUY',0
rnkstr01:
	dc.b		'  MANIAC',0
rnkstr02:
	dc.b		' INSURANCE]'
	dc.b		' RISK',0
rnkstr03:
	dc.b		'SPEED DEMON',0
rnkstr04:
	dc.b		'  RIPPIN',0
rnkstr05:
	dc.b		' SUPERDUDE',0
rnkstr06:
	dc.b		'    ACE',0
rnkstr07:
	dc.b		'    PRO',0
rnkstr08:
	dc.b		'  CABBIE',0
rnkstr09:
	dc.b		'  ROOKIE',0
rnkstr10:
	dc.b		' SLOW POKE',0
rnkstr11:
	dc.b		' TOUR GUIDE',0
rnkstr12:
	dc.b		'  GRANNY',0
rnkstr13:
	dc.b		' ROAD BLOCK',0
rnkstr14:
	dc.b		'  ASPHALT]'
	dc.b		'  TURTLE',0
	.even

higholst::
;h_scr::
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
;h_text::
	dc.w		185			;xpos
	dc.w		0			;ypos
	dc.l		hitxtdta		;data
	dc.w		87			;height
	dc.w		28			;dwidth
	dc.w		28			;iwidth
	dc.b		TRANS_ON		;flags
	dc.b		0			;firstpix
	dc.b		1			;type
	dc.b		3			;depth
	dc.b		1			;pitch
	dc.b		0			;index
	dc.w		0			;desc
	dc.l		$00202020		;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------
;cursor0::
	dc.w		80			;xpos
	dc.w		0			;ypos
	dc.l		curs0dta		;data
	dc.w		13			;height
	dc.w		1			;dwidth
	dc.w		1			;iwidth
	dc.b		TRANS_ON		;flags
	dc.b		0			;firstpix
	dc.b		0			;type
	dc.b		3			;depth
	dc.b		1			;pitch
	dc.b		0			;index
	dc.w		0			;desc
	dc.l		$00000000		;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------
;cursor1::
	dc.w		80			;xpos
	dc.w		0			;ypos
	dc.l		curs1dta		;data
	dc.w		13			;height
	dc.w		1			;dwidth
	dc.w		1			;iwidth
	dc.b		TRANS_ON		;flags
	dc.b		0			;firstpix
	dc.b		0			;type
	dc.b		3			;depth
	dc.b		1			;pitch
	dc.b		0			;index
	dc.w		0			;desc
	dc.l		$00000000		;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------

;
;
; Versions of eeread and eewrite that retry if a timeout happens.
; Use these instead of calling eeread and eewrite directly!
;

; eeread doesn't actually have any timeout???
eegetw::
	jmp	eeread


eeputw::
	jsr	eewrite
	bpl	.ret			; success: return
	jsr	eewrite			; otherwise, try...
	bpl	.ret
	jsr	eewrite			; ... and try again
.ret:
	rts
