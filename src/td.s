; This is the 68K file that goes with 3d.gas


	.include  'eq.s'
	.include  'externs.s'
	.include  "3dds.inc"

	.globl	td
	.globl	replaytd

	.extern	scoreb
	.extern	yourit
	.extern	do_joypad,_use_bnd
	.extern	doneplay

	.extern	startsnd	; in new
	.extern	init_snd
	.extern	eng_on
	.extern	engpitch
	.extern	eng_off
	.extern	do_skid, killSkid

;
; td: code for running 1 frame
; the real work is done by "dotd"; the external interfaces
; (td for normal frames, replaytd for replay frames) mess
; with the playback/record buffer, then call dotd
;

td:
	jsr	do_joypad
	move.l	player,a0
	move.l	4(a0),d0		; get Y position
	cmp.l	SEALEVEL,d0		; is it below (i.e. greater than) sea level?
	blt.b	.above			; if yes, continue
	tst.w	AUTO_REW(a0)		; are we already auto-rewinding?
	bne.b	.above			; yes, don't need to initialize
	move.w	CAMERA_FLAG(a0),AUTO_REW+2(a0)	; otherwise, save the current camera flag
	move.w	#2,CAMERA_FLAG(a0)		; and set camera flag to "external view"
	move.w	#6,AUTO_REW(a0)		; set the auto-rewind flag to rewind until 6 "good" frames are found
.above:
	move.l	CAR_CTRL(a0),d0		; d0 = control bits
	move.w	QTIME(a0),d1		; d1 = player->QTIME
	move.l	timestamp,d2		; d2 = elapsed time since last recording
	sub.l	CAR_TOTFRAME(a0),d2
	move.l	QHEAD(a0),a1		; a1 = head
	move.l	QTAIL(a0),a2		; a2 = tail
	move.l	QSTART(a0),a3		; a3 = start
	move.l	QEND(a0),a4		; a4 = end
	move.l	QPLAY(a0),a5		; a5 = playback
					; a6 is scratch

	tst.w	AUTO_REW(a0)		; is auto rewind happening?
	bne.b	.rewind			; yes == do the rewind
	btst.l	#OPTION,d0		; is the user rewinding??
	beq	record			; if not, go to "record"
.rewind:

; rewind code
; in pseudo-code, this looks like:
; if (playbackhead != tail)
; 	player->QTIME -= elapsed time
; while (player->QTIME < 0 && playbackhead != tail) {
;	head = playbackhead
;	retreat(playbackhead);
; 	player->QTIME += QUANTUM/2;
; }
	cmpa.l	a5,a2			; if playbackhead != tail
	beq	.99
	sub.w	d2,d1
.1:
	tst.w	d1
	bpl	.99
	cmpa.l	a5,a2
	beq	.99
		move.l	a5,a1		; set head = playbackhead
		cmp.l	a5,a3		; playbackhead already at start?
		bne	.20
			move.l	a4,a5	; set playbackhead to end
.20:
		sub.l	#QENTRYSIZ,a5
		move.l	a1,QHEAD(a0)
		move.l	a5,QPLAY(a0)
		add.w	#QUANTUM/2,d1
		bra.b	.1
.99:
	move.w	d1,QTIME(a0)

;
; now actually play back the player's position
; register a5 has the playback position
; register a0 has the player's structure
;
	move.w	#GPU_DO_REWIND,gpu_do
playback:
	moveq.l	#0,d0
	lea	CAR_VELOCITY(a0),a1
	move.l	d0,(a1)+			; zero velocity
	move.l	d0,(a1)+
	move.l	d0,(a1)+

	move.l	d0,(a1)+			; and zero rotation
	move.l	d0,(a1)+
	move.l	d0,(a1)+

	move.l	(a5)+,d0			; get band
	tst.w	AUTO_REW(a0)			; auto-rewind in effect?
	beq.b	.saveit				; no -- go save the band
	btst.l	#31,d0				; is this a "good" position
	beq.b	.saveit				; no -- go save the band
	sub.w	#1,AUTO_REW(a0)			; decrement number of frames needed
	bne.b	.saveit				; and if done...
	move.w	AUTO_REW+2(a0),CAMERA_FLAG(a0)	; ...restore previous camera view
