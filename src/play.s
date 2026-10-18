	.include		'eq.s'
	.include		'externs.s'
	.include		'3dds.inc'

	.extern	blit_rect
	.extern	mkMatrix
	.extern	_alloc_it,_fatal
	.extern	_inflate,_inptr,_outptr
	.extern	td,replaytd,modemtd
	.extern fixupbin
	.extern	car1clr,car2clr
	.extern	_memzero
	.extern	memcpy
	.extern	joyeacc,joyehold,joyesem,joyeacc2,joyehol2,joyesem2,stufqueue
	.extern	speedvar
	.extern	setsteeropt

INCL_MODEM	EQU	0		; if INCL_MODEM != 0, include modem code
PACK_SIZE	EQU	15		; size of packets from modem code

playloop::
	stop	#$2000			; avoid eating bus bandwidth while waiting

.if INCL_MODEM
;***modem stuff
;
	tst.w	modem			; maybe we have a modem that needs checking?
	beq	chkgpu			; nope -- only have to worry about the GPU
;
; see if there's data for us
;
.moredata:
	jsr	_MDMstat		; check modem input status
	cmp.w	#PACK_SIZE,d0			; at least 15 bytes of data (i.e. 1 packet)?
	bmi	.sendit			; nope == keep going
	pea	curpacket		; otherwise, go get the packet
	jsr	_MDMrxp			; data has arrived: go get it
	move.l	(sp)+,a0		; pop the packet address
	tst.l	d0			; everything OK?
	bmi	.sendit			; if no error, continue
.ok:
	move.l	(a0),-(sp)		; push the packet contents
	jsr	_recpacket
	addq.l	#4,sp
	bra	.moredata
;
; send a packet of nice information out to the other side
;
.sendit:
	move.l	timestamp,d0
	cmp.l	packtime,d0		; still the same vertical blank?
	beq	chkgpu			; yes -- don't mess with the modem yet

	jsr	_sendpacket		; get the packet to send
	tst.l	d0
	beq	.updtime		; if sendpacket() returns 0, send no packet
	move.l	d0,-(sp)
	jsr	_MDMtxp			; transmit it over the modem
	addq.l	#4,sp

.updtime:
	move.l	timestamp,packtime	; update "packet time"
.endif	; INCL_MODEM

chkgpu:
	tst.w	framedone
	beq.b	playloop		; GPU isn't finished drawing yet
	tst.w	gameover		; is the game over?
	bne	doneplay		; if so, go to doneplay
;
; display a "REWIND" icon in the upper left hand corner, if we're rewinding
;
	move.l	player,a0
	move.l	CAR_CTRL(a0),d0
	btst.l	#OPTION,d0			; user rewind?
	bne.b	.doit				; yes: "rewind"
	tst.w	AUTO_REW(a0)			; auto rewind?
	beq.b	norewnd				; no: no rewind
.doit:
		move.l	#PITCH1|PIXEL16|WID320|XADDPHR,d0	; destination flags
;		move.l	d0,d1					; source flags
		move.l	#PITCH1|PIXEL16|WID64|XADDPHR,d1	; source flags
		move.l	#$00100040,d6				; source is 64x16
		move.l	#$00140014,d5				; destination starts at (20,20)
		move.l	last_screen,a0				; blit to the last screen shown
		move.l	#REWIND,a1				; source address
		jsr	blit_pic
norewnd:
	tst.w	twoplayer		; are we two players?
	beq	.noswitch
		move.l	player,d2	; if so, switch players
		eori.l	#(PLAYER1 ^ PLAYER2), d2
		move.l	d2,player
		tst.w	modem		; are we modeming
		beq	.noswitch	; nope == go for it
		cmp.l	#PLAYER1,d2	; are we player 1?
		beq	.noswitch	; nope == go for it
		jsr	modemtd		; do a td for the remote player
		bra	playloop
.noswitch:
	jsr	td
	bra	playloop

;----------------------------------------------------------
; goplay: start the PLAY_MODE game up
;
;----------------------------------------------------------

goplay::
	;is there a steering wheel?
	jsr setsteeropt

	bsr		dsp_off

	move.w	#0,framedone
	jsr		clearscr				;erase the island map

	;change world if SF race 2 player (too slow)
	cmp.w	#RACE2PLR,cur_act
	bne.b	.7
	cmp.w	#SF_LEVEL,curlevel
	bne.b	.7
		move.w	#SF2P_LEVEL,curlevel
	.7:
.if INCL_MODEM
;***modem stuff
	move.w	modem,d0
	beq	nomdm
	jsr	_initpackets		; initialize packet handler
	move.w	modem,d0
	cmp.w	#1,d0			; caller?
	bne	callee
	jsr	_MDMinit		; initialize modem
	tst.l	d0
	bmi	abort
	pea	phonenumber
	jsr	_MDMcall
	addq.l	#4,sp
	tst.l	d0
	bmi	abort
	move.w	#M_SPKROFF,-(sp)
	jsr	_MDMcmd
	addq.l	#2,sp
	bra	nomdm
callee:
	jsr	_MDMinit
	tst.l	d0
	bmi	abort
	jsr	_MDManswer
	tst.l	d0
	bmi	abort
	move.w	#M_SPKROFF,-(sp)
	jsr	_MDMcmd
	addq.l	#2,sp
	bra	nomdm
abort:
	move.l	#$f0000000, BG
;	illegal
	move.w	#0,modem
nomdm:
;***end of modem stuff
.endif ; INCL_MODEM

; initialize C memory manager
	jsr	_init_alloc

; copy over the load screen object
	lea	ldscrcv,a0
	lea	ldscrobj,a1
	moveq	#4*OBJ_SIZE,d1
	jsr	memcpy
;
; set up screen for while we're loading
;
	move.l	#0,timestamp
	move.w	cur_act,d0
	cmp.w	#RACE1PLR,d0
	beq.b	.10
	cmp.w	#RACE2PLR,d0
	bne.w	.noldscrn				;only do loading screens for race games
							;(other games have special stuff of their own)
	move.w	#$4C7,VMODE
.10:
	bsr		ld_decmp			;load decompression GPU code
	bsr		load_q85

	lea		loadscrs,a0
	move.w	curlevel,d0
	lsl.w	#2,d0
	move.l	(a0,d0.w),In_Adr		;address of compressed data
	lea	ld_start,a1
	add.w	d0,d0			; 2 longs (start x,y & finish x,y) per entry in ldscrxy
	lea	ldscrxy,a0
	move.w	0(a0,d0.w), O_XPOS(a1)
	move.w	2(a0,d0.w), O_YPOS(a1)
	lea	OBJ_SIZE(a1),a1		; move to ld_finish
	move.w	4(a0,d0.w), O_XPOS(a1)
	move.w	6(a0,d0.w), O_YPOS(a1)
	move.l	#ASCRN1,Out_Adr		;set destination address
	move.l	#40,Out_Width			;number of 8 pixel blocks in destination area
	move.l	#WID320,Out_E_Width		;setting for blitter
	move.l	#G_RAM,G_PC			;set program counter
	move.l	#$00000011,G_CTRL		;start GPU
.20:	cmp.l	#dj_done,All_Done		;wait until decompression is finished
	bne.b	.20

;
; update X and Y for the load screen objects based on whether or not we're NTSC
;
	moveq	#3,d2					; 4 objects total
	move.w	leftx,d0
	add.w	d0,d0					; double for this screen mode
	move.w	topy,d1
	asr.w	#1,d1					; halve for this screen mode
	lea	ldscrobj,a1
.plp:
	add.w	d0,O_XPOS(a1)
	add.w	d1,O_YPOS(a1)
	lea	OBJ_SIZE(a1),a1
	dbra	d2,.plp

	lea		ldscrobj,a1			;address of first object header
	move.l	#ASCRN1,O_DATA(a1)
	moveq	#1,d6					;total objects in list (1st list has just the map)
	lea		olist_l4,a2
	jsr		build				;build packed object list
	move.l	#olist_l4,listAddr

	move.l	#LDFrame,$100.w				;use our special interrupt handler

