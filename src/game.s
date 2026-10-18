	.include	'eq.s'
	.include	'externs.s'

	.extern	SHUTDOWN

	.text
	move.l	#stacktop,a7			;init stack
	move.l	#4,olist_stp+4			;set up stop object list
	move.l	#0,olist_stp
	move.l	#olist_stp,listAddr
	move.w	#0,listgood
	bsr		initonce
	bsr		initstuff
	bsr		init_snd	
	bra	always
start::							;this is the restart address
.if 0
	move.l	#SHUTDOWN,d0			;shut down the DSP (Leonard's magic code)
	and.l	#$ffff,d0
	or.l	#$981d0000,d0
	move.l	d0,$f1b010
.else
	bsr	voicesoff
.endif

	move.l	#stacktop,a7			;init stack
	bsr		initstuff				;initialize everything

always:
	move.w	#0,listgood
	move.w	#0,steeropt			;always joypad steering

.if 0
;*** modem test code
	tst.w	modem
	beq.b	.10
	jsr	_MDMhangup
.10:
.endif

;;;	bsr		init_snd				;load DSP code, start it running
;;;	move.l	#Frame,$100			;why should we need this??? we shouldn't, but a bug somewhere makes $100 bad sometimes!
	bsr		gotitle				;go to title screen

mainloop::
	move.w	gamemode,d0			;get current game mode
	lsl.w	#2,d0				;4 bytes per game mode
	lea		looptable,a0			;list of loop addresses
	move.l	(a0,d0.w),a1
	jsr		(a1)					;do one of the loops
	bsr		adjradio				;adjust the changing radio station sound if necessary
	bsr		random				;change the seed values
	bsr		wait_int				;wait for vertical interrupt before continuing
	bra.b	mainloop


clearscr::						;cover screen with black, wait until it is displayed
	lea		scrcover,a1			;address of first object header
	moveq	#1,d6				;total objects in list
	lea		olist_ram,a2
	bsr		build				;build packed object list
	move.l	#olist_ram,listAddr
	move.w	#1,listgood
	bsr		wait_int
	rts

adjblak::
	move.l	#ADJBLACK_PRG,G_PC		;set program counter
	move.l	#$00000011,G_CTRL		;start GPU
.10:	cmp.l	#1,ADJBLACK_DONE		;wait until finished
	bne.b	.10
	rts

do_mask::
;A0 = address of table with mask info
;D0 = number of masks
;uncomp GPU code must be in GPU ram
	subq.w	#1,d0					;subtract 1 for loop counter
	move.l	#$00010000,d3				;set Y step to 1
.10:
	move.l	B_CMD,d7
	btst.l	#0,d7
	beq.b	.10						;wait until blitter is finished
	move.l	(a0)+,A1_BASE				;destination address
	move.l	(a0)+,d1					;blitter width
	move.l	d1,d2
	or.l		#(PITCH1|PIXEL16|XADDPIX),d1
	move.l	d1,A1_FLAGS				;destination
	or.l		#(PITCH1|PIXEL1|XADDPIX),d2
	move.l	d2,A2_FLAGS				;source
	move.l	(a0)+,d2
	move.l	d2,B_COUNT				;height, width of source data
	move.w	d2,d3					;combine width with Y step
	neg.w	d3						;make width negative
	move.l	d3,A1_STEP				;1 in Y step size, negative width in X step size
	move.l	d3,A2_STEP				;1 in Y step size, negative width in X step size
	move.l	(a0)+,UNCOMP_START
	move.l	(a0)+,d1					;size of mask / 8
	add.l	#maskram,d1
	move.l	d1,UNCOMP_END				;stop uncomp at this address

;A1_BASE		destination address
;A1_FLAGS		pitch,pixel,wid,xadd for destination
;A2_FLAGS		pitch,pixel,wid,xadd for source
;B_COUNT		height, width of source data
;A1_STEP		1, negative width
;A2_STEP		1, negative width

	move.l	#maskram,UNCOMP_DEST
	move.l	#UNCOMP_PRG,G_PC		;set program counter
	move.l	#$00000011,G_CTRL		;start GPU
.30:	cmp.l	#1,UNCOMP_DONE			;wait until uncomp is finished
	bne.b	.30

	move.l	#maskram,A2_BASE		;source address
	moveq	#0,d1
	move.l	d1,B_PATD				;low word is color to write if bit is set in source data
	move.l	d1,A2_PIXEL			;start at 0,0 of source data
	move.l	d1,A1_PIXEL			;X,Y position to write data in destination area
	move.l	#UPDA1|UPDA2|SRCEN|BCOMPEN|PATDSEL|LFU_A|LFU_AN,B_CMD
	dbra		d0,.10
	rts


dodecomp::
;A0 = address of table with info for decompression
;D0 = number of items to decompress
	subq.w	#1,d0				;subtract 1 for loop counter
.10:	move.l	(a0)+,In_Adr			;address of compressed data
	move.l	(a0)+,Out_Adr			;set destination address
	move.l	(a0)+,Out_Width		;number of 8 pixel blocks in destination area
	move.l	(a0)+,Out_E_Width		;setting for blitter

	move.l	#G_RAM,G_PC			;set program counter
	move.l	#$00000011,G_CTRL		;start GPU
.20:	cmp.l	#dj_done,All_Done		;wait until decompression is finished
	bne.b	.20
	dbra		d0,.10
	rts


do_cross::
;D0 = destination
;D1 = source pic 1
;D2 = end of pic 1
;D3 = source pic 2
	move.l	d0,CROSS_DEST
	move.l	d1,CROSS_PIC1
	move.l	d2,CROSS_PIC1_END
	move.l	d3,CROSS_PIC2
	move.l	crosscnt,CROSS_CNT
	move.l	#CROSS_PRG,G_PC					;set program counter
	move.l	#$00000011,G_CTRL					;start GPU
.30:	cmp.l	#1,CROSS_DONE						;wait until fade is finished
	bne.b	.30
	rts

do_fade::
;D0 = destination
;D1 = source pic
	move.l	d0,FADE_DEST
	move.l	d1,FADE_START
	add.l	#(448*288*2),d1
	move.l	d1,FADE_END
	move.l	bright,BRIGHTNESS
	move.l	#FADE_PRG,G_PC						;set program counter
	move.l	#$00000011,G_CTRL					;start GPU
.30:	cmp.l	#1,FADE_DONE						;wait until fade is finished
	bne.b	.30
	rts


; GPU stop object

stops:
	dc.l	0,4
