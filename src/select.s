	.include	'eq.s'
	.include	'externs.s'

MODEM_ENABLED	equ	0				;set to 1 to get a "modem" line

END_SEL_JOY_DELAY	equ	12			;for changing laps, times, dots

.if MODEM_ENABLED
MAX_BARPOS		equ	6			;number of lines that the bar can be on
.else
MAX_BARPOS		equ	5
.endif

VOL_CURSX			equ	204			;farthest left X position of volume cursors
VOL_CURSX_MAX		equ	322			;farthest right X position of volume cursors

;values for signmove
SIGN_STOP			equ	0
SIGN_UP			equ	1			;sign rising
SIGN_DOWN			equ	2			;sign dropping into ground

;values for menuflag
MAIN_MENU			equ	0
CHANGE_ACT		equ	1			;changing activity
CHANGE_OPT		equ	2			;changing options
CHANGE_BUT		equ	3			;changing buttons

; length of scrolling string
MAX_SCROLL	equ	22

	.text
selloop::
	bsr		mv_ssign				;scale club drive screen if necessary
	bsr		mv_sign				;move billboard up or down if necessary

	bsr		scrollit			; scroll instructions

	bsr		input				;check for restart
	bsr		selinput				;handle controller input specific to selection screen

	cmp.w	#SELECT_MODE,gamemode
	bne.b	.90					;exit if game just switched to PLAY_MODE
	lea		selobjs,a1			;address of first object header
	moveq	#SEL_OBJS,d6			;total objects in list
	lea		olist_ram,a2
	move.l	a2,listAddr
	bsr		build				;build packed object list
.90:
	rts

initsel::
	lea		sinfntsc,a0
	cmp.b	#NTSC,pal_ntsc
	beq.b	.10
	lea		sinf_pal,a0
.10:
	move.w	(a0)+,s_club+O_YPOS
	move.w	(a0)+,s_sign+O_YPOS
	move.w	(a0)+,s_text+O_YPOS
	move.w	(a0)+,s_mask+O_YPOS
	move.w	(a0)+,mvolcurs+O_YPOS
	move.w	(a0)+,svolcurs+O_YPOS
	move.w	(a0)+,d0
	move.w	d0,s_sign_l+O_YPOS
	move.w	d0,s_sign_r+O_YPOS
	move.l	(a0)+,d0
	move.l	d0,s_sign_l+O_DATA
	add.l	#448,d0
	move.l	d0,s_sign_r+O_DATA
	move.w	(a0)+,d0
	move.w	d0,s_sign_l+O_HEIGHT
	move.w	d0,s_sign_r+O_HEIGHT
	move.l	#$00202020,d0
	move.l	d0,s_sign_l+O_SCALE
	move.l	d0,s_sign_r+O_SCALE
	move.w	(a0)+,d0
	move.w	d0,s_scr_l+O_YPOS
	move.w	d0,s_scr_m+O_YPOS
	move.w	d0,s_scr_r+O_YPOS
	move.w	(a0)+,d0
	move.w	d0,s_scr_l+O_HEIGHT
	move.w	d0,s_scr_m+O_HEIGHT
	move.w	d0,s_scr_r+O_HEIGHT
	move.l	(a0),d0
	move.l	d0,s_scr_l+O_DATA
	add.l	#448,d0
	move.l	d0,s_scr_r+O_DATA

	moveq	#0,d0
	move.w	d0,s_sign+O_HEIGHT
	move.w	d0,s_text+O_HEIGHT
	moveq	#DELETE_OBJ,d0
	or.b		d0,s_bar+O_TYPE				;bar is off until billboard rises
	or.b		d0,mvolcurs+O_TYPE				;music volume cursor is off until needed
	or.b		d0,svolcurs+O_TYPE				;sound volume cursor is off until needed
	move.w	#0,s_sign_l+O_XPOS
	move.w	#224,s_sign_r+O_XPOS
	cmp.w	#PLAY_MODE,oldgmode
	bne.b	.30
	moveq	#DELETE_OBJ,d0					;club drive screen not shown when coming here from a game
	or.b		d0,s_sign_l+O_TYPE
	or.b		d0,s_sign_r+O_TYPE
	bsr		clearscr
	bra.b	.40
.30:
	moveq	#$7F,d0				;turn on club drive screen
	and.b	d0,s_sign_l+O_TYPE
	and.b	d0,s_sign_r+O_TYPE
	lea		selobjs,a1			;address of first object header
	moveq	#SEL_OBJS,d6			;total objects in list
	lea		olist_ram,a2
	bsr		build				;build packed object list
	bsr		wait_int
.40:	move.w	#SELECT_MODE,gamemode
	move.w	#$4C7,VMODE
	rts

sinf_pal::
;;;	dc.w		P_SCRN_TOP+230			;s_club+O_YPOS
	dc.w		P_SCRN_TOP+224			;s_club+O_YPOS
	dc.w		P_SCRN_TOP+392			;s_sign+O_YPOS
	dc.w		P_SCRN_TOP+402			;s_text+O_YPOS
	dc.w		P_SCRN_TOP+366			;s_mask+O_YPOS
	dc.w		P_SCRN_TOP+214			;mvolcurs+O_YPOS
	dc.w		P_SCRN_TOP+236			;svolcurs+O_YPOS
	dc.w		P_SCRN_TOP			;ypos for s_sign_l,r pieces
	dc.l		stonedta				;s_sign_l+O_DATA
	dc.w		287					;height for s_sign_l,r
	dc.w		P_SCRN_TOP			;ypos for s_scr pieces
	dc.w		287					;height for s_scr pieces
	dc.l		selscr				;s_scr_l+O_DATA

sinfntsc::
	dc.w		N_SCRN_TOP+178			;s_club+O_YPOS
	dc.w		N_SCRN_TOP+344			;s_sign+O_YPOS
	dc.w		N_SCRN_TOP+354			;s_text+O_YPOS
	dc.w		N_SCRN_TOP+318			;s_mask+O_YPOS
	dc.w		N_SCRN_TOP+166			;mvolcurs+O_YPOS
	dc.w		N_SCRN_TOP+188			;svolcurs+O_YPOS
	dc.w		N_SCRN_TOP			;ypos for s_sign_l,r pieces
	dc.l		stonedta+(448*32*2)		;s_sign_l+O_DATA
	dc.w		240					;height for s_sign_l,r
	dc.w		N_SCRN_TOP			;ypos for s_scr pieces
	dc.w		240					;height for s_scr pieces
	dc.l		selscr+(24*896)		;s_scr_l+O_DATA


mv_ssign::
	move.b	s_sign_l+O_TYPE,d0
	bmi.b	.90						;exit if club drive screen is off
	cmp.l	#$00000000,s_sign_l+O_SCALE	;smallest scale size
	bne.b	.50
	or.b		#DELETE_OBJ,s_sign_l+O_TYPE	;turn off sign when sign is at minimum size
	or.b		#DELETE_OBJ,s_sign_r+O_TYPE	;turn off sign when sign is at minimum size
	move.b	#SIGN_UP,signmove			;set flag for billboard to rise
	rts
.50:
	move.w	s_sign_l+O_YPOS,d1
	addq.w	#5,d1					;add some to ypos
	move.w	d1,s_sign_l+O_YPOS
	move.w	d1,s_sign_r+O_YPOS
	addq.w	#7,s_sign_l+O_XPOS			;move xpos right as sign shrinks
	move.l	#$00010101,d0
	sub.l	d0,s_sign_l+O_SCALE
	sub.l	d0,s_sign_r+O_SCALE
.90:	rts

goselect::
	cmp.w	#SF2P_LEVEL,curlevel
	bne.b	.05
		move.w	#SF_LEVEL,curlevel
.05:
	move.w	gamemode,oldgmode
	bsr		initsel
	move.b	#MAIN_MENU,menuflag		;reset flag for changing activity or options

	bsr		ld_decmp				;load jpeg GPU code
	bsr		load_q75				;copy jpeg quality table into GPU ram

	cmp.w	#PLAY_MODE,oldgmode
	bne.b	.10
	lea		seldcm,a0
	moveq	#3,d0				;load island, billboard, club drive sign
	bra.b	.15
.10:	lea		seldcm1,a0			;table with decompression info
	moveq	#2,d0				;load billboard, club drive sign
.15:	bsr		dodecomp

	lea		adblack,a0
	bsr		load_gpu
	move.l	#selscr+(448*100*2),ADJBLACK_START	;destination address - only need to do the part copied used for mask data
	move.l	#selscr+(448*288*2),ADJBLACK_END	;total size
	bsr		adjblak
	move.l	#clubdta,ADJBLACK_START			;destination address
	move.l	#selsign+(192*96*2),ADJBLACK_END	;total size
	bsr		adjblak

	bsr		copymap				;copy pieces of map background into separate buffers
	bsr		ld_uncmp				;load uncomp GPU code into GPU ram
	lea		msk_sel,a0			;address of table of mask info
	moveq	#7,d0				;number of masks to do
	bsr		do_mask				;uncompress masks, blit them

	move.w	#MAX_BARPOS-1,bar_pos
	;put bar at 'start game'
	bsr		drawstxt				;draw text for billboard
	moveq	#$7F,d1
	and.b	d1,s_club+O_TYPE		;turn on club drive sign
	and.b	d1,s_sign+O_TYPE		;turn on billboard
	and.b	d1,s_text+O_TYPE		;turn on text that goes on billboard
	and.b	d1,s_mask+O_TYPE		;turn on cover for ground
	cmp.w	#PLAY_MODE,oldgmode
	bne.b	.20
	move.b	#SIGN_UP,signmove
	bra.b	.30
.20:	move.b	#SIGN_STOP,signmove		;init flag for billboard
.30:

	bsr		ld_ltn				;load lighten code into GPU ram
	rts	


copymap::
;copy sections of the background into separate buffers so they can be lightened and redrawn
	move.l	#selscr,A2_BASE					;source address
	move.l	#PITCH1|PIXEL32|WID224|XADDPHR,A2_FLAGS	;description of source area

	moveq	#4,d6							;4 map sections, and cover for rising sign
	lea		mapcpinf,a0						;info for each piece
	move.l	#$00010000,d1						;set Y step to 1