;
; decompress start and finish icons
;
	move.l	#o_STARTICON,_inptr
	move.l	#STARTICON,_outptr
	jsr	_inflate

;
; set up object lists for flashing "start" and "finish"
;
 	lea		ldscrobj,a1
	moveq	#2,d6
	lea		olist_l1,a2			; second object list (map + start icon)
	jsr	build

	lea		ldscrobj,a1
	moveq	#3,d6
	lea		olist_l2,a2			; third object list (map + start icon + finish icon)
	jsr	build

	lea		ldscrobj,a1
	moveq	#4,d6
	lea		olist_l3,a2			; last object list (map + start icon + finish icon + text)
	jsr	build

	move.l	#o_ldtext,_inptr			; decompress the "Press any key to continue" message
	move.l	#ldtext,_outptr
	jsr	_inflate

	bra	.keepinit

.noldscrn:
; copy the "yourit" stuff
	move.l	#4096,d1
	lea	o_yourit,a0
	lea	yourit,a1
	jsr	memcpy
	move.w	cur_act,d0
	cmp.w	#TAG2PLR,d0
	bne	.colscrn
;
; put the "PLAYER 2:" message onto the screen
	move.l	#192*16*2,d1
	lea	o_p2txt,a0
	lea	ASCRN1,a1
	jsr	memcpy
;
; adjust the object list to reflect the new size of everything
;
	lea	ldscrobj,a1
	move.w	#120,O_XPOS(a1)
	move.w	#100,O_YPOS(a1)
	move.w	#16,O_HEIGHT(a1)
	move.w	#48,O_DWIDTH(a1)
	move.w	#48,O_IWIDTH(a1)
	move.l	#ASCRN1,O_DATA(a1)
	lea	ld_start,a1
	move.w	#152,O_XPOS(a1)
	move.w	#200,O_YPOS(a1)
	move.w	#32,O_HEIGHT(a1)
	move.w	#16,O_DWIDTH(a1)
	move.w	#16,O_IWIDTH(a1)
	move.b	#1,O_TYPE(a1)			; make it a scaled object
	move.l	#$00404040,O_SCALE(a1)
	move.l	#yourit,O_DATA(a1)

;
; update X and Y for the tag screen objects based on whether or not we're NTSC
;
	moveq	#1,d2					; 2 objects total
	move.w	leftx,d0
	add.w	d0,d0					; double for this screen mode
	move.w	topy,d1
	asr.w	#1,d1					; halve for this screen mode
	lea	ldscrobj,a1
.plp2:
	add.w	d0,O_XPOS(a1)
	add.w	d1,O_YPOS(a1)
	lea	OBJ_SIZE(a1),a1
	dbra	d2,.plp2


	moveq	#1,d6
	lea	ldscrobj,a1
	lea	olist_l1,a2
	jsr	build
	move.l	#olist_l1,listAddr
	move.w	#$4c1,VMODE
	move.l	#TAGFrame,$100.w

	moveq	#2,d6
	lea	ldscrobj,a1
	lea	olist_l2,a2
	jsr	build

	bra	.keepinit

.colscrn:
;
; copy over the collect game text
;
	move.l	#o_coltxt,_inptr
	move.l	#ldtext,_outptr
	jsr	_inflate

;
; set up screen to display a rotating
; power ball
;
	move.w	#$4c1,VMODE
	lea	ldscrobj,a1
	add.w	#112,O_XPOS(a1)
	add.w	#8,O_YPOS(a1)
	move.w	#96,O_HEIGHT(a1)
	move.w	#24,O_DWIDTH(a1)
	move.w	#24,O_IWIDTH(a1)
	; V14 retail opcode recovery: original ALN sign-extended the byte
	; immediate to $FFFF. RMAC chooses $00FF, which is equivalent
	; at runtime but not byte-identical. Preserve the historic
	; 3-word MOVE.B #$FF,O_TYPE(a1) encoding in assembler source.
	; Original 1994 line: move.b	#-1,O_TYPE(a1)			; don't show the power ball
	dc.w	$137C,$FFFF,O_TYPE	; don't show the power ball
	lea	OBJ_SIZE(a1),a2			; move to next item
	; V14 retail opcode recovery: original ALN sign-extended the byte
	; immediate to $FFFF. RMAC chooses $00FF, which is equivalent
	; at runtime but not byte-identical. Preserve the historic
	; 3-word MOVE.B #$FF,O_TYPE(a2) encoding in assembler source.
	; Original 1994 line: move.b	#-1,O_TYPE(a2)			; mark "start" icon as deleted
	dc.w	$157C,$FFFF,O_TYPE	; mark "start" icon as deleted
	lea	OBJ_SIZE(a2),a2
	; V14 retail opcode recovery: original ALN sign-extended the byte
	; immediate to $FFFF. RMAC chooses $00FF, which is equivalent
	; at runtime but not byte-identical. Preserve the historic
	; 3-word MOVE.B #$FF,O_TYPE(a2) encoding in assembler source.
	; Original 1994 line: move.b	#-1,O_TYPE(a2)			; mark "finish" icon as deleted
	dc.w	$157C,$FFFF,O_TYPE	; mark "finish" icon as deleted

;
; update X and Y for the load screen objects based on whether or not we're NTSC
;
	moveq	#3,d2					; 4 objects total
	move.w	leftx,d0
	add.w	d0,d0					; double for this screen mode
	move.w	topy,d1
	asr.w	#1,d1					; halve for this screen mode
	lea	ldscrobj,a1
.plp3:
	add.w	d0,O_XPOS(a1)
	add.w	d1,O_YPOS(a1)
	lea	OBJ_SIZE(a1),a1
	dbra	d2,.plp3

	moveq	#4,d6				; 4 objects in list
	lea	ldscrobj,a1
	lea	olist_ram,a2
	jsr	build
	move.l	#COLFrame,$100.w
	move.l	#olist_ram, listAddr

	lea	ldscrobj,a1
	move.b	#0,O_TYPE(a1)			; restore bitmapped object type
	move.l	#PWRBALL+40,d0
	move.l	d0,O_DATA(a1)
	lea	olist_l1,a2
	moveq	#4,d6
	jsr	build

	lea	ldscrobj,a1
	move.l	O_DATA(a1),d0
	add.l	#18432,d0
	move.l	d0,O_DATA(a1)
	lea	olist_l2,a2
	moveq	#4,d6
	jsr	build

	lea	ldscrobj,a1
	move.l	O_DATA(a1),d0
	add.l	#18432,d0
	move.l	d0,O_DATA(a1)
	lea	olist_l3,a2
	moveq	#4,d6
	jsr	build

	lea	ldscrobj,a1
	move.l	O_DATA(a1),d0
	add.l	#18432,d0
	move.l	d0,O_DATA(a1)
	lea	olist_l4,a2
	moveq	#4,d6
	jsr	build

	lea	ldscrobj,a1
	move.l	O_DATA(a1),d0
	add.l	#18432,d0
	move.l	d0,O_DATA(a1)
	lea	olist_l5,a2
	moveq	#4,d6
	jsr	build

	lea	ldscrobj,a1
	move.l	O_DATA(a1),d0
	add.l	#18432,d0
	move.l	d0,O_DATA(a1)
	lea	olist_l6,a2
	moveq	#4,d6
	jsr	build

	lea	ldscrobj,a1
	move.l	O_DATA(a1),d0
	add.l	#18432,d0
	move.l	d0,O_DATA(a1)
	lea	olist_l7,a2
	moveq	#4,d6
	jsr	build

	lea	ldscrobj,a1
	move.l	O_DATA(a1),d0
	add.l	#18432,d0
	move.l	d0,O_DATA(a1)
	lea	olist_l8,a2
	moveq	#4,d6
	jsr	build

;
; set up the powerball animation
;
	move.l	#o_PWRBALL,_inptr
	move.l	#PWRBALL,_outptr
	jsr	_inflate


