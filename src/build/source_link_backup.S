; ============================================================================
; CLUB DRIVE - RETAIL-RECOVERED LATE 68000 CODE AND CONSTANTS (v13)
; ============================================================================
; Provenance: supplied final Club Drive cartridge, byte span
;   ROM file offsets $01C814 through $01CFFF inclusive.
;   SHA-256 of exact region: bf246cf9959163733fbb640254fe4da49a90721e24bbce93e605ddb1e9fa096e
; This code/embedded data is NOT present in the surviving 1994 source.
; The hex words are faithfully transcribed as ASSEMBLER SOURCE and
; each decoded mnemonic is machine-generated guidance, NOT Atari comments.
; Some data might have been decoded as instructions; do not infer function
; boundaries from these comments. Pointers remain fixed to retail layout.
; Inputs/outputs: unknown for unlabeled routines, require flow tracing.
; Source editors: replacing a dc.w sequence with an equivalent instruction
; is supported, but the slot MUST retain its original size until the
; historical relocation model is fully recovered.
; This region must follow PACKET.S and precede the original data segment.
; ============================================================================
	.text
club_v13_late_code_begin::
; ---- ROM $01C814: recovered boundary (semantic role unverified) ----
	dc.w	$4E71	; $01C814  nop
	dc.w	$4E71	; $01C816  nop
; ---- ROM $01C818: recovered boundary (semantic role unverified) ----
	dc.w	$6200	; $01C818  bhiw 0x81c83e
	dc.w	$0024	; $01C81A  extension word or undecoded data
	dc.w	$7400	; $01C81C  moveq #0,%d2
	dc.w	$7200	; $01C81E  moveq #0,%d1
	dc.w	$2079	; $01C820  moveal 0x1ce0e,%a0
	dc.w	$0001	; $01C822  extension word or undecoded data
	dc.w	$CE0E	; $01C824  extension word or undecoded data
	dc.w	$1410	; $01C826  moveb %a0@,%d2
	dc.w	$3204	; $01C828  movew %d4,%d1
	dc.w	$2002	; $01C82A  movel %d2,%d0
	dc.w	$E3A8	; $01C82C  lsll %d1,%d0
	dc.w	$8A80	; $01C82E  orl %d0,%d5
	dc.w	$52B9	; $01C830  addql #1,0x1ce0e
	dc.w	$0001	; $01C832  extension word or undecoded data
	dc.w	$CE0E	; $01C834  extension word or undecoded data
	dc.w	$5044	; $01C836  addqw #8,%d4
	dc.w	$B87C	; $01C838  cmpw #6,%d4
	dc.w	$0006	; $01C83A  extension word or undecoded data
	dc.w	$63E2	; $01C83C  blss 0x81c820
	dc.w	$3405	; $01C83E  movew %d5,%d2
	dc.w	$C47C	; $01C840  andw #127,%d2
	dc.w	$007F	; $01C842  extension word or undecoded data
	dc.w	$3202	; $01C844  movew %d2,%d1
	dc.w	$D27C	; $01C846  addw #11,%d1
	dc.w	$000B	; $01C848  extension word or undecoded data
	dc.w	$EE8D	; $01C84A  lsrl #7,%d5
	dc.w	$5F44	; $01C84C  subqw #7,%d4
	dc.w	$300A	; $01C84E  movew %a2,%d0
	dc.w	$D041	; $01C850  addw %d1,%d0
	dc.w	$B049	; $01C852  cmpw %a1,%d0
	dc.w	$6200	; $01C854  bhiw 0x81c992
	dc.w	$013C	; $01C856  extension word or undecoded data
	dc.w	$3202	; $01C858  movew %d2,%d1
	dc.w	$D27C	; $01C85A  addw #10,%d1
	dc.w	$000A	; $01C85C  extension word or undecoded data
	dc.w	$BC41	; $01C85E  cmpw %d1,%d6
	dc.w	$6700	; $01C860  beqw 0x81c87a
	dc.w	$0018	; $01C862  extension word or undecoded data
	dc.w	$300A	; $01C864  movew %a2,%d0
	dc.w	$48C0	; $01C866  extl %d0
	dc.w	$D080	; $01C868  addl %d0,%d0
	dc.w	$41F6	; $01C86A  lea %fp@(0000000000000000,%d0:l),%a0
	dc.w	$0800	; $01C86C  extension word or undecoded data
	dc.w	$4273	; $01C86E  clrw %a3@(0000000000000000,%a0:l)
	dc.w	$8800	; $01C870  extension word or undecoded data
	dc.w	$524A	; $01C872  addqw #1,%a2
	dc.w	$5341	; $01C874  subqw #1,%d1
	dc.w	$BC41	; $01C876  cmpw %d1,%d6
	dc.w	$66EA	; $01C878  bnes 0x81c864
	dc.w	$4243	; $01C87A  clrw %d3
	dc.w	$3E09	; $01C87C  movew %a1,%d7
	dc.w	$BE4A	; $01C87E  cmpw %a2,%d7
	dc.w	$6200	; $01C880  bhiw 0x81c6cc
	dc.w	$FE4A	; $01C882  extension word or undecoded data
	dc.w	$2F2E	; $01C884  movel %fp@(-636),%sp@-
	dc.w	$FD84	; $01C886  extension word or undecoded data
	dc.w	$49F9	; $01C888  lea 0x81c0cc,%a4
	dc.w	$0081	; $01C88A  extension word or undecoded data
	dc.w	$C0CC	; $01C88C  extension word or undecoded data
	dc.w	$4E94	; $01C88E  jsr %a4@
	dc.w	$584F	; $01C890  addqw #4,%sp
	dc.w	$23C5	; $01C892  movel %d5,0x1d71a
	dc.w	$0001	; $01C894  extension word or undecoded data
	dc.w	$D71A	; $01C896  extension word or undecoded data
	dc.w	$33C4	; $01C898  movew %d4,0x1d71e
	dc.w	$0001	; $01C89A  extension word or undecoded data
	dc.w	$D71E	; $01C89C  extension word or undecoded data
	dc.w	$3D79	; $01C89E  movew 0x1d720,%fp@(-638)
	dc.w	$0001	; $01C8A0  extension word or undecoded data
	dc.w	$D720	; $01C8A2  extension word or undecoded data
	dc.w	$FD82	; $01C8A4  extension word or undecoded data
	dc.w	$486E	; $01C8A6  pea %fp@(-638)
	dc.w	$FD82	; $01C8A8  extension word or undecoded data
	dc.w	$486E	; $01C8AA  pea %fp@(-636)
	dc.w	$FD84	; $01C8AC  extension word or undecoded data
	dc.w	$4879	; $01C8AE  pea 0x8ea2d4
	dc.w	$008E	; $01C8B0  extension word or undecoded data
	dc.w	$A2D4	; $01C8B2  extension word or undecoded data
	dc.w	$4879	; $01C8B4  pea 0x8ea296
	dc.w	$008E	; $01C8B6  extension word or undecoded data
	dc.w	$A296	; $01C8B8  extension word or undecoded data
	dc.w	$3F3C	; $01C8BA  movew #257,%sp@-
	dc.w	$0101	; $01C8BC  extension word or undecoded data
	dc.w	$3F2E	; $01C8BE  movew %fp@(-648),%sp@-
	dc.w	$FD78	; $01C8C0  extension word or undecoded data
	dc.w	$47EE	; $01C8C2  lea %fp@(-632),%a3
	dc.w	$FD88	; $01C8C4  extension word or undecoded data
	dc.w	$2F0B	; $01C8C6  movel %a3,%sp@-
	dc.w	$243C	; $01C8C8  movel #8502482,%d2
	dc.w	$0081	; $01C8CA  extension word or undecoded data
	dc.w	$BCD2	; $01C8CC  extension word or undecoded data
	dc.w	$2A42	; $01C8CE  moveal %d2,%a5
	dc.w	$4E95	; $01C8D0  jsr %a5@
	dc.w	$DEFC	; $01C8D2  addaw #24,%sp
	dc.w	$0018	; $01C8D4  extension word or undecoded data
	dc.w	$3440	; $01C8D6  moveaw %d0,%a2
	dc.w	$4A40	; $01C8D8  tstw %d0
	dc.w	$6700	; $01C8DA  beqw 0x81c8f6
	dc.w	$001A	; $01C8DC  extension word or undecoded data
	dc.w	$B07C	; $01C8DE  cmpw #1,%d0
	dc.w	$0001	; $01C8E0  extension word or undecoded data
	dc.w	$6600	; $01C8E2  bnew 0x81c95a
	dc.w	$0076	; $01C8E4  extension word or undecoded data
	dc.w	$4879	; $01C8E6  pea 0x81c4a8
	dc.w	$0081	; $01C8E8  extension word or undecoded data
	dc.w	$C4A8	; $01C8EA  extension word or undecoded data
	dc.w	$4EB9	; $01C8EC  jsr 0x81bbcc
	dc.w	$0081	; $01C8EE  extension word or undecoded data
	dc.w	$BBCC	; $01C8F0  extension word or undecoded data
	dc.w	$6000	; $01C8F2  braw 0x81c952
	dc.w	$005E	; $01C8F4  extension word or undecoded data
	dc.w	$3D79	; $01C8F6  movew 0x1d722,%fp@(-644)
	dc.w	$0001	; $01C8F8  extension word or undecoded data
	dc.w	$D722	; $01C8FA  extension word or undecoded data
	dc.w	$FD7C	; $01C8FC  extension word or undecoded data
	dc.w	$486E	; $01C8FE  pea %fp@(-644)
	dc.w	$FD7C	; $01C900  extension word or undecoded data
	dc.w	$486E	; $01C902  pea %fp@(-642)
	dc.w	$FD7E	; $01C904  extension word or undecoded data
	dc.w	$4879	; $01C906  pea 0x8ea34e
	dc.w	$008E	; $01C908  extension word or undecoded data
	dc.w	$A34E	; $01C90A  extension word or undecoded data
	dc.w	$4879	; $01C90C  pea 0x8ea312
	dc.w	$008E	; $01C90E  extension word or undecoded data
	dc.w	$A312	; $01C910  extension word or undecoded data
	dc.w	$4267	; $01C912  clrw %sp@-
	dc.w	$3F2E	; $01C914  movew %fp@(-646),%sp@-
	dc.w	$FD7A	; $01C916  extension word or undecoded data
	dc.w	$302E	; $01C918  movew %fp@(-648),%d0
	dc.w	$FD78	; $01C91A  extension word or undecoded data
	dc.w	$C0BC	; $01C91C  andl #1023,%d0
	dc.w	$0000	; $01C91E  extension word or undecoded data
	dc.w	$03FF	; $01C920  extension word or undecoded data
	dc.w	$D080	; $01C922  addl %d0,%d0
	dc.w	$4873	; $01C924  pea %a3@(0000000000000000,%d0:l)
	dc.w	$0800	; $01C926  extension word or undecoded data
	dc.w	$2A42	; $01C928  moveal %d2,%a5
	dc.w	$4E95	; $01C92A  jsr %a5@
	dc.w	$DEFC	; $01C92C  addaw #24,%sp
	dc.w	$0018	; $01C92E  extension word or undecoded data
	dc.w	$3440	; $01C930  moveaw %d0,%a2
	dc.w	$4A40	; $01C932  tstw %d0
	dc.w	$6700	; $01C934  beqw 0x81c960
	dc.w	$002A	; $01C936  extension word or undecoded data
	dc.w	$B07C	; $01C938  cmpw #1,%d0
	dc.w	$0001	; $01C93A  extension word or undecoded data
	dc.w	$6600	; $01C93C  bnew 0x81c954
	dc.w	$0016	; $01C93E  extension word or undecoded data
	dc.w	$4879	; $01C940  pea 0x81c4c3
	dc.w	$0081	; $01C942  extension word or undecoded data
	dc.w	$C4C3	; $01C944  extension word or undecoded data
	dc.w	$4EB9	; $01C946  jsr 0x81bbcc
	dc.w	$0081	; $01C948  extension word or undecoded data
	dc.w	$BBCC	; $01C94A  extension word or undecoded data
	dc.w	$2EAE	; $01C94C  movel %fp@(-642),%sp@
	dc.w	$FD7E	; $01C94E  extension word or undecoded data
	dc.w	$4E94	; $01C950  jsr %a4@
	dc.w	$584F	; $01C952  addqw #4,%sp
	dc.w	$2F2E	; $01C954  movel %fp@(-636),%sp@-
	dc.w	$FD84	; $01C956  extension word or undecoded data
	dc.w	$4E94	; $01C958  jsr %a4@
	dc.w	$300A	; $01C95A  movew %a2,%d0
	dc.w	$6000	; $01C95C  braw 0x81c994
	dc.w	$0036	; $01C95E  extension word or undecoded data
	dc.w	$3F2E	; $01C960  movew %fp@(-644),%sp@-
	dc.w	$FD7C	; $01C962  extension word or undecoded data
	dc.w	$3F2E	; $01C964  movew %fp@(-638),%sp@-
	dc.w	$FD82	; $01C966  extension word or undecoded data
	dc.w	$2F2E	; $01C968  movel %fp@(-642),%sp@-
	dc.w	$FD7E	; $01C96A  extension word or undecoded data
	dc.w	$2F2E	; $01C96C  movel %fp@(-636),%sp@-
	dc.w	$FD84	; $01C96E  extension word or undecoded data
	dc.w	$4EB9	; $01C970  jsr 0x81c12e
	dc.w	$0081	; $01C972  extension word or undecoded data
	dc.w	$C12E	; $01C974  extension word or undecoded data
	dc.w	$DEFC	; $01C976  addaw #12,%sp
	dc.w	$000C	; $01C978  extension word or undecoded data
	dc.w	$4A40	; $01C97A  tstw %d0
	dc.w	$6600	; $01C97C  bnew 0x81c992
	dc.w	$0014	; $01C97E  extension word or undecoded data
	dc.w	$2F2E	; $01C980  movel %fp@(-636),%sp@-
	dc.w	$FD84	; $01C982  extension word or undecoded data
	dc.w	$4E94	; $01C984  jsr %a4@
	dc.w	$2EAE	; $01C986  movel %fp@(-642),%sp@
	dc.w	$FD7E	; $01C988  extension word or undecoded data
	dc.w	$4E94	; $01C98A  jsr %a4@
	dc.w	$4240	; $01C98C  clrw %d0
	dc.w	$6000	; $01C98E  braw 0x81c994
	dc.w	$0004	; $01C990  extension word or undecoded data
	dc.w	$7001	; $01C992  moveq #1,%d0
	dc.w	$4CEE	; $01C994  moveml %fp@(-692),%d2-%d7/%a2-%a5
	dc.w	$3CFC	; $01C996  extension word or undecoded data
	dc.w	$FD4C	; $01C998  extension word or undecoded data
	dc.w	$4E5E	; $01C99A  unlk %fp
	dc.w	$4E75	; $01C99C  rts
