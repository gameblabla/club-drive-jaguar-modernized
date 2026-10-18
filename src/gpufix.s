;
; fix up GPU programs to have the correct addresses
; NOTE: assumes that the GPU program images have been
; copied to RAM
; ALSO NOTE: only movei instructions are fixed up, and
; it is assumed that the GPU programs in question have no
; data, only instructions (if they do have data, they must
; have no data that looks like a "movei #SYMBOL+x,rn"
;
; How it works:
; There are two tables, fixtab and symmap.
; "fixtab" lists the addresses of all our .bin files. The
; do_gpufixups function walks through these, and then
; for each .bin file it searches for movei instructions
; with a magic number (the value SYMBOL plus a small constant)
; When it finds such an instruction, it replaces the magic
; number with the corresponding value in symmap; for example,
; SYMBOL+0 is mapped to the first entry in symmap, SYMBOL+1
; to the second entry, etc.
;
; To use this, just replace the tables below as appropriate,
; and then insert a call to do_gpufixups somewhere early in
; your initialization code. Note that do_gpufixups does assume
; that the .bin files are in RAM: if they are not, you'll
; have to copy them there!!!!

	include	'eq.s'
	include	'externs.s'
SYMBOL		EQU	$543b0700
MAXSYM		EQU	40

	.extern	bgpprog
	.extern	cgpprog
	.extern	tagend
	.extern	racend
	.extern	casend
	.extern	tagbeg
	.extern	racbeg
	.extern	casbeg
	.extern	rgpprog
	.extern	sn
	.extern	sqrtTab
	.extern	car_dat
	.extern	player
	.extern screen_addr
	.extern SKY
	.extern	atanTab
	.extern itCar
	.extern	twoplayer
	.extern	timestamp
	.extern	gametype
	.extern	dash
	.extern	digitfont
	.extern	cmpssfont
	.extern	mapscale
	.extern	maporig
	.extern	speedfont
	.extern	dotloc
	.extern	tnyfont
	.extern	precomp,pcram
	.extern preren,prram
	.extern TPNTADDR,TPNTEND

; table giving the mapping between "special" addresses and
; external symbols for GPU programs

symmap:
	dc.l	bgpram, cgpram, egpram, rgpram, sn, sqrtTab - 512, car_dat, player
	dc.l	screen_addr, SKY, atanTab, itCar, twoplayer, timestamp, gametype
	dc.l	dash,digitfont,cmpssfont,mapscale,maporig,speedfont,scoreinc,dotloc
	; V15 RECOVERY (2026): retail uses TABLES.S showcoord, not a second BSS flag.
	dc.l	dotimg,tnyfont,0,showcoord,pcram,debugflg,prram
	dc.l	animprog,animparam
	dc.l	mbands,gameover,splitscreen,gpu_do,TPNTADDR,TPNTEND,SKYHIGH
	dc.l	fps, playspd
	dc.l	0

;
; fix up the .bin file pointed to by a0, so that any instructions
; like "movei #SYMBOL+x,rn" get turned into "movei #foo, rn",
; where "foo" is the address for symbol x.
; puts the fixed up version of the program into the place
; pointed at by a1 (so we copy from ROM to RAM while fixing up)
;
; uses: registers a0-a2, d0-d2
; returns: nothing

fixupbin::
	lea	symmap,a2
	move.l	(a0)+,(a1)+	; start address for code
	move.l	(a0)+,d2	; total bytes of code (assume > 0)
	move.l	d2,(a1)+
fixloop:
	move.w	(a0)+,d0
	move.w	d0,(a1)+
	subq.l	#2,d2
	lsr.w	#5,d0		; get opcode
	cmpi	#$4c0,d0	; movei instruction?
	bne	endloop
	move.w	(a0)+,d0	; get 32 bit operand (low word is first)
	move.w	d0,(a1)+
	swap	d0
	move.w	(a0)+,d0
	move.w	d0,(a1)+
	swap	d0
	subq.l	#4,d2
	move.l	d0,d1
	andi.l	#$ffffff00,d1
	cmpi.l	#SYMBOL,d1
	bne	endloop
; OK, this is a movei instruction of the right form. Get the right symbol
; from the table and replace it
	and.l	#$ff,d0
	cmp.l	#MAXSYM,d0	; is the symbol in range?
	bgt	endloop		; no, don't replace it (maybe we should report an error??)
	add.l	d0,d0
	add.l	d0,d0		; multiply by 4 (sizeof(symbol))
	move.l	0(a2,d0.l),d0	; get the replacement symbol
	move.w	d0,-4(a1)	; write the low word
	swap	d0
	move.w	d0,-2(a1)	; write the high word
endloop:
	tst.l	d2
	bpl.b	fixloop	; retail uses 8-bit backward branch
	rts

;
; subroutine: fix up all .bin files that we're going to use
; to do this, we need to copy the files from the data segment
; (ROM) to bss
	.globl	do_gpufixups
	.extern	gpprog

do_gpufixups:
	lea	gpprog,a0
	lea	gpram,a1
	bsr.b	fixupbin	; retail relative byte call

	lea	cgpprog,a0
	lea	cgpram,a1
	bsr.b	fixupbin	; 8-bit displacement in retail

	lea	rgpprog,a0
	lea	rgpram,a1
	bsr	fixupbin

	lea	precomp,a0
	lea	pcram,a1
	bsr	fixupbin

	lea	preren,a0
	lea	prram,a1
	bsr	fixupbin

	move.w	gametype,d0
	tst.w	d0
	bne	.10
; tag game
		lea	tagbeg,a0
		lea	bgpram,a1
		bsr	fixupbin
		lea	tagend,a0
		lea	egpram,a1
		bsr	fixupbin
		rts
.10:
	cmp.w	#1,d0
	bne	.20
; race game
		lea	racbeg,a0
		lea	bgpram,a1
		bsr	fixupbin
		lea	racend,a0
		lea	egpram,a1
		bsr	fixupbin
		rts
.20:
; crash and score game
	lea	casbeg,a0
	lea	bgpram,a1
	bsr	fixupbin
	lea	casend,a0
	lea	egpram,a1
	bsr	fixupbin
	rts

	; Original cartridge retains three scheduling/padding NOPs
	; between GPUFIX and PLAYINP. Keep historical section layout.
	nop
	nop
	nop