.keepinit:
; get game variables based on user selections
	move.w	#60,scoreMax
	clr.b	debugflg
	bsr	initgame

; fix up external symbols in GPU programs
	jsr	do_gpufixups

;-------------------------------------------------
; initialize play variables

	; V15 RECOVERY (2026): retail uses TABLES.S showcoord, not a second BSS flag.
	move.b	#0,showcoord

;-------------------------------
; copy car models, set up CLUT
	move.w	cur_car0,d1
	add	d1,d1
	lea	cars_clr,a1
	move.w	(a1,d1.w),car1clr	; player 1 color
	add	d1,d1
	lea	cars_head,a0
	move.l	(a0,d1.w),a0
	lea	car1_ram,a1
	bsr	carfix

	move.w	cur_car1,d1
	add	d1,d1
	lea	cars_clr,a1
	move.w	(a1,d1.w),car2clr	;	CLUT+255+255	; player 2 color
	add	d1,d1
	lea	cars_head,a0
	move.l	(a0,d1.w),a0
	lea	car2_ram,a1
	bsr	carfix

;-------------------------------
; copy the "you win" icon
	move.l	#4096,d1
	lea	o_youwin,a0
	lea	youwin,a1
	jsr	memcpy

; copy the car data
	move.l	#(CAR_NUM_PNTS*6+3),d1
	lea	o_car_dat,a0
	lea	car_dat,a1
	jsr	memcpy

; copy over the dashboard
	move.l	#(320*30),d1
	lea	origdash,a0
	lea	dash,a1
	jsr	memcpy

; copy the fonts
	move.l	#180,d1
	lea	o_digitfont,a0
	lea	digitfont,a1
	jsr	memcpy
	move.l	#128,d1
	lea	o_cmpssfont,a0
	lea	cmpssfont,a1
	jsr	memcpy
	move.l	#576,d1
	lea	o_spdfont,a0
	lea	speedfont,a1
	jsr	memcpy
	moveq	#96,d1
	lea	o_tnyfont,a0
	lea	tnyfont,a1
	jsr	memcpy

;
; uncompress the "PAUSE" bitmap
	move.l	#o_PAUSECRY,_inptr
	move.l	#PAUSECRY,_outptr
	jsr	_inflate

;
; put a border around "PAUSE"
;
	move.l	#$78007800,B_PATD
	move.l	#$78007800,B_PATD+4
	move.l	#PAUSECRY,A1_BASE
	move.l	#PITCH1|PIXEL16|XADDPHR|WID160,A1_FLAGS
	move.l	#0,A1_PIXEL
	move.l	#$000100a0,B_COUNT
	move.l	#PATDSEL,B_CMD					; draw top
	move.l	#PITCH1|PIXEL16|XADDPHR|WID160,A1_FLAGS
	move.l	#$00670000,A1_PIXEL
	move.l	#$000100a0,B_COUNT
	move.l	#PATDSEL,B_CMD					; draw bottom
	move.l	#PITCH1|PIXEL16|XADD0|YADD1|WID160,A1_FLAGS
	move.l	#$00000000,A1_PIXEL
	move.l	#$00010068,B_COUNT
	move.l	#PATDSEL,B_CMD					; draw left
	move.l	#PITCH1|PIXEL16|XADD0|YADD1|WID160,A1_FLAGS
	move.l	#$0000009f,A1_PIXEL
	move.l	#$00010068,B_COUNT
	move.l	#PATDSEL,B_CMD					; draw right

	tst.w	splitscreen
	bne.b	nohood
	move.l	#320*60*2,-(sp)
	.extern	_alloc
	jsr	_alloc
	addq.l	#4,sp
	move.l	d0,hoodptr
	move.l	d0,_outptr
	move.l	#o_HOOD,_inptr
	jsr	_inflate
;
; fix up the hood color
;
	move.l	#360*60-1,d0
	move.w	car1clr,d2
	and.w	#$ff00,d2
	move.l	hoodptr,a0
.lp1:
	move.w	(a0),d1
	beq	.15
	or.w	d2,d1
.15:
	move.w	d1,(a0)+
	dbra	d0,.lp1
nohood:

;-------------------------------
; initialize the timers
	move.l	#256,-(sp)
	pea	TIMEARRAY
	jsr	_memzero
	addq.l	#8,sp

;-------------------------------
; initialize bss variables
	move.l	#0,mbands

	move.l	#PLAYER1,d0
	move.l	d0,player
	move.l	d0,itCar
	move.l	d0,lastItCar
	move.l	d0,chkPlayer
	move.l	d0,joyeacc
	move.l	d0,joyehold
	move.l	d0,joyehol2
	move.l	d0,joyeacc2
	move.b	d0,joyesem
	;set speedvar according to speedopt and world
	move.w	speedopt,d6
	add.w	#1,d6
	asl.w	#2,d6
	cmpi.w	#FUTURE_LEVEL,curlevel		;HOTWHEELS TRACK
	bne.b	.20
	cmpi.w	#TAG2PLR,cur_act			; check activity
	bpl.b	.20						;RACE1PLR,RACE2PLR are MI
		cmpi.w	#4,d6
		bne.b	.20
			move.w	#6,d6
	.20:
	move		d6,speedvar
	
	move.l	#HUD1,itHUD
	clr.w	waitTime
	clr.w	alpha
	clr.w	beta
	clr.w	gamma
	move.l	#ASCRN1,screen_addr
	move.l	#ASCRN1,last_screen

	; clear the watch window (data area)
	move.l	#DS_BASE, a0
	move.l	#$200140,d6			;320 x 32
	moveq	#0,d5				;top left corner is 0,200
	move.l	#$49804980, d7				;not black
	move.l	#PITCH1|PIXEL16|WID320|XADDPHR,d0
	jsr		blit_rect

	move.l	#8,G_CTRL	; Stop the GPU (not that it is going or anything, I mean, I'm not saying that)


; make a fresh copy of the object list

	move.l	#playolst,a0
	move.l	#playobjs,a1
	move.l	#(PLAY_OBJS*OBJ_SIZE),d1
	jsr	memcpy

	move.l	hoodptr,p1_hood+O_DATA
;
; set up drawing parameters based on whether or not we're
; running with split screens
;
	tst.w	splitscreen
	beq	bigscreen
;
; split screen
;
	move.l	#18927,SIDES
	move.l	#5619,SIDES+4
	move.l	#$7fff,ASPECTR

	move.w	#95,d1
	move.w	d1,p1_scr+O_HEIGHT

	move.w	p1_scr+O_YPOS,d0
	add.w	d1,d1
	add.w	d1,d0
	move.w	d0,bar_scr+O_YPOS
	add.w	#3,d0
	move.w	d0,map_scr+O_YPOS
	sub.w	#73,d0
	move.w	d0,p1_hud+O_YPOS

	move.l	#$005f0140,DRAWRECT		; screen size: 320x95
	move.l	#$A08000,XCENTER
	move.l	#$300000,YCENTER
; window corners
	move.l	#CORNERS,a3
	move.l	#$01408000, (a3)+	; RT
	move.l	#$00008000, (a3)+
	move.l	#$00008000, (a3)+	; TL
	move.l	#$00008000, (a3)+
	move.l	#$00008000, (a3)+	; BL
	move.l	#$005f8000, (a3)+
	move.l	#$01408000, (a3)+	; RB
	move.l	#$005f8000, (a3)

	lea	p1_hood,a0			; no hood is to be displayed
	move.b	#DELETE_OBJ,O_TYPE(a0)
	lea	p2_scr,a0			; player 2 screen and hud must be shown
	move.b	#0,O_TYPE(a0)
	lea	p2_hud,a0
	move.b	#0, O_TYPE(a0)
	bra	donescrn