; ---- ROM $01C99E: recovered boundary (semantic role unverified) ----
	dc.w	$4E56	; $01C99E  linkw %fp,#0
	dc.w	$0000	; $01C9A0  extension word or undecoded data
	dc.w	$48E7	; $01C9A2  moveml %d2-%d5,%sp@-
	dc.w	$3C00	; $01C9A4  extension word or undecoded data
	dc.w	$226E	; $01C9A6  moveal %fp@(8),%a1
	dc.w	$0008	; $01C9A8  extension word or undecoded data
	dc.w	$2439	; $01C9AA  movel 0x1d71a,%d2
	dc.w	$0001	; $01C9AC  extension word or undecoded data
	dc.w	$D71A	; $01C9AE  extension word or undecoded data
	dc.w	$3239	; $01C9B0  movew 0x1d71e,%d1
	dc.w	$0001	; $01C9B2  extension word or undecoded data
	dc.w	$D71E	; $01C9B4  extension word or undecoded data
	dc.w	$6600	; $01C9B6  bnew 0x81c9d8
	dc.w	$0020	; $01C9B8  extension word or undecoded data
	dc.w	$7800	; $01C9BA  moveq #0,%d4
	dc.w	$7600	; $01C9BC  moveq #0,%d3
	dc.w	$2079	; $01C9BE  moveal 0x1ce0e,%a0
	dc.w	$0001	; $01C9C0  extension word or undecoded data
	dc.w	$CE0E	; $01C9C2  extension word or undecoded data
	dc.w	$1810	; $01C9C4  moveb %a0@,%d4
	dc.w	$3601	; $01C9C6  movew %d1,%d3
	dc.w	$2004	; $01C9C8  movel %d4,%d0
	dc.w	$E7A8	; $01C9CA  lsll %d3,%d0
	dc.w	$8480	; $01C9CC  orl %d0,%d2
	dc.w	$52B9	; $01C9CE  addql #1,0x1ce0e
	dc.w	$0001	; $01C9D0  extension word or undecoded data
	dc.w	$CE0E	; $01C9D2  extension word or undecoded data
	dc.w	$5041	; $01C9D4  addqw #8,%d1
	dc.w	$67E6	; $01C9D6  beqs 0x81c9be
	dc.w	$3A02	; $01C9D8  movew %d2,%d5
	dc.w	$CA7C	; $01C9DA  andw #1,%d5
	dc.w	$0001	; $01C9DC  extension word or undecoded data
	dc.w	$3285	; $01C9DE  movew %d5,%a1@
	dc.w	$E28A	; $01C9E0  lsrl #1,%d2
	dc.w	$5341	; $01C9E2  subqw #1,%d1
	dc.w	$B27C	; $01C9E4  cmpw #1,%d1
	dc.w	$0001	; $01C9E6  extension word or undecoded data
	dc.w	$6200	; $01C9E8  bhiw 0x81ca0e
	dc.w	$0024	; $01C9EA  extension word or undecoded data
	dc.w	$7800	; $01C9EC  moveq #0,%d4
	dc.w	$7600	; $01C9EE  moveq #0,%d3
	dc.w	$2079	; $01C9F0  moveal 0x1ce0e,%a0
	dc.w	$0001	; $01C9F2  extension word or undecoded data
	dc.w	$CE0E	; $01C9F4  extension word or undecoded data
	dc.w	$1810	; $01C9F6  moveb %a0@,%d4
	dc.w	$3601	; $01C9F8  movew %d1,%d3
	dc.w	$2004	; $01C9FA  movel %d4,%d0
	dc.w	$E7A8	; $01C9FC  lsll %d3,%d0
	dc.w	$8480	; $01C9FE  orl %d0,%d2
	dc.w	$52B9	; $01CA00  addql #1,0x1ce0e
	dc.w	$0001	; $01CA02  extension word or undecoded data
	dc.w	$CE0E	; $01CA04  extension word or undecoded data
	dc.w	$5041	; $01CA06  addqw #8,%d1
	dc.w	$B27C	; $01CA08  cmpw #1,%d1
	dc.w	$0001	; $01CA0A  extension word or undecoded data
	dc.w	$63E2	; $01CA0C  blss 0x81c9f0
	dc.w	$3002	; $01CA0E  movew %d2,%d0
	dc.w	$C07C	; $01CA10  andw #3,%d0
	dc.w	$0003	; $01CA12  extension word or undecoded data
	dc.w	$E48A	; $01CA14  lsrl #2,%d2
	dc.w	$23C2	; $01CA16  movel %d2,0x1d71a
	dc.w	$0001	; $01CA18  extension word or undecoded data
	dc.w	$D71A	; $01CA1A  extension word or undecoded data
	dc.w	$5541	; $01CA1C  subqw #2,%d1
	dc.w	$33C1	; $01CA1E  movew %d1,0x1d71e
	dc.w	$0001	; $01CA20  extension word or undecoded data
	dc.w	$D71E	; $01CA22  extension word or undecoded data
	dc.w	$B07C	; $01CA24  cmpw #2,%d0
	dc.w	$0002	; $01CA26  extension word or undecoded data
	dc.w	$6600	; $01CA28  bnew 0x81ca36
	dc.w	$000C	; $01CA2A  extension word or undecoded data
	dc.w	$4EB9	; $01CA2C  jsr 0x81c4de
	dc.w	$0081	; $01CA2E  extension word or undecoded data
	dc.w	$C4DE	; $01CA30  extension word or undecoded data
	dc.w	$6000	; $01CA32  braw 0x81ca5a
	dc.w	$0026	; $01CA34  extension word or undecoded data
	dc.w	$4A40	; $01CA36  tstw %d0
	dc.w	$6600	; $01CA38  bnew 0x81ca46
	dc.w	$000C	; $01CA3A  extension word or undecoded data
	dc.w	$4EB9	; $01CA3C  jsr 0x81c210
	dc.w	$0081	; $01CA3E  extension word or undecoded data
	dc.w	$C210	; $01CA40  extension word or undecoded data
	dc.w	$6000	; $01CA42  braw 0x81ca5a
	dc.w	$0016	; $01CA44  extension word or undecoded data
	dc.w	$B07C	; $01CA46  cmpw #1,%d0
	dc.w	$0001	; $01CA48  extension word or undecoded data
	dc.w	$6700	; $01CA4A  beqw 0x81ca54
	dc.w	$0008	; $01CA4C  extension word or undecoded data
	dc.w	$7002	; $01CA4E  moveq #2,%d0
	dc.w	$6000	; $01CA50  braw 0x81ca5a
	dc.w	$0008	; $01CA52  extension word or undecoded data
	dc.w	$4EB9	; $01CA54  jsr 0x81c32c
	dc.w	$0081	; $01CA56  extension word or undecoded data
	dc.w	$C32C	; $01CA58  extension word or undecoded data
	dc.w	$4CEE	; $01CA5A  moveml %fp@(-16),%d2-%d5
	dc.w	$003C	; $01CA5C  extension word or undecoded data
	dc.w	$FFF0	; $01CA5E  extension word or undecoded data
	dc.w	$4E5E	; $01CA60  unlk %fp
	dc.w	$4E75	; $01CA62  rts
	dc.w	$4E56	; $01CA64  linkw %fp,#-4
	dc.w	$FFFC	; $01CA66  extension word or undecoded data
	dc.w	$2F02	; $01CA68  movel %d2,%sp@-
	dc.w	$720A	; $01CA6A  moveq #10,%d1
	dc.w	$D3B9	; $01CA6C  addl %d1,0x1ce0e
	dc.w	$0001	; $01CA6E  extension word or undecoded data
	dc.w	$CE0E	; $01CA70  extension word or undecoded data
	dc.w	$4879	; $01CA72  pea 0x81a638
	dc.w	$0081	; $01CA74  extension word or undecoded data
	dc.w	$A638	; $01CA76  extension word or undecoded data
	dc.w	$4EB9	; $01CA78  jsr 0x80b748
	dc.w	$0080	; $01CA7A  extension word or undecoded data
	dc.w	$B748	; $01CA7C  extension word or undecoded data
	dc.w	$584F	; $01CA7E  addqw #4,%sp
	dc.w	$4279	; $01CA80  clrw 0x1d718
	dc.w	$0001	; $01CA82  extension word or undecoded data
	dc.w	$D718	; $01CA84  extension word or undecoded data
	dc.w	$4279	; $01CA86  clrw 0x1d71e
	dc.w	$0001	; $01CA88  extension word or undecoded data
	dc.w	$D71E	; $01CA8A  extension word or undecoded data
	dc.w	$42B9	; $01CA8C  clrl 0x1d71a
	dc.w	$0001	; $01CA8E  extension word or undecoded data
	dc.w	$D71A	; $01CA90  extension word or undecoded data
	dc.w	$33FC	; $01CA92  movew #9,0x1d720
	dc.w	$0009	; $01CA94  extension word or undecoded data
	dc.w	$0001	; $01CA96  extension word or undecoded data
	dc.w	$D720	; $01CA98  extension word or undecoded data
	dc.w	$33FC	; $01CA9A  movew #6,0x1d722
	dc.w	$0006	; $01CA9C  extension word or undecoded data
	dc.w	$0001	; $01CA9E  extension word or undecoded data
	dc.w	$D722	; $01CAA0  extension word or undecoded data
	dc.w	$2F3C	; $01CAA2  movel #32768,%sp@-
	dc.w	$0000	; $01CAA4  extension word or undecoded data
	dc.w	$8000	; $01CAA6  extension word or undecoded data
	dc.w	$4879	; $01CAA8  pea 0x1f7000
	dc.w	$001F	; $01CAAA  extension word or undecoded data
	dc.w	$7000	; $01CAAC  extension word or undecoded data
	dc.w	$4EB9	; $01CAAE  jsr 0x81ba46
	dc.w	$0081	; $01CAB0  extension word or undecoded data
	dc.w	$BA46	; $01CAB2  extension word or undecoded data
	dc.w	$504F	; $01CAB4  addqw #8,%sp
	dc.w	$4242	; $01CAB6  clrw %d2
	dc.w	$4279	; $01CAB8  clrw 0x1d724
	dc.w	$0001	; $01CABA  extension word or undecoded data
	dc.w	$D724	; $01CABC  extension word or undecoded data
	dc.w	$486E	; $01CABE  pea %fp@(-2)
	dc.w	$FFFE	; $01CAC0  extension word or undecoded data
	dc.w	$4EB9	; $01CAC2  jsr 0x81c99e
	dc.w	$0081	; $01CAC4  extension word or undecoded data
	dc.w	$C99E	; $01CAC6  extension word or undecoded data
	dc.w	$584F	; $01CAC8  addqw #4,%sp
	dc.w	$4A40	; $01CACA  tstw %d0
	dc.w	$6600	; $01CACC  bnew 0x81caf4
	dc.w	$0026	; $01CACE  extension word or undecoded data
	dc.w	$B479	; $01CAD0  cmpw 0x1d724,%d2
	dc.w	$0001	; $01CAD2  extension word or undecoded data
	dc.w	$D724	; $01CAD4  extension word or undecoded data
	dc.w	$6400	; $01CAD6  bccw 0x81cae0
	dc.w	$0008	; $01CAD8  extension word or undecoded data
	dc.w	$3439	; $01CADA  movew 0x1d724,%d2
	dc.w	$0001	; $01CADC  extension word or undecoded data
	dc.w	$D724	; $01CADE  extension word or undecoded data
	dc.w	$4A6E	; $01CAE0  tstw %fp@(-2)
	dc.w	$FFFE	; $01CAE2  extension word or undecoded data
	dc.w	$67D2	; $01CAE4  beqs 0x81cab8
	dc.w	$3F39	; $01CAE6  movew 0x1d718,%sp@-
	dc.w	$0001	; $01CAE8  extension word or undecoded data
	dc.w	$D718	; $01CAEA  extension word or undecoded data
	dc.w	$4EB9	; $01CAEC  jsr 0x81c100
	dc.w	$0081	; $01CAEE  extension word or undecoded data
	dc.w	$C100	; $01CAF0  extension word or undecoded data
	dc.w	$4240	; $01CAF2  clrw %d0
	dc.w	$242E	; $01CAF4  movel %fp@(-8),%d2
	dc.w	$FFF8	; $01CAF6  extension word or undecoded data
	dc.w	$4E5E	; $01CAF8  unlk %fp
	dc.w	$4E75	; $01CAFA  rts
	dc.w	$0000	; $01CAFC  orib #0,%d0
	dc.w	$0000	; $01CAFE  extension word or undecoded data
