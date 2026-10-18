	.include	'eq.s'
	.include	'externs.s'
	.include	'3dds.inc'

;ROM_12W	equ	ROM_SINE12W

NEW_ENG	equ	0			; use new engine patch?
NEW_SKID equ	0			; use new skid patch?

	.text

;each voice is 20 longs
; 0						28 for 8 bit sample, 12 for 16 bit sample, 32 for 16 bit compressed sample
; 1	volume				low 0,	high $7FFF
; 2	data address
; 3	pitch				set to 0 to pause sample
; 4	length of sample data
; 5
; 6
; 8
; 9
;10
;11
;12
;13
;14
;15
;16
;17
;18
;19	pan					full left $7FFF	middle $3FFF	full right 0


bestFX:	; find the best voice number in the sfxVoice list to use for a sound
	; best = first unused voice | lowest non-zero priority
	; best voice number is returned in r2
	movea.l	#sfxVoice, a0
	lea		snd_hdr_tbl,a1
	lea		cur_voice_snd,a5
	move.w	#TOTAL_SOUNDS, d3		;priority to beat
	move.w	#SKID_SND, d5			;a special case priority kludge
.10:
	move.w	(a0)+, d4				;read the next possible voice num from the voice list
	beq		.30					;all done (searched the whole list)
		move.l	(a1,d4.w),a2		;a2 is now the [tablestart + (n * taboff)]

		move.l	(a2),d6			; check for voice on
		bmi.b	.20

		move.l	(a5,d4.w),d6		; what sound is currently being played?
		beq.b	.10				; if it's sound 0, don't interrupt it
		cmp.w	d5, d6			; is it a skid
		bne.b	.15
			clr	d6				; skids are lowest priority
		.15:
		cmp.w	d3, d6
		bpl.b	.10
		move		d6, d3			; best so far
		move		d4, d2
		bra.b		.10			; retail short loop
.20:	;unused voice
	move		d4, d2
	neg		d3
.30:
	lsr.w	#2, d2
	rts
sfxVoice:
	dc.w	P1SNDV*4, P2SNDV*4, 0 ;don't think the synth can handle it - P2ENGV*4, 0

startsnd::
;d0 - pass in sound index
;d1 - pass in xpos of sound or $00003FFF to use middle pan value
;d2 - voice number to use
;d7 - volume to use
	; use an available sfx voice? - If voice number is P1SNDV, a voice will be picked according to priority from the sfxVoice list
	cmpi.w	#P1SNDV, d2
	bne.b	.10
		jsr	bestFX
.10:
	cmp.b	#FIRST_FM,d0
	bcc		startfm				;all sounds > FIRST_FM can be any type except samples
startsmp::
;D0 = sound number
;D1 = sound xpos for pan value
;D2 = voice number to use
;d7 - volume to use (only used by crash sound)
	lea		snd_addr,a0
	lsl.w	#2,d0				;sample number * 4 bytes per address
	move.l	(a0,d0.w),a0			;get address of sample

	lea		snd_hdr_tbl,a1
	move		d2,d3				;save it for killing skids
	lsl.w	#2,d2				;voice number * 4
	move.l	(a1,d2.w),a1			;a1 is now the [tablestart + (n * taboff)]

	lea	cur_voice_snd,a5
	tst.l	(a1)					; check for voice on
	bmi.b	smpoff
		tst.w	d0				; sound 0 should always be played
		beq.b	smpoff
		move.l	(a5,d2.w),d6		; what sound is currently being played?
		beq.b	.10				; if it's sound 0, don't interrupt it
		cmp.w	#SKID_SND, d6		; skid sound priority kludge
		bne.b	.50
			moveq	#0, d6
			cmp.w	PLAYER1+CAR_SKD_VCE, d3	; turn off skid
			bne.b	.70
				move.w	#0, PLAYER1+CAR_SKD_VCE
			.70:
			cmp.w	PLAYER2+CAR_SKD_VCE, d3	; turn off skid
			bne.b	.50
				move.w	#0, PLAYER2+CAR_SKD_VCE
		.50:
		lsl.w	#2,d6			;match d0 (previosly shifted (long index (up above)))
		cmp.w	d0,d6
		bmi.b	smpoff			; lower priority: go turn it off
.10:
		moveq	#0,d0			; return failure
		rts
smpoff:
	move.l	#-4,(a1)				;turn off voice
	move.l	d0,d3				;get sound number * 4
	lsr.l	#2,d3				;change it to sound number
	move.l	d3,(a5,d2.w)			;save the sound number that is going to played in cur_voice_snd (d2 is voice number * 4)

	cmp.w	#CRASH_SND,d3
	bne.b	.10					;crash sound volume is in D7 already
	mulu		snd_vol,d7			;* current volume level
	lsr.l	#7,d7				;divide by max volume
	bra.b	.20
.10:	lea		soundvol,a2
	move.l	(a2,d0.w),d7
.20:
	move.l	d7,(1*4,a1)			;volume, offset 1 long

	move.l	a0,(2*4,a1)			;sample address,  offset 2 long 

	lea		samprate,a2
	move.l	(a2,d0.w),(3*4,a1)		;pitch, offset 3 long

	lea		samplen,a2
	move.l	(a2,d0.w),d3			;get sample length (if sample is 16 bit, this needs to be divided by 2)
	lsl.l	#8,d3				;convert to 23.8 format
	move.l	d3,(4*4,a1)			;length, offset 4 long

	moveq	#0,d3
	move.l	d3,(5*4,a1)			;Length (WTFC) not looping, offset 5 long
	move.l	d3,(6*4,a1)			;reset to 0, offset 6 long

	bsr		set_pan
	move.l	#32,(a1)				; start compressed 16 bit sample

;	moveq	#1,d0				; return success
.90:	rts


startfm::
;D0 = sound number
;D1 = sound xpos for pan value
;D2 = voice number to use
	lea		snd_addr,a0
	move.w	d0,d3				;to put in cur_voice_snd
	lsl.w	#2,d0				;sound number * 4 bytes per address
	move.l	(a0,d0.w),a0			;get address of sound info

	lea		cur_voice_snd,a1
	lsl.w	#2,d2				;voice number * 4
	move.l	d3,(a1,d2.w)

	lea		snd_hdr_tbl,a1
	move.l	(a1,d2.w),a1			;a1 is now the [tablestart + (n * taboff)]

	move.l	#-4,(a1)				;turn off voice before changing voice paramaters
	move.l	(4,a0),(1*4,a1)
	move.l	(8,a0),(2*4,a1)
	move.l	(12,a0),(3*4,a1)
	move.l	(16,a0),(4*4,a1)
	move.l	(20,a0),(5*4,a1)
	move.l	(24,a0),(6*4,a1)
	move.l	(28,a0),(7*4,a1)
	move.l	(32,a0),(8*4,a1)
	move.l	(36,a0),(9*4,a1)
	move.l	(40,a0),(10*4,a1)
	move.l	(44,a0),(11*4,a1)
	move.l	(48,a0),(12*4,a1)
	move.l	(52,a0),(13*4,a1)
	move.l	(56,a0),(14*4,a1)
	move.l	(60,a0),(15*4,a1)
	move.l	(64,a0),(16*4,a1)
	move.l	(68,a0),(17*4,a1)
	move.l	(72,a0),(18*4,a1)
;	move.l	(76,a0),(19*4,a1)
	bsr		set_pan
	move.l	(a0),(a1)				;start sound with sound type
.90:	rts

