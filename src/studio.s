;
; arena data area: studio
;
	.include	"studio.cry"
studio_start:
	dc.l	studio_head,$ff803a0a,$001f0000,$0046a8b5	; PLAYER1 start
	dc.w	600
	dc.l	studio_head,$003e2b6d,$001f0000,$00192dd5	; PLAYER2 start
	dc.w	-600
	dc.w	$880,$f00	; y and x scales for map
	dc.w	13,161		; center for map

	dc.l	studanim	; animation function

dots:
	dc.l	studio_head,$FF7796B6,$00325612,$00C532CB
	dc.l	studio_head,$FFD2A536,$003255E4,$00D9F874
	dc.l	studio_head,$000A75D6,$003255AA,$00D72D9A
	dc.l	studio_head,$005F8A56,$003255E2,$00DBAAE4
	dc.l	studio_head,$0082A240,$00325655,$00C70707
	dc.l	studio_head,$003343F4,$0032565B,$00B640AD
	dc.l	studio_head,$FFE0E23A,$00325617,$00A57137
	dc.l	studio_head,$FF9C3396,$00325542,$00743FB0
; 8
	dc.l	studio_head,$0017725F,$0032553F,$004760E7
	dc.l	studio_head,$0071F7F5,$0032554F,$002D4405
	dc.l	studio_head,$00566F3E,$0032557B,$000C26F2
	dc.l	studio_head,$001918AD,$00325484,$000E5B5C
	dc.l	studio_head,$FFE1D995,$003254F5,$000DD125
	dc.l	studio_head,$FFB0C91A,$00325543,$000B4810
	dc.l	studio_head,$FF687FED,$00325CB5,$000498B8
	dc.l	studio_head,$FFA9EB93,$00325593,$FFE2B626
; 16
	dc.l	studio_head,$002CDD53,$00325511,$FFE03D2A
	dc.l	studio_head,$00780833,$0032557D,$FFD61D55
	dc.l	studio_head,$FFF83CF3,$003254F3,$FFD795D7
	dc.l	studio_head,$FFAACA35,$00325555,$FFD1820A
	dc.l	studio_head,$FF6E7942,$0032561A,$FFC806BE
	dc.l	studio_head,$00360A36,$00325534,$FFB9982E
	dc.l	studio_head,$0005FE59,$00325541,$FF934C69
	dc.l	studio_head,$007F2C24,$003255AC,$FF8FB557
; 24
	dc.l	studio_head,$FF97566B,$0032557A,$FFAA2E75
	dc.l	studio_head,$FF88A90B,$003254DE,$FF5BA964
	dc.l	studio_head,$FFD4B779,$00325569,$FF39CBAF
	dc.l	studio_head,$FFF42354,$00325574,$FF4BF3B5
	dc.l	studio_head,$00635CEC,$0032556D,$FF7A63AC
	dc.l	studio_head,$0046C7E7,$00325600,$FF2E529E
	dc.l	studio_head,$00073E07,$003255ED,$FF4491F5
	dc.l	studio_head,$FFC306E9,$0028DD38,$0051233E
; 32
	dc.l	studio_head,$FFB5CBD9,$0020256D,$FFFB6EFD
	dc.l	studio_head,$FFA74003,$00202542,$FFE00739
	dc.l	studio_head,$FFD26CFD,$00202481,$FFE130A4
	dc.l	studio_head,$FFD6005D,$002024F6,$FFFD1D65
	dc.l	studio_head,$FFD82933,$0020258F,$001D5F6D
	dc.l	studio_head,$FFC0915E,$002EEA62,$007B5112
	dc.l	studio_head,$00160B62,$00325505,$FFC72045
	dc.l	studio_head,$008C91DA,$003255FE,$FF8CCF45
; 40
	dc.l	studio_head,$0007453D,$0032593E,$FF8D1636
	dc.l	studio_head,$FFB4B19C,$003255A7,$FFE0529D
	dc.l	studio_head,$FFC5C8B7,$00325598,$FF88373A
	dc.l	studio_head,$0046BC61,$003255D5,$FF78A65C
	dc.l	studio_head,$00664F16,$00325616,$FF37EA9B
	dc.l	studio_head,$0042A3C0,$003255DF,$FF352CE8
	dc.l	studio_head,$FFBC5F55,$003255F6,$FF2E009C
	dc.l	studio_head,$FF900CB7,$00325657,$FF4FE875
; 48
	dc.l	studio_head,$FF9960A3,$003255E0,$FF86E350
	dc.l	studio_head,$003392D9,$00325536,$0054D725
	dc.l	studio_head,$FFF38DA6,$0032550E,$00384B30
	dc.l	studio_head,$FFC93A3D,$0032553B,$0055113E
	dc.l	studio_head,$00623370,$003255EA,$00903095
	dc.l	studio_head,$FFF6F0B5,$003255A4,$FFD67C9F
	dc.l	studio_head,$FFB56002,$00325608,$FF7C1DEB
	dc.l	studio_head,$FFFB5E87,$00325547,$000A8624
; 56
	dc.l	studio_head,$FFBAAFB0,$0032565A,$009C0873
	dc.l	studio_head,$FFC2D6AA,$0021312E,$002B5CF9
	dc.l	studio_head,$FFC2087C,$00202502,$FFDA0CDE
	dc.l	studio_head,$FFAC1636,$00202548,$FFDF3E18
	dc.l	studio_head,$FF8A3674,$0032563E,$FF839DAC
	dc.l	studio_head,$FFFDBB5D,$003255FA,$FF6CBC48
	dc.l	studio_head,$0053431D,$003255B9,$FF70940F
	dc.l	studio_head,$000949ED,$003255DD,$FF5011FF
; 64
	.phrase
	include	'studio.mdl'
	include 'window.cry'
	include 'tv.cry'

textures:
	dc.l	pongfield	; screen_addr
	dc.l	$33820		; XADDINC|WID128|PIXEL16
	dc.w	128,105

	dc.l	window
	dc.l	$3800|$30020		; WID128|(PITCH1|PIXEL16|XADDINC)
	dc.w	128,105

	dc.l	tv
	dc.l	$3800|$30020		; WID128|(PITCH1|PIXEL16|XADDINC)
	dc.w	128,105

	.extern	gpustud
	dc.l	'IGPU'			; validating magic
studanim:
	dc.l	gpustud			; GPU animation program
	dc.l	parmblock		; parameter for animation program
	dc.l	0			; mobile band list
	dc.l	studinit		; initialization function

studinit:
	rts

	.long
parmblock:
	dc.l	textures
	dc.w	15,20
	dc.w	113,20
	dc.w	24,30
	dc.w	3,2		; velocity

	.long
cameras:
	dc.l	0,0,$8001,$ffc1807d
	dc.l	studio_head,$ff862000,$00181000,$ff9e7000
	dc.l	0,0,0,0
	dc.l	studio_head,$0040f000,$00181000,$ffe19000

	.bss
	.phrase
pongfield:
	ds.w	128*105
