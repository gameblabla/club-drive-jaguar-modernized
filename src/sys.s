	.include	'eq.s'
	.include	'externs.s'
	.include	'3dds.inc'

	.extern	td,push_joypad,stufqueue
GPU_INT		EQU	1
MODEM_INCL	EQU	0
	.text

initonce::
;do this stuff only 1 time
	move.l	#$00070007,G_END		;don't need to swap for GPU
	move.l	#$00070007,D_END		;ditto for DSP
	move.w	#$0100,JOYIN			;set bit 8 to cancel mute

	move.w	#0,$F10000			;JPIT1
	move.w	#0,$F10002			;JPIT2
	moveq	#0,d0
	move.l	d0,D_CTRL				;Turn DSP off
	move.l	d0,G_CTRL		;stop the GPU
	move.l	d0,D_FLAGS		;set the DSP into a known state

	move.b	#NTSC,pal_ntsc			;assume NTSC
	move.w	#5,fTime
	clr.l	d0
	move.w	d0,leftx
	move.w	d0,topy
	move.w	$F14002,d0
	btst.l	#4,d0				;bit 4 set if NTSC
	bne.b	.10
	move.b	#PAL,pal_ntsc
	move.w	#6,fTime
	move.w	#8,leftx
	move.w	#72,topy
.10:
	moveq	#5,d0				;copy the default seeds into ram
	lea		seedinit,a0
	lea		seed,a1
.20:	move.l	(a0)+,(a1)+
	dbra		d0,.20

	move.l	#0,coverdta
	move.l	#0,coverdta+4

	move.w	#DEF_CAR0,cur_car0			;car type 0 for player 1
	move.w	#DEF_CAR1,cur_car1			;car type 0 for player 2
	move.w	#DEF_ACTIVITY,cur_act
	move.w	#DEF_LAPS,rac1laps
	move.w	#DEF_LAPS,rac2laps
	move.w	#DEF_TAGTIME,tagtime
	move.w	#DEF_TAGTUNE1,tagtune0
	move.w	#DEF_TAGTUNE2,tagtune1
	move.w	#DEF_DOTS,col1dots
	move.w	#DEF_DOTS,col2dots
	move.w	#DEF_MDM,modem
	move.w	#DEF_LEVEL,curlevel

	moveq	#-1,d0
	move.l	d0,prevscr0
	move.l	d0,prevscr1

	moveq	#0,d0
	move.b	d0,muteflag			;music on
	move.w	d0,loadsdn			;club drive sign and map background not loaded yet
	bsr		mkbranch

	bsr		ob_heads				;copy object headers into ram

	rts

initstuff::
;do this after a restart
	move.w	#-1,gamemode			;make sure title screen gets loaded the first time
	clr.b	stufqueue			;make sure vi doesn't read joypad

	move.l	#4,olistbld+4			;set up a stop object
	move.l	#0,olistbld
	move.l	#olist,d0
	swap	d0
	move.l	d0,OLP

	move.l	#0,G_CTRL			; stop the GPU

	moveq	#1,d6
	lea		scrcover,a1
	lea		olist_ram,a2
	bsr		build
;;;	bsr		copy_olist

	bsr		VideoIni				;init video stuff
	bsr		IntInit
	move.l	#olist,d0				;get address of start of object list
	swap		d0
	move.l	d0,OLP

	lea		palette,a0			;get address of palette
	bsr		set_palette			;copy palette into

	move.w	#$4C7,VMODE			;turn on display, 16 bit RGB

	jsr		_init_alloc			;initialize C memory manager
	move.l	#art,_inptr			;start of compressed data
	move.l	#strt8bit,_outptr		;where to put uncompressed data
	jsr		_inflate				;unzip 8 bit art

	moveq.l	#0,d0
	move.l	d0,timestamp
	move.l	d0,packtime
	move.w	d0,buffNum
	move.w	d0,buffShn
	move.b	d0,keepmus			;flag for restarting music on title screen
	move.b	d0,muteflag
	move.w	d0,radiocnt			;total frames for the sound for changing music

	bsr		defhighs				;get high scores from eeprom or set default high scores
	rts

ld_decmp::
;copy the decompression .GAS code into the GPU
	lea		dejagst,a0			;starting address of dejag.bin
	bsr		load_gpu
	move.l	#dehuff,Dehuff_Adr		;set the pointer to dehuff.abs table
	rts
ld_uncmp::
;copy the uncomp .GAS code into the GPU
	lea		uncomp,a0				;starting address of uncomp.bin
	bra.b	load_gpu
ld_ltn::
;copy the lighten .GAS code into the GPU
	lea		lighten,a0			;starting address of lighten.bin