set_pan::
;A1 = address of voice table
;D1 = sound xpos for pan value
	move.w	#SCRN_RIGHT,d3
	cmp.l	#$00003FFF,d1			;check sound xpos that was passed in
	beq.b	.30
	cmp.w	d3,d1				;compare right of screen to sound xpos
	blt.b	.10
	moveq	#2,d1				;use full right if off right side of screen
	bra.b	.30
.10:	tst.w	d1
	bpl.b	.20
	move.l	#$00007FFE,d1			;use full left if off left side of screen
	bra.b	.30
.20:	sub.w	d1,d3				;now have distance from right side
	mulu		#$49,d3				;pan per pixel * number of pixels ($7FFF / maximum xpos) = number from 0-$7FC0
	and.l	#$0000FFFF,d3			;make sure high word is 0
	add.l	#$0000003E,d3			;move sound a little left
	move.l	d3,d1
.30:	move.l	d1,(19*4,a1)			;set pan value
	rts



;-------------------------------------------------
; skid sounds
; a0 - player struct address
do_skid::
	; first check for a voice
	move.w	CAR_SKD_VCE(a0), d2
	bne		.50
		jsr		bestFX
		btst		#15, d3		; if d3 < 0 then voice d2 is not used
		bne		.20
			rts
		.20:
		move.l	player, a0
		move.w	d2, CAR_SKD_VCE(a0)
		move.w	#SKID_SND, d0
		jsr		startfm
		move.w	#SKID_SND*4,d7			;get engine type (which is the sound number)
		lea		soundvol,a2
		move.l	(a2,d7.w),d7			;get volume adjusted by snd_vol
		move.l	d7,(6*4,a1)			;set engine volume
.50:	; change the pitch
	rts

killSkid::
	move.w	CAR_SKD_VCE(a0), d2
	asl.w	#2, d2
	lea		snd_hdr_tbl,a1
	move.l	(a1,d2.w),a1			;a1 is now the [tablestart + (n * taboff)]
	move.l	#-4,(a1)				;turn off voice
	clr		CAR_SKD_VCE(a0)
	rts
;-------------------------------------------------
; eng_on: turn on an engine sound
; parameters: d0: engine sound number
;             d1: sound xpos (not used)
;	      d2: voice (use either 6 or 7)
;	      d3: engine speed
eng_on::
	bsr		eng_off				;turn off existing engine sound if there is one
	tst.w	engoffopt				;check for engines being off
	bne	.ret					; if they're off, don't do anything else
	move.l	#$3FFF,d1				;sound xpos
	movem.w	d0-d3,-(sp)
	bsr		startfm
	movem.w	(sp)+,d0-d3
	move.w	d0,d7				;get engine type (which is the sound number)
	lsl.w	#2,d7				;* 4 for table offset
	lea		soundvol,a2
	move.l	(a2,d7.w),d7			;get volume adjusted by snd_vol
	move.l	d7,(6*4,a1)			;set engine volume
	bsr		e_pitch				;adjust pitch depending on engine speed
.ret:
	rts

eng_off::
;turn off last voices which are used by the engine sound
	lea		tablestart+(taboff*(MAX_VOICES-2)),a0
	cmp.w	#MAX_VOICES-1,d2
	bne	.10
		lea	taboff(a0),a0
.10:
	move.l	#-4,(a0)				;turn off voice
	rts

;
; engpitch: change an engine sound
;
; parameters: d0: engine sound number
;	      d2: voice (use either 6 or 7)
;	      d3: engine speed
engpitch::
	move.w	d2,d7
	add.w	d7,d7
	add.w	d7,d7
	lea		snd_hdr_tbl,a1
	move.l	(a1,d7.w),a1
	move.l	(a1),d7				; check for voice on
	bmi.b		eng_on				;if engine is off, turn it on
e_pitch:
	tst.w	d0
	bmi.b	.90					;engine off if $FFFF
	lea		tablestart+(taboff*(MAX_VOICES-2)),a0
	cmp.w	#MAX_VOICES-1,d2
	bne		.10
	lea		taboff(a0),a0
.10:
	sub.w	#FIRST_ENGINE,d0
	lsl.w	#3,d0				;engine type * 8

	lea		egmnmx,a1
	bsr		setengd1
	move.l	d1,(4*4,a0)
	lea		egmnmx1,a1
	bsr		setengd1
	move.l	d1,(8*4,a0)
	lea		egmnmx2,a1
	bsr		setengd1
	move.l	d1,(13*4,a0)
	lea		egmnmx3,a1
	bsr		setengd1
	move.l	d1,(16*4,a0)
.90:	rts
setengd1::
;A0 = tablestart
;A1 = engmnmx table
;D0 = engtype * 8
;D3 = engine speed
	move.l	4(a1,d0.w),d1			;maximum pitch
	sub.l	(a1,d0.w),d1			;subtract minimum pitch
	beq.b	.99
	divs		#MAX_SPEED,d1			;range / possible steps
	muls		d3,d1				;current speed * pitch per step
	add.l	(a1,d0.w),d1			;add minimum to (speed * step)
.99:
	rts

egmnmx::
;minimum, maximum pitch for each engine sound	5th long
.if NEW_ENG
	dc.l		$ae00,  $1cf00
.else
	dc.l		$2200,  $1cf00
.endif
	dc.l		$2200,	$24800
	dc.l		$3000,	$1c000
	dc.l		$2e00,	$20000
	dc.l		$3d00,	$1c000
	dc.l		$2200,	$1b000
;;	dc.l		$4d00,	$18000
egmnmx1::
;minimum, maximum values for each engine sound	9th long
.if NEW_ENG
	dc.l		$20a00,$56d00
.else
	dc.l		$272e,$21589
.endif
	dc.l		$272e,	$2a0f8
	dc.l		$2c24,	$2c24
	dc.l		$c4,		$c4
	dc.l		$12b67,	$12b67
	dc.l		$27c2,	$27c2
	dc.l		$4d,		$186
egmnmx2::
;minimum, maximum values for each engine sound	14th long
.if NEW_ENG
	dc.l		$6a33, $11a97
.else
	dc.l		$aa00,	$7686
.endif
	dc.l		$aa00,	$6800
	dc.l		$10000,	$10000
	dc.l		$1026,	$b68f
	dc.l		$4737,	$21c8b
	dc.l		$27b1,	$1fe30
	dc.l		$a13,	$3309
egmnmx3::
;minimum, maximum values for each engine sound	17th long
.if NEW_ENG
	dc.l		$4f9b,$d3d4
.else
	dc.l		0,0
.endif
	dc.l		$0,		$0
	dc.l		$1800,	$39e00
	dc.l		$20fa,	$207bf
	dc.l		$852b,	$3f2c7
	dc.l		$4a39,	$3a5
	dc.l		$c8,		$4c8


it_music::
   	clr.l	d7
	cmp.l	#PLAYER2,lastItCar
	beq.b	.10
	move.w	tagtune0,d7
	bra.b	.20
.10:	move.w	tagtune1,d7
.20:	cmp.w	#TOTAL_SONGS,tagtune0		;if tagtune is TOTAL_SONGS, that means none
	bne.b	.50						;if either tag tune is set to 'none', do nothing
	cmp.w	#TOTAL_SONGS,tagtune1
	bne.b	.50
	rts
