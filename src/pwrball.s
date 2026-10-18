PWRLIST:
.if 1
; list of animation states
	dc.l	pwrb0000,pwrb0001,pwrb0002,pwrb0003,pwrb0004,pwrb0005,pwrb0006,pwrb0007,pwrb0008
.else
	dc.l	pwrb0000,pwrb0000,pwrb0000,pwrb0000,pwrb0000,pwrb0000,pwrb0000,pwrb0000,pwrb0000
.endif
	.phrase
	include	"pwrb0000.cry"
	include	"pwrb0001.cry"
	include	"pwrb0002.cry"
	include	"pwrb0003.cry"
	include	"pwrb0004.cry"
	include	"pwrb0005.cry"
	include	"pwrb0006.cry"
	include	"pwrb0007.cry"
	include	"pwrb0008.cry"