;	bra.b	load_gpu
load_gpu::
;A0 = address of GPU code to load
	move.l	#$00000008,G_CTRL		;stop the GPU
	move.l	(a0)+,a1				;GPU ram address
	move.l	(a0)+,d0				;size of code in bytes
	move.l	a0,d1
	and.l	#7,d1				; is source phrase aligned?
	bne.b	.slowway			; nope == do it the slow way
	move.l	a1,d1				; is destination phrase aligned?
	and.l	#7,d1				; nope == do it the slow way
	bne.b	.slowway
	move.l	a0,A2_BASE			; set source
	move.l	#PIXEL8|WID8|XADDPHR,A2_FLAGS
	move.l	#0,A2_PIXEL
	move.l	#$00008000,d1
	lea	0(a1,d1.l),a1			; use the 32 bit memory interface
	move.l	a1,A1_BASE			; set destination
	move.l	#PIXEL8|WID8|XADDPHR,A1_FLAGS
	move.l	#0,A1_PIXEL
	move.l	#0,A1_FPIXEL
	or.l	#$00010000,d0			; set outer loop counter = 1
	move.l	d0,B_COUNT
	move.l	#SRCEN|LFU_A|LFU_AN,B_CMD	; start up the blitter
	rts
.slowway:
	asr.l	#2,d0				;convert bytes to longs
	subq.l	#1,d0				;subtract 1 for loop counter
.20:	move.l	(a0)+,(a1)+
	dbra		d0,.20
	rts

load_q75::
	move.l	#q75,A2_BASE					;source address
	bra.b	ld_dq
load_q85::
	move.l	#q85,A2_BASE					;source address
;	bra.b	ld_dq
ld_dq::
;load the decompression table into GPU ram
;A2_BASE is set to the address of the dq table to load
	move.l	#$00000008,G_CTRL				;stop the GPU
	move.l	#DQ_Adr,A1_BASE				;destination address in GPU ram
	move.l	#PITCH1|PIXEL32|WID80|XADDPHR,d0
	move.l	d0,A1_FLAGS					;destination
	move.l	d0,A2_FLAGS					;source
	moveq	#0,d0
	move.l	d0,A2_PIXEL					;start at 0,0 of source image
	move.l	d0,A1_PIXEL					;Y,X position to write data in destination area
	move.l	#$00010050,B_COUNT				;copy 320 bytes or 80 longs
	move.l	#$0001FFB0,A1_STEP				;1 in Y step size, negative width in X step size
	move.l	#UPDA1|SRCEN|LFU_A|LFU_AN,B_CMD	;turn on blitter
	rts

ob_heads::
;copy object headers into ram
	lea		ob_src,a0
	lea		ob_dst,a1
	lea		ob_num,a2
	moveq	#6,d0						;items in each table - 1
.10:
	move.l	(a0)+,a3
	move.l	(a1)+,a4
	move.w	(a2)+,d1
.20:
	move.w	(a3)+,(a4)+
	dbra		d1,.20
	dbra		d0,.10
	rts
ob_src::
	dc.l		titlolst,selolst,credolst,higholst,playolst,scrcov,ldscrcv
ob_dst::
	dc.l		titlobjs,selobjs,credobjs,highobjs,playobjs,scrcover,ldscrobj
ob_num::
	dc.w		(TITLE_OBJS*OBJ_SIZE/2)-1
	dc.w		(SEL_OBJS*OBJ_SIZE/2)-1
	dc.w		(CREDIT_OBJS*OBJ_SIZE/2)-1
	dc.w		(HISCORE_OBJS*OBJ_SIZE/2)-1
	dc.w		(PLAY_OBJS*OBJ_SIZE/2)-1
	dc.w		(1*OBJ_SIZE/2)-1
	dc.w		(LOAD_OBJS*OBJ_SIZE/2)-1

build::						;pack the object data into olist_ram
;A1 = need address of first object
;A2 is the address of the object list being built
;D6 = total number of objects to be processed

;register use
;A0 is the address of the object list used by the object processor
;D0 holds the long being built
;D1 is used for temporary calculations
;D2 is the lines off screen, calculated in set_odata, used by set_oheight
;D3 is #12 for shifting d0
;D4 is #10 for shifting d0
;D5 is #11 for shifting d0
;D6 counts the objects being processed
;D7 is the address of the boject used by the object processor divided by 8

	move.w	#N_SCRN_TOP-1,d2	;assume NTSC
	cmp.b	#NTSC,pal_ntsc
	beq.b	.01
	move.w	#P_SCRN_TOP-1,d2
.01:
	moveq	#12,d3			;for doing lsl.l on d0
	moveq	#10,d4			;for doing lsl.l on d0
	moveq	#11,d5			;for doing lsl.l on d0
	move.l	#olistbld,d7		;address of packed olist
	lsr.l	#3,d7			;divide by 8 for object processor
	subq.w	#1,d6			;start dbra counter at total objects - 1
proc_obj:						;process an object
	tst.b	O_TYPE(a1)		;check the delete flag for this object
	bmi		next_obj			;skip this object if negative bit is set

;PHRASE 1
set_odata:
;if the object is above top line of the screen,
;the data pointer is set to the first line of the object that is on screen
	move.l	O_DATA(a1),d0		;get normal data address
;D2 = screen top - 1
	sub.w	O_YPOS(a1),d2		;top of screen - ypos = half lines off top of screen
	bpl.b	.05				;if object is above top of screen, use normal data address
	clr.w	d2				;0 lines off screen, use normal data address
	bra.b	.10