.saveit:
	bclr.l	#31,d0
	tst.l	d0
	beq.b	.05				; if it's null, don't save it
	move.l	d0,NEW_FLOOR(a0)		; store band
.05:
	lea	CAR_POSN(a0),a1
	move.l	(a5)+,(a1)+			; get position
	move.l	(a5)+,(a1)+
	move.l	(a5)+,(a1)+

	lea	CAR_MATRIX(a0),a1		; get the matrix
	move.w	(a5)+,(a1)+
	move.w	(a5)+,(a1)+
	lea	2(a1),a1			; skip last column
	move.w	(a5)+,(a1)+
	move.w	(a5)+,(a1)+
	lea	2(a1),a1			; skip last column
	move.w	(a5)+,(a1)+
	move.w	(a5)+,(a1)+
	lea	2(a1),a1			; skip last column

	moveq.l	#0,d0
	move.w	(a5)+,d0			; get score
	tst.w	gameover			; if the game is over, don't change the player's score!
	bne	donerecord
	move.w	d0,GAME_DATA(a0)
	tst.w	gametype			; tag game?
	bne	.07
	move.l	d0,CAR_TIMER(a0)		; if so, time == score
.07:
	move.w	scoreinc,d1			; get the score increment: hi word in d1, low in d2
	move.w	scoreinc+2,d2
	mulu	d0,d1
	mulu	d0,d2
	swap	d1				; shift hi word left by 16
	move.w	#0,d1
	add.l	d2,d1
	move.l	d1,SCORE(a0)

;
; update the score
;

	bra	donerecord

; recording code
; in pseudo-code, it looks like:
; player->QTIME += elapsed time
; while (player->QTIME >= QUANTUM) {
;	playbackhead = head
;	*head = info
;	advance(head)
;	if (head == tail) advance(tail)
;	player->QTIME -= QUANTUM
; }

record:
	move.w	#GPU_DO_NORMAL,gpu_do
	add.w	d2,d1
.1:
	cmp.w	#QUANTUM,d1
	bmi	.99
		move.l	a1,QPLAY(a0)
		move.l	FLOOR_MODEL(a0),d0
		beq.b	.nowheel		; null models are never good positions
		lea	CAR_SHOCKS(a0),a6
		tst.l	(a6)+			; see if wheels are on ground
		beq.b	.nowheel
		tst.l	(a6)+
		beq.b	.nowheel
		tst.l	(a6)+
		beq.b	.nowheel
		tst.l	(a6)
		beq.b	.nowheel
		bset.l	#31,d0			; set the "good position" flag
		clr.l	CAR_SPIN(a0)
;		move.l	timestamp, CAR_DOWN(a0)
.nowheel:
		move.l	d0,(a1)+		; save band
		move.l	a0,a6
		move.l	(a6)+,(a1)+		; save position
		move.l	(a6)+,(a1)+
		move.l	(a6)+,(a1)+
		move.l	(a6)+,(a1)+		; save first 2 columns x
		lea	2(a6),a6
		move.l	(a6)+,(a1)+		; save first 2 columns y
		lea	2(a6),a6
		move.l	(a6)+,(a1)+		; save first 2 columns z
		move.w	GAME_DATA(a0),(a1)+	; save game data (score can be reconstructed from this)
		cmp.l	a1,a4			; head at end?
		bne	.20
			move.l	a3,a1		; set head to start
.20:
		move.l	a1,QHEAD(a0)
		cmp.l	a1,a2			; head == tail?
		bne	.30
			lea	QENTRYSIZ(a2),a2	; advance tail
			cmp.l	a2,a4			; tail at end?
			bne	.25
				move.l	a3,a2
.25:
			move.l	a2,QTAIL(a0)
.30:
		sub.w	#QUANTUM,d1
		bra.b	.1
.99:
	move.w	d1,QTIME(a0)

donerecord:
;
; fall through to "dotd"
;




dotd: ; do a cycle ---------------------------------------------------------------------

	; test for readiness
	tst.w	SEMAPHORE+8
	beq	donetd