.50:	move.l	d7,songnum				;fall through to playmus
playmus::
;songnum = number of score to play
	movem.l	d0-d2/a0-a3,-(sp)

	bsr		mus_off				;turn off first 4 voices

	lea		mus_info,a3
	move.l	songnum,d7
	lsl.w	#4,d7				;16 bytes in mus_info table for each piece of music
	add.l	d7,a3
	move.l	(a3)+,a0				;get score address
	move.l	(a3)+,a1				;address of patches
	move.l	(a3)+,a2				;end of patches
	move.l	(a3)+,d1				;JPIT2

	lea		musicst,a3
.20:	move.l	(a0)+,d2
	move.l	d2,(a3)+
	cmp.l	#$7FFFFFFF,d2			;$7FFFFFFF is the end of the score
	bne.b	.20
	lea		patchst,a3			;ram address
.50:	move.l	(a1)+,(a3)+
	cmpa.l	a1,a2				;A2 = end of patches
	bne.b	.50

	move.l	#musicst,SCORE_ADD
	move.l	#patchst,PATCHLOC
	move.l	#0,TIMER_ADD
	bsr		set_mvol
	move.l	#D_RAM+$30,D_PC		;Set up D_PC
	move.l	#$15,SMODE
	move.l	#19,SCLK				;assume 19 for SCLK
	cmp.w	#CONGA_MUSIC*16,d7
	bne.b	.60
	move.l	#26,SCLK
.60:
	move.w	d1,jpit2val
	move.l	#$1,D_CTRL			;start DSP
	cmp.b	#1,muteflag
	beq.b	.99
	move.w	d1,$F10002			;JPIT2
	move.w	#$114,$F10000			;JPIT1
.99:
	movem.l	(sp)+,d0-d2/a0-a3
	rts

	.extern	congams,honky,sfjazz,tech,rapmus,reggae,clubwave
mus_info::
;address of score, address of patches, end address of patches, JPIT2
	dc.l		congams,	p0,	pe,		$56			;conga
	dc.l		honky,	tm0,	tme,		$2E			;western
	dc.l		sfjazz,	jm0,	jmend,	$60			;jazz
	dc.l		tech,	xm0,	xmend,	$50			;techno
	dc.l		rapmus,	rm0,	rmend,	$60			;gangster rap
	dc.l		reggae,	rg0,	rgend,	$48			;reggae
	dc.l		clubwave,	cw0,	cwend,	$35			;club wave

ck_radio::
	move.l	joybothe,d1
	btst.l	#KEY_0, d1
	bne		mute
	cmp.b	#1,muteflag
	beq		.90						;don't allow changing song if muted
	btst.l	#KEY_STAR, d1				;check edge
	beq.b	.20
	cmp.l	#1,songnum				;first song number (can't select conga music)
	bne.b	.15
	move.l	#TOTAL_SONGS-1,songnum
	bra.b	.40
.15:	sub.l	#1,songnum
	bra.b	.40
.20:
	btst.l	#KEY_HASH, d1				;check edge
	beq.b	.90
	add.l	#1,songnum
	cmp.l	#TOTAL_SONGS,songnum
	bne.b	.40
	move.l	#1,songnum				;go to first song number
.40:
	jsr	mute							; toggle sound off
	move.b	#RADIO_STEPS,radiocnt		;init counter for length of radio change sound
	cmp.w	#PLAY_MODE,gamemode
	bne.b	.10
		lsr.b	radiocnt				;use half as many steps during game so sound doesn't last too long
.10:
	moveq	#RADIO_SND,d0				;sound number
	move.l	#$3FFF,d1					;sound xpos
	moveq	#5,d2					;voice number
	bsr		startsnd
	move.l	soundvol+(RADIO_SND*4),(6*4,a1)	;set radio sound volume (A1 = address of voice table)
.90:
	rts

adjradio::
	lea		tablestart+(taboff*5),a0	;radio sound uses 6th voice
	tst.b	radiocnt
	beq.b	.90					;just exit
	sub.b	#1,radiocnt
	bne.b	.30
	move.l	#-4,(0*4,a0)			;if radio sound is done, turn off the sound
	jsr	mute
	bra		playmus
.30:
	move.l	(4*4,a0),d3			;get current pitch
	sub.l	#(($9b800-$100)/(RADIO_STEPS/2)),d3	;do double
	cmp.w	#PLAY_MODE,gamemode
	beq.b	.50
	add.l	#(($9b800-$100)/RADIO_STEPS),d3	;mon back
.50:
	move.l	d3,(4*4,a0)			;save new pitch
.90:	rts


init_snd::
;	move.l	#$00070007,D_END		;Set GOOD mode
	moveq	#0,d0
	move.l	d0,D_CTRL				;Turn DSP off
	nop
	move.l	d0,D_FLAGS			;Set known state
	move.w	d0,$F10000			;JPIT1
	move.w	d0,$F10002			;JPIT2

	move.l	#$7fff,VOLUME			;full volume

; First we copy the Jerry code into Jerry
; The label GPUSTART will be created by LTXCONV/ALN at the start of the block
; The code gets loaded into the DSP at DSPORG
	.extern	FULSYN_S, FULSYN_E
	move.l	#DSPORG,a1
	move.l	#FULSYN_S,a0
	move.l	a0,d0
	move.l	#FULSYN_E,d1
	sub.l	d0,d1
	lsr.l	#2,d1
.10:	move.l	(a0)+,(a1)+
	dbra		d1,.10

	bsr		voicesoff				;initialize all of the voice tables

	lea		envstart,a0			;load the envelopes into DSP ram
	move.l	#ENV_ADDR,a1
.18:	move.l	(a0)+,(a1)+
	cmpa.l	#envend,a0
	bne.b	.18

	move.l	#0,SCLK
	move.l	#$15,SMODE
	move.l	#$13,SCLK

	move.l	#D_RAM,D_PC			;Set up D_PC
	move.l	#1,D_CTRL				;turn on DSP
	rts

set_svol::
	lea		svollist,a0						;maximum volumes
	lea		soundvol,a1						;adjusted volumes
	lea		svolmin,a2						;minimum volumes for each sound
	move.w	snd_vol,d0						;get current sound volume level
	moveq	#TOTAL_SOUNDS-1,d7
.10:	move.l	(a0)+,d1							;get max volume
	mulu		d0,d1							;max volume * current volume level
	lsr.l	#7,d1							;divide by max volume level ($80)
	add.l	(a2)+,d1							;add minimum volume
.15:
	move.l	d1,(a1)+							;save adjusted volume level
	dbra		d7,.10
	rts

set_mvol::
	clr.l	d0
	move.w	mus_vol,d0
	asl.w	#8,d0				;convert 0 - $7F to 0 - $7FFF
	move.l	d0,VOLUME
	rts

dsp_off::
	moveq	#0,d0
	move.w	d0,$F10000			;JPIT1
	move.w	d0,$F10002			;JPIT2
	move.l	d0,SMODE
	move.l	d0,D_CTRL				;Turn DSP off
	rts

mute::
	eor.b	#1,muteflag
	cmp.b	#0,muteflag
	beq.b	.20
	cmp.l	#CONGA_MUSIC,songnum	;this music uses more than 4 voices
	bne.b	mus_off				;if not conga music, just turn off 4 voices
	move.w	#0,$F10000			;JPIT1
	move.w	#0,$F10002			;JPIT2
	bra.b	voicesoff
.20:
	move.w	jpit2val,$F10002		;JPIT2
	move.w	#$114,$F10000			;JPIT1
	rts