.05:	lsr.w	#1,d2			;convert half lines to lines
	move.w	O_DWIDTH(a1),d1	;get phrases per line of data in the object
	lsl.w	#3,d1			;multiply phrases * 8 bytes per phrase
	mulu.w	d2,d1			;lines off screen * bytes per line in the object
	add.l	d1,d0			;skip the total bytes that are off the top of the screen
.10:	lsr.l	#3,d0			;divide by 8
	lsl.l	d5,d0			;shift left 11 bits to make room for link pointer

;set the link pointer to the next object
	addq.l	#4,d7			;next object is 4 phrases ahead
	move.l	d7,d1			;get address in olist of next object
	
	lsr.l	#8,d1			;the rightmost 8 bits go in the next long, so remove them
	or.l		d1,d0			;or with data pointer
	move.l	d0,(a2)+			;save first long in phrase 1, advance the pointer to next long

	move.b	d7,d0			;get the low 8 bits of the link pointer that was saved earlier
	lsl.l	d4,d0			;shift left 10 bits to make room for height

set_oheight:
;d2.w is set to the number of lines that are above the top of the screen
;if part of the object is above the top line of the screen,
;the height is reduced by the number of lines off the top of the screen
	move.w	O_HEIGHT(a1),d1	;get the height of the object
	cmpi.b	#1,O_TYPE(a1)		;see if this is a scaled bit map object
	bne.b	.10				;branch if object is not scaled
	subq.w	#1,d1			;an extra line is displayed at the bottom of the object if this is not here
.10:	sub.w	d2,d1			;subtract lines off screen from scaled height
	bmi.b	.20				;if lines off screen > height, make height 0 instead of negative
	or.w		d1,d0			;or with link pointer in second half of phrase 1
.20:	lsl.l	d5,d0			;shift left 11 bits to make room for ypos

set_oypos:
;if ypos is negative, it gets set to 0
;set_odata and set_oheight will adjust the data pointer and height accordingly
	move.w	O_YPOS(a1),d1
	bmi.b	.10				;if ypos is negative, object would not be displayed, so set ypos to 0
	and.w	#$7ff,d1			;only write 11 bits for ypos
	or.w		d1,d0			;or with link pointer and height
.10:	lsl.l	#3,d0			;shift left 3 bits to make room for type

set_otype: 
	or.b		O_TYPE(a1),d0		;object type
	move.l	d0,(a2)+			;write second half of phrase 1

;PHRASE 2
set_ofirstpix:
	move.b	O_FIRSTPIX(a1),d0
	lsl.l	#4,d0			;shift left 4 bits to make room for release, transparent, rmw, reflect bits

set_flags:
	or.b		O_FLAGS(a1),d0		;or with firstpix
	lsl.l	#7,d0			;shift left 7 bits to make room for index

set_oindex:
	or.b		O_INDEX(a1),d0		;or with firstpix and flags
	lsl.l	#6,d0			;shift left 6 bits to make room for part of iwidth

set_oiwidth:
	move.w	O_IWIDTH(a1),d1			
	lsr.w	#4,d1			;right 4 bits go in the next long, so remove them
	or.b		d1,d0
	move.l	d0,(a2)+			;write first long of phrase 2

	move.w	O_IWIDTH(a1),d0			
	and.w	#$F,d0			;get low 4 bits of iwidth
	lsl.l	d4,d0			;shift left 10 bits to make room for dwidth

set_odwidth:
	or.w		O_DWIDTH(a1),d0	;or with part of iwidth
	lsl.l	#3,d0			;shift left 3 bits to make room for pitch

set_opitch:
	or.b		O_PITCH(a1),d0		;or with dwidth and iwidth
	lsl.l	#3,d0			;shift left 3 bits to make room for depth

set_odepth:
	or.b		O_DEPTH(a1),d0		;or with dwidth, iwidth, pitch
	lsl.l	d3,d0			;shift left 12 bits to make room for xpos

set_oxpos:
	move.w	O_XPOS(a1),d1		;object xpos
	and.w	#$fff,d1			;only write 12 bits for xpos
	or.w		d1,d0			;or with the rest of the stuff
	move.l	d0,(a2)+			;write second half of phrase 2

;PHRASE 3
;for scaled bit map object only
	move.l	O_SCALE(a1),4(a2)	;write remainder, vscale, hscale bytes in 2nd long of phrase 3
	adda.l	#16,a2			;add extra 2 phrases for scaled object

next_obj:						;jump to here if delete flag is on
	adda.l	#OBJ_SIZE,a1		;point to next object in pseudo object list
	dbra		d6,proc_obj		;repeat until all objects have been processed
	
;write a stop object at the end of the list
	move.l	#0,(a2)+		
	move.l	#4,(a2)			;write object type 4 (stop object)
 	rts	

copy_olist::
	move.l		listAddr,a0		;listAddr contains pointer to object list image
	lea		olistbld,a1		;beginning of olist
	moveq.l	#4,d1				; stop object
.10:
	move.l	(a0)+,(a1)+			; copy first long of phrase
	move.l	(a0)+,d0			; get second long
	move.l	d0,(a1)+			; copy it
	cmp.l	d1,d0				; see if we are at the stop object
	bne.b	.10
	rts

