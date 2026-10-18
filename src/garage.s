;
; arena data area: garage
;
	.include	"garage.cry"
garage_start:
	dc.l	garage_head,$ffc16900,$001d4000,$007db94f	; ORIGIN
	dc.w	$400
	dc.l	garage_head,$ffd73000,$001d4000,$ffc28000	; ORIGIN
	dc.w	0
	dc.w	$0cc0,$0cc0	; y and x scales for map
	dc.w	$0d,$9e		; center for map

.if 1
	dc.l	garaanim	; animation function
.else
	dc.l	0
.endif

	.phrase
; offset 48: list of 64 locations where powerballs may appear
dots:
	dc.l	garage_head,$0049CF45,$001D05AE,$0078E41C
	dc.l	garage_head,$ffd6e0f4,$001d0591,$005d1eca
	dc.l	garage_head,$ffa23337,$001bb802,$0048d191
	dc.l	garage_head,$001f7e45,$001d0506,$000027db
	dc.l	garage_head,$003CA101,$001D0550,$FF96A63D
	dc.l	garage_head,$0058466B,$0019A84B,$FFBE8F30
	dc.l	garage_head,$FFDD201A,$001D051D,$001B205E
	dc.l	garage_head,$FFD1B9AC,$001D050E,$FF8A7B5A

	dc.l	garage_head,$FF9B04A2,$001D061C,$FF6A64F7
	dc.l	garage_head,$FF9E2F7F,$000FD64B,$FF660E2E
	dc.l	garage_head,$0049BB5B,$000FD51E,$FF7A9D3C
	dc.l	garage_head,$004B0845,$000FD5CA,$0075A720
	dc.l	garage_head,$FFF66118,$000FD544,$0066F4AD
	dc.l	garage_head,$00037B6A,$000FD55C,$00521159
	dc.l	garage_head,$FFE60095,$000FD51F,$FFD15DFD
	dc.l	garage_head,$FFBE168C,$000FD54D,$004FBC67

	dc.l	garage_head,$0037C3F4,$001D0521,$0026EB60
	dc.l	garage_head,$FFFFD7B1,$001D04FF,$00071FF4
	dc.l	garage_head,$FFE076AD,$001D04FF,$FFF2D5B5
	dc.l	garage_head,$FFBBFDE9,$001D0524,$002A2037
	dc.l	garage_head,$FFC95FC7,$001D0596,$005ED884
	dc.l	garage_head,$FFD73C03,$001D0643,$0081D599
	dc.l	garage_head,$FFD4C119,$001D063B,$FF6A502E
	dc.l	garage_head,$000AC114,$001D05B3,$FF6253DA

	dc.l	garage_head,$003800C9,$001D0644,$FF65576E
	dc.l	garage_head,$FFF5BC94,$000FD54C,$0062E4D0
	dc.l	garage_head,$0002B6AC,$000FD50E,$FFC7E9FF
	dc.l	garage_head,$FFC2FC0E,$000FD510,$0031FD32
	dc.l	garage_head,$00388E8C,$000FD501,$FFD18272
	dc.l	garage_head,$FFBB088F,$000FD531,$FFD8FD4B
	dc.l	garage_head,$FF9A2082,$000FD5A1,$0078B66A
	dc.l	garage_head,$FFA66506,$000FD600,$00777726

	dc.l	garage_head,$FFE54A27,$000FD565,$004D392A
	dc.l	garage_head,$000805AE,$001D05B2,$002756BA
	dc.l	garage_head,$00164C4F,$001D053A,$0003AD4D
	dc.l	garage_head,$0033C75D,$001D04F3,$FF9E654B
	dc.l	garage_head,$00104362,$001D054F,$FF815385
	dc.l	garage_head,$FFF2B469,$001D0571,$FF6036A1
	dc.l	garage_head,$FFCFE323,$001D05FB,$FF6AA418
	dc.l	garage_head,$003053B7,$001D0524,$003B2787

	dc.l	garage_head,$0042B977,$001D052F,$0069F4A5
	dc.l	garage_head,$FFDAC547,$001D0541,$005FB3F0
	dc.l	garage_head,$FF9D263A,$0016B946,$FFFB21D0
	dc.l	garage_head,$006061FA,$00125D21,$002F89D5
	dc.l	garage_head,$FFF3F207,$000FD561,$005406A0
	dc.l	garage_head,$FF9A56D3,$000FD5BB,$008611EB
	dc.l	garage_head,$0004B80B,$001D054C,$005DC804
	dc.l	garage_head,$0047A663,$001D0655,$FF60DEE8

	dc.l	garage_head,$FFBBFD96,$001D0530,$FF8D6C38
	dc.l	garage_head,$FFC55D71,$001D0550,$FFD3DA00
	dc.l	garage_head,$003B7411,$001D064A,$007FA819
	dc.l	garage_head,$FFC0FE48,$001D04D0,$0012A653
	dc.l	garage_head,$FFEB5CA3,$000FD4C4,$FFD7AB60
	dc.l	garage_head,$00129CE3,$000FD542,$004DFEEB
	dc.l	garage_head,$0012B4FA,$001D04FF,$FFF7B68C
	dc.l	garage_head,$00442DE8,$001D051A,$FFA8DC68

	dc.l	garage_head,$FF9767F8,$00119312,$FFAB558B
	dc.l	garage_head,$FFFE9346,$001D049A,$001EC258
	dc.l	garage_head,$FFF39946,$001D05EA,$00726A8F
	dc.l	garage_head,$FFA12A19,$000FD5A4,$FF5E6E62
	dc.l	garage_head,$005F746E,$00141727,$0014DB6F
	dc.l	garage_head,$005E5CA7,$0017FC33,$FFD84A5D
	dc.l	garage_head,$000A9389,$000FD582,$002997DF
	dc.l	garage_head,$FFC156A7,$000FD805,$0039EBD0

	.phrase
	include	'garage.mdl'

	.phrase
	include	'drone.mdl'

	.phrase
	include 'sign_cl.cry'
	include 'sign_pk.cry'
	include 'sign_ul.cry'

textures:
	dc.l	sign_cl
	dc.l	$33020		; XADDINC | WID64 |PIXEL16
	dc.w	64,22

	dc.l	sign_pk
	dc.l	$32c20		; XADDINC | WID48 |PIXEL16
	dc.w	48,64

	dc.l	sign_ul
	dc.l	$32820		; XADDINC | WID32 |PIXEL16
	dc.w	32,39

	.extern	gpugara
	dc.l	'OGPU'		; validating magic for initialized GPU function (1 player only)
garaanim:
	dc.l	gpugara		; GPU animation program
	dc.l	parmblock	; parameter for animation
	dc.l	drone_head	; list of mobile bands
	dc.l	0
	dc.l	garainit	; initilization function

garainit:
	move.l	#gararec,gp	; initialize playback head
	move.l	#0,gp+4
	rts

	.extern	gararec,gararecx
	.long
parmblock:
	dc.l	drone_head
	dc.l	gararec		; begin recording
	dc.l	gararecx	; end recording
gp:	dc.l	gararec		; playback head
	dc.l	0		; elapsed time

	.long
cameras:
	dc.l	0,$7fff,0,$fff50016
	dc.l	garage_head,$fffcb000,$0016f000,$fff15000
	dc.l	0,0,0,0
	dc.l	garage_head,$fffcb000,$00101000,$fff15000