.10:
	move.l	(a0)+,A1_BASE						;destination address
	move.l	(a0)+,A2_PIXEL						;Y,X in background
	move.l	#0,A1_PIXEL						;Y,X in destination
	move.l	(a0)+,d0							;get height, width of source image
	move.l	d0,B_COUNT						;height, width of source image
	move.w	d0,d1							;combine width with Y step
	neg.w	d1								;make width negative
	move.l	d1,A1_STEP
	move.l	d1,A2_STEP
	move.l	(a0)+,A1_FLAGS						;source flags
	move.l	#UPDA1|UPDA2|SRCEN|LFU_A|LFU_AN,B_CMD	;turn on blitter

.50:	move.l	B_CMD,d2
	btst.l	#0,d2
	beq.b	.50					;wait until blitter is finished
	dbra		d6,.10
	rts

mapcpinf::
;destination address
;Y,X position in source
;height, width
;flags for blitter
	dc.l		futdta,	$002E0044,	$00430070,	PITCH1|PIXEL32|WID112|XADDPHR		;future
	dc.l		sfdta,	$0044001C,	$00710060,	PITCH1|PIXEL32|WID96|XADDPHR		;sf
	dc.l		wstdta,	$0064005C,	$005B0070,	PITCH1|PIXEL32|WID112|XADDPHR		;west
	dc.l		housdta,	$00800034,	$00600080,	PITCH1|PIXEL32|WID128|XADDPHR		;house
	dc.l		hmskdta,	$00B7003C,	$002D0070,	PITCH1|PIXEL32|WID112|XADDPHR		;cover for bottom of sign as it rises

mv_sign::
	cmp.b	#SIGN_STOP,signmove
	beq		.90
	cmp.b	#SIGN_UP,signmove
	beq.b	.50
	cmp.w	#0,s_sign+O_HEIGHT
	bne.b	.20
;when sign has disappeared
	moveq	#DELETE_OBJ,d0
	or.b		d0,s_sign+O_TYPE			;turn off billboard
	or.b		d0,s_text+O_TYPE			;turn off text for billboard
	or.b		d0,s_mask+O_TYPE			;turn off cover for sign
	bsr		ltn_map					;lighten currently selected level
	moveq	#1,d5					;set flag to draw current level lightened
	bsr		drawmap					;draw current selected piece
	move.b	#SIGN_STOP,signmove			;set flag to stop moving sign
	bra		.90
.20:	addq.w	#4,s_sign+O_YPOS			;move sign down
	subq.w	#2,s_sign+O_HEIGHT			;reduce sign height
	addq.w	#4,s_text+O_YPOS			;move text down
	cmp.w	#83,s_sign+O_HEIGHT			;don't start reducing text height until sign is below this height
	bge.b	.90						;(sign height is larger than text height)
	cmp.w	#2,s_text+O_HEIGHT
	blt.b	.90						;don't reduce text height if it is already 0
	subq.w	#2,s_text+O_HEIGHT
	bra.b	.90

.50:	cmp.w	#96,s_sign+O_HEIGHT
	bne.b	.60
;if sign is at its full height
	move.b	#SIGN_STOP,signmove			;set flag to stop moving sign
	bsr		set_mbar					;set the position of the bar
	and.b	#$7F,s_bar+O_TYPE			;turn on bar
	or.b		#DELETE_OBJ,s_club+O_TYPE	;turn off club drive sign since it is now covered by billboard
	bra.b	.90
.60:	subq.w	#4,s_sign+O_YPOS			;move sign up
	addq.w	#2,s_sign+O_HEIGHT			;increase sign height
	subq.w	#4,s_text+O_YPOS			;move text up
	cmp.w	#76,s_text+O_HEIGHT			;stop increasing text height when it is at its full height
	beq.b	.90
	cmp.w	#8,s_sign+O_HEIGHT			;don't increase text height until sign is >= to this height
	blt.b	.90
	addq.w	#2,s_text+O_HEIGHT
.90:
	rts

drawstxt::
;draw the main text menu
	bsr		clrtext							;clear entire text box

	move.w	cur_act,d1
	lsl.w	#2,d1
	lea		act_str,a0
	move.l	(a0,d1.w),a0						;address of string to print
	moveq	#0,d0
	bsr		drawstr							;draw activity selection

	move.w	curlevel,d1
	lsl.w	#2,d1
	lea		wrldstr,a0
	move.l	(a0,d1.w),a0						;address of string to print
	moveq	#1,d0
	bsr		drawstr							;draw world selection

	lea		car_str0,a0						;address of string to print
	moveq	#2,d0
	bsr		drawstr							;draw player 1 car selection

	lea		car_str1,a0						;address of string to print
	moveq	#3,d0
	bsr.b	drawstr							;draw player 2 car selection

	bsr		caricons							;draw the car icons

	lea		opt_str,a0						;address of string to print
	moveq	#4,d0
	bsr.b	drawstr							;draw options

.if MODEM_ENABLED
	move.w	modem,d0
	lea		modem_str,a0					;address of string to print
	cmp.w	#0,d0
	beq	.70
	lea		call_str,a0
	cmp.w	#1,d0
	beq	.70
	lea		answ_str,a0
.70:
	moveq	#5,d0
	bsr.b	drawstr							;draw modem thing
	lea		strt_str,a0					;draw "start game"
	moveq	#6,d0

.else
	lea		strt_str,a0					;draw "start game"
	moveq	#5,d0
.endif

	bsr.b	drawstr

;
; draw a line to separate the help line
;
	lea	seltext,a0
	move.l	#$00420000,d0
	move.l	#$000100B9,d1
	move.l	#$01010101,d2		; black
	bsr	eraseline

	bsr	initscroll

	lea		scrlbytes,a0
	moveq	#7,d0
;	bsr.b	drawstr							;draw press B to change
;	rts

drawstr::
;d0.w = offset for str_pos table
	lea		str_pos,a1
	lsl.w	#2,d0
	move.l	(a1,d0.w),d5
	bra		blitstxt
str_pos::
	dc.l		$00020003							;activity
	dc.l		$000D0003							;world
	dc.l		$00180003							;player 1 car
	dc.l		$0018005b							;player 2 car
	dc.l		$00230003							;options
.if MODEM_ENABLED
	dc.l		$002E0003							;modem
	dc.l		$00390003							;start game
.else
	dc.l		$002E0003							;start game
.endif
	dc.l		$00440003							;instructions

caricons::
	moveq	#0,d1
	move.l	#$00060018,d2						;height, width (24 x 6, 8 bit)
	move.l	#UPDA1|UPDA2|SRCEN|LFU_A|LFU_AN,d3
	move.l	#seltext,A1_BASE					;destination address
	move.l	#PITCH1|PIXEL8|WID192|XADDPIX,A1_FLAGS	;description of destination area
	move.l	#PITCH1|PIXEL8|WID24|XADDPIX,A2_FLAGS	;description of source data
	move.l	#$0001FFE8,d0						;1 in Y step, negative width in X step size
	move.l	d0,A1_STEP
	move.l	d0,A2_STEP
	move.l	#$0018003c,A1_PIXEL					;dest Y,X
	move.l	d1,A2_PIXEL						;source Y,X
	move.l	d2,B_COUNT
	move.w	cur_car0,d0						;current car for player 1
	lsl.w	#2,d0
	lea		caricnad,a0
	move.l	(a0,d0.w),A2_BASE					;source address
	move.l	d3,B_CMD							;start blitter
	move.w	cur_car1,d0						;current car for player 2
	lsl.w	#2,d0
	move.l	(a0,d0.w),A2_BASE					;source address
	move.l	#$00180094,A1_PIXEL					;dest Y,X
	move.l	d1,A2_PIXEL						;source Y,X
	move.l	d2,B_COUNT						;height, width
	move.l	d3,B_CMD							;start blitter
	rts

caricnad::
	dc.l		car1icn		;white
	dc.l		car2icn		;yellow
	dc.l		car0icn		;red
	dc.l		car3icn		;blue
	dc.l		car4icn		;cyan
	dc.l		car5icn		;green

clrtexta::
	move.l	#seltexta,A1_BASE					;destination address
	bra.b	clrtxt
clrtext::
;erase whole text window
	move.l	#seltext,A1_BASE					;destination address
clrtxt:
	move.l	#PITCH1|PIXEL32|WID48|XADDPHR,A1_FLAGS	;destination
	move.l	#$0001FFD0,A1_STEP					;high = Y step, low = negative width
	move.l	#$004C0030,B_COUNT					;high = height, low = width
	moveq	#0,d0
	move.l	d0,A1_PIXEL						;set rectangle Y,X
	move.l	d0,B_PATD
	move.l	d0,B_PATD+4
	move.l	#PATDSEL|UPDA1,B_CMD				;turn on blitter
	rts

draw_act::
;draw the text for selecting an activity
	bsr.b		clrtexta		; retail uses short call							;erase seltexta buffer

	move.w	cur_act,d0
	lsl.w	#2,d0
	lea		sel_acl0,a1
	move.l	(a1,d0.w),a0
	move.l	#$00020003,d5
	bsr		blitatxt							;draw activity selection

	move.w	cur_act,d0
	lsl.w	#2,d0
	lea		sel_acl1,a1
	move.l	(a1,d0.w),a0
	move.l	#$00180003,d5
	bsr		blitatxt							;draw activity description

	bsr		drawstng							;draw setting for laps, time, or powerballs

;
; draw a line to separate the help line
;
	lea	seltexta,a0
	move.l	#$00420000,d0
	move.l	#$000100B9,d1
	move.l	#$01010101,d2		; black
	bsr	eraseline

;	bsr	initscroll
	lea	scrlbytes,a0

	move.l	#$00440003,d5
	bsr		blitatxt
