	.include	'eq.s'
	.include	'externs.s'

;salesman actions
SM_WAIT	equ	0						;arms crossed
SM_TAP	equ	1						;tapping foot
SM_WALK	equ	2						;walking
SM_POINTL	equ	3						;point to left side of screen
SM_POINTR	equ	4						;point to right side of screen
SM_JUMP	equ	5						;jumping after car has been chosen

SALES_WAIT		equ	300				;salesman starts tapping foot or crossing arms after this many frames of no input
SALES_WAIT2		equ	540				;salesman has a chance of changing his waiting action
SALES_WAIT_STOP	equ	780

;salesman directions
LEFT		equ	0
RIGHT	equ	1

LEFT_PT_LEFT	equ	38					;at left edge pointing to left car
MID_PT_RIGHT	equ	50					;at left side of screen pointing to middle
MID_PT_LEFT	equ	142					;at right side of screen pointing to middle
RIGHT_PT_RIGHT	equ	158					;at right edge pointing to right car

	.text
lotloop::
	bsr.b	sm_anim

	lea		lotobjs,a1				;address of first object header
	moveq	#LOT_OBJS,d6				;total objects in list
	lea		olist_ram,a2
	bsr		build					;build packed object list

	bsr		input
	bsr		lotinput
	rts

sm_anim::
	addq.w	#1,sm_anchg
	lea		act_chg,a0
	move.w	sm_act,d0					;get current action
	lsl.w	#1,d0
	move.w	sm_anchg,d1				;get current counter value
	cmp.w	(a0,d0.w),d1				;compare limit to current
	blt.b	.30						;if current < limit, not time to change step yet
	move.w	#0,sm_anchg				;reset counter
	addq.w	#1,sm_anstp
	lea		act_stps,a0
	move.w	sm_anstp,d1				;get current anim step
	cmp.w	(a0,d0.w),d1				;compare limit to current
	blt.b	.30
	move.w	#0,sm_anstp				;reset anim step
	cmp.w	#SM_JUMP,sm_act
	beq		retrnsel					;exit screen when jumping is finished
.30:
;D0 = action * 2
	lsl.w	#3,d0					;change to sm_act * 16
	add.w	sm_anstp,d0
	lea		sm_frms,a0
	move.b	(a0,d0.w),d0				;get frame number
	and.w	#$FF,d0					;now have frame number in D0
	lsl.w	#1,d0					;frame number * 2

	lea		sm_dwid,a0				;dwidth and iwidth
	move.w	(a0,d0.w),lot_man+O_DWIDTH
	move.w	(a0,d0.w),lot_man+O_IWIDTH
	lea		sm_ht,a0					;height
	move.w	(a0,d0.w),lot_man+O_HEIGHT

	lea		sm_xadj,a0				;xpos adjustment table
	move.w	sales_x,d1				;get current xpos for the 'box'
	cmp.b	#HFLIP_ON|TRANS_ON,lot_man+O_FLAGS
	beq.b	.40
	add.w	(a0,d0.w),d1				;add xpos adjustment
	bra.b	.45
.40:
	add.w	#144,d1					;width of salesman 'box'
	sub.w	(a0,d0.w),d1				;subtract xpos adjustment
.45:
	move.w	d1,lot_man+O_XPOS
.50:
	lea		sm_yadj,a0				;ypos adjustment
	move.w	(a0,d0.w),d1
	add.w	sales_y,d1
	move.w	d1,lot_man+O_YPOS

	lsl.w	#1,d0					;data table is 4 bytes per address
	lea		sm_data,a0
	move.l	(a0,d0.w),lot_man+O_DATA
	rts

gocarlot::
;car_chsr = 0 if player 1 is choosing a car
;car_chsr = 1 if player 2 is choosing a car
;	bsr		dsp_off
;	move.l	#REGGAE_MUSIC,songnum
;	bsr		playmus					;start music

	move.w	#SM_POINTR,sm_act			;point at car when screen begins
	moveq	#0,d0
	move.w	d0,sm_anstp				;reset anim step
	move.w	d0,sm_anchg				;reset anim counter
	move.w	d0,smautoct				;reset automatic movement counter

	lea		cur_car0,a0				;assume player 1 is choosing a car
	cmp.b	#0,car_chsr
	beq.b	.05
	lea		cur_car1,a0				;player 2 is choosing a car
