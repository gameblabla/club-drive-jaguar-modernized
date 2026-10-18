;
; arena data area: future4
;

	.include	"future4.cry"
future4_start:
	dc.l	future4_head,$005e5400,$0023b000,$0314e300	; ORIGIN
	dc.w	$600
	dc.l	future4_head,$ffe36900,$0023df00,$03116300	; ORIGIN
	dc.w	$200
	dc.w	$0650,$12c0		; y and x scales for map
	dc.w	$c,$0107		; center for map

	dc.l	0			; animation function

; offset 48: list of 64 locations where powerballs may appear

dots:
	dc.l	future4_head,$00B173EF,$0024365E,$0290079E
	dc.l	future4_head,$FFEEAD38,$00297D0D,$02BC8482
	dc.l	future4_head,$FF721330,$0024351E,$02C98A31
	dc.l	future4_head,$FF216C92,$00242F94,$0306CD55
	dc.l	future4_head,$FF6E7555,$0009E995,$034EE68A
	dc.l	future4_head,$0090ED2C,$FFF185FD,$0372D061
	dc.l	future4_head,$00A03355,$0012B5B0,$02970A3D
	dc.l	future4_head,$FFEE9618,$0018B4FF,$02CE54F4
; 8
	dc.l	future4_head,$FF1F875D,$001387AF,$02433ABC
	dc.l	future4_head,$FF8AC321,$0021958E,$02E859C1
	dc.l	future4_head,$FFE05046,$0022EE73,$031C742A
	dc.l	future4_head,$FF4F3177,$0024360D,$02936BD4
	dc.l	future4_head,$001898F9,$00087BCE,$0237DF97
	dc.l	future4_head,$006D589F,$002435BB,$02EFFFBE
	dc.l	future4_head,$FF8289B8,$0024352D,$028E316F
	dc.l	future4_head,$0026267C,$00243414,$02B4F269
; 16
	dc.l	future4_head,$FF1FEA13,$FFF185BA,$03790BBD
	dc.l	future4_head,$FF99F033,$FFF1860F,$0377D9FB
	dc.l	future4_head,$0048DC53,$FFF185FB,$03761F08
	dc.l	future4_head,$00BC56EF,$FFF185A3,$0374D471
	dc.l	future4_head,$00B2F2CA,$0018199B,$033DB608
	dc.l	future4_head,$0051AAA6,$0015FEF1,$0341128A
	dc.l	future4_head,$FF1E51E7,$FFF1860F,$0217CAB4
	dc.l	future4_head,$FFA6298E,$00123B5E,$0346CD08
; 24
	dc.l	future4_head,$FF2158FD,$000ED066,$034ACBEB
	dc.l	future4_head,$FF334B74,$0021C404,$0322F1B4
	dc.l	future4_head,$FF75D4F4,$0022004F,$0321A692
	dc.l	future4_head,$FFC099D4,$002246EE,$03202A53
	dc.l	future4_head,$FFF3ADD4,$002276ED,$031F2694
	dc.l	future4_head,$FF60BDCC,$FFF18577,$0223650A
	dc.l	future4_head,$0080C9D9,$00226819,$031F773B
	dc.l	future4_head,$00BCF8AB,$00237EE1,$031753AC
; 32
	dc.l	future4_head,$FFFFAF29,$FFF1861B,$02219091
	dc.l	future4_head,$005B1257,$002435B2,$03073AD1
	dc.l	future4_head,$0022DE6A,$00243509,$03068B63
	dc.l	future4_head,$FFE9034B,$002346B3,$0301B117
	dc.l	future4_head,$FFA6DF78,$00243550,$0302BFB7
	dc.l	future4_head,$FF6034FA,$002435D4,$03018554
	dc.l	future4_head,$FF1F9D76,$002435E4,$02F002F8
	dc.l	future4_head,$FF65879D,$00243646,$02ED3317
; 40
	dc.l	future4_head,$FFF36B30,$001EC583,$02EDF684
	dc.l	future4_head,$005D3170,$002436EC,$02F4318A
	dc.l	future4_head,$007C23AD,$FFF18613,$02189B26
	dc.l	future4_head,$00BEFE26,$002435C6,$02C69F7E
	dc.l	future4_head,$00A460AA,$002435E6,$02AE2631
	dc.l	future4_head,$0048E686,$0024355B,$02AE3FA7
	dc.l	future4_head,$001E0EFE,$0024340B,$02B54620
	dc.l	future4_head,$FF9173F7,$00243552,$02BFE4A0
; 48
	dc.l	future4_head,$FF55484E,$0024365C,$02C42680
	dc.l	future4_head,$FF1F9EB7,$0024358F,$02B3C277
	dc.l	future4_head,$FF2344A5,$002435AA,$0287C9D5
	dc.l	future4_head,$FF3428BB,$001B4CEB,$0250F895
	dc.l	future4_head,$FF205EF4,$00192803,$024C43ED
	dc.l	future4_head,$FFBC41A6,$0024359A,$02A69F52
	dc.l	future4_head,$000BB184,$0018B4FF,$02D4F0DA
	dc.l	future4_head,$FFF4D213,$0018B4CB,$02B95FFD
; 56
	dc.l	future4_head,$0071B2A0,$0024358F,$02B3F025
	dc.l	future4_head,$00479D0E,$0024349E,$02815419
	dc.l	future4_head,$009692AB,$002435F5,$028FB6BB
	dc.l	future4_head,$00BD0D5B,$002435ED,$02824BC4
	dc.l	future4_head,$00A0F968,$001D169C,$025548E3
	dc.l	future4_head,$00110DD0,$001FD290,$025C4DDE
	dc.l	future4_head,$FFAF1093,$001D1AB3,$02554FE9
	dc.l	future4_head,$00A9BEC3,$0004AC1F,$02351826
; 64
	.phrase
	include	'future4.mdl'
	include	'atari.cry'

textures:
	dc.l	atari		; screen_addr
	dc.l	$33020		; XADDINC|WID64|PIXEL16
	dc.w	64,24