;
; parameters for 1 player, big screen mode
;
bigscreen:
	move.l	#18927,SIDES
	move.l	#11770,SIDES+4
	move.l	#$7fff,ASPECTR

	move.w	#185,d1
	move.w	d1,p1_scr+O_HEIGHT

	move.w	p1_scr+O_YPOS,d0

	move.w	#185,d1
	add.w	d1,d1
	add.w	d1,d0
	move.w	d0,bar_scr+O_YPOS
	add.w	#3,d0
	move.w	d0,map_scr+O_YPOS
	sub.w	#73,d0
	move.w	d0,p1_hud+O_YPOS
	sub.w	#14,d0
	move.w	d0,p1_hood+O_YPOS
	move.w	#42,p1_hood+O_HEIGHT
	move.l	#$00c80140,DRAWRECT		; screen size: 320x200
	move.l	#$A08000,XCENTER
	move.l	#$640000,YCENTER
; window corners
	move.l	#CORNERS,a3
	move.l	#$01408000, (a3)+	; RT
	move.l	#$00008000, (a3)+
	move.l	#$00008000, (a3)+	; TL
	move.l	#$00008000, (a3)+
	move.l	#$00008000, (a3)+	; BL
	move.l	#$00c88000, (a3)+
	move.l	#$01408000, (a3)+	; RB
	move.l	#$00c88000, (a3)

	lea	p1_hood,a0			; show hood (maybe)
	move.b	#0,O_TYPE(a0)
	lea	p2_scr,a0
	move.b	#DELETE_OBJ,O_TYPE(a0)	; don't show second player's stuff
	lea	p2_hud,a0
	move.b	#DELETE_OBJ,O_TYPE(a0)

donescrn:


; clear screen2
	move.l	#$00C80140,d6			;320 x 200 ;dc
	moveq	#0,d5				;top left corner is 0,0
	move.l	#$52325232, d7			;not black
	move.l	#PITCH1|PIXEL16|WID320|XADDPHR,d0
	move.l	#ASCRN2,a0
	jsr		blit_rect

; clear the HUDS
	move.l	#$003f0040,d6			; 64x64
	moveq	#0,d5
	moveq	#0,d7				; black
	move.l	#PITCH1|PIXEL16|WID64|XADDPHR,d0
	move.l	#HUD1,a0
	jsr	blit_rect

	; set up car stuf
	moveq.l	#0,d0
	movea.l	#(PLAYER1 + CAR_MODEL), a0
	move.l	#car1_ram, (a0)
	movea.l	#(PLAYER1 + CAR_VELOCITY), a0
	move.l	d0, (a0)+
	move.l	d0, (a0)+
	move.l	d0, (a0)
	movea.l	#(PLAYER1 + CAR_OMEGA), a0
	move.l	d0, (a0)+
	move.l	d0, (a0)+
	move.l	d0, (a0)
	movea.l	#(PLAYER1 + SCORE), a0
	move.l	d0, (a0)+		; score
	move.l	d0, (a0)+		; prev score
	move.l	#dash+1189, (a0)	; address of window -1
	move.l	d0,PLAYER1+CUR_PORTAL
	lea	PLAYER1+CUR_SOUND,a0
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,PLAYER1+GAME_DATA
	move.l	d0,PLAYER1+CAR_TIMER
	move.l	d0,PLAYER1+WAIT_TIME
	move.l	#$00030052,PLAYER1+TIMERPIX		; (90-8,3): coordinates for last digit of timer in dash board
	move.l	d0,PLAYER1+MAP_POS
	move.w	#$81,PLAYER1+CAMERA_FLAG
	move.l	d0,PLAYER1+PORTAL_ROT
	lea	PLAYER1+CAR_TIRE_SPD,a0
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)
	move.l	d0,PLAYER1+CAR_GEAR
	move.l	d0,PLAYER1+CAR_SKD_VCE
	move.l	d0,PLAYER1+AUTO_REW
	move.l	d0,PLAYER1+CAR_QUEUE

	movea.l	#(PLAYER2 + CAR_MODEL), a0
	move.l	#car2_ram, (a0)
	movea.l	#(PLAYER2 + CAR_VELOCITY), a0
	move.l	d0, (a0)+
	move.l	d0, (a0)+
	move.l	d0, (a0)
	movea.l	#(PLAYER2 + CAR_OMEGA), a0
	move.l	d0, (a0)+
	move.l	d0, (a0)+
	move.l	d0, (a0)
	movea.l	#(PLAYER2 + SCORE), a0
	move.l	d0, (a0)+
	move.l	d0, (a0)+
	move.l	#dash+5669, (a0)	; address of window -1
	move.l	d0,PLAYER2+CUR_PORTAL
	lea	PLAYER2+CUR_SOUND,a0
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,PLAYER2+GAME_DATA
	move.l	d0,PLAYER2+CAR_TIMER
	move.l	d0,PLAYER2+WAIT_TIME
	move.l	#$00110052,PLAYER2+TIMERPIX	;(90-8,17)
	move.l	d0,PLAYER2+MAP_POS
	move.w	#$81,PLAYER2+CAMERA_FLAG
	move.l	d0,PLAYER2+PORTAL_ROT
	lea	PLAYER2+CAR_TIRE_SPD,a0
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)
	move.l	d0,PLAYER2+CAR_GEAR
	move.l	d0,PLAYER2+CAR_SKD_VCE
	move.l	d0,PLAYER2+AUTO_REW
	move.l	d0,PLAYER2+CAR_QUEUE

	; initial positions
	; if we're running over a modem, the initial positions are reversed for the "callee"
	lea	startWorld,a2
	lea	PLAYER1,a0
	cmp.w	#2,modem
	bne	.play1
	lea	PLAYER2,a0
	move.l	a0, itCar
.play1:
	move.l	#0,FLOOR_MODEL(a0)	; currently no floor
	move.l	#0,CAMERA_MODEL(a0)	; or camera
	move.l	(a2)+,a3			; get band
	move.l	a3,NEW_FLOOR(a0)
	move.l	a3,NEW_CAMERA(a0)
	lea	CAMERA_POSN(a0),a1
	lea	XORIG(a3),a3
	move.l	(a3)+,(a1)+
	move.l	(a3)+,(a1)+
	move.l	(a3)+,(a1)+
	lea	CAR_POSN(a0), a1
	move.l	(a2)+,(a1)+
	move.l	(a2)+,(a1)+
	move.l	(a2)+,(a1)+
	clr.l	d0
	move.w	(a2)+,d0
	move.w	d0,beta
	move.l	d0,CAR_HEAD(a0)
	jsr		mkMatrix

	lea	startWorld,a2
	lea	STARTP2(a2),a2		; player 2's starting position

	lea	PLAYER2,a0
	cmp.w	#2,modem
	bne	.play2
	lea	PLAYER1,a0
.play2:
	move.l	#0,FLOOR_MODEL(a0)	; currently no floor
	move.l	#0,CAMERA_MODEL(a0)	; or camera
	move.l	(a2)+,a3		; get band
	move.l	a3,NEW_CAMERA(a0)
	move.l	a3,NEW_FLOOR(a0)
	lea	CAMERA_POSN(a0),a1
	lea	XORIG(a3),a3
	move.l	(a3)+,(a1)+
	move.l	(a3)+,(a1)+
	move.l	(a3)+,(a1)+

	lea	CAR_POSN(a0),a1
	move.l	(a2)+,(a1)+
	move.l	(a2)+,(a1)+
	move.l	(a2)+,(a1)+
	clr.l	d0
	move.w	(a2)+,d0
	move.w	d0,beta
	move.l	d0,CAR_HEAD(a0)
	jsr		mkMatrix

; Initialize map stuff
;
	lea	startWorld,a2
	lea	MSCALE(a2),a2
	move.l	(a2)+,mapscale
	move.l	(a2)+,maporig

; initialize
; animation function (if any)
	move.l	startWorld+STARTANIM,a0
	move.l	-4(a0),d0
	cmp.l	#'IGPU',d0			; look for magic that tells us we have an animation function
	beq	.33
		cmp.l	#'OGPU',d0		; different magic: this says animate only in 1 player mode
		bne	.32
		tst.w	twoplayer
		beq	.33			; one player mode: go ahead and animate
	.32:
		sub.l	a0,a0			; don't do any animation