mkbranch::
; [-------unused-------][--------link--------] [unused] cc[---ypos---]type
; xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx

;link is the address of the stop object / 8
;cc is 2 for branch0, 1 for branch1
;type is 3 for both branch objects
;ypos is vde for branch0, vdb for branch1
	move.l	#0,stopobj
	move.l	#4,stopobj+4

	move.l	#n_vde,d1					;assume NTSC
	moveq	#n_vdb,d2
	cmp.b	#NTSC,pal_ntsc
	beq.b	.20
	move.l	#p_vde,d1
	moveq	#p_vdb,d2			; retail PAL VDB encoding
.20:
	move.l	#stopobj,d0				;get the address of the stop object
	lsr.l	#3,d0					;reduce address to phrases
	move.l	d0,d3					;need to use low byte later

	lsr.l	#8,d0					;lowest 8 bits go in next long, so remove them
	move.l	d0,branch0				;set high bytes of link pointer
	lsl.l	#3,d1					;shift vde left 3 to make room for object type
	or.w		#$8003,d1					;set cc to 2, type to 3
	lsl.l	#8,d3					;shift past 8 unused bits
	swap		d3						;move low 8 bits of link pointer and unused 8 bits to high word
	move.w	d1,d3					;combine cc, ypos, type with low 8 bits of link pointer and unused 8 bits
	move.l	d3,branch0+4				;save 2nd long in the phrase

	move.l	branch0,branch1			;high bytes of link pointer are the same as branch0
	lsl.l	#3,d2					;shift vdb left 3 to make room for object type
	or.w		#$4003,d2					;set cc to 1, type to 3
	move.w	d2,d3					;combine cc, ypos, type with low 8 bits of link pointer and unused 8 bits
	move.l	d3,branch1+4				;save 2nd long in the phrase
	rts

VideoIni::
	cmp.b	#NTSC,pal_ntsc
	beq.b	.10
	move.w	#p_hde,HDE
	move.w	#p_hdb1,HDB1
	move.w	#p_hdb2,HDB2
	move.w	#p_vdb,VDB
	bra.b	.50
.10:
	move.w	#n_hde,HDE
	move.w	#n_hdb1,HDB1
	move.w	#n_hdb2,HDB2
	move.w	#n_vdb,VDB
.50:
	move.w	#$FFFF,VDE
	move.w	#$0000,BG				;default background color (16 bit RGB or CRY color)
	move.l	#$00000000,BORD1		;default border color (green,red,unused,blue)
	move.w	#$4C7,VMODE			;turn on display, 16 bit RGB
	rts


set_palette::
;A0 must be the address of the palette data
;palette data is 256 words of colors
	bsr	wait_int		; wait for an interrupt
	lea		CLUT,a1			;get address of color lookup table
	move.w	#255,d0			;number of colors to set
.10:	move.w	(a0)+,(a1)+		;put color value into color lookup table
	dbra		d0,.10			;continue through palette table
	rts

wait_int::
	move.l	timestamp,d0
.10:	stop		#$2000
	cmp.l	timestamp,d0
	beq.b	.10
	rts

	.even

LEVEL2	equ	4*$40
IntInit::
	move.w	sr,d7			; save status register
	ori.w	#$0700,sr		; interrupts off
	move.l	#0,timestamp
	move.l	#0,packtime
	move.l	#0,_MDMin
	move.l	#Frame,LEVEL2.w		; retail stores interrupt vector using 16-bit absolute address
	move.w	#$13,INT1
	move.w	#n_vde|1,d1
	cmp.b	#NTSC,pal_ntsc
	beq.b	.10
	move.w	#p_vde|1,d1
.10:	move.w	d1,VI

	and.w	#$f8ff,d7		; d7 was the old status register
	move.w	d7,sr
	rts

;
; generic interrupt handler
; throughout the handler, register d6
; contains the current set of pending
; interrupts
; also a4,d4 for modems
;
Frame::
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	INT1,d6
	lea	_MDMin,a4
	move.w	#MDM_BUFSIZ,d4
.beg:
	move.w	d6,d0			; clear pending irqs
	lsl.w	#8,d0
	or.w	#$13,d0			; and enable them again
	move.w	d0,INT1

	btst	#4,d6			; is this a Jerry interrupt?
	beq	.c_tom
	bclr	#4,d6

	move.w	$f10020,d0
	btst	#4,d0			; is it the async serial?
	beq	.c_tom

	lsl.w	#8,d0
	or.w	#$10,d0
	move.w	d0, $f10020		; clear pending irq


	bsr	asyncint		; get the character

	or.w	INT1,d6
	bra.b	.beg

.c_tom:

	btst	#1,d6			; has a GPU interrupt happened?
	beq	.vbl0
		bclr	#1,d6

.gpuplay:
		; the GPU interrupt
		move.w	#1,framedone
		move.w	gpu_do,d0		; what was the GPU doing?
		btst.l	#0,d0			; if it was not rendering...
		beq	.noswtch		; ...skip the screen update stuff

		move.w	buffNum, d0
		addq.w	#1, d0
		move.w	d0, buffNum
		move.l	screen_addr,d1
		move.l	d1,last_screen		; save last screen drawn info
		tst.w	splitscreen
		beq	.3
			eori.l	#$ed80, d1
			btst		#0, d0
			bne		.5
	.3:
			eori.l	#ATOGGLE, d1
			move.w	#0,framedone	; wait for the VBI
	.5:
		move.l	d1,screen_addr