copytxta::
;copy temp seltexta to seltext
;192 x 76
	move.l	#PITCH1|PIXEL32|WID48|XADDPHR,d0
	move.l	d0,A1_FLAGS						;destination
	move.l	d0,A2_FLAGS						;source
	move.l	#seltext,A1_BASE					;destination address
	move.l	#seltexta,A2_BASE					;source address
	moveq	#0,d0
	move.l	d0,A1_PIXEL						;get rectangle Y,X
	move.l	d0,A2_PIXEL						;source Y,X
	move.l	#$0001FFD0,d0						;high = Y step, low = negative width
	move.l	d0,A1_STEP
	move.l	d0,A2_STEP
	move.l	#$004C0030,B_COUNT					;high = height, low = width
	move.l	#UPDA1|UPDA2|SRCEN|LFU_A|LFU_AN,B_CMD	;turn on blitter
	rts

draw_opt::
;draw the text for changing options
	bsr		clrtext							;clear whole text area

	lea		sel_op01,a0						;string to print
	move.l	#$00020003,d5						;Y,X position
	bsr		blitstxt							;draw 'music:'
	move.w	mus_vol,d0
	add.w	#VOL_CURSX,d0
	cmp.w	#VOL_CURSX_MAX,d0
	blt.b	.20
	move.w	#VOL_CURSX_MAX,d0
.20:	move.w	d0,mvolcurs+O_XPOS					;set X position for cursor

	lea		sel_op02,a0						;string to print
	move.l	#$000D0003,d5						;Y,X position
	bsr		blitstxt							;draw 'sound:'
	move.w	snd_vol,d0
	add.w	#VOL_CURSX,d0
	cmp.w	#VOL_CURSX_MAX,d0
	blt.b	.30
	move.w	#VOL_CURSX_MAX,d0
.30:	move.w	d0,svolcurs+O_XPOS					;set X position for cursor

;draw the 2 volume bars on the text window
	move.l	#PITCH1|PIXEL8|WID192|XADDPIX,A1_FLAGS	;destination
	move.l	#seltext,A1_BASE					;destination address
	move.l	#$00020039,A1_PIXEL					;get rectangle Y,X
	move.l	#$0001FF86,A1_STEP					;high = Y step, low = negative width
	move.l	#$0007007A,B_COUNT					;high = height, low = width
	move.l	#$12121212,d0						;4 bytes of the color to draw
	move.l	d0,B_PATD							;the palette color for the bars
	move.l	d0,B_PATD+4
	move.l	#PATDSEL|UPDA1,B_CMD				;turn on blitter
	move.l	#$000D0039,A1_PIXEL					;get rectangle Y,X
	move.l	#$0007007A,B_COUNT					;high = height, low = width
	move.l	#PATDSEL|UPDA1,B_CMD				;turn on blitter


	bsr		drawspeed
	bsr		drawengopt

	lea		sel_opb,a0						;string to print
	move.l	#$002E0003,d5						;Y,X position
	bsr		blitstxt							;draw 'buttons:'

	lea		sel_opr,a0					;string to print
	move.l	#$00390003,d5
	bsr		blitstxt					;draw 'return to main menu'

;
; draw a line to separate the help line
;
	lea	seltext,a0
	move.l	#$00420000,d0
	move.l	#$000100B9,d1
	move.l	#$01010101,d2		; black
	bsr	eraseline

	bsr	initscroll

	lea	scrlbytes,a0
	move.l	#$00440003,d5
	bsr		blitstxt

	rts
;
; draw the text for changing buttons
;
draw_but::
;draw the text for changing options
	bsr		clrtext							;clear whole text area

	lea	but_opb,a0
	move.l	#$00020003,d5
	bsr	blitstxt

	bsr	but_only			; draw buttons
;
; draw a line to separate the help line
;
	lea	seltext,a0
	move.l	#$00420000,d0
	move.l	#$000100B9,d1
	move.l	#$01010101,d2			; black
	bsr	eraseline

	bsr	initscroll

	lea		scrlbytes,a0
	move.l	#$00440003,d5
	bsr		blitstxt

	rts

but_only:
	move.w	cont_opt,d0						;get the current controller setting
	lsl.w	#2,d0
	lea		sel_opt2,a1						;list of strings
	move.l	(a1,d0.w),a0						;string to print
	move.l	#$000C0049,d5						;Y,X position
	bsr		blitstxt							;draw the 3 lines for what the A,B,C buttons do
	rts

drawspeed::
	lea		sel_ops2,a0
	move.l	#$00230050,d5						;Y,X position
	bsr		blitstxt							;erase old setting

	lea		sel_ops0,a0						;string to print
	cmp.w	#0,speedopt
	beq.b	.40
	lea		sel_ops1,a0
.40:	move.l	#$00230003,d5						;Y,X position
	bsr		blitstxt							;draw 'speed:'
	rts

drawengopt::
	lea		sel_ops2,a0
	move.l	#$00180050,d5						;Y,X position
	bsr		blitstxt							;erase old setting

	lea		sel_opw0,a0						;string to print
	cmp.w	#0,engoffopt
	beq.b	.40
	lea		sel_opw1,a0
.40:	move.l	#$00180003,d5						;Y,X position
	bsr		blitstxt							;draw 'engine sounds:'
	rts

drawstng::
;draw the number setting for laps, time, or powerballs
	move.w	cur_act,d0
	lsl.w	#2,d0
	lea		numtoprn,a1
	lea		acop_trans,a0
	move.l	(a1,d0.w),a1						;get address of setting to change
	move.l	(a0,d0.w),a0						; get mapping from "index" to "thing printed"
	move.w	(a1),d0							;get current value for setting
	add.w	d0,d0							; make it into an index
	move.w	(a0,d0.w),d0						; get the corresponding "real" number
	and.l	#$FFFF,d0							;clear high word for division
;convert the number in D0 a byte for each decimal digit
	lea		num_dec,a0
	moveq	#16,d1							;for shifting division result
	moveq	#'0',d2
	divu		#100,d0
	move.b	d0,(a0)							;result is hundreds digit
	add.b	d2,(a0)
	lsr.l	d1,d0							;move remainder from high word to low word, clear high word
	divu		#10,d0
	move.b	d0,1(a0)							;result is tens digit
	add.b	d2,1(a0)
	swap		d0								;move remainder to low word
	move.b	d0,2(a0)							;ones digit
	add.b	d2,2(a0)
	move.b	#0,3(a0)							;to mark end of string
	cmp.b	(a0),d2
	bne.b	.10								;if first digit is not 0, exit
	move.b	#'&',(a0)							;change first 0 to some blank space
	cmp.b	1(a0),d2
	bne.b	.10								;if second digit is not 0, exit
	move.b	#'&',1(a0)						;change second digit to some blank space
.10:
	move.w	cur_act,d0
	lsl.w	#2,d0
	lea		stng_yx,a1						;Y,X position for setting digits
	move.l	(a1,d0.w),d5						;get Y,X position for digits
	bsr		blitatxt							;A0 = num_dec, draw into seltexta buffer, then copy to seltext

	cmp.w	#TAG2PLR,cur_act
	bne		.90
	move.l	stng_yx+(TAG2PLR*4),d5				;Y,X position for tag time setting
	add.l	#$000A0010,d5						;put tune names below the time setting
	move.l	#seltexta,A1_BASE					;destination address
	move.l	#PITCH1|PIXEL8|WID192|XADDPHR,A1_FLAGS	;destination
	move.l	#$0001FF90,A1_STEP					;high = Y step, low = negative width
	move.l	#$00110070,B_COUNT					;high = height, low = width
	move.l	d5,A1_PIXEL						;set rectangle Y,X
	moveq	#0,d0
	move.l	d0,B_PATD
	move.l	d0,B_PATD+4
	move.l	#PATDSEL|UPDA1,B_CMD				;turn on blitter
	lea		tgtunes,a0						;addresses of tune name strings
	move.w	tagtune0,d0						;tune number for player 1
	lsl.w	#2,d0
	move.l	(a0,d0.w),a0						;address of tune name to print
	bsr		blitatxt

	move.l	stng_yx+(TAG2PLR*4),d5				;Y,X position for tag time setting
	add.l	#$00140010,d5						;put tune names below the time setting
	lea		tgtunes,a0						;addresses of tune name strings
	move.w	tagtune1,d0						;tune number for player 1
	lsl.w	#2,d0
	move.l	(a0,d0.w),a0						;address of tune name to print
	bsr		blitatxt
.90:
	rts
numtoprn::
	dc.l		rac1laps							;laps for 1 player racing
	dc.l		rac2laps							;laps for 2 player racing
	dc.l		tagtime							;time for 2 player tag
	dc.l		col1dots							;powerballs for 1 player collect
	dc.l		col2dots							;powerballs for 2 player collect
stng_yx::
	dc.l		$000C0034							;laps for 1 player racing
	dc.l		$000C0034							;laps for 2 player racing
	dc.l		$000C0034							;time for 2 player tag
	dc.l		$000C006B							;powerballs for 1 player collect
	dc.l		$000C006B							;powerballs for 2 player collect

drawmap::
;d7 = number of map piece to draw
;d5 = 1 if current level should be lightened, 0 if not
	; check for secret worlds
	cmp		#SECRET_LEVEL, d7
	bmi.b	.5
		rts									; no graphics - don't try to draw it
.5:
	move.l	#selscr,A1_BASE					;destination address is background screen
	move.l	#PITCH1|PIXEL16|WID448|XADDPHR,A1_FLAGS
	moveq	#0,d0
	move.l	d0,B_PATD							;the color that will not be written if found in the source data
	move.l	d0,B_PATD+4						;the color that will not be written if found in the source data
	move.l	d0,A2_PIXEL						;start at 0,0 of source image

	move.w	d7,d6							;get map piece number
	lsl.w	#2,d6
	lea		mapinfo,a0
	move.l	(a0,d6.w),a0						;address of info table

	cmp.w	#1,d5							;d5 is 1 if current level should be lightened
	bne.b	.10
	cmp.w	curlevel,d7						;compare current level to map piece number
	bne.b	.10								;if not =, draw normal colored map piece
	adda.l	#4,a0							;skip source address in table
	move.l	#ltnbufr,A2_BASE					;source address (light)
	bra.b	.20