mus_off::
;turn off the first 4 voices
	move.w	#0,$F10000			;JPIT1
	move.w	#0,$F10002			;JPIT2
	lea		tablestart,a0
	moveq	#-4,d0
	move.l	d0,(taboff*0,a0)		;turn off first 4 voices only
	move.l	d0,(taboff*1,a0)
	move.l	d0,(taboff*2,a0)
	move.l	d0,(taboff*3,a0)
	rts

voicesoff::
;turn off all of the voices
	lea		tablestart,a0			;first voice table
	moveq	#MAX_VOICES-1,d0
.10:	move.l	#-4,(a0)				;turn off voice
;	adda.l	#taboff,a0			;go to next voice
	lea	taboff(a0),a0			; go to next voice
	dbra		d0,.10
	move.l	#0,(a0)				;put a 0 (stop) at at last voice + 1
	rts

sndtime::
;the time units required to play each type of sound
;check TIMELEFT in DSP ram to get number of time units available
;if there is not enough time available, don't play the sound yet
;		TIME UNITS REQUIRED		VALUE AT START OF EACH VOICE TABLE
;	dc.l		0				;0	end of active voices
;	dc.l		23				;4	FM/Env
;	dc.l		15				;8	Simple FM
;	dc.l		19				;12	16 bit sampler
;	dc.l		24				;16	Complex FM
;	dc.l		18				;20	2^n wavetable
;	dc.l		19				;24	Waveform/Envelope
;	dc.l		19				;28	8 bit sampler


;SOUNDS
snd_addr::					;addresses of sound data for fm sounds and samples
	dc.l		winsnd			; first 3 sounds should always be the same
	dc.l		crashsnd
	dc.l		flushsnd
	dc.l		pianosnd
	dc.l		meowsnd
	dc.l		mousesnd
	dc.l		doorsnd
	dc.l		ouchsnd
	dc.l		p1yea
	dc.l		p2yea
	dc.l		eng00
	dc.l		eng01
	dc.l		eng02
	dc.l		eng03
	dc.l		eng04
	dc.l		eng05
	dc.l		radiosnd
	dc.l		skid_snd

samprate::
	dc.l		200				;win
	dc.l		150				;crash
	dc.l		200				;flush
	dc.l		200				;piano
	dc.l		300				;meow
	dc.l		200				;mouse
	dc.l		200				;door
	dc.l		170				;ouch
	dc.l		200				;p1yea
	dc.l		200				;p2yea
samplen::
	dc.l		18774/2			;win
	dc.l		42510/2			;crash
	dc.l		56011			;flush
	dc.l		8370				;piano
	dc.l		22409			;meow
	dc.l		2142				;mouse
	dc.l		24254			;door
	dc.l		20941			;ouch
	dc.l		26966/2			;p1yea
	dc.l		15344/2			;p2yea
svollist::
;maximum volumes for each sound
;adjusted by value in snd_vol, then copied to soundvol table
	dc.l		$6000			;win
	dc.l		$0				;crash (special case)
	dc.l		$7fff			;flush
	dc.l		$7000			;piano
	dc.l		$7800			;meow
	dc.l		$5000			;mouse
	dc.l		$4000			;door
	dc.l		$7800			;ouch
	dc.l		$7f00			;p1yea		; was $6000
	dc.l		$6000			;p2yea
	dc.l		$2400			;eng00		; was 3000
	dc.l		$3000			;eng01
	dc.l		$3000			;eng02
	dc.l		$3000			;eng03
	dc.l		$3000			;eng04
	dc.l		$3000			;eng05
	dc.l		$2400			;radio
.if NEW_SKID
	dc.l		$6000
.else
	dc.l		$c00			;skid		; was $6000
.endif
svolmin::
;minimum volumes for each sound
	dc.l		$0				;win
	dc.l		$0				;crash (special case)
	dc.l		$0				;flush
	dc.l		$0				;piano
	dc.l		$0				;meow
	dc.l		$0				;mouse
	dc.l		$0				;door
	dc.l		$0				;ouch
	dc.l		$0				;p1yea
	dc.l		$0				;p2yea
	dc.l		$0				;eng00	; was 600
	dc.l		$400				;eng01
	dc.l		$400				;eng02
	dc.l		$400				;eng03
	dc.l		$400				;eng04
	dc.l		$400				;eng05
	dc.l		$0				;radio
	dc.l		$0				;skid

.if NEW_ENG
eng00::
	.dc.l	$00000010
	.dc.l	ROM_SINE
	.dc.l	ROM_NOISE
	.dc.l	$00000000
	.dc.l	$0000AE00
	.dc.l	$00000000
	.dc.l	$00000100
	.dc.l	$00000000
	.dc.l	$80000300
	.dc.l	$00000200
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$8000009C
	.dc.l	$00000300
	.dc.l	$00000000
	.dc.l	$80000075
	.dc.l	$00000200
	.dc.l	ROM_AMSINE
	.dc.l	$00003FFF
.else
eng00::
	dc.l	$00000010		;complex FM
	dc.l	ROM_AMSINE	;carrier
	dc.l	ROM_TRI		;mod
	dc.l	$00000000
	dc.l	$0000003D		;$2200 - $24800
	dc.l	$00000000
	dc.l	$00000380
	dc.l	$00000000
	dc.l	$0000272e		;$272e - $2a0f8
	dc.l	$0000009B
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$0000aa00		;$aa00 - $6800
	dc.l	$000002FF
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	ROM_12W
	dc.l	$00003FFF		;pan
.endif

eng01:
	dc.l	$00000010		;complex FM
	dc.l	ROM_AMSINE	;carrier
	dc.l	ROM_TRI		;mod
	dc.l	$00000000
	dc.l	$0000003D		;$2200 - $24800
	dc.l	$00000000
	dc.l	$00000380
	dc.l	$00000000
	dc.l	$0000272e		;$272e - $2a0f8
	dc.l	$0000009B
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$0000aa00		;$aa00 - $6800
	dc.l	$000002FF
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	ROM_12W
	dc.l	$00003FFF		;pan
eng02::
	dc.l	$00000010		;complex FM
	dc.l	ROM_CHIRP16	;carrier
	dc.l	ROM_12W		;mod
	dc.l	$00000000
	dc.l	$00003000		;$3000 - $1c000
	dc.l	$00000000
;	dc.l	$00006000		;volume
	dc.l	$00000380
	dc.l	$00000000
	dc.l	$00002C24
	dc.l	$00000064
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00010000
	dc.l	$00000100
	dc.l	$00000000
	dc.l	$00001800		;$1800 - $39e00
	dc.l	$00001000
	dc.l	ROM_NTRI
	dc.l	$00003FFF		;pan
eng03::
	dc.l	$00000010		;complex FM
	dc.l	ROM_DELTA		;carrier
	dc.l	ROM_NTRI		;mod
	dc.l	$00000000
	dc.l	$00002e00		;$2e00 - $20000
	dc.l	$00000000
;	dc.l	$00006000		;volume
	dc.l	$00000380
	dc.l	$00000000
	dc.l	$000000c4
	dc.l	$0000000a
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00001026		;$1026 - $b68f
	dc.l	$000000ff
	dc.l	$00000000
	dc.l	$000020fa		;$20fa - $207bf
	dc.l	$0000041e
	dc.l	ROM_NTRI
	dc.l	$00003FFF		;pan
eng04::
	dc.l	$00000010
	dc.l	ROM_SINE
	dc.l	ROM_SINE
	dc.l	$00000000
	dc.l	$00003D00		;$3d00 - $1CF00
	dc.l	$00000000
