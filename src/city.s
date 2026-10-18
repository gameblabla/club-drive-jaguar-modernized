	.include	'map.cry'

city_start:
	dc.l	sf157_head,$b5785e20,$0042925b,$3f624ab4	; ORIGIN
	dc.w	$400
	dc.l	sf157_head,$b5573825,$0042668e,$3f4eb37a	; ORIGIN
	dc.w	$400

	dc.w	$106,$106
	dc.w	$ff76,$0104		; center for map
.if 1
	dc.l	cityanim		; animation function
.else
	dc.l	0
.endif
	.globl	sf1_head
	.globl	sf2_head
	.globl	sf3_head
	.globl	sf4_head
	.globl	sf5_head
	.globl	sf6_head
	.globl	sf7_head
	.globl	sf8_head
	.globl	sf9_head
	.globl	sf10_head
	.globl	sf11_head
	.globl	sf12_head
	.globl	sf13_head
	.globl	sf14_head
	.globl	sf15_head
	.globl	sf16_head
	.globl	sf17_head
	.globl	sf18_head
	.globl	sf19_head
	.globl	sf20_head
	.globl	sf21_head
	.globl	sf22_head
	.globl	sf23_head
	.globl	sf24_head
	.globl	sf25_head
	.globl	sf26_head
	.globl	sf27_head
	.globl	sf28_head
	.globl	sf29_head
	.globl	sf30_head
	.globl	sf31_head
	.globl	sf32_head
	.globl	sf33_head
	.globl	sf34_head
	.globl	sf35_head
	.globl	sf36_head
	.globl	sf37_head
	.globl	sf38_head
	.globl	sf39_head
	.globl	sf40_head
	.globl	sf41_head
	.globl	sf42_head
	.globl	sf43_head
	.globl	sf44_head
	.globl	sf45_head
	.globl	sf46_head
	.globl	sf47_head
	.globl	sf48_head
	.globl	sf49_head
	.globl	sf50_head
	.globl	sf51_head
	.globl	sf52_head
	.globl	sf53_head
	.globl	sf54_head
	.globl	sf55_head
	.globl	sf56_head
	.globl	sf57_head
	.globl	sf58_head
	.globl	sf59_head
	.globl	sf60_head
	.globl	sf61_head
	.globl	sf62_head
	.globl	sf63_head
	.globl	sf64_head
	.globl	sf65_head
	.globl	sf66_head
	.globl	sf67_head
	.globl	sf68_head
	.globl	sf69_head
	.globl	sf70_head
	.globl	sf71_head
	.globl	sf72_head
	.globl	sf73_head
	.globl	sf74_head
	.globl	sf75_head
	.globl	sf76_head
	.globl	sf77_head
	.globl	sf78_head
	.globl	sf79_head
	.globl	sf80_head
	.globl	sf81_head
	.globl	sf82_head
	.globl	sf83_head
	.globl	sf84_head
	.globl	sf85_head
	.globl	sf86_head
	.globl	sf87_head
	.globl	sf88_head
	.globl	sf89_head
	.globl	sf90h_head
	.globl	sf90l_head
	.globl	sf91_head
	.globl	sf92_head
	.globl	sf93_head
	.globl	sf94_head
	.globl	sf95_head
	.globl	sf96_head
	.globl	sf97_head
	.globl	sf98_head
	.globl	sf99_head
	.globl	sf100_head
	.globl	sf101_head
	.globl	sf102_head
	.globl	sf103_head
	.globl	sf104_head
	.globl	sf105_head
	.globl	sf106_head
	.globl	sf107_head
	.globl	sf108a_head
	.globl	sf108b_head
	.globl	sf109_head
	.globl	sf110_head
	.globl	sf111_head
	.globl	sf112_head
	.globl	sf113_head
	.globl	sf114_head
	.globl	sf115_head
	.globl	sf116_head
	.globl	sf117_head
	.globl	sf118_head
	.globl	sf119_head
	.globl	sf120_head
	.globl	sf121_head
	.globl	sf122_head
	.globl	sf123_head
	.globl	sf124_head
	.globl	sf125_head
	.globl	sf126_head
	.globl	sf127_head
	.globl	sf128_head
	.globl	sf129_head
	.globl	sf130_head
	.globl	sf131_head
	.globl	sf132_head
	.globl	sf133_head
	.globl	sf134_head
	.globl	sf135_head
	.globl	sf136_head
	.globl	sf137_head
	.globl	sf138_head
	.globl	sf139_head
	.globl	sf140_head
	.globl	sf141_head
	.globl	sf142_head
	.globl	sf143_head
	.globl	sf144_head
	.globl	sf145_head
	.globl	sf146_head
	.globl	sf147_head
	.globl	sf148_head
	.globl	sf149_head
	.globl	sf150_head
	.globl	sf151_head
	.globl	sf152_head
	.globl	sf153_head
	.globl	sf154_head
	.globl	sf155_head
	.globl	sf156_head
	.globl	sf157_head
	.globl	sf158_head
	.globl	sf159_head
	.globl	sf160_head
	.globl	sf161_head
	.globl	sf162_head
	.globl	sf163_head
	.globl	sf164_head

	.include	'sf1.mdl'
	.include	'sf2.mdl'
	.include	'sf3.mdl'
	.include	'sf4.mdl'
	.include	'sf5.mdl'
	.include	'sf6.mdl'
	.include	'sf7.mdl'
	.include	'sf8.mdl'
	.include	'sf9.mdl'
	.include	'sf10.mdl'
	.include	'sf11.mdl'
	.include	'sf12.mdl'
	.include	'sf13.mdl'
	.include	'sf14.mdl'
	.include	'sf15.mdl'
	.include	'sf16.mdl'
	.include	'sf17.mdl'
	.include	'sf18.mdl'
	.include	'sf19.mdl'
	.include	'sf20.mdl'
	.include	'sf21.mdl'
	.include	'sf22.mdl'
	.include	'sf23.mdl'
	.include	'sf24.mdl'
	.include	'sf25.mdl'
	.include	'sf26.mdl'
	.include	'sf27.mdl'
	.include	'sf28.mdl'
	.include	'sf29.mdl'
	.include	'sf30.mdl'
	.include	'sf31.mdl'
	.include	'sf32.mdl'
	.include	'sf33.mdl'
	.include	'sf34.mdl'
	.include	'sf35.mdl'
	.include	'sf36.mdl'
	.include	'sf37.mdl'
	.include	'sf38.mdl'
	.include	'sf39.mdl'
	.include	'sf40.mdl'
	.include	'sf41.mdl'
	.include	'sf42.mdl'
	.include	'sf43.mdl'
	.include	'sf44.mdl'
	.include	'sf45.mdl'
	.include	'sf46.mdl'
	.include	'sf47.mdl'
	.include	'sf48.mdl'
	.include	'sf49.mdl'
	.include	'sf50.mdl'
	.include	'sf51.mdl'
	.include	'sf52.mdl'
	.include	'sf53.mdl'
	.include	'sf54.mdl'
	.include	'sf55.mdl'
	.include	'sf56.mdl'
	.include	'sf57.mdl'
	.include	'sf58.mdl'
	.include	'sf59.mdl'
	.include	'sf60.mdl'
	.include	'sf61.mdl'
	.include	'sf62.mdl'
	.include	'sf63.mdl'
	.include	'sf64.mdl'
	.include	'sf65.mdl'
	.include	'sf66.mdl'
	.include	'sf67.mdl'
	.include	'sf68.mdl'
	.include	'sf69.mdl'
	.include	'sf70.mdl'
	.include	'sf71.mdl'
	.include	'sf72.mdl'
	.include	'sf73.mdl'
	.include	'sf74.mdl'
	.include	'sf75.mdl'
	.include	'sf76.mdl'
	.include	'sf77.mdl'
	.include	'sf78.mdl'
	.include	'sf79.mdl'
	.include	'sf80.mdl'
	.include	'sf81.mdl'
	.include	'sf82.mdl'
	.include	'sf83.mdl'
	.include	'sf84.mdl'
	.include	'sf85.mdl'
	.include	'sf86.mdl'
	.include	'sf87.mdl'
	.include	'sf88.mdl'
	.include	'sf89.mdl'
	.include	'sf90h.mdl'
	.include	'sf90l.mdl'
	.include	'sf91.mdl'
	.include	'sf92.mdl'
	.include	'sf93.mdl'
	.include	'sf94.mdl'
	.include	'sf95.mdl'
	.include	'sf96.mdl'
	.include	'sf97.mdl'
	.include	'sf98.mdl'
	.include	'sf99.mdl'
	.include	'sf100.mdl'
	.include	'sf101.mdl'
	.include	'sf102.mdl'
	.include	'sf103.mdl'
	.include	'sf104.mdl'
	.include	'sf105.mdl'
	.include	'sf106.mdl'
	.include	'sf107.mdl'
	.include	'sf108a.mdl'
	.include	'sf108b.mdl'
	.include	'sf109.mdl'
	.include	'sf110.mdl'
	.include	'sf111.mdl'
	.include	'sf112.mdl'
	.include	'sf113.mdl'
	.include	'sf114.mdl'
	.include	'sf115.mdl'
	.include	'sf116.mdl'
	.include	'sf117.mdl'
	.include	'sf118.mdl'
	.include	'sf119.mdl'
	.include	'sf120.mdl'
	.include	'sf121.mdl'
	.include	'sf122.mdl'
	.include	'sf123.mdl'
	.include	'sf124.mdl'
	.include	'sf125.mdl'
	.include	'sf126.mdl'
	.include	'sf127.mdl'
	.include	'sf128.mdl'
	.include	'sf129.mdl'
	.include	'sf130.mdl'
	.include	'sf131.mdl'
	.include	'sf132.mdl'
	.include	'sf133.mdl'
	.include	'sf134.mdl'
	.include	'sf135.mdl'
	.include	'sf136.mdl'
	.include	'sf137.mdl'
	.include	'sf138.mdl'
	.include	'sf139.mdl'
	.include	'sf140.mdl'
	.include	'sf141.mdl'
	.include	'sf142.mdl'
	.include	'sf143.mdl'
	.include	'sf144.mdl'
	.include	'sf145.mdl'
	.include	'sf146.mdl'
	.include	'sf147.mdl'
	.include	'sf148.mdl'
	.include	'sf149.mdl'
	.include	'sf150.mdl'
	.include	'sf151.mdl'
	.include	'sf152.mdl'
	.include	'sf153.mdl'
	.include	'sf154.mdl'
	.include	'sf155.mdl'
	.include	'sf156.mdl'
	.include	'sf157.mdl'
	.include	'sf158.mdl'
	.include	'sf159.mdl'
	.include	'sf160.mdl'
	.include	'sf161.mdl'
	.include	'sf161b.mdl'
	.include	'sf162.mdl'
	.include	'sf163.mdl'
	.include	'sf164.mdl'
	.include	'sf165.mdl'

	.include	'sf2_2.mdl'
	.include	'sf2_3.mdl'
	.include	'sf2_4.mdl'
	.include	'sf2_5.mdl'
	.include	'sf2_6.mdl'
	.include	'sf2_7.mdl'
	.include	'sf2_8.mdl'
	.include	'sf2_9.mdl'
	.include	'sf2_10.mdl'
	.include	'sf2_11.mdl'
	.include	'sf2_12.mdl'
	.include	'sf2_13.mdl'
	.include	'sf2_14.mdl'
	.include	'sf2_15.mdl'
	.include	'sf2_16.mdl'
	.include	'sf2_17.mdl'
	.include	'sf2_18.mdl'
	.include	'sf2_19.mdl'
	.include	'sf2_20.mdl'
	.include	'sf2_21.mdl'
	.include	'sf2_22.mdl'
	.include	'sf2_23.mdl'
	.include	'sf2_24.mdl'
	.include	'sf2_25.mdl'
	.include	'sf2_26.mdl'
	.include	'sf2_27.mdl'
	.include	'sf2_28.mdl'
	.include	'sf2_29.mdl'
	.include	'sf2_30.mdl'
	.include	'sf2_31.mdl'
	.include	'sf2_32.mdl'
	.include	'sf2_33.mdl'
	.include	'sf2_34.mdl'
	.include	'sf2_35.mdl'
	.include	'sf2_36.mdl'
	.include	'sf2_37.mdl'
	.include	'sf2_38.mdl'
	.include	'sf2_39.mdl'
	.include	'sf2_40.mdl'
	.include	'sf2_41.mdl'
	.include	'sf2_42.mdl'
	.include	'sf2_43.mdl'
	.include	'sf2_44.mdl'
	.include	'sf2_45.mdl'
	.include	'sf2_46.mdl'
	.include	'sf2_47.mdl'
	.include	'sf2_48.mdl'
	.include	'sf2_49.mdl'
	.include	'sf2_50.mdl'
	.include	'sf2_51.mdl'
	.include	'sf2_52.mdl'
	.include	'sf2_53.mdl'
	.include	'sf2_54.mdl'
	.include	'sf2_55.mdl'
	.include	'sf2_56.mdl'
	.include	'sf2_57.mdl'
	.include	'sf2_58.mdl'
	.include	'sf2_59.mdl'
	.include	'sf2_60.mdl'
	.include	'sf2_61.mdl'
	.include	'sf2_62.mdl'
	.include	'sf2_63.mdl'
	.include	'sf2_64.mdl'
	.include	'sf2_65.mdl'
	.include	'sf2_66.mdl'
	.include	'sf2_67.mdl'
	.include	'sf2_68.mdl'
	.include	'sf2_69.mdl'
	.include	'sf2_70.mdl'
	.include	'sf2_71.mdl'
	.include	'sf2_72.mdl'
	.include	'sf2_73.mdl'
	.include	'sf2_74.mdl'
	.include	'sf2_75.mdl'
	.include	'sf2_76.mdl'
	.include	'sf2_77.mdl'
	.include	'sf2_78.mdl'
	.include	'sf2_79.mdl'
	.include	'sf2_80.mdl'
	.include	'sf2_81.mdl'
	.include	'sf2_82.mdl'
	.include	'sf2_83.mdl'
	.include	'sf2_84.mdl'
	.include	'sf2_85.mdl'
	.include	'sf2_86.mdl'
	.include	'sf2_87.mdl'
	.include	'sf2_88.mdl'
	.include	'sf2_89.mdl'
	.include	'sf2_90.mdl'
	.include	'sf2_91.mdl'
	.include	'sf2_92.mdl'
	.include	'sf2_93.mdl'
	.include	'sf2_94.mdl'
	.include	'sf2_95.mdl'
	.include	'sf2_96.mdl'
	.include	'sf2_97.mdl'
	.include	'sf2_98.mdl'
	.include	'sf2_99.mdl'
	.include	'sf2_100.mdl'
	.include	'sf2_101.mdl'
	.include	'sf2_102.mdl'
	.include	'sf2_103.mdl'
	.include	'sf2_104.mdl'
	.include	'sf2_105.mdl'
	.include	'sf2_106.mdl'
	.include	'sf2_107.mdl'
	.include	'sf2_108.mdl'
	.include	'sf2_109.mdl'
	.include	'sf2_110.mdl'
	.include	'sf2_111.mdl'
	.include	'sf2_112.mdl'
	.include	'sf2_113.mdl'
	.include	'sf2_114.mdl'
	.include	'sf2_115.mdl'
	.include	'sf2_116.mdl'
	.include	'sf2_117.mdl'
	.include	'sf2_118.mdl'
	.include	'sf2_119.mdl'
	.include	'sf2_120.mdl'
	.include	'sf2_121.mdl'
	.include	'sf2_122.mdl'
	.include	'sf2_123.mdl'
	.include	'sf2_124.mdl'
	.include	'sf2_125.mdl'
	.include	'sf2_126.mdl'
	.include	'sf2_127.mdl'
	.include	'sf2_128.mdl'
	.include	'sf2_129.mdl'
	.include	'sf2_132.mdl'
	.include	'sf2_135.mdl'

	.include	'sf3_2.mdl'
	.include	'sf3_3.mdl'
	.include	'sf3_4.mdl'
	.include	'sf3_5.mdl'
	.include	'sf3_6.mdl'
	.include	'sf3_7.mdl'
	.include	'sf3_8.mdl'
	.include	'sf3_9.mdl'
	.include	'sf3_10.mdl'
	.include	'sf3_11.mdl'
	.include	'sf3_12.mdl'
	.include	'sf3_13.mdl'
	.include	'sf3_14.mdl'
	.include	'sf3_15.mdl'
	.include	'sf3_16.mdl'
	.include	'sf3_17.mdl'
	.include	'sf3_18.mdl'
	.include	'sf3_19.mdl'
	.include	'sf3_20.mdl'
	.include	'sf3_21.mdl'
	.include	'sf3_22.mdl'
	.include	'sf3_23.mdl'
	.include	'sf3_24.mdl'
	.include	'sf3_25.mdl'
	.include	'sf3_26.mdl'
	.include	'sf3_27.mdl'
	.include	'sf3_28.mdl'
	.include	'sf3_29.mdl'
	.include	'sf3_30.mdl'
	.include	'sf3_31.mdl'
	.include	'sf3_32.mdl'
	.include	'sf3_33.mdl'
	.include	'sf3_34.mdl'
	.include	'sf3_35.mdl'
	.include	'sf3_36.mdl'
	.include	'sf3_37.mdl'
	.include	'sf3_38.mdl'
	.include	'sf3_39.mdl'
	.include	'sf3_40.mdl'
	.include	'sf3_41.mdl'
	.include	'sf3_42.mdl'
	.include	'sf3_43.mdl'
	.include	'sf3_46.mdl'
	.include	'sf3_47.mdl'

	.include	'sf4_1.mdl'
	.include	'sf4_2.mdl'
	.include	'sf4_3.mdl'
	.include	'sf4_4.mdl'
	.include	'sf4_5.mdl'
	.include	'sf4_6.mdl'
	.include	'sf4_7.mdl'
	.include	'sf4_8.mdl'
	.include	'sf4_9.mdl'
	.include	'sf4_10.mdl'
	.include	'sf4_11.mdl'
	.include	'sf4_12.mdl'
	.include	'sf4_13.mdl'
	.include	'sf4_14.mdl'

	.include	'm1.mdl'
	.include	'm2.mdl'
	.include	'm3.mdl'
	.include	'm4.mdl'
	.include	'm5.mdl'
	.include	'm6.mdl'
	.include	'm7.mdl'
	.include	'm8.mdl'
	.include	'm9.mdl'
	.include	'm10.mdl'
	.include	'm11.mdl'
	.include	'm12.mdl'
	.include	'm13.mdl'
	.include	'm14.mdl'
	.include	'm15.mdl'
	.include	'm16.mdl'
	.include	'm17.mdl'
	.include	'm18.mdl'
	.include	'm19.mdl'
	.include	'm20.mdl'
	.include	'm21.mdl'
	.include	'm22.mdl'
	.include	'm23.mdl'
	.include	'm24.mdl'
	.include	'm25.mdl'
	.include	'm26.mdl'

	.include	'cabcar.mdl'

	.phrase
	.include	'beachl.cry'
	.include	'beachr.cry'
	.include	'bridgel.cry'
	.include	'bridger.cry'

	.long
	.extern	cabrec,cabrecx,gpucity

	dc.l	'IGPU'