.10:	move.l	(a0)+,A2_BASE						;source address (dark)
.20:
	move.l	(a0)+,A1_PIXEL						;Y,X position to write data
	move.l	(a0)+,B_COUNT						;height, width
	move.l	(a0)+,d0
	move.l	d0,A1_STEP						;Y step, X step
	move.l	d0,A2_STEP						;Y step, X step
	move.l	(a0),A2_FLAGS						;source
	move.l	#UPDA1|UPDA2|SRCEN|DSTEN|LFU_A|LFU_AN|DCOMPEN,B_CMD		;start blitter
	rts

ltn_map::
;lighten the currently selected map piece
;return current level in D7
	move.w	curlevel,d6
	; check for secret worlds
	cmp		#SECRET_LEVEL, d6
	bmi.b	.5
		rts									; no graphics - don't try to draw it
.5:
	lsl.w	#2,d6
	lea		ltninfo,a0
	move.l	(a0,d6.w),a0						;get address of info table

	move.l	(a0)+,d0							;get flags setting
	move.l	d0,A1_FLAGS						;destination
	move.l	d0,A2_FLAGS						;source
	move.l	#ltnbufr,A1_BASE					;destination address
	move.l	(a0)+,A2_BASE						;source address
	moveq	#0,d0
	move.l	d0,A1_PIXEL						;get rectangle Y,X
	move.l	d0,A2_PIXEL						;source Y,X
	move.l	(a0)+,d0
	move.l	d0,A1_STEP						;high = Y step, low = negative width
	move.l	d0,A2_STEP						;high = Y step, low = negative width
	move.l	(a0)+,B_COUNT						;high = height, low = width
	move.l	#UPDA1|UPDA2|SRCEN|LFU_A|LFU_AN,B_CMD	;turn on blitter

	move.l	#ltnbufr,d0
	move.l	d0,LIGHTEN_START					;where to write lightened data
	add.l	(a0),d0							;add size of data
	move.l	d0,LIGHTEN_END
	move.l	#LIGHTEN_PRG,G_PC					;set program counter
	move.l	#$00000011,G_CTRL					;start GPU
.30:	cmp.l	#1,LIGHTEN_DONE					;wait until lighten is finished
	bne.b	.30
	move.w	curlevel,d7						;return current level in d7
	rts

mapinfo::
	dc.l		futinfo,sfinfo,wstinfo,housinfo
futinfo::
	dc.l		futdta					;data
	dc.l		$002E0088					;y,x
	dc.l		$004300E0					;height, width
	dc.l		$0001FF20					;Y step, X step
	dc.l		PITCH1|PIXEL16|WID224|XADDPHR	;flags
sfinfo::
	dc.l		sfdta					;data
	dc.l		$00440038					;y,x
	dc.l		$007100C0					;height, width
	dc.l		$0001FF40					;Y step, X step
	dc.l		PITCH1|PIXEL16|WID192|XADDPHR	;flags
wstinfo::
	dc.l		wstdta					;data
	dc.l		$006400B8					;y,x
	dc.l		$005B00E0					;height, width
	dc.l		$0001FF20					;Y step, X step
	dc.l		PITCH1|PIXEL16|WID224|XADDPHR	;flags
housinfo::
	dc.l		housdta					;data
	dc.l		$00800068					;y,x
	dc.l		$00600100					;height, width
	dc.l		$0001FF00					;Y step, X step
	dc.l		PITCH1|PIXEL16|WID256|XADDPHR	;flags

ltninfo::
	dc.l		futltn,sfltn,wstltn,housltn
futltn::
	dc.l		PITCH1|PIXEL32|WID112|XADDPHR	;flags
	dc.l		futdta					;data
	dc.l		$0001FF90					;Y step, X step
	dc.l		$00430070					;height, width
	dc.l		(224*67*2)				;size of lightened data
sfltn::
	dc.l		PITCH1|PIXEL32|WID96|XADDPHR	;flags
	dc.l		sfdta					;data
	dc.l		$0001FFA0					;Y step, X step
	dc.l		$00710060					;height, width
	dc.l		(192*113*2)				;size of lightened data
wstltn::
	dc.l		PITCH1|PIXEL32|WID112|XADDPHR	;flags
	dc.l		wstdta					;data
	dc.l		$0001FF90					;Y step, X step
	dc.l		$005B0070					;height, width
	dc.l		(224*91*2)				;size of lightened data
housltn::
	dc.l		PITCH1|PIXEL32|WID128|XADDPHR	;flags
	dc.l		housdta					;data
	dc.l		$0001FF80					;Y step, X step
	dc.l		$00600080					;height, width
	dc.l		(256*96*2)				;size of lightened data


selinput::
	bsr.b	selbut					;button input
	tst.b	s_sign+O_TYPE
	bpl		seljoy					;if sign is on, check joypad
	bra		mapjoy					;if sign is off, select island piece with the joypad
;	rts

selbut::
	cmp.b	#MAIN_MENU,menuflag			;check flag for changing activity or options
	beq	mainbut
	move.l	joybothe,d0				;either player can press button
	and.l	#ANY_FIRE,d0
	beq		.90
	cmp.b	#CHANGE_OPT,menuflag
	beq.b	optbut
	cmp.b	#CHANGE_ACT,menuflag
	beq.b	actbut
	cmp.b	#CHANGE_BUT,menuflag
	beq.b	butbut
.90:
	rts

optbut:
	cmp.w	#2,bar_pos		;change speed?
	beq	chg_engopt
	cmp.w	#3,bar_pos		;change steering?
	beq	chg_speed
	cmp.w	#4,bar_pos		;change buttons?
	beq	chg_cont
	cmp.w	#5,bar_pos		;return to main menu?
	beq	opt_ret
	rts

butbut:
	move.b	#CHANGE_OPT,menuflag
	move.w	#4,bar_pos
	move.w	bar_yopt+8,d0				;use bar position number 4
	add.w	s_text+O_YPOS,d0
	move.w	d0,s_bar+O_YPOS
	bsr		draw_opt
	moveq	#$7F,d0
	and.b	d0,mvolcurs+O_TYPE
	and.b	d0,svolcurs+O_TYPE
	rts

actbut:
	move.w	#0,bar_pos				;put bar on activity
	move.b	#MAIN_MENU,menuflag			;reset flag for changing activity or options
	bsr		set_mbar
	bsr		drawstxt					;redraw sign text
	rts

mainbut:
	tst.b	s_sign+O_TYPE
	bpl.b	.20
	move.l	joybothe,d0				;either player can press button
	and.l	#ANY_FIRE,d0				;if sign is off, any fire button turns in back on
	beq		.90
	cmp.w	#1,bar_pos
	bne.b	.15
	move.w	#0,d5					;do not lighten current level
	move.w	curlevel,d7
	bsr		drawmap					;replace lightened piece of map
.15:
	bsr		drawstxt					;redraw sign text
	move.b	#SIGN_UP,signmove
	moveq	#$7F,d0
	and.b	d0,s_sign+O_TYPE			;turn sign back on when any fire button is pressed
	and.b	d0,s_text+O_TYPE
	and.b	d0,s_mask+O_TYPE
	bra.b	.90
.20:
	move.l	joybothe,d0				;either player can press button
	and.l	#ANY_FIRE,d0
	beq.b	.90
	move.w	bar_pos,d1				;which line the bar is on
	lsl.w	#2,d1
	lea		baraddrs,a0
	move.l	(a0,d1.w),a0				;get address of subroutine
	jsr		(a0)
.90:
	rts

baraddrs::
;go to these routines when fire button is pressed for each bar_pos
	dc.l		chg_act					;change activity
	dc.l		chg_wrld					;change world
	dc.l		chg_cars					;change car type for player 1
	dc.l		chg_opt						;change options
.if MODEM_ENABLED
	dc.l		chg_mdm						;change modem
.endif
	dc.l		strtgame					;start the game

chg_act::
	move.b	#CHANGE_ACT,menuflag		;set changing activity flag
	bsr	initscroll
	bra		draw_act		;redraw text on sign

chg_wrld::
	or.b		#DELETE_OBJ,s_bar+O_TYPE
	move.b	#SIGN_DOWN,signmove
	and.b	#$7F,s_mask+O_TYPE			;turn on cover
	rts

chg_cars::
	move.l	joyedge,d0				; check to see if player 1 pressed a button
	and.l	#ANY_FIRE,d0
	beq.b	.10
	bsr	chg_car1				; if yes, change his car
.10:
	move.l	joyedge2,d0
	and.l	#ANY_FIRE,d0				;check for player 2 now
	beq.b	.90
	bsr	chg_car2
.90:
	rts

chg_car1::
	lea		cur_car0,a0				;car for this player
	move.w	cur_car1,d1				;car for other player
	bra.b	chg_car
chg_car2::
	lea		cur_car1,a0				;car for this player
	move.w	cur_car0,d1				;car for other player
;	bra.b	chg_car
chg_car::
	move.w	(a0),d0					;car for this player
.10:	add.w	#1,d0
	cmp.w	#MAX_CAR_TYPES,d0
	blt.b	.20
	move.w	#0,d0					;cycle back to first car
.20:

.if 0
	cmp.w	d1,d0
	beq.b	.10						;don't allow the same car as the other player
.endif

	move.w	d0,(a0)					;save new car type
.50:	bsr		caricons					;redraw the car icons
	rts

.if MODEM_ENABLED
chg_mdm::
	move.w	modem,d0
	addq.w	#1,d0
	cmp.w	#3,d0
	bne.b	.10
	moveq	#0,d0
.10:
	move.w	d0,modem
	bra	drawstxt		;redraw text on sign
.endif

chg_opt::
	move.b	#CHANGE_OPT,menuflag
	move.w	#0,bar_pos
	move.w	bar_yopt,d0				;use top bar position
	add.w	s_text+O_YPOS,d0
	move.w	d0,s_bar+O_YPOS
	bsr		draw_opt
	moveq	#$7F,d0
	and.b	d0,mvolcurs+O_TYPE
	and.b	d0,svolcurs+O_TYPE
	rts

