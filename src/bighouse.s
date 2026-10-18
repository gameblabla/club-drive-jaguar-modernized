	include	"map.cry"

bighouse_start:
	dc.l	sitrm_head,$02d10000,$008b0000,$02f6b000
	dc.w	$400
	dc.l	sitrm_head,$02b81000,$008b0000,$02f6b000
	dc.w	$400
	dc.w	$1a0,$1a0	; y and x scales for map
	dc.w	14,159		; center for map
	dc.l	housanim	; animation function

	.globl	dninrm_head
	.globl	foyer_head
	.globl	hallway_head
	.globl	fmlyrm_head
	.globl	kitchen_head
	.globl	lav1_head
	.globl	lav2_head
	.globl	lndryrm_head
	.globl	sitrm_head
	.globl	stairway_head
	.globl	study_head

	.include	'dninrm.mdl'
	.include	'foyer.mdl'
	.include	'hallway.mdl'
	.include	'fmlyrm.mdl'
	.include	'kitchen.mdl'
	.include	'lav1.mdl'
	.include	'lav2.mdl'
	.include	'lndryrm.mdl'
	.include	'sitrm.mdl'
	.include	'stairway.mdl'
	.include	'study.mdl'

	.include	'dninr_l1.mdl'
	.include	'foyer_l1.mdl'
	.include	'hallw_l1.mdl'
	.include	'fmlyr_l1.mdl'
	.include	'kitch_l1.mdl'
	.include	'lav1_l1.mdl'
	.include	'lav2_l1.mdl'
	.include	'lndry_l1.mdl'
	.include	'sitrm_l1.mdl'
	.include	'stair_l1.mdl'
	.include	'study_l1.mdl'

	.include	'dninr_l2.mdl'
	.include	'foyer_l2.mdl'
	.include	'fmlyr_l2.mdl'
	.include	'kitch_l2.mdl'
	.include	'lav1_l2.mdl'
	.include	'lav2_l2.mdl'
	.include	'lndry_l2.mdl'
	.include	'sitrm_l2.mdl'
	.include	'study_l2.mdl'

	.include	'dninr_l3.mdl'
	.include	'foyer_l3.mdl'
	.include	'fmlyr_l3.mdl'
	.include	'kitch_l3.mdl'
	.include	'lav1_l3.mdl'
	.include	'lndry_l3.mdl'
	.include	'sitrm_l3.mdl'
	.include	'study_l3.mdl'

	.include	'medwr.mdl'
	.include	'cat.mdl'
	.include	'maus.mdl'
	.phrase

textures:
	dc.l	$20000		; screen_addr
	dc.l	$34220		; XADDINC|WID320|PIXEL16
	dc.w	320,180

	dc.l	fplace
	dc.l	$33220
	dc.w	80,50

	dc.l	chkflag1
	dc.l	$32620		; XADDINC|WID28|PIXEL16
	dc.w	28,4

	dc.l	chkflag2
	dc.l	$31020		; XADDINC|WID4|PIXEL16
	dc.w	4,24

	.extern	gpuhouse
	dc.l	'IGPU'			; validating magic (IGPU == "initialized GPU function")
housanim:
	dc.l	gpuhouse		; GPU animation program
	dc.l	param			; parameter for animation program
	dc.l	maus_head		; mobile band list (null terminated)
	dc.l	cat_head
	dc.l	0
	dc.l	housinit		; initialization function

housinit:
	move.l	#1,param+4		; initialize seed for random number generator
	move.l	#mausrec+300,mp		; initialize mouse playback head
	move.l	#0,mp+4
	move.l	#catrec+300,cp		; initialize cat playback head
	move.l	#0,cp+4
	rts

	.extern	mausrec,mausrecx
	.extern	catrec,catrecx
	.long
param:
	dc.l	textures
	dc.l	1		; seed for random number generator
	dc.l	maus_head
	dc.l	mausrec
	dc.l	mausrecx
mp:	dc.l	mausrec		; playback head
	dc.l	0		; elapsed time
	dc.l	cat_head
	dc.l	catrec
	dc.l	catrecx
cp:	dc.l	catrec		; playback head
	dc.l	0		; elapsed time

	.phrase
topline:
	dcb.w	80,$f000
fplace:
	dcb.w	4000,$f000
botlines:
	dcb.w	480,$f000

	.phrase
; 28x4 checkered flag pattern
chkflag1:
	dc.w	$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0
	dc.w	$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0
	dc.w	$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0
	dc.w	$0000,$78f0,$0000,$78f0
	dc.w	$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000
	dc.w	$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000
	dc.w	$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000
	dc.w	$78f0,$0000,$78f0,$0000
	dc.w	$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0
	dc.w	$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0
	dc.w	$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0
	dc.w	$0000,$78f0,$0000,$78f0
	dc.w	$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000
	dc.w	$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000
	dc.w	$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000
	dc.w	$78f0,$0000,$78f0,$0000

	.phrase
; 4x24 checkered flag pattern
chkflag2:
	dc.w	$0000,$78f0,$0000,$78f0,$78f0,$0000,$78f0,$0000
	dc.w	$0000,$78f0,$0000,$78f0,$78f0,$0000,$78f0,$0000
	dc.w	$0000,$78f0,$0000,$78f0,$78f0,$0000,$78f0,$0000

	dc.w	$0000,$78f0,$0000,$78f0,$78f0,$0000,$78f0,$0000
	dc.w	$0000,$78f0,$0000,$78f0,$78f0,$0000,$78f0,$0000
	dc.w	$0000,$78f0,$0000,$78f0,$78f0,$0000,$78f0,$0000

	dc.w	$0000,$78f0,$0000,$78f0,$78f0,$0000,$78f0,$0000
	dc.w	$0000,$78f0,$0000,$78f0,$78f0,$0000,$78f0,$0000
	dc.w	$0000,$78f0,$0000,$78f0,$78f0,$0000,$78f0,$0000

	dc.w	$0000,$78f0,$0000,$78f0,$78f0,$0000,$78f0,$0000
	dc.w	$0000,$78f0,$0000,$78f0,$78f0,$0000,$78f0,$0000
	dc.w	$0000,$78f0,$0000,$78f0,$78f0,$0000,$78f0,$0000


	.long
cam0:
	dc.l	0,0,0,0
	dc.l	sitrm_head,$0131a000,$00281000,$024ce000
cam1:
	dc.l	0,0,0,0
	dc.l	dninrm_head,$ff6db000,$00281000,$01bfb000
cam2:
	dc.l	0,0,0,0
	dc.l	fmlyrm_head,$fe468000,$002db000,$02c5e000
cam3:
	dc.l	0,0,0,0
	dc.l	kitchen_head,$fdd8b000,$00318000,$ff7f9000
cam4:
	dc.l	0,0,0,0
	dc.l	lndryrm_head,$fe382000,$00281000,$fdedb000
cam5:
	dc.l	0,0,0,0
	dc.l	foyer_head,$01fd1000,$00281000,$003c1000
cam6:
	dc.l	0,0,0,0
	dc.l	hallway_head,$0028a000,$00281000,$00a78000
cam7:
	dc.l	0,0,0,0
	dc.l	study_head,$ff583000,$00381000,$fd617000
cam8:
	dc.l	0,0,0,0
	dc.l	lav1_head,$fe6b5000,$00381000,$fd1c0000
cam9:
	dc.l	0,0,0,0
	dc.l	lav2_head,$0077d000,$00601000,$ff5f2000
cascam:
	dc.l	0,0,0,0
	dc.l	medwr_head,$113be000,$00001000,$11346000
