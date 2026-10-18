	.include	'eq.s'
	.include	'externs.s'

SIGN_ON		equ	500					;when club drive sign turns on
TITLE_LIMIT	equ	2000					;maximum value for titlestp, go to credits at this point

C_LOAD		equ	18					;when car should be loaded
C_GO		equ	C_LOAD+1			;when car should start to move

C_XSTART	equ	-64					;starting x position for the car

N_CAR_YSTART	equ	N_SCRN_TOP+458			;starting Y position for car before it moves for NTSC
N_CAR_YEND	equ	N_SCRN_TOP+298			;ending Y position for car when it stops for NTSC
.if 0
P_CAR_YSTART	equ	P_SCRN_TOP+458			;starting Y position for car before it moves for PAL
P_CAR_YEND	equ	P_SCRN_TOP+298			;ending Y position for car when it stops for PAL
.else
P_CAR_YSTART	equ	P_SCRN_TOP+558			;starting Y position for car before it moves for PAL
P_CAR_YEND	equ	P_SCRN_TOP+398			;ending Y position for car when it stops for PAL
.endif

	.text
titleloop::
	addq.w	#1,titlestp				;increase animation counter

	bsr		mv_tcar					;move the car
	bsr		mv_tsign					;move and scale club drive sign only after it has been turned on

	cmp.w	#TITLE_LIMIT,titlestp
	bge		gocredit					;go to credits after club drive sign has been displayed long enough

	cmp.w	#HISCORE_MODE,oldgmode
	beq.b	.20
	bsr		ttlfade					;fade in from black background
	bra.b	.40
.20:	bsr		ttlcross					;cross fade with high score screen
.40:
	move.w	#-1,t_scr_m+O_TYPE			;delete the release object
	lea		titlobjs,a1				;address of first object header
	moveq	#TITLE_OBJS,d6				;total objects in list
	lea		olist_ram,a2
	bsr		build					;build packed object list
	move.l		#olist_ram,listAddr
	move.w		#1,listgood
	bsr		input					;check for restart
	bsr		titlinput
	rts

ttlfade::
	cmp.l	#MAX_BRIGHT,bright
	bne.b	.10
	cmp.w	#1,loadsdn				;see if club drive sign and map background have been loaded
	beq.b	.90						;just exit if other screens have been loaded
	bra		ld_scrns

.10:	add.l	#1,bright					;increase brightness
	cmp.l	#backgr1,t_scr+O_DATA
	blt.b	.20						;if using backgr0, switch to backgr1
	move.l	#backgr0,d0				;data for t_scr object and destination for doing fade
	bra.b	.40
.20:
	move.l	#backgr1,d0				;data for t_scr object and destination for doing fade
.40:
	move.l	d0,d1					;leave start of backgr0 or backgr1 in D0 for do_fade
	cmp.b	#NTSC,pal_ntsc
	bne.b	.50
	add.l	#(448*32*2),d1				;skip 32 lines for NTSC
.50:
	move.l	d1,t_scr+O_DATA
	move.l	#titlescr,d1				;D0 = destination, D1 = source pic
	bsr		do_fade
.90:
	rts

ttlcross::
	cmp.l	#MAX_CROSSCNT,crosscnt
	bne.b	.10
	cmp.w	#1,loadsdn				;see if club drive sign and map background have been loaded
	beq.b	.90						;just exit if other screens have been loaded
	bra		ld_scrns

.10:	add.l	#1,crosscnt
	cmp.l	#backgr1,t_scr+O_DATA
	blt.b	.20
	move.l	#backgr0,d0				;data for t_scr object and destination for doing fade
	bra.b	.30
.20:
	move.l	#backgr1,d0				;data for t_scr object and destination for doing fade
.30:
	move.l	d0,d4					;leave backgr0 or backgr1 in D0 for do_cross
	move.l	#credscr,d1				;source pic 1
	move.l	#credscr+(448*288*2),d2		;end of source pic 1
	move.l	#titlescr,d3				;source pic 2
	cmp.b	#NTSC,pal_ntsc
	bne.b	.50
	add.l	#(448*32*2),d4				;skip 32 lines of club drive sign for NTSC
	sub.l	#(448*20*2),d1				;high score background and title screen background have different y positions for NTSC
.50:
	move.l	d4,t_scr+O_DATA			;destination
	bsr		do_cross
.90:
	rts