cityanim:
	dc.l	gpucity		; GPU animation program
	dc.l	parmblock	; parameter for animation
	dc.l	cabcar_head	; list of mobile bands
	dc.l	0
	dc.l	animinit	; initilization function

animinit:
	move.l	#cabrec,cp	; initialize playback head
	move.l	#0,cp+4
	rts

	.long
parmblock:
	dc.l	cabcar_head
	dc.l	cabrec		; begin recording
	dc.l	cabrecx		; end recording
cp:	dc.l	cabrec		; playback head
	dc.l	0		; elapsed time

	.phrase
textures:
	dc.l	chkflag1
	dc.l	$32420		; XADDINC|WID24|PIXEL16
	dc.w	24,4

	dc.l	beachl
	dc.l	$33020		; XADDINC|WID64|PIXEL16
	dc.w	64,20

	dc.l	beachr
	dc.l	$33020		; XADDINC|WID64|PIXEL16
	dc.w	64,20

	dc.l	bridgel
	dc.l	$33020		; XADDINC|WID64|PIXEL16
	dc.w	64,20

	dc.l	bridger
	dc.l	$33020		; XADDINC|WID64|PIXEL16
	dc.w	64,20

	dc.l	chkflag2
	dc.l	$31020		; XADDINC|WID4|PIXEL16
	dc.w	4,24