strtgame::
	move.w	#0,loadsdn			;club drive sign and map background will be erased
	move.w	cur_act,d0			;get current activity
	lsl.w	#2,d0				;convert to index
	lea		acop_adr,a0
	move.l	(a0,d0.w),a0			;get pointer to index of laps, dots, or time
	move.w	(a0),d1
	add.w	d1,d1
	add.w	d1,d1
	lea		acop_score,a1
	move.l	(a1,d0.w),a1			;get pointer to score table
	move.l	(a1,d1.w),scoreinc		;store appropriate score increment
	jmp		goplay
;	rts

seljoy::
	cmp.b	#CHANGE_ACT,menuflag
	beq.b	actjoy
	cmp.b	#CHANGE_OPT,menuflag
	beq	optjoy
	cmp.b	#CHANGE_BUT,menuflag
	beq	butjoy

	move.w	#MAX_BARPOS,d1				;total bar positions
	lea		bar_ypos,a0				;table of bar y positions
	bra		mv_bar

butjoy::
	move.l	joybothe,d0				;allow either player
	btst.l	#JOY_LEFT,d0
	bne.b	.30
	btst.l	#JOY_RIGHT,d0
	bne.b	.30						;ignore diagonals
	rts
.30:
; change controller options
	bsr	chg_but
	rts

actjoy::
	move.l	joybothe,d0				;allow either player
	btst.l	#JOY_LEFT,d0
	bne.b	.30
	btst.l	#JOY_RIGHT,d0
	bne.b	.30						;ignore diagonals

	moveq	#2,d1					;total positions for bar
	cmp.w	#TAG2PLR,cur_act
	bne.b	.10
	moveq	#4,d1					;tag also has the 2 tune options
.10:	lea		bar_yact,a0				;table of y positions for bar
	bsr		mv_bar
;change setting
.30:
	cmp.w	#1,bar_pos
	beq		chg_acop
	cmp.w	#2,bar_pos
	bge		chgttune

	move.l	joybothe,d0				;allow either player
	and.l	#ANY_JOY,d0
	bne.b	.32
	move.l	joybothc,d0				;allow either player
	and.l	#ANY_JOY,d0
	beq.b	.90
	addq.b	#1,joydelay+1
	cmp.b	#END_SEL_JOY_DELAY,joydelay+1
	blt.b	.90
	move.l	joybothc,d0				;allow either player
	bra.b	.35
.32:
	move.l	joybothe,d0				;allow either player
.35:
	btst.l	#JOY_LEFT,d0
	beq.b	.40
	subq.w	#1,cur_act
	cmp.w	#-1,cur_act
	bne.b	.50
	move.w	#MAX_ACTIVITIES-1,cur_act
	bra.b	.50
.40:
	btst.l	#JOY_RIGHT,d0
	beq.b	.90
	addq.w	#1,cur_act
	cmp.w	#MAX_ACTIVITIES,cur_act
	blt.b	.50
	move.w	#0,cur_act
.50:
	move.b	#0,joydelay+1
	bsr		draw_act

.90:	rts

chgttune::
	lea		tagtune0,a0
	cmp.w	#2,bar_pos
	beq.b	.10
	lea		tagtune1,a0
.10:
	move.l	joybothe,d0				;allow either player
	and.l	#ANY_JOY,d0
	bne.b	.12
	move.l	joybothc,d0				;allow either player
	and.l	#ANY_JOY,d0
	beq		.90
	addq.b	#1,joydelay+3
	cmp.b	#END_SEL_JOY_DELAY,joydelay+3
	blt		.90
	move.l	joybothc,d0				;allow either player
	bra.b	.15
.12:
	move.l	joybothe,d0				;allow either player
.15:
	btst.l	#JOY_LEFT,d0
	beq.b	.20
	sub.w	#1,(a0)
	cmp.w	#0,(a0)					;don't use first song
	bne.b	.50
	move.w	#TOTAL_SONGS,(a0)			;max means none
	bra.b	.50
.20:
	btst.l	#JOY_RIGHT,d0
	beq.b	.90
	add.w	#1,(a0)
	cmp.w	#TOTAL_SONGS+1,(a0)
	blt.b	.50
	move.w	#1,(a0)					;don't use first song (conga)
.50:
	move.b	#0,joydelay+3
	bsr		drawstng
	bsr		copytxta
	bsr		newttune
.90:
	rts

newttune:
	moveq.l	#0,d0
	cmp.w	#2,bar_pos
	bne.b	.10
	move.w	tagtune0,d0
	bra	.50
.10:
	cmp.w	#3,bar_pos
	bne.b	.90
	move.w	tagtune1,d0
.50:
	cmp.w	#TOTAL_SONGS,d0				;no music?
	beq.b	.90
	move.l	d0,songnum
	jsr	playmus

.90:	rts

chg_acop::
;change the laps, time, or dots for a activity
	move.w	cur_act,d7
	lsl.w	#1,d7
	lea		acop_min,a1
	move.w	(a1,d7.w),d1				;get the minimum setting
	lea		acop_max,a1
	move.w	(a1,d7.w),d2				;get the maximum setting
	lsl.w	#1,d7
	lea		acop_adr,a1
	move.l	(a1,d7.w),a0
;D1 = minimum setting
;D2 = maximum setting
;A0 = address of setting to change
	move.l	joybothe,d0				;allow either player
	and.l	#ANY_JOY,d0
	bne.b	.20
	move.l	joybothc,d0				;allow either player
	and.l	#ANY_JOY,d0
	beq		.90
	addq.b	#1,joydelay+2
	cmp.b	#END_SEL_JOY_DELAY,joydelay+2
	blt		.90
	move.l	joybothc,d0				;allow either player
	bra.b	.30
.20:
	move.l	joybothe,d0				;allow either player
.30:
	btst.l	#JOY_LEFT,d0
	beq.b	.40
	cmp.w	(a0),d1					;compare to minimum
	beq.b	.90
	subq.w	#1,(a0)
	bra.b	.50
.40:
	btst.l	#JOY_RIGHT,d0
	beq.b	.90
	cmp.w	(a0),d2					;compare to maximum
	beq.b	.90
	addq.w	#1,(a0)
.50:
	move.b	#0,joydelay+2
	bsr		drawstng
	bsr		copytxta
.90:
	rts

;
; tables to translate user's selection into
; "seconds", "laps", or whatever; and also
; the corresponding amounts for "scoreinc"
; "scoreinc*number of scoring events" should
; make $3c000000 (60 in 8.24 notation)
;
laptrans::
	dc.w	1, 2, 3, 4, 5, 6
lapscore::
	dc.l	$3c000000,$1e000000,$14000000,$0f000000,$0c000000,$0a000000
timetrans::
	dc.w	   30,60,90,120,180
timescore::
	dc.l	$1b4e8,$da74,$91a3,$6d3a,$48d1
.if 1
; production code
dottrans::
	dc.w	5,10,20,30,40
dotscore::
	dc.l	$0c000000,$06000000,$03000000,$02000000,$01800000
.else
; debugging code
dottrans::
	dc.w	1,10,20,30,40
dotscore::
	dc.l	$3c000000,$06000000,$03000000,$02000000,$01800000
.endif

acop_min::
	dc.w		MIN_LAPS
	dc.w		MIN_LAPS
	dc.w		MIN_TAGTIME
	dc.w		MIN_DOTS
	dc.w		MIN_DOTS
acop_max::
	dc.w		MAX_LAPS
	dc.w		MAX_LAPS
	dc.w		MAX_TAGTIME
	dc.w		MAX_DOTS
	dc.w		MAX_DOTS
acop_adr::
	dc.l		rac1laps
	dc.l		rac2laps
	dc.l		tagtime
	dc.l		col1dots
	dc.l		col2dots
acop_trans::
	dc.l		laptrans
	dc.l		laptrans
	dc.l		timetrans
	dc.l		dottrans
	dc.l		dottrans
acop_score::
	dc.l		lapscore
	dc.l		lapscore
	dc.l		timescore
	dc.l		dotscore
	dc.l		dotscore

mv_bar::
;see if bar should move
;D1 = max for bar_pos
;A0 = table for bar ypos
	move.l	joybothe,d0				;allow either player
	and.l	#ANY_JOY,d0
	bne.b	.20
	move.l	joybothc,d0				;allow either player
	and.l	#ANY_JOY,d0
	beq		.90
	addq.b	#1,joydelay
	cmp.b	#END_SEL_JOY_DELAY,joydelay
	blt		.90
	move.l	joybothc,d0				;allow either player
	bra.b	.40
.20:
	move.l	joybothe,d0				;allow either player
.40:
	btst.l	#JOY_UP,d0
	beq.b	.50
	subq.w	#1,bar_pos
	cmp.w	#-1,bar_pos
	bne.b	.60
	move.w	d1,bar_pos
	subq.w	#1,bar_pos				;put bar at max - 1
	bra.b	.60
.50:
	btst.l	#JOY_DOWN,d0
	beq.b	.90
	addq.w	#1,bar_pos
	cmp.w	bar_pos,d1				;compare to maximum bar_pos in D1
	bne.b	.60
	move.w	#0,bar_pos
.60:
	move.b	#0,joydelay
	bsr		set_bar
	bsr	initscroll
;
; if we just landed on a new "TAG TUNE:" line, we need
; to play that tune
;
	cmp.b	#CHANGE_ACT,menuflag
	bne.b	.90
	bsr	newttune
.90:	rts

optjoy::
	moveq	#6,d1					;total positions for bar
	lea		bar_yopt,a0				;table of y positions for bar
	bsr		mv_bar

	cmp.w	#0,bar_pos
	beq.b	chg_mus					;change music
	cmp.w	#1,bar_pos
	beq		chg_snd					;change sound effects
	cmp.w	#2,bar_pos
	beq		chg_engopt				;change engine
	cmp.w	#3,bar_pos
	beq		chg_speed				;change speed setting
	rts

chg_mus::
;change the music volume
	move.l	joybothc,d0				;allow either player
	btst.l	#JOY_LEFT,d0
	beq.b	.40
	cmp.w	#0,mus_vol						;compare to minimum
	beq.b	.40
	subq.w	#1,mus_vol
	bra.b	.50
.40:
	btst.l	#JOY_RIGHT,d0
	beq.b	.90
	cmp.w	#MAX_VOLUME,mus_vol					;compare to maximum
	beq.b	.50
	addq.w	#1,mus_vol