.33:
	move.l	a0,animprog
	move.l	a0,animparam
	move.l	#dummyinit,animinit
	cmp.l	#0,a0
	beq	.39
; We have an animation program, and it needs fixing up
; run the GPU fixup program on it
		lea.l	8(a0),a5		; get the list of mobile bands
		move.l	4(a0),animparam		; parameter for animation program
		move.l	(a0),a0
		move.l	a0,a1
		move.l	a0,animprog
		jsr	fixupbin

.lp3:
		.extern	_use_bnd
		move.l	(a5)+,a0		; get the next mobile band
		cmp.l	#0,a0
		beq	.38

		move.l	(a0),d0			; get the band flags
		bset.l	#16,d0			; set the "I'm a mobile band" flag
		move.l	d0,(a0)			; and save it
		move.l	#0,-(sp)
		move.l	a0,-(sp)
		jsr	_use_bnd
		addq.l	#8,sp
		bra.b	.lp3
.38:
		move.l	(a5)+,a0		; load up the initialization function
		move.l	a0,animinit
		jsr	(a0)			; initialize animation
.39:

; Copy over the GPU program
	move.l	#$00070007, G_END
	move.l	#G_RAM,a1
	move.l	#gpram,a0
	move.l	(a0)+,d0		; skip over bogus (wrong P.O.V.) starting address
	move.l	(a0)+,d0
	add.l	#3, d0	; round up to nearest word length
	lsr.l	#2, d0
.40:	move.l	(a0)+,(a1)+
	dbra	d0,.40

	move.l	#PLAYER1+CAR_MATRIX,car1_ram+BND_MATRIX
	move.l	#car1_ram,-(sp)
	jsr	_alloc_it
	move.l	#PLAYER2+CAR_MATRIX,car2_ram+BND_MATRIX
	move.l	#car2_ram,(sp)
	jsr	_alloc_it
	addq.l	#4,sp

; set the "nocollide,not a floor,is other car" flags for the cars
	move.l	#$30001,car1_ram
	move.l	#$30001,car2_ram

	clr.w	changeIT
	tst.w	gametype
	bne	.45
		move.w	#1,changeIT
.45:
	move.w	#0,gameover

	moveq	#0,d0
	move.l	d0,PLAYER1+CAR_TOTFRAME
	move.l	d0,PLAYER2+CAR_TOTFRAME
;
; set up record/playback queue
;
	lea	QUEUES,a0
	move.l	a0,PLAYER1+QSTART
	move.l	a0,PLAYER1+QHEAD
	move.l	a0,PLAYER1+QTAIL
	move.l	a0,PLAYER1+QPLAY
	move.l	#QENTRYSIZ*QNUMENTRY,d0
	tst.w	twoplayer
	bne	.46
		add.l	d0,d0		; in one player mode we can go twice as long
.46:
	lea	(a0,d0.l),a0
	move.l	a0,PLAYER1+QEND
	move.l	a0,PLAYER2+QSTART
	move.l	a0,PLAYER2+QHEAD
	move.l	a0,PLAYER2+QTAIL
	move.l	a0,PLAYER2+QPLAY
	lea	(a0,d0.l),a0
	move.l	a0,PLAYER2+QEND
	move.w	#QUANTUM,PLAYER1+QTIME
	move.w	#QUANTUM,PLAYER2+QTIME

;	jsr		clearscr
	lea		bar_palette,a0					;palette for dashboard
	jsr		set_palette
; special palette stuff:
; color 251 is always black
; color 252 is always green (a neutral color)
; color 253 is used for dots in crash and score
; color 254 is player 1, 255 is player 2
	move.w	#$7fc0,CLUT+252+252
	move.w	#$48b0,CLUT+253+253
	move.w	car1clr,CLUT+254+254
	move.w	car2clr,CLUT+255+255

	lea	pause_scr,a0
	move.b	#0,O_TYPE(a0)			; make sure pause displays normally
	move.b	#0,O_FLAGS(a0)

;
; update X and Y for the game screen objects based on whether or not we're NTSC
;
	moveq	#PLAY_OBJS-1,d2
	move.w	leftx,d0
	move.w	topy,d1
	lea	playobjs,a1
.plp:
	add.w	d0,O_XPOS(a1)
	add.w	d1,O_YPOS(a1)
	lea	OBJ_SIZE(a1),a1
	dbra	d2,.plp


;
; build object lists
;
	move.l	#ASCRN1,p1_scr+O_DATA
	move.l	#BSCRN1,p2_scr+O_DATA
	moveq	#PLAY_OBJS-1,d6
	lea	playobjs,a1
	lea	olist_ram,a2
	jsr	build

	move.l	#ASCRN2,p1_scr+O_DATA
	move.l	#BSCRN2,p2_scr+O_DATA
	moveq	#PLAY_OBJS-1,d6
	lea	playobjs,a1
	lea	olist_sec,a2
	jsr	build

	.extern	pinput
;
; if we're displaying flashing "start" and "finish" icons,
; make sure that animation is finished
;
	move.l	$100.w,d0			; get interrupt routine
	cmp.l	#LDFrame,d0
	bne	.noanim
.await:
		move.l	timestamp,d0
		cmp.l	#1500,d0		; 6 seconds elapsed yet?
		bmi.b	.await
		jsr	pinput			; read controller
		move.l	joybothe,d0
		and.l	#ANY_FIRE,d0		; wait for a fire button
		beq.b	.await
		move.l	#Frame,$100.w		; use standard interrupt routine
		jsr	wait_int			; wait for an interrupt
		bra	.startit
;
; this is the place for the Tag game and Collect game
;
.noanim:
		jsr	pinput			; read controller (for reset)
		move.l	joybothe,d0
		and.l	#ANY_FIRE,d0		; if a fire button is pushed, break
		bne	.doit
		move.l	timestamp,d0		; otherwise keep waiting until
		cmp.l	#1500,d0		; five seconds have elapsed
		bmi.b	.noanim
.doit:
	move.l	#Frame,$100.w
	move.l	#0,coverdta
	move.l	#0,coverdta+4

.startit:
; clear screen1
	move.l	#$00C80140,d6			;320 x 200 ;dc
	moveq	#0,d5				;top left corner is 0,0
	move.l	#$00010001, d7			;not black
	move.l	#PITCH1|PIXEL16|WID320|XADDPHR,d0
	move.l	#ASCRN1,a0
	jsr		blit_rect

	move.l	#olist_sec,listAddr
	move.w	#PLAY_MODE,gamemode
	move.l	#ASCRN1,screen_addr
	move.w	#0,buffNum
	move.w	#0,buffShn

	move.w	#$6C1,VMODE

.if INCL_MODEM
;***modem testing stuff
	.extern	WAITPLAY
	move.w	modem,d0
	beq	goferit			; no modem
		move.l	#PITCH1|PIXEL16|WID320|XADDPHR,d0	; destination flags
		move.l	#PITCH1|PIXEL16|WID64|XADDPHR,d1	; source flags
		move.l	#$00400040,d6				; source is 64x64
		move.l	#$00400080,d5				; destination starts at (128,64)
		move.l	#ASCRN2,a0				; blit to the current screen
		move.l	#WAITPLAY,a1				; source address
		jsr	blit_pic
;;	move.l	#(1<<OPTION),CAR_CTRL+PLAYER2	; mark player 2's car as being remote controlled
	move.w	modem,d0
	cmp.w	#2,d0
	beq	slave
master:
	move.l	#$5e6adead,-(sp)	; caller sends "Sega Dead"
	jsr	_MDMtxp
	addq.l	#4,sp