;	dc.l	$00006000
	dc.l	$00000380
	dc.l	$00000000
	dc.l	$00012B67
	dc.l	$000000FF
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00004737		;$4737 - $21C8B
	dc.l	$00000198
	dc.l	$00000000
	dc.l	$0000852B		;$852b - $3F2C7
	dc.l	$000003FF
	dc.l	ROM_AMSINE
	dc.l	$00003FFF
eng05::
	dc.l	$00000010
	dc.l	ROM_SINE
	dc.l	ROM_SINE
	dc.l	$00000000
	dc.l	$00002200		;$2200 - $1b500
	dc.l	$00000000
;	dc.l	$00006000
	dc.l	$00000380
	dc.l	$00000000
	dc.l	$000027C2
	dc.l	$000000FF
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$000027B1		;$27b1 - $1fe30
	dc.l	$0000019B
	dc.l	$00000000
	dc.l	$00004A39		;$4a39 - $3a5
	dc.l	$000003A5
	dc.l	ROM_AMSINE
	dc.l	$00003FFF
eng06::
	dc.l	$00000010
	dc.l	ROM_AMSINE
	dc.l	ROM_SINE
	dc.l	$00000000
	dc.l	$00004D00		;$4d00 -$18600
	dc.l	$00000000
;	dc.l	$00006000
	dc.l	$00000380
	dc.l	$00000000
	dc.l	$0000004D		;$4d - $186
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000A13		;$a13 - $3309
	dc.l	$0000007D
	dc.l	$00000000
	dc.l	$00060000
	dc.l	$000000C8		;$c8 - $4C8
	dc.l	ROM_CHIRP16
	dc.l	$00003FFF


skid_snd::
.if NEW_SKID
ENV_SKID equ ENV_CW
	.dc.l	$00000004
	.dc.l	ROM_AMSINE
	.dc.l	ROM_NOISE
	.dc.l	$00000000
	.dc.l	$00067300
	.dc.l	$00000000
;	.dc.l	$80000a00		; volume	
	.dc.l	$00006000		; volume
	.dc.l	$00000000
	.dc.l	$00000579
	.dc.l	$00000100
	.dc.l	ENV_SKID
	.dc.l	$0000001B
	.dc.l	$00040000
	.dc.l	$00010000
	.dc.l	$00000000
	.dc.l	$00070000
	.dc.l	$00000578
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00003FFF
.else
	dc.l	$00000010	;complex FM
	dc.l	ROM_TRI	;trianglar wave
	dc.l	ROM_TRI
	dc.l	$00000000
	dc.l	$00073D00	;top end pitch  - bottom pitch is $41000 
	dc.l	$00000000
	dc.l	$00000a00	;volume
	dc.l	$00000000
	dc.l	$00002008	;same throughout
	dc.l	$00000300	;same
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00007567	;same
	dc.l	$00000B00	;same
	dc.l	$00000000
	dc.l	$00040000	;same
	dc.l	$00000300	;same
	dc.l	ROM_NOISE	;noise wave
	dc.l	$00003FFF	;pan
.endif


radiosnd::
;when switching tunes turn this patch on and run the pitch parameter from 9B800 to 100 fast!
	dc.l	$00000008
	dc.l	ROM_DELTA
	dc.l	ROM_NOISE
	dc.l	$00000000
	dc.l	$0009B800	;pitch parameter
	dc.l	$00000000
;	dc.l	$00000000	;volume
	dc.l	$00000080
	dc.l	$00000000
	dc.l	$80003F00
	dc.l	$00001B00
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF

snd_hdr_tbl::				;there should be MAX_VOICES entries
	dc.l		tablestart+(0*taboff), tablestart+(1*taboff),tablestart+(2*taboff),tablestart+(3*taboff)
	dc.l		tablestart+(4*taboff),tablestart+(5*taboff),tablestart+(6*taboff),tablestart+(7*taboff)

;waveforms are 512 bytes long, on 512 byte boundary
;envelopes are all on a 32 byte boundary
envstart::
;userwv3 for TECHNO music
	dc.l	$00000B90,$000071C7,$00007FFF,$000051ED,$000039AE,$00004892,$00004EBC,$00003A82
	dc.l	$00002FC8,$00003E2E,$000043DE,$00002F97,$00002498,$000039C4,$0000481E,$00002B06
	dc.l	$000009AE,$00002122,$00005A63,$00005EC7,$00001902,$FFFFDBC8,$FFFFEF0F,$000032B8
	dc.l	$00005B32,$00005929,$00004EB7,$00004128,$00001963,$FFFFE5EB,$FFFFD72A,$FFFFF13C
	dc.l	$00000000,$FFFFEEE7,$FFFFF0D3,$000029A4,$0000645B,$00005A0A,$0000218D,$000012F8
	dc.l	$00004582,$0000705D,$0000586B,$00001BD7,$FFFFF3E7,$FFFFE501,$FFFFD92B,$FFFFDBC6
	dc.l	$FFFFFEC8,$00001F06,$000006B5,$FFFFC5A6,$FFFFA5B2,$FFFFBDA6,$FFFFD0A9,$FFFFB52B
	dc.l	$FFFF9E61,$FFFFCCB8,$000021EA,$000045F5,$000022B0,$FFFFF73A,$FFFFF2EE,$FFFFFFC7
	dc.l	$00000000,$000000B3,$00000D16,$00000640,$FFFFDA56,$FFFFBC65,$FFFFE72C,$00003C98
	dc.l	$0000648E,$000048C6,$00002DCE,$000041AE,$000055B2,$000030AA,$FFFFF015,$FFFFDCF9
	dc.l	$00000057,$00002199,$00002118,$00001354,$0000025B,$FFFFD881,$FFFF9E13,$FFFF8CD7
	dc.l	$FFFFBC79,$FFFFECDC,$FFFFD9D3,$FFFFA2BA,$FFFF9F30,$FFFFDDC0,$000013B0,$0000116E
	dc.l	$00000000,$00000F88,$000026B6,$0000131D,$FFFFDE1A,$FFFFB8B1,$FFFFADD5,$FFFFA5AE
	dc.l	$FFFFA795,$FFFFD3D3,$000015A6,$00002192,$FFFFDFAB,$FFFF9D9B,$FFFFA8E3,$FFFFE36F
	dc.l	$FFFFF697,$FFFFD2D9,$FFFFB84F,$FFFFC953,$FFFFDD83,$FFFFD0DE,$FFFFBDCE,$FFFFC582
	dc.l	$FFFFD37B,$FFFFC7A4,$FFFFB4EB,$FFFFBD7D,$FFFFCBEC,$FFFFB28E,$FFFF88DB,$FFFFA059
;OPENING
;stldrum
	dc.l	$00000000,$00007FFF,$00004CB6,$00003312,$00002640,$00001FD7,$00001022,$00001FAE
	dc.l	$00000FD7,$000007EB,$000003F5,$000001FA,$00000000,$00000000,$00000000,$00000000
;TECHNO
;bigbass
	dc.l	$00007FFF,$00003FFF,$00005FFF,$00003FFF,$00001FFF,$00000FFF,$000007FF,$000003FF
	dc.l	$000001FF,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
;techhat
	dc.l	$00007FFF,$00006F18,$0000378C,$00001BC6,$00000DE3,$000006F1,$00000378,$000001BC
	dc.l	$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
;wawo
	dc.l	$00007FFF,$0000264B,$00007FFF,$00003FFF,$00007FFF,$00003FFF,$00001FFF,$00000FFF
	dc.l	$000007FF,$000003FF,$000001FF,$00000000,$00000000,$00000000,$00000000,$00000000