ld_scrns::
	bsr		ld_decmp					;load decompression GPU code
	bsr		load_q85
	lea		ttlmore,a0				;table with decompression info
	moveq	#1,d0					;the club drive screen
	bsr		dodecomp
	bsr		drawcprt					;draw the copyright text onto the club drive background
	bsr		load_q75
	lea		seldcm,a0					;table with decompression info
	moveq	#1,d0					;the island map screen
	bsr		dodecomp
	move.w	#1,loadsdn				;club drive sign and map background are loaded now
	rts

mv_tcar::
	cmp.b	#$1B,t_sign_l+O_HSCALE		;big enough to cover the car
	blt.b	.10
	or.b		#DELETE_OBJ,t_car+O_TYPE		;turn off car after club drive sign is big enough
 	rts
.10:
	cmp.w	#C_LOAD,titlestp
	bne.b	.40						;not time to load car yet
	jsr		_init_alloc
	move.l	#ttlcar,_inptr				;address of compressed data
	move.l	#tcardta,_outptr			;address for uncompressed data
	jsr		_inflate
	rts
.40:
	cmp.w	#C_GO,titlestp
	blt.b	.90						;not time to make car move yet
	move.w	t_car+O_YPOS,d0
	cmp.w	tcaryend,d0
	blt.b	.90						;stop moving if at end ypos
	subq.w	#2,t_car+O_YPOS			;move car up a little
	addq.w	#3,t_car+O_XPOS			;move car right a little
.90:
	rts

mv_tsign::
	cmp.w	#SIGN_ON,titlestp
	blt.b	.90						;exit if sign is not on yet
	moveq	#$7F,d0
	and.b	d0,t_sign_l+O_TYPE			;make sure sign is turned on
	and.b	d0,t_sign_r+O_TYPE			;make sure sign is turned on
	cmp.l	#$00202020,t_sign_l+O_SCALE	;normal scale size
	bne.b	.50
	or.b		#DELETE_OBJ,t_scr+O_TYPE		;turn off beach background when sign is at full size
	rts
.50:
	move.w	t_sign_l+O_YPOS,d1
	subq.w	#5,d1					;subtract some from ypos
	move.w	d1,t_sign_l+O_YPOS
	move.w	d1,t_sign_r+O_YPOS
	subq.w	#7,t_sign_l+O_XPOS
	move.l	#$00010101,d0
	add.l	d0,t_sign_l+O_SCALE
	add.l	d0,t_sign_r+O_SCALE
.90:	rts

gotitle::
	clr.w	titlestp					;reset animation step
	cmp.b	#1,keepmus				;if 1, don't restart music (when cycling from high score screen during demo)
	beq.b	.05
	move.l	#REGGAE_MUSIC,songnum
	bsr		playmus					;start music
.05:	clr.b	keepmus					;reset the flag for restarting music

	moveq	#DELETE_OBJ,d0
	or.b		d0,t_sign_l+O_TYPE			;turn off club drive sign
	or.b		d0,t_sign_r+O_TYPE			;turn off club drive sign
	moveq	#0,d0
	move.l	d0,t_sign_l+O_SCALE			;start club drive at minimum size
	move.l	d0,t_sign_r+O_SCALE
	move.w	#224,d0					;start at middle of screen
	move.w	d0,t_sign_l+O_XPOS
	move.w	d0,t_sign_r+O_XPOS
	move.w	#C_XSTART,t_car+O_XPOS
	lea		tinfntsc,a0
	cmp.b	#NTSC,pal_ntsc
	beq.b	.10
	lea		tinf_pal,a0
.10:
	move.w	(a0)+,tcaryend
	move.w	(a0)+,t_car+O_YPOS
	move.w	(a0)+,d0						;ypos of beach background
	move.w	d0,t_scr+O_YPOS
	move.w	d0,t_scr_m+O_YPOS
	move.w	(a0)+,d0						;height of beach and sign objects
	move.w	d0,t_scr+O_HEIGHT
	move.w	d0,t_scr_m+O_HEIGHT
	move.w	d0,t_sign_l+O_HEIGHT
	move.w	d0,t_sign_r+O_HEIGHT
	move.w	(a0)+,d0						;ypos of sign
	move.w	d0,t_sign_l+O_YPOS
	move.w	d0,t_sign_r+O_YPOS
	move.l	(a0)+,d0
	move.l	d0,t_scr+O_DATA
	move.l	(a0),d0
	move.l	d0,t_sign_l+O_DATA
	add.l	#448,d0
	move.l	d0,t_sign_r+O_DATA

	move.w	gamemode,oldgmode
	cmp.w	#TITLE_MODE,gamemode
	beq.b	.95						;don't need to reload graphics if already on title screen
	cmp.w	#HISCORE_MODE,oldgmode
	beq.b	.80
	bsr		clearscr
	move.w	#$4C7,VMODE
	bsr		ld_decmp				;load decompression GPU code
	bsr		load_q85
	lea		titlebkg,a0			;table with decompression info
	moveq	#1,d0				;number of objects to decompress
	bsr		dodecomp
