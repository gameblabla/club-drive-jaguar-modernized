;
; arena data area: garace
;
.phrase
	.include	"garacemp.cry"
garr_start:
	dc.l	garace_head,$fff8d000,$001d4000,$001fe000	; ORIGIN
	dc.w	$400
	dc.l	garace_head,$0025f000,$001d4000,$fff36000	; ORIGIN
	dc.w	0
	dc.w	$0b20,$0c60	; y and x scales for map
	dc.w	$10,$a0		; center for map
	dc.l	0

	.phrase
	include	'garace.mdl'

	.phrase
	include 'sign_cl.cry'
	include 'sign_pk.cry'
	include 'sign_ul.cry'

textures:
	dc.l	chkflag1
	dc.l	$31020		; XADDINC|WID4|PIXEL16
;	dc.l	$32420		; XADDINC|WID24|PIXEL16
	dc.w	4,24

	dc.l	sign_pk
	dc.l	$32c20		; XADDINC | WID48 |PIXEL16
	dc.w	48,64

	dc.l	sign_ul
	dc.l	$32820		; XADDINC | WID32 |PIXEL16
	dc.w	32,39

	dc.l	sign_cl
	dc.l	$33020		; XADDINC | WID64 |PIXEL16
	dc.w	64,22

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

cameras:
	dc.l	0,$7fff,0,$fff50016
	dc.l	garace_head,$fffcb000,$0016f000,$fff15000
	dc.l	0,0,0,0
	dc.l	garace_head,$fffcb000,$00101000,$fff15000
	dc.l	0,0,$7fff,	$ffff8001
	