.50:
	move.w	mus_vol,d0
	add.w	#VOL_CURSX,d0
	cmp.w	#VOL_CURSX_MAX,d0
	blt.b	.60
	move.w	#VOL_CURSX_MAX,d0
.60:	move.w	d0,mvolcurs+O_XPOS					;set X position for music volume cursor

	bsr		set_mvol
.90:
	rts

chg_snd::
;change the sound effects volume
	move.l	joybothc,d0						;allow either player
	btst.l	#JOY_LEFT,d0
	beq.b	.40
	cmp.w	#0,snd_vol						;compare to minimum
	beq.b	.40
	subq.w	#1,snd_vol
	bra.b	.50
.40:
	btst.l	#JOY_RIGHT,d0
	beq.b	.90
	cmp.w	#MAX_VOLUME,snd_vol					;compare to maximum
	beq.b	.50
	addq.w	#1,snd_vol
.50:
	move.w	snd_vol,d0
	add.w	#VOL_CURSX,d0
	cmp.w	#VOL_CURSX_MAX,d0
	blt.b	.60
	move.w	#VOL_CURSX_MAX,d0
.60:	move.w	d0,svolcurs+O_XPOS					;set X position for sound volume cursor

	bsr		set_svol
.90:
	rts

chg_speed::
	lea	speedopt,a0
	lea	drawspeed,a1
	move.w	#MAX_OPTSPEED,d1
	bra.b	chg_thing

chg_engopt::
	lea	engoffopt,a0
	lea	drawengopt,a1
	move.w	#MAX_ENGOPT,d1
;	bra.b	chg_thing

;
; change a slidable option
; parameters:
; a0 == pointer to variable
; d1 == max value for variable
; a2 == routine for redrawing variable
;
chg_thing::
;change some settings
;fire button is the same as right arrow
	move.l	joybothe,d0						;allow either player
	move.l	d0,d2
	and.l	#(ANY_JOY),d2
	bne.b	.10

	move.l	joybothc,d0						;allow either player
	move.l	d0,d2
	and.l	#(ANY_JOY|ANY_FIRE),d2
	beq.b	.90
	addq.b	#1,joydelay+4
	cmp.b	#END_SEL_JOY_DELAY,joydelay+4
	blt.b	.90
	move.l	d0,d2
	and.l	#(ANY_FIRE),d2						;fire button is the same as right arrow
	bne.b	.41
.10:
	btst.l	#JOY_LEFT,d0
	beq.b	.40
	subq.w	#1,(a0)
	move.w	(a0),d0
	cmp.w	#-1,d0
	bne.b	.50
	move.w	d1,(a0)
	bra.b	.50
.40:
	btst.l	#JOY_RIGHT,d0
	beq.b	.90
.41:
	move.w	(a0),d0
	cmp.w	d1,d0							;at max.?
	beq.b	.45
	addq.w	#1,(a0)
	bra.b	.50
.45:
	move.w	#0,(a0)
.50:
	move.b	#0,joydelay+4
	jsr	(a1)							;redraw the option
.90:
	rts

;
; return from the Options menu
;
opt_ret::
	bsr	save_opt		;update option setting in eeprom if necessary
	move.b	#MAIN_MENU,menuflag			;reset flag for changing activity or options
	or.b		#DELETE_OBJ,mvolcurs+O_TYPE	;turn off music volume cursor
	or.b		#DELETE_OBJ,svolcurs+O_TYPE	;turn off sound volume cursor
	move.w	#3,bar_pos				;put bar on "options" menu item
	bsr		set_mbar
	bsr		drawstxt					;redraw sign text
	jsr		wait_int
	rts

chg_cont::
	move.w	#0,bar_pos
	move.b	#CHANGE_BUT,menuflag
	or.b		#DELETE_OBJ,mvolcurs+O_TYPE	;turn off music volume cursor
	or.b		#DELETE_OBJ,svolcurs+O_TYPE	;turn off sound volume cursor
	bsr	set_mbar
	bra	draw_but

chg_but:
	movea.l	#A1_PIXEL, a0
	moveq	#0,d0
	move.l	d0,B_PATD-A1_PIXEL(a0)
	move.l	d0,B_PATD+4-A1_PIXEL(a0)
;change the controller settings
	move.l	joybothe,d0						;allow either player
	and.l	#ANY_JOY,d0
	bne.b	.10
	move.l	joybothc,d0						;allow either player
	and.l	#ANY_JOY,d0
	beq.b	.90
	addq.b	#1,joydelay+5
	cmp.b	#END_SEL_JOY_DELAY,joydelay+5
	blt.b	.90
	move.l	joybothc,d0						;allow either player
	bra.b	.20
.10:
	move.l	joybothe,d0						;allow either player
.20:
	btst.l	#JOY_LEFT,d0
	beq.b	.40
	cmp.w	#0,cont_opt						;compare to minimum
	beq.b	.90
	subq.w	#1,cont_opt
	bra.b	.50
.40:
	btst.l	#JOY_RIGHT,d0
	beq.b	.90
	cmp.w	#MAX_CONTROL,cont_opt				;compare to maximum
	beq.b	.90
	addq.w	#1,cont_opt
.50:
; clear under
;	movea.l	#A1_PIXEL, a0
	move.l	#$000b0042,(a0)					;Y,X position
	move.l	#PITCH1|PIXEL32|WID48|XADDPHR,A1_FLAGS-A1_PIXEL(a0)	;destination
	move.l	#$0001FFf0,A1_STEP-A1_PIXEL(a0)					;high = Y step, low = negative width
	move.l	#$001b0010,B_COUNT-A1_PIXEL(a0)					;high = height, low = width
;	moveq	#0,d0
;	move.l	d0,A1_PIXEL						;set rectangle Y,X
;	move.l	d0,B_PATD-A1_PIXEL(a0)
;	move.l	d0,B_PATD+4-A1_PIXEL(a0)
	move.l	#PATDSEL|UPDA1,B_CMD-A1_PIXEL(a0)				;turn on blitter

	move.b	#0,joydelay+5
	bsr		but_only						;draw just the buttons part of sign
.90:
	rts


set_mbar::
	lea		bar_ypos,a0
set_bar::
;A0 = table of bar y positions
	move.w	bar_pos,d0
	lsl.w	#1,d0
	move.w	(a0,d0.w),d0
	add.w	s_text+O_YPOS,d0
	move.w	d0,s_bar+O_YPOS
	rts
bar_ypos::
;add to text object ypos
	dc.w		0
	dc.w		22
	dc.w		44
	dc.w		66
	dc.w		88
	dc.w		110
	dc.w		132
;	dc.w		122
bar_yopt::
;add to text object ypos when selecting options
	dc.w		0
	dc.w		22
	dc.w		44
	dc.w		66
	dc.w		88
	dc.w		110
bar_yact::
	dc.w		0
	dc.w		20
	dc.w		40
	dc.w		60
	dc.w		80

mapjoy::
	move.l	joybothe,d0				;allow either player
	btst.l	#JOY_LEFT,d0
	beq.b	.10
	moveq	#SF_LEVEL,d6				;left = SAN FRANCISCO
	bra.b	.15						;don't need to check JOY_RIGHT
.10:
	btst.l	#JOY_RIGHT,d0
	beq.b	.20
	moveq	#WEST_LEVEL,d6				;right = WEST WORLD
.15:
	bsr		ltn_new
.20:
	move.l	joybothe,d0				;allow either player
	btst.l	#JOY_UP,d0
	beq.b	.30
	moveq	#FUTURE_LEVEL,d6			;up = FUTURE WORLD
	bra.b	.50						;don't need to check JOY_DOWN
.30:
	btst.l	#JOY_DOWN,d0
	beq.b	.60
	moveq	#HOUSE_LEVEL,d6			;down = HOUSE
.50:
	bra.b	ltn_new
.60:
	move.l	#(1<<KEY_4)|(1<<KEY_2), d1	; '42'
	and.l	d1, d0					;did somebody just push a 4 or a 2?
	beq.b	.90
	move.l	#ANY_KEY, d2
	move.l	joycur,d0					;allow either player - but not a combo of both
	and.l	d2, d0
	cmp.l	d1, d0					; '42'
	beq.b	.95
	move.l	joycur2,d0				;check the other player
	and.l	d2, d0
	cmp.l	d1, d0					; '42'
	beq.b	.95
.90:
	rts
.95:
	moveq	#SECRET_LEVEL, d6
	; fall into ltn_new

ltn_new::
;change which map piece is lightened, when joypad is moved
;d6 = level that was just selected
	move.w	curlevel,d7				;remember current level
	move.w	d6,curlevel				;set new level
	cmp.w	d6,d7					;compare previous level to new level
	beq.b	.90						;don't need to redraw if it didn't change
	moveq	#0,d5					;clear flag so current level is not lightened
	bsr		drawmap					;change lightened piece to normal color
	bsr		ltn_map					;lighten current selected piece, set D7 to current level
	moveq	#1,d5					;lighten current level
	bsr		drawmap					;draw current selected piece
.90:	rts

blitatxt::
	move.l	#seltexta,A1_BASE					;destination address
	bra.b	blittxt
blitstxt::
	move.l	#seltext,A1_BASE					;destination address
blittxt::
;A0 = address of string to print
;A1_BASE set to destination address
	lea		fontaddr,a5
	lea		font_wid,a6
	clr.l	d1
	move.w	d5,d4				;save left margin
	move.l	#PITCH1|PIXEL8|WID192|XADDPHR,A1_FLAGS	;description of destination area
	move.l	#PITCH1|PIXEL8|WID8|XADDPHR,A2_FLAGS	;description of source data
.10:
	move.w	d4,d5				;set left margin
.15:
	clr.l	d0
	move.b	(a0)+,d0				;get the character
	beq.b	.90
	cmp.b	#']',d0				;return
	bne.b	.20
	add.l	#$000A0000,d5			;move down 1 line
	bra.b	.10					;reset left margin
.20:	sub.b	#' ',d0				;address and width tables start with this character
	lsl.w	#2,d0				;4 bytes per character address
	move.l	(a5,d0.w),A2_BASE		;address of current character data
	beq.b	.50					;if 0, it is some blank space
	bsr.b	blitschr