.noswtch:
		or.w	INT1,d6
		bra	.beg
.vbl0:
	btst	#0,d6			; Vertical blank interrupt?
	beq	.novbi
	bclr	#0,d6

	; test for buffer switch
	move.w	gamemode,d0
	cmp.w	#PLAY_MODE,d0
	bne.b	.20
	add.w	#1,framecnt
	move.w	buffNum, d0
	move.w	buffShn, d1
	eor.w	d1, d0
	tst.w	splitscreen
	beq	.12
		btst		#1, d0
		bra	.14
.12:
	btst		#0, d0
.14:
	beq		.20
		move.w	buffNum, buffShn
		move.l	#olist_sec, d1
		eori.l	#olist_ram, d1
		eor.l	d1, listAddr
		move.w	#1,framedone	; inform main loop that a frame is done
		move.w	framecnt,fps
		move.w	#0,framecnt
.20:

.docpy:
.if MODEM_INCL
	move.w	$f10020,d0
	btst	#4,d0
	bne	.cpyok
	lsl.w	#8,d0
	or.w	#$10,d0
	move.w	d0,$f10020
	bsr	asyncint
.endif
.cpyok:

;	bsr		copy_olist

	move.l		listAddr,a0		;listAddr contains pointer to object list image
	lea		olistbld,a1		;beginning of olist
	moveq.l	#4,d1				; stop object
	tst.w	listgood			;is listAddr valid?
	bne.b	.cpolist			; yes: go copy it
	move.l	d1,(a1)+			;bad listAddr; just put a stop object in
	move.l	d1,(a1)+
	bra	.donecopy
.cpolist:
	move.l	(a0)+,(a1)+			; copy first long of phrase
	move.l	(a0)+,d0			; get second long
	move.l	d0,(a1)+			; copy it
	cmp.l	d1,d0				; see if we are at the stop object
	bne.b	.cpolist
.donecopy:
.if MODEM_INCL
	move.w	$f10020,d0
	btst	#4,d0
	bne	.tstmpok
	lsl.w	#8,d0
	or.w	#$10,d0
	move.w	d0,$f10020
	bsr	asyncint
.endif

.tstmpok:
	moveq.l	#0,d0
	move.w	fTime,d0
	add.l	d0,timestamp

;
; WARNING WARNING WARNING
; Move this code to the main game loop when we put in
; modem stuff, it may take too long during interrupts
;
	;and finally,read user input
	tst.b	stufqueue
	beq.b	.novbi
		move.l	d6,-(sp)
		eori.l	#(PLAYER1 ^ PLAYER2), chkPlayer
		jsr		push_joypad
		move.l	(sp)+,d6

.novbi:
	or.w	INT1,d6			; check for more interrupts
	and.w	#$13,d6			; that we're interested in
	bne	.beg

	movem.l	(sp)+,d0-d7/a0-a6
	move.w	#0,INT2
	rte

;
; specialized interrupt handler:
; runs while everything is being initialized; puts up the flashing
; "start" and "finish" icons as appropriate
; throughout the handler, register d6
; contains the current set of pending
; interrupts
;
LDFrame::
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	INT1,d6
	lea	_MDMin,a4
	move.w	#MDM_BUFSIZ,d4
.beg:
	move.w	d6,d0			; clear pending irqs
	lsl.w	#8,d0
	or.w	#$13,d0			; and enable them again
	move.w	d0,INT1

	btst	#4,d6			; is this a Jerry interrupt?
	beq	.c_tom
	bclr	#4,d6

	move.w	$f10020,d0
	btst	#4,d0			; is it the async serial?
	beq	.c_tom

	lsl.w	#8,d0
	or.w	#$10,d0
	move.w	d0, $f10020		; clear pending irq


	bsr	asyncint		; get the character

	or.w	INT1,d6
	bra.b	.beg

.c_tom:

	bclr	#1,d6
.vbl0:
	btst	#0,d6			; Vertical blank interrupt?
	beq	.novbi
	bclr	#0,d6

;
; update elapsed time
;
	moveq.l	#0,d1
	move.w	fTime,d1
	move.l	timestamp,d0
	add.l	d1,d0
	move.l	d0,timestamp
;
; divide by 128 to get (roughly) thirds of a second
;
	asr.l	#7,d0
	cmp.l	#16,d0		; has the total time elapsed yet?
	bpl	.docpy		; yes -- leave listAddr alone
	add.l	d0,d0
	add.l	d0,d0		; multiply by 4
	lea	ldscrtim,a0
	move.l	0(a0,d0.l),listAddr

.docpy:
	move.w	$f10020,d0
	btst	#4,d0
	bne	.cpyok
	lsl.w	#8,d0
	or.w	#$10,d0
	move.w	d0,$f10020
	bsr	asyncint

.cpyok:

;	bsr		copy_olist

	move.l		listAddr,a0		;listAddr contains pointer to object list image
	lea		olistbld,a1		;beginning of olist
	moveq.l	#4,d1				; stop object
.cpolist:
	move.l	(a0)+,(a1)+			; copy first long of phrase
	move.l	(a0)+,d0			; get second long
	move.l	d0,(a1)+			; copy it
	cmp.l	d1,d0				; see if we are at the stop object
	bne.b	.cpolist

	move.w	$f10020,d0
	btst	#4,d0
	bne	.tstmpok
	lsl.w	#8,d0
	or.w	#$10,d0
	move.w	d0,$f10020
	bsr	asyncint

.tstmpok:

.novbi:
	or.w	INT1,d6			; check for more interrupts
	and.w	#$13,d6			; that we're interested in
	bne	.beg

	movem.l	(sp)+,d0-d7/a0-a6
	move.w	#0,INT2
	rte

;
; specialized interrupt handler:
; runs while collect game is being initialized;
; animates a power ball icon
; throughout the handler, register d6
; contains the current set of pending
; interrupts
;
COLFrame::
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	INT1,d6
	lea	_MDMin,a4
	move.w	#MDM_BUFSIZ,d4
.beg:
	move.w	d6,d0			; clear pending irqs
	lsl.w	#8,d0
	or.w	#$13,d0			; and enable them again
	move.w	d0,INT1

	btst	#4,d6			; is this a Jerry interrupt?
	beq	.c_tom
	bclr	#4,d6

	move.w	$f10020,d0
	btst	#4,d0			; is it the async serial?
	beq	.c_tom

	lsl.w	#8,d0
	or.w	#$10,d0
	move.w	d0, $f10020		; clear pending irq


	bsr	asyncint		; get the character

	or.w	INT1,d6
	bra.b	.beg

.c_tom:

	bclr	#1,d6
.vbl0:
	btst	#0,d6			; Vertical blank interrupt?
	beq	.novbi
	bclr	#0,d6

;
; update elapsed time
;
	move.l	timestamp,d0		; count frames rather than ticks, but use 4 so that
	addq.l	#4,d0			; we're at least "close" to ticks (which would be
	move.l	d0,timestamp		; either 5 or 6; 4 is easier to divide by)
;
; pick an object list
;
	sub.l	#25*4,d0			; wait 25 frames before changing anything
	bmi.b	.docpy
	sub.l	#10*4,d0			; next n frames are static ball
	bpl.b	.anim
	move.l	#olist_l1,listAddr
	bra.b	.docpy
.anim:
	asr.l	#2,d0			; divide by 4
	and.l	#$3c,d0			; 16*4 frames	(0xf << 2 == 0x3c)
	lea	balltim,a0
	move.l	0(a0,d0.l),listAddr

.docpy:
	move.w	$f10020,d0
	btst	#4,d0
	bne	.cpyok
	lsl.w	#8,d0
	or.w	#$10,d0
	move.w	d0,$f10020
	bsr	asyncint

.cpyok:

;	bsr		copy_olist

	move.l		listAddr,a0		;listAddr contains pointer to object list image
	lea		olistbld,a1		;beginning of olist
	moveq.l	#4,d1				; stop object
.cpolist:
	move.l	(a0)+,(a1)+			; copy first long of phrase
	move.l	(a0)+,d0			; get second long
	move.l	d0,(a1)+			; copy it
	cmp.l	d1,d0				; see if we are at the stop object
	bne.b	.cpolist

	move.w	$f10020,d0
	btst	#4,d0
	bne	.tstmpok
	lsl.w	#8,d0
	or.w	#$10,d0
	move.w	d0,$f10020
	bsr	asyncint

.tstmpok:

.novbi:
	or.w	INT1,d6			; check for more interrupts
	and.w	#$13,d6			; that we're interested in
	bne	.beg

	movem.l	(sp)+,d0-d7/a0-a6
	move.w	#0,INT2
	rte

;
; specialized interrupt handler:
; runs while tag game is being initialized;
; flashes "you're it" on the screen
; throughout the handler, register d6
; contains the current set of pending
; interrupts
;
TAGFrame::
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	INT1,d6
	lea	_MDMin,a4
	move.w	#MDM_BUFSIZ,d4
.beg:
	move.w	d6,d0			; clear pending irqs
	lsl.w	#8,d0
	or.w	#$13,d0			; and enable them again
	move.w	d0,INT1

	btst	#4,d6			; is this a Jerry interrupt?
	beq	.c_tom
	bclr	#4,d6

	move.w	$f10020,d0
	btst	#4,d0			; is it the async serial?
	beq	.c_tom

	lsl.w	#8,d0
	or.w	#$10,d0
	move.w	d0, $f10020		; clear pending irq


	bsr	asyncint		; get the character

	or.w	INT1,d6
	bra.b	.beg

.c_tom:

	bclr	#1,d6
.vbl0:
	btst	#0,d6			; Vertical blank interrupt?
	beq	.novbi
	bclr	#0,d6

;
; update elapsed time
;
	moveq.l	#0,d1
	move.w	fTime,d1
	move.l	timestamp,d0
	add.l	d1,d0
	move.l	d0,timestamp