.05:	move.w	(a0),d0					;get current car type
	move.w	d0,pointcar				;save it as the last car that was pointed at
	lea		sm_def_f,a1				;flags settings for each car type
	move.b	(a1,d0.w),lot_man+O_FLAGS
	lsl.w	#1,d0
	lea		sm_def_x,a1				;x positions for each car type
	move.w	(a1,d0.w),sales_x			;set salesman X position for current car
	lea		sm_def_d,a1				;directions for each car type
	move.w	(a1,d0.w),sm_dir

	cmp.b	#NTSC,pal_ntsc
	beq.b	.10
	move.w	#P_SCRN_TOP+150,sales_y
	move.w	#P_SCRN_TOP,lot_scr+O_YPOS
	move.w	#287,lot_scr+O_HEIGHT
	move.w	#P_SCRN_TOP+100,lot_man+O_YPOS
	bra.b	.20
.10:	move.w	#N_SCRN_TOP+128,sales_y
	move.w	#N_SCRN_TOP,lot_scr+O_YPOS
	move.l	#lotscr+(48*640),lot_scr+O_DATA
	move.w	#240,lot_scr+O_HEIGHT
	move.w	#N_SCRN_TOP+100,lot_man+O_YPOS
.20:
;get the object data for the car lot screen
	bsr		clearscr

	bsr		ld_decmp
	bsr		load_q90				;load jpeg quality table

	lea		lotbkg,a0				;table with decompression info
	moveq	#17,d0				;number of objects to decompress
	bsr		dodecomp				;load just the background for now

	lea		adblack,a0
	bsr		load_gpu
	move.l	#lot_jm00,ADJBLACK_START			;destination address
	move.l	#lot_wk07+(64*96*2),ADJBLACK_END	;total size
	bsr		adjblak

	bsr		ld_uncmp				;load uncomp .GAS code

	lea		msk_lot,a0			;address of table of mask info
	moveq	#16,d0				;number of masks
	bsr		do_mask

	move.w	#CARLOT_MODE,gamemode
	move.w	#$6C7,VMODE			;switch to 320 width
	rts	

lotinput::
	cmp.w	#SM_JUMP,sm_act
	beq.b	.90						;no input allowed after fire button is pressed to exit
	lea		cur_car0,a0				;assume player 1 is choosing a car
	move.l	joyedge,d0
	cmp.b	#0,car_chsr
	beq.b	.10
	lea		cur_car1,a0				;player 2 is choosing a car
	move.l	joyedge2,d0
.10:	and.l	#ANY_FIRE,d0
	beq.b	lotjoy					;if no fire button was pressed, check joypad
;set the car type here
	cmp.w	#MID_PT_RIGHT-6,sales_x
	bge.b	.20
	move.w	#0,(a0)					;set cur_car0 or cur_car1 to left car if salesman xpos is < MID_PT_RIGHT
	bra.b	.50
.20:
	cmp.w	#MID_PT_LEFT+7,sales_x
	bge.b	.30
	move.w	#1,(a0)					;set car type to middle car if salesman xpos is between MID_PT_RIGHT and MID_PT_LEFT
	bra.b	.50
.30:
	move.w	#2,(a0)					;set car type to right car
.50:
	move.w	#SM_JUMP,sm_act			;make salesman jump when car has been selected
	moveq	#0,d0
	move.w	d0,sm_anchg				;reset counter
	move.w	d0,sm_anstp
	move.w	d0,smautoct
.90:	rts

lotjoy::
	move.l	joyedge,d0
	cmp.b	#0,car_chsr
	beq.b	.05
	move.l	joyedge2,d0