.50:	lsr.w	#2,d0				;change char * 4 to char
.60:	move.b	(a6,d0.w),d1			;get width of this character
	add.w	d1,d5				;add width of character
	bra.b	.15
.90:	rts

blitschr::
;d5 is the top left corner Y,X
;A2_BASE is set to the address of the image data
	move.l	#$006000C0,A1_CLIP				;192x96 clipping area
	move.l	d5,A1_PIXEL					;Y,X position to write data in destination area
	move.l	#0,A2_PIXEL					;start at 0,0 of source image
	move.l	#$0001FFF8,d2					;set Y step to 1, X step to negative width
	move.w	d5,d6
	and.w	#7,d6						;and with X position
	beq.b	.20
	subq.w	#8,d2						;move left 1 phrase
	add.w	d6,d2						;add offset from phrase boundary
.20:	move.l	d2,A1_STEP					;Y step, X step

	move.l	#$0001FFF8,d2					;set Y step to 1, X step to negative width
	cmp.w	#0,d6						;check X position anded with 7
	beq.b	.40							;if 0, no adjustment needed
	subq.w	#8,d2						;move left 1 phrase
.40:	move.l	d2,A2_STEP					;Y step, X step
	move.l	#$00070008,B_COUNT				;height, width of source image
	move.l	#UPDA1|UPDA2|SRCEN|LFU_A|LFU_AN|CLIP_A1,B_CMD	;turn on blitter
	rts

act_str::
	dc.l		act_rac1,act_rac2,act_tag,act_col1,act_col2
act_tag::
	dc.b		'GAME:  2 PLAYER TAG',0
act_col1::
	dc.b		'GAME:  1 PLR COLLECT',0
act_col2::
	dc.b		'GAME:  2 PLR COLLECT',0
act_rac1::
	dc.b		'GAME: 1 PLAYER RACE',0
act_rac2::
	dc.b		'GAME: 2 PLAYER RACE',0

	.even
wrldstr::
	dc.l		wrld_fut,wrld_sf,wrld_wst,wrld_hs,wrld_ty
wrld_fut::
	dc.b		'WORLD: VELOCITY PARK',0
wrld_sf::
	dc.b		'WORLD: SAN FRANCISCO',0
wrld_wst::
	dc.b		'WORLD: THE OLD WEST',0
wrld_hs::
	dc.b		'WORLD: JEROME',39,'S PAD',0
wrld_ty::
	dc.b		'WORLD: PLANET TODD',0

car_str0::
	dc.b		'CAR 1:',0
car_str1::
	dc.b		'CAR 2:',0

opt_str::
	dc.b		'OPTIONS',0

.if MODEM_ENABLED
modem_str::
	dc.b		'NO MODEM',0
call_str::
	dc.b		'CALL',0
answ_str::
	dc.b		'ANSWER',0
.endif

strt_str::
	dc.b		'START GAME',0

ins0_str::
	dc.b	'  PRESS FIRE TO SELECT A NEW GAME  '
nulstr:
	dc.b	0
ins1_str::
	dc.b	'  PRESS FIRE TO SELECT A NEW WORLD  ', 0
ins2_str::
	dc.b	'  PRESS FIRE TO CHANGE YOUR CAR  ', 0
ins3_str::
	dc.b	'  PRESS FIRE FOR MORE OPTIONS  ', 0
.if MODEM_ENABLED
ins4_str::
	dc.b	'  PRESS FIRE TO CHANGE MODEM SETTING ', 0
.endif
ins5_str::
	dc.b	'  PRESS FIRE TO START GAME  ', 0

ains0::
	dc.b	'  USE LEFT OR RIGHT ARROW TO CHANGE GAME, PRESS FIRE TO RETURN TO MAIN MENU  ',0
ains1::
	dc.b	'  USE LEFT OR RIGHT ARROW TO CHANGE NUMBER, PRESS FIRE TO RETURN TO MAIN MENU  ', 0
ains2::
	dc.b	'  USE LEFT OR RIGHT ARROW TO CHANGE TUNE  ', 0

oins0::
	dc.b	'  USE LEFT OR RIGHT ARROW TO CHANGE MUSIC VOLUME  ', 0
oins1::
	dc.b	'  USE LEFT OR RIGHT ARROW TO CHANGE SOUND EFFECTS VOLUME  ', 0
oins2::
	dc.b	'  USE LEFT OR RIGHT ARROW TO CHANGE GAME SPEED  ', 0
oins3::
	dc.b	'  USE LEFT OR RIGHT ARROW TO CHANGE CONTROLLER  ', 0
oins4::
	dc.b	'  PRESS FIRE TO CHANGE MEANING OF BUTTONS  ', 0
oins5::
	dc.b	'  PRESS FIRE TO RETURN TO MAIN MENU  ', 0

bins0:
	dc.b	'  USE LEFT OR RIGHT ARROW TO CHANGE BUTTONS, PRESS FIRE TO RETURN TO OPTIONS MENU ', 0

	.even
main_instructions:
	dc.l	ins0_str, ins1_str, ins2_str, ins3_str
.if MODEM_ENABLED
	dc.l	 ins4_str
.endif
	dc.l	ins5_str
act_instructions:
	dc.l	ains0, ains1, ains2, ains2
opt_instructions:
	dc.l	oins0, oins1, oins2, oins3, oins4, oins5
but_instructions:
	dc.l	bins0

sel_acl0::
	dc.l		sel_act0,sel_act1,sel_act2,sel_act3,sel_act4
sel_acl1::
	dc.l		sel_act5,sel_act5,sel_act6,sel_act7,sel_act8
sel_act0::
	dc.b		'RACING   1 PLAYER]'
	dc.b		'LAPS:',0
sel_act1::
	dc.b		'RACING   2 PLAYERS]'
	dc.b		'LAPS:',0
sel_act2::
	dc.b		'TAG   2 PLAYERS]'
	dc.b		'TIME:]'
	dc.b		'TUNE 1:]'
	dc.b		'TUNE 2:',0
sel_act3::
	dc.b		'COLLECT   1 PLAYER]'
	dc.b		'POWERBALLS:',0
sel_act4::
	dc.b		'COLLECT   2 PLAYERS]'
	dc.b		'POWERBALLS:',0
sel_act5::
	dc.b		'RACE BETWEEN TWO]'
	dc.b		'CHECKPOINTS FOR THE]'
	dc.b		'SELECTED NUMBER OF]'
	dc.b		'LAPS'
	dc.b		0

sel_act6::
	dc.b		']'
	dc.b		']'
	dc.b		'AVOID BEING IT FOR]'
	dc.b		'THE SELECTED TIME]'
	dc.b		0

sel_act7::
	dc.b		'COLLECT POWERBALLS]'
	dc.b		'AS QUICKLY AS YOU]'
	dc.b		'CAN'
	dc.b		0
sel_act8::
	dc.b		'BE FIRST TO COLLECT]'
	dc.b		'THE SELECTED NUMBER]'
	dc.b		'OF POWERBALLS'
	dc.b		0

.if 0
sel_acc::
	dc.b		'PRESS FIRE TO ACCEPT',0
.endif

	.even
tgtunes::
	dc.l		0,tgtune1,tgtune2,tgtune3,tgtune4,tgtune5,tgtune6,tgtune7
tgtune1::
	dc.b		'GARTERS',0
tgtune2::
	dc.b		'TENDERLOIN',0
tgtune3::
	dc.b		'SPIN OUT',0
tgtune4::
	dc.b		'DRIVE BY',0
tgtune5::
	dc.b		'SUNSET BEACH',0
tgtune6::
	dc.b		'CLUB WAVE',0
tgtune7::
	dc.b		'NONE',0

	.even
sel_opt2::
	dc.l		sel_op03,sel_op04,sel_op05,sel_op06,sel_op07,sel_op08
sel_op01::
	dc.b		'MUSIC:',0
sel_op02::
	dc.b		'SOUND:',0

sel_ops0::
	dc.b		'SPEED:    SLOW',0
sel_ops1::
	dc.b		'SPEED:    FAST',0

sel_opw0::
	dc.b		'ENGINES:  NOISY',0
sel_opw1::
	dc.b		'ENGINES:  SILENT',0


sel_ops2::
	dc.b		'            ',0

sel_opr::
	dc.b		'RETURN TO MAIN MENU', 0
sel_opb::
	dc.b		'BUTTONS', 0

but_opb::
	dc.b		'BUTTONS:]'
	dc.b		'    A]'
	dc.b		'    B]'
	dc.b		'    C'
	dc.b		0
sel_op03::
	dc.b		'BRAKES     ]'
	dc.b		'FORWARD]'
	dc.b		'REVERSE    '
	dc.b		0
sel_op04::
	dc.b		'BRAKES     ]'
	dc.b		'REVERSE    ]'
	dc.b		'FORWARD'
	dc.b		0
sel_op05::
	dc.b		'FORWARD]'
	dc.b		'BRAKES     ]'
	dc.b		'REVERSE    '
	dc.b		0
sel_op06::
	dc.b		'REVERSE    ]'
	dc.b		'BRAKES     ]'
	dc.b		'FORWARD'
	dc.b		0
sel_op07::
	dc.b		'FORWARD]'
	dc.b		'REVERSE    ]'
	dc.b		'BRAKES     '
	dc.b		0
sel_op08::
	dc.b		'REVERSE    ]'
	dc.b		'FORWARD]'
	dc.b		'BRAKES     '
	dc.b		0


	.even

selolst::
;s_scr_l::
	dc.w		0			;xpos
	dc.w		0			;ypos
	dc.l		selscr		;data
	dc.w		287			;height
	dc.w		112			;dwidth
	dc.w		56			;iwidth
	dc.b		0			;flags
	dc.b		0			;firstpix
	dc.b		0			;type
	dc.b		4			;depth
	dc.b		1			;pitch
	dc.b		0			;index
	dc.w		0			;desc
	dc.l		0			;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------