.wait:
	jsr	_MDMstat		; is there data for us?
	cmp.w	#PACK_SIZE,d0
	bmi	.wait			; nope, sorry

	pea	curpacket		; data has finally arrived...
	jsr	_MDMrxp			; it should say "Dead Beef"
	addq.l	#4,sp
	tst.l	d0
	bmi	badconnect
	move.l	curpacket,d0
	cmp.l	#$deadbeef,d0
	bne	badconnect
	bra	goferit
slave:
.wait:
	jsr	_MDMstat		; is there data for us?
	cmp.w	#PACK_SIZE,d0
	bmi	.wait			; nope, sorry

	pea	curpacket		; callee expects "Sega Dead"
	jsr	_MDMrxp
	addq.l	#4,sp
	tst.l	d0
	bmi	badconnect
	move.l	curpacket,d0
	cmp.l	#$5e6adead,d0
	bne	badconnect
	move.l	#$deadbeef,-(sp)	; send "Dead Beef"
	jsr	_MDMtxp
	addq.l	#4,sp
	bra	goferit
badconnect:
	move.l	#$f0000000, BG
;	illegal
.endif ; INCL_MODEM
goferit:
;***end
; start the engine sounds
	moveq	#0,d3
	move.w	#PLAYER1_ENG_SOUND,d0		; engine sound
	move.l	#$3fff,d1	; xposn
	move.w	#P1ENGV,d2		; voice
	jsr	eng_on

	tst.w	twoplayer
	beq	noeng2
	moveq	#0,d3
	move.w	#PLAYER2_ENG_SOUND,d0	; engine sound
	move.l	#$3fff,d1	; xposn
	move.w	#P2ENGV,d2	; voice
	jsr	eng_on
noeng2:

	moveq.l	#0,d0
	move.w	d0,framecnt
	move.w	d0,fps
	move.l	d0,timestamp
	move.l	d0,packtime		; note time we sent last packet
	move.w	#QUANTUM,playspd	; initialize playback speed for animators
	move.b	#1,stufqueue		; get input queue going
	jsr		td

dummyinit:			; default animation initializer function (does nothing, obviously)
	rts

doneplay::
	clr.b	stufqueue				;no more driving input
	cmp.w	#SF2P_LEVEL,curlevel
	bne.b	.15
		move.w	#SF_LEVEL,curlevel
	.15:

;
; clear HUDs
;
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
;
; in a two player game, tell the winner he won!
;
	tst.w	splitscreen
	beq	nowinner
		move.l	#$001f0040,d6			; 64x32
		moveq.l	#$0,d5				; top left corner
		move.l	#youwin,a1
		move.l	#PITCH1|PIXEL16|WID64|XADDPHR,d0	; destination flags
		move.l	#PITCH1|PIXEL16|WID64|XADDPHR,d1	; source flags
		move.l	#HUD1,a0
		cmp.l	#PLAYER1,winner
		beq	.10
			move.l	#HUD2,a0
.10:
		jsr	blit_pic
nowinner:
;
; copy the "game over" screen over top of the "pause" icon
;
.if 1
	move.l	#gameovr,_inptr
	move.l	#PAUSECRY,_outptr
	jsr	_inflate
.else
	lea	gameovr,a0
	lea	PAUSECRY,a1
	move.l	#160*104*2,d1
	jsr	memcpy
.endif
;
; wait for a VBI
;
	jsr	wait_int
;
; set up the pause object as a scaled bitmap object; we'll
; zoom that object up
;
	moveq	#PLAY_OBJS,d6
	move.l	#ASCRN1,d0				; make sure olist_pau will match what's in either olist_ram
	move.l	#BSCRN1,d1				; or olist_sec (whichever is currently being displayed)
	move.l	listAddr,d2
	cmp.l	#olist_ram,d2
	beq	.10
		move.l	#ASCRN2,d0
		move.l	#BSCRN2,d1
.10:
	move.l	d0,p1_scr+O_DATA
	move.l	d1,p2_scr+O_DATA
	lea	pause_scr,a0

	move.b	#RMW_ON,O_FLAGS(a0)
	move.b	#1,O_TYPE(a0)				; set to "scaled bitmap object type"
	move.l	#0,O_SCALE(a0)				; start at 0 size
	move.w	O_XPOS(a0),d0
	add.w	#96,d0					; width is 160; half of this is 80; 96 = 32 * 3 is close
	move.w	d0,O_XPOS(a0)
	move.w	O_YPOS(a0),d0				; height is 104; half of this is 52; 64 = 32*2 is close
	add.w	#64,d0					;
	move.w	d0,O_YPOS(a0)				;

	lea	playobjs,a1
	lea	olist_pau,a2
	jsr	build
	move.l	#olist_pau,listAddr

	move.w	#0,framedone
;
; zoom up the "Game Over" sign, while waiting for input
;
zoomit:
	jsr	wait_int
	jsr	input			; read controller for reset key
;	move.l	joybothe,d0
;	and.l	#ANY_FIRE,d0
;	bne	donedone
	moveq	#PLAY_OBJS,d6
	lea	pause_scr,a0

	move.w	framedone,d1
	addq.w	#1,d1
	move.w	d1,framedone
	cmp.w	#2,d1
	bne.b	regframe

	move.w	#0,framedone
	move.l	O_SCALE(a0),d0
	cmp.l	#$00202020,d0
	beq.b	donezoom
	add.l	#$00010101,d0
	move.l	d0,O_SCALE(a0)
	sub.w	#2,O_YPOS(a0)
	sub.w	#3,O_XPOS(a0)
regframe:

	lea	playobjs,a1
	lea	olist_pau,a2
	jsr	build
	bra.b	zoomit

donezoom:

	jsr		addhiscr				;see if previous score should be added to the best scores
	cmp.w	#0,showrank
	beq.b	.40
	lea		prevscr0,a0
	cmp.l	#-1,(a0)				;-1 means don't use this score
	beq.b	.30
	bsr		drawrank				;show score for player 1 from previous game
	bra.b	.40
.30:	lea		prevscr1,a0
	cmp.l	#-1,(a0)				;-1 means don't use this score
	beq.b	.40
	bsr		drawrank				;show score for player 2 from previous game
.40:
;
; wait for 3 seconds before starting playback
;
	move.l	#0,timestamp
	move.l	#0,packtime

; Copy over the GPU program
	move.l	#$00070007, G_END
	move.l	#G_RAM,a1
	move.l	#gpram,a0
	move.l	(a0)+,d0		; skip over bogus (wrong P.O.V.) starting address
	move.l	(a0)+,d0
	add.l	#3, d0	; round up to nearest word length
	lsr.l	#2, d0
.41:	move.l	(a0)+,(a1)+
	dbra	d0,.41

rwait:
	jsr	wait_int
	jsr	input			; read controller for reset key
	move.l	joybothe,d0
	and.l	#ANY_FIRE,d0
	bne	donedone
	move.l	timestamp,d0
	cmp.l	#900,d0
	bne.b	rwait

morelists:
;
; copy the hi scores onto the "game over" icon
; (if hi scores are available, "showrank" will
; be set)
	tst.w	showrank
	beq.b	.norank
	jsr	eoghiscores
.norank:

;
; set up new object lists with the "game over" icon
;
	moveq	#PLAY_OBJS,d6
	move.l	#ASCRN1,p1_scr+O_DATA
	move.l	#BSCRN1,p2_scr+O_DATA
	lea	pause_scr,a0
	move.b	#RMW_ON,O_FLAGS(a0)
	move.b	#0,O_TYPE(a0)				; set to non-scaled bitmap type

	lea	playobjs,a1
	lea	olist_ram,a2
	jsr	build

	moveq	#PLAY_OBJS,d6
	move.l	#ASCRN2,p1_scr+O_DATA
	move.l	#BSCRN2,p2_scr+O_DATA
	lea	pause_scr,a0
	move.b	#RMW_ON,O_FLAGS(a0)
	move.b	#0,O_TYPE(a0)				; set to non-scaled bitmap type

	lea	playobjs,a1
	lea	olist_sec,a2
	jsr	build

	move.l	#olist_sec,listAddr
	move.l	#ASCRN1,screen_addr
	move.w	#0,buffNum
	move.w	#0,buffShn