;quack
	dc.l	$00007530,$00003A98,$000065CC,$00000000,$00000000,$00000000,$00000000,$00000000
;waky
	dc.l	$00000000,$00003A98,$000057E4,$0000668A,$00006DDD,$00007186,$00007530,$00003A98
	dc.l	$00001D4C,$00000EA6,$00000753,$000003A9,$000001D4,$000000EA,$00000075,$00000000
;GANSTER
;eightoh8
	dc.l	$00007FFF,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
;moogenv
	dc.l	$00007FFF,$00002530,$00001A18,$000013D8,$00000D98,$00000992,$0000044C,$00000000
;REGGAE
;regbass
	dc.l	$00007FFF,$00006CFF,$0000263F,$00000B9F,$00000000,$00000000,$00000000,$00000000
;epiano
	dc.l	$00007FFF,$00003FFF,$00001FFF,$00000FFF,$00000000,$00000000,$00000000,$00000000
.if NEW_SKID
;skid sound
	.dc.l	$00000000, $0000359F, $0000453F, $0000237F
	.dc.l	$00002440, $000034FF, $00001AC1, $00000000
.else
;CLUB WAVE
	dc.l	$00007FFF,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
.endif
	dc.l	$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
envend::

	.extern	tsnare,tconga,tkick,marimba
;OPENING patches
p0:
	dc.l	$00000020			;kick
