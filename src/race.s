;
; velocity park race world
;

	.include	"map.cry"
race_start:
	dc.l	race1_head,$fe654000,$0025a000,$03eba000	; ORIGIN
	dc.w	$200
	dc.l	race1_head,$fe654000,$0025a000,$03d18000	; ORIGIN
	dc.w	$200
	dc.w	$100,$100		; y and x scales for map
	dc.w	14,160		; center for map
	dc.l	0

	.include	"race1.mdl"
	.include	"race2.mdl"
	.include	"race3a.mdl"
	.include	"race3b.mdl"
	.include	"race4.mdl"
	.include	"race5a.mdl"
	.include	"race5b.mdl"
	.include	"race6.mdl"
	.include	"race7a.mdl"
	.include	"race7b.mdl"
	.include	"race8.mdl"
	.include	"race9.mdl"
	.include	"race10a.mdl"
	.include	"race10b.mdl"
	.include	"race11.mdl"
	.include	"race12a.mdl"
	.include	"race12b.mdl"
	.include	"race13.mdl"
	.include	"race14a.mdl"
	.include	"race14b.mdl"
	.include	"race15.mdl"
	.include	"race16a.mdl"
	.include	"race16b.mdl"
	.include	"ground.mdl"

	.phrase
textures:
	dc.l	chkflag1
	dc.l	$32420		; XADDINC|WID24|PIXEL16
	dc.w	24,4

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


cam1:
	dc.l	0,0,0,0
	dc.l	race1_head,$fef25000,$00065000,$03dc1000
cam2:
	dc.l	0,0,0,0
	dc.l	race2_head,$0168a000,$ffd81000,$03dc1000
cam8:
	dc.l	$7fff,$0,$0,$ff578151
	dc.l	race8_head,$02f4b2b8,$fff81000,$fc267000
cam9:
	dc.l	$7fff,$0,$0,$affea0
	dc.l	race8_head,$00219000,$fff81000,$fc267000
	dc.l	0,0,0,0
	dc.l	race9_head,$fd533000,$fff81000,$fc267000
cam11:
	dc.l	0,0,0,0
	dc.l	race11_head,$fda3c000,$ffd81000,$fecb2000