;
; replay the game
;
; set up the players' attributes
;
	move.l	#PLAYER1,player
	moveq.l	#0,d0
	move.l	d0,timestamp
	move.l	d0,packtime
	move.l	d0,PLAYER1+CAR_FRAME
	move.l	d0,PLAYER1+CAR_TOTFRAME
	move.w	d0,PLAYER1+QTIME
	move.l	#(1 << OPTION),PLAYER1+CAR_CTRL
	move.w	#2,PLAYER1+CAMERA_FLAG

	move.l	d0,PLAYER2+CAR_FRAME
	move.l	d0,PLAYER2+CAR_TOTFRAME
	move.w	d0,PLAYER2+QTIME
	move.l	#(1 << OPTION),PLAYER2+CAR_CTRL
	move.w	#2,PLAYER2+CAMERA_FLAG
;
; re-initialize animation routines
;
	move.l	animinit,a0
	jsr	(a0)

; if we're playing crash and score, reset the
; powerball model (cleared in utime.gas) to
; point at the winning car's model, since
; the winner must be in the powerball's band

	cmp.w	#2,gametype
	bne	.49
	move.l	winner,a0
	move.l	FLOOR_MODEL(a0),dotloc
.49:

	move.w	#0,framedone
rplaylp:
	move.w	#QUANTUM/2,playspd
	jsr	input
	move.l	joybothe,d0
	and.l	#(1<<FIRE_A)|(1<<FIRE_B)|(1<<FIRE_C),d0
	bne	donedone
	move.l	joybothc,d0
	btst.l	#OPTION,d0		; option button down?
	beq.b	.noopt
		move.w	#QUANTUM/5,playspd
.noopt:
	btst.l	#PAUSE,d0		; pause button down?
	bne.b	rplaylp			; don't play anything else

	jsr	replaytd
.10:
	stop	#$2000
	tst.w	framedone		; is the GPU finished?
	beq.b	.10			; no -- keep waiting
	tst.w	twoplayer		; 1 player mode?
	beq.b	rplaylp			; yes: play another frame
	tst.w	modem			; modem?
	bne.b	rplaylp			; yes: play another frame
	move.l	player,d0
	eori.l	#(PLAYER1^PLAYER2),d0	; switch to new player
	move.l	d0,player
	bra.b	rplaylp

donedone:
	jsr	wait_int
	jsr		voicesoff
	jsr		dsp_off
	cmp.w	#0,showrank
	beq.b	.10
	tst.b	gothiscore
	beq.b	.10
	bra		gohiedit
.10:
	move.l	#stacktop,a7				; re-init stack
	jsr		clearscr
	move.l	#REGGAE_MUSIC,songnum
	jsr		playmus					;start music
	lea		palette,a0				;get address of palette
	jsr		set_palette				;copy palette into
	jsr		goselect
	jmp		mainloop

;
; figure out what kind of game the user wants to play, based on earlier stuff;
; also, make sure the appropriate world is moved to startWorld
;
	.extern	studio,garage,future,westa,toya
	.extern bighouse,westw,city,racew,toyw,garr

;loading screens for each world (address of compressed picture)
loadscrs::
	dc.l	loadvp,loadsf,loadwst,loadhs,loadtod,loadgrc
; x,y coordinates for start icon and finish icon for each world
ldscrxy::
	dc.w	$5a,$c0		; velocity park
	dc.w	$e0,$10c	;     start, finish
	dc.w	$24,$106	; san francisco
	dc.w	$140,$6c
	dc.w	$12d,$f0	; westworld
	dc.w	$30,$9e
	dc.w	$2a, $8c	; Jerome's pad
	dc.w	$a0, $cc
	dc.w	$400,$400	; Planet Todd
	dc.w	$400,$400	; 
	dc.w	$c0,$110	; garace - sf 2plr
	dc.w	$c0,$d0

; arena worlds
aworlds:	dc.l	future,garage,westa,studio,toya
; and arenas skys
askys:		dc.l	o_SKY,o_GARASKY,o_SKY,o_SKY,o_SKY
; and arenas sea levels
aseas:		dc.l	$7ffff000,$001ff000,$00101000,$7ffff000,$6ffff000

; big worlds
bworlds:	dc.l	racew,city,westw,bighouse,toyw,garr
bskys:		dc.l	o_GARASKY,o_SKY,o_SKY,o_SKY,o_SKY,o_GARASKY
bseas:		dc.l	$0028e000,$0098f000,$00301000,$008ff000,$0038e000,$001ff000

; music for worlds
wmusic:		dc.l	CLUBWAVE_MUSIC,JAZZ_MUSIC,HONKY_MUSIC,RAP_MUSIC,CLUBWAVE_MUSIC,JAZZ_MUSIC

initgame::
	move.w	#0,splitscreen
	moveq	#0,d0
	lea	dotloc,a0
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.w	cur_act,d0			; get activity
	cmp.w	#RACE1PLR,d0
	bne	.10
		move.w	#0,twoplayer
		move.w	#1,gametype
		lea	bworlds,a0
		lea	bskys,a4
		lea	bseas,a5
		bra	ldit
.10:
	cmp.w	#RACE2PLR,d0
	bne	.20
		move.w	#1,twoplayer
		move.w	#1,splitscreen
		move.w	#1,gametype
		lea	bworlds,a0
		lea	bskys,a4
		lea	bseas,a5
		bra	ldit
.20:
	cmp.w	#TAG2PLR,d0
	bne	.30
		move.w	#1,twoplayer
		move.w	#1,splitscreen
		move.w	#0,gametype
		lea	aworlds,a0
		lea	askys,a4
		lea	aseas,a5
		bra	ldit
.30:
	cmp.w	#COLL1PLR,d0
	bne	.40
		move.w	#0,twoplayer
		move.w	#2,gametype
		lea	aworlds,a0
		lea	askys,a4
		lea	aseas,a5
		bra	ldit

.40:
	move.w	#1,splitscreen
	move.w	#1,twoplayer
	move.w	#2,gametype
	lea	aworlds,a0
	lea	askys,a4
	lea	aseas,a5
ldit:
;***modem stuff: if we're on a modem, we're 2 player, non split screen
	tst.w	modem
	beq.b	.nom
	move.w	#0,splitscreen
	move.w	#1,twoplayer
.nom:
	move.w	curlevel,d0
	add.w	d0,d0
	add.w	d0,d0
	move.l	(a0,d0.w),a0
	lea	wmusic,a2
	move.l	(a2,d0.w),songnum			;playmus needs number of music to play in songnum
	cmp.w	#TAG2PLR,cur_act
	bne.b	.05
	cmp.w	#TOTAL_SONGS,tagtune0
	beq.b	.05						;if either player selects 'none' for a tag tune, use the default
	cmp.w	#TOTAL_SONGS,tagtune1
	beq.b	.05
	jsr		it_music
	bra.b	.08
.05:	jsr		playmus				;turn on music while decompressing
.08:
	move.l	(a4,d0.w),a4				; get the sky
	move.l	(a5,d0.w),SEALEVEL			; get the sea level
	lea	mapWorld,a1

; uncompress a0 to a1
	move.l	a0,_inptr
	move.l	a1,_outptr
; save the sky
	move.l	a4,worldsky
;
; set the horizon level
;
	move.l	#640,d0
	cmp.l	#o_SKY,a4
	beq.b	.plainsky
		move.l	#618,d0
.plainsky:
	move.l	d0,SKYHIGH

;
; inflate the world
;
	jsr	_inflate

	tst.w	d0
	beq	.10
	move.l	d0,-(sp)
	jsr	_fatal
.10:
;
; inflate the sky
;
	move.l	worldsky,_inptr
	move.l	#SKY,_outptr
	jsr	_inflate
	tst.w	d0
	beq	.20
	move.l	d0,-(sp)
	jsr	_fatal
.20:
	rts