;
; cameras
;
cam2:
	dc.l	0,0,0,0
	dc.l	sf2_head, $b36c1000,$003de200,$33b5d000
cam6:
	dc.l	0,0,0,0
	dc.l	sf6_head, $b3657400,$003e3000,$34db4000
cam12:
	dc.l	0,0,0,0
	dc.l	sf12_head, $b3ec5000,$003f1000,$344ed000
cam14:
	dc.l	0,0,0,0
	dc.l	sf14_head, $b3edc000,$00397000,$34d7d000
cam18:
	dc.l	0,0,0,0
	dc.l	sf18_head, $b47c0000,$00340000,$33cf5000
cam20:
	dc.l	0,0,0,0
	dc.l	sf20_head, $b47c7000,$00212000,$3451a000
cam26:
	dc.l	0,0,0,0
	dc.l	sf26_head, $b5004000,$00338000,$33d1f000
cam28:
	dc.l	0,0,0,0
	dc.l	sf28_head, $b5018000,$00269000,$34562000
cam30:
	dc.l	0,0,0,0
	dc.l	sf30_head, $b5044000,$00174000,$34d59000
cam35:
	dc.l	0,0,0,0
	dc.l	sf35_head, $b5b07000,$00256000,$33f66000
cam37:
	dc.l	0,0,0,0
	dc.l	sf37_head, $b585a000,$00145000,$34b86000