.80:
	lea		fade,a0				;starting address of fade.bin
	cmp.w	#HISCORE_MODE,oldgmode
	bne.b	.90
	lea		cross,a0				;starting address of cross.bin
.90:	bsr		load_gpu
.95:
	moveq	#0,d0
	move.l	d0,bright
	move.l	d0,crosscnt

	moveq	#$7F,d0
	and.b	d0,t_scr+O_TYPE		;turn on background
	and.b	d0,t_car+O_TYPE		;turn on car
	move.w	#TITLE_MODE,gamemode

	rts	

drawcprt::
	move.l	#stonedta,A1_BASE					;destination address
	move.l	#copyrt,A2_BASE					;source address
	move.l	#PITCH1|PIXEL16|WID448|XADDPHR,A1_FLAGS
	move.l	#PITCH1|PIXEL16|WID192|XADDPHR,A2_FLAGS	;source
	moveq	#0,d0
	move.l	d0,B_PATD							;the color that will not be written if found in the source data
	move.l	d0,B_PATD+4						;the color that will not be written if found in the source data
	move.l	d0,A2_PIXEL						;start at 0,0 of source image
	move.l	#$00EB007C,A1_PIXEL					;Y,X position to write data
	move.l	#$000700C0,B_COUNT					;height = 7, width = 192
	move.l	#$0001FF40,d0
	move.l	d0,A1_STEP						;Y step, X step
	move.l	d0,A2_STEP						;Y step, X step
	move.l	#UPDA1|UPDA2|SRCEN|DSTEN|LFU_A|LFU_AN|DCOMPEN,B_CMD		;start blitter
	rts

tinf_pal::
	dc.w	P_CAR_YEND			;tcaryend
	dc.w	P_CAR_YSTART			;t_car+O_YPOS
	dc.w	P_SCRN_TOP			;ypos of beach background
	dc.w	287					;height of beach and sign objects
	dc.w	P_SCRN_TOP+160			;ypos of club drive sign
	dc.l	backgr0				;t_scr+O_DATA
	dc.l	stonedta				;t_sign_l+O_DATA
tinfntsc::
	dc.w	N_CAR_YEND			;tcaryend
	dc.w	N_CAR_YSTART			;t_car+O_YPOS
	dc.w	N_SCRN_TOP			;ypos of beach background
	dc.w	240					;height of beach and sign objects
	dc.w	N_SCRN_TOP+160			;ypos of club drive sign
	dc.l	backgr1+(32*448*2)		;t_scr+O_DATA
	dc.l	stonedta+(32*448*2)		;t_sign_l+O_DATA


titlinput::
	cmp.w	#1,loadsdn
	bne.b	.90					;wait until club drive sign and map background have been loaded
	move.l	joybothe,d0
	and.l	#ANY_FIRE,d0
	bne		goselect

	move.l	joybothe,d0
	btst.l	#KEY_6,d0
	beq.b	.90
	bsr		clearscr
	bsr		ld_decmp
	bsr		load_q85
	lea		credbkg,a0			;table with decompression info
	moveq	#1,d0				;number of objects to decompress
	bsr		dodecomp				;load just the background for now
	bra		gohiscor
.90:
	rts


titlolst::
;t_scr_m::
	dc.w		224			;xpos
	dc.w		0			;ypos
	dc.l		titlescr		;data
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
	dc.l		$00202020		;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------
;t_scr::
	dc.w		0			;xpos
	dc.w		0			;ypos
	dc.l		titlescr		;data
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
;t_car::
	dc.w		208			;xpos
	dc.w		0			;ypos
	dc.l		tcardta		;data
	dc.w		72			;height
	dc.w		64			;dwidth
	dc.w		64			;iwidth
	dc.b		TRANS_ON		;flags
	dc.b		0			;firstpix
	dc.b		0			;type
	dc.b		4			;depth
	dc.b		1			;pitch
	dc.b		0			;index
	dc.w		0			;desc
	dc.l		0			;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------
;t_sign_l::
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
;t_sign_r::
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