;
; Utility functions for unzip'ing
;
_loadgpu::
	move.l	4(sp),a0
	jmp	load_gpu


DONEFLAG	EQU	G_RAM+2996

_rungpu::
	move.l	#G_RAM,G_PC
	move.l	#$abcdef01,d1
	move.l	d1,DONEFLAG
	move.l	#$11,G_CTRL
.10:
	move.l	DONEFLAG,d0
	cmp.l	d1,d0
	; RETAIL RECONSTRUCTION (2026): branch displacement is -10,
	; and the original Atari assembler chose the 8-bit form.
	; A 16-bit branch changes the padding before the object list.
	beq.b	.10

	rts

RFLAG	equ	RELEASE_OFF		; object processor RELEASE flag to be used

	.phrase
playolst::
;	player 1
	dc.w		0			; o_xpos
	dc.w		38		; o_ypos	; top o screen is n_vdb
	dc.l		ASCRN1		; o_data
	dc.w		95			; o_height
	dc.w		80			; o_dwidth
	dc.w		80			; o_iwidth
	dc.b		RFLAG		; o_flags
	dc.b		0			; o_firstpix
	dc.b		0			; o_type	Bit Mapped type
	dc.b		4			; o_depth
	dc.b		1			; o_pitch
	dc.b		0			; o_index
	dc.w		0			; o_desc
	dc.l		$202020		; o_scale

;---------------------------------------------------------------------
;	player 1 hood (1 player mode only)
	dc.w		$400			; o_xpos	
	dc.w		38+280			; o_ypos	; top o screen is n_vdb
	dc.l		0			; o_data
	dc.w		60			; o_height	; height gets set at run time
	dc.w		80			; o_dwidth
	dc.w		80			; o_iwidth
	dc.b		TRANS_ON|RFLAG	; o_flags
	dc.b		0			; o_firstpix
	dc.b		0			; o_type	Bit Mapped type
	dc.b		4			; o_depth
	dc.b		1			; o_pitch
	dc.b		0			; o_index
	dc.w		0			; o_desc
	dc.l		$202020		; o_scale

;---------------------------------------------------------------------
;	player 1 HUD
	dc.w		20			; o_xpos
	dc.w		38+120		; o_ypos	; top o screen is n_vdb
	dc.l		HUD1
	dc.w		32			; o_height
	dc.w		16			; o_dwidth
	dc.w		16			; o_iwidth
	dc.b		TRANS_ON|RFLAG	; o_flags
	dc.b		0			; o_firstpix
	dc.b		0			; o_type	Bit Mapped type
	dc.b		4			; o_depth
	dc.b		1			; o_pitch
	dc.b		0			; o_index
	dc.w		0			; o_desc
	dc.l		$202020		; o_scale

;---------------------------------------------------------------------
;	map
	dc.w		112			; o_xpos
	dc.w		38+193		; o_ypos
	dc.l		mapWorld		; o_data
	dc.w		24			; o_height
	dc.w		24			; o_dwidth
	dc.w		24			; o_iwidth
	dc.b		RFLAG		; o_flags
	dc.b		0			; o_firstpix
	dc.b		0			; o_type	Bit Mapped type
	dc.b		4			; o_depth
	dc.b		1			; o_pitch
	dc.b		0			; o_index
	dc.w		0			; o_desc
	dc.l		$202020			; o_scale
;---------------------------------------------------------------------
;	middle bar
	dc.w		0			; o_xpos
	dc.w		38+190		; o_ypos
	dc.l		dash			; o_data
	dc.w		30			; o_height
	dc.w		40			; o_dwidth
	dc.w		40			; o_iwidth
	dc.b		TRANS_ON|RFLAG	; o_flags
	dc.b		0			; o_firstpix
	dc.b		0			; o_type	Bit Mapped type
	dc.b		3			; o_depth
	dc.b		1			; o_pitch
	dc.b		0			; o_index
	dc.w		0			; o_desc
	dc.l		$202040		; o_scale

p2_obj::
;---------------------------------------------------------------------
;	player 2
	dc.w		0			; o_xpos	
	dc.w		38+250			; o_ypos	; top o screen is n_vdb
	dc.l		BSCRN1			; o_data
	dc.w		95			; o_height
	dc.w		80			; o_dwidth
	dc.w		80			; o_iwidth
	dc.b		RFLAG		; o_flags
	dc.b		0			; o_firstpix
	dc.b		0			; o_type	Bit Mapped type
	dc.b		4			; o_depth
	dc.b		1			; o_pitch
	dc.b		0			; o_index
	dc.w		0			; o_desc
	dc.l		$202020		; o_scale

;---------------------------------------------------------------------
;	player 2 HUD
	dc.w		20			; o_xpos	
	dc.w		38+355			; o_ypos	; top o screen is n_vdb
	dc.l		HUD2
	dc.w		32			; o_height
	dc.w		16			; o_dwidth
	dc.w		16			; o_iwidth
	dc.b		TRANS_ON|RFLAG	; o_flags
	dc.b		0			; o_firstpix
	dc.b		0			; o_type	Bit Mapped type
	dc.b		4			; o_depth
	dc.b		1			; o_pitch
	dc.b		0			; o_index
	dc.w		0			; o_desc
	dc.l		$202020		; o_scale

;---------------------------------------------------------------------
;	"pause" icon
	dc.w		80			; o_xpos	
	dc.w		38+110			; o_ypos	; top o screen is n_vdb
	dc.l		PAUSECRY
	dc.w		104			; o_height
	dc.w		40			; o_dwidth
	dc.w		40			; o_iwidth
	dc.b		0			; o_flags
	dc.b		0			; o_firstpix
	dc.b		0			; o_type	Bit Mapped type
	dc.b		4			; o_depth
	dc.b		1			; o_pitch
	dc.b		0			; o_index
	dc.w		0			; o_desc
	dc.l		$202020		; o_scale

;
; copy a car model from ROM to RAM, and fix it up
; WARNING WARNING WARNING
; the car*.mdl files must be edited by hand so that
; car?_head is at the beginning of the file, rather
; than the end!!!
;
; parameters: a0 = pointer to ROM copy of car
;             a1 = pointer to RAM copy of car

	.even
carfix:
	move.l	#4096,d0		; number of bytes to copy
	move.l	a1,a2			; save a pointer to RAM car_head
	move.l	a1,d7
	move.l	a0,d6
	sub.l	d6,d7			; now d7 is the fixup factor
clp1:
	move.l	(a0)+,(a1)+
	subq.l	#4,d0
	; RETAIL RECONSTRUCTION (2026): preserve short backwards
	; loop branch as encoded in the final cartridge (displacement -6).
	bpl.b	clp1
;
; now fix up the crucial pointers
;
	add.l	d7,PROP_LIST(a2)
	add.l	d7,DIVIDER_LIST(a2)
	add.l	d7,EDGE_LIST(a2)
	add.l	d7,PNT_LIST(a2)
	add.l	d7,SURF_LIST(a2)
	add.l	d7,SURFS_END(a2)
	add.l	d7,TREE(a2)
	add.l	d7,COLOR_LIST(a2)

	rts


	.globl	car1_head
	.globl	car2_head
	.globl	car3_head
	.globl	car4_head
	.globl	car5_head
	.globl	car6_head

	.long
cars_head:
	dc.l	car3_head,car2_head,car1_head,car4_head,car5_head,car6_head
cars_clr:
	dc.w	$78e0,$ffe0,$f0e0,$03ff,$0fd8,$7ac0

	.phrase
	.include "assets/native/resources/data/CAR.DAT"
	.include "assets/3d/native_models/root/car1.mdl"
	.include "assets/3d/native_models/root/car2.mdl"
	.include "assets/3d/native_models/root/car3.mdl"
	.include "assets/3d/native_models/root/car4.mdl"
	.include "assets/3d/native_models/root/car5.mdl"
	.include "assets/3d/native_models/root/car6.mdl"

phonenumber:
	dc.b	5, 5, 5, 1, 2, 1, 2, $ff