;
; pick an object list
;
	move.l	#olist_l2,listAddr
	asr.l	#7,d0			; divide by 128 to get (roughly) thirds of a second
	cmp.l	#7,d0			; time elapsed yet?
	bpl.b	.docpy			; yes == do olist_l2
	btst	#0,d0			; odd frame?
	bne.b	.docpy			; yes == do olist_l2
	move.l	#olist_l1,listAddr

.docpy:
	move.w	$f10020,d0
	btst	#4,d0
	bne	.cpyok
	lsl.w	#8,d0
	or.w	#$10,d0
	move.w	d0,$f10020
	bsr	asyncint

.cpyok:

;	bsr		copy_olist

	move.l		listAddr,a0		;listAddr contains pointer to object list image
	lea		olistbld,a1		;beginning of olist
	moveq.l	#4,d1				; stop object
.cpolist:
	move.l	(a0)+,(a1)+			; copy first long of phrase
	move.l	(a0)+,d0			; get second long
	move.l	d0,(a1)+			; copy it
	cmp.l	d1,d0				; see if we are at the stop object
	bne.b	.cpolist

	move.w	$f10020,d0
	btst	#4,d0
	bne	.tstmpok
	lsl.w	#8,d0
	or.w	#$10,d0
	move.w	d0,$f10020
	bsr	asyncint

.tstmpok:

.novbi:
	or.w	INT1,d6			; check for more interrupts
	and.w	#$13,d6			; that we're interested in
	bne	.beg

	movem.l	(sp)+,d0-d7/a0-a6
	move.w	#0,INT2
	rte

;
; asynchronous interrupt routine
; called at interrupt time; reads the bytes and stuffs them into
; the buffer at _MDMin
;
; WARNING: do not use register d6 in this routine!
; safe assumptions:
; a4.l contains _MDMin
; d4.l contains MDM_BUFSIZ

;
; asynchronous interrupt routine
; called at interrupt time; reads the bytes and stuffs them into
; the buffer at _MDMin
;
; WARNING: do not use register d6 in this routine!
; safe assumptions:
; a4.l contains _MDMin
; d4.l contains MDM_BUFSIZ

asyncint:
	move.w	u_stat,d0
	btst	#u_err,d0		; check for error
	bne.b	.err
	btst	#u_rbf,d0		; receive buffer full?
	beq	.ret			; no -- return
	move.w	u_stat,d0
	btst	#u_err,d0
	bne.b	.err
	move.w	u_data,d0		; get the byte
	add.l	#1,_MDMrec		; record 1 more byte received
	move.w	(a4),d1			; get tail (i.e. where we write to)
	move.w	2(a4),d2		; get head (i.e. where we read from)
	move.b	d0,4(a4,d1.w)		; store the byte in the buffer
	addq.w	#1,d1			; increment tail
	cmp.w	d4,d1			; cmp.w #MDM_BUFSIZ,d1
	bne.b	.10
	moveq	#0,d1
.10:
;
; Ideally, if there's an overflow we would like to drop old bytes
; and stuff the new incoming bytes into the buffer; however,
; doing this requires that the interrupt handler mess with the
; buffer head, which leads to a race condition with _MDMget().
; So we end up dropping newer bytes on overflow, which is bad, but
; better than the race condition

	cmp.w	d1,d2			; is the buffer full?
	beq	.drop
	move.w	d1,(a4)			; no -- update the tail
	bra.b	asyncint
.drop:
	add.l	#1,_MDMdrop		; buffer full: drop a byte


	bra.b	asyncint
.ret:
	rts
.err:
	add.l	#1,_MDMerr
	btst	#10,d0
	beq	.err1
	addq.l	#1,_MDMferr
.err1:	btst	#9,d0
	beq	.err2
	addq.l	#1,_MDMperr
.err2:	btst	#11,d0
	beq	.err3
	addq.l	#1,_MDMoerr
.err3:	move.w	#clrerr+ctl_init,u_ctrl	; clear the error
	nop
	nop
	bra	asyncint


