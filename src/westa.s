;
; arena data area: west
;

	.include	"west.cry"
west_start:
	dc.l	west_head,$ffe25000,$0009a800,$00ac0d00	; PLAYER1 start
	dc.w	$400
	dc.l	west_head,$ffc7a000,$0009a800,$ff515000	; PLAYER2 start
	dc.w	0
	dc.w	$800,$800		; y and x scales for map
	dc.w	$c,$a0			; center for map
	dc.l	0			; animation function

dots:
	dc.l	west_head,$ff777549,$000AA604,$ff47af64
	dc.l	west_head,$FF93B7E3,$000AA5EC,$ff4cd6fb
	dc.l	west_head,$FFB8E956,$000AA5DD,$ff3b0028
	dc.l	west_head,$FFFA4ACB,$000AA622,$ff393e5d
	dc.l	west_head,$002B22C6,$000AA5E3,$ff5f50de
	dc.l	west_head,$005CEB16,$000AA962,$ff9c6ddb
	dc.l	west_head,$00349271,$000AA8FE,$ff9a59ff
	dc.l	west_head,$FFFB140B,$000AA8FE,$ff973a61
; 8
	dc.l	west_head,$FFDD1625,$000AA8FE,$ff95bedc
	dc.l	west_head,$FFB15244,$000AA8FE,$ff937200
	dc.l	west_head,$FF8BD993,$000AA8FE,$ff9191df
	dc.l	west_head,$FF5B9CB0,$000AA504,$ffa49421
	dc.l	west_head,$FF8B1775,$000AA515,$ffabb212
	dc.l	west_head,$FF86CB40,$000AA538,$ffdca392
	dc.l	west_head,$FF666C2F,$000AA5A9,$fff61bf1
	dc.l	west_head,$FFAAF272,$000AA593,$ffdcb13d
; 16
	dc.l	west_head,$FF8C2EFE,$000AA518,$00030ae2
	dc.l	west_head,$FF942B2A,$000AA5D5,$0024d8ff
	dc.l	west_head,$FF949A59,$000AA553,$00594863
	dc.l	west_head,$FF7D1B7A,$000AA50C,$0075034d
	dc.l	west_head,$FFA01D5E,$000AA65B,$00990447
	dc.l	west_head,$FFFCB606,$000AA60A,$00b546bd
	dc.l	west_head,$003409CC,$000AA5FA,$0088a854
	dc.l	west_head,$003E1232,$000AA55A,$00626194
; 24
	dc.l	west_head,$0004143B,$000AA557,$0065e7ad
	dc.l	west_head,$FFD19018,$000AA5A7,$004daa1b
	dc.l	west_head,$FFB0D4E5,$000AA500,$004364d8
	dc.l	west_head,$FFB4E7F2,$000AA501,$0021a77c
	dc.l	west_head,$FFAFCDE3,$000AA592,$ffed4398
	dc.l	west_head,$FFAE7179,$000AA48E,$ffc62ed4
	dc.l	west_head,$FFF26DEA,$000AA5D4,$ffb3c3ae
	dc.l	west_head,$FFEE9000,$000AA554,$0006b219
; 32
	dc.l	west_head,$FFF29B34,$000AA53B,$003c6f4e
	dc.l	west_head,$FFD53B72,$000AA4A8,$fffacbad
	dc.l	west_head,$FFDDE558,$000AA551,$ffb0c46d
	dc.l	west_head,$FFE53C33,$000AA50E,$fffb0f06
	dc.l	west_head,$FFF42ABA,$000AA514,$0030e4c8
	dc.l	west_head,$FFC36530,$000AA5EC,$00783f7b
	dc.l	west_head,$FFB7114B,$000AA595,$0024f380
	dc.l	west_head,$FFB2459D,$000AA51E,$ffd27980
; 40
	dc.l	west_head,$FFB3BDE0,$000AA54D,$ff8f2d60
	dc.l	west_head,$FFDD7560,$000AA5B1,$ff6474c0
	dc.l	west_head,$00165100,$000AA5C8,$ff8fe689
	dc.l	west_head,$FFF5FF2B,$000AA812,$ffe09442
	dc.l	west_head,$FFF2D098,$000AA49A,$001449dd
	dc.l	west_head,$FFF26DA4,$000AA53F,$00428429
	dc.l	west_head,$FFD2AF9B,$000AA515,$00666bf6
	dc.l	west_head,$001E5C99,$000AA604,$0080d715
; 48
	dc.l	west_head,$002A5B91,$000AA548,$0057d519
	dc.l	west_head,$002ED459,$000AA5C4,$002c33b9
	dc.l	west_head,$003095CE,$000AA5DA,$ffe44019
	dc.l	west_head,$001D8556,$000AA5BE,$ffa52fb9
	dc.l	west_head,$005FB318,$000AA597,$ff86d247
	dc.l	west_head,$FF8D9324,$000AA5C8,$0009f1c7
	dc.l	west_head,$FFF05A2B,$000AA56C,$ffd89d7f
	dc.l	west_head,$FFAF5BBC,$000AA4E5,$fffd8034
; 56
	dc.l	west_head,$FFC1D62C,$000AA5A4,$ffa0033f
	dc.l	west_head,$FFD368EB,$000AA5CB,$ff2ddb97
	dc.l	west_head,$002B892B,$000AA551,$0005ed94
	dc.l	west_head,$FF65F277,$000AA5B1,$ffc8a380
	dc.l	west_head,$FFB9952F,$000AA59C,$0019d593
	dc.l	west_head,$FFE8EF69,$000AA5B3,$005775e2
	dc.l	west_head,$0019B351,$000AA581,$006136e1
	dc.l	west_head,$00228B98,$000AA511,$ffde05a4
; 64
	.phrase
	include	'west.mdl'

	.phrase
	include 'chic.cry'
	include 'saloon.cry'

textures:
	dc.l	chic
	dc.l	$33020		; XADDINC | WID64 |PIXEL16
	dc.w	64,97

	dc.l	saloon
	dc.l	$33420		; XADDINC | WID96 |PIXEL16
	dc.w	96,53

	.long
cameras:
	dc.l	$8001,0,0,$ffd00060
	dc.l	west_head,$ff64c000,$00031000,$ff55d000
	dc.l	$7fff,0,0,$fff9800d
	dc.l	west_head,$00428000,$00031000,$ff717000
	dc.l	0,0,0,0
	dc.l	west_head,$ffaf5000,$00031000,$000cc000