.05:
	and.l	#ANY_JOY,d0
	bne.b	.10
	cmp.w	#SM_WALK,sm_act
	bne		mvsmauto
	cmp.w	#LEFT,sm_dir
	beq		mv_sm_lf
	bra		mv_sm_rt
.10:
	move.l	joyedge,d0
	cmp.b	#0,car_chsr
	beq.b	.15
	move.l	joyedge2,d0
.15:
	btst.l	#JOY_LEFT,d0
	beq.b	.20
  	move.w	#SM_WALK,sm_act
	bsr.b	mv_sm_lf
	bra.b	.90
.20:
	move.l	joyedge,d0
	cmp.b	#0,car_chsr
	beq.b	.25
	move.l	joyedge2,d0
.25:
	btst.l	#JOY_RIGHT,d0
	beq.b	.30
  	move.w	#SM_WALK,sm_act
	bsr		mv_sm_rt
.30:
.90:	rts


mv_sm_lf::
	cmp.w	#RIGHT,sm_dir
	bne.b	.10
	move.w	#LEFT,sm_dir
	bsr		set_flip
	bra.b	.20
.10:
	cmp.w	#LEFT_PT_LEFT,sales_x
	bge.b	.15
	move.w	#0,pointcar					;left car
	bra.b	.40
.15:	move.w	act_chg+(SM_WALK*2),d1
	sub.w	#1,d1
	cmp.w	sm_anchg,d1
	bne.b	.90
.20:
	lea		walk_amt,a0
	move.w	sm_anstp,d5
	move.b	(a0,d5.w),d5
	neg.w	d5

.30:	move.w	#0,smautoct					;reset automatic move timer
	move.w	#LEFT,sm_dir
	bsr		set_flip
	move.w	sales_x,d1
	cmp.w	#LEFT_PT_LEFT,d1
	blt.b	.40							;if at left edge, point at left car
	add.w	d5,d1
	move.w	d1,sales_x
	cmp.w	#1,pointcar
	beq.b	.90							;don't stop at middle car after already stopping there
	cmp.w	#MID_PT_LEFT+6,d1				;see if salesman should stop to point at middle car
	bge.b	.90
	cmp.w	#MID_PT_LEFT-6,d1
	blt.b	.90
	move.w	#1,pointcar
.40:	move.w	#SM_POINTR,sm_act				;make him point at car
	moveq	#0,d0
	move.w	d0,sm_anchg
	move.w	d0,sm_anstp
.90:	rts

mv_sm_rt::
	cmp.w	#LEFT,sm_dir
	bne.b	.10
	move.w	#RIGHT,sm_dir
	bsr		set_flip
	bra.b	.20
.10:
	cmp.w	#RIGHT_PT_RIGHT,sales_x
	blt.b	.15
	move.w	#2,pointcar					;right car
	bra.b	.40
.15:	move.w	act_chg+(SM_WALK*2),d1
	sub.w	#1,d1
	cmp.w	sm_anchg,d1
	bne.b	.90
.20:
	lea		walk_amt,a0
	move.w	sm_anstp,d5
	move.b	(a0,d5.w),d5

.30:	move.w	#0,smautoct					;reset automatic move timer
	move.w	#RIGHT,sm_dir
	bsr		set_flip
	move.w	sales_x,d1
	cmp.w	#RIGHT_PT_RIGHT,d1
	bge.b	.40							;if at right edge, point at right car
	add.w	d5,d1
	move.w	d1,sales_x
	cmp.w	#1,pointcar
	beq.b	.90							;don't stop at middle car after already stopping there
	cmp.w	#MID_PT_RIGHT-6,d1				;see if salesman should stop to point at middle car
	blt.b	.90
	cmp.w	#MID_PT_RIGHT+6,d1
	bge.b	.90
	move.w	#1,pointcar
.40:	move.w	#SM_POINTR,sm_act				;make him point at car
	moveq	#0,d0
	move.w	d0,sm_anchg
	move.w	d0,sm_anstp
.90:	rts