;s_scr_m::
	dc.w		224			;xpos
	dc.w		0			;ypos
	dc.l		selscr		;data
	dc.w		287			;height
	dc.w		1			;dwidth
	dc.w		1			;iwidth
	dc.b		RELEASE_ON	;flags
	dc.b		0			;firstpix
	dc.b		0			;type
	dc.b		0			;depth
	dc.b		1			;pitch
	dc.b		0			;index
	dc.w		0			;desc
	dc.l		0			;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------
;s_scr_r::
	dc.w		224			;xpos
	dc.w		0			;ypos
	dc.l		selscr+448	;data
	dc.w		287			;height
	dc.w		112			;dwidth
	dc.w		56			;iwidth
	dc.b		0			;flags
	dc.b		0			;firstpix
	dc.b		0			;type
	dc.b		4			;depth
	dc.b		1			;pitch
	dc.b		0			;index
	dc.w		0			;desc
	dc.l		0			;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------
;s_club::
	dc.w		152			;xpos
	dc.w		0			;ypos
	dc.l		clubdta		;data
	dc.w		80			;height
	dc.w		40			;dwidth
	dc.w		40			;iwidth
	dc.b		TRANS_ON		;flags
	dc.b		0			;firstpix
	dc.b		0			;type
	dc.b		4			;depth
	dc.b		1			;pitch
	dc.b		0			;index
	dc.w		0			;desc
	dc.l		0			;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------
;s_sign::
	dc.w		143			;xpos
	dc.w		0			;ypos
	dc.l		selsign		;data
	dc.w		96			;height
	dc.w		48			;dwidth
	dc.w		48			;iwidth
	dc.b		TRANS_ON		;flags
	dc.b		0			;firstpix
	dc.b		0			;type
	dc.b		4			;depth
	dc.b		1			;pitch
	dc.b		0			;index
	dc.w		0			;desc
	dc.l		0			;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------
;s_bar::
	dc.w		147			;xpos
	dc.w		0			;ypos
	dc.l		selbar		;data
	dc.w		11			;height
	dc.w		3			;dwidth
	dc.w		3			;iwidth
	dc.b		TRANS_ON		;flags
	dc.b		0			;firstpix
	dc.b		0			;type
	dc.b		0			;depth
	dc.b		1			;pitch
	dc.b		8			;index		colors $10,11
	dc.w		0			;desc
	dc.l		0			;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------
;s_text::
	dc.w		147			;xpos		s_sign xpos + 19
	dc.w		0			;ypos
	dc.l		seltext		;data
	dc.w		76			;height
	dc.w		24			;dwidth
	dc.w		24			;iwidth
	dc.b		TRANS_ON		;flags
	dc.b		0			;firstpix
	dc.b		0			;type
	dc.b		3			;depth
	dc.b		1			;pitch
	dc.b		0			;index
	dc.w		0			;desc
	dc.l		0			;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------
;s_mask::
	dc.w		120			;xpos
	dc.w		0			;ypos
	dc.l		hmskdta		;data
	dc.w		45			;height
	dc.w		56			;dwidth
	dc.w		56			;iwidth
	dc.b		TRANS_ON		;flags
	dc.b		0			;firstpix
	dc.b		0			;type
	dc.b		4			;depth
	dc.b		1			;pitch
	dc.b		0			;index
	dc.w		0			;desc
	dc.l		0			;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------
;mvolcurs::
	dc.w		0			;xpos
	dc.w		0			;ypos
	dc.l		volcdata		;data
	dc.w		7			;height
	dc.w		1			;dwidth
	dc.w		1			;iwidth
	dc.b		TRANS_ON		;flags
	dc.b		0			;firstpix
	dc.b		0			;type
	dc.b		3			;depth
	dc.b		1			;pitch
	dc.b		0			;index
	dc.w		0			;desc
	dc.l		0			;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------
;svolcurs::
	dc.w		0			;xpos
	dc.w		0			;ypos
	dc.l		volcdata		;data
	dc.w		7			;height
	dc.w		1			;dwidth
	dc.w		1			;iwidth
	dc.b		TRANS_ON		;flags
	dc.b		0			;firstpix
	dc.b		0			;type
	dc.b		3			;depth
	dc.b		1			;pitch
	dc.b		0			;index
	dc.w		0			;desc
	dc.l		0			;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------
;s_sign_l::
	dc.w		132			;xpos
	dc.w		0			;ypos
	dc.l		stonedta		;data
	dc.w		287			;height
	dc.w		112			;dwidth
	dc.w		56			;iwidth
	dc.b		0			;flags
	dc.b		0			;firstpix
	dc.b		1			;type
	dc.b		4			;depth
	dc.b		1			;pitch
	dc.b		0			;index
	dc.w		0			;desc
	dc.l		$00202020		;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------
;s_sign_r::
	dc.w		132			;xpos
	dc.w		0			;ypos
	dc.l		stonedta+448	;data
	dc.w		287			;height
	dc.w		112			;dwidth
	dc.w		56			;iwidth
	dc.b		0			;flags
	dc.b		0			;firstpix
	dc.b		1			;type
	dc.b		4			;depth
	dc.b		1			;pitch
	dc.b		0			;index
	dc.w		0			;desc
	dc.l		$00202020		;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------


;
; scrolling text code
;
scrollit::
	cmp.b	#MAIN_MENU,menuflag		;check for whether we're on the main menu
	beq.b	.mkscroll
	cmp.b	#CHANGE_ACT,menuflag
	beq.b	.mkscroll
	cmp.b	#CHANGE_OPT,menuflag
	beq.b	.mkscroll
	cmp.b	#CHANGE_BUT,menuflag
	beq.b	.mkscroll
	rts

.mkscroll:
	moveq	#0,d0
	moveq	#0,d6
	lea	scrlbytes,a2
	move.b	(a2),d0				; get first character of scroll
	sub.w	#' ',d0				; font tables start at ' '
	lea	font_wid,a3
	move.b	(a3,d0.w),d0			; get width
	cmp.w	scrolloff,d0			; is the offset greater?
	bpl.b	.printit			; no: go ahead and print the string
;
; here we have to scroll the current contents of "scrlbytes" left by 1, and fetch
; the next character from "scrollstr"
;
	lea	scrlbytes,a2
.scrollit:
	move.b	1(a2),d0			; fetch next character
	move.b	d0,(a2)+			; copy it into this position
	bne.b	.scrollit			; keep going until end of string

.newchar:
	move.l	scrollstr,a0
	move.w	scrollpos,d1			; see where we are in the scroll string
	add.w	#1,scrollpos
	move.b	(a0,d1.w),d0			; fetch next byte
	bne.b	.nonzero			; if end of string...
	move.w	#0,scrollpos
	bra.b	.newchar
.nonzero:
	move.b	d0,-1(a2)			; store into last position of scrlbytes
	move.w	#0,scrolloff

.printit:
	cmp.b	#CHANGE_ACT,menuflag
	beq.b	.drawona
.drawons:
;
; erase the old string
;
	lea	seltext,a0
	move.l	#$00440003,d0
	move.l	#$000700BD,d1
	moveq.l	#0,d2
	bsr	eraseline
;
; OK, now draw the string
;
	lea	scrlbytes,a0
	move.l	#$00440003,d5
	sub.w	scrolloff,d5
	add.w	#1,scrolloff
	bra	blitstxt			; returns to caller!!!
.drawona:
;
; erase the old string
;
	lea	seltexta,a0
	move.l	#$00440003,d0
	move.l	#$000700BD,d1
	moveq.l	#0,d2
	bsr	eraseline
;
; OK, now draw the string
;
	lea	scrlbytes,a0
	move.l	#$00440003,d5
	sub.w	scrolloff,d5
	add.w	#1,scrolloff
	bsr	blitatxt
	bsr	copytxta		; copy alternate buffer over onto the screen
.ret:
	rts
;
; fill part of a line with background color
; parameters:	d0 = starting pixel
;		a0 = base of window
;		d1 = height,width of window to clear
;		d2 = pattern to put in window
eraseline:
	move.l	d0,A1_PIXEL
	move.l	a0,A1_BASE
	move.l	#PITCH1|PIXEL8|WID192|XADDPIX,A1_FLAGS	;description of destination area
	move.l	#$006000C0,A1_CLIP				;192x96 clipping area
	move.l	d1,B_COUNT
	neg	d1						; figure out step value
	swap	d1
	move.w	#1,d1
	swap	d1
	move.l	d1,A1_STEP
	move.l	#0,A1_FSTEP
	move.l	d2,B_PATD
	move.l	d2,B_PATD+4
	move.l	#UPDA1|PATDSEL|CLIP_A1,B_CMD			;turn on blitter
	rts

initscroll:
	movem.l	d0-d2/a0-a1,-(sp)
	lea	main_instructions,a1
	cmp.b	#MAIN_MENU,menuflag
	beq.b	.doscroll
	lea	act_instructions,a1
	cmp.b	#CHANGE_ACT,menuflag
	beq.b	.doscroll
	lea	opt_instructions,a1
	cmp.b	#CHANGE_OPT,menuflag
	beq.b	.doscroll
	lea	but_instructions,a1
	cmp.b	#CHANGE_BUT,menuflag
	beq.b	.doscroll
	rts
;
; initialize the scrolling text buffer for the
; main billboard, based upon the current value
; of bar_pos
;
.doscroll:

	move.w	bar_pos,d1			; figure out which string we should be on
	add.w	d1,d1
	add.w	d1,d1
	move.l	(a1,d1.w),a1			; this is the source string
	move.l	a1,scrollstr

; copy to the scrolling text area
	move.w	#0,d2				; d2 is the string position counter
	move.w	#MAX_SCROLL-1,d1		; d1 is the loop counter
	lea	scrlbytes,a0			; destination for copy
.slp:
	move.b	(a1)+, d0			; get next byte
	add.w	#1,d2				; bump up position
	bne.b	.10
	move.l	scrollstr,a1			; go back to start of string
	move.w	#0,d2
.10:
	move.b	d0,(a0)+
	dbra	d1,.slp

	move.b	#0,(a0)
	move.w	#0,scrolloff
	move.w	d2,scrollpos

	movem.l	(sp)+,d0-d2/a0-a1
	rts