cam40:
	dc.l	0,0,0,0
	dc.l	sf40_head, $b643f000,$00353000,$33d8a000
cam43:
	dc.l	0,0,0,0
	dc.l	sf43_head, $b61b1000,$0014e000,$34dd5000
cam44:
	dc.l	0,0,0,0
	dc.l	sf44_head, $b6a48000,$002d9000,$33d99000
cam47:
	dc.l	0,0,0,0
	dc.l	sf47_head, $b698a000,$001e8000,$3465f000
cam51:
	dc.l	0,0,0,0
	dc.l	sf51_head, $b7351000,$00386000,$33c34000
cam53:
	dc.l	0,0,0,0
	dc.l	sf53_head, $b720d000,$00201000,$345a9000
cam58:
	dc.l	0,0,0,0
	dc.l	sf58_head, $b7baf000,$0042eb1e,$33ccc000
cam59:
	dc.l	0,0,0,0
	dc.l	sf59_head, $b7b79000,$00388000,$34598000
cam62:
	dc.l	0,0,0,0
	dc.l	sf62_head, $b7f5f000,$0048a000,$35b14000
cam67:
	dc.l	0,0,0,0
	dc.l	sf67_head, $b7c29000,$00431000,$3754a000
cam70:
	dc.l	0,0,0,0
	dc.l	sf70_head, $b6c6e000,$00431000,$37c33000
