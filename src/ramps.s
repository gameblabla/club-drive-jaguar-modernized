;
; arena data area: ramps
;

.phrase
	.include	"ramps.cry"
west_start:
	dc.l	ramps_head,$008f2bd4,$fffd37d9,$ffd42b7e	;start
	dc.w	$698
	dc.l	ramps_head,$ff67ed5b,$fffd3949,$ffd3a0b2	;start
	dc.w	$168
	dc.w	$800,$8c0		; y and x scales for map
	dc.w	$e,$a0		; center for map
	dc.l	0			; animation function

dots:
; 0 - region 0
	dc.l	ramps_head,$00a00eb2,$fffe6000,$ff629aab
	dc.l	ramps_head,$0038c2de,$fffe6000,$ff629aab
	dc.l	ramps_head,$0038c2de,$fffe6000,$00da841e
	dc.l	ramps_head,$0038c2de,$fffe6000,$00800000
	dc.l	ramps_head,$0038c2de,$fffe6000,$00890000
	dc.l	ramps_head,$0041c2de,$fffe6000,$00500000
	dc.l	ramps_head,$0046c2de,$fffe6000,$00400000
	dc.l	ramps_head,$0071c2de,$fffe6000,$00400000
; 8 - region 1
	dc.l	ramps_head,$ffadca44,$fffe6000,$ff629aab
	dc.l	ramps_head,$ff615303,$fffe6000,$ff629aab
	dc.l	ramps_head,$ff615303,$fffe6000,$00da841e
	dc.l	ramps_head,$ff615303,$fffe6000,$00800000
	dc.l	ramps_head,$ff615303,$fffe6000,$00890000
	dc.l	ramps_head,$ff695303,$fffe6000,$00500000
	dc.l	ramps_head,$ff705303,$fffe6000,$00400000
	dc.l	ramps_head,$ff805303,$fffe6000,$00400000
; 16 - region 2
	dc.l	ramps_head,$0038c2de,$fffe6000,$00608fdc
	dc.l	ramps_head,$ff615400,$fffe6000,$00608fdc
	dc.l	ramps_head,$ff615400,$fffe6000,$000314dc
	dc.l	ramps_head,$0038c2de,$fffe6000,$000314dc
	dc.l	ramps_head,$0020c2de,$fffe6000,$00508fdc
	dc.l	ramps_head,$ff915400,$fffe6000,$00408fdc
	dc.l	ramps_head,$ff915400,$fffe6000,$001314dc
	dc.l	ramps_head,$002fc2de,$fffe6000,$000b14dc
; 24 - region 3
	dc.l	ramps_head,$0038c2de,$fffe6000,$ffe865b5
	dc.l	ramps_head,$ff615400,$fffe6000,$ffe865b5
	dc.l	ramps_head,$ff615400,$fffe6000,$ff629aab
	dc.l	ramps_head,$0038c2de,$fffe6000,$ff629aab
	dc.l	ramps_head,$0020c2de,$fffe6000,$ffc865b5
	dc.l	ramps_head,$ff915400,$fffe6000,$ffa865b5
	dc.l	ramps_head,$ff915400,$fffe6000,$ff729aab
	dc.l	ramps_head,$002fc2de,$fffe6000,$ff659aab
; 32 - region 4
	dc.l	ramps_head,$00320019,$fffe6000,$008a6227
	dc.l	ramps_head,$ff615303,$fffe6000,$008a6227
	dc.l	ramps_head,$00290019,$fffe6000,$008a6227
	dc.l	ramps_head,$00320019,$fffe6000,$00936227
	dc.l	ramps_head,$00290019,$fffe6000,$00936227
	dc.l	ramps_head,$ff615303,$fffe6000,$00936227
	dc.l	ramps_head,$ff6a5303,$fffe6000,$008a6227
	dc.l	ramps_head,$ff6a5303,$fffe6000,$00396227
; 40 - region 5
	dc.l	ramps_head,$ffd9622d,$fffe6000,$00800000
	dc.l	ramps_head,$0008a689,$fffe6000,$00668fdc
	dc.l	ramps_head,$ffd9622d,$fffe6000,$00668fdc
	dc.l	ramps_head,$0008a689,$fffe6000,$00800000
	dc.l	ramps_head,$fff8e800,$fffe6000,$0071cccc
	dc.l	ramps_head,$ffe49e9a,$fffe6000,$fff39896
	dc.l	ramps_head,$ffe49e9a,$fffe6000,$fff39896
	dc.l	ramps_head,$ffe49e9a,$fffe6000,$fff39896
; 48 - region 6 ramp
	dc.l	ramps_head,$FF6EE5D3,$FFEFE235,$FF3CF16E
	dc.l	ramps_head,$FF75FECE,$FFFDF12F,$FF5A7569
	dc.l	ramps_head,$FF959895,$FFF6AA9F,$FF44B50D
	dc.l	ramps_head,$FFCE016B,$FFF5A132,$FF42E6A4
	dc.l	ramps_head,$0003EF51,$FFFE200A,$FF5D597D
	dc.l	ramps_head,$000BDC04,$FFEFDB91,$FF3CAC06
	dc.l	ramps_head,$FFA91B58,$FFE7BB27,$FF37769B
	dc.l	ramps_head,$00517C2A,$FFF454CB,$FF4126E6
; 56 - region 7 (ramp, air)
	dc.l	ramps_head,$006FD42A,$FFEE4878,$FF3B6A90
	dc.l	ramps_head,$006FAD0B,$FFFD6178,$FF55B48F
	dc.l	ramps_head,$0093B0C2,$FFF69317,$FF449144
	dc.l	ramps_head,$007B8971,$FFE51FD0,$FF368BFF
	dc.l	ramps_head,$00229EFF,$FFFE20D0,$FF5C91FD
	dc.l	ramps_head,$0000FC9E,$FFD8C473,$FF34AA45
	dc.l	ramps_head,$000c5a59,$ffee2c1d,$ff3c955c
	dc.l	ramps_head,$009522f1,$ffbdc767,$ff3ac6b4	; I'm a bad, bad boy.

	.phrase
	include	'ramps.mdl'

	.phrase
;textures:
;	dc.l	chkflag1
;	dc.l	$32420		; XADDINC|WID24|PIXEL16
;	dc.w	24,4

;	.phrase
;; 24x4 checkered flag pattern
;chkflag1:
;	dc.w	$0000,$78f0,$0000,$78f0,$0000,$78f0,$0000,$78f0