walk_amt::
	dc.b		10,4,4,12,12,2,7,10
	.even

mvsmauto::
;move salesman automatically if there has been no joypad movement for awhile
	addq.w	#1,smautoct					;increase automatic movement counter
	cmp.w	#SALES_WAIT,smautoct			;see if it's time to start tapping foot or crossing arms
	blt		.90							;keep tapping foot
	beq.b	.30
	cmp.w	#SALES_WAIT2,smautoct			;2 chances to change waiting action
	bne.b	.50
.30:
	bsr		set_flip
	move.l	seed,d0
	and.w	#1,d0
	beq.b	.40							;random chance of waiting or tapping
	move.w	#SM_TAP,sm_act
	bra.b	.85
.40:	move.w	#SM_WAIT,sm_act
	bra.b	.85
.50:
	cmp.w	#SALES_WAIT_STOP,smautoct
	blt.b	.90
	move.l	seed,d0
	and.w	#1,d0
	beq.b	.60
	move.w	#SM_POINTL,sm_act				;point with cane close to body
	cmp.b	#HFLIP_ON|TRANS_ON,lot_man+O_FLAGS	;need to reverse flip status to point at the same car
	beq.b	.55
	move.b	#HFLIP_ON|TRANS_ON,lot_man+O_FLAGS
	bra.b	.80
.55:
	move.b	#HFLIP_OFF|TRANS_ON,lot_man+O_FLAGS
	bra.b	.80
.60:
	move.w	#SM_POINTR,sm_act				;change to pointing when timer is at SALES_WAIT_STOP
	bsr.b	set_flip
.80:	move.w	#0,smautoct					;reset counter
.85:	move.w	#0,sm_anchg
	move.w	#0,sm_anstp
.90:	rts

set_flip::
	cmp.w	#RIGHT,sm_dir
	beq.b	.10
	move.b	#HFLIP_OFF|TRANS_ON,lot_man+O_FLAGS
	bra.b	.20
.10:	move.b	#HFLIP_ON|TRANS_ON,lot_man+O_FLAGS
.20:	rts

sm_dwid::
	dc.w		20				;jump 00
	dc.w		28				;jump 01
	dc.w		20				;jump 02
	dc.w		16				;point 00
	dc.w		20				;point 01
	dc.w		8				;wait 00
	dc.w		16				;wait 01
	dc.w		16				;wait 02
	dc.w		20				;walk 00
	dc.w		12				;walk 01
	dc.w		8				;walk 02
	dc.w		12				;walk 03
	dc.w		12				;walk 04
	dc.w		12				;walk 05
	dc.w		12				;walk 06
	dc.w		16				;walk 07
sm_ht::
	dc.w		96				;jump 00
	dc.w		80				;jump 01
	dc.w		120				;jump 02
	dc.w		96				;point 00
	dc.w		96				;point 01
	dc.w		96				;wait 00
	dc.w		96				;wait 01
	dc.w		96				;wait 02
	dc.w		96				;walk 00
	dc.w		96				;walk 01
	dc.w		96				;walk 02
	dc.w		96				;walk 03
	dc.w		96				;walk 04
	dc.w		96				;walk 05
	dc.w		96				;walk 06
	dc.w		96				;walk 07
sm_xadj::
;add to xpos for the 144 x 144 box
	dc.w		27				;jump 00
	dc.w		10				;jump 01
	dc.w		33				;jump 02
	dc.w		53				;point 00
	dc.w		12				;point 01
	dc.w		57				;wait 00
	dc.w		49				;wait 01
	dc.w		49				;wait 02
	dc.w		30				;walk 00
	dc.w		54				;walk 01
	dc.w		66				;walk 02
	dc.w		51				;walk 03
	dc.w		64				;walk 04
	dc.w		64				;walk 05
	dc.w		52				;walk 06
	dc.w		41				;walk 07