cam71:
	dc.l	0,0,0,0
	dc.l	sf71_head, $b760b000,$002ff000,$355a5000
cam75:
	dc.l	0,0,0,0
	dc.l	sf75_head, $b7b93000,$00341000,$365c9000
cam80:
	dc.l	0,0,0,0
	dc.l	sf80_head, $b684c000,$00101000,$3576e000
cam82:
	dc.l	0,0,0,0
	dc.l	sf82_head, $b7001000,$00248000,$35ba9000
cam84:
	dc.l	0,0,0,0
	dc.l	sf84_head, $b7827000,$00311000,$360a7000
cam94:
	dc.l	0,0,0,0
	dc.l	sf94_head, $b6951000,$00201000,$36a4d000
cam99:
	dc.l	0,0,0,0
	dc.l	sf99_head, $b695e000,$00355000,$3715f000
cam108:
	dc.l	0,0,0,0
	dc.l	sf108b_head,$b4fbb000,$0030c000,$367c6000
cam112:
	dc.l	0,0,0,0
	dc.l	sf112_head, $b5728000,$0021b000,$37917000
cam117:
	dc.l	0,0,0,0
	dc.l	sf117_head, $b46dc000,$0031d000,$370bf000
cam119:
	dc.l	0,0,0,0
	dc.l	sf119_head, $b4f89000,$0038a000,$3788f000
cam123:
	dc.l	0,0,0,0
	dc.l	sf123_head, $b4699000,$0028a000,$378cc000
cam129:
	dc.l	0,0,0,0
	dc.l	sf129_head, $b3e1b000,$0024e000,$35ed8000
cam135:
	dc.l	0,0,0,0
	dc.l	sf135_head, $b3e4fe00,$003ff000,$378bd000
cam142:
	dc.l	0,0,0,0
	dc.l	sf142_head, $b3493000,$003ff000,$3703d000
cam144:
	dc.l	0,0,0,0
	dc.l	sf144_head, $b3600000,$003ff000,$367a3000
cam146:
	dc.l	0,0,0,0
	dc.l	sf146_head, $b3600000,$00381000,$35e75000
cam152:
	dc.l	0,0,0,0
	dc.l	sf152_head, $b3e41000,$0033a000,$35617000

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
; 4x24 checkered flag pattern
chkflag2:
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