; ---- ROM $01CB00: recovered boundary (semantic role unverified) ----
	dc.w	$4E56	; $01CB00  linkw %fp,#0
	dc.w	$0000	; $01CB02  extension word or undecoded data
	dc.w	$48E7	; $01CB04  moveml %d2-%d4,%sp@-
	dc.w	$3800	; $01CB06  extension word or undecoded data
	dc.w	$322E	; $01CB08  movew %fp@(8),%d1
	dc.w	$0008	; $01CB0A  extension word or undecoded data
	dc.w	$342E	; $01CB0C  movew %fp@(10),%d2
	dc.w	$000A	; $01CB0E  extension word or undecoded data
	dc.w	$362E	; $01CB10  movew %fp@(12),%d3
	dc.w	$000C	; $01CB12  extension word or undecoded data
	dc.w	$382E	; $01CB14  movew %fp@(14),%d4
	dc.w	$000E	; $01CB16  extension word or undecoded data
	dc.w	$3001	; $01CB18  movew %d1,%d0
	dc.w	$E940	; $01CB1A  aslw #4,%d0
	dc.w	$D041	; $01CB1C  addw %d1,%d0
	dc.w	$3202	; $01CB1E  movew %d2,%d1
	dc.w	$E341	; $01CB20  aslw #1,%d1
	dc.w	$D242	; $01CB22  addw %d2,%d1
	dc.w	$E541	; $01CB24  aslw #2,%d1
	dc.w	$9242	; $01CB26  subw %d2,%d1
	dc.w	$D041	; $01CB28  addw %d1,%d0
	dc.w	$3203	; $01CB2A  movew %d3,%d1
	dc.w	$E741	; $01CB2C  aslw #3,%d1
	dc.w	$9243	; $01CB2E  subw %d3,%d1
	dc.w	$D041	; $01CB30  addw %d1,%d0
	dc.w	$3204	; $01CB32  movew %d4,%d1
	dc.w	$E341	; $01CB34  aslw #1,%d1
	dc.w	$D244	; $01CB36  addw %d4,%d1
	dc.w	$D041	; $01CB38  addw %d1,%d0
	dc.w	$C07C	; $01CB3A  andw #31,%d0
	dc.w	$001F	; $01CB3C  extension word or undecoded data
	dc.w	$4CEE	; $01CB3E  moveml %fp@(-12),%d2-%d4
	dc.w	$001C	; $01CB40  extension word or undecoded data
	dc.w	$FFF4	; $01CB42  extension word or undecoded data
	dc.w	$4E5E	; $01CB44  unlk %fp
	dc.w	$4E75	; $01CB46  rts
	dc.w	$4E56	; $01CB48  linkw %fp,#0
	dc.w	$0000	; $01CB4A  extension word or undecoded data
	dc.w	$48E7	; $01CB4C  moveml %d2-%d6,%sp@-
	dc.w	$3E00	; $01CB4E  extension word or undecoded data
	dc.w	$322E	; $01CB50  movew %fp@(8),%d1
	dc.w	$0008	; $01CB52  extension word or undecoded data
	dc.w	$363C	; $01CB54  movew #255,%d3
	dc.w	$00FF	; $01CB56  extension word or undecoded data
	dc.w	$3803	; $01CB58  movew %d3,%d4
	dc.w	$C86E	; $01CB5A  andw %fp@(10),%d4
	dc.w	$000A	; $01CB5C  extension word or undecoded data
	dc.w	$3403	; $01CB5E  movew %d3,%d2
	dc.w	$C46E	; $01CB60  andw %fp@(12),%d2
	dc.w	$000C	; $01CB62  extension word or undecoded data
	dc.w	$C66E	; $01CB64  andw %fp@(14),%d3
	dc.w	$000E	; $01CB66  extension word or undecoded data
	dc.w	$2001	; $01CB68  movel %d1,%d0
	dc.w	$7C1D	; $01CB6A  moveq #29,%d6
	dc.w	$EDA0	; $01CB6C  asll %d6,%d0
	dc.w	$CABC	; $01CB6E  andl #536870911,%d5
	dc.w	$1FFF	; $01CB70  extension word or undecoded data
	dc.w	$FFFF	; $01CB72  extension word or undecoded data
	dc.w	$8A80	; $01CB74  orl %d0,%d5
	dc.w	$3F03	; $01CB76  movew %d3,%sp@-
	dc.w	$3F02	; $01CB78  movew %d2,%sp@-
	dc.w	$3F04	; $01CB7A  movew %d4,%sp@-
	dc.w	$3F01	; $01CB7C  movew %d1,%sp@-
	dc.w	$4EB9	; $01CB7E  jsr 0x81cb00
	dc.w	$0081	; $01CB80  extension word or undecoded data
	dc.w	$CB00	; $01CB82  extension word or undecoded data
	dc.w	$7C1F	; $01CB84  moveq #31,%d6
	dc.w	$C086	; $01CB86  andl %d6,%d0
	dc.w	$E148	; $01CB88  lslw #8,%d0
	dc.w	$4840	; $01CB8A  swap %d0
	dc.w	$4240	; $01CB8C  clrw %d0
	dc.w	$CABC	; $01CB8E  andl #-520093697,%d5
	dc.w	$E0FF	; $01CB90  extension word or undecoded data
	dc.w	$FFFF	; $01CB92  extension word or undecoded data
	dc.w	$8A80	; $01CB94  orl %d0,%d5
	dc.w	$4844	; $01CB96  swap %d4
	dc.w	$4244	; $01CB98  clrw %d4
	dc.w	$CABC	; $01CB9A  andl #-16711681,%d5
	dc.w	$FF00	; $01CB9C  extension word or undecoded data
	dc.w	$FFFF	; $01CB9E  extension word or undecoded data
	dc.w	$8A84	; $01CBA0  orl %d4,%d5
	dc.w	$C4BC	; $01CBA2  andl #255,%d2
	dc.w	$0000	; $01CBA4  extension word or undecoded data
	dc.w	$00FF	; $01CBA6  extension word or undecoded data
	dc.w	$E18A	; $01CBA8  lsll #8,%d2
	dc.w	$CA7C	; $01CBAA  andw #255,%d5
	dc.w	$00FF	; $01CBAC  extension word or undecoded data
	dc.w	$8A82	; $01CBAE  orl %d2,%d5
	dc.w	$1A03	; $01CBB0  moveb %d3,%d5
	dc.w	$2005	; $01CBB2  movel %d5,%d0
	dc.w	$4CEE	; $01CBB4  moveml %fp@(-20),%d2-%d6
	dc.w	$007C	; $01CBB6  extension word or undecoded data
	dc.w	$FFEC	; $01CBB8  extension word or undecoded data
	dc.w	$4E5E	; $01CBBA  unlk %fp
	dc.w	$4E75	; $01CBBC  rts
	dc.w	$4E56	; $01CBBE  linkw %fp,#0
	dc.w	$0000	; $01CBC0  extension word or undecoded data
	dc.w	$48E7	; $01CBC2  moveml %d2-%d4,%sp@-
	dc.w	$3800	; $01CBC4  extension word or undecoded data
	dc.w	$222E	; $01CBC6  movel %fp@(8),%d1
	dc.w	$0008	; $01CBC8  extension word or undecoded data
	dc.w	$2601	; $01CBCA  movel %d1,%d3
	dc.w	$4243	; $01CBCC  clrw %d3
	dc.w	$4843	; $01CBCE  swap %d3
	dc.w	$E04B	; $01CBD0  lsrw #8,%d3
	dc.w	$1003	; $01CBD2  moveb %d3,%d0
	dc.w	$C03C	; $01CBD4  andb #-32,%d0
	dc.w	$00E0	; $01CBD6  extension word or undecoded data
	dc.w	$6700	; $01CBD8  beqw 0x81cbea
	dc.w	$0010	; $01CBDA  extension word or undecoded data
	dc.w	$2401	; $01CBDC  movel %d1,%d2
	dc.w	$781D	; $01CBDE  moveq #29,%d4
	dc.w	$E8AA	; $01CBE0  lsrl %d4,%d2
	dc.w	$B47C	; $01CBE2  cmpw #5,%d2
	dc.w	$0005	; $01CBE4  extension word or undecoded data
	dc.w	$6300	; $01CBE6  blsw 0x81cbf0
	dc.w	$0008	; $01CBE8  extension word or undecoded data
	dc.w	$4240	; $01CBEA  clrw %d0
	dc.w	$6000	; $01CBEC  braw 0x81cc22
	dc.w	$0034	; $01CBEE  extension word or undecoded data
	dc.w	$4267	; $01CBF0  clrw %sp@-
	dc.w	$1F41	; $01CBF2  moveb %d1,%sp@(1)
	dc.w	$0001	; $01CBF4  extension word or undecoded data
	dc.w	$2001	; $01CBF6  movel %d1,%d0
	dc.w	$E088	; $01CBF8  lsrl #8,%d0
	dc.w	$4267	; $01CBFA  clrw %sp@-
	dc.w	$1F40	; $01CBFC  moveb %d0,%sp@(1)
	dc.w	$0001	; $01CBFE  extension word or undecoded data
	dc.w	$2001	; $01CC00  movel %d1,%d0
	dc.w	$4240	; $01CC02  clrw %d0
	dc.w	$4840	; $01CC04  swap %d0
	dc.w	$4267	; $01CC06  clrw %sp@-
	dc.w	$1F40	; $01CC08  moveb %d0,%sp@(1)
	dc.w	$0001	; $01CC0A  extension word or undecoded data
	dc.w	$3F02	; $01CC0C  movew %d2,%sp@-
	dc.w	$4EB9	; $01CC0E  jsr 0x81cb00
	dc.w	$0081	; $01CC10  extension word or undecoded data
	dc.w	$CB00	; $01CC12  extension word or undecoded data
	dc.w	$3203	; $01CC14  movew %d3,%d1
	dc.w	$C27C	; $01CC16  andw #31,%d1
	dc.w	$001F	; $01CC18  extension word or undecoded data
	dc.w	$B240	; $01CC1A  cmpw %d0,%d1
	dc.w	$57C0	; $01CC1C  seq %d0
	dc.w	$4880	; $01CC1E  extw %d0
	dc.w	$4440	; $01CC20  negw %d0
	dc.w	$4CEE	; $01CC22  moveml %fp@(-12),%d2-%d4
	dc.w	$001C	; $01CC24  extension word or undecoded data
	dc.w	$FFF4	; $01CC26  extension word or undecoded data
	dc.w	$4E5E	; $01CC28  unlk %fp
	dc.w	$4E75	; $01CC2A  rts
	dc.w	$4E56	; $01CC2C  linkw %fp,#0
	dc.w	$0000	; $01CC2E  extension word or undecoded data
	dc.w	$3039	; $01CC30  movew 0x1d734,%d0
	dc.w	$0001	; $01CC32  extension word or undecoded data
	dc.w	$D734	; $01CC34  extension word or undecoded data
	dc.w	$5279	; $01CC36  addqw #1,0x1d734
	dc.w	$0001	; $01CC38  extension word or undecoded data
	dc.w	$D734	; $01CC3A  extension word or undecoded data
	dc.w	$B07C	; $01CC3C  cmpw #3,%d0
	dc.w	$0003	; $01CC3E  extension word or undecoded data
	dc.w	$6F00	; $01CC40  blew 0x81cc50
	dc.w	$000E	; $01CC42  extension word or undecoded data
	dc.w	$2F3C	; $01CC44  movel #-17965393,%sp@-
	dc.w	$FEED	; $01CC46  extension word or undecoded data
	dc.w	$DEAF	; $01CC48  extension word or undecoded data
	dc.w	$4EB9	; $01CC4A  jsr 0x81ba38
	dc.w	$0081	; $01CC4C  extension word or undecoded data
	dc.w	$BA38	; $01CC4E  extension word or undecoded data
	dc.w	$4E5E	; $01CC50  unlk %fp
	dc.w	$4E75	; $01CC52  rts
	dc.w	$4E56	; $01CC54  linkw %fp,#0
	dc.w	$0000	; $01CC56  extension word or undecoded data
	dc.w	$2F03	; $01CC58  movel %d3,%sp@-
	dc.w	$2F02	; $01CC5A  movel %d2,%sp@-
	dc.w	$242E	; $01CC5C  movel %fp@(8),%d2
	dc.w	$0008	; $01CC5E  extension word or undecoded data
	dc.w	$52B9	; $01CC60  addql #1,0x1d730
	dc.w	$0001	; $01CC62  extension word or undecoded data
	dc.w	$D730	; $01CC64  extension word or undecoded data
	dc.w	$2F02	; $01CC66  movel %d2,%sp@-
	dc.w	$4EB9	; $01CC68  jsr 0x81cbbe
	dc.w	$0081	; $01CC6A  extension word or undecoded data
	dc.w	$CBBE	; $01CC6C  extension word or undecoded data
	dc.w	$584F	; $01CC6E  addqw #4,%sp
	dc.w	$4A40	; $01CC70  tstw %d0
	dc.w	$6700	; $01CC72  beqw 0x81cce4
	dc.w	$0070	; $01CC74  extension word or undecoded data
	dc.w	$2002	; $01CC76  movel %d2,%d0
	dc.w	$761D	; $01CC78  moveq #29,%d3
	dc.w	$E6A8	; $01CC7A  lsrl %d3,%d0
	dc.w	$5340	; $01CC7C  subqw #1,%d0
	dc.w	$B07C	; $01CC7E  cmpw #4,%d0
	dc.w	$0004	; $01CC80  extension word or undecoded data
	dc.w	$6200	; $01CC82  bhiw 0x81cd88
	dc.w	$0104	; $01CC84  extension word or undecoded data
	dc.w	$C0BC	; $01CC86  andl #65535,%d0
	dc.w	$0000	; $01CC88  extension word or undecoded data
	dc.w	$FFFF	; $01CC8A  extension word or undecoded data
	dc.w	$D080	; $01CC8C  addl %d0,%d0
	dc.w	$303B	; $01CC8E  movew %pc@(0x81cc96,%d0:l),%d0
	dc.w	$0806	; $01CC90  extension word or undecoded data
	dc.w	$4EFB	; $01CC92  jmp %pc@(0x81cc96,%d0:w)
	dc.w	$0002	; $01CC94  extension word or undecoded data
	dc.w	$000A	; $01CC96  012
	dc.w	$0042	; $01CC98  oriw #172,%d2
	dc.w	$00AC	; $01CC9A  extension word or undecoded data
	dc.w	$00BE	; $01CC9C  oril #14950402,%d6
	dc.w	$00E4	; $01CC9E  extension word or undecoded data
	dc.w	$2002	; $01CCA0  extension word or undecoded data
	dc.w	$4240	; $01CCA2  clrw %d0
	dc.w	$4840	; $01CCA4  swap %d0
	dc.w	$E140	; $01CCA6  aslw #8,%d0
	dc.w	$2202	; $01CCA8  movel %d2,%d1
	dc.w	$E089	; $01CCAA  lsrl #8,%d1
	dc.w	$C27C	; $01CCAC  andw #255,%d1
	dc.w	$00FF	; $01CCAE  extension word or undecoded data
	dc.w	$8041	; $01CCB0  orw %d1,%d0
	dc.w	$33C0	; $01CCB2  movew %d0,0x1d736
	dc.w	$0001	; $01CCB4  extension word or undecoded data
	dc.w	$D736	; $01CCB6  extension word or undecoded data
	dc.w	$2002	; $01CCB8  movel %d2,%d0
	dc.w	$E180	; $01CCBA  asll #8,%d0
	dc.w	$C07C	; $01CCBC  andw #-256,%d0
	dc.w	$FF00	; $01CCBE  extension word or undecoded data
	dc.w	$33C0	; $01CCC0  movew %d0,0x1d738
	dc.w	$0001	; $01CCC2  extension word or undecoded data
	dc.w	$D738	; $01CCC4  extension word or undecoded data
	dc.w	$4279	; $01CCC6  clrw 0x1d73a
	dc.w	$0001	; $01CCC8  extension word or undecoded data
	dc.w	$D73A	; $01CCCA  extension word or undecoded data
	dc.w	$33FC	; $01CCCC  movew #2,0x1d73c
	dc.w	$0002	; $01CCCE  extension word or undecoded data
	dc.w	$0001	; $01CCD0  extension word or undecoded data
	dc.w	$D73C	; $01CCD2  extension word or undecoded data
	dc.w	$6000	; $01CCD4  braw 0x81cd88
	dc.w	$00B2	; $01CCD6  extension word or undecoded data
	dc.w	$0C79	; $01CCD8  cmpiw #2,0x1d73c
	dc.w	$0002	; $01CCDA  extension word or undecoded data
	dc.w	$0001	; $01CCDC  extension word or undecoded data
	dc.w	$D73C	; $01CCDE  extension word or undecoded data
	dc.w	$6700	; $01CCE0  beqw 0x81ccf6
	dc.w	$0014	; $01CCE2  extension word or undecoded data
	dc.w	$52B9	; $01CCE4  addql #1,0x1d72c
	dc.w	$0001	; $01CCE6  extension word or undecoded data
	dc.w	$D72C	; $01CCE8  extension word or undecoded data
	dc.w	$2F02	; $01CCEA  movel %d2,%sp@-
	dc.w	$4EB9	; $01CCEC  jsr 0x81cc2c
	dc.w	$0081	; $01CCEE  extension word or undecoded data
	dc.w	$CC2C	; $01CCF0  extension word or undecoded data
	dc.w	$6000	; $01CCF2  braw 0x81cd8e
	dc.w	$009A	; $01CCF4  extension word or undecoded data
	dc.w	$2002	; $01CCF6  movel %d2,%d0
	dc.w	$4240	; $01CCF8  clrw %d0
	dc.w	$4840	; $01CCFA  swap %d0
	dc.w	$C07C	; $01CCFC  andw #255,%d0
	dc.w	$00FF	; $01CCFE  extension word or undecoded data
	dc.w	$8079	; $01CD00  orw 0x1d738,%d0
	dc.w	$0001	; $01CD02  extension word or undecoded data
	dc.w	$D738	; $01CD04  extension word or undecoded data
	dc.w	$33C0	; $01CD06  movew %d0,0x1d738
	dc.w	$0001	; $01CD08  extension word or undecoded data
	dc.w	$D738	; $01CD0A  extension word or undecoded data
	dc.w	$3202	; $01CD0C  movew %d2,%d1
	dc.w	$33C1	; $01CD0E  movew %d1,0x1d73a
	dc.w	$0001	; $01CD10  extension word or undecoded data
	dc.w	$D73A	; $01CD12  extension word or undecoded data
	dc.w	$3F01	; $01CD14  movew %d1,%sp@-
	dc.w	$3F00	; $01CD16  movew %d0,%sp@-
	dc.w	$3F39	; $01CD18  movew 0x1d736,%sp@-
	dc.w	$0001	; $01CD1A  extension word or undecoded data
	dc.w	$D736	; $01CD1C  extension word or undecoded data
	dc.w	$4EB9	; $01CD1E  jsr 0x809de8
	dc.w	$0080	; $01CD20  extension word or undecoded data
	dc.w	$9DE8	; $01CD22  extension word or undecoded data
	dc.w	$33FC	; $01CD24  movew #1,0x1d73c
	dc.w	$0001	; $01CD26  extension word or undecoded data
	dc.w	$0001	; $01CD28  extension word or undecoded data
	dc.w	$D73C	; $01CD2A  extension word or undecoded data
	dc.w	$4279	; $01CD2C  clrw 0x1d73a
	dc.w	$0001	; $01CD2E  extension word or undecoded data
	dc.w	$D73A	; $01CD30  extension word or undecoded data
	dc.w	$4279	; $01CD32  clrw 0x1d738
	dc.w	$0001	; $01CD34  extension word or undecoded data
	dc.w	$D738	; $01CD36  extension word or undecoded data
	dc.w	$4279	; $01CD38  clrw 0x1d736
	dc.w	$0001	; $01CD3A  extension word or undecoded data
	dc.w	$D736	; $01CD3C  extension word or undecoded data
	dc.w	$6000	; $01CD3E  braw 0x81cd88
	dc.w	$0048	; $01CD40  extension word or undecoded data
	dc.w	$C4BC	; $01CD42  andl #16777215,%d2
	dc.w	$00FF	; $01CD44  extension word or undecoded data
	dc.w	$FFFF	; $01CD46  extension word or undecoded data
	dc.w	$2F02	; $01CD48  movel %d2,%sp@-
	dc.w	$4EB9	; $01CD4A  jsr 0x809e28
	dc.w	$0080	; $01CD4C  extension word or undecoded data
	dc.w	$9E28	; $01CD4E  extension word or undecoded data
	dc.w	$6000	; $01CD50  braw 0x81cd88
	dc.w	$0036	; $01CD52  extension word or undecoded data
	dc.w	$4267	; $01CD54  clrw %sp@-
	dc.w	$1F42	; $01CD56  moveb %d2,%sp@(1)
	dc.w	$0001	; $01CD58  extension word or undecoded data
	dc.w	$2002	; $01CD5A  movel %d2,%d0
	dc.w	$E088	; $01CD5C  lsrl #8,%d0
	dc.w	$4267	; $01CD5E  clrw %sp@-
	dc.w	$1F40	; $01CD60  moveb %d0,%sp@(1)
	dc.w	$0001	; $01CD62  extension word or undecoded data
	dc.w	$2002	; $01CD64  movel %d2,%d0
	dc.w	$4240	; $01CD66  clrw %d0
	dc.w	$4840	; $01CD68  swap %d0
	dc.w	$4267	; $01CD6A  clrw %sp@-
	dc.w	$1F40	; $01CD6C  moveb %d0,%sp@(1)
	dc.w	$0001	; $01CD6E  extension word or undecoded data
	dc.w	$4EB9	; $01CD70  jsr 0x809e3e
	dc.w	$0080	; $01CD72  extension word or undecoded data
	dc.w	$9E3E	; $01CD74  extension word or undecoded data
	dc.w	$6000	; $01CD76  braw 0x81cd88
	dc.w	$0010	; $01CD78  extension word or undecoded data
	dc.w	$C4BC	; $01CD7A  andl #16777215,%d2
	dc.w	$00FF	; $01CD7C  extension word or undecoded data
	dc.w	$FFFF	; $01CD7E  extension word or undecoded data
	dc.w	$2F02	; $01CD80  movel %d2,%sp@-
	dc.w	$4EB9	; $01CD82  jsr 0x809f06
	dc.w	$0080	; $01CD84  extension word or undecoded data
	dc.w	$9F06	; $01CD86  extension word or undecoded data
	dc.w	$4279	; $01CD88  clrw 0x1d734
	dc.w	$0001	; $01CD8A  extension word or undecoded data
	dc.w	$D734	; $01CD8C  extension word or undecoded data
	dc.w	$242E	; $01CD8E  movel %fp@(-8),%d2
	dc.w	$FFF8	; $01CD90  extension word or undecoded data
	dc.w	$262E	; $01CD92  movel %fp@(-4),%d3
	dc.w	$FFFC	; $01CD94  extension word or undecoded data
	dc.w	$4E5E	; $01CD96  unlk %fp
	dc.w	$4E75	; $01CD98  rts
	dc.w	$4E56	; $01CD9A  linkw %fp,#-4
	dc.w	$FFFC	; $01CD9C  extension word or undecoded data
	dc.w	$48E7	; $01CD9E  moveml %d2-%d6,%sp@-
	dc.w	$3E00	; $01CDA0  extension word or undecoded data
	dc.w	$4EB9	; $01CDA2  jsr 0x809e86
	dc.w	$0080	; $01CDA4  extension word or undecoded data
	dc.w	$9E86	; $01CDA6  extension word or undecoded data
	dc.w	$2200	; $01CDA8  movel %d0,%d1
	dc.w	$3039	; $01CDAA  movew 0x1d73e,%d0
	dc.w	$0001	; $01CDAC  extension word or undecoded data
	dc.w	$D73E	; $01CDAE  extension word or undecoded data
	dc.w	$5340	; $01CDB0  subqw #1,%d0
	dc.w	$B07C	; $01CDB2  cmpw #4,%d0
	dc.w	$0004	; $01CDB4  extension word or undecoded data
	dc.w	$6200	; $01CDB6  bhiw 0x81ce14
	dc.w	$005C	; $01CDB8  extension word or undecoded data
	dc.w	$C0BC	; $01CDBA  andl #65535,%d0
	dc.w	$0000	; $01CDBC  extension word or undecoded data
	dc.w	$FFFF	; $01CDBE  extension word or undecoded data
	dc.w	$D080	; $01CDC0  addl %d0,%d0
	dc.w	$303B	; $01CDC2  movew %pc@(0x81cdca,%d0:l),%d0
	dc.w	$0806	; $01CDC4  extension word or undecoded data
	dc.w	$4EFB	; $01CDC6  jmp %pc@(0x81cdca,%d0:w)
	dc.w	$0002	; $01CDC8  extension word or undecoded data
	dc.w	$000A	; $01CDCA  012
	dc.w	$0010	; $01CDCC  orib #68,%a0@
	dc.w	$0044	; $01CDCE  extension word or undecoded data
	dc.w	$003E	; $01CDD0  076
	dc.w	$003E	; $01CDD2  076
	dc.w	$7402	; $01CDD4  moveq #2,%d2
	dc.w	$6000	; $01CDD6  braw 0x81ce16
	dc.w	$003E	; $01CDD8  extension word or undecoded data
	dc.w	$B2B9	; $01CDDA  cmpl 0x1d74c,%d1
	dc.w	$0001	; $01CDDC  extension word or undecoded data
	dc.w	$D74C	; $01CDDE  extension word or undecoded data
	dc.w	$6600	; $01CDE0  bnew 0x81cdf6
	dc.w	$0014	; $01CDE2  extension word or undecoded data
	dc.w	$5279	; $01CDE4  addqw #1,0x1d750
	dc.w	$0001	; $01CDE6  extension word or undecoded data
	dc.w	$D750	; $01CDE8  extension word or undecoded data
	dc.w	$0C79	; $01CDEA  cmpiw #4,0x1d750
	dc.w	$0004	; $01CDEC  extension word or undecoded data
	dc.w	$0001	; $01CDEE  extension word or undecoded data
	dc.w	$D750	; $01CDF0  extension word or undecoded data
	dc.w	$6300	; $01CDF2  blsw 0x81ce02
	dc.w	$000E	; $01CDF4  extension word or undecoded data
	dc.w	$7403	; $01CDF6  moveq #3,%d2
	dc.w	$4279	; $01CDF8  clrw 0x1d750
	dc.w	$0001	; $01CDFA  extension word or undecoded data
	dc.w	$D750	; $01CDFC  extension word or undecoded data
	dc.w	$6000	; $01CDFE  braw 0x81ce16
	dc.w	$0016	; $01CE00  extension word or undecoded data
	dc.w	$7404	; $01CE02  moveq #4,%d2
	dc.w	$6000	; $01CE04  braw 0x81ce16
	dc.w	$0010	; $01CE06  extension word or undecoded data
	dc.w	$7401	; $01CE08  moveq #1,%d2
	dc.w	$6000	; $01CE0A  braw 0x81ce16
	dc.w	$000A	; $01CE0C  extension word or undecoded data
	dc.w	$7405	; $01CE0E  moveq #5,%d2
	dc.w	$6000	; $01CE10  braw 0x81ce16
	dc.w	$0004	; $01CE12  extension word or undecoded data
	dc.w	$7403	; $01CE14  moveq #3,%d2
	dc.w	$4AB9	; $01CE16  tstl 0x1d74c
	dc.w	$0001	; $01CE18  extension word or undecoded data
	dc.w	$D74C	; $01CE1A  extension word or undecoded data
	dc.w	$6600	; $01CE1C  bnew 0x81ce22
	dc.w	$0004	; $01CE1E  extension word or undecoded data
	dc.w	$7403	; $01CE20  moveq #3,%d2
	dc.w	$3002	; $01CE22  movew %d2,%d0
	dc.w	$5340	; $01CE24  subqw #1,%d0
	dc.w	$B07C	; $01CE26  cmpw #4,%d0
	dc.w	$0004	; $01CE28  extension word or undecoded data
	dc.w	$6200	; $01CE2A  bhiw 0x81cf16
	dc.w	$00EA	; $01CE2C  extension word or undecoded data
	dc.w	$C0BC	; $01CE2E  andl #65535,%d0
	dc.w	$0000	; $01CE30  extension word or undecoded data
	dc.w	$FFFF	; $01CE32  extension word or undecoded data
	dc.w	$D080	; $01CE34  addl %d0,%d0
	dc.w	$303B	; $01CE36  movew %pc@(0x81ce3e,%d0:l),%d0
	dc.w	$0806	; $01CE38  extension word or undecoded data
	dc.w	$4EFB	; $01CE3A  jmp %pc@(0x81ce3e,%d0:w)
	dc.w	$0002	; $01CE3C  extension word or undecoded data
	dc.w	$000A	; $01CE3E  012
	dc.w	$0056	; $01CE40  oriw #158,%fp@
	dc.w	$009E	; $01CE42  extension word or undecoded data
	dc.w	$0082	; $01CE44  oril #12209849,%d2
	dc.w	$00BA	; $01CE46  extension word or undecoded data
	dc.w	$4EB9	; $01CE48  extension word or undecoded data
	dc.w	$0080	; $01CE4A  oril #-1634590656,%d0
	dc.w	$9E92	; $01CE4C  extension word or undecoded data
	dc.w	$2040	; $01CE4E  extension word or undecoded data
	dc.w	$23D0	; $01CE50  movel %a0@,0x1d740
	dc.w	$0001	; $01CE52  extension word or undecoded data
	dc.w	$D740	; $01CE54  extension word or undecoded data
	dc.w	$23E8	; $01CE56  movel %a0@(4),0x1d744
	dc.w	$0004	; $01CE58  extension word or undecoded data
	dc.w	$0001	; $01CE5A  extension word or undecoded data
	dc.w	$D744	; $01CE5C  extension word or undecoded data
	dc.w	$23E8	; $01CE5E  movel %a0@(8),0x1d748
	dc.w	$0008	; $01CE60  extension word or undecoded data
	dc.w	$0001	; $01CE62  extension word or undecoded data
	dc.w	$D748	; $01CE64  extension word or undecoded data
	dc.w	$2079	; $01CE66  moveal 0x1d74c,%a0
	dc.w	$0001	; $01CE68  extension word or undecoded data
	dc.w	$D74C	; $01CE6A  extension word or undecoded data
	dc.w	$2039	; $01CE6C  movel 0x1d740,%d0
	dc.w	$0001	; $01CE6E  extension word or undecoded data
	dc.w	$D740	; $01CE70  extension word or undecoded data
	dc.w	$90A8	; $01CE72  subl %a0@(16),%d0
	dc.w	$0010	; $01CE74  extension word or undecoded data
	dc.w	$7C0C	; $01CE76  moveq #12,%d6
	dc.w	$ECA0	; $01CE78  asrl %d6,%d0
	dc.w	$2239	; $01CE7A  movel 0x1d744,%d1
	dc.w	$0001	; $01CE7C  extension word or undecoded data
	dc.w	$D744	; $01CE7E  extension word or undecoded data
	dc.w	$92A8	; $01CE80  subl %a0@(20),%d1
	dc.w	$0014	; $01CE82  extension word or undecoded data
	dc.w	$ECA1	; $01CE84  asrl %d6,%d1
	dc.w	$3A00	; $01CE86  movew %d0,%d5
	dc.w	$E045	; $01CE88  asrw #8,%d5
	dc.w	$1800	; $01CE8A  moveb %d0,%d4
	dc.w	$3601	; $01CE8C  movew %d1,%d3
	dc.w	$E043	; $01CE8E  asrw #8,%d3
	dc.w	$6000	; $01CE90  braw 0x81cf16
	dc.w	$0084	; $01CE92  extension word or undecoded data
	dc.w	$2079	; $01CE94  moveal 0x1d74c,%a0
	dc.w	$0001	; $01CE96  extension word or undecoded data
	dc.w	$D74C	; $01CE98  extension word or undecoded data
	dc.w	$2239	; $01CE9A  movel 0x1d744,%d1
	dc.w	$0001	; $01CE9C  extension word or undecoded data
	dc.w	$D744	; $01CE9E  extension word or undecoded data
	dc.w	$92A8	; $01CEA0  subl %a0@(20),%d1
	dc.w	$0014	; $01CEA2  extension word or undecoded data
	dc.w	$2039	; $01CEA4  movel 0x1d748,%d0
	dc.w	$0001	; $01CEA6  extension word or undecoded data
	dc.w	$D748	; $01CEA8  extension word or undecoded data
	dc.w	$90A8	; $01CEAA  subl %a0@(24),%d0
	dc.w	$0018	; $01CEAC  extension word or undecoded data
	dc.w	$7C0C	; $01CEAE  moveq #12,%d6
	dc.w	$ECA0	; $01CEB0  asrl %d6,%d0
	dc.w	$2A01	; $01CEB2  movel %d1,%d5
	dc.w	$ECA5	; $01CEB4  asrl %d6,%d5
	dc.w	$3800	; $01CEB6  movew %d0,%d4
	dc.w	$E044	; $01CEB8  asrw #8,%d4
	dc.w	$1600	; $01CEBA  moveb %d0,%d3
	dc.w	$6000	; $01CEBC  braw 0x81cf16
	dc.w	$0058	; $01CEBE  extension word or undecoded data
	dc.w	$486E	; $01CEC0  pea %fp@(-4)
	dc.w	$FFFC	; $01CEC2  extension word or undecoded data
	dc.w	$4EB9	; $01CEC4  jsr 0x809ea0
	dc.w	$0080	; $01CEC6  extension word or undecoded data
	dc.w	$9EA0	; $01CEC8  extension word or undecoded data
	dc.w	$584F	; $01CECA  addqw #4,%sp
	dc.w	$1A2E	; $01CECC  moveb %fp@(-4),%d5
	dc.w	$FFFC	; $01CECE  extension word or undecoded data
	dc.w	$182E	; $01CED0  moveb %fp@(-3),%d4
	dc.w	$FFFD	; $01CED2  extension word or undecoded data
	dc.w	$162E	; $01CED4  moveb %fp@(-2),%d3
	dc.w	$FFFE	; $01CED6  extension word or undecoded data
	dc.w	$6000	; $01CED8  braw 0x81cf16
	dc.w	$003C	; $01CEDA  extension word or undecoded data
	dc.w	$4279	; $01CEDC  clrw 0x1d750
	dc.w	$0001	; $01CEDE  extension word or undecoded data
	dc.w	$D750	; $01CEE0  extension word or undecoded data
	dc.w	$23C1	; $01CEE2  movel %d1,0x1d74c
	dc.w	$0001	; $01CEE4  extension word or undecoded data
	dc.w	$D74C	; $01CEE6  extension word or undecoded data
	dc.w	$2A01	; $01CEE8  movel %d1,%d5
	dc.w	$4245	; $01CEEA  clrw %d5
	dc.w	$4845	; $01CEEC  swap %d5
	dc.w	$2801	; $01CEEE  movel %d1,%d4
	dc.w	$E08C	; $01CEF0  lsrl #8,%d4
	dc.w	$1601	; $01CEF2  moveb %d1,%d3
	dc.w	$6000	; $01CEF4  braw 0x81cf16
	dc.w	$0020	; $01CEF6  extension word or undecoded data
	dc.w	$4EB9	; $01CEF8  jsr 0x809ec4
	dc.w	$0080	; $01CEFA  extension word or undecoded data
	dc.w	$9EC4	; $01CEFC  extension word or undecoded data
	dc.w	$23C0	; $01CEFE  movel %d0,0x1d754
	dc.w	$0001	; $01CF00  extension word or undecoded data
	dc.w	$D754	; $01CF02  extension word or undecoded data
	dc.w	$1A39	; $01CF04  moveb 0x1d755,%d5
	dc.w	$0001	; $01CF06  extension word or undecoded data
	dc.w	$D755	; $01CF08  extension word or undecoded data
	dc.w	$1839	; $01CF0A  moveb 0x1d756,%d4
	dc.w	$0001	; $01CF0C  extension word or undecoded data
	dc.w	$D756	; $01CF0E  extension word or undecoded data
	dc.w	$1639	; $01CF10  moveb 0x1d757,%d3
	dc.w	$0001	; $01CF12  extension word or undecoded data
	dc.w	$D757	; $01CF14  extension word or undecoded data
	dc.w	$33C2	; $01CF16  movew %d2,0x1d73e
	dc.w	$0001	; $01CF18  extension word or undecoded data
	dc.w	$D73E	; $01CF1A  extension word or undecoded data
	dc.w	$52B9	; $01CF1C  addql #1,0x1d728
	dc.w	$0001	; $01CF1E  extension word or undecoded data
	dc.w	$D728	; $01CF20  extension word or undecoded data
	dc.w	$4267	; $01CF22  clrw %sp@-
	dc.w	$1F43	; $01CF24  moveb %d3,%sp@(1)
	dc.w	$0001	; $01CF26  extension word or undecoded data
	dc.w	$4267	; $01CF28  clrw %sp@-
	dc.w	$1F44	; $01CF2A  moveb %d4,%sp@(1)
	dc.w	$0001	; $01CF2C  extension word or undecoded data
	dc.w	$4267	; $01CF2E  clrw %sp@-
	dc.w	$1F45	; $01CF30  moveb %d5,%sp@(1)
	dc.w	$0001	; $01CF32  extension word or undecoded data
	dc.w	$3F02	; $01CF34  movew %d2,%sp@-
	dc.w	$4EB9	; $01CF36  jsr 0x81cb48
	dc.w	$0081	; $01CF38  extension word or undecoded data
	dc.w	$CB48	; $01CF3A  extension word or undecoded data
	dc.w	$4CEE	; $01CF3C  moveml %fp@(-24),%d2-%d6
	dc.w	$007C	; $01CF3E  extension word or undecoded data
	dc.w	$FFE8	; $01CF40  extension word or undecoded data
	dc.w	$4E5E	; $01CF42  unlk %fp
	dc.w	$4E75	; $01CF44  rts
	dc.w	$4E56	; $01CF46  linkw %fp,#0
	dc.w	$0000	; $01CF48  extension word or undecoded data
	dc.w	$33FC	; $01CF4A  movew #-1,0x1d73e
	dc.w	$FFFF	; $01CF4C  extension word or undecoded data
	dc.w	$0001	; $01CF4E  extension word or undecoded data
	dc.w	$D73E	; $01CF50  extension word or undecoded data
	dc.w	$42B9	; $01CF52  clrl 0x1d74c
	dc.w	$0001	; $01CF54  extension word or undecoded data
	dc.w	$D74C	; $01CF56  extension word or undecoded data
	dc.w	$4279	; $01CF58  clrw 0x1d734
	dc.w	$0001	; $01CF5A  extension word or undecoded data
	dc.w	$D734	; $01CF5C  extension word or undecoded data
	dc.w	$42B9	; $01CF5E  clrl 0x1d72c
	dc.w	$0001	; $01CF60  extension word or undecoded data
	dc.w	$D72C	; $01CF62  extension word or undecoded data
	dc.w	$42B9	; $01CF64  clrl 0x1d730
	dc.w	$0001	; $01CF66  extension word or undecoded data
	dc.w	$D730	; $01CF68  extension word or undecoded data
	dc.w	$42B9	; $01CF6A  clrl 0x1d728
	dc.w	$0001	; $01CF6C  extension word or undecoded data
	dc.w	$D728	; $01CF6E  extension word or undecoded data
	dc.w	$33FC	; $01CF70  movew #1,0x1d752
	dc.w	$0001	; $01CF72  extension word or undecoded data
	dc.w	$0001	; $01CF74  extension word or undecoded data
	dc.w	$D752	; $01CF76  extension word or undecoded data
	dc.w	$4E5E	; $01CF78  unlk %fp
	dc.w	$4E75	; $01CF7A  rts
	dc.w	$0000	; $01CF7C  orib #0,%d0
	dc.w	$0000	; $01CF7E  extension word or undecoded data
	dc.w	$7880	; $01CF80  moveq #-128,%d4
	dc.w	$7880	; $01CF82  moveq #-128,%d4
	dc.w	$7880	; $01CF84  moveq #-128,%d4
	dc.w	$7880	; $01CF86  moveq #-128,%d4
	dc.w	$0000	; $01CF88  orib #-64,%d0
	dc.w	$78C0	; $01CF8A  extension word or undecoded data
	dc.w	$0000	; $01CF8C  extension word or undecoded data
	dc.w	$0000	; $01CF8E  extension word or undecoded data
	dc.w	$0000	; $01CF90  extension word or undecoded data
	dc.w	$0000	; $01CF92  extension word or undecoded data
	dc.w	$0000	; $01CF94  extension word or undecoded data
	dc.w	$0000	; $01CF96  extension word or undecoded data
	dc.w	$0000	; $01CF98  extension word or undecoded data
	dc.w	$0000	; $01CF9A  extension word or undecoded data
	dc.w	$0000	; $01CF9C  extension word or undecoded data
	dc.w	$0000	; $01CF9E  extension word or undecoded data
	dc.w	$0000	; $01CFA0  extension word or undecoded data
	dc.w	$0000	; $01CFA2  extension word or undecoded data
	dc.w	$0000	; $01CFA4  orib #-128,%d0
	dc.w	$7880	; $01CFA6  extension word or undecoded data
	dc.w	$7880	; $01CFA8  moveq #-128,%d4
	dc.w	$7880	; $01CFAA  moveq #-128,%d4
	dc.w	$7880	; $01CFAC  moveq #-128,%d4
	dc.w	$7880	; $01CFAE  moveq #-128,%d4
	dc.w	$7880	; $01CFB0  moveq #-128,%d4
	dc.w	$7880	; $01CFB2  moveq #-128,%d4
	dc.w	$7880	; $01CFB4  moveq #-128,%d4
	dc.w	$7880	; $01CFB6  moveq #-128,%d4
	dc.w	$7880	; $01CFB8  moveq #-128,%d4
	dc.w	$7880	; $01CFBA  moveq #-128,%d4
	dc.w	$0000	; $01CFBC  orib #-64,%d0
	dc.w	$78C0	; $01CFBE  extension word or undecoded data
	dc.w	$0000	; $01CFC0  extension word or undecoded data
	dc.w	$0000	; $01CFC2  extension word or undecoded data
	dc.w	$0000	; $01CFC4  extension word or undecoded data
	dc.w	$0000	; $01CFC6  extension word or undecoded data
	dc.w	$0000	; $01CFC8  extension word or undecoded data
	dc.w	$0000	; $01CFCA  extension word or undecoded data
	dc.w	$0000	; $01CFCC  extension word or undecoded data
	dc.w	$0000	; $01CFCE  extension word or undecoded data
	dc.w	$0000	; $01CFD0  extension word or undecoded data
	dc.w	$0000	; $01CFD2  extension word or undecoded data
	dc.w	$0000	; $01CFD4  extension word or undecoded data
	dc.w	$0000	; $01CFD6  extension word or undecoded data
	dc.w	$0000	; $01CFD8  orib #-128,%d0
	dc.w	$7880	; $01CFDA  extension word or undecoded data
	dc.w	$7880	; $01CFDC  moveq #-128,%d4
	dc.w	$7880	; $01CFDE  moveq #-128,%d4
	dc.w	$7880	; $01CFE0  moveq #-128,%d4
	dc.w	$7880	; $01CFE2  moveq #-128,%d4
	dc.w	$7880	; $01CFE4  moveq #-128,%d4
	dc.w	$7880	; $01CFE6  moveq #-128,%d4
	dc.w	$7880	; $01CFE8  moveq #-128,%d4
	dc.w	$7880	; $01CFEA  moveq #-128,%d4
	dc.w	$7880	; $01CFEC  moveq #-128,%d4
	dc.w	$7880	; $01CFEE  moveq #-128,%d4
	dc.w	$7880	; $01CFF0  moveq #-128,%d4
	dc.w	$7880	; $01CFF2  moveq #-128,%d4
	dc.w	$7880	; $01CFF4  moveq #-128,%d4
	dc.w	$7880	; $01CFF6  moveq #-128,%d4
	dc.w	$7880	; $01CFF8  moveq #-128,%d4
	dc.w	$7880	; $01CFFA  moveq #-128,%d4
	dc.w	$7880	; $01CFFC  moveq #-128,%d4
	dc.w	$7880	; $01CFFE  moveq #-128,%d4
club_v13_late_code_end::
; EOF: no original compiler source was invented.