;
; MDMget: get a byte from the async buffer
; returns: positive number (byte) on success, -1 if no bytes available
; uses only registers d0-d1/a0-a1
;
; BUG: if an interrupt happens, and the interrupt handler messes
; with the buffer head, then there can be problems
; (there's a race condition here).
; our temporary work around is to never allow the interrupt
; handler to change the buffer head (and God help us if
; the buffer overflows!)
;
_MDMget::
	lea	_MDMin+4,a0
	moveq.l	#0,d0		; prepare for return value

	move.w	-2(a0),d1	; get buffer head (i.e. where we read from)
	cmp.w	-4(a0),d1	; equals buffer tail (i.e. where we write to)
	beq.b	.err		; if so, the buffer is empty
	move.b	0(a0,d1),d0	; get byte
	addq.w	#1,d1		; increment head
	cmp.w	#MDM_BUFSIZ,d1	; check for wrap around
	bne.b	.10
	moveq	#0,d1
.10:
	move.w	d1,-2(a0)	; save new buffer head
.ret:
	rts
.err:
	moveq.l	#-1,d0
	bra.b	.ret

;
; MDMstat: returns the number of bytes available in the buffer
;
_MDMstat::
	bsr	InspectBuffer
	bmi	.ret
	move.w	_MDMin,d0	; get buffer tail (i.e. where we write to)
	sub.w	_MDMin+2,d0	; bytes = tail-head (tail is where we read from)
	bpl	.ret
	add.w	#MDM_BUFSIZ,d0	; if negative, we've wrapped around; add BUFSIZ to compensate
.ret:
	rts

little equ 1
InspectBuffer:
	movem.l	d2-d4,-(sp)
	moveq	#0,d4		;return code
	lea	_MDMin+4,a0
	move.w	-2(a0),d0
	cmp.w	-4(a0),d0
	beq	.out
.6:	move.w	d0,d2		;save the offset of the start of this packet
	move.b	(a0,d0.w),d1
	cmp.b	#$ff,d1
	beq	.1
	cmp.b	#$fe,d1
	bne	.2
.1:	addq.w	#1,d0		;if it's a synch byte advance the pointer
	cmp.w	#MDM_BUFSIZ,d0
	bne	.3
	moveq	#0,d0
.3:	cmp.w	-4(a0),d0
	beq	.out
	move.b	(a0,d0.w),d1	;and read the real byte
.2:	move.b	d1,d3		;else keep it as a real byte
	addq.w	#1,d0		;and advance the pointer
	cmp.w	#MDM_BUFSIZ,d0
	bne	.4
	moveq	#0,d0
.4:	cmp.w	-4(a0),d0
	beq	.out
	move.b	(a0,d0.w),d1	;get the other real byte
.if little
	cmp.b	#$b1,d1
.else
	cmp.b	#$b1,d3
.endif
	bne	.8
	move.l	#MDM_ERR_CALL_WAITING,d4
	bra	.cut
.8:
.if little
	cmp.b	#$a4,d1
	bne	.7
	btst	#0,d3		;did we get a lost line signal?
.else
	cmp.b	#$a4,d3
	bne	.7
	btst	#0,d1
.endif
	beq	.cut		;no, get rid of it
	move.l	#MDM_ERR_LOST_LINE,d4	;yes, remember the return code
	bra	.cut		;and cut out the packet
.7:	addq.w	#1,d0
	cmp.w	#MDM_BUFSIZ,d0
	bne	.5
	moveq	#0,d0
.5:	cmp.w	-4(a0),d0
	bne	.6
.out:	move.l	d4,d0
	movem.l	(sp)+,d2-d4
	tst.l	d0
	rts
.cut:	cmp.w	-2(a0),d2
	beq	.done
	subq.w	#1,d2
	bpl	.10
	move.w	#MDM_BUFSIZ,d2
.10:	move.b	(a0,d2.w),(a0,d0.w)
	subq.w	#1,d0
	bpl.b	.cut
	move.w	#MDM_BUFSIZ,d0
	bra.b	.cut
.done:	move.w	d0,-2(a0)	;advance the "read from" pointer
	tst.l	d4		;if we have an error, return it
	beq.b	.7		;else look for more
	bra.b	.out

;
; MDMflush: flush all input from the modem
;
_MDMflush::
	move.w	sr,d0
;	ori.w	#$0700,d0
	move	#$2700,sr
	move.l	#0,_MDMin
	move.w	d0,sr
	rts


random::
	move.l	d1,-(sp)
	move.l	seed+4,seed		;move seed 1 to seed 0
	move.l	seed+8,seed+4		;move seed 2 to seed 1
	move.l	seed+12,seed+8		;move seed 3 to seed 2
	move.l	seed+16,seed+12	;move seed 4 to seed 3
	move.l	seed+20,seed+16	;move seed 5 to seed 4
	move.l	seed,d0			;get seed 0
	move.l	seed+12, d1		;get seed 3
	addx.l	d1, d0			;add seed 0 to seed 3
	move.l	seed+20, d1		;get seed 5
	addx.l	d1, d0			;add seed 5 to seed 0 and seed 3
	move.l	d0, seed+20		;store result in seed 5
	move.l	seed, d0			;return new seed value in d0
	move.l	(sp)+, d1			;restore value that was in d1
	rts

seedinit::	dc.l $73510EA7,$495E98CF,$3279CF13,$11126C33,$73213445,$61AEAD73

;
; load screen timing stuff
;
ldscrtim:
	dc.l	olist_l4
	dc.l	olist_l4, olist_l1, olist_l4
	dc.l	olist_l1,  olist_l4, olist_l1
	dc.l	olist_l2, olist_l1, olist_l2
	dc.l	olist_l1, olist_l2, olist_l2
	dc.l	olist_l2, olist_l2, olist_l3
	dc.l	olist_l3, olist_l3, olist_l3

balltim:
	dc.l	olist_l1, olist_l1, olist_l2, olist_l2
	dc.l	olist_l3, olist_l3, olist_l4, olist_l4
	dc.l	olist_l5, olist_l5, olist_l6, olist_l6
	dc.l	olist_l7, olist_l7, olist_l8, olist_l8