;
; draw the hood, if we're 1 player and have an inside the car view
; (and if we're rendering)
;
	move.w	gpu_do,d0
	btst.l	#0,d0		; are we rendering?
	beq.b	nohood		; no == don't draw any hood, or rewind icon
	tst.w	splitscreen
	bne.b	nohood
		move.l	listAddr,a1
		move.l	32+12(a1),d0		; get second long of second phrase of bitmapped object
		and.l	#$FFFFF000,d0		; zero out X position
		or.w	leftx,d0
		move.l	player,a0
		tst.w	CAMERA_FLAG(a0)
		beq.b	.10			; if CAMERA_FLAG is 0, we want X to be 0
			or.w	#$0400,d0	; otherwise, set X to a ridiculously large value
.10:
		move.l	d0,32+12(a1)
nohood:
	jsr	adjradio

	tst.w	changeIT
	beq	sameIT

	; clear current itHUD
	move.l	#$001f0040,d6			; 64x32
	moveq	#0,d5				; top left corner
	moveq	#0,d7
	move.l	#PITCH1|PIXEL16|WID64|XADDPHR,d0
	move.l	itHUD,a0
	jsr	blit_rect

	move.l	itHUD,d0			; toggle itHUD
	eori.l	#(HUD1^HUD2),d0
	move.l	d0,itHUD

	; set itHUD to say "you're it"
	move.l	#$001f0040,d6			; 64x32
	moveq.l	#$0,d5				; top left corner
	move.l	#yourit,a1				; image data

	move.l	#PITCH1|PIXEL16|WID64|XADDPHR,d0	; destination flags
	move.l	#PITCH1|PIXEL16|WID64|XADDPHR,d1	; source flags
	move.l	itHUD,a0
	jsr	blit_pic
	clr.w	changeIT
sameIT:

	move.l	#PLAYER1,a0		; set car bands up to display properly
	lea	CAR_MODEL(a0),a2	; a2 points at pointer to car model
	lea	CAR_POSN(a0),a0		; a0 points at car position

	move.l	(a2),a1			; a1 points at car model
	lea	XORIG(a1),a1		; set the origin for the car model
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+

	move.l	#PLAYER2,a0		; set car bands up to display properly
	lea	CAR_MODEL(a0),a2	; a2 points at pointer to car model
	lea	CAR_POSN(a0),a0		; a0 points at car position

	move.l	(a2),a1			; a1 points at car model
	lea	XORIG(a1),a1		; set the origin for the car model
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+

; if we're rendering,
; set up the player's correct band
;
	move.w	gpu_do,d0
	btst	#0,d0
	beq	samecamera

	move.l	player,a0
	move.l	CUR_PORTAL(a0),d0	; did he go through a portal?
	beq	noportal
		moveq.l	#0,d1
		move.l	d1,CUR_PORTAL(a0)	; zero portal pointer
		move.l	d0,a1
		move.l	(a1)+,d0			; get new floor model
		move.l	d0,NEW_FLOOR(a0)
		move.l	d0,NEW_CAMERA(a0)
		lea	CAR_POSN(a0),a2
		move.l	(a1)+,(a2)+		; and new position
		move.l	(a1)+,(a2)+
		move.l	(a1)+,(a2)+
		lea	12(a1),a1		; skip to rotation
		move.l	(a1)+,PORTAL_ROT(a0)	; set rotation
		bra	chkfloor
noportal:
	move.l	NEW_FLOOR(a0),d0
chkfloor:
	cmp.l	FLOOR_MODEL(a0),d0
	beq	samefloor
;
; change floor models here	
;
		move.l	FLOOR_MODEL(a0),-(sp)
		move.l	d0,-(sp)
		move.l	d0,FLOOR_MODEL(a0)
		jsr	_use_bnd
		addq.l	#8,sp
		move.l	player,a0
samefloor:
	move.l	NEW_CAMERA(a0),d0
	cmp.l	CAMERA_MODEL(a0),d0
	beq	samecamera
;
; change camera models here
;
		move.l	CAMERA_MODEL(a0),-(sp)
		move.l	d0,-(sp)
		move.l	d0,CAMERA_MODEL(a0)
		jsr	_use_bnd
		addq.l	#8,sp
samecamera:

; do stuck upsidedown check (and optional kick)
	move.l	player,a0						;?
	; first check if car is upsidedown
	btst.b	#7, CAR_MATRIX+8(a0)
	beq		.80
	; check for upward crash force
	move.l	CAR_FORCE+4(a0), d0
	beq		.80
;	; check for time since everything was OK
;	move.l	CAR_DOWN(a0), d0
;	sub.l	timestamp, d0
;	cmp.l	#300, d0	; 1 sec
;	bmi		.80
	; check for SLOW rotation
	move.w	CAR_OMEGA(a0), d0	;just the high word is good enough
	bpl.b	.20
		neg	d0
	.20:
	cmp.w	#8, d0
	bpl		.80
	move.w	CAR_OMEGA+8(a0), d0	;just the high word is good enough
	bpl.b	.40
		neg	d0
	.40:
	cmp.w	#8, d0
	bpl		.80
		; looks like we're stuck - kick it
		clr.w	CAR_SPIN(a0)				; don dampen the spin now
		clr.w	CAR_OMEGA+4(a0)			; control marry-go-round motion
		clr.w	CAR_OMEGA+8(a0)			; control over motion - omega[z]
		; how are we oriented
		cmpi.w	#-11585, CAR_MATRIX+8(a0)
		bpl		.50
			; mostly flat on its back
			move.l	#$ffff0000, CAR_VELOCITY+4(a0)	; upward motion
			move.w	#35, CAR_OMEGA(a0)				; over motion - omega[x]
			bra		.80
		.50: ;else
			; mostly on its side
			move.l	#$ffffc000, CAR_VELOCITY+4(a0)	; upward motion
			move.w	CAR_MATRIX+10(a0), d0			; down[Z]
			; which way should we spin it?
			cmpi.w	#-11585, d0
			bpl		.60
				move.w	#35, CAR_OMEGA(a0)			; omega[x]
				bra		.80
			.60:
			cmpi.w	#11585, d0
			bpl		.62
				move.w	#-35, CAR_OMEGA(a0)			; omega[x]
				bra		.80
			.62:
			; since |down[z]|<11585, |down[x]| must be bigger
			clr.w	CAR_OMEGA(a0)					; omega[x]
			btst.b	#7, CAR_MATRIX+6(a0)			; down[X]
			beq		.64
				move.w	#35, CAR_OMEGA+8(a0)		; omega[z]
				bra.b	.80
			.64: ;else
				move.w	#-35, CAR_OMEGA+8(a0)		; omega[z]
.80:

; do center bar display stuf ------------------------
; (but only if the game isn't over)
	tst.w	gameover
	bne	dogpu

	move.l	player,a0
	move.l	SCORE(a0),d7
	swap	d7			; ignore low bits of score
	lsr.w	#8,d7			; ignore some more low bits...
	move.w	PRV_SCORE(a0), d6
	cmp.w	d6, d7
	blt		backupscore
	beq		samescore
barloop:
		; add another nib to the score bar
		addq	#1, d6
		move.w	d6,d0
		move.w	d6, PRV_SCORE(a0)
		movea.l	SCOREPIX(a0), a1
		movea.l	#scoreb, a4
		add		d0, a4
		add		d0, a1
		asl		#1, d0
		add		d0, a4
		moveq	#7, d1
		move.b	(a4)+, (a1)
		add		#320, a1
		move.b	(a4)+, d0
.20:			move.b	d0, (a1)
			add		#320, a1
			dbra		d1,.20
		move.b	(a4), (a1)

		cmp.w	scoreMax,d6
		blt.b	notovr
			move.l	a0,winner		; keep track of the winner
			move.w	#1,gameover
			move.w	#P1ENGV,d2
			jsr	eng_off
			move.w	#P2ENGV,d2
			jsr	eng_off

			moveq	#WOO_SND,d0	; "woo"
			move.l	#$3fff,d1	; pan
			move.w	#P2SNDV,d2
			jsr	startsnd
			;turn off other sfx - (if any)
			move.l	#-4, tablestart+(taboff*P1SNDV)

			move.w	#GPU_DO_END,gpu_do	; tell the GPU just to draw the score
			bra	dogpu
notovr:
		cmp.w	d6,d7
		bne	barloop
		move.l	player,a0
		move.w	gametype,d0
		cmp.w	#0,d0			; race game or crash and score game?
		bne	doyea
		bra	samescore
backupscore:
	; drop a nib from the score bar
	move.w	d6,d0
	subq	#1,d6
	move.w	d6, PRV_SCORE(a0)
	movea.l	SCOREPIX(a0),a1
	add	d0,a1
	move.b	#251,d2
	moveq	#7,d1
	move.b	d2,(a1)
	add	#320,a1
.20:
		move.b	d2,(a1)
		add	#320,a1
		dbra	d1,.20
	move.b	d2,(a1)
	cmp.w	d6,d7
	bne.b	backupscore

samescore:

;
; generate a new dot in crash and score
;
	move.w	gametype,d0
	cmp.w	#2,d0
	bne	nocas
		bsr	getpwrball
nocas:

	tst.w	gametype		; if tag game
	bne	nosounds

	move.l	itCar, a0		; check for a tag

; play some sounds -----------------------------------
	cmp.l	lastItCar, a0
	beq		nosounds
		move.l	a0, lastItCar
		moveq	#1, d0
		move.w	d0,changeIT
doyea:
		move.w	#P1_YES_SND,d0
		move.l	#$3fff,d1
		move.w	#P1SNDV,d2
		cmp.l	#PLAYER1,a0
		beq	.11
			moveq	#P2_YES_SND, d0
;			moveq	#P2SNDV, d2
.11:
		jsr		startsnd
		tst.w	gametype
		bne	.12
		jsr		it_music					;play the appropriate music for who is it
.12:

nosounds:
	move.l	player, a0
	lea		CUR_SOUND(a0), a1
	move.l	(a1)+, d0
	beq		noCrsh
		move.l	(a1)+,d7	; sound volume
		move.l	(a1),d1		; sound position
		cmp.w	#CRASH_SND,d0	; if this is a crash sound
		bne.b	.05
		cmp.w	#$0040,d7	; and it's relatively quiet
		bmi	zerosnd		; then don't make a noise
.05:
		moveq	#P1SNDV,d2
;		cmp.l	#PLAYER1,a0
;		beq	.11
;			moveq	#P2SNDV,d2
;.11:
		jsr		startsnd

;;		tst.w	d0			; was the sound started?
;;		beq	noCrsh			; no! keep going
zerosnd:
			move.l	player,a0	; yes: mark it as free
			move.l	#0,CUR_SOUND(a0)

noCrsh:
;
; do engine sounds
;
	move.l	player,a0
	lea	CAR_TIRE_SPD(a0),a1		; engine speed is based on velocity
	move.l	(a1)+,d3
	add.l	(a1)+,d3
	add.l	(a1)+,d3
	add.l	(a1)+,d3
	bpl	.11
		neg.l	d3
.11:
	asr.l	#8,d3
	asr.l	#8,d3
	move.l	CAR_GEAR(a0),d4	; engine speed is based on gear
	movea.l	#downShift, a2
	movea.l	#upShift, a3
.21:
	cmp.w	(a2, d4), d3		; check for posible down shift
	bge		.31
		subq.l	#2, d4
		bra.b		.21	; retail 8-bit backward gear-search loop
.31:
	cmp.w	(a3, d4), d3		; check for posible up shift
	ble		.41
		addq.l	#2, d4
		bra.b		.21	; retail 8-bit backward gear-search loop
.41:
	move.l	d4,CAR_GEAR(a0)	; engine speed is based on gear
	movea.l	#gearRatio, a2
	mulu		(a2, d4), d3
;	asr.l	#1,d3	;last minute make sound lower
	move.w	#PLAYER1_ENG_SOUND,d0		; engine sound number
	move.w	#P1ENGV,d2			; voice
	cmp.l	#PLAYER1,a0
	beq	engp0
		move.w	#PLAYER2_ENG_SOUND,d0		; engine sound number
		move.w	#P2ENGV,d2
engp0:
	jsr	engpitch

; do some skids

	move.l	player, a0
	move.w	CAR_SLIDE(a0), d0
	beq.b	.10
		jsr	do_skid
		bra	.20
	.10:
		move.w	CAR_SKD_VCE(a0), d0
		beq	.20
			jsr	killSkid
	.20:
;
; now start up the GPU functions
;
dogpu:
	clr.w	framedone
	move.l	#0, G_FLAGS		; set primary register bank - disable all interupts
	move.l	#G_RAM, G_PC		; GPU Program counter gets $f03000
	move.l	#$0011, G_CTRL		; Set the GPU going

donetd:
	rts
	
;
; replaytd: code for doing 3D frames during the end of game replay
;
replaytd: ; do a cycle ---------------------------------------------------------------------

	move.l	player,a0
	move.w	QTIME(a0),d1		; d1 = player->QTIME
	move.l	timestamp,d2		; d2 = elapsed time since last recording
	sub.l	CAR_TOTFRAME(a0),d2
	move.l	QHEAD(a0),a1		; a1 = head
	move.l	QTAIL(a0),a2		; a2 = tail
	move.l	QSTART(a0),a3		; a3 = start
	move.l	QEND(a0),a4		; a4 = end
	move.l	QPLAY(a0),a5		; a5 = playback
					; a6 is scratch
; replay code
; in pseudo-code, this looks like:
; player->QTIME += elapsed time
; while (player->QTIME > 0) {
;	advance(playbackhead);
;	if (playbackhead == head)
;		playbackhead = tail;
; 	player->QTIME -= playspd; (normally QUANTUM/2)
; }

	add.w	d2,d1
.1:
	tst.w	d1
	bmi	.99
		add.l	#QENTRYSIZ,a5
		cmp.l	a5,a4		; playbackhead at end?
		bne	.20
			move.l	a3,a5	; set playbackhead to start
.20:
		cmp.l	a5,a1		; playbackhead == head?
		bne	.30
			move.l	a2,a5	; set playbackhead to tail
.30:
		move.l	a1,QHEAD(a0)
		move.l	a5,QPLAY(a0)
		sub.w	playspd,d1
		bra.b	.1	; retail 8-bit replay loop branch
.99:
	move.w	d1,QTIME(a0)

donetape:
	move.w	#GPU_DO_REPLAY,gpu_do
	bra	playback

;
; modemtd: do just enough stuff for a remote user
;
modemtd::
	move.w	#GPU_DO_REMOTE,gpu_do
	bra	dotd

;
; initialize a power ball
;
getpwrball::
	lea	PWRBALL,a0
	move.l	timestamp,d0	; find time
	lsr.l	#4,d0		; timestamp is 300ths of a second; each frame is roughly 300/16 seconds long
	divu.w	#9,d0		; we have a total of 9 frames
	swap	d0		; it was the remainder we wanted
	add.w	d0,d0		; multiply by 2 (bytes per word of color table)
	lea	pwrcolor,a1
	move.w	(a1,d0.w),CLUT+253+253
	add.w	d0,d0		; multiply by 2 again (4 bytes per frame)
	move.l	(a0,d0.w),d0	; get frame image ptr
	lea	(a0,d0.l),a0	; add PWRBALL base
	move.l	a0,dotimg
	tst.l	dotloc		; is there already a dot?
	bne	ret
	jsr	random		; pick a random number
	and.l	#$3f0,d0		; make it 0-64, and multiply by 16
	lea	startWorld+STARTDOTS,a0	; here's where the table of values starts
	add.l	d0,a0
	move.l	(a0)+,dotloc	; set up the dot
	move.l	(a0)+,dotloc+4
	move.l	(a0)+,dotloc+8
	move.l	(a0)+,dotloc+12
ret:
	rts

pwrcolor:				; table of 9 colors for sparkle effect
	dc.w	$259b,$48b0,$63c4,$77c8,$7ed1,$a9cf,$f0c0,$ffb0,$7fa0

downShift:
	dc.w	0, $10, $20, $30, $40
upShift:
	dc.w	$20, $33, $46, $59, $7000
gearRatio:
	dc.w	16, 10, 7, 6, 4
	; Historical 68000 module boundary padding uses NOP, not zero fill.
	nop