;	dc.l	$00001800			;volume
	dc.l	$00000140			;volume
	dc.l	tkick
	dc.l	$00001400  
	dc.l	((2431)<<8)-1
	dc.l	((2431)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((2431)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00006800
p1:
	dc.l	$00000020			;snare
	dc.l	$00000100			;volume
	dc.l	tsnare
	dc.l	$00001000  
	dc.l	((4780)<<8)-1
	dc.l	((4780)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((4780)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00006800

;patch 2			; Sampled conga
p2:
	dc.l	$00000020
	dc.l	$000000F8	;volume
	dc.l	tconga
	dc.l	$00001090
	dc.l	((4127)<<8)-1
	dc.l	((4127)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((4127)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00006800

;patch 3	
p3:				;jazzbas4
	dc.l	$00000020
	dc.l	$000000F8	;volume
	dc.l	sfbass
	dc.l	$00001090
	dc.l	((11753)<<8)-1
	dc.l	((11753)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((11753)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF
; Patch 4				;Steel drum
p4:
	dc.l	$00000004		;FM/env
	dc.l	ROM_SINE
	dc.l	ROM_SINE
	dc.l	$00000000
	dc.l	$00012400
	dc.l	$00000000
	dc.l	$00000140		;vol (was 1C0)
	dc.l	$00000000
	dc.l	$80000500
	dc.l	$00000099
	dc.l	ENV_CONGA0
	dc.l	$00000110
	dc.l	$000C0000
	dc.l	$000C0000
	dc.l	$00000000
	dc.l	$000C0000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF
; Patch 5				;Marimba from the synth
p5:
	dc.l	$00000020
	dc.l	$00000080		;vol
	dc.l	marimba
	dc.l	$00001000
	dc.l	((12032)<<8)-1
	dc.l	((12032)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((12032)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF
pe::

; honky music patches
	.extern tmtwo,tmthree,tmfour,tritone
; Patch 0	honkyc2.raw
tm0:
	dc.l	$00000020
	dc.l	$00000060
	dc.l	tmtwo
	dc.l	$00001000  
	dc.l	((29722/2)<<8)-1
	dc.l	((29722/2)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((29722/2)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00006800

; Patch 1	honkyc3.raw
tm1:
	dc.l	$00000020
	dc.l	$00000060
	dc.l	tmthree
	dc.l	$00001000
	dc.l	((25768/2)<<8)-1
	dc.l	((25768/2)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((25768/2)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00005000	

; Patch 2	honkyc4.raw
tm2:
	dc.l	$00000020
	dc.l	$00000060
	dc.l	tmfour
	dc.l	$00001000  
	dc.l	((25150/2)<<8)-1
	dc.l	((25150/2)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((25150/2)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003800

; Patch 3	pnotri.raw
tm3:
	dc.l	$00000020
	dc.l	$00000060
	dc.l	tritone
	dc.l	$00001030
	dc.l	((11704/2)<<8)-1
	dc.l	((11704/2)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((11704/2)<<8)-1
	dc.l	$80000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00002FFF

; Patch 4	bass.f16
tm4:
	dc.l	$00000020
	dc.l	$000000c0
	dc.l	sfbass
	dc.l	$00000FFE
	dc.l	((11773)<<8)-1
	dc.l	((11773)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((11773)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF

; Patch 5	rockkick.f16
tm5:
	dc.l	$00000020
	dc.l	$00000090
	dc.l	rockkick
	dc.l	$00001000
	dc.l	((3321)<<8)-1
	dc.l	((3321)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((3321)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF	

; Patch 6	roksnare.f16
tm6:
	dc.l	$00000020
	dc.l	$00000060
	dc.l	roksnare
	dc.l	$00001000
	dc.l	((9406)<<8)-1
	dc.l	((9406)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((9406)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00001FFF	
tme:

	.extern	sfkick,sfbass,trumpet,clsd_hat,open_hat,sfsnare,ride,rim,toms
;sfjazz patches
jm0::
; Patch 0				;Kick
	dc.l	$00000020
	dc.l	$00000100		;vol
	dc.l	sfkick
	dc.l	$00001000           ; transposition parameter - 1000 is no change (2000 doubles, 800 halves)
	dc.l	((10935)<<8)-1
	dc.l	((10935)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((10935)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF	

; Patch 1				;bass
	dc.l	$00000020
	dc.l	$00000140
	dc.l	sfbass
	dc.l	$00001000           ; transposition parameter - 1000 is no change (2000 doubles, 800 halves)
	dc.l	((11773)<<8)-1
	dc.l	((11773)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((11773)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF	

; Patch 2				;TRUMPET
	dc.l	$00000020
	dc.l	$00000100		;vol
	dc.l	trumpet
	dc.l	$00001000
	dc.l	((11753)<<8)-1
	dc.l	((11753)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((11753)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF

; Patch 3				;HI HAT
	dc.l	$00000020
	dc.l	$00000100		;vol
	dc.l	clsd_hat		;Closed Hi Hat
	dc.l	$00001000		;(open is @ patch 10)
	dc.l	((4488)<<8)-1
	dc.l	((4488)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((4488)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF	

; Patch 4				;Snare
	dc.l	$00000020
	dc.l	$000000c0		;vol
	dc.l	sfsnare
	dc.l	$00001000
	dc.l	((16059)<<8)-1
	dc.l	((16059)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((16059)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF

; Patch 5				;ride
	dc.l	$00000020
	dc.l	$00000140		;vol
	dc.l	ride
	dc.l	$00001000
	dc.l	((43051)<<8)-1
	dc.l	((43051)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((43051)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF

; Patch 6				;rim click
	dc.l	$00000020
	dc.l	$00000100		;vol
	dc.l	rim			;rim click
	dc.l	$00001000
	dc.l	((2715)<<8)-1
	dc.l	((2715)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((2715)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF

; Patch 7				;Tom Toms
	dc.l	$00000020
	dc.l	$00000100	;vol
	dc.l	toms		;low tom (midtom @ 10 high tom @ 11)
	dc.l	$00001000
	dc.l	((16916)<<8)-1
	dc.l	((16916)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((16916)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF

; Patch 8				;Mapped from patch 2
	dc.l	$00000020
	dc.l	$00000100		;vol
	dc.l	open_hat		;Open Hi Hat
	dc.l	$00001000
	dc.l	((5520)<<8)-1
	dc.l	((5520)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((5520)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF
jmend:

;techno patches
xm0::
; Patch 0				; FM voice shifted to 8-14
	dc.l	$00000008
	dc.l	ROM_SINE
	dc.l	ROM_DELTA	;mod
	dc.l	$00000000	
	dc.l	$00009B00	;pitch
	dc.l	$00000000
	dc.l	$00000080	;vol
	dc.l	$00000000
	dc.l	$00010000	;freq of 
	dc.l	$00001B00	;depth
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000FFF

	.extern	rapkick,rapsnr1,rapsnr2,raphat,raptone,rappiano,wahguitr,balloon

;patch 1				; kick sample
	dc.l	$00000020
;	dc.l	$00004000
	dc.l	$00000280		;vol
	dc.l	rapkick			;techkick
	dc.l	$00000C00           ; transposition parameter - 1000 is no change (2000 doubles, 800 halves)
	dc.l	((2568/2)<<8)-1
	dc.l	((2568/2)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((2568/2)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF	;pan	

; Patch 2				; tech hat
_voice0:
	dc.l	$00000004
	dc.l	ROM_12W
	dc.l	ROM_AMSINE
	dc.l	$00000000
	dc.l	$00001000
	dc.l	$00000000
;	dc.l	$00000010		;vol
	dc.l	$00000080		;vol
	dc.l	$00000000
	dc.l	$80000100
	dc.l	$00006700
	dc.l	ENV_TECH1
	dc.l	$00000046
	dc.l	$00080000
	dc.l	$00040000
	dc.l	$00000000
	dc.l	$00040000
	dc.l	$00007530
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF

; Patch 3				;snare
	dc.l	$00000020
;	dc.l	$00002000
	dc.l	$00000180	;vol
	dc.l	rapsnr2		;techsnar
	dc.l	$00000500
	dc.l	((2418/2)<<8)-1
	dc.l	((2418/2)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((2418/2)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00002000

;patch 4				;organ -- pad
	dc.l	$00000004
	dc.l	ROM_SINE
	dc.l	ROM_NTRI		;mod
	dc.l	$00000000
	dc.l	$00001000		;pitch
	dc.l	$00000000
;	dc.l	$00000A00		;vol
	dc.l	$000000D0		;vol
	dc.l	$00000000
	dc.l	$80030000
	dc.l	$00000D00
	dc.l	ENV_TECH4
	dc.l	$0000000B
	dc.l	$000F0000
	dc.l	$00040000
	dc.l	$00000000
	dc.l	$00040000
	dc.l	$00004351
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF

; Patch 5				; bass
	dc.l	$00000004
	dc.l	WAVE_TECH
	dc.l	ROM_TRI		;mod
	dc.l	$00000000
	dc.l	$00001000	;pitch
	dc.l	$00000000
;	dc.l	$00001000	;vol
	dc.l	$00000100	;vol
	dc.l	$00000000
	dc.l	$80000100
	dc.l	$00000000
	dc.l	ENV_TECH0
	dc.l	$00000030
	dc.l	$00070000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00030000
	dc.l	$0000012C
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF

; Patch 6				; spronk
	dc.l	$00000004
	dc.l	ROM_AMSINE
	dc.l	ROM_CHIRP16
	dc.l	$00000000
	dc.l	$00001000
	dc.l	$00000000
;	dc.l	$00001800		;vol
	dc.l	$00000140		;vol
	dc.l	$00000000
	dc.l	$80000001
	dc.l	$00000000
	dc.l	ENV_TECH2
	dc.l	$00000046
	dc.l	$000B0000
	dc.l	$00040000
	dc.l	$00000000
	dc.l	$00040000
	dc.l	$00001770
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF

; Patch 7				; quack
	dc.l	$00000004
	dc.l	ROM_CHIRP16
	dc.l	ROM_CHIRP16
	dc.l	$00000000
	dc.l	$00000100
	dc.l	$00000000
	dc.l	$00000080		;vol
	dc.l	$00000000
	dc.l	$00000420
	dc.l	$00000064
	dc.l	ENV_TECH3
	dc.l	$00000055
	dc.l	$00030000
	dc.l	$00040000
	dc.l	$00000000
	dc.l	$00040000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00001000



;-------------------------------------------------------------------------------
; Patch 8				;first of eight complex FM voices (8-14)
	dc.l	$00000008
	dc.l	ROM_SINE
	dc.l	ROM_DELTA
	dc.l	$00000000
	dc.l	$00009B00
	dc.l	$00000000
;	dc.l	$00000000	;vol
	dc.l	$00000080	;vol
	dc.l	$00000000
	dc.l	$00010000
	dc.l	$00002F00
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00002FFF

; Patch 9				;first of eight complex FM voices (8-14)
	dc.l	$00000008
	dc.l	ROM_SINE
	dc.l	ROM_DELTA
	dc.l	$00000000
	dc.l	$00009B00
	dc.l	$00000000
;	dc.l	$00000000	;vol
	dc.l	$00000080	;vol
	dc.l	$00000000
	dc.l	$00010000
	dc.l	$00003200
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF

; Patch 10				;first of eight complex FM voices (8-14)
	dc.l	$00000008
	dc.l	ROM_SINE
	dc.l	ROM_DELTA
	dc.l	$00000000
	dc.l	$00009B00
	dc.l	$00000000
;	dc.l	$00000000	;vol
	dc.l	$00000080	;vol
	dc.l	$00000000
	dc.l	$00010000
	dc.l	$00004500
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00004FFF

; Patch 11				;first of eight complex FM voices (8-14)
	dc.l	$00000008
	dc.l	ROM_SINE
	dc.l	ROM_DELTA
	dc.l	$00000000
	dc.l	$00009B00
	dc.l	$00000000
;	dc.l	$00000000	;vol
	dc.l	$00000080	;vol
	dc.l	$00000000
	dc.l	$00010000
	dc.l	$00005800
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00005FFF

; Patch 12				;first of eight complex FM voices (8-14)
	dc.l	$00000008
	dc.l	ROM_SINE
	dc.l	ROM_DELTA
	dc.l	$000C8100
	dc.l	$00009B00
	dc.l	$00000000
;	dc.l	$00000000	;vol
	dc.l	$00000080	;vol
	dc.l	$00000000
	dc.l	$00010000
	dc.l	$00006B00
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00006FFF
; Patch 13				;first of eight complex FM voices (8-14)
	dc.l	$00000008
	dc.l	ROM_SINE
	dc.l	ROM_DELTA
	dc.l	$000C8100
	dc.l	$00009B00
	dc.l	$00000000
;	dc.l	$00000000	;vol
	dc.l	$00000080	;vol
	dc.l	$00000000
	dc.l	$00010000
	dc.l	$00007E00
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00007FFF
; Patch 14				;first of eight complex FM voices (8-14)
	dc.l	$00000008
	dc.l	ROM_SINE
	dc.l	ROM_DELTA
	dc.l	$00000000
	dc.l	$00009B00
	dc.l	$00000000
;	dc.l	$00000000	;vol
	dc.l	$00000080	;vol
	dc.l	$00000000
	dc.l	$00010000
	dc.l	$00008100
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00007FFF
xmend::

	.extern	squeekie
;gangsta rap patches
; Patch 0	sampled kick
rm0:
	dc.l	$00000020
	dc.l	$000002cc	;vol
	dc.l	rapkick
	dc.l	$00001000   
	dc.l	((2568)<<8)-1
	dc.l	((2568)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((2568)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF	

; Patch 1	snare 1
	dc.l	$00000020
;	dc.l	$00005000
	dc.l	$00000266	;vol
	dc.l	rapsnr1
	dc.l	$00001000       
	dc.l	((2203)<<8)-1
	dc.l	((2203)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((2203)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00002000

; Patch 2	snare 2
	dc.l	$00000020
;	dc.l	$00005000
	dc.l	$00000266	;vol
	dc.l	rapsnr2
	dc.l	$00001000
	dc.l	((2418)<<8)-1
	dc.l	((2418)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((2418)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00006000	

; Patch 3	hihat
	dc.l	$00000020
;	dc.l	$00005000	;
	dc.l	$00000266	;vol
	dc.l	raphat
	dc.l	$00001000
	dc.l	((1879)<<8)-1
	dc.l	((1879)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((1879)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003E00	

; Patch 4	phat808
	dc.l	$00000004
	dc.l	ROM_SINE
	dc.l	ROM_SINE
	dc.l	$00000000
	dc.l	$00001000	;pitch
	dc.l	$00000000
	dc.l	$80000333	;vol
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	ENV_GANG0
	dc.l	$00000018
	dc.l	$00040000
	dc.l	$00040000
	dc.l	$00000000
	dc.l	$00040000
	dc.l	$00000258
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF

; Patch 5	squeekie	
	dc.l	$00000020
	dc.l	$00000200	;vol
	dc.l	squeekie
	dc.l	$00001000
	dc.l	((20778)<<8)-1
	dc.l	((20778)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((20778)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00002800
	
; Patch 6	piano stuff
	dc.l	$00000020
	dc.l	$00000133	;vol
	dc.l	rappiano
	dc.l	$00001000
	dc.l	((19397)<<8)-1
	dc.l	((19397)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((19397)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00005800

; Patch 7	wah guitar
	dc.l	$00000020
	dc.l	$00000133	;vol
	dc.l	wahguitr
	dc.l	$00001000
	dc.l	((3902)<<8)-1
	dc.l	((3902)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((3902)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF

; Patch 8	bass synth
	dc.l	000000004
	dc.l	ROM_12W
	dc.l	ROM_12W		;mod
	dc.l	$00000000
	dc.l	$00000000	;pitch
	dc.l	$00000000
	dc.l	$000002cc	;vol
	dc.l	$00000000
	dc.l	$80000100
	dc.l	$00000000
	dc.l	ENV_GANG1
	dc.l	$00000030
	dc.l	$00070000
	dc.l	$00070000
	dc.l	$00000000
	dc.l	$00070000
	dc.l	$00000280
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF

; Patch 9	balloons
	dc.l	$00000020
	dc.l	$000000cc
	dc.l	balloon
	dc.l	$00001000
	dc.l	((23329)<<8)-1
	dc.l	((23329)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((23329)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003000
rmend:

	.extern	chord1,chord2,cabas1,cabas3
;reggae patches
rg0:
	dc.l	$00000004
	dc.l	ROM_AMSINE
	dc.l	ROM_SINE
	dc.l	$00000000
	dc.l	$00001000
	dc.l	$00000000
	dc.l	$00000200	;vol
	dc.l	$00000000
	dc.l	$80000104
	dc.l	$00000000
	dc.l	ENV_REG0
	dc.l	$00000032
	dc.l	$00040000
	dc.l	$00040000
	dc.l	$00000000
	dc.l	$00040000
	dc.l	$00000080
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF

; Patch 1	chord
	dc.l	$00000020
	dc.l	$00000100	;vol
	dc.l	chord1
	dc.l	$00001Ba4
	dc.l	((7913)<<8)-1
	dc.l	((7913)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((7913)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00004800

; Patch 2	melody
	dc.l	$00000004
	dc.l	ROM_SINE
	dc.l	ROM_12W
	dc.l	$00000000
	dc.l	$00002000
	dc.l	$00000000
	dc.l	$800000cc	;vol
	dc.l	$00000000
	dc.l	$80000a00
	dc.l	$00000000
	dc.l	ENV_REG1
	dc.l	$00000036
	dc.l	$00090000
	dc.l	$00090000
	dc.l	$00000000
	dc.l	$00090000
	dc.l	$0000044c
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00004200

; Patch 3	kick
	dc.l	$00000020
	dc.l	$00000266	;vol
	dc.l	rapkick
	dc.l	$00001000   
	dc.l	((2568)<<8)-1
	dc.l	((2568)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((2568)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003FFF	

; Patch 4	snare
	dc.l	$00000020
	dc.l	$00000198	;vol
	dc.l	rapsnr2
	dc.l	$00001000
	dc.l	((2418)<<8)-1
	dc.l	((2418)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((2418)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00006000	

; Patch 5	hihat	
	dc.l	$00000020
	dc.l	$000000cc	;vol
	dc.l	raphat
	dc.l	$00001000
	dc.l	((1879)<<8)-1
	dc.l	((1879)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((1879)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00002000	

; Patch 6	chord2
	dc.l	$00000020
	dc.l	$00000100	;vol
	dc.l	chord2
	dc.l	$00001Ba4       
	dc.l	((4555)<<8)-1
	dc.l	((4555)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((4555)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003800

; Patch 7	TOMS
	dc.l	$00000020
	dc.l	$00000198	;vol
	dc.l	toms
	dc.l	$00001BB0       
	dc.l	((16916)<<8)-1
	dc.l	((16916)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((16916)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003800

; Patch 8	CABASSA1
	dc.l	$00000020
	dc.l	$00000066	;vol
	dc.l	cabas1
	dc.l	$00001BB0       
	dc.l	((3468)<<8)-1
	dc.l	((3468)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((3468)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003800

; Patch 9	CABASSA2
	dc.l	$00000020
	dc.l	$00000066	;vol
	dc.l	cabas3
	dc.l	$00001BB0       
	dc.l	((3468)<<8)-1
	dc.l	((3468)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	((3468)<<8)-1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00003800

rgend:

;CLUB WAVE
	.extern	rockkick,roksnare,sawwave
cw:
; Patch 0	rockkick.raw
cw0:
	.dc.l	$00000020
	.dc.l	$00000100
	.dc.l	rockkick
	.dc.l	$00001180  
	.dc.l	((2568)<<8)-1
	.dc.l	((2568)<<8)-1
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	((2568)<<8)-1
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00006800

; Patch 1	roksnare.raw
cw1:
	.dc.l	$00000020
	.dc.l	$000000a0
	.dc.l	roksnare
	.dc.l	$00001400
	.dc.l	((9406)<<8)-1
	.dc.l	((9406)<<8)-1
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	((9406)<<8)-1
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00004800	


; Patch 2	wave
cw2:
	.dc.l	$00000020
	.dc.l	$00000100	; vol
	.dc.l	sawwave
	.dc.l	$00001000
	.dc.l	((7418)<<8)-1
	.dc.l	((7418)<<8)-1
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	((7418)<<8)-1
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00003800


; Patch 3	triangle
cw3:
	.dc.l	$00000008
	.dc.l	ROM_TRI
	.dc.l	ROM_SINE
	.dc.l	$00000000
	.dc.l	$00001000
	.dc.l	$00000000
	.dc.l	$00000100	;vol
	.dc.l	$00000000
	.dc.l	$80000100
        .dc.l	$00000200
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00004200
cwend:	
