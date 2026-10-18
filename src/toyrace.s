;
; arena data area: toyrace
;
.phrase
	.include	"toyrace.cry"
toyr_start:
	dc.l	toyrp1_head,$0086eb75,$fff4dfdd,$fee7ed66	;start
	dc.w	$56d
	dc.l	toyrp1_head,$008a14aa,$fff3d770,$feda8347	;start
	dc.w	$56d
	dc.w	$880,$880		; y and x scales for map
	dc.w	$f,$9d			; center for map
	dc.l	0			; animation function

	.phrase
	include	'toyrp1.mdl'
	include	'toyrp2.mdl'
	include	'toyrp3.mdl'
	include	'toyrp1l2.mdl'
	include	'toyrp3l2.mdl'

	.phrase
textures:
	dc.l	chkflag1
	dc.l	$31020		; XADDINC|WID4|PIXEL16
;	dc.l	$32420		; XADDINC|WID24|PIXEL16
	dc.w	4,24

	.phrase
; 4x24 checkered flag pattern
chkflag1:
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

arf:
	dc.l	0,0,$7fff,	$ffff8001
	dc.l toyrp3_head,	$003aa06b, $ff7e1500, $007b3000
	dc.l	-8213,0,14176, 1165257
	dc.l toyrp1_head,	$ff62ab28, $ffdcc580, $ff7bed00
	dc.l	0,0,0,	0
	dc.l toyrp1_head,	$00254988,$ff56c000,$ff462400
	