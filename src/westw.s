	.include	'map.cry'

west_start:
	dc.l	edstown_head,$fde60000,$001b7e00,$f652e000	; PLAYER1 start
	dc.w	$200						; player 1 starting angle
	dc.l	edstown_head,$fde7a000,$001b7e00,$f6480000	; PLAYER2 start
	dc.w	$200						; player 2 starting angle
	dc.w	$01c0,$0240	; y and x scales for map
	dc.w	$0e,$a0		; center for map

	dc.l	0		; animation function

	.include	'bigeasy1.mdl'
	.include	'bigeasy2.mdl'
	.include	'bigeasy3.mdl'
	.include	'bigeasy4.mdl'
	.include	'bigeasy5.mdl'
	.include	'boothill.mdl'
	.include	'crsrds_e.mdl'
	.include	'crsrds_n.mdl'
	.include	'crsrds_s.mdl'
	.include	'crsrds_w.mdl'
	.include	'edstown.mdl'
	.include	'flnarch1.mdl'
	.include	'flnarch2.mdl'
	.include	'flnarch3.mdl'
	.include	'flnarch4.mdl'
	.include	'flnarch5.mdl'
	.include	'flnarch6.mdl'
	.include	'flnarch7.mdl'
	.include	'hilo_rd1.mdl'
	.include	'hilo_rd2.mdl'
	.include	'hilo_rd3.mdl'
	.include	'hilo_rd4.mdl'
	.include	'injncnty.mdl'
	.include	'kenstown.mdl'
	.include	'lone_n.mdl'
	.include	'lone_ne.mdl'
	.include	'lone_sw.mdl'
	.include	'lone_ssw.mdl'
	.include	'msquez_1.mdl'
	.include	'msquez_2.mdl'
	.include	'msquez_3.mdl'
	.include	'msquez_4.mdl'
	.include	'rockyrd1.mdl'
	.include	'rockyrd2.mdl'
	.include	'rockyrd3.mdl'
	.include	'rockyrd4.mdl'
	.include	'sidew_a.mdl'
	.include	'sidew_b.mdl'
	.include	'sidew_c.mdl'
	.include	'sidew_d.mdl'
	.include	'sidew_e.mdl'
	.include	'sidew_f.mdl'
	.include	'tnnl_n_c.mdl'
	.include	'tnnl_n1a.mdl'
	.include	'tnnl_n2a.mdl'
	.include	'tnnl_n2b.mdl'
	.include	'tnnl_n2c.mdl'
	.include	'tnnl_n3a.mdl'
	.include	'tnnl_n3b.mdl'
	.include	'tnnl_n3c.mdl'
	.include	'tnnl_s_c.mdl'
	.include	'tnnl_s1a.mdl'
	.include	'tnnl_s2a.mdl'
	.include	'tnnl_s2b.mdl'
	.include	'tnnl_s2c.mdl'
	.include	'tnnl_s3a.mdl'
	.include	'tnnl_s3b.mdl'
	.include	'tnnl_s3c.mdl'
	.include	'tnnl_s3d.mdl'
	.include	'tnnl_s3e.mdl'
	.include	'tnnl_s3f.mdl'
	.include	'whtwtr1.mdl'
	.include	'whtwtr2.mdl'
	.include	'whtwtr3.mdl'
	.include	'whtwtr4.mdl'
	.include	'whtwtr5.mdl'

	.include	'atari.mdl'
	.include	'dinowr.mdl'

; low detail versions of stuff
	.include	'tnnls3fl.mdl'

	.phrase
	include		'chic.cry'
	include		'atari.cry'

	.phrase
; 24x4 checkered flag pattern
chkflag1:
	dc.w	$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0
	dc.w	$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0
	dc.w	$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0
	dc.w	$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000
	dc.w	$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000
	dc.w	$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000
	dc.w	$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0
	dc.w	$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0
	dc.w	$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0
	dc.w	$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000
	dc.w	$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000
	dc.w	$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000

	.phrase
textures:
	dc.l	chkflag1
	dc.l	$32420		; XADDINC|WID24|PIXEL16
	dc.w	24,4

	dc.l	chic
	dc.l	$33020		; XADDINC | WID64 |PIXEL16
	dc.w	64,97

	dc.l	atari		;
	dc.l	$33020		; XADDINC|WID64|PIXEL16
	dc.w	64,24

	.long
ataricam:
	dc.l	0,0,0,0
	dc.l	atari_head,$ff65e000,$00001000,$012aa000