sm_yadj::
;add to ypos for the 144 x 144 box
;this is halflines
	dc.w		102				;jump 00
	dc.w		130				;jump 01
	dc.w		4				;jump 02
	dc.w		94				;point 00
	dc.w		94				;point 01
	dc.w		88				;wait 00
	dc.w		92				;wait 01
	dc.w		92				;wait 02
	dc.w		92				;walk 00
	dc.w		90				;walk 01
	dc.w		92				;walk 02
	dc.w		94				;walk 03
	dc.w		92				;walk 04
	dc.w		90				;walk 05
	dc.w		92				;walk 06
	dc.w		94				;walk 07
sm_data::
	dc.l		lot_jm00			;jump 00
	dc.l		lot_jm01			;jump 01
	dc.l		lot_jm02			;jump 02
	dc.l		lot_pt00			;point 00
	dc.l		lot_pt01			;point 01
	dc.l		lot_wt00			;wait 00
	dc.l		lot_wt01			;wait 01
	dc.l		lot_wt02			;wait 02
	dc.l		lot_wk00			;walk 00
	dc.l		lot_wk01			;walk 01
	dc.l		lot_wk02			;walk 02
	dc.l		lot_wk03			;walk 03
	dc.l		lot_wk04			;walk 04
	dc.l		lot_wk05			;walk 05
	dc.l		lot_wk06			;walk 06
	dc.l		lot_wk07			;walk 07

act_chg::
;number of frames to wait before changing act_stps
	dc.w		100				;wait
	dc.w		15				;tap
	dc.w		6				;walk
	dc.w		100				;point L
	dc.w		100				;point R
	dc.w		10				;jump
act_stps::
;total steps in each animation cycle
	dc.w		1				;wait
	dc.w		2				;tap
	dc.w		8				;walk
	dc.w		1				;point L
	dc.w		1				;point R
	dc.w		10				;jump
sm_frms::
	dc.b		 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0		;wait
	dc.b		 6, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0		;tap
	dc.b		 8, 9,10,11,12,13,14,15, 0, 0, 0, 0, 0, 0, 0, 0		;walk
	dc.b		 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0		;point L
	dc.b		 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0		;point R
	dc.b		 0, 1, 2, 2, 1, 0, 1, 2, 2, 1, 0, 0, 0, 0, 0, 0		;jump

sm_def_x::
;starting X positions for salesman when screen appears depending on cur_car0 or cur_car1
	dc.w		LEFT_PT_LEFT			;for left car
	dc.w		MID_PT_RIGHT			;for middle car
	dc.w		RIGHT_PT_RIGHT			;for right car
sm_def_d::
;starting directions for salesman when screen appears depending on cur_car0 or cur_car1
	dc.w		LEFT					;for left car
	dc.w		RIGHT				;for middle car
	dc.w		RIGHT				;for right car
sm_def_f::
;starting O_FLAGS setting for salesman when screen appears depending on cur_car0 or cur_car1
	dc.b		HFLIP_OFF|TRANS_ON		;for left car
	dc.b		HFLIP_ON|TRANS_ON		;for middle car
	dc.b		HFLIP_ON|TRANS_ON		;for right car

	.even

lotolst::
;lot_scr::
	dc.w		0			;xpos
	dc.w		0			;ypos
	dc.l		lotscr		;data
	dc.w		287			;height
	dc.w		80			;dwidth
	dc.w		80			;iwidth
	dc.b		0			;flags
	dc.b		0			;firstpix
	dc.b		0			;type
	dc.b		4			;depth
	dc.b		1			;pitch
	dc.b		0			;index
	dc.w		0			;desc
	dc.l		$00202020		;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------
;lot_man::
	dc.w		100			;xpos
	dc.w		0			;ypos
	dc.l		lot_jm00		;data
	dc.w		96			;height
	dc.w		20			;dwidth
	dc.w		20			;iwidth
	dc.b		TRANS_ON		;flags
	dc.b		0			;firstpix
	dc.b		0			;type
	dc.b		4			;depth
	dc.b		1			;pitch
	dc.b		0			;index
	dc.w		0			;desc
	dc.l		$00202020		;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------

