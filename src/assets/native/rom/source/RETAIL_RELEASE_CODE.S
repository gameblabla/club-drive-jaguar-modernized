; Original Jaguar ROM cartridge file offsets 0x13574..0x1D000
; v11 verified fixed-address release layout (not used in the source-linked ROM yet).
; Every GPU program is included from compiled .GAS source, never from retail GPU opcode dumps.
; The helper block is 68000 CODE DISASSEMBLED FROM RETAIL, preserved as exact
; machine words with decoded instruction comments, pending symbolic relinking.
 .text
club_release_code_begin::
 ; 0x013574: Original 68000 NOPs at first GPU boundary
 dc.w $4E71,$4E71
 ; 0x013578 GPU 3D -- generated from 3D.GAS
club_v11_gpprog::
 incbin "build/gpu_link/3d.bin"
 ; 0x0135AE: Original 1994 linker padding after 3d (not assumed zero)
 dc.w $3030
 ; 0x0135B0 GPU CASBEG -- generated from CASBEG.GAS
club_v11_casbeg::
 incbin "build/gpu_link/casbeg.bin"
 ; 0x014038 GPU TAGBEG -- generated from TAGBEG.GAS
club_v11_tagbeg::
 incbin "build/gpu_link/tagbeg.bin"
 ; 0x014788 GPU RACBEG -- generated from RACBEG.GAS
club_v11_racbeg::
 incbin "build/gpu_link/racbeg.bin"
 ; 0x015124: Original 1994 linker padding after racbeg (not assumed zero)
 dc.w $0000,$0000
 ; 0x015128 GPU COMP -- generated from COMP.GAS
club_v11_cgpprog::
 incbin "build/gpu_link/comp.bin"
 ; 0x015F76: Original 1994 linker padding after comp (not assumed zero)
 dc.w $3030
 ; 0x015F78 GPU REN -- generated from REN.GAS
club_v11_rgpprog::
 incbin "build/gpu_link/ren.bin"
 ; 0x016E26: Original 1994 linker padding after ren (not assumed zero)
 dc.w $3030
 ; 0x016E28 GPU CASEND -- generated from CASEND.GAS
club_v11_casend::
 incbin "build/gpu_link/casend.bin"
 ; 0x017CA6: Original 1994 linker padding after casend (not assumed zero)
 dc.w $3030
 ; 0x017CA8 GPU TAGEND -- generated from TAGEND.GAS
club_v11_tagend::
 incbin "build/gpu_link/tagend.bin"
 ; 0x018BA6: Original 1994 linker padding after tagend (not assumed zero)
 dc.w $3030
 ; 0x018BA8 GPU RACEND -- generated from RACEND.GAS
club_v11_racend::
 incbin "build/gpu_link/racend.bin"
 ; 0x019A66: Original 1994 linker padding after racend (not assumed zero)
 dc.w $3030
 ; 0x019A68 GPU GPUNZIP -- generated from GPUNZIP.GAS
club_v11__gpunzip::
 incbin "build/gpu_link/gpunzip.bin"
 ; 0x019E30 GPU PRECOMP -- generated from PRECOMP.GAS
club_v11_precomp::
 incbin "build/gpu_link/precomp.bin"
 ; 0x01A8E4: Original 1994 linker padding after precomp (not assumed zero)
 dc.w $0000,$0000
 ; 0x01A8E8 GPU PREREN -- generated from PREREN.GAS
club_v11_preren::
 incbin "build/gpu_link/preren.bin"
 ; 0x01AE06: Original 1994 linker padding after preren (not assumed zero)
 dc.w $3030
; First C/68000 helper instruction at ROM 0x01AE08
; Machine words reconstructed from retail. Decoded mnemonics are explanatory.
; Absolute call and data addresses are still literal retail addresses.
club_v11_recovered_cpu_begin::
; ---------------------------------------------------------------
; _alloc_it / $8001AE08  (identified by same-address opcode match)
; Surviving source: MKTP.C
; Purpose: allocate transformed geometry and collision buffers.
; NOTE: reconstructed label / explanation, NOT original Atari prose.
;       The dc.w opcodes below are still recovered from retail ROM.
; ---------------------------------------------------------------
club_retail_v12_alloc_it::
 dc.w $4E56 ; ROM 0x01AE08: linkw %fp,#0
 dc.w $0000
 dc.w $48E7 ; ROM 0x01AE0C: moveml %d2-%d5/%a2-%a4,%sp@-
 dc.w $3C38
 dc.w $246E ; ROM 0x01AE10: moveal %fp@(8),%a2
 dc.w $0008
 dc.w $3A2A ; ROM 0x01AE14: movew %a2@(6),%d5
 dc.w $0006
 dc.w $CBFC ; ROM 0x01AE18: mulsw #6,%d5
 dc.w $0006
 dc.w $2F05 ; ROM 0x01AE1C: movel %d5,%sp@-
 dc.w $47F9 ; ROM 0x01AE1E: lea 0x81b0b8,%a3
 dc.w $0081
 dc.w $B0B8
 dc.w $4E93 ; ROM 0x01AE24: jsr %a3@
 dc.w $584F ; ROM 0x01AE26: addqw #4,%sp
 dc.w $2540 ; ROM 0x01AE28: movel %d0,%a2@(76)
 dc.w $004C
 dc.w $6700 ; ROM 0x01AE2C: beqw 0x81ae4e
 dc.w $0020
 dc.w $4A6A ; ROM 0x01AE30: tstw %a2@(14)
 dc.w $000E
 dc.w $6700 ; ROM 0x01AE34: beqw 0x81ae54
 dc.w $001E
 dc.w $386A ; ROM 0x01AE38: moveaw %a2@(14),%a4
 dc.w $000E
 dc.w $200C ; ROM 0x01AE3C: movel %a4,%d0
 dc.w $D080 ; ROM 0x01AE3E: addl %d0,%d0
 dc.w $2F00 ; ROM 0x01AE40: movel %d0,%sp@-
 dc.w $4E93 ; ROM 0x01AE42: jsr %a3@
 dc.w $584F ; ROM 0x01AE44: addqw #4,%sp
 dc.w $2540 ; ROM 0x01AE46: movel %d0,%a2@(80)
 dc.w $0050
 dc.w $6600 ; ROM 0x01AE4A: bnew 0x81ae58
 dc.w $000C
 dc.w $4240 ; ROM 0x01AE4E: clrw %d0
 dc.w $6000 ; ROM 0x01AE50: braw 0x81af32
 dc.w $00E0
 dc.w $42AA ; ROM 0x01AE54: clrl %a2@(80)
 dc.w $0050
 dc.w $386A ; ROM 0x01AE58: moveaw %a2@(10),%a4
 dc.w $000A
 dc.w $200C ; ROM 0x01AE5C: movel %a4,%d0
 dc.w $E980 ; ROM 0x01AE5E: asll #4,%d0
 dc.w $2F00 ; ROM 0x01AE60: movel %d0,%sp@-
 dc.w $47F9 ; ROM 0x01AE62: lea 0x81b0b8,%a3
 dc.w $0081
 dc.w $B0B8
 dc.w $4E93 ; ROM 0x01AE68: jsr %a3@
 dc.w $584F ; ROM 0x01AE6A: addqw #4,%sp
 dc.w $2540 ; ROM 0x01AE6C: movel %d0,%a2@(84)
 dc.w $0054
 dc.w $67DC ; ROM 0x01AE70: beqs 0x81ae4e
 dc.w $386A ; ROM 0x01AE72: moveaw %a2@(8),%a4
 dc.w $0008
 dc.w $2F0C ; ROM 0x01AE76: movel %a4,%sp@-
 dc.w $4E93 ; ROM 0x01AE78: jsr %a3@
 dc.w $584F ; ROM 0x01AE7A: addqw #4,%sp
 dc.w $2540 ; ROM 0x01AE7C: movel %d0,%a2@(88)
 dc.w $0058
 dc.w $67CC ; ROM 0x01AE80: beqs 0x81ae4e
 dc.w $386A ; ROM 0x01AE82: moveaw %a2@(8),%a4
 dc.w $0008
 dc.w $200C ; ROM 0x01AE86: movel %a4,%d0
 dc.w $D080 ; ROM 0x01AE88: addl %d0,%d0
 dc.w $2F00 ; ROM 0x01AE8A: movel %d0,%sp@-
 dc.w $4E93 ; ROM 0x01AE8C: jsr %a3@
 dc.w $584F ; ROM 0x01AE8E: addqw #4,%sp
 dc.w $2540 ; ROM 0x01AE90: movel %d0,%a2@(92)
 dc.w $005C
 dc.w $67B8 ; ROM 0x01AE94: beqs 0x81ae4e
 dc.w $4AAA ; ROM 0x01AE96: tstl %a2@(104)
 dc.w $0068
 dc.w $6700 ; ROM 0x01AE9A: beqw 0x81aebc
 dc.w $0020
 dc.w $302A ; ROM 0x01AE9E: movew %a2@(4),%d0
 dc.w $0004
 dc.w $D06A ; ROM 0x01AEA2: addw %a2@(6),%d0
 dc.w $0006
 dc.w $3A00 ; ROM 0x01AEA6: movew %d0,%d5
 dc.w $CBFC ; ROM 0x01AEA8: mulsw #6,%d5
 dc.w $0006
 dc.w $2F05 ; ROM 0x01AEAC: movel %d5,%sp@-
 dc.w $4E93 ; ROM 0x01AEAE: jsr %a3@
 dc.w $584F ; ROM 0x01AEB0: addqw #4,%sp
 dc.w $2540 ; ROM 0x01AEB2: movel %d0,%a2@(72)
 dc.w $0048
 dc.w $6600 ; ROM 0x01AEB6: bnew 0x81aec2
 dc.w $000A
 dc.w $6092 ; ROM 0x01AEBA: bras 0x81ae4e
 dc.w $256A ; ROM 0x01AEBC: movel %a2@(44),%a2@(72)
 dc.w $002C
 dc.w $0048
 dc.w $082A ; ROM 0x01AEC2: btst #0,%a2@(3)
 dc.w $0000
 dc.w $0003
 dc.w $6600 ; ROM 0x01AEC8: bnew 0x81af26
 dc.w $005C
 dc.w $7600 ; ROM 0x01AECC: moveq #0,%d3
 dc.w $382A ; ROM 0x01AECE: movew %a2@(12),%d4
 dc.w $000C
 dc.w $226A ; ROM 0x01AED2: moveal %a2@(48),%a1
 dc.w $0030
 dc.w $4242 ; ROM 0x01AED6: clrw %d2
 dc.w $B842 ; ROM 0x01AED8: cmpw %d2,%d4
 dc.w $6F00 ; ROM 0x01AEDA: blew 0x81af0c
 dc.w $0030
 dc.w $6000 ; ROM 0x01AEDE: braw 0x81aefe
 dc.w $001E
 dc.w $3001 ; ROM 0x01AEE2: movew %d1,%d0
 dc.w $E340 ; ROM 0x01AEE4: aslw #1,%d0
 dc.w $D041 ; ROM 0x01AEE6: addw %d1,%d0
 dc.w $E340 ; ROM 0x01AEE8: aslw #1,%d0
 dc.w $3040 ; ROM 0x01AEEA: moveaw %d0,%a0
 dc.w $D0FC ; ROM 0x01AEEC: addaw #12,%a0
 dc.w $000C
 dc.w $3048 ; ROM 0x01AEF0: moveaw %a0,%a0
 dc.w $D688 ; ROM 0x01AEF2: addl %a0,%d3
 dc.w $3001 ; ROM 0x01AEF4: movew %d1,%d0
 dc.w $48C0 ; ROM 0x01AEF6: extl %d0
 dc.w $D080 ; ROM 0x01AEF8: addl %d0,%d0
 dc.w $43F1 ; ROM 0x01AEFA: lea %a1@(0000000000000004,%d0:l),%a1
 dc.w $0804
 dc.w $3219 ; ROM 0x01AEFE: movew %a1@+,%d1
 dc.w $C27C ; ROM 0x01AF00: andw #15,%d1
 dc.w $000F
 dc.w $66DC ; ROM 0x01AF04: bnes 0x81aee2
 dc.w $5242 ; ROM 0x01AF06: addqw #1,%d2
 dc.w $B842 ; ROM 0x01AF08: cmpw %d2,%d4
 dc.w $6EF2 ; ROM 0x01AF0A: bgts 0x81aefe
 dc.w $2F03 ; ROM 0x01AF0C: movel %d3,%sp@-
 dc.w $4EB9 ; ROM 0x01AF0E: jsr 0x81b0b8
 dc.w $0081
 dc.w $B0B8
 dc.w $2540 ; ROM 0x01AF14: movel %d0,%a2@(100)
 dc.w $0064
 dc.w $6700 ; ROM 0x01AF18: beqw 0x81ae4e
 dc.w $FF34
 dc.w $357C ; ROM 0x01AF1C: movew #2,%a2@(112)
 dc.w $0002
 dc.w $0070
 dc.w $6000 ; ROM 0x01AF22: braw 0x81af30
 dc.w $000C
 dc.w $42AA ; ROM 0x01AF26: clrl %a2@(100)
 dc.w $0064
 dc.w $357C ; ROM 0x01AF2A: movew #1,%a2@(112)
 dc.w $0001
 dc.w $0070
 dc.w $7001 ; ROM 0x01AF30: moveq #1,%d0
 dc.w $4CEE ; ROM 0x01AF32: moveml %fp@(-28),%d2-%d5/%a2-%a4
 dc.w $1C3C
 dc.w $FFE4
 dc.w $4E5E ; ROM 0x01AF38: unlk %fp
 dc.w $4E75 ; ROM 0x01AF3A: rts
; ---------------------------------------------------------------
; _free_bnd / $8001AF3C  (identified by same-address opcode match)
; Surviving source: MKTP.C
; Purpose: release boundary transforms after reference counts fall to zero.
; NOTE: reconstructed label / explanation, NOT original Atari prose.
;       The dc.w opcodes below are still recovered from retail ROM.
; ---------------------------------------------------------------
club_retail_v12_free_bnd::
 dc.w $4E56 ; ROM 0x01AF3C: linkw %fp,#0
 dc.w $0000
 dc.w $2F0B ; ROM 0x01AF40: movel %a3,%sp@-
 dc.w $2F0A ; ROM 0x01AF42: movel %a2,%sp@-
 dc.w $206E ; ROM 0x01AF44: moveal %fp@(8),%a0
 dc.w $0008
 dc.w $B0FC ; ROM 0x01AF48: cmpaw #0,%a0
 dc.w $0000
 dc.w $6700 ; ROM 0x01AF4C: beqw 0x81b026
 dc.w $00D8
 dc.w $2468 ; ROM 0x01AF50: moveal %a0@(116),%a2
 dc.w $0074
 dc.w $47E8 ; ROM 0x01AF54: lea %a0@(120),%a3
 dc.w $0078
 dc.w $B4FC ; ROM 0x01AF58: cmpaw #0,%a2
 dc.w $0000
 dc.w $6700 ; ROM 0x01AF5C: beqw 0x81b026
 dc.w $00C8
 dc.w $536A ; ROM 0x01AF60: subqw #1,%a2@(114)
 dc.w $0072
 dc.w $4A6A ; ROM 0x01AF64: tstw %a2@(114)
 dc.w $0072
 dc.w $6E00 ; ROM 0x01AF68: bgtw 0x81b01c
 dc.w $00B2
 dc.w $4AAA ; ROM 0x01AF6C: tstl %a2@(76)
 dc.w $004C
 dc.w $6700 ; ROM 0x01AF70: beqw 0x81af80
 dc.w $000E
 dc.w $2F2A ; ROM 0x01AF74: movel %a2@(76),%sp@-
 dc.w $004C
 dc.w $4EB9 ; ROM 0x01AF78: jsr 0x81b1ae
 dc.w $0081
 dc.w $B1AE
 dc.w $584F ; ROM 0x01AF7E: addqw #4,%sp
 dc.w $4AAA ; ROM 0x01AF80: tstl %a2@(80)
 dc.w $0050
 dc.w $6700 ; ROM 0x01AF84: beqw 0x81af94
 dc.w $000E
 dc.w $2F2A ; ROM 0x01AF88: movel %a2@(80),%sp@-
 dc.w $0050
 dc.w $4EB9 ; ROM 0x01AF8C: jsr 0x81b1ae
 dc.w $0081
 dc.w $B1AE
 dc.w $584F ; ROM 0x01AF92: addqw #4,%sp
 dc.w $4AAA ; ROM 0x01AF94: tstl %a2@(84)
 dc.w $0054
 dc.w $6700 ; ROM 0x01AF98: beqw 0x81afa8
 dc.w $000E
 dc.w $2F2A ; ROM 0x01AF9C: movel %a2@(84),%sp@-
 dc.w $0054
 dc.w $4EB9 ; ROM 0x01AFA0: jsr 0x81b1ae
 dc.w $0081
 dc.w $B1AE
 dc.w $584F ; ROM 0x01AFA6: addqw #4,%sp
 dc.w $4AAA ; ROM 0x01AFA8: tstl %a2@(88)
 dc.w $0058
 dc.w $6700 ; ROM 0x01AFAC: beqw 0x81afbc
 dc.w $000E
 dc.w $2F2A ; ROM 0x01AFB0: movel %a2@(88),%sp@-
 dc.w $0058
 dc.w $4EB9 ; ROM 0x01AFB4: jsr 0x81b1ae
 dc.w $0081
 dc.w $B1AE
 dc.w $584F ; ROM 0x01AFBA: addqw #4,%sp
 dc.w $4AAA ; ROM 0x01AFBC: tstl %a2@(92)
 dc.w $005C
 dc.w $6700 ; ROM 0x01AFC0: beqw 0x81afd0
 dc.w $000E
 dc.w $2F2A ; ROM 0x01AFC4: movel %a2@(92),%sp@-
 dc.w $005C
 dc.w $4EB9 ; ROM 0x01AFC8: jsr 0x81b1ae
 dc.w $0081
 dc.w $B1AE
 dc.w $584F ; ROM 0x01AFCE: addqw #4,%sp
 dc.w $4AAA ; ROM 0x01AFD0: tstl %a2@(104)
 dc.w $0068
 dc.w $6700 ; ROM 0x01AFD4: beqw 0x81afe4
 dc.w $000E
 dc.w $2F2A ; ROM 0x01AFD8: movel %a2@(72),%sp@-
 dc.w $0048
 dc.w $4EB9 ; ROM 0x01AFDC: jsr 0x81b1ae
 dc.w $0081
 dc.w $B1AE
 dc.w $584F ; ROM 0x01AFE2: addqw #4,%sp
 dc.w $4AAA ; ROM 0x01AFE4: tstl %a2@(100)
 dc.w $0064
 dc.w $6700 ; ROM 0x01AFE8: beqw 0x81aff8
 dc.w $000E
 dc.w $2F2A ; ROM 0x01AFEC: movel %a2@(100),%sp@-
 dc.w $0064
 dc.w $4EB9 ; ROM 0x01AFF0: jsr 0x81b1ae
 dc.w $0081
 dc.w $B1AE
 dc.w $584F ; ROM 0x01AFF6: addqw #4,%sp
 dc.w $42AA ; ROM 0x01AFF8: clrl %a2@(76)
 dc.w $004C
 dc.w $42AA ; ROM 0x01AFFC: clrl %a2@(80)
 dc.w $0050
 dc.w $42AA ; ROM 0x01B000: clrl %a2@(84)
 dc.w $0054
 dc.w $42AA ; ROM 0x01B004: clrl %a2@(88)
 dc.w $0058
 dc.w $42AA ; ROM 0x01B008: clrl %a2@(92)
 dc.w $005C
 dc.w $42AA ; ROM 0x01B00C: clrl %a2@(96)
 dc.w $0060
 dc.w $42AA ; ROM 0x01B010: clrl %a2@(100)
 dc.w $0064
 dc.w $426A ; ROM 0x01B014: clrw %a2@(112)
 dc.w $0070
 dc.w $42AA ; ROM 0x01B018: clrl %a2@(72)
 dc.w $0048
 dc.w $245B ; ROM 0x01B01C: moveal %a3@+,%a2
 dc.w $B4FC ; ROM 0x01B01E: cmpaw #0,%a2
 dc.w $0000
 dc.w $6600 ; ROM 0x01B022: bnew 0x81af60
 dc.w $FF3C
 dc.w $246E ; ROM 0x01B026: moveal %fp@(-8),%a2
 dc.w $FFF8
 dc.w $266E ; ROM 0x01B02A: moveal %fp@(-4),%a3
 dc.w $FFFC
 dc.w $4E5E ; ROM 0x01B02E: unlk %fp
 dc.w $4E75 ; ROM 0x01B030: rts
; ---------------------------------------------------------------
; _use_bnd / $8001B032  (identified by same-address opcode match)
; Surviving source: MKTP.C
; Purpose: activate a boundary model and maintain shared-resource counts.
; NOTE: reconstructed label / explanation, NOT original Atari prose.
;       The dc.w opcodes below are still recovered from retail ROM.
; ---------------------------------------------------------------
club_retail_v12_use_bnd::
 dc.w $4E56 ; ROM 0x01B032: linkw %fp,#0
 dc.w $0000
 dc.w $2F0B ; ROM 0x01B036: movel %a3,%sp@-
 dc.w $2F0A ; ROM 0x01B038: movel %a2,%sp@-
 dc.w $266E ; ROM 0x01B03A: moveal %fp@(8),%a3
 dc.w $0008
 dc.w $2F2E ; ROM 0x01B03E: movel %fp@(12),%sp@-
 dc.w $000C
 dc.w $4EB9 ; ROM 0x01B042: jsr 0x81af3c
 dc.w $0081
 dc.w $AF3C
 dc.w $584F ; ROM 0x01B048: addqw #4,%sp
 dc.w $B6FC ; ROM 0x01B04A: cmpaw #0,%a3
 dc.w $0000
 dc.w $6600 ; ROM 0x01B04E: bnew 0x81b060
 dc.w $0010
 dc.w $2F3C ; ROM 0x01B052: movel #286331153,%sp@-
 dc.w $1111
 dc.w $1111
 dc.w $4EB9 ; ROM 0x01B058: jsr 0x81b2d0
 dc.w $0081
 dc.w $B2D0
 dc.w $584F ; ROM 0x01B05E: addqw #4,%sp
 dc.w $246B ; ROM 0x01B060: moveal %a3@(116),%a2
 dc.w $0074
 dc.w $D6FC ; ROM 0x01B064: addaw #120,%a3
 dc.w $0078
 dc.w $B4FC ; ROM 0x01B068: cmpaw #0,%a2
 dc.w $0000
 dc.w $6700 ; ROM 0x01B06C: beqw 0x81b0ac
 dc.w $003E
 dc.w $4A6A ; ROM 0x01B070: tstw %a2@(112)
 dc.w $0070
 dc.w $6600 ; ROM 0x01B074: bnew 0x81b0a0
 dc.w $002A
 dc.w $2F0A ; ROM 0x01B078: movel %a2,%sp@-
 dc.w $4EB9 ; ROM 0x01B07A: jsr 0x81ae08
 dc.w $0081
 dc.w $AE08
 dc.w $584F ; ROM 0x01B080: addqw #4,%sp
 dc.w $4A40 ; ROM 0x01B082: tstw %d0
 dc.w $6600 ; ROM 0x01B084: bnew 0x81b096
 dc.w $0010
 dc.w $2F3C ; ROM 0x01B088: movel #-572662307,%sp@-
 dc.w $DDDD
 dc.w $DDDD
 dc.w $4EB9 ; ROM 0x01B08E: jsr 0x81b2d0
 dc.w $0081
 dc.w $B2D0
 dc.w $584F ; ROM 0x01B094: addqw #4,%sp
 dc.w $357C ; ROM 0x01B096: movew #1,%a2@(114)
 dc.w $0001
 dc.w $0072
 dc.w $6000 ; ROM 0x01B09C: braw 0x81b0a4
 dc.w $0006
 dc.w $526A ; ROM 0x01B0A0: addqw #1,%a2@(114)
 dc.w $0072
 dc.w $245B ; ROM 0x01B0A4: moveal %a3@+,%a2
 dc.w $B4FC ; ROM 0x01B0A6: cmpaw #0,%a2
 dc.w $0000
 dc.w $66C4 ; ROM 0x01B0AA: bnes 0x81b070
 dc.w $246E ; ROM 0x01B0AC: moveal %fp@(-8),%a2
 dc.w $FFF8
 dc.w $266E ; ROM 0x01B0B0: moveal %fp@(-4),%a3
 dc.w $FFFC
 dc.w $4E5E ; ROM 0x01B0B4: unlk %fp
 dc.w $4E75 ; ROM 0x01B0B6: rts
; ---------------------------------------------------------------
; _alloc / $8001B0B8  (identified by same-address opcode match)
; Surviving source: ALLOC.C
; Purpose: allocate heap storage from a HEADER free list.
; NOTE: reconstructed label / explanation, NOT original Atari prose.
;       The dc.w opcodes below are still recovered from retail ROM.
; ---------------------------------------------------------------
club_retail_v12_alloc::
 dc.w $4E56 ; ROM 0x01B0B8: linkw %fp,#0
 dc.w $0000
 dc.w $2F02 ; ROM 0x01B0BC: movel %d2,%sp@-
 dc.w $700F ; ROM 0x01B0BE: moveq #15,%d0
 dc.w $D0AE ; ROM 0x01B0C0: addl %fp@(8),%d0
 dc.w $0008
 dc.w $E688 ; ROM 0x01B0C4: lsrl #3,%d0
 dc.w $2400 ; ROM 0x01B0C6: movel %d0,%d2
 dc.w $5282 ; ROM 0x01B0C8: addql #1,%d2
 dc.w $2279 ; ROM 0x01B0CA: moveal 0x1df12,%a1
 dc.w $0001
 dc.w $DF12
 dc.w $B2FC ; ROM 0x01B0D0: cmpaw #0,%a1
 dc.w $0000
 dc.w $6600 ; ROM 0x01B0D4: bnew 0x81b0ec
 dc.w $0016
 dc.w $43F9 ; ROM 0x01B0D8: lea 0x1df0a,%a1
 dc.w $0001
 dc.w $DF0A
 dc.w $23C9 ; ROM 0x01B0DE: movel %a1,0x1df12
 dc.w $0001
 dc.w $DF12
 dc.w $2289 ; ROM 0x01B0E4: movel %a1,%a1@
 dc.w $42B9 ; ROM 0x01B0E6: clrl 0x1df0e
 dc.w $0001
 dc.w $DF0E
 dc.w $2051 ; ROM 0x01B0EC: moveal %a1@,%a0
 dc.w $B4A8 ; ROM 0x01B0EE: cmpl %a0@(4),%d2
 dc.w $0004
 dc.w $6200 ; ROM 0x01B0F2: bhiw 0x81b126
 dc.w $0032
 dc.w $6600 ; ROM 0x01B0F6: bnew 0x81b100
 dc.w $0008
 dc.w $2290 ; ROM 0x01B0FA: movel %a0@,%a1@
 dc.w $6000 ; ROM 0x01B0FC: braw 0x81b112
 dc.w $0014
 dc.w $2028 ; ROM 0x01B100: movel %a0@(4),%d0
 dc.w $0004
 dc.w $9082 ; ROM 0x01B104: subl %d2,%d0
 dc.w $2140 ; ROM 0x01B106: movel %d0,%a0@(4)
 dc.w $0004
 dc.w $E780 ; ROM 0x01B10A: asll #3,%d0
 dc.w $D1C0 ; ROM 0x01B10C: addal %d0,%a0
 dc.w $2142 ; ROM 0x01B10E: movel %d2,%a0@(4)
 dc.w $0004
 dc.w $23C9 ; ROM 0x01B112: movel %a1,0x1df12
 dc.w $0001
 dc.w $DF12
 dc.w $20BC ; ROM 0x01B118: movel #659724,%a0@
 dc.w $000A
 dc.w $110C
 dc.w $2008 ; ROM 0x01B11E: movel %a0,%d0
 dc.w $5080 ; ROM 0x01B120: addql #8,%d0
 dc.w $6000 ; ROM 0x01B122: braw 0x81b150
 dc.w $002C
 dc.w $B1F9 ; ROM 0x01B126: cmpal 0x1df12,%a0
 dc.w $0001
 dc.w $DF12
 dc.w $6600 ; ROM 0x01B12C: bnew 0x81b14a
 dc.w $001C
 dc.w $2F02 ; ROM 0x01B130: movel %d2,%sp@-
 dc.w $4EB9 ; ROM 0x01B132: jsr 0x81b158
 dc.w $0081
 dc.w $B158
 dc.w $584F ; ROM 0x01B138: addqw #4,%sp
 dc.w $2040 ; ROM 0x01B13A: moveal %d0,%a0
 dc.w $B0FC ; ROM 0x01B13C: cmpaw #0,%a0
 dc.w $0000
 dc.w $6600 ; ROM 0x01B140: bnew 0x81b14a
 dc.w $0008
 dc.w $7000 ; ROM 0x01B144: moveq #0,%d0
 dc.w $6000 ; ROM 0x01B146: braw 0x81b150
 dc.w $0008
 dc.w $2248 ; ROM 0x01B14A: moveal %a0,%a1
 dc.w $2050 ; ROM 0x01B14C: moveal %a0@,%a0
 dc.w $609E ; ROM 0x01B14E: bras 0x81b0ee
 dc.w $242E ; ROM 0x01B150: movel %fp@(-4),%d2
 dc.w $FFFC
 dc.w $4E5E ; ROM 0x01B154: unlk %fp
 dc.w $4E75 ; ROM 0x01B156: rts
; ---------------------------------------------------------------
; _morecore / $8001B158  (identified by same-address opcode match)
; Surviving source: ALLOC.C
; Purpose: extend the heap and return a free-list block.
; NOTE: reconstructed label / explanation, NOT original Atari prose.
;       The dc.w opcodes below are still recovered from retail ROM.
; ---------------------------------------------------------------
club_retail_v12_morecore::
 dc.w $4E56 ; ROM 0x01B158: linkw %fp,#0
 dc.w $0000
 dc.w $2F02 ; ROM 0x01B15C: movel %d2,%sp@-
 dc.w $202E ; ROM 0x01B15E: movel %fp@(8),%d0
 dc.w $0008
 dc.w $D0BC ; ROM 0x01B162: addl #255,%d0
 dc.w $0000
 dc.w $00FF
 dc.w $2400 ; ROM 0x01B168: movel %d0,%d2
 dc.w $C47C ; ROM 0x01B16A: andw #-256,%d2
 dc.w $FF00
 dc.w $2002 ; ROM 0x01B16E: movel %d2,%d0
 dc.w $E780 ; ROM 0x01B170: asll #3,%d0
 dc.w $2F00 ; ROM 0x01B172: movel %d0,%sp@-
 dc.w $4EB9 ; ROM 0x01B174: jsr 0x81b24a
 dc.w $0081
 dc.w $B24A
 dc.w $584F ; ROM 0x01B17A: addqw #4,%sp
 dc.w $2040 ; ROM 0x01B17C: moveal %d0,%a0
 dc.w $B0FC ; ROM 0x01B17E: cmpaw #0,%a0
 dc.w $0000
 dc.w $6700 ; ROM 0x01B182: beqw 0x81b1a4
 dc.w $0020
 dc.w $2142 ; ROM 0x01B186: movel %d2,%a0@(4)
 dc.w $0004
 dc.w $20BC ; ROM 0x01B18A: movel #659724,%a0@
 dc.w $000A
 dc.w $110C
 dc.w $4868 ; ROM 0x01B190: pea %a0@(8)
 dc.w $0008
 dc.w $4EB9 ; ROM 0x01B194: jsr 0x81b1ae
 dc.w $0081
 dc.w $B1AE
 dc.w $2039 ; ROM 0x01B19A: movel 0x1df12,%d0
 dc.w $0001
 dc.w $DF12
 dc.w $6000 ; ROM 0x01B1A0: braw 0x81b1a6
 dc.w $0004
 dc.w $7000 ; ROM 0x01B1A4: moveq #0,%d0
 dc.w $242E ; ROM 0x01B1A6: movel %fp@(-4),%d2
 dc.w $FFFC
 dc.w $4E5E ; ROM 0x01B1AA: unlk %fp
 dc.w $4E75 ; ROM 0x01B1AC: rts
; ---------------------------------------------------------------
; _free / $8001B1AE  (identified by same-address opcode match)
; Surviving source: ALLOC.C
; Purpose: release storage and coalesce adjacent free-list blocks.
; NOTE: reconstructed label / explanation, NOT original Atari prose.
;       The dc.w opcodes below are still recovered from retail ROM.
; ---------------------------------------------------------------
club_retail_v12_free::
 dc.w $4E56 ; ROM 0x01B1AE: linkw %fp,#0
 dc.w $0000
 dc.w $2F0A ; ROM 0x01B1B2: movel %a2,%sp@-
 dc.w $202E ; ROM 0x01B1B4: movel %fp@(8),%d0
 dc.w $0008
 dc.w $6700 ; ROM 0x01B1B8: beqw 0x81b242
 dc.w $0088
 dc.w $2440 ; ROM 0x01B1BC: moveal %d0,%a2
 dc.w $514A ; ROM 0x01B1BE: subqw #8,%a2
 dc.w $203C ; ROM 0x01B1C0: movel #659724,%d0
 dc.w $000A
 dc.w $110C
 dc.w $B092 ; ROM 0x01B1C6: cmpl %a2@,%d0
 dc.w $6700 ; ROM 0x01B1C8: beqw 0x81b1d4
 dc.w $000A
 dc.w $2F00 ; ROM 0x01B1CC: movel %d0,%sp@-
 dc.w $4EB9 ; ROM 0x01B1CE: jsr 0x81b2d0
 dc.w $0081
 dc.w $B2D0
 dc.w $4292 ; ROM 0x01B1D4: clrl %a2@
 dc.w $2279 ; ROM 0x01B1D6: moveal 0x1df12,%a1
 dc.w $0001
 dc.w $DF12
 dc.w $6000 ; ROM 0x01B1DC: braw 0x81b1f4
 dc.w $0016
 dc.w $B3D1 ; ROM 0x01B1E0: cmpal %a1@,%a1
 dc.w $6500 ; ROM 0x01B1E2: bcsw 0x81b1f2
 dc.w $000E
 dc.w $B3CA ; ROM 0x01B1E6: cmpal %a2,%a1
 dc.w $6500 ; ROM 0x01B1E8: bcsw 0x81b1fc
 dc.w $0012
 dc.w $B5D1 ; ROM 0x01B1EC: cmpal %a1@,%a2
 dc.w $6500 ; ROM 0x01B1EE: bcsw 0x81b1fc
 dc.w $000C
 dc.w $2251 ; ROM 0x01B1F2: moveal %a1@,%a1
 dc.w $B3CA ; ROM 0x01B1F4: cmpal %a2,%a1
 dc.w $64E8 ; ROM 0x01B1F6: bccs 0x81b1e0
 dc.w $B5D1 ; ROM 0x01B1F8: cmpal %a1@,%a2
 dc.w $64E4 ; ROM 0x01B1FA: bccs 0x81b1e0
 dc.w $202A ; ROM 0x01B1FC: movel %a2@(4),%d0
 dc.w $0004
 dc.w $E780 ; ROM 0x01B200: asll #3,%d0
 dc.w $41F2 ; ROM 0x01B202: lea %a2@(0000000000000000,%d0:l),%a0
 dc.w $0800
 dc.w $B1D1 ; ROM 0x01B206: cmpal %a1@,%a0
 dc.w $6600 ; ROM 0x01B208: bnew 0x81b21c
 dc.w $0012
 dc.w $2228 ; ROM 0x01B20C: movel %a0@(4),%d1
 dc.w $0004
 dc.w $D3AA ; ROM 0x01B210: addl %d1,%a2@(4)
 dc.w $0004
 dc.w $2051 ; ROM 0x01B214: moveal %a1@,%a0
 dc.w $2490 ; ROM 0x01B216: movel %a0@,%a2@
 dc.w $6000 ; ROM 0x01B218: braw 0x81b21e
 dc.w $0004
 dc.w $2491 ; ROM 0x01B21C: movel %a1@,%a2@
 dc.w $2029 ; ROM 0x01B21E: movel %a1@(4),%d0
 dc.w $0004
 dc.w $E780 ; ROM 0x01B222: asll #3,%d0
 dc.w $D089 ; ROM 0x01B224: addl %a1,%d0
 dc.w $B5C0 ; ROM 0x01B226: cmpal %d0,%a2
 dc.w $6600 ; ROM 0x01B228: bnew 0x81b23a
 dc.w $0010
 dc.w $222A ; ROM 0x01B22C: movel %a2@(4),%d1
 dc.w $0004
 dc.w $D3A9 ; ROM 0x01B230: addl %d1,%a1@(4)
 dc.w $0004
 dc.w $2292 ; ROM 0x01B234: movel %a2@,%a1@
 dc.w $6000 ; ROM 0x01B236: braw 0x81b23c
 dc.w $0004
 dc.w $228A ; ROM 0x01B23A: movel %a2,%a1@
 dc.w $23C9 ; ROM 0x01B23C: movel %a1,0x1df12
 dc.w $0001
 dc.w $DF12
 dc.w $246E ; ROM 0x01B242: moveal %fp@(-4),%a2
 dc.w $FFFC
 dc.w $4E5E ; ROM 0x01B246: unlk %fp
 dc.w $4E75 ; ROM 0x01B248: rts
; ---------------------------------------------------------------
; _sbrk / $8001B24A  (identified by same-address opcode match)
; Surviving source: ALLOC.C
; Purpose: advance the Jaguar RAM heap cursor, reserving the top page.
; NOTE: reconstructed label / explanation, NOT original Atari prose.
;       The dc.w opcodes below are still recovered from retail ROM.
; ---------------------------------------------------------------
club_retail_v12_sbrk::
 dc.w $4E56 ; ROM 0x01B24A: linkw %fp,#0
 dc.w $0000
 dc.w $2F02 ; ROM 0x01B24E: movel %d2,%sp@-
 dc.w $4A79 ; ROM 0x01B250: tstw 0x1df08
 dc.w $0001
 dc.w $DF08
 dc.w $6600 ; ROM 0x01B256: bnew 0x81b270
 dc.w $0018
 dc.w $74F8 ; ROM 0x01B25A: moveq #-8,%d2
 dc.w $C4BC ; ROM 0x01B25C: andl #1673095,%d2
 dc.w $0019
 dc.w $8787
 dc.w $23C2 ; ROM 0x01B262: movel %d2,0x1df04
 dc.w $0001
 dc.w $DF04
 dc.w $33FC ; ROM 0x01B268: movew #1,0x1df08
 dc.w $0001
 dc.w $0001
 dc.w $DF08
 dc.w $222E ; ROM 0x01B270: movel %fp@(8),%d1
 dc.w $0008
 dc.w $D2B9 ; ROM 0x01B274: addl 0x1df04,%d1
 dc.w $0001
 dc.w $DF04
 dc.w $B2B9 ; ROM 0x01B27A: cmpl 0x1df00,%d1
 dc.w $0001
 dc.w $DF00
 dc.w $6200 ; ROM 0x01B280: bhiw 0x81b294
 dc.w $0012
 dc.w $2039 ; ROM 0x01B284: movel 0x1df04,%d0
 dc.w $0001
 dc.w $DF04
 dc.w $23C1 ; ROM 0x01B28A: movel %d1,0x1df04
 dc.w $0001
 dc.w $DF04
 dc.w $6000 ; ROM 0x01B290: braw 0x81b296
 dc.w $0004
 dc.w $7000 ; ROM 0x01B294: moveq #0,%d0
 dc.w $242E ; ROM 0x01B296: movel %fp@(-4),%d2
 dc.w $FFFC
 dc.w $4E5E ; ROM 0x01B29A: unlk %fp
 dc.w $4E75 ; ROM 0x01B29C: rts
; ---------------------------------------------------------------
; _init_alloc / $8001B29E  (identified by same-address opcode match)
; Surviving source: ALLOC.C
; Purpose: reset the Club Drive heap allocator.
; NOTE: reconstructed label / explanation, NOT original Atari prose.
;       The dc.w opcodes below are still recovered from retail ROM.
; ---------------------------------------------------------------
club_retail_v12_init_alloc::
 dc.w $4E56 ; ROM 0x01B29E: linkw %fp,#0
 dc.w $0000
 dc.w $4279 ; ROM 0x01B2A2: clrw 0x1df08
 dc.w $0001
 dc.w $DF08
 dc.w $42B9 ; ROM 0x01B2A8: clrl 0x1df04
 dc.w $0001
 dc.w $DF04
 dc.w $42B9 ; ROM 0x01B2AE: clrl 0x1df12
 dc.w $0001
 dc.w $DF12
 dc.w $42B9 ; ROM 0x01B2B4: clrl 0x1df0e
 dc.w $0001
 dc.w $DF0E
 dc.w $42B9 ; ROM 0x01B2BA: clrl 0x1df0a
 dc.w $0001
 dc.w $DF0A
 dc.w $23FC ; ROM 0x01B2C0: movel #2093056,0x1df00
 dc.w $001F
 dc.w $F000
 dc.w $0001
 dc.w $DF00
 dc.w $4E5E ; ROM 0x01B2CA: unlk %fp
 dc.w $4E75 ; ROM 0x01B2CC: rts
 dc.w $4E71 ; ROM 0x01B2CE: nop
 dc.w $4E56 ; ROM 0x01B2D0: linkw %fp,#0
 dc.w $0000
 dc.w $202F ; ROM 0x01B2D4: movel %sp@(8),%d0
 dc.w $0008
 dc.w $4AFC ; ROM 0x01B2D8: illegal
 dc.w $4E5E ; ROM 0x01B2DA: unlk %fp
 dc.w $4E75 ; ROM 0x01B2DC: rts
 dc.w $206F ; ROM 0x01B2DE: moveal %sp@(4),%a0
 dc.w $0004
 dc.w $222F ; ROM 0x01B2E2: movel %sp@(8),%d1
 dc.w $0008
 dc.w $2F02 ; ROM 0x01B2E6: movel %d2,%sp@-
 dc.w $7000 ; ROM 0x01B2E8: moveq #0,%d0
 dc.w $B2BC ; ROM 0x01B2EA: cmpl #128,%d1
 dc.w $0000
 dc.w $0080
 dc.w $6B00 ; ROM 0x01B2F0: bmiw 0x81b380
 dc.w $008E
 dc.w $2408 ; ROM 0x01B2F4: movel %a0,%d2
 dc.w $0802 ; ROM 0x01B2F6: btst #0,%d2
 dc.w $0000
 dc.w $6706 ; ROM 0x01B2FA: beqs 0x81b302
 dc.w $10C0 ; ROM 0x01B2FC: moveb %d0,%a0@+
 dc.w $5381 ; ROM 0x01B2FE: subql #1,%d1
 dc.w $2408 ; ROM 0x01B300: movel %a0,%d2
 dc.w $0802 ; ROM 0x01B302: btst #1,%d2
 dc.w $0001
 dc.w $6706 ; ROM 0x01B306: beqs 0x81b30e
 dc.w $30C0 ; ROM 0x01B308: movew %d0,%a0@+
 dc.w $5581 ; ROM 0x01B30A: subql #2,%d1
 dc.w $2408 ; ROM 0x01B30C: movel %a0,%d2
 dc.w $0802 ; ROM 0x01B30E: btst #2,%d2
 dc.w $0002
 dc.w $6704 ; ROM 0x01B312: beqs 0x81b318
 dc.w $20C0 ; ROM 0x01B314: movel %d0,%a0@+
 dc.w $5981 ; ROM 0x01B316: subql #4,%d1
 dc.w $2401 ; ROM 0x01B318: movel %d1,%d2
 dc.w $B4BC ; ROM 0x01B31A: cmpl #16384,%d2
 dc.w $0000
 dc.w $4000
 dc.w $6B06 ; ROM 0x01B320: bmis 0x81b328
 dc.w $243C ; ROM 0x01B322: movel #16384,%d2
 dc.w $0000
 dc.w $4000
 dc.w $9282 ; ROM 0x01B328: subl %d2,%d1
 dc.w $23C8 ; ROM 0x01B32A: movel %a0,0xf02200
 dc.w $00F0
 dc.w $2200
 dc.w $D1C2 ; ROM 0x01B330: addal %d2,%a0
 dc.w $23FC ; ROM 0x01B332: movel #0,0xf0220c
 dc.w $0000
 dc.w $0000
 dc.w $00F0
 dc.w $220C
 dc.w $23FC ; ROM 0x01B33C: movel #0,0xf02218
 dc.w $0000
 dc.w $0000
 dc.w $00F0
 dc.w $2218
 dc.w $23FC ; ROM 0x01B346: movel #6168,0xf02204
 dc.w $0000
 dc.w $1818
 dc.w $00F0
 dc.w $2204
 dc.w $23C0 ; ROM 0x01B350: movel %d0,0xf02268
 dc.w $00F0
 dc.w $2268
 dc.w $23C0 ; ROM 0x01B356: movel %d0,0xf0226c
 dc.w $00F0
 dc.w $226C
 dc.w $4842 ; ROM 0x01B35C: swap %d2
 dc.w $343C ; ROM 0x01B35E: movew #1,%d2
 dc.w $0001
 dc.w $4842 ; ROM 0x01B362: swap %d2
 dc.w $23C2 ; ROM 0x01B364: movel %d2,0xf0223c
 dc.w $00F0
 dc.w $223C
 dc.w $23FC ; ROM 0x01B36A: movel #65536,0xf02238
 dc.w $0001
 dc.w $0000
 dc.w $00F0
 dc.w $2238
 dc.w $B2BC ; ROM 0x01B374: cmpl #0,%d1
 dc.w $0000
 dc.w $0000
 dc.w $669C ; ROM 0x01B37A: bnes 0x81b318
 dc.w $6000 ; ROM 0x01B37C: braw 0x81b386
 dc.w $0008
 dc.w $10C0 ; ROM 0x01B380: moveb %d0,%a0@+
 dc.w $5381 ; ROM 0x01B382: subql #1,%d1
 dc.w $66FA ; ROM 0x01B384: bnes 0x81b380
 dc.w $241F ; ROM 0x01B386: movel %sp@+,%d2
 dc.w $4E75 ; ROM 0x01B388: rts
 dc.w $206F ; ROM 0x01B38A: moveal %sp@(4),%a0
 dc.w $0004
 dc.w $226F ; ROM 0x01B38E: moveal %sp@(8),%a1
 dc.w $0008
 dc.w $222F ; ROM 0x01B392: movel %sp@(12),%d1
 dc.w $000C
 dc.w $600C ; ROM 0x01B396: bras 0x81b3a4
 dc.w $226F ; ROM 0x01B398: moveal %sp@(4),%a1
 dc.w $0004
 dc.w $206F ; ROM 0x01B39C: moveal %sp@(8),%a0
 dc.w $0008
 dc.w $222F ; ROM 0x01B3A0: movel %sp@(12),%d1
 dc.w $000C
 dc.w $B2BC ; ROM 0x01B3A4: cmpl #128,%d1
 dc.w $0000
 dc.w $0080
 dc.w $6B00 ; ROM 0x01B3AA: bmiw 0x81b456
 dc.w $00AA
 dc.w $48E7 ; ROM 0x01B3AE: moveml %d2-%d7,%sp@-
 dc.w $3F00
 dc.w $7407 ; ROM 0x01B3B2: moveq #7,%d2
 dc.w $2602 ; ROM 0x01B3B4: movel %d2,%d3
 dc.w $2802 ; ROM 0x01B3B6: movel %d2,%d4
 dc.w $2A02 ; ROM 0x01B3B8: movel %d2,%d5
 dc.w $4682 ; ROM 0x01B3BA: notl %d2
 dc.w $4683 ; ROM 0x01B3BC: notl %d3
 dc.w $2009 ; ROM 0x01B3BE: movel %a1,%d0
 dc.w $C480 ; ROM 0x01B3C0: andl %d0,%d2
 dc.w $C880 ; ROM 0x01B3C2: andl %d0,%d4
 dc.w $2008 ; ROM 0x01B3C4: movel %a0,%d0
 dc.w $C680 ; ROM 0x01B3C6: andl %d0,%d3
 dc.w $CA80 ; ROM 0x01B3C8: andl %d0,%d5
 dc.w $2C3C ; ROM 0x01B3CA: movel #6168,%d6
 dc.w $0000
 dc.w $1818
 dc.w $2E3C ; ROM 0x01B3D0: movel #25165829,%d7
 dc.w $0180
 dc.w $0005
 dc.w $BA7C ; ROM 0x01B3D6: cmpw #0,%d5
 dc.w $0000
 dc.w $6606 ; ROM 0x01B3DA: bnes 0x81b3e2
 dc.w $2E3C ; ROM 0x01B3DC: movel #25165825,%d7
 dc.w $0180
 dc.w $0001
 dc.w $2039 ; ROM 0x01B3E2: movel 0xf02238,%d0
 dc.w $00F0
 dc.w $2238
 dc.w $0800 ; ROM 0x01B3E8: btst #0,%d0
 dc.w $0000
 dc.w $67F4 ; ROM 0x01B3EC: beqs 0x81b3e2
 dc.w $2001 ; ROM 0x01B3EE: movel %d1,%d0
 dc.w $B0BC ; ROM 0x01B3F0: cmpl #32752,%d0
 dc.w $0000
 dc.w $7FF0
 dc.w $6B06 ; ROM 0x01B3F6: bmis 0x81b3fe
 dc.w $203C ; ROM 0x01B3F8: movel #32752,%d0
 dc.w $0000
 dc.w $7FF0
 dc.w $9280 ; ROM 0x01B3FE: subl %d0,%d1
 dc.w $23C2 ; ROM 0x01B400: movel %d2,0xf02200
 dc.w $00F0
 dc.w $2200
 dc.w $D480 ; ROM 0x01B406: addl %d0,%d2
 dc.w $23C3 ; ROM 0x01B408: movel %d3,0xf02224
 dc.w $00F0
 dc.w $2224
 dc.w $D680 ; ROM 0x01B40E: addl %d0,%d3
 dc.w $23C4 ; ROM 0x01B410: movel %d4,0xf0220c
 dc.w $00F0
 dc.w $220C
 dc.w $23FC ; ROM 0x01B416: movel #0,0xf02218
 dc.w $0000
 dc.w $0000
 dc.w $00F0
 dc.w $2218
 dc.w $23C5 ; ROM 0x01B420: movel %d5,0xf02230
 dc.w $00F0
 dc.w $2230
 dc.w $23C6 ; ROM 0x01B426: movel %d6,0xf02204
 dc.w $00F0
 dc.w $2204
 dc.w $23C6 ; ROM 0x01B42C: movel %d6,0xf02228
 dc.w $00F0
 dc.w $2228
 dc.w $4840 ; ROM 0x01B432: swap %d0
 dc.w $303C ; ROM 0x01B434: movew #1,%d0
 dc.w $0001
 dc.w $4840 ; ROM 0x01B438: swap %d0
 dc.w $23C0 ; ROM 0x01B43A: movel %d0,0xf0223c
 dc.w $00F0
 dc.w $223C
 dc.w $23C7 ; ROM 0x01B440: movel %d7,0xf02238
 dc.w $00F0
 dc.w $2238
 dc.w $B2BC ; ROM 0x01B446: cmpl #0,%d1
 dc.w $0000
 dc.w $0000
 dc.w $6694 ; ROM 0x01B44C: bnes 0x81b3e2
 dc.w $4CDF ; ROM 0x01B44E: moveml %sp@+,%d2-%d7
 dc.w $00FC
 dc.w $6000 ; ROM 0x01B452: braw 0x81b45c
 dc.w $0008
 dc.w $12D8 ; ROM 0x01B456: moveb %a0@+,%a1@+
 dc.w $5381 ; ROM 0x01B458: subql #1,%d1
 dc.w $66FA ; ROM 0x01B45A: bnes 0x81b456
 dc.w $4E75 ; ROM 0x01B45C: rts
 dc.w $4EF9 ; ROM 0x01B45E: jmp 0x81b0b8
 dc.w $0081
 dc.w $B0B8
 dc.w $4E75 ; ROM 0x01B464: rts
 dc.w $2042 ; ROM 0x01B466: moveal %d2,%a0
 dc.w $2243 ; ROM 0x01B468: moveal %d3,%a1
 dc.w $4CAF ; ROM 0x01B46A: movemw %sp@(4),%d0-%d3
 dc.w $000F
 dc.w $0004
 dc.w $3F00 ; ROM 0x01B470: movew %d0,%sp@-
 dc.w $6A00 ; ROM 0x01B472: bplw 0x81b47a
 dc.w $0006
 dc.w $4441 ; ROM 0x01B476: negw %d1
 dc.w $4040 ; ROM 0x01B478: negxw %d0
 dc.w $4A42 ; ROM 0x01B47A: tstw %d2
 dc.w $6A00 ; ROM 0x01B47C: bplw 0x81b486
 dc.w $0008
 dc.w $4443 ; ROM 0x01B480: negw %d3
 dc.w $4042 ; ROM 0x01B482: negxw %d2
 dc.w $4657 ; ROM 0x01B484: notw %sp@
 dc.w $48C0 ; ROM 0x01B486: extl %d0
 dc.w $6700 ; ROM 0x01B488: beqw 0x81b48e
 dc.w $0004
 dc.w $C0C3 ; ROM 0x01B48C: muluw %d3,%d0
 dc.w $4A42 ; ROM 0x01B48E: tstw %d2
 dc.w $6700 ; ROM 0x01B490: beqw 0x81b498
 dc.w $0006
 dc.w $C4C1 ; ROM 0x01B494: muluw %d1,%d2
 dc.w $D042 ; ROM 0x01B496: addw %d2,%d0
 dc.w $4840 ; ROM 0x01B498: swap %d0
 dc.w $4240 ; ROM 0x01B49A: clrw %d0
 dc.w $C2C3 ; ROM 0x01B49C: muluw %d3,%d1
 dc.w $D081 ; ROM 0x01B49E: addl %d1,%d0
 dc.w $2609 ; ROM 0x01B4A0: movel %a1,%d3
 dc.w $2408 ; ROM 0x01B4A2: movel %a0,%d2
 dc.w $4A5F ; ROM 0x01B4A4: tstw %sp@+
 dc.w $6A00 ; ROM 0x01B4A6: bplw 0x81b4ac
 dc.w $0004
 dc.w $4480 ; ROM 0x01B4AA: negl %d0
 dc.w $4E75 ; ROM 0x01B4AC: rts
 dc.w $2042 ; ROM 0x01B4AE: moveal %d2,%a0
 dc.w $2243 ; ROM 0x01B4B0: moveal %d3,%a1
 dc.w $4267 ; ROM 0x01B4B2: clrw %sp@-
 dc.w $4280 ; ROM 0x01B4B4: clrl %d0
 dc.w $242F ; ROM 0x01B4B6: movel %sp@(10),%d2
 dc.w $000A
 dc.w $6700 ; ROM 0x01B4BA: beqw 0x81b52c
 dc.w $0070
 dc.w $6A00 ; ROM 0x01B4BE: bplw 0x81b4c6
 dc.w $0006
 dc.w $4482 ; ROM 0x01B4C2: negl %d2
 dc.w $4657 ; ROM 0x01B4C4: notw %sp@
 dc.w $222F ; ROM 0x01B4C6: movel %sp@(6),%d1
 dc.w $0006
 dc.w $6A00 ; ROM 0x01B4CA: bplw 0x81b4d2
 dc.w $0006
 dc.w $4481 ; ROM 0x01B4CE: negl %d1
 dc.w $4657 ; ROM 0x01B4D0: notw %sp@
 dc.w $B282 ; ROM 0x01B4D2: cmpl %d2,%d1
 dc.w $6500 ; ROM 0x01B4D4: bcsw 0x81b514
 dc.w $003E
 dc.w $4A6F ; ROM 0x01B4D8: tstw %sp@(10)
 dc.w $000A
 dc.w $6600 ; ROM 0x01B4DC: bnew 0x81b4fe
 dc.w $0020
 dc.w $3601 ; ROM 0x01B4E0: movew %d1,%d3
 dc.w $4241 ; ROM 0x01B4E2: clrw %d1
 dc.w $4841 ; ROM 0x01B4E4: swap %d1
 dc.w $6700 ; ROM 0x01B4E6: beqw 0x81b4ec
 dc.w $0004
 dc.w $82C2 ; ROM 0x01B4EA: divuw %d2,%d1
 dc.w $3001 ; ROM 0x01B4EC: movew %d1,%d0
 dc.w $4840 ; ROM 0x01B4EE: swap %d0
 dc.w $3203 ; ROM 0x01B4F0: movew %d3,%d1
 dc.w $82C2 ; ROM 0x01B4F2: divuw %d2,%d1
 dc.w $3001 ; ROM 0x01B4F4: movew %d1,%d0
 dc.w $4241 ; ROM 0x01B4F6: clrw %d1
 dc.w $4841 ; ROM 0x01B4F8: swap %d1
 dc.w $6000 ; ROM 0x01B4FA: braw 0x81b514
 dc.w $0018
 dc.w $761F ; ROM 0x01B4FE: moveq #31,%d3
 dc.w $D281 ; ROM 0x01B500: addl %d1,%d1
 dc.w $D180 ; ROM 0x01B502: addxl %d0,%d0
 dc.w $B082 ; ROM 0x01B504: cmpl %d2,%d0
 dc.w $6500 ; ROM 0x01B506: bcsw 0x81b50e
 dc.w $0006
 dc.w $9082 ; ROM 0x01B50A: subl %d2,%d0
 dc.w $5241 ; ROM 0x01B50C: addqw #1,%d1
 dc.w $51CB ; ROM 0x01B50E: dbf %d3,0x81b500
 dc.w $FFF0
 dc.w $C141 ; ROM 0x01B512: exg %d0,%d1
 dc.w $4A6F ; ROM 0x01B514: tstw %sp@(6)
 dc.w $0006
 dc.w $6A00 ; ROM 0x01B518: bplw 0x81b51e
 dc.w $0004
 dc.w $4481 ; ROM 0x01B51C: negl %d1
 dc.w $4A5F ; ROM 0x01B51E: tstw %sp@+
 dc.w $6A00 ; ROM 0x01B520: bplw 0x81b526
 dc.w $0004
 dc.w $4480 ; ROM 0x01B524: negl %d0
 dc.w $2609 ; ROM 0x01B526: movel %a1,%d3
 dc.w $2408 ; ROM 0x01B528: movel %a0,%d2
 dc.w $4E75 ; ROM 0x01B52A: rts
 dc.w $82C2 ; ROM 0x01B52C: divuw %d2,%d1
 dc.w $60E4 ; ROM 0x01B52E: bras 0x81b514
 dc.w $2F2F ; ROM 0x01B530: movel %sp@(8),%sp@-
 dc.w $0008
 dc.w $2F2F ; ROM 0x01B534: movel %sp@(8),%sp@-
 dc.w $0008
 dc.w $4EB9 ; ROM 0x01B538: jsr 0x81b4ae
 dc.w $0081
 dc.w $B4AE
 dc.w $508F ; ROM 0x01B53E: addql #8,%sp
 dc.w $2001 ; ROM 0x01B540: movel %d1,%d0
 dc.w $4E75 ; ROM 0x01B542: rts
 dc.w $4E71 ; ROM 0x01B544: nop
 dc.w $4E71 ; ROM 0x01B546: nop
 dc.w $0000 ; ROM 0x01B548: orib #1,%d0
 dc.w $0001
 dc.w $0003 ; ROM 0x01B54C: orib #7,%d3
 dc.w $0007
 dc.w $000F ; ROM 0x01B550: 017
 dc.w $001F ; ROM 0x01B552: orib #63,%sp@+
 dc.w $003F
 dc.w $007F ; ROM 0x01B556: 0177
 dc.w $00FF ; ROM 0x01B558: 0377
 dc.w $01FF ; ROM 0x01B55A: 0777
 dc.w $03FF ; ROM 0x01B55C: 01777
 dc.w $07FF ; ROM 0x01B55E: 03777
 dc.w $0FFF ; ROM 0x01B560: 07777
 dc.w $1FFF ; ROM 0x01B562: 017777
 dc.w $3FFF ; ROM 0x01B564: 037777
 dc.w $7FFF ; ROM 0x01B566: 077777
 dc.w $FFFF ; ROM 0x01B568: 0177777
 dc.w $4E56 ; ROM 0x01B56A: linkw %fp,#-732
 dc.w $FD24
 dc.w $48E7 ; ROM 0x01B56E: moveml %d2-%d7/%a2-%a5,%sp@-
 dc.w $3F3C
 dc.w $242E ; ROM 0x01B572: movel %fp@(8),%d2
 dc.w $0008
 dc.w $266E ; ROM 0x01B576: moveal %fp@(28),%a3
 dc.w $001C
 dc.w $4878 ; ROM 0x01B57A: pea 0x22
 dc.w $0022
 dc.w $486E ; ROM 0x01B57E: pea %fp@(-34)
 dc.w $FFDE
 dc.w $4EB9 ; ROM 0x01B582: jsr 0x81b2de
 dc.w $0081
 dc.w $B2DE
 dc.w $504F ; ROM 0x01B588: addqw #8,%sp
 dc.w $2442 ; ROM 0x01B58A: moveal %d2,%a2
 dc.w $382E ; ROM 0x01B58C: movew %fp@(12),%d4
 dc.w $000C
 dc.w $7200 ; ROM 0x01B590: moveq #0,%d1
 dc.w $321A ; ROM 0x01B592: movew %a2@+,%d1
 dc.w $2001 ; ROM 0x01B594: movel %d1,%d0
 dc.w $D080 ; ROM 0x01B596: addl %d0,%d0
 dc.w $5276 ; ROM 0x01B598: addqw #1,%fp@(ffffffffffffffde,%d0:l)
 dc.w $08DE
 dc.w $5344 ; ROM 0x01B59C: subqw #1,%d4
 dc.w $66F2 ; ROM 0x01B59E: bnes 0x81b592
 dc.w $3E2E ; ROM 0x01B5A0: movew %fp@(12),%d7
 dc.w $000C
 dc.w $BE6E ; ROM 0x01B5A4: cmpw %fp@(-34),%d7
 dc.w $FFDE
 dc.w $6600 ; ROM 0x01B5A8: bnew 0x81b5ba
 dc.w $0010
 dc.w $286E ; ROM 0x01B5AC: moveal %fp@(24),%a4
 dc.w $0018
 dc.w $4294 ; ROM 0x01B5B0: clrl %a4@
 dc.w $4253 ; ROM 0x01B5B2: clrw %a3@
 dc.w $4240 ; ROM 0x01B5B4: clrw %d0
 dc.w $6000 ; ROM 0x01B5B6: braw 0x81b95a
 dc.w $03A2
 dc.w $3D53 ; ROM 0x01B5BA: movew %a3@,%fp@(-730)
 dc.w $FD26
 dc.w $7601 ; ROM 0x01B5BE: moveq #1,%d3
 dc.w $7200 ; ROM 0x01B5C0: moveq #0,%d1
 dc.w $3203 ; ROM 0x01B5C2: movew %d3,%d1
 dc.w $2001 ; ROM 0x01B5C4: movel %d1,%d0
 dc.w $D080 ; ROM 0x01B5C6: addl %d0,%d0
 dc.w $4A76 ; ROM 0x01B5C8: tstw %fp@(ffffffffffffffde,%d0:l)
 dc.w $08DE
 dc.w $6600 ; ROM 0x01B5CC: bnew 0x81b5d8
 dc.w $000A
 dc.w $5243 ; ROM 0x01B5D0: addqw #1,%d3
 dc.w $B67C ; ROM 0x01B5D2: cmpw #16,%d3
 dc.w $0010
 dc.w $63EA ; ROM 0x01B5D6: blss 0x81b5c2
 dc.w $3A43 ; ROM 0x01B5D8: moveaw %d3,%a5
 dc.w $B66E ; ROM 0x01B5DA: cmpw %fp@(-730),%d3
 dc.w $FD26
 dc.w $6300 ; ROM 0x01B5DE: blsw 0x81b5e6
 dc.w $0006
 dc.w $3D4D ; ROM 0x01B5E2: movew %a5,%fp@(-730)
 dc.w $FD26
 dc.w $7810 ; ROM 0x01B5E6: moveq #16,%d4
 dc.w $7200 ; ROM 0x01B5E8: moveq #0,%d1
 dc.w $3204 ; ROM 0x01B5EA: movew %d4,%d1
 dc.w $2001 ; ROM 0x01B5EC: movel %d1,%d0
 dc.w $D080 ; ROM 0x01B5EE: addl %d0,%d0
 dc.w $4A76 ; ROM 0x01B5F0: tstw %fp@(ffffffffffffffde,%d0:l)
 dc.w $08DE
 dc.w $6600 ; ROM 0x01B5F4: bnew 0x81b5fc
 dc.w $0006
 dc.w $5344 ; ROM 0x01B5F8: subqw #1,%d4
 dc.w $66EE ; ROM 0x01B5FA: bnes 0x81b5ea
 dc.w $3D44 ; ROM 0x01B5FC: movew %d4,%fp@(-718)
 dc.w $FD32
 dc.w $B86E ; ROM 0x01B600: cmpw %fp@(-730),%d4
 dc.w $FD26
 dc.w $6400 ; ROM 0x01B604: bccw 0x81b60e
 dc.w $0008
 dc.w $3D6E ; ROM 0x01B608: movew %fp@(-718),%fp@(-730)
 dc.w $FD32
 dc.w $FD26
 dc.w $36AE ; ROM 0x01B60E: movew %fp@(-730),%a3@
 dc.w $FD26
 dc.w $7001 ; ROM 0x01B612: moveq #1,%d0
 dc.w $E760 ; ROM 0x01B614: aslw %d3,%d0
 dc.w $3D40 ; ROM 0x01B616: movew %d0,%fp@(-720)
 dc.w $FD30
 dc.w $B66E ; ROM 0x01B61A: cmpw %fp@(-718),%d3
 dc.w $FD32
 dc.w $6400 ; ROM 0x01B61E: bccw 0x81b646
 dc.w $0026
 dc.w $7200 ; ROM 0x01B622: moveq #0,%d1
 dc.w $3203 ; ROM 0x01B624: movew %d3,%d1
 dc.w $2001 ; ROM 0x01B626: movel %d1,%d0
 dc.w $D080 ; ROM 0x01B628: addl %d0,%d0
 dc.w $3036 ; ROM 0x01B62A: movew %fp@(ffffffffffffffde,%d0:l),%d0
 dc.w $08DE
 dc.w $916E ; ROM 0x01B62E: subw %d0,%fp@(-720)
 dc.w $FD30
 dc.w $6B00 ; ROM 0x01B632: bmiw 0x81b65a
 dc.w $0026
 dc.w $5243 ; ROM 0x01B636: addqw #1,%d3
 dc.w $3E2E ; ROM 0x01B638: movew %fp@(-720),%d7
 dc.w $FD30
 dc.w $E347 ; ROM 0x01B63C: aslw #1,%d7
 dc.w $3D47 ; ROM 0x01B63E: movew %d7,%fp@(-720)
 dc.w $FD30
 dc.w $B843 ; ROM 0x01B642: cmpw %d3,%d4
 dc.w $62DE ; ROM 0x01B644: bhis 0x81b624
 dc.w $4280 ; ROM 0x01B646: clrl %d0
 dc.w $3004 ; ROM 0x01B648: movew %d4,%d0
 dc.w $D080 ; ROM 0x01B64A: addl %d0,%d0
 dc.w $41F6 ; ROM 0x01B64C: lea %fp@(ffffffffffffffde,%d0:l),%a0
 dc.w $08DE
 dc.w $3E10 ; ROM 0x01B650: movew %a0@,%d7
 dc.w $9F6E ; ROM 0x01B652: subw %d7,%fp@(-720)
 dc.w $FD30
 dc.w $6A00 ; ROM 0x01B656: bplw 0x81b660
 dc.w $0008
 dc.w $7002 ; ROM 0x01B65A: moveq #2,%d0
 dc.w $6000 ; ROM 0x01B65C: braw 0x81b95a
 dc.w $02FC
 dc.w $3E2E ; ROM 0x01B660: movew %fp@(-720),%d7
 dc.w $FD30
 dc.w $DF50 ; ROM 0x01B664: addw %d7,%a0@
 dc.w $4243 ; ROM 0x01B666: clrw %d3
 dc.w $426E ; ROM 0x01B668: clrw %fp@(-712)
 dc.w $FD38
 dc.w $45EE ; ROM 0x01B66C: lea %fp@(-32),%a2
 dc.w $FFE0
 dc.w $41EE ; ROM 0x01B670: lea %fp@(-710),%a0
 dc.w $FD3A
 dc.w $6000 ; ROM 0x01B674: braw 0x81b67c
 dc.w $0006
 dc.w $D65A ; ROM 0x01B678: addw %a2@+,%d3
 dc.w $30C3 ; ROM 0x01B67A: movew %d3,%a0@+
 dc.w $5344 ; ROM 0x01B67C: subqw #1,%d4
 dc.w $66F8 ; ROM 0x01B67E: bnes 0x81b678
 dc.w $2442 ; ROM 0x01B680: moveal %d2,%a2
 dc.w $4244 ; ROM 0x01B682: clrw %d4
 dc.w $7200 ; ROM 0x01B684: moveq #0,%d1
 dc.w $243C ; ROM 0x01B686: movel #-714,%d2
 dc.w $FFFF
 dc.w $FD36
 dc.w $367C ; ROM 0x01B68C: moveaw #-680,%a3
 dc.w $FD58
 dc.w $361A ; ROM 0x01B690: movew %a2@+,%d3
 dc.w $6700 ; ROM 0x01B692: beqw 0x81b6b2
 dc.w $001E
 dc.w $3203 ; ROM 0x01B696: movew %d3,%d1
 dc.w $2001 ; ROM 0x01B698: movel %d1,%d0
 dc.w $D080 ; ROM 0x01B69A: addl %d0,%d0
 dc.w $D08E ; ROM 0x01B69C: addl %fp,%d0
 dc.w $2240 ; ROM 0x01B69E: moveal %d0,%a1
 dc.w $D3C2 ; ROM 0x01B6A0: addal %d2,%a1
 dc.w $4280 ; ROM 0x01B6A2: clrl %d0
 dc.w $3011 ; ROM 0x01B6A4: movew %a1@,%d0
 dc.w $D080 ; ROM 0x01B6A6: addl %d0,%d0
 dc.w $41F6 ; ROM 0x01B6A8: lea %fp@(0000000000000000,%d0:l),%a0
 dc.w $0800
 dc.w $3784 ; ROM 0x01B6AC: movew %d4,%a3@(0000000000000000,%a0:l)
 dc.w $8800
 dc.w $5251 ; ROM 0x01B6B0: addqw #1,%a1@
 dc.w $5244 ; ROM 0x01B6B2: addqw #1,%d4
 dc.w $B86E ; ROM 0x01B6B4: cmpw %fp@(12),%d4
 dc.w $000C
 dc.w $65D6 ; ROM 0x01B6B8: bcss 0x81b690
 dc.w $4244 ; ROM 0x01B6BA: clrw %d4
 dc.w $426E ; ROM 0x01B6BC: clrw %fp@(-714)
 dc.w $FD36
 dc.w $45EE ; ROM 0x01B6C0: lea %fp@(-680),%a2
 dc.w $FD58
 dc.w $367C ; ROM 0x01B6C4: moveaw #-1,%a3
 dc.w $FFFF
 dc.w $3A2E ; ROM 0x01B6C8: movew %fp@(-730),%d5
 dc.w $FD26
 dc.w $4445 ; ROM 0x01B6CC: negw %d5
 dc.w $42AE ; ROM 0x01B6CE: clrl %fp@(-104)
 dc.w $FF98
 dc.w $93C9 ; ROM 0x01B6D2: subal %a1,%a1
 dc.w $4246 ; ROM 0x01B6D4: clrw %d6
 dc.w $3E2E ; ROM 0x01B6D6: movew %fp@(-718),%d7
 dc.w $FD32
 dc.w $BE4D ; ROM 0x01B6DA: cmpw %a5,%d7
 dc.w $6D00 ; ROM 0x01B6DC: bltw 0x81b944
 dc.w $0266
 dc.w $42AE ; ROM 0x01B6E0: clrl %fp@(-728)
 dc.w $FD28
 dc.w $300D ; ROM 0x01B6E4: movew %a5,%d0
 dc.w $48C0 ; ROM 0x01B6E6: extl %d0
 dc.w $D080 ; ROM 0x01B6E8: addl %d0,%d0
 dc.w $3036 ; ROM 0x01B6EA: movew %fp@(ffffffffffffffde,%d0:l),%d0
 dc.w $08DE
 dc.w $5340 ; ROM 0x01B6EE: subqw #1,%d0
 dc.w $3D40 ; ROM 0x01B6F0: movew %d0,%fp@(-716)
 dc.w $FD34
 dc.w $0C6E ; ROM 0x01B6F4: cmpiw #-1,%fp@(-716)
 dc.w $FFFF
 dc.w $FD34
 dc.w $6700 ; ROM 0x01B6FA: beqw 0x81b938
 dc.w $023C
 dc.w $42AE ; ROM 0x01B6FE: clrl %fp@(-724)
 dc.w $FD2C
 dc.w $6000 ; ROM 0x01B702: braw 0x81b81e
 dc.w $011A
 dc.w $524B ; ROM 0x01B706: addqw #1,%a3
 dc.w $3A00 ; ROM 0x01B708: movew %d0,%d5
 dc.w $3C2E ; ROM 0x01B70A: movew %fp@(-718),%d6
 dc.w $FD32
 dc.w $9C45 ; ROM 0x01B70E: subw %d5,%d6
 dc.w $3006 ; ROM 0x01B710: movew %d6,%d0
 dc.w $B06E ; ROM 0x01B712: cmpw %fp@(-730),%d0
 dc.w $FD26
 dc.w $6300 ; ROM 0x01B716: blsw 0x81b71e
 dc.w $0006
 dc.w $302E ; ROM 0x01B71A: movew %fp@(-730),%d0
 dc.w $FD26
 dc.w $3C00 ; ROM 0x01B71E: movew %d0,%d6
 dc.w $360D ; ROM 0x01B720: movew %a5,%d3
 dc.w $9645 ; ROM 0x01B722: subw %d5,%d3
 dc.w $7401 ; ROM 0x01B724: moveq #1,%d2
 dc.w $E762 ; ROM 0x01B726: aslw %d3,%d2
 dc.w $302E ; ROM 0x01B728: movew %fp@(-716),%d0
 dc.w $FD34
 dc.w $5240 ; ROM 0x01B72C: addqw #1,%d0
 dc.w $B042 ; ROM 0x01B72E: cmpw %d2,%d0
 dc.w $6400 ; ROM 0x01B730: bccw 0x81b75e
 dc.w $002C
 dc.w $3002 ; ROM 0x01B734: movew %d2,%d0
 dc.w $5340 ; ROM 0x01B736: subqw #1,%d0
 dc.w $3400 ; ROM 0x01B738: movew %d0,%d2
 dc.w $946E ; ROM 0x01B73A: subw %fp@(-716),%d2
 dc.w $FD34
 dc.w $300D ; ROM 0x01B73E: movew %a5,%d0
 dc.w $48C0 ; ROM 0x01B740: extl %d0
 dc.w $D080 ; ROM 0x01B742: addl %d0,%d0
 dc.w $41F6 ; ROM 0x01B744: lea %fp@(ffffffffffffffde,%d0:l),%a0
 dc.w $08DE
 dc.w $6000 ; ROM 0x01B748: braw 0x81b758
 dc.w $000E
 dc.w $E34A ; ROM 0x01B74C: lslw #1,%d2
 dc.w $5448 ; ROM 0x01B74E: addqw #2,%a0
 dc.w $B450 ; ROM 0x01B750: cmpw %a0@,%d2
 dc.w $6300 ; ROM 0x01B752: blsw 0x81b75e
 dc.w $000A
 dc.w $9450 ; ROM 0x01B756: subw %a0@,%d2
 dc.w $5243 ; ROM 0x01B758: addqw #1,%d3
 dc.w $BC43 ; ROM 0x01B75A: cmpw %d3,%d6
 dc.w $62EE ; ROM 0x01B75C: bhis 0x81b74c
 dc.w $7C01 ; ROM 0x01B75E: moveq #1,%d6
 dc.w $E766 ; ROM 0x01B760: aslw %d3,%d6
 dc.w $3006 ; ROM 0x01B762: movew %d6,%d0
 dc.w $5240 ; ROM 0x01B764: addqw #1,%d0
 dc.w $3E00 ; ROM 0x01B766: movew %d0,%d7
 dc.w $CEFC ; ROM 0x01B768: muluw #6,%d7
 dc.w $0006
 dc.w $2F07 ; ROM 0x01B76C: movel %d7,%sp@-
 dc.w $4EB9 ; ROM 0x01B76E: jsr 0x81b45e
 dc.w $0081
 dc.w $B45E
 dc.w $584F ; ROM 0x01B774: addqw #4,%sp
 dc.w $2240 ; ROM 0x01B776: moveal %d0,%a1
 dc.w $B2FC ; ROM 0x01B778: cmpaw #0,%a1
 dc.w $0000
 dc.w $6600 ; ROM 0x01B77C: bnew 0x81b796
 dc.w $0018
 dc.w $3E0B ; ROM 0x01B780: movew %a3,%d7
 dc.w $6700 ; ROM 0x01B782: beqw 0x81b790
 dc.w $000C
 dc.w $2F2E ; ROM 0x01B786: movel %fp@(-104),%sp@-
 dc.w $FF98
 dc.w $4EB9 ; ROM 0x01B78A: jsr 0x81b964
 dc.w $0081
 dc.w $B964
 dc.w $7003 ; ROM 0x01B790: moveq #3,%d0
 dc.w $6000 ; ROM 0x01B792: braw 0x81b95a
 dc.w $01C6
 dc.w $3039 ; ROM 0x01B796: movew 0x1df24,%d0
 dc.w $0001
 dc.w $DF24
 dc.w $5240 ; ROM 0x01B79C: addqw #1,%d0
 dc.w $D046 ; ROM 0x01B79E: addw %d6,%d0
 dc.w $33C0 ; ROM 0x01B7A0: movew %d0,0x1df24
 dc.w $0001
 dc.w $DF24
 dc.w $2209 ; ROM 0x01B7A6: movel %a1,%d1
 dc.w $5C81 ; ROM 0x01B7A8: addql #6,%d1
 dc.w $286E ; ROM 0x01B7AA: moveal %fp@(24),%a4
 dc.w $0018
 dc.w $2881 ; ROM 0x01B7AE: movel %d1,%a4@
 dc.w $5449 ; ROM 0x01B7B0: addqw #2,%a1
 dc.w $2D49 ; ROM 0x01B7B2: movel %a1,%fp@(24)
 dc.w $0018
 dc.w $4291 ; ROM 0x01B7B6: clrl %a1@
 dc.w $340B ; ROM 0x01B7B8: movew %a3,%d2
 dc.w $48C2 ; ROM 0x01B7BA: extl %d2
 dc.w $2002 ; ROM 0x01B7BC: movel %d2,%d0
 dc.w $E580 ; ROM 0x01B7BE: asll #2,%d0
 dc.w $2241 ; ROM 0x01B7C0: moveal %d1,%a1
 dc.w $2D89 ; ROM 0x01B7C2: movel %a1,%fp@(ffffffffffffff98,%d0:l)
 dc.w $0898
 dc.w $3E0B ; ROM 0x01B7C6: movew %a3,%d7
 dc.w $6700 ; ROM 0x01B7C8: beqw 0x81b81e
 dc.w $0054
 dc.w $2002 ; ROM 0x01B7CC: movel %d2,%d0
 dc.w $D080 ; ROM 0x01B7CE: addl %d0,%d0
 dc.w $41F6 ; ROM 0x01B7D0: lea %fp@(0000000000000000,%d0:l),%a0
 dc.w $0800
 dc.w $3144 ; ROM 0x01B7D4: movew %d4,%a0@(-714)
 dc.w $FD36
 dc.w $1D6E ; ROM 0x01B7D8: moveb %fp@(-729),%fp@(-39)
 dc.w $FD27
 dc.w $FFD9
 dc.w $D63C ; ROM 0x01B7DE: addb #16,%d3
 dc.w $0010
 dc.w $1D43 ; ROM 0x01B7E2: moveb %d3,%fp@(-40)
 dc.w $FFD8
 dc.w $2D49 ; ROM 0x01B7E6: movel %a1,%fp@(-38)
 dc.w $FFDA
 dc.w $3005 ; ROM 0x01B7EA: movew %d5,%d0
 dc.w $906E ; ROM 0x01B7EC: subw %fp@(-730),%d0
 dc.w $FD26
 dc.w $3604 ; ROM 0x01B7F0: movew %d4,%d3
 dc.w $E06B ; ROM 0x01B7F2: lsrw %d0,%d3
 dc.w $304B ; ROM 0x01B7F4: moveaw %a3,%a0
 dc.w $5348 ; ROM 0x01B7F6: subqw #1,%a0
 dc.w $3048 ; ROM 0x01B7F8: moveaw %a0,%a0
 dc.w $2008 ; ROM 0x01B7FA: movel %a0,%d0
 dc.w $E580 ; ROM 0x01B7FC: asll #2,%d0
 dc.w $3D43 ; ROM 0x01B7FE: movew %d3,%fp@(-722)
 dc.w $FD2E
 dc.w $2076 ; ROM 0x01B802: moveal %fp@(ffffffffffffff98,%d0:l),%a0
 dc.w $0898
 dc.w $202E ; ROM 0x01B806: movel %fp@(-724),%d0
 dc.w $FD2C
 dc.w $D080 ; ROM 0x01B80A: addl %d0,%d0
 dc.w $D0AE ; ROM 0x01B80C: addl %fp@(-724),%d0
 dc.w $FD2C
 dc.w $D080 ; ROM 0x01B810: addl %d0,%d0
 dc.w $21AE ; ROM 0x01B812: movel %fp@(-40),%a0@(0000000000000000,%d0:l)
 dc.w $FFD8
 dc.w $0800
 dc.w $31AE ; ROM 0x01B818: movew %fp@(-36),%a0@(0000000000000004,%d0:l)
 dc.w $FFDC
 dc.w $0804
 dc.w $3005 ; ROM 0x01B81E: movew %d5,%d0
 dc.w $D06E ; ROM 0x01B820: addw %fp@(-730),%d0
 dc.w $FD26
 dc.w $B04D ; ROM 0x01B824: cmpw %a5,%d0
 dc.w $6D00 ; ROM 0x01B826: bltw 0x81b706
 dc.w $FEDE
 dc.w $3E0D ; ROM 0x01B82A: movew %a5,%d7
 dc.w $9E05 ; ROM 0x01B82C: subb %d5,%d7
 dc.w $1D47 ; ROM 0x01B82E: moveb %d7,%fp@(-39)
 dc.w $FFD9
 dc.w $41EE ; ROM 0x01B832: lea %fp@(-680),%a0
 dc.w $FD58
 dc.w $3D6E ; ROM 0x01B836: movew %fp@(12),%fp@(-726)
 dc.w $000C
 dc.w $FD2A
 dc.w $202E ; ROM 0x01B83C: movel %fp@(-728),%d0
 dc.w $FD28
 dc.w $D080 ; ROM 0x01B840: addl %d0,%d0
 dc.w $D1C0 ; ROM 0x01B842: addal %d0,%a0
 dc.w $B1CA ; ROM 0x01B844: cmpal %a2,%a0
 dc.w $6200 ; ROM 0x01B846: bhiw 0x81b854
 dc.w $000C
 dc.w $1D7C ; ROM 0x01B84A: moveb #99,%fp@(-40)
 dc.w $0063
 dc.w $FFD8
 dc.w $6000 ; ROM 0x01B850: braw 0x81b8aa
 dc.w $0058
 dc.w $3E2E ; ROM 0x01B854: movew %fp@(14),%d7
 dc.w $000E
 dc.w $BE52 ; ROM 0x01B858: cmpw %a2@,%d7
 dc.w $6300 ; ROM 0x01B85A: blsw 0x81b87a
 dc.w $001E
 dc.w $103C ; ROM 0x01B85E: moveb #15,%d0
 dc.w $000F
 dc.w $0C52 ; ROM 0x01B862: cmpiw #255,%a2@
 dc.w $00FF
 dc.w $6200 ; ROM 0x01B866: bhiw 0x81b86e
 dc.w $0006
 dc.w $103C ; ROM 0x01B86A: moveb #16,%d0
 dc.w $0010
 dc.w $1D40 ; ROM 0x01B86E: moveb %d0,%fp@(-40)
 dc.w $FFD8
 dc.w $3D5A ; ROM 0x01B872: movew %a2@+,%fp@(-38)
 dc.w $FFDA
 dc.w $6000 ; ROM 0x01B876: braw 0x81b8aa
 dc.w $0032
 dc.w $3012 ; ROM 0x01B87A: movew %a2@,%d0
 dc.w $906E ; ROM 0x01B87C: subw %fp@(14),%d0
 dc.w $000E
 dc.w $C0BC ; ROM 0x01B880: andl #65535,%d0
 dc.w $0000
 dc.w $FFFF
 dc.w $D080 ; ROM 0x01B886: addl %d0,%d0
 dc.w $286E ; ROM 0x01B888: moveal %fp@(20),%a4
 dc.w $0014
 dc.w $1D74 ; ROM 0x01B88C: moveb %a4@(0000000000000001,%d0:l),%fp@(-40)
 dc.w $0801
 dc.w $FFD8
 dc.w $301A ; ROM 0x01B892: movew %a2@+,%d0
 dc.w $906E ; ROM 0x01B894: subw %fp@(14),%d0
 dc.w $000E
 dc.w $C0BC ; ROM 0x01B898: andl #65535,%d0
 dc.w $0000
 dc.w $FFFF
 dc.w $D080 ; ROM 0x01B89E: addl %d0,%d0
 dc.w $286E ; ROM 0x01B8A0: moveal %fp@(16),%a4
 dc.w $0010
 dc.w $3D74 ; ROM 0x01B8A4: movew %a4@(0000000000000000,%d0:l),%fp@(-38)
 dc.w $0800
 dc.w $FFDA
 dc.w $300D ; ROM 0x01B8AA: movew %a5,%d0
 dc.w $9045 ; ROM 0x01B8AC: subw %d5,%d0
 dc.w $7401 ; ROM 0x01B8AE: moveq #1,%d2
 dc.w $E162 ; ROM 0x01B8B0: aslw %d0,%d2
 dc.w $3604 ; ROM 0x01B8B2: movew %d4,%d3
 dc.w $EA6B ; ROM 0x01B8B4: lsrw %d5,%d3
 dc.w $BC43 ; ROM 0x01B8B6: cmpw %d3,%d6
 dc.w $6300 ; ROM 0x01B8B8: blsw 0x81b8da
 dc.w $0020
 dc.w $7200 ; ROM 0x01B8BC: moveq #0,%d1
 dc.w $3203 ; ROM 0x01B8BE: movew %d3,%d1
 dc.w $2001 ; ROM 0x01B8C0: movel %d1,%d0
 dc.w $D080 ; ROM 0x01B8C2: addl %d0,%d0
 dc.w $D081 ; ROM 0x01B8C4: addl %d1,%d0
 dc.w $D080 ; ROM 0x01B8C6: addl %d0,%d0
 dc.w $23AE ; ROM 0x01B8C8: movel %fp@(-40),%a1@(0000000000000000,%d0:l)
 dc.w $FFD8
 dc.w $0800
 dc.w $33AE ; ROM 0x01B8CE: movew %fp@(-36),%a1@(0000000000000004,%d0:l)
 dc.w $FFDC
 dc.w $0804
 dc.w $D642 ; ROM 0x01B8D4: addw %d2,%d3
 dc.w $BC43 ; ROM 0x01B8D6: cmpw %d3,%d6
 dc.w $62E4 ; ROM 0x01B8D8: bhis 0x81b8be
 dc.w $300D ; ROM 0x01B8DA: movew %a5,%d0
 dc.w $5340 ; ROM 0x01B8DC: subqw #1,%d0
 dc.w $7601 ; ROM 0x01B8DE: moveq #1,%d3
 dc.w $E163 ; ROM 0x01B8E0: aslw %d0,%d3
 dc.w $6000 ; ROM 0x01B8E2: braw 0x81b8ea
 dc.w $0006
 dc.w $B744 ; ROM 0x01B8E6: eorw %d3,%d4
 dc.w $E24B ; ROM 0x01B8E8: lsrw #1,%d3
 dc.w $3004 ; ROM 0x01B8EA: movew %d4,%d0
 dc.w $C043 ; ROM 0x01B8EC: andw %d3,%d0
 dc.w $66F6 ; ROM 0x01B8EE: bnes 0x81b8e6
 dc.w $B744 ; ROM 0x01B8F0: eorw %d3,%d4
 dc.w $7001 ; ROM 0x01B8F2: moveq #1,%d0
 dc.w $EB60 ; ROM 0x01B8F4: aslw %d5,%d0
 dc.w $5340 ; ROM 0x01B8F6: subqw #1,%d0
 dc.w $C044 ; ROM 0x01B8F8: andw %d4,%d0
 dc.w $320B ; ROM 0x01B8FA: movew %a3,%d1
 dc.w $48C1 ; ROM 0x01B8FC: extl %d1
 dc.w $D281 ; ROM 0x01B8FE: addl %d1,%d1
 dc.w $41F6 ; ROM 0x01B900: lea %fp@(0000000000000000,%d1:l),%a0
 dc.w $1800
 dc.w $243C ; ROM 0x01B904: movel #-714,%d2
 dc.w $FFFF
 dc.w $FD36
 dc.w $B070 ; ROM 0x01B90A: cmpw %a0@(0000000000000000,%d2:l),%d0
 dc.w $2800
 dc.w $6700 ; ROM 0x01B90E: beqw 0x81b930
 dc.w $0020
 dc.w $534B ; ROM 0x01B912: subqw #1,%a3
 dc.w $9A6E ; ROM 0x01B914: subw %fp@(-730),%d5
 dc.w $FD26
 dc.w $7001 ; ROM 0x01B918: moveq #1,%d0
 dc.w $EB60 ; ROM 0x01B91A: aslw %d5,%d0
 dc.w $5340 ; ROM 0x01B91C: subqw #1,%d0
 dc.w $C044 ; ROM 0x01B91E: andw %d4,%d0
 dc.w $320B ; ROM 0x01B920: movew %a3,%d1
 dc.w $48C1 ; ROM 0x01B922: extl %d1
 dc.w $D281 ; ROM 0x01B924: addl %d1,%d1
 dc.w $41F6 ; ROM 0x01B926: lea %fp@(0000000000000000,%d1:l),%a0
 dc.w $1800
 dc.w $B070 ; ROM 0x01B92A: cmpw %a0@(0000000000000000,%d2:l),%d0
 dc.w $2800
 dc.w $66E2 ; ROM 0x01B92E: bnes 0x81b912
 dc.w $536E ; ROM 0x01B930: subqw #1,%fp@(-716)
 dc.w $FD34
 dc.w $6400 ; ROM 0x01B934: bccw 0x81b81e
 dc.w $FEE8
 dc.w $524D ; ROM 0x01B938: addqw #1,%a5
 dc.w $3E2E ; ROM 0x01B93A: movew %fp@(-718),%d7
 dc.w $FD32
 dc.w $BE4D ; ROM 0x01B93E: cmpw %a5,%d7
 dc.w $6C00 ; ROM 0x01B940: bgew 0x81b6e4
 dc.w $FDA2
 dc.w $4240 ; ROM 0x01B944: clrw %d0
 dc.w $4A6E ; ROM 0x01B946: tstw %fp@(-720)
 dc.w $FD30
 dc.w $6700 ; ROM 0x01B94A: beqw 0x81b95a
 dc.w $000E
 dc.w $0C6E ; ROM 0x01B94E: cmpiw #1,%fp@(-718)
 dc.w $0001
 dc.w $FD32
 dc.w $56C0 ; ROM 0x01B954: sne %d0
 dc.w $4880 ; ROM 0x01B956: extw %d0
 dc.w $4440 ; ROM 0x01B958: negw %d0
 dc.w $4CEE ; ROM 0x01B95A: moveml %fp@(-772),%d2-%d7/%a2-%a5
 dc.w $3CFC
 dc.w $FCFC
 dc.w $4E5E ; ROM 0x01B960: unlk %fp
 dc.w $4E75 ; ROM 0x01B962: rts
 dc.w $4E56 ; ROM 0x01B964: linkw %fp,#0
 dc.w $0000
 dc.w $2F02 ; ROM 0x01B968: movel %d2,%sp@-
 dc.w $206E ; ROM 0x01B96A: moveal %fp@(8),%a0
 dc.w $0008
 dc.w $B0FC ; ROM 0x01B96E: cmpaw #0,%a0
 dc.w $0000
 dc.w $6700 ; ROM 0x01B972: beqw 0x81b98e
 dc.w $001A
 dc.w $5D48 ; ROM 0x01B976: subqw #6,%a0
 dc.w $2428 ; ROM 0x01B978: movel %a0@(2),%d2
 dc.w $0002
 dc.w $2F08 ; ROM 0x01B97C: movel %a0,%sp@-
 dc.w $4EB9 ; ROM 0x01B97E: jsr 0x81b1ae
 dc.w $0081
 dc.w $B1AE
 dc.w $584F ; ROM 0x01B984: addqw #4,%sp
 dc.w $2042 ; ROM 0x01B986: moveal %d2,%a0
 dc.w $B0FC ; ROM 0x01B988: cmpaw #0,%a0
 dc.w $0000
 dc.w $66E8 ; ROM 0x01B98C: bnes 0x81b976
 dc.w $4240 ; ROM 0x01B98E: clrw %d0
 dc.w $242E ; ROM 0x01B990: movel %fp@(-4),%d2
 dc.w $FFFC
 dc.w $4E5E ; ROM 0x01B994: unlk %fp
 dc.w $4E75 ; ROM 0x01B996: rts
 dc.w $4E56 ; ROM 0x01B998: linkw %fp,#0
 dc.w $0000
 dc.w $2F02 ; ROM 0x01B99C: movel %d2,%sp@-
 dc.w $4282 ; ROM 0x01B99E: clrl %d2
 dc.w $342E ; ROM 0x01B9A0: movew %fp@(8),%d2
 dc.w $0008
 dc.w $2F02 ; ROM 0x01B9A4: movel %d2,%sp@-
 dc.w $2F39 ; ROM 0x01B9A6: movel 0x1d60a,%sp@-
 dc.w $0001
 dc.w $D60A
 dc.w $4879 ; ROM 0x01B9AC: pea 0x1f7000
 dc.w $001F
 dc.w $7000
 dc.w $4EB9 ; ROM 0x01B9B2: jsr 0x81b38a
 dc.w $0081
 dc.w $B38A
 dc.w $D5B9 ; ROM 0x01B9B8: addl %d2,0x1d60a
 dc.w $0001
 dc.w $D60A
 dc.w $242E ; ROM 0x01B9BE: movel %fp@(-4),%d2
 dc.w $FFFC
 dc.w $4E5E ; ROM 0x01B9C2: unlk %fp
 dc.w $4E75 ; ROM 0x01B9C4: rts
 dc.w $4E56 ; ROM 0x01B9C6: linkw %fp,#0
 dc.w $0000
 dc.w $2F0A ; ROM 0x01B9CA: movel %a2,%sp@-
 dc.w $202E ; ROM 0x01B9CC: movel %fp@(8),%d0
 dc.w $0008
 dc.w $222E ; ROM 0x01B9D0: movel %fp@(12),%d1
 dc.w $000C
 dc.w $306E ; ROM 0x01B9D4: moveaw %fp@(16),%a0
 dc.w $0010
 dc.w $326E ; ROM 0x01B9D8: moveaw %fp@(18),%a1
 dc.w $0012
 dc.w $247C ; ROM 0x01B9DC: moveal #15743884,%a2
 dc.w $00F0
 dc.w $3B8C
 dc.w $2480 ; ROM 0x01B9E2: movel %d0,%a2@
 dc.w $247C ; ROM 0x01B9E4: moveal #15743888,%a2
 dc.w $00F0
 dc.w $3B90
 dc.w $2481 ; ROM 0x01B9EA: movel %d1,%a2@
 dc.w $247C ; ROM 0x01B9EC: moveal #15743892,%a2
 dc.w $00F0
 dc.w $3B94
 dc.w $3048 ; ROM 0x01B9F2: moveaw %a0,%a0
 dc.w $2488 ; ROM 0x01B9F4: movel %a0,%a2@
 dc.w $247C ; ROM 0x01B9F6: moveal #15743896,%a2
 dc.w $00F0
 dc.w $3B98
 dc.w $3249 ; ROM 0x01B9FC: moveaw %a1,%a1
 dc.w $2489 ; ROM 0x01B9FE: movel %a1,%a2@
 dc.w $247C ; ROM 0x01BA00: moveal #15743900,%a2
 dc.w $00F0
 dc.w $3B9C
 dc.w $24B9 ; ROM 0x01BA06: movel 0x1df1a,%a2@
 dc.w $0001
 dc.w $DF1A
 dc.w $247C ; ROM 0x01BA0C: moveal #15743904,%a2
 dc.w $00F0
 dc.w $3BA0
 dc.w $4280 ; ROM 0x01BA12: clrl %d0
 dc.w $3039 ; ROM 0x01BA14: movew 0x1df1e,%d0
 dc.w $0001
 dc.w $DF1E
 dc.w $2480 ; ROM 0x01BA1A: movel %d0,%a2@
 dc.w $247C ; ROM 0x01BA1C: moveal #15743908,%a2
 dc.w $00F0
 dc.w $3BA4
 dc.w $4280 ; ROM 0x01BA22: clrl %d0
 dc.w $3039 ; ROM 0x01BA24: movew 0x1df18,%d0
 dc.w $0001
 dc.w $DF18
 dc.w $2480 ; ROM 0x01BA2A: movel %d0,%a2@
 dc.w $247C ; ROM 0x01BA2C: moveal #15743912,%a2
 dc.w $00F0
 dc.w $3BA8
 dc.w $24B9 ; ROM 0x01BA32: movel 0x1d60e,%a2@
 dc.w $0001
 dc.w $D60E
 dc.w $247C ; ROM 0x01BA38: moveal #15743916,%a2
 dc.w $00F0
 dc.w $3BAC
 dc.w $24B9 ; ROM 0x01BA3E: movel 0x1d60a,%a2@
 dc.w $0001
 dc.w $D60A
 dc.w $247C ; ROM 0x01BA44: moveal #15743920,%a2
 dc.w $00F0
 dc.w $3BB0
 dc.w $24BC ; ROM 0x01BA4A: movel #2060288,%a2@
 dc.w $001F
 dc.w $7000
 dc.w $4EB9 ; ROM 0x01BA50: jsr 0x80b7a6
 dc.w $0080
 dc.w $B7A6
 dc.w $247C ; ROM 0x01BA56: moveal #15743916,%a2
 dc.w $00F0
 dc.w $3BAC
 dc.w $23D2 ; ROM 0x01BA5C: movel %a2@,0x1d60a
 dc.w $0001
 dc.w $D60A
 dc.w $247C ; ROM 0x01BA62: moveal #15743912,%a2
 dc.w $00F0
 dc.w $3BA8
 dc.w $23D2 ; ROM 0x01BA68: movel %a2@,0x1d60e
 dc.w $0001
 dc.w $D60E
 dc.w $247C ; ROM 0x01BA6E: moveal #15743908,%a2
 dc.w $00F0
 dc.w $3BA4
 dc.w $2212 ; ROM 0x01BA74: movel %a2@,%d1
 dc.w $33C1 ; ROM 0x01BA76: movew %d1,0x1df18
 dc.w $0001
 dc.w $DF18
 dc.w $247C ; ROM 0x01BA7C: moveal #15743904,%a2
 dc.w $00F0
 dc.w $3BA0
 dc.w $2212 ; ROM 0x01BA82: movel %a2@,%d1
 dc.w $33C1 ; ROM 0x01BA84: movew %d1,0x1df1e
 dc.w $0001
 dc.w $DF1E
 dc.w $247C ; ROM 0x01BA8A: moveal #15743900,%a2
 dc.w $00F0
 dc.w $3B9C
 dc.w $2212 ; ROM 0x01BA90: movel %a2@,%d1
 dc.w $2201 ; ROM 0x01BA92: movel %d1,%d1
 dc.w $4279 ; ROM 0x01BA94: clrw 0x1df1a
 dc.w $0001
 dc.w $DF1A
 dc.w $33C1 ; ROM 0x01BA9A: movew %d1,0x1df1c
 dc.w $0001
 dc.w $DF1C
 dc.w $246E ; ROM 0x01BAA0: moveal %fp@(-4),%a2
 dc.w $FFFC
 dc.w $4E5E ; ROM 0x01BAA4: unlk %fp
 dc.w $4E75 ; ROM 0x01BAA6: rts
 dc.w $4E56 ; ROM 0x01BAA8: linkw %fp,#0
 dc.w $0000
 dc.w $48E7 ; ROM 0x01BAAC: moveml %d2-%d7,%sp@-
 dc.w $3F00
 dc.w $2839 ; ROM 0x01BAB0: movel 0x1df1a,%d4
 dc.w $0001
 dc.w $DF1A
 dc.w $3639 ; ROM 0x01BAB6: movew 0x1df1e,%d3
 dc.w $0001
 dc.w $DF1E
 dc.w $3C39 ; ROM 0x01BABC: movew 0x1df18,%d6
 dc.w $0001
 dc.w $DF18
 dc.w $3A03 ; ROM 0x01BAC2: movew %d3,%d5
 dc.w $CA7C ; ROM 0x01BAC4: andw #7,%d5
 dc.w $0007
 dc.w $7007 ; ROM 0x01BAC8: moveq #7,%d0
 dc.w $C085 ; ROM 0x01BACA: andl %d5,%d0
 dc.w $E0AC ; ROM 0x01BACC: lsrl %d0,%d4
 dc.w $9645 ; ROM 0x01BACE: subw %d5,%d3
 dc.w $B67C ; ROM 0x01BAD0: cmpw #15,%d3
 dc.w $000F
 dc.w $6200 ; ROM 0x01BAD4: bhiw 0x81bafa
 dc.w $0024
 dc.w $7400 ; ROM 0x01BAD8: moveq #0,%d2
 dc.w $7200 ; ROM 0x01BADA: moveq #0,%d1
 dc.w $2079 ; ROM 0x01BADC: moveal 0x1d60e,%a0
 dc.w $0001
 dc.w $D60E
 dc.w $1410 ; ROM 0x01BAE2: moveb %a0@,%d2
 dc.w $3203 ; ROM 0x01BAE4: movew %d3,%d1
 dc.w $2002 ; ROM 0x01BAE6: movel %d2,%d0
 dc.w $E3A8 ; ROM 0x01BAE8: lsll %d1,%d0
 dc.w $8880 ; ROM 0x01BAEA: orl %d0,%d4
 dc.w $52B9 ; ROM 0x01BAEC: addql #1,0x1d60e
 dc.w $0001
 dc.w $D60E
 dc.w $5043 ; ROM 0x01BAF2: addqw #8,%d3
 dc.w $B67C ; ROM 0x01BAF4: cmpw #15,%d3
 dc.w $000F
 dc.w $63E2 ; ROM 0x01BAF8: blss 0x81badc
 dc.w $3A04 ; ROM 0x01BAFA: movew %d4,%d5
 dc.w $4244 ; ROM 0x01BAFC: clrw %d4
 dc.w $4844 ; ROM 0x01BAFE: swap %d4
 dc.w $D67C ; ROM 0x01BB00: addw #-16,%d3
 dc.w $FFF0
 dc.w $B67C ; ROM 0x01BB04: cmpw #15,%d3
 dc.w $000F
 dc.w $6200 ; ROM 0x01BB08: bhiw 0x81bb2e
 dc.w $0024
 dc.w $7400 ; ROM 0x01BB0C: moveq #0,%d2
 dc.w $7200 ; ROM 0x01BB0E: moveq #0,%d1
 dc.w $2079 ; ROM 0x01BB10: moveal 0x1d60e,%a0
 dc.w $0001
 dc.w $D60E
 dc.w $1410 ; ROM 0x01BB16: moveb %a0@,%d2
 dc.w $3203 ; ROM 0x01BB18: movew %d3,%d1
 dc.w $2002 ; ROM 0x01BB1A: movel %d2,%d0
 dc.w $E3A8 ; ROM 0x01BB1C: lsll %d1,%d0
 dc.w $8880 ; ROM 0x01BB1E: orl %d0,%d4
 dc.w $52B9 ; ROM 0x01BB20: addql #1,0x1d60e
 dc.w $0001
 dc.w $D60E
 dc.w $5043 ; ROM 0x01BB26: addqw #8,%d3
 dc.w $B67C ; ROM 0x01BB28: cmpw #15,%d3
 dc.w $000F
 dc.w $63E2 ; ROM 0x01BB2C: blss 0x81bb10
 dc.w $3004 ; ROM 0x01BB2E: movew %d4,%d0
 dc.w $4640 ; ROM 0x01BB30: notw %d0
 dc.w $B045 ; ROM 0x01BB32: cmpw %d5,%d0
 dc.w $6700 ; ROM 0x01BB34: beqw 0x81bb3e
 dc.w $0008
 dc.w $7001 ; ROM 0x01BB38: moveq #1,%d0
 dc.w $6000 ; ROM 0x01BB3A: braw 0x81bbba
 dc.w $007E
 dc.w $4244 ; ROM 0x01BB3E: clrw %d4
 dc.w $4844 ; ROM 0x01BB40: swap %d4
 dc.w $D67C ; ROM 0x01BB42: addw #-16,%d3
 dc.w $FFF0
 dc.w $5345 ; ROM 0x01BB46: subqw #1,%d5
 dc.w $BA7C ; ROM 0x01BB48: cmpw #-1,%d5
 dc.w $FFFF
 dc.w $6700 ; ROM 0x01BB4C: beqw 0x81bba6
 dc.w $0058
 dc.w $7E00 ; ROM 0x01BB50: moveq #0,%d7
 dc.w $B67C ; ROM 0x01BB52: cmpw #7,%d3
 dc.w $0007
 dc.w $6200 ; ROM 0x01BB56: bhiw 0x81bb7c
 dc.w $0024
 dc.w $7400 ; ROM 0x01BB5A: moveq #0,%d2
 dc.w $7200 ; ROM 0x01BB5C: moveq #0,%d1
 dc.w $2079 ; ROM 0x01BB5E: moveal 0x1d60e,%a0
 dc.w $0001
 dc.w $D60E
 dc.w $1410 ; ROM 0x01BB64: moveb %a0@,%d2
 dc.w $3203 ; ROM 0x01BB66: movew %d3,%d1
 dc.w $2002 ; ROM 0x01BB68: movel %d2,%d0
 dc.w $E3A8 ; ROM 0x01BB6A: lsll %d1,%d0
 dc.w $8880 ; ROM 0x01BB6C: orl %d0,%d4
 dc.w $52B9 ; ROM 0x01BB6E: addql #1,0x1d60e
 dc.w $0001
 dc.w $D60E
 dc.w $5043 ; ROM 0x01BB74: addqw #8,%d3
 dc.w $B67C ; ROM 0x01BB76: cmpw #7,%d3
 dc.w $0007
 dc.w $63E2 ; ROM 0x01BB7A: blss 0x81bb5e
 dc.w $3E06 ; ROM 0x01BB7C: movew %d6,%d7
 dc.w $41F9 ; ROM 0x01BB7E: lea 0x1f7000,%a0
 dc.w $001F
 dc.w $7000
 dc.w $1184 ; ROM 0x01BB84: moveb %d4,%a0@(0000000000000000,%d7:l)
 dc.w $7800
 dc.w $5246 ; ROM 0x01BB88: addqw #1,%d6
 dc.w $BC7C ; ROM 0x01BB8A: cmpw #-32768,%d6
 dc.w $8000
 dc.w $6600 ; ROM 0x01BB8E: bnew 0x81bb9e
 dc.w $000E
 dc.w $3F06 ; ROM 0x01BB92: movew %d6,%sp@-
 dc.w $4EB9 ; ROM 0x01BB94: jsr 0x81b998
 dc.w $0081
 dc.w $B998
 dc.w $544F ; ROM 0x01BB9A: addqw #2,%sp
 dc.w $4246 ; ROM 0x01BB9C: clrw %d6
 dc.w $E08C ; ROM 0x01BB9E: lsrl #8,%d4
 dc.w $5143 ; ROM 0x01BBA0: subqw #8,%d3
 dc.w $51CD ; ROM 0x01BBA2: dbf %d5,0x81bb52
 dc.w $FFAE
 dc.w $33C6 ; ROM 0x01BBA6: movew %d6,0x1df18
 dc.w $0001
 dc.w $DF18
 dc.w $23C4 ; ROM 0x01BBAC: movel %d4,0x1df1a
 dc.w $0001
 dc.w $DF1A
 dc.w $33C3 ; ROM 0x01BBB2: movew %d3,0x1df1e
 dc.w $0001
 dc.w $DF1E
 dc.w $4240 ; ROM 0x01BBB8: clrw %d0
 dc.w $4CEE ; ROM 0x01BBBA: moveml %fp@(-24),%d2-%d7
 dc.w $00FC
 dc.w $FFE8
 dc.w $4E5E ; ROM 0x01BBC0: unlk %fp
 dc.w $4E75 ; ROM 0x01BBC2: rts
 dc.w $4E56 ; ROM 0x01BBC4: linkw %fp,#-588
 dc.w $FDB4
 dc.w $48E7 ; ROM 0x01BBC8: moveml %d2-%d3/%a2,%sp@-
 dc.w $3020
 dc.w $347C ; ROM 0x01BBCC: moveaw #0,%a2
 dc.w $0000
 dc.w $323C ; ROM 0x01BBD0: movew #143,%d1
 dc.w $008F
 dc.w $327C ; ROM 0x01BBD4: moveaw #-576,%a1
 dc.w $FDC0
 dc.w $300A ; ROM 0x01BBD8: movew %a2,%d0
 dc.w $48C0 ; ROM 0x01BBDA: extl %d0
 dc.w $D080 ; ROM 0x01BBDC: addl %d0,%d0
 dc.w $41F6 ; ROM 0x01BBDE: lea %fp@(0000000000000000,%d0:l),%a0
 dc.w $0800
 dc.w $33BC ; ROM 0x01BBE2: movew #8,%a1@(0000000000000000,%a0:l)
 dc.w $0008
 dc.w $8800
 dc.w $524A ; ROM 0x01BBE8: addqw #1,%a2
 dc.w $B24A ; ROM 0x01BBEA: cmpw %a2,%d1
 dc.w $6CEA ; ROM 0x01BBEC: bges 0x81bbd8
 dc.w $323C ; ROM 0x01BBEE: movew #255,%d1
 dc.w $00FF
 dc.w $B24A ; ROM 0x01BBF2: cmpw %a2,%d1
 dc.w $6D00 ; ROM 0x01BBF4: bltw 0x81bc12
 dc.w $001C
 dc.w $327C ; ROM 0x01BBF8: moveaw #-576,%a1
 dc.w $FDC0
 dc.w $300A ; ROM 0x01BBFC: movew %a2,%d0
 dc.w $48C0 ; ROM 0x01BBFE: extl %d0
 dc.w $D080 ; ROM 0x01BC00: addl %d0,%d0
 dc.w $41F6 ; ROM 0x01BC02: lea %fp@(0000000000000000,%d0:l),%a0
 dc.w $0800
 dc.w $33BC ; ROM 0x01BC06: movew #9,%a1@(0000000000000000,%a0:l)
 dc.w $0009
 dc.w $8800
 dc.w $524A ; ROM 0x01BC0C: addqw #1,%a2
 dc.w $B24A ; ROM 0x01BC0E: cmpw %a2,%d1
 dc.w $6CEA ; ROM 0x01BC10: bges 0x81bbfc
 dc.w $323C ; ROM 0x01BC12: movew #279,%d1
 dc.w $0117
 dc.w $B24A ; ROM 0x01BC16: cmpw %a2,%d1
 dc.w $6D00 ; ROM 0x01BC18: bltw 0x81bc36
 dc.w $001C
 dc.w $327C ; ROM 0x01BC1C: moveaw #-576,%a1
 dc.w $FDC0
 dc.w $300A ; ROM 0x01BC20: movew %a2,%d0
 dc.w $48C0 ; ROM 0x01BC22: extl %d0
 dc.w $D080 ; ROM 0x01BC24: addl %d0,%d0
 dc.w $41F6 ; ROM 0x01BC26: lea %fp@(0000000000000000,%d0:l),%a0
 dc.w $0800
 dc.w $33BC ; ROM 0x01BC2A: movew #7,%a1@(0000000000000000,%a0:l)
 dc.w $0007
 dc.w $8800
 dc.w $524A ; ROM 0x01BC30: addqw #1,%a2
 dc.w $B24A ; ROM 0x01BC32: cmpw %a2,%d1
 dc.w $6CEA ; ROM 0x01BC34: bges 0x81bc20
 dc.w $323C ; ROM 0x01BC36: movew #287,%d1
 dc.w $011F
 dc.w $B24A ; ROM 0x01BC3A: cmpw %a2,%d1
 dc.w $6D00 ; ROM 0x01BC3C: bltw 0x81bc5a
 dc.w $001C
 dc.w $327C ; ROM 0x01BC40: moveaw #-576,%a1
 dc.w $FDC0
 dc.w $300A ; ROM 0x01BC44: movew %a2,%d0
 dc.w $48C0 ; ROM 0x01BC46: extl %d0
 dc.w $D080 ; ROM 0x01BC48: addl %d0,%d0
 dc.w $41F6 ; ROM 0x01BC4A: lea %fp@(0000000000000000,%d0:l),%a0
 dc.w $0800
 dc.w $33BC ; ROM 0x01BC4E: movew #8,%a1@(0000000000000000,%a0:l)
 dc.w $0008
 dc.w $8800
 dc.w $524A ; ROM 0x01BC54: addqw #1,%a2
 dc.w $B24A ; ROM 0x01BC56: cmpw %a2,%d1
 dc.w $6CEA ; ROM 0x01BC58: bges 0x81bc44
 dc.w $3D7C ; ROM 0x01BC5A: movew #7,%fp@(-582)
 dc.w $0007
 dc.w $FDBA
 dc.w $486E ; ROM 0x01BC60: pea %fp@(-582)
 dc.w $FDBA
 dc.w $486E ; ROM 0x01BC64: pea %fp@(-580)
 dc.w $FDBC
 dc.w $4879 ; ROM 0x01BC68: pea 0x8ea2d4
 dc.w $008E
 dc.w $A2D4
 dc.w $4879 ; ROM 0x01BC6E: pea 0x8ea296
 dc.w $008E
 dc.w $A296
 dc.w $3F3C ; ROM 0x01BC74: movew #257,%sp@-
 dc.w $0101
 dc.w $3F3C ; ROM 0x01BC78: movew #288,%sp@-
 dc.w $0120
 dc.w $243C ; ROM 0x01BC7C: movel #-576,%d2
 dc.w $FFFF
 dc.w $FDC0
 dc.w $4876 ; ROM 0x01BC82: pea %fp@(0000000000000000,%d2:l)
 dc.w $2800
 dc.w $4EB9 ; ROM 0x01BC86: jsr 0x81b56a
 dc.w $0081
 dc.w $B56A
 dc.w $DEFC ; ROM 0x01BC8C: addaw #24,%sp
 dc.w $0018
 dc.w $3440 ; ROM 0x01BC90: moveaw %d0,%a2
 dc.w $4A40 ; ROM 0x01BC92: tstw %d0
 dc.w $6600 ; ROM 0x01BC94: bnew 0x81bd36
 dc.w $00A0
 dc.w $2242 ; ROM 0x01BC98: moveal %d2,%a1
 dc.w $300A ; ROM 0x01BC9A: movew %a2,%d0
 dc.w $48C0 ; ROM 0x01BC9C: extl %d0
 dc.w $D080 ; ROM 0x01BC9E: addl %d0,%d0
 dc.w $41F6 ; ROM 0x01BCA0: lea %fp@(0000000000000000,%d0:l),%a0
 dc.w $0800
 dc.w $33BC ; ROM 0x01BCA4: movew #5,%a1@(0000000000000000,%a0:l)
 dc.w $0005
 dc.w $8800
 dc.w $524A ; ROM 0x01BCAA: addqw #1,%a2
 dc.w $360A ; ROM 0x01BCAC: movew %a2,%d3
 dc.w $B67C ; ROM 0x01BCAE: cmpw #29,%d3
 dc.w $001D
 dc.w $6FE6 ; ROM 0x01BCB2: bles 0x81bc9a
 dc.w $3D7C ; ROM 0x01BCB4: movew #5,%fp@(-588)
 dc.w $0005
 dc.w $FDB4
 dc.w $486E ; ROM 0x01BCBA: pea %fp@(-588)
 dc.w $FDB4
 dc.w $486E ; ROM 0x01BCBE: pea %fp@(-586)
 dc.w $FDB6
 dc.w $4879 ; ROM 0x01BCC2: pea 0x8ea34e
 dc.w $008E
 dc.w $A34E
 dc.w $4879 ; ROM 0x01BCC8: pea 0x8ea312
 dc.w $008E
 dc.w $A312
 dc.w $4267 ; ROM 0x01BCCE: clrw %sp@-
 dc.w $3F3C ; ROM 0x01BCD0: movew #30,%sp@-
 dc.w $001E
 dc.w $486E ; ROM 0x01BCD4: pea %fp@(-576)
 dc.w $FDC0
 dc.w $4EB9 ; ROM 0x01BCD8: jsr 0x81b56a
 dc.w $0081
 dc.w $B56A
 dc.w $DEFC ; ROM 0x01BCDE: addaw #24,%sp
 dc.w $0018
 dc.w $3440 ; ROM 0x01BCE2: moveaw %d0,%a2
 dc.w $B07C ; ROM 0x01BCE4: cmpw #1,%d0
 dc.w $0001
 dc.w $6F00 ; ROM 0x01BCE8: blew 0x81bcfc
 dc.w $0012
 dc.w $2F2E ; ROM 0x01BCEC: movel %fp@(-580),%sp@-
 dc.w $FDBC
 dc.w $4EB9 ; ROM 0x01BCF0: jsr 0x81b964
 dc.w $0081
 dc.w $B964
 dc.w $300A ; ROM 0x01BCF6: movew %a2,%d0
 dc.w $6000 ; ROM 0x01BCF8: braw 0x81bd36
 dc.w $003C
 dc.w $3F2E ; ROM 0x01BCFC: movew %fp@(-588),%sp@-
 dc.w $FDB4
 dc.w $3F2E ; ROM 0x01BD00: movew %fp@(-582),%sp@-
 dc.w $FDBA
 dc.w $2F2E ; ROM 0x01BD04: movel %fp@(-586),%sp@-
 dc.w $FDB6
 dc.w $2F2E ; ROM 0x01BD08: movel %fp@(-580),%sp@-
 dc.w $FDBC
 dc.w $4EB9 ; ROM 0x01BD0C: jsr 0x81b9c6
 dc.w $0081
 dc.w $B9C6
 dc.w $DEFC ; ROM 0x01BD12: addaw #12,%sp
 dc.w $000C
 dc.w $4A40 ; ROM 0x01BD16: tstw %d0
 dc.w $6600 ; ROM 0x01BD18: bnew 0x81bd34
 dc.w $001A
 dc.w $2F2E ; ROM 0x01BD1C: movel %fp@(-580),%sp@-
 dc.w $FDBC
 dc.w $45F9 ; ROM 0x01BD20: lea 0x81b964,%a2
 dc.w $0081
 dc.w $B964
 dc.w $4E92 ; ROM 0x01BD26: jsr %a2@
 dc.w $2EAE ; ROM 0x01BD28: movel %fp@(-586),%sp@
 dc.w $FDB6
 dc.w $4E92 ; ROM 0x01BD2C: jsr %a2@
 dc.w $4240 ; ROM 0x01BD2E: clrw %d0
 dc.w $6000 ; ROM 0x01BD30: braw 0x81bd36
 dc.w $0004
 dc.w $7001 ; ROM 0x01BD34: moveq #1,%d0
 dc.w $4CEE ; ROM 0x01BD36: moveml %fp@(-600),%d2-%d3/%a2
 dc.w $040C
 dc.w $FDA8
 dc.w $4E5E ; ROM 0x01BD3C: unlk %fp
 dc.w $4E75 ; ROM 0x01BD3E: rts
 dc.w $2069 ; ROM 0x01BD40: moveal %a1@(28259),%a0
 dc.w $6E63
 dc.w $6F6D ; ROM 0x01BD44: bles 0x81bdb3
 dc.w $706C ; ROM 0x01BD46: moveq #108,%d0
 dc.w $6574 ; ROM 0x01BD48: bcss 0x81bdbe
 dc.w $6520 ; ROM 0x01BD4A: bcss 0x81bd6c
 dc.w $6C69 ; ROM 0x01BD4C: bges 0x81bdb7
 dc.w $7465 ; ROM 0x01BD4E: moveq #101,%d2
 dc.w $7261 ; ROM 0x01BD50: moveq #97,%d1
 dc.w $6C20 ; ROM 0x01BD52: bges 0x81bd74
 dc.w $7472 ; ROM 0x01BD54: moveq #114,%d2
 dc.w $6565 ; ROM 0x01BD56: bcss 0x81bdbd
 dc.w $0D0A ; ROM 0x01BD58: movepw %a2@(105),%d6
 dc.w $0069
 dc.w $6E63 ; ROM 0x01BD5C: bgts 0x81bdc1
 dc.w $6F6D ; ROM 0x01BD5E: bles 0x81bdcd
 dc.w $706C ; ROM 0x01BD60: moveq #108,%d0
 dc.w $6574 ; ROM 0x01BD62: bcss 0x81bdd8
 dc.w $6520 ; ROM 0x01BD64: bcss 0x81bd86
 dc.w $6469 ; ROM 0x01BD66: bccs 0x81bdd1
 dc.w $7374 ; ROM 0x01BD68: mvsw %a4@(0000000000006365)@(0000000000002074),%d1
 dc.w $616E
 dc.w $6365
 dc.w $2074
 dc.w $7265 ; ROM 0x01BD70: moveq #101,%d1
 dc.w $650A ; ROM 0x01BD72: bcss 0x81bd7e
 dc.w $0000 ; ROM 0x01BD74: orib #86,%d0
 dc.w $4E56
 dc.w $FD74 ; ROM 0x01BD78: frestore (cpid=6) %a4@(ffffffffffffffe7,%d4:l)
 dc.w $48E7
 dc.w $3F3C ; ROM 0x01BD7C: movew #10809,%sp@-
 dc.w $2A39
 dc.w $0001 ; ROM 0x01BD80: orib #26,%d1
 dc.w $DF1A
 dc.w $3839 ; ROM 0x01BD84: movew 0x1df1e,%d4
 dc.w $0001
 dc.w $DF1E
 dc.w $B87C ; ROM 0x01BD8A: cmpw #4,%d4
 dc.w $0004
 dc.w $6200 ; ROM 0x01BD8E: bhiw 0x81bdb4
 dc.w $0024
 dc.w $7400 ; ROM 0x01BD92: moveq #0,%d2
 dc.w $7200 ; ROM 0x01BD94: moveq #0,%d1
 dc.w $2079 ; ROM 0x01BD96: moveal 0x1d60e,%a0
 dc.w $0001
 dc.w $D60E
 dc.w $1410 ; ROM 0x01BD9C: moveb %a0@,%d2
 dc.w $3204 ; ROM 0x01BD9E: movew %d4,%d1
 dc.w $2002 ; ROM 0x01BDA0: movel %d2,%d0
 dc.w $E3A8 ; ROM 0x01BDA2: lsll %d1,%d0
 dc.w $8A80 ; ROM 0x01BDA4: orl %d0,%d5
 dc.w $52B9 ; ROM 0x01BDA6: addql #1,0x1d60e
 dc.w $0001
 dc.w $D60E
 dc.w $5044 ; ROM 0x01BDAC: addqw #8,%d4
 dc.w $B87C ; ROM 0x01BDAE: cmpw #4,%d4
 dc.w $0004
 dc.w $63E2 ; ROM 0x01BDB2: blss 0x81bd96
 dc.w $3005 ; ROM 0x01BDB4: movew %d5,%d0
 dc.w $C07C ; ROM 0x01BDB6: andw #31,%d0
 dc.w $001F
 dc.w $D07C ; ROM 0x01BDBA: addw #257,%d0
 dc.w $0101
 dc.w $3D40 ; ROM 0x01BDBE: movew %d0,%fp@(-648)
 dc.w $FD78
 dc.w $EA8D ; ROM 0x01BDC2: lsrl #5,%d5
 dc.w $5B44 ; ROM 0x01BDC4: subqw #5,%d4
 dc.w $B87C ; ROM 0x01BDC6: cmpw #4,%d4
 dc.w $0004
 dc.w $6200 ; ROM 0x01BDCA: bhiw 0x81bdf0
 dc.w $0024
 dc.w $7400 ; ROM 0x01BDCE: moveq #0,%d2
 dc.w $7200 ; ROM 0x01BDD0: moveq #0,%d1
 dc.w $2079 ; ROM 0x01BDD2: moveal 0x1d60e,%a0
 dc.w $0001
 dc.w $D60E
 dc.w $1410 ; ROM 0x01BDD8: moveb %a0@,%d2
 dc.w $3204 ; ROM 0x01BDDA: movew %d4,%d1
 dc.w $2002 ; ROM 0x01BDDC: movel %d2,%d0
 dc.w $E3A8 ; ROM 0x01BDDE: lsll %d1,%d0
 dc.w $8A80 ; ROM 0x01BDE0: orl %d0,%d5
 dc.w $52B9 ; ROM 0x01BDE2: addql #1,0x1d60e
 dc.w $0001
 dc.w $D60E
 dc.w $5044 ; ROM 0x01BDE8: addqw #8,%d4
 dc.w $B87C ; ROM 0x01BDEA: cmpw #4,%d4
 dc.w $0004
 dc.w $63E2 ; ROM 0x01BDEE: blss 0x81bdd2
 dc.w $3005 ; ROM 0x01BDF0: movew %d5,%d0
 dc.w $C07C ; ROM 0x01BDF2: andw #31,%d0
 dc.w $001F
 dc.w $5240 ; ROM 0x01BDF6: addqw #1,%d0
 dc.w $3D40 ; ROM 0x01BDF8: movew %d0,%fp@(-646)
 dc.w $FD7A
 dc.w $EA8D ; ROM 0x01BDFC: lsrl #5,%d5
 dc.w $5B44 ; ROM 0x01BDFE: subqw #5,%d4
 dc.w $B87C ; ROM 0x01BE00: cmpw #3,%d4
 dc.w $0003
 dc.w $6200 ; ROM 0x01BE04: bhiw 0x81be2a
 dc.w $0024
 dc.w $7400 ; ROM 0x01BE08: moveq #0,%d2
 dc.w $7200 ; ROM 0x01BE0A: moveq #0,%d1
 dc.w $2079 ; ROM 0x01BE0C: moveal 0x1d60e,%a0
 dc.w $0001
 dc.w $D60E
 dc.w $1410 ; ROM 0x01BE12: moveb %a0@,%d2
 dc.w $3204 ; ROM 0x01BE14: movew %d4,%d1
 dc.w $2002 ; ROM 0x01BE16: movel %d2,%d0
 dc.w $E3A8 ; ROM 0x01BE18: lsll %d1,%d0
 dc.w $8A80 ; ROM 0x01BE1A: orl %d0,%d5
 dc.w $52B9 ; ROM 0x01BE1C: addql #1,0x1d60e
 dc.w $0001
 dc.w $D60E
 dc.w $5044 ; ROM 0x01BE22: addqw #8,%d4
 dc.w $B87C ; ROM 0x01BE24: cmpw #3,%d4
 dc.w $0003
 dc.w $63E2 ; ROM 0x01BE28: blss 0x81be0c
 dc.w $3005 ; ROM 0x01BE2A: movew %d5,%d0
 dc.w $C07C ; ROM 0x01BE2C: andw #15,%d0
 dc.w $000F
 dc.w $3240 ; ROM 0x01BE30: moveaw %d0,%a1
 dc.w $5849 ; ROM 0x01BE32: addqw #4,%a1
 dc.w $E88D ; ROM 0x01BE34: lsrl #4,%d5
 dc.w $5944 ; ROM 0x01BE36: subqw #4,%d4
 dc.w $0C6E ; ROM 0x01BE38: cmpiw #286,%fp@(-648)
 dc.w $011E
 dc.w $FD78
 dc.w $6200 ; ROM 0x01BE3E: bhiw 0x81c22a
 dc.w $03EA
 dc.w $0C6E ; ROM 0x01BE42: cmpiw #30,%fp@(-646)
 dc.w $001E
 dc.w $FD7A
 dc.w $6200 ; ROM 0x01BE48: bhiw 0x81c22a
 dc.w $03E0
 dc.w $4241 ; ROM 0x01BE4C: clrw %d1
 dc.w $B249 ; ROM 0x01BE4E: cmpw %a1,%d1
 dc.w $6400 ; ROM 0x01BE50: bccw 0x81beb8
 dc.w $0066
 dc.w $7C00 ; ROM 0x01BE54: moveq #0,%d6
 dc.w $49F9 ; ROM 0x01BE56: lea 0x8ea270,%a4
 dc.w $008E
 dc.w $A270
 dc.w $367C ; ROM 0x01BE5C: moveaw #-632,%a3
 dc.w $FD88
 dc.w $347C ; ROM 0x01BE60: moveaw #-3,%a2
 dc.w $FFFD
 dc.w $B87C ; ROM 0x01BE64: cmpw #2,%d4
 dc.w $0002
 dc.w $6200 ; ROM 0x01BE68: bhiw 0x81be8e
 dc.w $0024
 dc.w $7600 ; ROM 0x01BE6C: moveq #0,%d3
 dc.w $7400 ; ROM 0x01BE6E: moveq #0,%d2
 dc.w $2079 ; ROM 0x01BE70: moveal 0x1d60e,%a0
 dc.w $0001
 dc.w $D60E
 dc.w $1610 ; ROM 0x01BE76: moveb %a0@,%d3
 dc.w $3404 ; ROM 0x01BE78: movew %d4,%d2
 dc.w $2003 ; ROM 0x01BE7A: movel %d3,%d0
 dc.w $E5A8 ; ROM 0x01BE7C: lsll %d2,%d0
 dc.w $8A80 ; ROM 0x01BE7E: orl %d0,%d5
 dc.w $52B9 ; ROM 0x01BE80: addql #1,0x1d60e
 dc.w $0001
 dc.w $D60E
 dc.w $5044 ; ROM 0x01BE86: addqw #8,%d4
 dc.w $B87C ; ROM 0x01BE88: cmpw #2,%d4
 dc.w $0002
 dc.w $63E2 ; ROM 0x01BE8C: blss 0x81be70
 dc.w $3C01 ; ROM 0x01BE8E: movew %d1,%d6
 dc.w $2006 ; ROM 0x01BE90: movel %d6,%d0
 dc.w $D080 ; ROM 0x01BE92: addl %d0,%d0
 dc.w $3034 ; ROM 0x01BE94: movew %a4@(0000000000000000,%d0:l),%d0
 dc.w $0800
 dc.w $C0BC ; ROM 0x01BE98: andl #65535,%d0
 dc.w $0000
 dc.w $FFFF
 dc.w $D080 ; ROM 0x01BE9E: addl %d0,%d0
 dc.w $41F6 ; ROM 0x01BEA0: lea %fp@(0000000000000000,%d0:l),%a0
 dc.w $0800
 dc.w $3E05 ; ROM 0x01BEA4: movew %d5,%d7
 dc.w $CE7C ; ROM 0x01BEA6: andw #7,%d7
 dc.w $0007
 dc.w $3787 ; ROM 0x01BEAA: movew %d7,%a3@(0000000000000000,%a0:l)
 dc.w $8800
 dc.w $E68D ; ROM 0x01BEAE: lsrl #3,%d5
 dc.w $D84A ; ROM 0x01BEB0: addw %a2,%d4
 dc.w $5241 ; ROM 0x01BEB2: addqw #1,%d1
 dc.w $B249 ; ROM 0x01BEB4: cmpw %a1,%d1
 dc.w $65AC ; ROM 0x01BEB6: bcss 0x81be64
 dc.w $B27C ; ROM 0x01BEB8: cmpw #18,%d1
 dc.w $0012
 dc.w $6200 ; ROM 0x01BEBC: bhiw 0x81beee
 dc.w $0030
 dc.w $7400 ; ROM 0x01BEC0: moveq #0,%d2
 dc.w $45F9 ; ROM 0x01BEC2: lea 0x8ea270,%a2
 dc.w $008E
 dc.w $A270
 dc.w $327C ; ROM 0x01BEC8: moveaw #-632,%a1
 dc.w $FD88
 dc.w $3401 ; ROM 0x01BECC: movew %d1,%d2
 dc.w $2002 ; ROM 0x01BECE: movel %d2,%d0
 dc.w $D080 ; ROM 0x01BED0: addl %d0,%d0
 dc.w $3032 ; ROM 0x01BED2: movew %a2@(0000000000000000,%d0:l),%d0
 dc.w $0800
 dc.w $C0BC ; ROM 0x01BED6: andl #65535,%d0
 dc.w $0000
 dc.w $FFFF
 dc.w $D080 ; ROM 0x01BEDC: addl %d0,%d0
 dc.w $41F6 ; ROM 0x01BEDE: lea %fp@(0000000000000000,%d0:l),%a0
 dc.w $0800
 dc.w $4271 ; ROM 0x01BEE2: clrw %a1@(0000000000000000,%a0:l)
 dc.w $8800
 dc.w $5241 ; ROM 0x01BEE6: addqw #1,%d1
 dc.w $B27C ; ROM 0x01BEE8: cmpw #18,%d1
 dc.w $0012
 dc.w $63DE ; ROM 0x01BEEC: blss 0x81becc
 dc.w $3D7C ; ROM 0x01BEEE: movew #7,%fp@(-638)
 dc.w $0007
 dc.w $FD82
 dc.w $486E ; ROM 0x01BEF4: pea %fp@(-638)
 dc.w $FD82
 dc.w $486E ; ROM 0x01BEF8: pea %fp@(-636)
 dc.w $FD84
 dc.w $42A7 ; ROM 0x01BEFC: clrl %sp@-
 dc.w $42A7 ; ROM 0x01BEFE: clrl %sp@-
 dc.w $3F3C ; ROM 0x01BF00: movew #19,%sp@-
 dc.w $0013
 dc.w $3F3C ; ROM 0x01BF04: movew #19,%sp@-
 dc.w $0013
 dc.w $243C ; ROM 0x01BF08: movel #-632,%d2
 dc.w $FFFF
 dc.w $FD88
 dc.w $4876 ; ROM 0x01BF0E: pea %fp@(0000000000000000,%d2:l)
 dc.w $2800
 dc.w $4EB9 ; ROM 0x01BF12: jsr 0x81b56a
 dc.w $0081
 dc.w $B56A
 dc.w $DEFC ; ROM 0x01BF18: addaw #24,%sp
 dc.w $0018
 dc.w $3440 ; ROM 0x01BF1C: moveaw %d0,%a2
 dc.w $4A40 ; ROM 0x01BF1E: tstw %d0
 dc.w $6700 ; ROM 0x01BF20: beqw 0x81bf3a
 dc.w $0018
 dc.w $B07C ; ROM 0x01BF24: cmpw #1,%d0
 dc.w $0001
 dc.w $6600 ; ROM 0x01BF28: bnew 0x81c1f2
 dc.w $02C8
 dc.w $2F2E ; ROM 0x01BF2C: movel %fp@(-636),%sp@-
 dc.w $FD84
 dc.w $4EB9 ; ROM 0x01BF30: jsr 0x81b964
 dc.w $0081
 dc.w $B964
 dc.w $6000 ; ROM 0x01BF36: braw 0x81c1f2
 dc.w $02BA
 dc.w $326E ; ROM 0x01BF3A: moveaw %fp@(-648),%a1
 dc.w $FD78
 dc.w $D2EE ; ROM 0x01BF3E: addaw %fp@(-646),%a1
 dc.w $FD7A
 dc.w $3A6E ; ROM 0x01BF42: moveaw %fp@(-638),%a5
 dc.w $FD82
 dc.w $200D ; ROM 0x01BF46: movel %a5,%d0
 dc.w $41F9 ; ROM 0x01BF48: lea 0x81b548,%a0
 dc.w $0081
 dc.w $B548
 dc.w $D080 ; ROM 0x01BF4E: addl %d0,%d0
 dc.w $3870 ; ROM 0x01BF50: moveaw %a0@(0000000000000000,%d0:l),%a4
 dc.w $0800
 dc.w $4243 ; ROM 0x01BF54: clrw %d3
 dc.w $3E09 ; ROM 0x01BF56: movew %a1,%d7
 dc.w $BE4A ; ROM 0x01BF58: cmpw %a2,%d7
 dc.w $6300 ; ROM 0x01BF5A: blsw 0x81c11c
 dc.w $01C0
 dc.w $2642 ; ROM 0x01BF5E: moveal %d2,%a3
 dc.w $3C3C ; ROM 0x01BF60: movew #-1,%d6
 dc.w $FFFF
 dc.w $B86E ; ROM 0x01BF64: cmpw %fp@(-638),%d4
 dc.w $FD82
 dc.w $6400 ; ROM 0x01BF68: bccw 0x81bf8e
 dc.w $0024
 dc.w $7400 ; ROM 0x01BF6C: moveq #0,%d2
 dc.w $7200 ; ROM 0x01BF6E: moveq #0,%d1
 dc.w $2079 ; ROM 0x01BF70: moveal 0x1d60e,%a0
 dc.w $0001
 dc.w $D60E
 dc.w $1410 ; ROM 0x01BF76: moveb %a0@,%d2
 dc.w $3204 ; ROM 0x01BF78: movew %d4,%d1
 dc.w $2002 ; ROM 0x01BF7A: movel %d2,%d0
 dc.w $E3A8 ; ROM 0x01BF7C: lsll %d1,%d0
 dc.w $8A80 ; ROM 0x01BF7E: orl %d0,%d5
 dc.w $52B9 ; ROM 0x01BF80: addql #1,0x1d60e
 dc.w $0001
 dc.w $D60E
 dc.w $5044 ; ROM 0x01BF86: addqw #8,%d4
 dc.w $B86E ; ROM 0x01BF88: cmpw %fp@(-638),%d4
 dc.w $FD82
 dc.w $65E2 ; ROM 0x01BF8C: bcss 0x81bf70
 dc.w $300C ; ROM 0x01BF8E: movew %a4,%d0
 dc.w $C045 ; ROM 0x01BF90: andw %d5,%d0
 dc.w $C0FC ; ROM 0x01BF92: muluw #6,%d0
 dc.w $0006
 dc.w $2040 ; ROM 0x01BF96: moveal %d0,%a0
 dc.w $D1EE ; ROM 0x01BF98: addal %fp@(-636),%a0
 dc.w $FD84
 dc.w $2D48 ; ROM 0x01BF9C: movel %a0,%fp@(-642)
 dc.w $FD7E
 dc.w $4241 ; ROM 0x01BFA0: clrw %d1
 dc.w $1228 ; ROM 0x01BFA2: moveb %a0@(1),%d1
 dc.w $0001
 dc.w $4280 ; ROM 0x01BFA6: clrl %d0
 dc.w $1001 ; ROM 0x01BFA8: moveb %d1,%d0
 dc.w $E0AD ; ROM 0x01BFAA: lsrl %d0,%d5
 dc.w $9841 ; ROM 0x01BFAC: subw %d1,%d4
 dc.w $3228 ; ROM 0x01BFAE: movew %a0@(2),%d1
 dc.w $0002
 dc.w $B27C ; ROM 0x01BFB2: cmpw #15,%d1
 dc.w $000F
 dc.w $6200 ; ROM 0x01BFB6: bhiw 0x81bfd0
 dc.w $0018
 dc.w $300A ; ROM 0x01BFBA: movew %a2,%d0
 dc.w $48C0 ; ROM 0x01BFBC: extl %d0
 dc.w $D080 ; ROM 0x01BFBE: addl %d0,%d0
 dc.w $41F6 ; ROM 0x01BFC0: lea %fp@(0000000000000000,%d0:l),%a0
 dc.w $0800
 dc.w $3601 ; ROM 0x01BFC4: movew %d1,%d3
 dc.w $3783 ; ROM 0x01BFC6: movew %d3,%a3@(0000000000000000,%a0:l)
 dc.w $8800
 dc.w $524A ; ROM 0x01BFCA: addqw #1,%a2
 dc.w $6000 ; ROM 0x01BFCC: braw 0x81c114
 dc.w $0146
 dc.w $B27C ; ROM 0x01BFD0: cmpw #16,%d1
 dc.w $0010
 dc.w $6600 ; ROM 0x01BFD4: bnew 0x81c03e
 dc.w $0068
 dc.w $B87C ; ROM 0x01BFD8: cmpw #1,%d4
 dc.w $0001
 dc.w $6200 ; ROM 0x01BFDC: bhiw 0x81c002
 dc.w $0024
 dc.w $7400 ; ROM 0x01BFE0: moveq #0,%d2
 dc.w $7200 ; ROM 0x01BFE2: moveq #0,%d1
 dc.w $2079 ; ROM 0x01BFE4: moveal 0x1d60e,%a0
 dc.w $0001
 dc.w $D60E
 dc.w $1410 ; ROM 0x01BFEA: moveb %a0@,%d2
 dc.w $3204 ; ROM 0x01BFEC: movew %d4,%d1
 dc.w $2002 ; ROM 0x01BFEE: movel %d2,%d0
 dc.w $E3A8 ; ROM 0x01BFF0: lsll %d1,%d0
 dc.w $8A80 ; ROM 0x01BFF2: orl %d0,%d5
 dc.w $52B9 ; ROM 0x01BFF4: addql #1,0x1d60e
 dc.w $0001
 dc.w $D60E
 dc.w $5044 ; ROM 0x01BFFA: addqw #8,%d4
 dc.w $B87C ; ROM 0x01BFFC: cmpw #1,%d4
 dc.w $0001
 dc.w $63E2 ; ROM 0x01C000: blss 0x81bfe4
 dc.w $3405 ; ROM 0x01C002: movew %d5,%d2
 dc.w $C47C ; ROM 0x01C004: andw #3,%d2
 dc.w $0003
 dc.w $3202 ; ROM 0x01C008: movew %d2,%d1
 dc.w $5641 ; ROM 0x01C00A: addqw #3,%d1
 dc.w $E48D ; ROM 0x01C00C: lsrl #2,%d5
 dc.w $5544 ; ROM 0x01C00E: subqw #2,%d4
 dc.w $300A ; ROM 0x01C010: movew %a2,%d0
 dc.w $D041 ; ROM 0x01C012: addw %d1,%d0
 dc.w $B049 ; ROM 0x01C014: cmpw %a1,%d0
 dc.w $6200 ; ROM 0x01C016: bhiw 0x81c22a
 dc.w $0212
 dc.w $3202 ; ROM 0x01C01A: movew %d2,%d1
 dc.w $5441 ; ROM 0x01C01C: addqw #2,%d1
 dc.w $BC41 ; ROM 0x01C01E: cmpw %d1,%d6
 dc.w $6700 ; ROM 0x01C020: beqw 0x81c114
 dc.w $00F2
 dc.w $300A ; ROM 0x01C024: movew %a2,%d0
 dc.w $48C0 ; ROM 0x01C026: extl %d0
 dc.w $D080 ; ROM 0x01C028: addl %d0,%d0
 dc.w $41F6 ; ROM 0x01C02A: lea %fp@(0000000000000000,%d0:l),%a0
 dc.w $0800
 dc.w $3783 ; ROM 0x01C02E: movew %d3,%a3@(0000000000000000,%a0:l)
 dc.w $8800
 dc.w $524A ; ROM 0x01C032: addqw #1,%a2
 dc.w $5341 ; ROM 0x01C034: subqw #1,%d1
 dc.w $BC41 ; ROM 0x01C036: cmpw %d1,%d6
 dc.w $66EA ; ROM 0x01C038: bnes 0x81c024
 dc.w $6000 ; ROM 0x01C03A: braw 0x81c114
 dc.w $00D8
 dc.w $B27C ; ROM 0x01C03E: cmpw #17,%d1
 dc.w $0011
 dc.w $6600 ; ROM 0x01C042: bnew 0x81c0ac
 dc.w $0068
 dc.w $B87C ; ROM 0x01C046: cmpw #2,%d4
 dc.w $0002
 dc.w $6200 ; ROM 0x01C04A: bhiw 0x81c070
 dc.w $0024
 dc.w $7400 ; ROM 0x01C04E: moveq #0,%d2
 dc.w $7200 ; ROM 0x01C050: moveq #0,%d1
 dc.w $2079 ; ROM 0x01C052: moveal 0x1d60e,%a0
 dc.w $0001
 dc.w $D60E
 dc.w $1410 ; ROM 0x01C058: moveb %a0@,%d2
 dc.w $3204 ; ROM 0x01C05A: movew %d4,%d1
 dc.w $2002 ; ROM 0x01C05C: movel %d2,%d0
 dc.w $E3A8 ; ROM 0x01C05E: lsll %d1,%d0
 dc.w $8A80 ; ROM 0x01C060: orl %d0,%d5
 dc.w $52B9 ; ROM 0x01C062: addql #1,0x1d60e
 dc.w $0001
 dc.w $D60E
 dc.w $5044 ; ROM 0x01C068: addqw #8,%d4
 dc.w $B87C ; ROM 0x01C06A: cmpw #2,%d4
 dc.w $0002
 dc.w $63E2 ; ROM 0x01C06E: blss 0x81c052
 dc.w $3405 ; ROM 0x01C070: movew %d5,%d2
 dc.w $C47C ; ROM 0x01C072: andw #7,%d2
 dc.w $0007
 dc.w $3202 ; ROM 0x01C076: movew %d2,%d1
 dc.w $5641 ; ROM 0x01C078: addqw #3,%d1
 dc.w $E68D ; ROM 0x01C07A: lsrl #3,%d5
 dc.w $5744 ; ROM 0x01C07C: subqw #3,%d4
 dc.w $300A ; ROM 0x01C07E: movew %a2,%d0
 dc.w $D041 ; ROM 0x01C080: addw %d1,%d0
 dc.w $B049 ; ROM 0x01C082: cmpw %a1,%d0
 dc.w $6200 ; ROM 0x01C084: bhiw 0x81c22a
 dc.w $01A4
 dc.w $3202 ; ROM 0x01C088: movew %d2,%d1
 dc.w $5441 ; ROM 0x01C08A: addqw #2,%d1
 dc.w $BC41 ; ROM 0x01C08C: cmpw %d1,%d6
 dc.w $6700 ; ROM 0x01C08E: beqw 0x81c112
 dc.w $0082
 dc.w $300A ; ROM 0x01C092: movew %a2,%d0
 dc.w $48C0 ; ROM 0x01C094: extl %d0
 dc.w $D080 ; ROM 0x01C096: addl %d0,%d0
 dc.w $41F6 ; ROM 0x01C098: lea %fp@(0000000000000000,%d0:l),%a0
 dc.w $0800
 dc.w $4273 ; ROM 0x01C09C: clrw %a3@(0000000000000000,%a0:l)
 dc.w $8800
 dc.w $524A ; ROM 0x01C0A0: addqw #1,%a2
 dc.w $5341 ; ROM 0x01C0A2: subqw #1,%d1
 dc.w $BC41 ; ROM 0x01C0A4: cmpw %d1,%d6
 dc.w $66EA ; ROM 0x01C0A6: bnes 0x81c092
 dc.w $6000 ; ROM 0x01C0A8: braw 0x81c112
 dc.w $0068
 dc.w $B87C ; ROM 0x01C0AC: cmpw #6,%d4
 dc.w $0006
 dc.w $6200 ; ROM 0x01C0B0: bhiw 0x81c0d6
 dc.w $0024
 dc.w $7400 ; ROM 0x01C0B4: moveq #0,%d2
 dc.w $7200 ; ROM 0x01C0B6: moveq #0,%d1
 dc.w $2079 ; ROM 0x01C0B8: moveal 0x1d60e,%a0
 dc.w $0001
 dc.w $D60E
 dc.w $1410 ; ROM 0x01C0BE: moveb %a0@,%d2
 dc.w $3204 ; ROM 0x01C0C0: movew %d4,%d1
 dc.w $2002 ; ROM 0x01C0C2: movel %d2,%d0
 dc.w $E3A8 ; ROM 0x01C0C4: lsll %d1,%d0
 dc.w $8A80 ; ROM 0x01C0C6: orl %d0,%d5
 dc.w $52B9 ; ROM 0x01C0C8: addql #1,0x1d60e
 dc.w $0001
 dc.w $D60E
 dc.w $5044 ; ROM 0x01C0CE: addqw #8,%d4
 dc.w $B87C ; ROM 0x01C0D0: cmpw #6,%d4
 dc.w $0006
 dc.w $63E2 ; ROM 0x01C0D4: blss 0x81c0b8
 dc.w $3405 ; ROM 0x01C0D6: movew %d5,%d2
 dc.w $C47C ; ROM 0x01C0D8: andw #127,%d2
 dc.w $007F
 dc.w $3202 ; ROM 0x01C0DC: movew %d2,%d1
 dc.w $D27C ; ROM 0x01C0DE: addw #11,%d1
 dc.w $000B
 dc.w $EE8D ; ROM 0x01C0E2: lsrl #7,%d5
 dc.w $5F44 ; ROM 0x01C0E4: subqw #7,%d4
 dc.w $300A ; ROM 0x01C0E6: movew %a2,%d0
 dc.w $D041 ; ROM 0x01C0E8: addw %d1,%d0
 dc.w $B049 ; ROM 0x01C0EA: cmpw %a1,%d0
 dc.w $6200 ; ROM 0x01C0EC: bhiw 0x81c22a
 dc.w $013C
 dc.w $3202 ; ROM 0x01C0F0: movew %d2,%d1
 dc.w $D27C ; ROM 0x01C0F2: addw #10,%d1
 dc.w $000A
 dc.w $BC41 ; ROM 0x01C0F6: cmpw %d1,%d6
 dc.w $6700 ; ROM 0x01C0F8: beqw 0x81c112
 dc.w $0018
 dc.w $300A ; ROM 0x01C0FC: movew %a2,%d0
 dc.w $48C0 ; ROM 0x01C0FE: extl %d0
 dc.w $D080 ; ROM 0x01C100: addl %d0,%d0
 dc.w $41F6 ; ROM 0x01C102: lea %fp@(0000000000000000,%d0:l),%a0
 dc.w $0800
 dc.w $4273 ; ROM 0x01C106: clrw %a3@(0000000000000000,%a0:l)
 dc.w $8800
 dc.w $524A ; ROM 0x01C10A: addqw #1,%a2
 dc.w $5341 ; ROM 0x01C10C: subqw #1,%d1
 dc.w $BC41 ; ROM 0x01C10E: cmpw %d1,%d6
 dc.w $66EA ; ROM 0x01C110: bnes 0x81c0fc
 dc.w $4243 ; ROM 0x01C112: clrw %d3
 dc.w $3E09 ; ROM 0x01C114: movew %a1,%d7
 dc.w $BE4A ; ROM 0x01C116: cmpw %a2,%d7
 dc.w $6200 ; ROM 0x01C118: bhiw 0x81bf64
 dc.w $FE4A
 dc.w $2F2E ; ROM 0x01C11C: movel %fp@(-636),%sp@-
 dc.w $FD84
 dc.w $49F9 ; ROM 0x01C120: lea 0x81b964,%a4
 dc.w $0081
 dc.w $B964
 dc.w $4E94 ; ROM 0x01C126: jsr %a4@
 dc.w $584F ; ROM 0x01C128: addqw #4,%sp
 dc.w $23C5 ; ROM 0x01C12A: movel %d5,0x1df1a
 dc.w $0001
 dc.w $DF1A
 dc.w $33C4 ; ROM 0x01C130: movew %d4,0x1df1e
 dc.w $0001
 dc.w $DF1E
 dc.w $3D79 ; ROM 0x01C136: movew 0x1df20,%fp@(-638)
 dc.w $0001
 dc.w $DF20
 dc.w $FD82
 dc.w $486E ; ROM 0x01C13E: pea %fp@(-638)
 dc.w $FD82
 dc.w $486E ; ROM 0x01C142: pea %fp@(-636)
 dc.w $FD84
 dc.w $4879 ; ROM 0x01C146: pea 0x8ea2d4
 dc.w $008E
 dc.w $A2D4
 dc.w $4879 ; ROM 0x01C14C: pea 0x8ea296
 dc.w $008E
 dc.w $A296
 dc.w $3F3C ; ROM 0x01C152: movew #257,%sp@-
 dc.w $0101
 dc.w $3F2E ; ROM 0x01C156: movew %fp@(-648),%sp@-
 dc.w $FD78
 dc.w $47EE ; ROM 0x01C15A: lea %fp@(-632),%a3
 dc.w $FD88
 dc.w $2F0B ; ROM 0x01C15E: movel %a3,%sp@-
 dc.w $243C ; ROM 0x01C160: movel #8500586,%d2
 dc.w $0081
 dc.w $B56A
 dc.w $2A42 ; ROM 0x01C166: moveal %d2,%a5
 dc.w $4E95 ; ROM 0x01C168: jsr %a5@
 dc.w $DEFC ; ROM 0x01C16A: addaw #24,%sp
 dc.w $0018
 dc.w $3440 ; ROM 0x01C16E: moveaw %d0,%a2
 dc.w $4A40 ; ROM 0x01C170: tstw %d0
 dc.w $6700 ; ROM 0x01C172: beqw 0x81c18e
 dc.w $001A
 dc.w $B07C ; ROM 0x01C176: cmpw #1,%d0
 dc.w $0001
 dc.w $6600 ; ROM 0x01C17A: bnew 0x81c1f2
 dc.w $0076
 dc.w $4879 ; ROM 0x01C17E: pea 0x81bd40
 dc.w $0081
 dc.w $BD40
 dc.w $4EB9 ; ROM 0x01C184: jsr 0x81b464
 dc.w $0081
 dc.w $B464
 dc.w $6000 ; ROM 0x01C18A: braw 0x81c1ea
 dc.w $005E
 dc.w $3D79 ; ROM 0x01C18E: movew 0x1df22,%fp@(-644)
 dc.w $0001
 dc.w $DF22
 dc.w $FD7C
 dc.w $486E ; ROM 0x01C196: pea %fp@(-644)
 dc.w $FD7C
 dc.w $486E ; ROM 0x01C19A: pea %fp@(-642)
 dc.w $FD7E
 dc.w $4879 ; ROM 0x01C19E: pea 0x8ea34e
 dc.w $008E
 dc.w $A34E
 dc.w $4879 ; ROM 0x01C1A4: pea 0x8ea312
 dc.w $008E
 dc.w $A312
 dc.w $4267 ; ROM 0x01C1AA: clrw %sp@-
 dc.w $3F2E ; ROM 0x01C1AC: movew %fp@(-646),%sp@-
 dc.w $FD7A
 dc.w $302E ; ROM 0x01C1B0: movew %fp@(-648),%d0
 dc.w $FD78
 dc.w $C0BC ; ROM 0x01C1B4: andl #1023,%d0
 dc.w $0000
 dc.w $03FF
 dc.w $D080 ; ROM 0x01C1BA: addl %d0,%d0
 dc.w $4873 ; ROM 0x01C1BC: pea %a3@(0000000000000000,%d0:l)
 dc.w $0800
 dc.w $2A42 ; ROM 0x01C1C0: moveal %d2,%a5
 dc.w $4E95 ; ROM 0x01C1C2: jsr %a5@
 dc.w $DEFC ; ROM 0x01C1C4: addaw #24,%sp
 dc.w $0018
 dc.w $3440 ; ROM 0x01C1C8: moveaw %d0,%a2
 dc.w $4A40 ; ROM 0x01C1CA: tstw %d0
 dc.w $6700 ; ROM 0x01C1CC: beqw 0x81c1f8
 dc.w $002A
 dc.w $B07C ; ROM 0x01C1D0: cmpw #1,%d0
 dc.w $0001
 dc.w $6600 ; ROM 0x01C1D4: bnew 0x81c1ec
 dc.w $0016
 dc.w $4879 ; ROM 0x01C1D8: pea 0x81bd5b
 dc.w $0081
 dc.w $BD5B
 dc.w $4EB9 ; ROM 0x01C1DE: jsr 0x81b464
 dc.w $0081
 dc.w $B464
 dc.w $2EAE ; ROM 0x01C1E4: movel %fp@(-642),%sp@
 dc.w $FD7E
 dc.w $4E94 ; ROM 0x01C1E8: jsr %a4@
 dc.w $584F ; ROM 0x01C1EA: addqw #4,%sp
 dc.w $2F2E ; ROM 0x01C1EC: movel %fp@(-636),%sp@-
 dc.w $FD84
 dc.w $4E94 ; ROM 0x01C1F0: jsr %a4@
 dc.w $300A ; ROM 0x01C1F2: movew %a2,%d0
 dc.w $6000 ; ROM 0x01C1F4: braw 0x81c22c
 dc.w $0036
 dc.w $3F2E ; ROM 0x01C1F8: movew %fp@(-644),%sp@-
 dc.w $FD7C
 dc.w $3F2E ; ROM 0x01C1FC: movew %fp@(-638),%sp@-
 dc.w $FD82
 dc.w $2F2E ; ROM 0x01C200: movel %fp@(-642),%sp@-
 dc.w $FD7E
 dc.w $2F2E ; ROM 0x01C204: movel %fp@(-636),%sp@-
 dc.w $FD84
 dc.w $4EB9 ; ROM 0x01C208: jsr 0x81b9c6
 dc.w $0081
 dc.w $B9C6
 dc.w $DEFC ; ROM 0x01C20E: addaw #12,%sp
 dc.w $000C
 dc.w $4A40 ; ROM 0x01C212: tstw %d0
 dc.w $6600 ; ROM 0x01C214: bnew 0x81c22a
 dc.w $0014
 dc.w $2F2E ; ROM 0x01C218: movel %fp@(-636),%sp@-
 dc.w $FD84
 dc.w $4E94 ; ROM 0x01C21C: jsr %a4@
 dc.w $2EAE ; ROM 0x01C21E: movel %fp@(-642),%sp@
 dc.w $FD7E
 dc.w $4E94 ; ROM 0x01C222: jsr %a4@
 dc.w $4240 ; ROM 0x01C224: clrw %d0
 dc.w $6000 ; ROM 0x01C226: braw 0x81c22c
 dc.w $0004
 dc.w $7001 ; ROM 0x01C22A: moveq #1,%d0
 dc.w $4CEE ; ROM 0x01C22C: moveml %fp@(-692),%d2-%d7/%a2-%a5
 dc.w $3CFC
 dc.w $FD4C
 dc.w $4E5E ; ROM 0x01C232: unlk %fp
 dc.w $4E75 ; ROM 0x01C234: rts
 dc.w $4E56 ; ROM 0x01C236: linkw %fp,#0
 dc.w $0000
 dc.w $48E7 ; ROM 0x01C23A: moveml %d2-%d5,%sp@-
 dc.w $3C00
 dc.w $226E ; ROM 0x01C23E: moveal %fp@(8),%a1
 dc.w $0008
 dc.w $2439 ; ROM 0x01C242: movel 0x1df1a,%d2
 dc.w $0001
 dc.w $DF1A
 dc.w $3239 ; ROM 0x01C248: movew 0x1df1e,%d1
 dc.w $0001
 dc.w $DF1E
 dc.w $6600 ; ROM 0x01C24E: bnew 0x81c270
 dc.w $0020
 dc.w $7800 ; ROM 0x01C252: moveq #0,%d4
 dc.w $7600 ; ROM 0x01C254: moveq #0,%d3
 dc.w $2079 ; ROM 0x01C256: moveal 0x1d60e,%a0
 dc.w $0001
 dc.w $D60E
 dc.w $1810 ; ROM 0x01C25C: moveb %a0@,%d4
 dc.w $3601 ; ROM 0x01C25E: movew %d1,%d3
 dc.w $2004 ; ROM 0x01C260: movel %d4,%d0
 dc.w $E7A8 ; ROM 0x01C262: lsll %d3,%d0
 dc.w $8480 ; ROM 0x01C264: orl %d0,%d2
 dc.w $52B9 ; ROM 0x01C266: addql #1,0x1d60e
 dc.w $0001
 dc.w $D60E
 dc.w $5041 ; ROM 0x01C26C: addqw #8,%d1
 dc.w $67E6 ; ROM 0x01C26E: beqs 0x81c256
 dc.w $3A02 ; ROM 0x01C270: movew %d2,%d5
 dc.w $CA7C ; ROM 0x01C272: andw #1,%d5
 dc.w $0001
 dc.w $3285 ; ROM 0x01C276: movew %d5,%a1@
 dc.w $E28A ; ROM 0x01C278: lsrl #1,%d2
 dc.w $5341 ; ROM 0x01C27A: subqw #1,%d1
 dc.w $B27C ; ROM 0x01C27C: cmpw #1,%d1
 dc.w $0001
 dc.w $6200 ; ROM 0x01C280: bhiw 0x81c2a6
 dc.w $0024
 dc.w $7800 ; ROM 0x01C284: moveq #0,%d4
 dc.w $7600 ; ROM 0x01C286: moveq #0,%d3
 dc.w $2079 ; ROM 0x01C288: moveal 0x1d60e,%a0
 dc.w $0001
 dc.w $D60E
 dc.w $1810 ; ROM 0x01C28E: moveb %a0@,%d4
 dc.w $3601 ; ROM 0x01C290: movew %d1,%d3
 dc.w $2004 ; ROM 0x01C292: movel %d4,%d0
 dc.w $E7A8 ; ROM 0x01C294: lsll %d3,%d0
 dc.w $8480 ; ROM 0x01C296: orl %d0,%d2
 dc.w $52B9 ; ROM 0x01C298: addql #1,0x1d60e
 dc.w $0001
 dc.w $D60E
 dc.w $5041 ; ROM 0x01C29E: addqw #8,%d1
 dc.w $B27C ; ROM 0x01C2A0: cmpw #1,%d1
 dc.w $0001
 dc.w $63E2 ; ROM 0x01C2A4: blss 0x81c288
 dc.w $3002 ; ROM 0x01C2A6: movew %d2,%d0
 dc.w $C07C ; ROM 0x01C2A8: andw #3,%d0
 dc.w $0003
 dc.w $E48A ; ROM 0x01C2AC: lsrl #2,%d2
 dc.w $23C2 ; ROM 0x01C2AE: movel %d2,0x1df1a
 dc.w $0001
 dc.w $DF1A
 dc.w $5541 ; ROM 0x01C2B4: subqw #2,%d1
 dc.w $33C1 ; ROM 0x01C2B6: movew %d1,0x1df1e
 dc.w $0001
 dc.w $DF1E
 dc.w $B07C ; ROM 0x01C2BC: cmpw #2,%d0
 dc.w $0002
 dc.w $6600 ; ROM 0x01C2C0: bnew 0x81c2ce
 dc.w $000C
 dc.w $4EB9 ; ROM 0x01C2C4: jsr 0x81bd76
 dc.w $0081
 dc.w $BD76
 dc.w $6000 ; ROM 0x01C2CA: braw 0x81c2f2
 dc.w $0026
 dc.w $4A40 ; ROM 0x01C2CE: tstw %d0
 dc.w $6600 ; ROM 0x01C2D0: bnew 0x81c2de
 dc.w $000C
 dc.w $4EB9 ; ROM 0x01C2D4: jsr 0x81baa8
 dc.w $0081
 dc.w $BAA8
 dc.w $6000 ; ROM 0x01C2DA: braw 0x81c2f2
 dc.w $0016
 dc.w $B07C ; ROM 0x01C2DE: cmpw #1,%d0
 dc.w $0001
 dc.w $6700 ; ROM 0x01C2E2: beqw 0x81c2ec
 dc.w $0008
 dc.w $7002 ; ROM 0x01C2E6: moveq #2,%d0
 dc.w $6000 ; ROM 0x01C2E8: braw 0x81c2f2
 dc.w $0008
 dc.w $4EB9 ; ROM 0x01C2EC: jsr 0x81bbc4
 dc.w $0081
 dc.w $BBC4
 dc.w $4CEE ; ROM 0x01C2F2: moveml %fp@(-16),%d2-%d5
 dc.w $003C
 dc.w $FFF0
 dc.w $4E5E ; ROM 0x01C2F8: unlk %fp
 dc.w $4E75 ; ROM 0x01C2FA: rts
 dc.w $4E56 ; ROM 0x01C2FC: linkw %fp,#-4
 dc.w $FFFC
 dc.w $2F02 ; ROM 0x01C300: movel %d2,%sp@-
 dc.w $720A ; ROM 0x01C302: moveq #10,%d1
 dc.w $D3B9 ; ROM 0x01C304: addl %d1,0x1d60e
 dc.w $0001
 dc.w $D60E
 dc.w $4879 ; ROM 0x01C30A: pea 0x819a68
 dc.w $0081
 dc.w $9A68
 dc.w $4EB9 ; ROM 0x01C310: jsr 0x80b79c
 dc.w $0080
 dc.w $B79C
 dc.w $584F ; ROM 0x01C316: addqw #4,%sp
 dc.w $4279 ; ROM 0x01C318: clrw 0x1df18
 dc.w $0001
 dc.w $DF18
 dc.w $4279 ; ROM 0x01C31E: clrw 0x1df1e
 dc.w $0001
 dc.w $DF1E
 dc.w $42B9 ; ROM 0x01C324: clrl 0x1df1a
 dc.w $0001
 dc.w $DF1A
 dc.w $33FC ; ROM 0x01C32A: movew #9,0x1df20
 dc.w $0009
 dc.w $0001
 dc.w $DF20
 dc.w $33FC ; ROM 0x01C332: movew #6,0x1df22
 dc.w $0006
 dc.w $0001
 dc.w $DF22
 dc.w $2F3C ; ROM 0x01C33A: movel #32768,%sp@-
 dc.w $0000
 dc.w $8000
 dc.w $4879 ; ROM 0x01C340: pea 0x1f7000
 dc.w $001F
 dc.w $7000
 dc.w $4EB9 ; ROM 0x01C346: jsr 0x81b2de
 dc.w $0081
 dc.w $B2DE
 dc.w $504F ; ROM 0x01C34C: addqw #8,%sp
 dc.w $4242 ; ROM 0x01C34E: clrw %d2
 dc.w $4279 ; ROM 0x01C350: clrw 0x1df24
 dc.w $0001
 dc.w $DF24
 dc.w $486E ; ROM 0x01C356: pea %fp@(-2)
 dc.w $FFFE
 dc.w $4EB9 ; ROM 0x01C35A: jsr 0x81c236
 dc.w $0081
 dc.w $C236
 dc.w $584F ; ROM 0x01C360: addqw #4,%sp
 dc.w $4A40 ; ROM 0x01C362: tstw %d0
 dc.w $6600 ; ROM 0x01C364: bnew 0x81c38c
 dc.w $0026
 dc.w $B479 ; ROM 0x01C368: cmpw 0x1df24,%d2
 dc.w $0001
 dc.w $DF24
 dc.w $6400 ; ROM 0x01C36E: bccw 0x81c378
 dc.w $0008
 dc.w $3439 ; ROM 0x01C372: movew 0x1df24,%d2
 dc.w $0001
 dc.w $DF24
 dc.w $4A6E ; ROM 0x01C378: tstw %fp@(-2)
 dc.w $FFFE
 dc.w $67D2 ; ROM 0x01C37C: beqs 0x81c350
 dc.w $3F39 ; ROM 0x01C37E: movew 0x1df18,%sp@-
 dc.w $0001
 dc.w $DF18
 dc.w $4EB9 ; ROM 0x01C384: jsr 0x81b998
 dc.w $0081
 dc.w $B998
 dc.w $4240 ; ROM 0x01C38A: clrw %d0
 dc.w $242E ; ROM 0x01C38C: movel %fp@(-8),%d2
 dc.w $FFF8
 dc.w $4E5E ; ROM 0x01C390: unlk %fp
 dc.w $4E75 ; ROM 0x01C392: rts
 dc.w $4E71 ; ROM 0x01C394: nop
 dc.w $4E71 ; ROM 0x01C396: nop
 dc.w $4E56 ; ROM 0x01C398: linkw %fp,#0
 dc.w $0000
 dc.w $48E7 ; ROM 0x01C39C: moveml %d2-%d4,%sp@-
 dc.w $3800
 dc.w $322E ; ROM 0x01C3A0: movew %fp@(8),%d1
 dc.w $0008
 dc.w $342E ; ROM 0x01C3A4: movew %fp@(10),%d2
 dc.w $000A
 dc.w $362E ; ROM 0x01C3A8: movew %fp@(12),%d3
 dc.w $000C
 dc.w $382E ; ROM 0x01C3AC: movew %fp@(14),%d4
 dc.w $000E
 dc.w $3001 ; ROM 0x01C3B0: movew %d1,%d0
 dc.w $E940 ; ROM 0x01C3B2: aslw #4,%d0
 dc.w $D041 ; ROM 0x01C3B4: addw %d1,%d0
 dc.w $3202 ; ROM 0x01C3B6: movew %d2,%d1
 dc.w $E341 ; ROM 0x01C3B8: aslw #1,%d1
 dc.w $D242 ; ROM 0x01C3BA: addw %d2,%d1
 dc.w $E541 ; ROM 0x01C3BC: aslw #2,%d1
 dc.w $9242 ; ROM 0x01C3BE: subw %d2,%d1
 dc.w $D041 ; ROM 0x01C3C0: addw %d1,%d0
 dc.w $3203 ; ROM 0x01C3C2: movew %d3,%d1
 dc.w $E741 ; ROM 0x01C3C4: aslw #3,%d1
 dc.w $9243 ; ROM 0x01C3C6: subw %d3,%d1
 dc.w $D041 ; ROM 0x01C3C8: addw %d1,%d0
 dc.w $3204 ; ROM 0x01C3CA: movew %d4,%d1
 dc.w $E341 ; ROM 0x01C3CC: aslw #1,%d1
 dc.w $D244 ; ROM 0x01C3CE: addw %d4,%d1
 dc.w $D041 ; ROM 0x01C3D0: addw %d1,%d0
 dc.w $C07C ; ROM 0x01C3D2: andw #31,%d0
 dc.w $001F
 dc.w $4CEE ; ROM 0x01C3D6: moveml %fp@(-12),%d2-%d4
 dc.w $001C
 dc.w $FFF4
 dc.w $4E5E ; ROM 0x01C3DC: unlk %fp
 dc.w $4E75 ; ROM 0x01C3DE: rts
 dc.w $4E56 ; ROM 0x01C3E0: linkw %fp,#0
 dc.w $0000
 dc.w $48E7 ; ROM 0x01C3E4: moveml %d2-%d6,%sp@-
 dc.w $3E00
 dc.w $322E ; ROM 0x01C3E8: movew %fp@(8),%d1
 dc.w $0008
 dc.w $363C ; ROM 0x01C3EC: movew #255,%d3
 dc.w $00FF
 dc.w $3803 ; ROM 0x01C3F0: movew %d3,%d4
 dc.w $C86E ; ROM 0x01C3F2: andw %fp@(10),%d4
 dc.w $000A
 dc.w $3403 ; ROM 0x01C3F6: movew %d3,%d2
 dc.w $C46E ; ROM 0x01C3F8: andw %fp@(12),%d2
 dc.w $000C
 dc.w $C66E ; ROM 0x01C3FC: andw %fp@(14),%d3
 dc.w $000E
 dc.w $2001 ; ROM 0x01C400: movel %d1,%d0
 dc.w $7C1D ; ROM 0x01C402: moveq #29,%d6
 dc.w $EDA0 ; ROM 0x01C404: asll %d6,%d0
 dc.w $CABC ; ROM 0x01C406: andl #536870911,%d5
 dc.w $1FFF
 dc.w $FFFF
 dc.w $8A80 ; ROM 0x01C40C: orl %d0,%d5
 dc.w $3F03 ; ROM 0x01C40E: movew %d3,%sp@-
 dc.w $3F02 ; ROM 0x01C410: movew %d2,%sp@-
 dc.w $3F04 ; ROM 0x01C412: movew %d4,%sp@-
 dc.w $3F01 ; ROM 0x01C414: movew %d1,%sp@-
 dc.w $4EB9 ; ROM 0x01C416: jsr 0x81c398
 dc.w $0081
 dc.w $C398
 dc.w $7C1F ; ROM 0x01C41C: moveq #31,%d6
 dc.w $C086 ; ROM 0x01C41E: andl %d6,%d0
 dc.w $E148 ; ROM 0x01C420: lslw #8,%d0
 dc.w $4840 ; ROM 0x01C422: swap %d0
 dc.w $4240 ; ROM 0x01C424: clrw %d0
 dc.w $CABC ; ROM 0x01C426: andl #-520093697,%d5
 dc.w $E0FF
 dc.w $FFFF
 dc.w $8A80 ; ROM 0x01C42C: orl %d0,%d5
 dc.w $4844 ; ROM 0x01C42E: swap %d4
 dc.w $4244 ; ROM 0x01C430: clrw %d4
 dc.w $CABC ; ROM 0x01C432: andl #-16711681,%d5
 dc.w $FF00
 dc.w $FFFF
 dc.w $8A84 ; ROM 0x01C438: orl %d4,%d5
 dc.w $C4BC ; ROM 0x01C43A: andl #255,%d2
 dc.w $0000
 dc.w $00FF
 dc.w $E18A ; ROM 0x01C440: lsll #8,%d2
 dc.w $CA7C ; ROM 0x01C442: andw #255,%d5
 dc.w $00FF
 dc.w $8A82 ; ROM 0x01C446: orl %d2,%d5
 dc.w $1A03 ; ROM 0x01C448: moveb %d3,%d5
 dc.w $2005 ; ROM 0x01C44A: movel %d5,%d0
 dc.w $4CEE ; ROM 0x01C44C: moveml %fp@(-20),%d2-%d6
 dc.w $007C
 dc.w $FFEC
 dc.w $4E5E ; ROM 0x01C452: unlk %fp
 dc.w $4E75 ; ROM 0x01C454: rts
 dc.w $4E56 ; ROM 0x01C456: linkw %fp,#0
 dc.w $0000
 dc.w $48E7 ; ROM 0x01C45A: moveml %d2-%d4,%sp@-
 dc.w $3800
 dc.w $222E ; ROM 0x01C45E: movel %fp@(8),%d1
 dc.w $0008
 dc.w $2601 ; ROM 0x01C462: movel %d1,%d3
 dc.w $4243 ; ROM 0x01C464: clrw %d3
 dc.w $4843 ; ROM 0x01C466: swap %d3
 dc.w $E04B ; ROM 0x01C468: lsrw #8,%d3
 dc.w $1003 ; ROM 0x01C46A: moveb %d3,%d0
 dc.w $C03C ; ROM 0x01C46C: andb #-32,%d0
 dc.w $00E0
 dc.w $6700 ; ROM 0x01C470: beqw 0x81c482
 dc.w $0010
 dc.w $2401 ; ROM 0x01C474: movel %d1,%d2
 dc.w $781D ; ROM 0x01C476: moveq #29,%d4
 dc.w $E8AA ; ROM 0x01C478: lsrl %d4,%d2
 dc.w $B47C ; ROM 0x01C47A: cmpw #5,%d2
 dc.w $0005
 dc.w $6300 ; ROM 0x01C47E: blsw 0x81c488
 dc.w $0008
 dc.w $4240 ; ROM 0x01C482: clrw %d0
 dc.w $6000 ; ROM 0x01C484: braw 0x81c4ba
 dc.w $0034
 dc.w $4267 ; ROM 0x01C488: clrw %sp@-
 dc.w $1F41 ; ROM 0x01C48A: moveb %d1,%sp@(1)
 dc.w $0001
 dc.w $2001 ; ROM 0x01C48E: movel %d1,%d0
 dc.w $E088 ; ROM 0x01C490: lsrl #8,%d0
 dc.w $4267 ; ROM 0x01C492: clrw %sp@-
 dc.w $1F40 ; ROM 0x01C494: moveb %d0,%sp@(1)
 dc.w $0001
 dc.w $2001 ; ROM 0x01C498: movel %d1,%d0
 dc.w $4240 ; ROM 0x01C49A: clrw %d0
 dc.w $4840 ; ROM 0x01C49C: swap %d0
 dc.w $4267 ; ROM 0x01C49E: clrw %sp@-
 dc.w $1F40 ; ROM 0x01C4A0: moveb %d0,%sp@(1)
 dc.w $0001
 dc.w $3F02 ; ROM 0x01C4A4: movew %d2,%sp@-
 dc.w $4EB9 ; ROM 0x01C4A6: jsr 0x81c398
 dc.w $0081
 dc.w $C398
 dc.w $3203 ; ROM 0x01C4AC: movew %d3,%d1
 dc.w $C27C ; ROM 0x01C4AE: andw #31,%d1
 dc.w $001F
 dc.w $B240 ; ROM 0x01C4B2: cmpw %d0,%d1
 dc.w $57C0 ; ROM 0x01C4B4: seq %d0
 dc.w $4880 ; ROM 0x01C4B6: extw %d0
 dc.w $4440 ; ROM 0x01C4B8: negw %d0
 dc.w $4CEE ; ROM 0x01C4BA: moveml %fp@(-12),%d2-%d4
 dc.w $001C
 dc.w $FFF4
 dc.w $4E5E ; ROM 0x01C4C0: unlk %fp
 dc.w $4E75 ; ROM 0x01C4C2: rts
 dc.w $4E56 ; ROM 0x01C4C4: linkw %fp,#0
 dc.w $0000
 dc.w $3039 ; ROM 0x01C4C8: movew 0x1df34,%d0
 dc.w $0001
 dc.w $DF34
 dc.w $5279 ; ROM 0x01C4CE: addqw #1,0x1df34
 dc.w $0001
 dc.w $DF34
 dc.w $B07C ; ROM 0x01C4D4: cmpw #3,%d0
 dc.w $0003
 dc.w $6F00 ; ROM 0x01C4D8: blew 0x81c4e8
 dc.w $000E
 dc.w $2F3C ; ROM 0x01C4DC: movel #-17965393,%sp@-
 dc.w $FEED
 dc.w $DEAF
 dc.w $4EB9 ; ROM 0x01C4E2: jsr 0x81b2d0
 dc.w $0081
 dc.w $B2D0
 dc.w $4E5E ; ROM 0x01C4E8: unlk %fp
 dc.w $4E75 ; ROM 0x01C4EA: rts
 dc.w $4E56 ; ROM 0x01C4EC: linkw %fp,#0
 dc.w $0000
 dc.w $2F03 ; ROM 0x01C4F0: movel %d3,%sp@-
 dc.w $2F02 ; ROM 0x01C4F2: movel %d2,%sp@-
 dc.w $242E ; ROM 0x01C4F4: movel %fp@(8),%d2
 dc.w $0008
 dc.w $52B9 ; ROM 0x01C4F8: addql #1,0x1df30
 dc.w $0001
 dc.w $DF30
 dc.w $2F02 ; ROM 0x01C4FE: movel %d2,%sp@-
 dc.w $4EB9 ; ROM 0x01C500: jsr 0x81c456
 dc.w $0081
 dc.w $C456
 dc.w $584F ; ROM 0x01C506: addqw #4,%sp
 dc.w $4A40 ; ROM 0x01C508: tstw %d0
 dc.w $6700 ; ROM 0x01C50A: beqw 0x81c57c
 dc.w $0070
 dc.w $2002 ; ROM 0x01C50E: movel %d2,%d0
 dc.w $761D ; ROM 0x01C510: moveq #29,%d3
 dc.w $E6A8 ; ROM 0x01C512: lsrl %d3,%d0
 dc.w $5340 ; ROM 0x01C514: subqw #1,%d0
 dc.w $B07C ; ROM 0x01C516: cmpw #4,%d0
 dc.w $0004
 dc.w $6200 ; ROM 0x01C51A: bhiw 0x81c620
 dc.w $0104
 dc.w $C0BC ; ROM 0x01C51E: andl #65535,%d0
 dc.w $0000
 dc.w $FFFF
 dc.w $D080 ; ROM 0x01C524: addl %d0,%d0
 dc.w $303B ; ROM 0x01C526: movew %pc@(0x81c52e,%d0:l),%d0
 dc.w $0806
 dc.w $4EFB ; ROM 0x01C52A: jmp %pc@(0x81c52e,%d0:w)
 dc.w $0002
 dc.w $000A ; ROM 0x01C52E: 012
 dc.w $0042 ; ROM 0x01C530: oriw #172,%d2
 dc.w $00AC
 dc.w $00BE ; ROM 0x01C534: oril #14950402,%d6
 dc.w $00E4
 dc.w $2002
 dc.w $4240 ; ROM 0x01C53A: clrw %d0
 dc.w $4840 ; ROM 0x01C53C: swap %d0
 dc.w $E140 ; ROM 0x01C53E: aslw #8,%d0
 dc.w $2202 ; ROM 0x01C540: movel %d2,%d1
 dc.w $E089 ; ROM 0x01C542: lsrl #8,%d1
 dc.w $C27C ; ROM 0x01C544: andw #255,%d1
 dc.w $00FF
 dc.w $8041 ; ROM 0x01C548: orw %d1,%d0
 dc.w $33C0 ; ROM 0x01C54A: movew %d0,0x1df36
 dc.w $0001
 dc.w $DF36
 dc.w $2002 ; ROM 0x01C550: movel %d2,%d0
 dc.w $E180 ; ROM 0x01C552: asll #8,%d0
 dc.w $C07C ; ROM 0x01C554: andw #-256,%d0
 dc.w $FF00
 dc.w $33C0 ; ROM 0x01C558: movew %d0,0x1df38
 dc.w $0001
 dc.w $DF38
 dc.w $4279 ; ROM 0x01C55E: clrw 0x1df3a
 dc.w $0001
 dc.w $DF3A
 dc.w $33FC ; ROM 0x01C564: movew #2,0x1df3c
 dc.w $0002
 dc.w $0001
 dc.w $DF3C
 dc.w $6000 ; ROM 0x01C56C: braw 0x81c620
 dc.w $00B2
 dc.w $0C79 ; ROM 0x01C570: cmpiw #2,0x1df3c
 dc.w $0002
 dc.w $0001
 dc.w $DF3C
 dc.w $6700 ; ROM 0x01C578: beqw 0x81c58e
 dc.w $0014
 dc.w $52B9 ; ROM 0x01C57C: addql #1,0x1df2c
 dc.w $0001
 dc.w $DF2C
 dc.w $2F02 ; ROM 0x01C582: movel %d2,%sp@-
 dc.w $4EB9 ; ROM 0x01C584: jsr 0x81c4c4
 dc.w $0081
 dc.w $C4C4
 dc.w $6000 ; ROM 0x01C58A: braw 0x81c626
 dc.w $009A
 dc.w $2002 ; ROM 0x01C58E: movel %d2,%d0
 dc.w $4240 ; ROM 0x01C590: clrw %d0
 dc.w $4840 ; ROM 0x01C592: swap %d0
 dc.w $C07C ; ROM 0x01C594: andw #255,%d0
 dc.w $00FF
 dc.w $8079 ; ROM 0x01C598: orw 0x1df38,%d0
 dc.w $0001
 dc.w $DF38
 dc.w $33C0 ; ROM 0x01C59E: movew %d0,0x1df38
 dc.w $0001
 dc.w $DF38
 dc.w $3202 ; ROM 0x01C5A4: movew %d2,%d1
 dc.w $33C1 ; ROM 0x01C5A6: movew %d1,0x1df3a
 dc.w $0001
 dc.w $DF3A
 dc.w $3F01 ; ROM 0x01C5AC: movew %d1,%sp@-
 dc.w $3F00 ; ROM 0x01C5AE: movew %d0,%sp@-
 dc.w $3F39 ; ROM 0x01C5B0: movew 0x1df36,%sp@-
 dc.w $0001
 dc.w $DF36
 dc.w $4EB9 ; ROM 0x01C5B6: jsr 0x809ee8
 dc.w $0080
 dc.w $9EE8
 dc.w $33FC ; ROM 0x01C5BC: movew #1,0x1df3c
 dc.w $0001
 dc.w $0001
 dc.w $DF3C
 dc.w $4279 ; ROM 0x01C5C4: clrw 0x1df3a
 dc.w $0001
 dc.w $DF3A
 dc.w $4279 ; ROM 0x01C5CA: clrw 0x1df38
 dc.w $0001
 dc.w $DF38
 dc.w $4279 ; ROM 0x01C5D0: clrw 0x1df36
 dc.w $0001
 dc.w $DF36
 dc.w $6000 ; ROM 0x01C5D6: braw 0x81c620
 dc.w $0048
 dc.w $C4BC ; ROM 0x01C5DA: andl #16777215,%d2
 dc.w $00FF
 dc.w $FFFF
 dc.w $2F02 ; ROM 0x01C5E0: movel %d2,%sp@-
 dc.w $4EB9 ; ROM 0x01C5E2: jsr 0x809f28
 dc.w $0080
 dc.w $9F28
 dc.w $6000 ; ROM 0x01C5E8: braw 0x81c620
 dc.w $0036
 dc.w $4267 ; ROM 0x01C5EC: clrw %sp@-
 dc.w $1F42 ; ROM 0x01C5EE: moveb %d2,%sp@(1)
 dc.w $0001
 dc.w $2002 ; ROM 0x01C5F2: movel %d2,%d0
 dc.w $E088 ; ROM 0x01C5F4: lsrl #8,%d0
 dc.w $4267 ; ROM 0x01C5F6: clrw %sp@-
 dc.w $1F40 ; ROM 0x01C5F8: moveb %d0,%sp@(1)
 dc.w $0001
 dc.w $2002 ; ROM 0x01C5FC: movel %d2,%d0
 dc.w $4240 ; ROM 0x01C5FE: clrw %d0
 dc.w $4840 ; ROM 0x01C600: swap %d0
 dc.w $4267 ; ROM 0x01C602: clrw %sp@-
 dc.w $1F40 ; ROM 0x01C604: moveb %d0,%sp@(1)
 dc.w $0001
 dc.w $4EB9 ; ROM 0x01C608: jsr 0x809f3e
 dc.w $0080
 dc.w $9F3E
 dc.w $6000 ; ROM 0x01C60E: braw 0x81c620
 dc.w $0010
 dc.w $C4BC ; ROM 0x01C612: andl #16777215,%d2
 dc.w $00FF
 dc.w $FFFF
 dc.w $2F02 ; ROM 0x01C618: movel %d2,%sp@-
 dc.w $4EB9 ; ROM 0x01C61A: jsr 0x80a006
 dc.w $0080
 dc.w $A006
 dc.w $4279 ; ROM 0x01C620: clrw 0x1df34
 dc.w $0001
 dc.w $DF34
 dc.w $242E ; ROM 0x01C626: movel %fp@(-8),%d2
 dc.w $FFF8
 dc.w $262E ; ROM 0x01C62A: movel %fp@(-4),%d3
 dc.w $FFFC
 dc.w $4E5E ; ROM 0x01C62E: unlk %fp
 dc.w $4E75 ; ROM 0x01C630: rts
 dc.w $4E56 ; ROM 0x01C632: linkw %fp,#-4
 dc.w $FFFC
 dc.w $48E7 ; ROM 0x01C636: moveml %d2-%d6,%sp@-
 dc.w $3E00
 dc.w $4EB9 ; ROM 0x01C63A: jsr 0x809f86
 dc.w $0080
 dc.w $9F86
 dc.w $2200 ; ROM 0x01C640: movel %d0,%d1
 dc.w $3039 ; ROM 0x01C642: movew 0x1df3e,%d0
 dc.w $0001
 dc.w $DF3E
 dc.w $5340 ; ROM 0x01C648: subqw #1,%d0
 dc.w $B07C ; ROM 0x01C64A: cmpw #4,%d0
 dc.w $0004
 dc.w $6200 ; ROM 0x01C64E: bhiw 0x81c6ac
 dc.w $005C
 dc.w $C0BC ; ROM 0x01C652: andl #65535,%d0
 dc.w $0000
 dc.w $FFFF
 dc.w $D080 ; ROM 0x01C658: addl %d0,%d0
 dc.w $303B ; ROM 0x01C65A: movew %pc@(0x81c662,%d0:l),%d0
 dc.w $0806
 dc.w $4EFB ; ROM 0x01C65E: jmp %pc@(0x81c662,%d0:w)
 dc.w $0002
 dc.w $000A ; ROM 0x01C662: 012
 dc.w $0010 ; ROM 0x01C664: orib #68,%a0@
 dc.w $0044
 dc.w $003E ; ROM 0x01C668: 076
 dc.w $003E ; ROM 0x01C66A: 076
 dc.w $7402 ; ROM 0x01C66C: moveq #2,%d2
 dc.w $6000 ; ROM 0x01C66E: braw 0x81c6ae
 dc.w $003E
 dc.w $B2B9 ; ROM 0x01C672: cmpl 0x1df4c,%d1
 dc.w $0001
 dc.w $DF4C
 dc.w $6600 ; ROM 0x01C678: bnew 0x81c68e
 dc.w $0014
 dc.w $5279 ; ROM 0x01C67C: addqw #1,0x1df50
 dc.w $0001
 dc.w $DF50
 dc.w $0C79 ; ROM 0x01C682: cmpiw #4,0x1df50
 dc.w $0004
 dc.w $0001
 dc.w $DF50
 dc.w $6300 ; ROM 0x01C68A: blsw 0x81c69a
 dc.w $000E
 dc.w $7403 ; ROM 0x01C68E: moveq #3,%d2
 dc.w $4279 ; ROM 0x01C690: clrw 0x1df50
 dc.w $0001
 dc.w $DF50
 dc.w $6000 ; ROM 0x01C696: braw 0x81c6ae
 dc.w $0016
 dc.w $7404 ; ROM 0x01C69A: moveq #4,%d2
 dc.w $6000 ; ROM 0x01C69C: braw 0x81c6ae
 dc.w $0010
 dc.w $7401 ; ROM 0x01C6A0: moveq #1,%d2
 dc.w $6000 ; ROM 0x01C6A2: braw 0x81c6ae
 dc.w $000A
 dc.w $7405 ; ROM 0x01C6A6: moveq #5,%d2
 dc.w $6000 ; ROM 0x01C6A8: braw 0x81c6ae
 dc.w $0004
 dc.w $7403 ; ROM 0x01C6AC: moveq #3,%d2
 dc.w $4AB9 ; ROM 0x01C6AE: tstl 0x1df4c
 dc.w $0001
 dc.w $DF4C
 dc.w $6600 ; ROM 0x01C6B4: bnew 0x81c6ba
 dc.w $0004
 dc.w $7403 ; ROM 0x01C6B8: moveq #3,%d2
 dc.w $3002 ; ROM 0x01C6BA: movew %d2,%d0
 dc.w $5340 ; ROM 0x01C6BC: subqw #1,%d0
 dc.w $B07C ; ROM 0x01C6BE: cmpw #4,%d0
 dc.w $0004
 dc.w $6200 ; ROM 0x01C6C2: bhiw 0x81c7ae
 dc.w $00EA
 dc.w $C0BC ; ROM 0x01C6C6: andl #65535,%d0
 dc.w $0000
 dc.w $FFFF
 dc.w $D080 ; ROM 0x01C6CC: addl %d0,%d0
 dc.w $303B ; ROM 0x01C6CE: movew %pc@(0x81c6d6,%d0:l),%d0
 dc.w $0806
 dc.w $4EFB ; ROM 0x01C6D2: jmp %pc@(0x81c6d6,%d0:w)
 dc.w $0002
 dc.w $000A ; ROM 0x01C6D6: 012
 dc.w $0056 ; ROM 0x01C6D8: oriw #158,%fp@
 dc.w $009E
 dc.w $0082 ; ROM 0x01C6DC: oril #12209849,%d2
 dc.w $00BA
 dc.w $4EB9
 dc.w $0080 ; ROM 0x01C6E2: oril #-1617813440,%d0
 dc.w $9F92
 dc.w $2040
 dc.w $23D0 ; ROM 0x01C6E8: movel %a0@,0x1df40
 dc.w $0001
 dc.w $DF40
 dc.w $23E8 ; ROM 0x01C6EE: movel %a0@(4),0x1df44
 dc.w $0004
 dc.w $0001
 dc.w $DF44
 dc.w $23E8 ; ROM 0x01C6F6: movel %a0@(8),0x1df48
 dc.w $0008
 dc.w $0001
 dc.w $DF48
 dc.w $2079 ; ROM 0x01C6FE: moveal 0x1df4c,%a0
 dc.w $0001
 dc.w $DF4C
 dc.w $2039 ; ROM 0x01C704: movel 0x1df40,%d0
 dc.w $0001
 dc.w $DF40
 dc.w $90A8 ; ROM 0x01C70A: subl %a0@(16),%d0
 dc.w $0010
 dc.w $7C0C ; ROM 0x01C70E: moveq #12,%d6
 dc.w $ECA0 ; ROM 0x01C710: asrl %d6,%d0
 dc.w $2239 ; ROM 0x01C712: movel 0x1df44,%d1
 dc.w $0001
 dc.w $DF44
 dc.w $92A8 ; ROM 0x01C718: subl %a0@(20),%d1
 dc.w $0014
 dc.w $ECA1 ; ROM 0x01C71C: asrl %d6,%d1
 dc.w $3A00 ; ROM 0x01C71E: movew %d0,%d5
 dc.w $E045 ; ROM 0x01C720: asrw #8,%d5
 dc.w $1800 ; ROM 0x01C722: moveb %d0,%d4
 dc.w $3601 ; ROM 0x01C724: movew %d1,%d3
 dc.w $E043 ; ROM 0x01C726: asrw #8,%d3
 dc.w $6000 ; ROM 0x01C728: braw 0x81c7ae
 dc.w $0084
 dc.w $2079 ; ROM 0x01C72C: moveal 0x1df4c,%a0
 dc.w $0001
 dc.w $DF4C
 dc.w $2239 ; ROM 0x01C732: movel 0x1df44,%d1
 dc.w $0001
 dc.w $DF44
 dc.w $92A8 ; ROM 0x01C738: subl %a0@(20),%d1
 dc.w $0014
 dc.w $2039 ; ROM 0x01C73C: movel 0x1df48,%d0
 dc.w $0001
 dc.w $DF48
 dc.w $90A8 ; ROM 0x01C742: subl %a0@(24),%d0
 dc.w $0018
 dc.w $7C0C ; ROM 0x01C746: moveq #12,%d6
 dc.w $ECA0 ; ROM 0x01C748: asrl %d6,%d0
 dc.w $2A01 ; ROM 0x01C74A: movel %d1,%d5
 dc.w $ECA5 ; ROM 0x01C74C: asrl %d6,%d5
 dc.w $3800 ; ROM 0x01C74E: movew %d0,%d4
 dc.w $E044 ; ROM 0x01C750: asrw #8,%d4
 dc.w $1600 ; ROM 0x01C752: moveb %d0,%d3
 dc.w $6000 ; ROM 0x01C754: braw 0x81c7ae
 dc.w $0058
 dc.w $486E ; ROM 0x01C758: pea %fp@(-4)
 dc.w $FFFC
 dc.w $4EB9 ; ROM 0x01C75C: jsr 0x809fa0
 dc.w $0080
 dc.w $9FA0
 dc.w $584F ; ROM 0x01C762: addqw #4,%sp
 dc.w $1A2E ; ROM 0x01C764: moveb %fp@(-4),%d5
 dc.w $FFFC
 dc.w $182E ; ROM 0x01C768: moveb %fp@(-3),%d4
 dc.w $FFFD
 dc.w $162E ; ROM 0x01C76C: moveb %fp@(-2),%d3
 dc.w $FFFE
 dc.w $6000 ; ROM 0x01C770: braw 0x81c7ae
 dc.w $003C
 dc.w $4279 ; ROM 0x01C774: clrw 0x1df50
 dc.w $0001
 dc.w $DF50
 dc.w $23C1 ; ROM 0x01C77A: movel %d1,0x1df4c
 dc.w $0001
 dc.w $DF4C
 dc.w $2A01 ; ROM 0x01C780: movel %d1,%d5
 dc.w $4245 ; ROM 0x01C782: clrw %d5
 dc.w $4845 ; ROM 0x01C784: swap %d5
 dc.w $2801 ; ROM 0x01C786: movel %d1,%d4
 dc.w $E08C ; ROM 0x01C788: lsrl #8,%d4
 dc.w $1601 ; ROM 0x01C78A: moveb %d1,%d3
 dc.w $6000 ; ROM 0x01C78C: braw 0x81c7ae
 dc.w $0020
 dc.w $4EB9 ; ROM 0x01C790: jsr 0x809fc4
 dc.w $0080
 dc.w $9FC4
 dc.w $23C0 ; ROM 0x01C796: movel %d0,0x1df54
 dc.w $0001
 dc.w $DF54
 dc.w $1A39 ; ROM 0x01C79C: moveb 0x1df55,%d5
 dc.w $0001
 dc.w $DF55
 dc.w $1839 ; ROM 0x01C7A2: moveb 0x1df56,%d4
 dc.w $0001
 dc.w $DF56
 dc.w $1639 ; ROM 0x01C7A8: moveb 0x1df57,%d3
 dc.w $0001
 dc.w $DF57
 dc.w $33C2 ; ROM 0x01C7AE: movew %d2,0x1df3e
 dc.w $0001
 dc.w $DF3E
 dc.w $52B9 ; ROM 0x01C7B4: addql #1,0x1df28
 dc.w $0001
 dc.w $DF28
 dc.w $4267 ; ROM 0x01C7BA: clrw %sp@-
 dc.w $1F43 ; ROM 0x01C7BC: moveb %d3,%sp@(1)
 dc.w $0001
 dc.w $4267 ; ROM 0x01C7C0: clrw %sp@-
 dc.w $1F44 ; ROM 0x01C7C2: moveb %d4,%sp@(1)
 dc.w $0001
 dc.w $4267 ; ROM 0x01C7C6: clrw %sp@-
 dc.w $1F45 ; ROM 0x01C7C8: moveb %d5,%sp@(1)
 dc.w $0001
 dc.w $3F02 ; ROM 0x01C7CC: movew %d2,%sp@-
 dc.w $4EB9 ; ROM 0x01C7CE: jsr 0x81c3e0
 dc.w $0081
 dc.w $C3E0
 dc.w $4CEE ; ROM 0x01C7D4: moveml %fp@(-24),%d2-%d6
 dc.w $007C
 dc.w $FFE8
 dc.w $4E5E ; ROM 0x01C7DA: unlk %fp
 dc.w $4E75 ; ROM 0x01C7DC: rts
 dc.w $4E56 ; ROM 0x01C7DE: linkw %fp,#0
 dc.w $0000
 dc.w $33FC ; ROM 0x01C7E2: movew #-1,0x1df3e
 dc.w $FFFF
 dc.w $0001
 dc.w $DF3E
 dc.w $42B9 ; ROM 0x01C7EA: clrl 0x1df4c
 dc.w $0001
 dc.w $DF4C
 dc.w $4279 ; ROM 0x01C7F0: clrw 0x1df34
 dc.w $0001
 dc.w $DF34
 dc.w $42B9 ; ROM 0x01C7F6: clrl 0x1df2c
 dc.w $0001
 dc.w $DF2C
 dc.w $42B9 ; ROM 0x01C7FC: clrl 0x1df30
 dc.w $0001
 dc.w $DF30
 dc.w $42B9 ; ROM 0x01C802: clrl 0x1df28
 dc.w $0001
 dc.w $DF28
 dc.w $33FC ; ROM 0x01C808: movew #1,0x1df52
 dc.w $0001
 dc.w $0001
 dc.w $DF52
 dc.w $4E5E ; ROM 0x01C810: unlk %fp
 dc.w $4E75 ; ROM 0x01C812: rts
 dc.w $4E71 ; ROM 0x01C814: nop
 dc.w $4E71 ; ROM 0x01C816: nop
 dc.w $6200 ; ROM 0x01C818: bhiw 0x81c83e
 dc.w $0024
 dc.w $7400 ; ROM 0x01C81C: moveq #0,%d2
 dc.w $7200 ; ROM 0x01C81E: moveq #0,%d1
 dc.w $2079 ; ROM 0x01C820: moveal 0x1ce0e,%a0
 dc.w $0001
 dc.w $CE0E
 dc.w $1410 ; ROM 0x01C826: moveb %a0@,%d2
 dc.w $3204 ; ROM 0x01C828: movew %d4,%d1
 dc.w $2002 ; ROM 0x01C82A: movel %d2,%d0
 dc.w $E3A8 ; ROM 0x01C82C: lsll %d1,%d0
 dc.w $8A80 ; ROM 0x01C82E: orl %d0,%d5
 dc.w $52B9 ; ROM 0x01C830: addql #1,0x1ce0e
 dc.w $0001
 dc.w $CE0E
 dc.w $5044 ; ROM 0x01C836: addqw #8,%d4
 dc.w $B87C ; ROM 0x01C838: cmpw #6,%d4
 dc.w $0006
 dc.w $63E2 ; ROM 0x01C83C: blss 0x81c820
 dc.w $3405 ; ROM 0x01C83E: movew %d5,%d2
 dc.w $C47C ; ROM 0x01C840: andw #127,%d2
 dc.w $007F
 dc.w $3202 ; ROM 0x01C844: movew %d2,%d1
 dc.w $D27C ; ROM 0x01C846: addw #11,%d1
 dc.w $000B
 dc.w $EE8D ; ROM 0x01C84A: lsrl #7,%d5
 dc.w $5F44 ; ROM 0x01C84C: subqw #7,%d4
 dc.w $300A ; ROM 0x01C84E: movew %a2,%d0
 dc.w $D041 ; ROM 0x01C850: addw %d1,%d0
 dc.w $B049 ; ROM 0x01C852: cmpw %a1,%d0
 dc.w $6200 ; ROM 0x01C854: bhiw 0x81c992
 dc.w $013C
 dc.w $3202 ; ROM 0x01C858: movew %d2,%d1
 dc.w $D27C ; ROM 0x01C85A: addw #10,%d1
 dc.w $000A
 dc.w $BC41 ; ROM 0x01C85E: cmpw %d1,%d6
 dc.w $6700 ; ROM 0x01C860: beqw 0x81c87a
 dc.w $0018
 dc.w $300A ; ROM 0x01C864: movew %a2,%d0
 dc.w $48C0 ; ROM 0x01C866: extl %d0
 dc.w $D080 ; ROM 0x01C868: addl %d0,%d0
 dc.w $41F6 ; ROM 0x01C86A: lea %fp@(0000000000000000,%d0:l),%a0
 dc.w $0800
 dc.w $4273 ; ROM 0x01C86E: clrw %a3@(0000000000000000,%a0:l)
 dc.w $8800
 dc.w $524A ; ROM 0x01C872: addqw #1,%a2
 dc.w $5341 ; ROM 0x01C874: subqw #1,%d1
 dc.w $BC41 ; ROM 0x01C876: cmpw %d1,%d6
 dc.w $66EA ; ROM 0x01C878: bnes 0x81c864
 dc.w $4243 ; ROM 0x01C87A: clrw %d3
 dc.w $3E09 ; ROM 0x01C87C: movew %a1,%d7
 dc.w $BE4A ; ROM 0x01C87E: cmpw %a2,%d7
 dc.w $6200 ; ROM 0x01C880: bhiw 0x81c6cc
 dc.w $FE4A
 dc.w $2F2E ; ROM 0x01C884: movel %fp@(-636),%sp@-
 dc.w $FD84
 dc.w $49F9 ; ROM 0x01C888: lea 0x81c0cc,%a4
 dc.w $0081
 dc.w $C0CC
 dc.w $4E94 ; ROM 0x01C88E: jsr %a4@
 dc.w $584F ; ROM 0x01C890: addqw #4,%sp
 dc.w $23C5 ; ROM 0x01C892: movel %d5,0x1d71a
 dc.w $0001
 dc.w $D71A
 dc.w $33C4 ; ROM 0x01C898: movew %d4,0x1d71e
 dc.w $0001
 dc.w $D71E
 dc.w $3D79 ; ROM 0x01C89E: movew 0x1d720,%fp@(-638)
 dc.w $0001
 dc.w $D720
 dc.w $FD82
 dc.w $486E ; ROM 0x01C8A6: pea %fp@(-638)
 dc.w $FD82
 dc.w $486E ; ROM 0x01C8AA: pea %fp@(-636)
 dc.w $FD84
 dc.w $4879 ; ROM 0x01C8AE: pea 0x8ea2d4
 dc.w $008E
 dc.w $A2D4
 dc.w $4879 ; ROM 0x01C8B4: pea 0x8ea296
 dc.w $008E
 dc.w $A296
 dc.w $3F3C ; ROM 0x01C8BA: movew #257,%sp@-
 dc.w $0101
 dc.w $3F2E ; ROM 0x01C8BE: movew %fp@(-648),%sp@-
 dc.w $FD78
 dc.w $47EE ; ROM 0x01C8C2: lea %fp@(-632),%a3
 dc.w $FD88
 dc.w $2F0B ; ROM 0x01C8C6: movel %a3,%sp@-
 dc.w $243C ; ROM 0x01C8C8: movel #8502482,%d2
 dc.w $0081
 dc.w $BCD2
 dc.w $2A42 ; ROM 0x01C8CE: moveal %d2,%a5
 dc.w $4E95 ; ROM 0x01C8D0: jsr %a5@
 dc.w $DEFC ; ROM 0x01C8D2: addaw #24,%sp
 dc.w $0018
 dc.w $3440 ; ROM 0x01C8D6: moveaw %d0,%a2
 dc.w $4A40 ; ROM 0x01C8D8: tstw %d0
 dc.w $6700 ; ROM 0x01C8DA: beqw 0x81c8f6
 dc.w $001A
 dc.w $B07C ; ROM 0x01C8DE: cmpw #1,%d0
 dc.w $0001
 dc.w $6600 ; ROM 0x01C8E2: bnew 0x81c95a
 dc.w $0076
 dc.w $4879 ; ROM 0x01C8E6: pea 0x81c4a8
 dc.w $0081
 dc.w $C4A8
 dc.w $4EB9 ; ROM 0x01C8EC: jsr 0x81bbcc
 dc.w $0081
 dc.w $BBCC
 dc.w $6000 ; ROM 0x01C8F2: braw 0x81c952
 dc.w $005E
 dc.w $3D79 ; ROM 0x01C8F6: movew 0x1d722,%fp@(-644)
 dc.w $0001
 dc.w $D722
 dc.w $FD7C
 dc.w $486E ; ROM 0x01C8FE: pea %fp@(-644)
 dc.w $FD7C
 dc.w $486E ; ROM 0x01C902: pea %fp@(-642)
 dc.w $FD7E
 dc.w $4879 ; ROM 0x01C906: pea 0x8ea34e
 dc.w $008E
 dc.w $A34E
 dc.w $4879 ; ROM 0x01C90C: pea 0x8ea312
 dc.w $008E
 dc.w $A312
 dc.w $4267 ; ROM 0x01C912: clrw %sp@-
 dc.w $3F2E ; ROM 0x01C914: movew %fp@(-646),%sp@-
 dc.w $FD7A
 dc.w $302E ; ROM 0x01C918: movew %fp@(-648),%d0
 dc.w $FD78
 dc.w $C0BC ; ROM 0x01C91C: andl #1023,%d0
 dc.w $0000
 dc.w $03FF
 dc.w $D080 ; ROM 0x01C922: addl %d0,%d0
 dc.w $4873 ; ROM 0x01C924: pea %a3@(0000000000000000,%d0:l)
 dc.w $0800
 dc.w $2A42 ; ROM 0x01C928: moveal %d2,%a5
 dc.w $4E95 ; ROM 0x01C92A: jsr %a5@
 dc.w $DEFC ; ROM 0x01C92C: addaw #24,%sp
 dc.w $0018
 dc.w $3440 ; ROM 0x01C930: moveaw %d0,%a2
 dc.w $4A40 ; ROM 0x01C932: tstw %d0
 dc.w $6700 ; ROM 0x01C934: beqw 0x81c960
 dc.w $002A
 dc.w $B07C ; ROM 0x01C938: cmpw #1,%d0
 dc.w $0001
 dc.w $6600 ; ROM 0x01C93C: bnew 0x81c954
 dc.w $0016
 dc.w $4879 ; ROM 0x01C940: pea 0x81c4c3
 dc.w $0081
 dc.w $C4C3
 dc.w $4EB9 ; ROM 0x01C946: jsr 0x81bbcc
 dc.w $0081
 dc.w $BBCC
 dc.w $2EAE ; ROM 0x01C94C: movel %fp@(-642),%sp@
 dc.w $FD7E
 dc.w $4E94 ; ROM 0x01C950: jsr %a4@
 dc.w $584F ; ROM 0x01C952: addqw #4,%sp
 dc.w $2F2E ; ROM 0x01C954: movel %fp@(-636),%sp@-
 dc.w $FD84
 dc.w $4E94 ; ROM 0x01C958: jsr %a4@
 dc.w $300A ; ROM 0x01C95A: movew %a2,%d0
 dc.w $6000 ; ROM 0x01C95C: braw 0x81c994
 dc.w $0036
 dc.w $3F2E ; ROM 0x01C960: movew %fp@(-644),%sp@-
 dc.w $FD7C
 dc.w $3F2E ; ROM 0x01C964: movew %fp@(-638),%sp@-
 dc.w $FD82
 dc.w $2F2E ; ROM 0x01C968: movel %fp@(-642),%sp@-
 dc.w $FD7E
 dc.w $2F2E ; ROM 0x01C96C: movel %fp@(-636),%sp@-
 dc.w $FD84
 dc.w $4EB9 ; ROM 0x01C970: jsr 0x81c12e
 dc.w $0081
 dc.w $C12E
 dc.w $DEFC ; ROM 0x01C976: addaw #12,%sp
 dc.w $000C
 dc.w $4A40 ; ROM 0x01C97A: tstw %d0
 dc.w $6600 ; ROM 0x01C97C: bnew 0x81c992
 dc.w $0014
 dc.w $2F2E ; ROM 0x01C980: movel %fp@(-636),%sp@-
 dc.w $FD84
 dc.w $4E94 ; ROM 0x01C984: jsr %a4@
 dc.w $2EAE ; ROM 0x01C986: movel %fp@(-642),%sp@
 dc.w $FD7E
 dc.w $4E94 ; ROM 0x01C98A: jsr %a4@
 dc.w $4240 ; ROM 0x01C98C: clrw %d0
 dc.w $6000 ; ROM 0x01C98E: braw 0x81c994
 dc.w $0004
 dc.w $7001 ; ROM 0x01C992: moveq #1,%d0
 dc.w $4CEE ; ROM 0x01C994: moveml %fp@(-692),%d2-%d7/%a2-%a5
 dc.w $3CFC
 dc.w $FD4C
 dc.w $4E5E ; ROM 0x01C99A: unlk %fp
 dc.w $4E75 ; ROM 0x01C99C: rts
 dc.w $4E56 ; ROM 0x01C99E: linkw %fp,#0
 dc.w $0000
 dc.w $48E7 ; ROM 0x01C9A2: moveml %d2-%d5,%sp@-
 dc.w $3C00
 dc.w $226E ; ROM 0x01C9A6: moveal %fp@(8),%a1
 dc.w $0008
 dc.w $2439 ; ROM 0x01C9AA: movel 0x1d71a,%d2
 dc.w $0001
 dc.w $D71A
 dc.w $3239 ; ROM 0x01C9B0: movew 0x1d71e,%d1
 dc.w $0001
 dc.w $D71E
 dc.w $6600 ; ROM 0x01C9B6: bnew 0x81c9d8
 dc.w $0020
 dc.w $7800 ; ROM 0x01C9BA: moveq #0,%d4
 dc.w $7600 ; ROM 0x01C9BC: moveq #0,%d3
 dc.w $2079 ; ROM 0x01C9BE: moveal 0x1ce0e,%a0
 dc.w $0001
 dc.w $CE0E
 dc.w $1810 ; ROM 0x01C9C4: moveb %a0@,%d4
 dc.w $3601 ; ROM 0x01C9C6: movew %d1,%d3
 dc.w $2004 ; ROM 0x01C9C8: movel %d4,%d0
 dc.w $E7A8 ; ROM 0x01C9CA: lsll %d3,%d0
 dc.w $8480 ; ROM 0x01C9CC: orl %d0,%d2
 dc.w $52B9 ; ROM 0x01C9CE: addql #1,0x1ce0e
 dc.w $0001
 dc.w $CE0E
 dc.w $5041 ; ROM 0x01C9D4: addqw #8,%d1
 dc.w $67E6 ; ROM 0x01C9D6: beqs 0x81c9be
 dc.w $3A02 ; ROM 0x01C9D8: movew %d2,%d5
 dc.w $CA7C ; ROM 0x01C9DA: andw #1,%d5
 dc.w $0001
 dc.w $3285 ; ROM 0x01C9DE: movew %d5,%a1@
 dc.w $E28A ; ROM 0x01C9E0: lsrl #1,%d2
 dc.w $5341 ; ROM 0x01C9E2: subqw #1,%d1
 dc.w $B27C ; ROM 0x01C9E4: cmpw #1,%d1
 dc.w $0001
 dc.w $6200 ; ROM 0x01C9E8: bhiw 0x81ca0e
 dc.w $0024
 dc.w $7800 ; ROM 0x01C9EC: moveq #0,%d4
 dc.w $7600 ; ROM 0x01C9EE: moveq #0,%d3
 dc.w $2079 ; ROM 0x01C9F0: moveal 0x1ce0e,%a0
 dc.w $0001
 dc.w $CE0E
 dc.w $1810 ; ROM 0x01C9F6: moveb %a0@,%d4
 dc.w $3601 ; ROM 0x01C9F8: movew %d1,%d3
 dc.w $2004 ; ROM 0x01C9FA: movel %d4,%d0
 dc.w $E7A8 ; ROM 0x01C9FC: lsll %d3,%d0
 dc.w $8480 ; ROM 0x01C9FE: orl %d0,%d2
 dc.w $52B9 ; ROM 0x01CA00: addql #1,0x1ce0e
 dc.w $0001
 dc.w $CE0E
 dc.w $5041 ; ROM 0x01CA06: addqw #8,%d1
 dc.w $B27C ; ROM 0x01CA08: cmpw #1,%d1
 dc.w $0001
 dc.w $63E2 ; ROM 0x01CA0C: blss 0x81c9f0
 dc.w $3002 ; ROM 0x01CA0E: movew %d2,%d0
 dc.w $C07C ; ROM 0x01CA10: andw #3,%d0
 dc.w $0003
 dc.w $E48A ; ROM 0x01CA14: lsrl #2,%d2
 dc.w $23C2 ; ROM 0x01CA16: movel %d2,0x1d71a
 dc.w $0001
 dc.w $D71A
 dc.w $5541 ; ROM 0x01CA1C: subqw #2,%d1
 dc.w $33C1 ; ROM 0x01CA1E: movew %d1,0x1d71e
 dc.w $0001
 dc.w $D71E
 dc.w $B07C ; ROM 0x01CA24: cmpw #2,%d0
 dc.w $0002
 dc.w $6600 ; ROM 0x01CA28: bnew 0x81ca36
 dc.w $000C
 dc.w $4EB9 ; ROM 0x01CA2C: jsr 0x81c4de
 dc.w $0081
 dc.w $C4DE
 dc.w $6000 ; ROM 0x01CA32: braw 0x81ca5a
 dc.w $0026
 dc.w $4A40 ; ROM 0x01CA36: tstw %d0
 dc.w $6600 ; ROM 0x01CA38: bnew 0x81ca46
 dc.w $000C
 dc.w $4EB9 ; ROM 0x01CA3C: jsr 0x81c210
 dc.w $0081
 dc.w $C210
 dc.w $6000 ; ROM 0x01CA42: braw 0x81ca5a
 dc.w $0016
 dc.w $B07C ; ROM 0x01CA46: cmpw #1,%d0
 dc.w $0001
 dc.w $6700 ; ROM 0x01CA4A: beqw 0x81ca54
 dc.w $0008
 dc.w $7002 ; ROM 0x01CA4E: moveq #2,%d0
 dc.w $6000 ; ROM 0x01CA50: braw 0x81ca5a
 dc.w $0008
 dc.w $4EB9 ; ROM 0x01CA54: jsr 0x81c32c
 dc.w $0081
 dc.w $C32C
 dc.w $4CEE ; ROM 0x01CA5A: moveml %fp@(-16),%d2-%d5
 dc.w $003C
 dc.w $FFF0
 dc.w $4E5E ; ROM 0x01CA60: unlk %fp
 dc.w $4E75 ; ROM 0x01CA62: rts
 dc.w $4E56 ; ROM 0x01CA64: linkw %fp,#-4
 dc.w $FFFC
 dc.w $2F02 ; ROM 0x01CA68: movel %d2,%sp@-
 dc.w $720A ; ROM 0x01CA6A: moveq #10,%d1
 dc.w $D3B9 ; ROM 0x01CA6C: addl %d1,0x1ce0e
 dc.w $0001
 dc.w $CE0E
 dc.w $4879 ; ROM 0x01CA72: pea 0x81a638
 dc.w $0081
 dc.w $A638
 dc.w $4EB9 ; ROM 0x01CA78: jsr 0x80b748
 dc.w $0080
 dc.w $B748
 dc.w $584F ; ROM 0x01CA7E: addqw #4,%sp
 dc.w $4279 ; ROM 0x01CA80: clrw 0x1d718
 dc.w $0001
 dc.w $D718
 dc.w $4279 ; ROM 0x01CA86: clrw 0x1d71e
 dc.w $0001
 dc.w $D71E
 dc.w $42B9 ; ROM 0x01CA8C: clrl 0x1d71a
 dc.w $0001
 dc.w $D71A
 dc.w $33FC ; ROM 0x01CA92: movew #9,0x1d720
 dc.w $0009
 dc.w $0001
 dc.w $D720
 dc.w $33FC ; ROM 0x01CA9A: movew #6,0x1d722
 dc.w $0006
 dc.w $0001
 dc.w $D722
 dc.w $2F3C ; ROM 0x01CAA2: movel #32768,%sp@-
 dc.w $0000
 dc.w $8000
 dc.w $4879 ; ROM 0x01CAA8: pea 0x1f7000
 dc.w $001F
 dc.w $7000
 dc.w $4EB9 ; ROM 0x01CAAE: jsr 0x81ba46
 dc.w $0081
 dc.w $BA46
 dc.w $504F ; ROM 0x01CAB4: addqw #8,%sp
 dc.w $4242 ; ROM 0x01CAB6: clrw %d2
 dc.w $4279 ; ROM 0x01CAB8: clrw 0x1d724
 dc.w $0001
 dc.w $D724
 dc.w $486E ; ROM 0x01CABE: pea %fp@(-2)
 dc.w $FFFE
 dc.w $4EB9 ; ROM 0x01CAC2: jsr 0x81c99e
 dc.w $0081
 dc.w $C99E
 dc.w $584F ; ROM 0x01CAC8: addqw #4,%sp
 dc.w $4A40 ; ROM 0x01CACA: tstw %d0
 dc.w $6600 ; ROM 0x01CACC: bnew 0x81caf4
 dc.w $0026
 dc.w $B479 ; ROM 0x01CAD0: cmpw 0x1d724,%d2
 dc.w $0001
 dc.w $D724
 dc.w $6400 ; ROM 0x01CAD6: bccw 0x81cae0
 dc.w $0008
 dc.w $3439 ; ROM 0x01CADA: movew 0x1d724,%d2
 dc.w $0001
 dc.w $D724
 dc.w $4A6E ; ROM 0x01CAE0: tstw %fp@(-2)
 dc.w $FFFE
 dc.w $67D2 ; ROM 0x01CAE4: beqs 0x81cab8
 dc.w $3F39 ; ROM 0x01CAE6: movew 0x1d718,%sp@-
 dc.w $0001
 dc.w $D718
 dc.w $4EB9 ; ROM 0x01CAEC: jsr 0x81c100
 dc.w $0081
 dc.w $C100
 dc.w $4240 ; ROM 0x01CAF2: clrw %d0
 dc.w $242E ; ROM 0x01CAF4: movel %fp@(-8),%d2
 dc.w $FFF8
 dc.w $4E5E ; ROM 0x01CAF8: unlk %fp
 dc.w $4E75 ; ROM 0x01CAFA: rts
 dc.w $0000 ; ROM 0x01CAFC: orib #0,%d0
 dc.w $0000
 dc.w $4E56 ; ROM 0x01CB00: linkw %fp,#0
 dc.w $0000
 dc.w $48E7 ; ROM 0x01CB04: moveml %d2-%d4,%sp@-
 dc.w $3800
 dc.w $322E ; ROM 0x01CB08: movew %fp@(8),%d1
 dc.w $0008
 dc.w $342E ; ROM 0x01CB0C: movew %fp@(10),%d2
 dc.w $000A
 dc.w $362E ; ROM 0x01CB10: movew %fp@(12),%d3
 dc.w $000C
 dc.w $382E ; ROM 0x01CB14: movew %fp@(14),%d4
 dc.w $000E
 dc.w $3001 ; ROM 0x01CB18: movew %d1,%d0
 dc.w $E940 ; ROM 0x01CB1A: aslw #4,%d0
 dc.w $D041 ; ROM 0x01CB1C: addw %d1,%d0
 dc.w $3202 ; ROM 0x01CB1E: movew %d2,%d1
 dc.w $E341 ; ROM 0x01CB20: aslw #1,%d1
 dc.w $D242 ; ROM 0x01CB22: addw %d2,%d1
 dc.w $E541 ; ROM 0x01CB24: aslw #2,%d1
 dc.w $9242 ; ROM 0x01CB26: subw %d2,%d1
 dc.w $D041 ; ROM 0x01CB28: addw %d1,%d0
 dc.w $3203 ; ROM 0x01CB2A: movew %d3,%d1
 dc.w $E741 ; ROM 0x01CB2C: aslw #3,%d1
 dc.w $9243 ; ROM 0x01CB2E: subw %d3,%d1
 dc.w $D041 ; ROM 0x01CB30: addw %d1,%d0
 dc.w $3204 ; ROM 0x01CB32: movew %d4,%d1
 dc.w $E341 ; ROM 0x01CB34: aslw #1,%d1
 dc.w $D244 ; ROM 0x01CB36: addw %d4,%d1
 dc.w $D041 ; ROM 0x01CB38: addw %d1,%d0
 dc.w $C07C ; ROM 0x01CB3A: andw #31,%d0
 dc.w $001F
 dc.w $4CEE ; ROM 0x01CB3E: moveml %fp@(-12),%d2-%d4
 dc.w $001C
 dc.w $FFF4
 dc.w $4E5E ; ROM 0x01CB44: unlk %fp
 dc.w $4E75 ; ROM 0x01CB46: rts
 dc.w $4E56 ; ROM 0x01CB48: linkw %fp,#0
 dc.w $0000
 dc.w $48E7 ; ROM 0x01CB4C: moveml %d2-%d6,%sp@-
 dc.w $3E00
 dc.w $322E ; ROM 0x01CB50: movew %fp@(8),%d1
 dc.w $0008
 dc.w $363C ; ROM 0x01CB54: movew #255,%d3
 dc.w $00FF
 dc.w $3803 ; ROM 0x01CB58: movew %d3,%d4
 dc.w $C86E ; ROM 0x01CB5A: andw %fp@(10),%d4
 dc.w $000A
 dc.w $3403 ; ROM 0x01CB5E: movew %d3,%d2
 dc.w $C46E ; ROM 0x01CB60: andw %fp@(12),%d2
 dc.w $000C
 dc.w $C66E ; ROM 0x01CB64: andw %fp@(14),%d3
 dc.w $000E
 dc.w $2001 ; ROM 0x01CB68: movel %d1,%d0
 dc.w $7C1D ; ROM 0x01CB6A: moveq #29,%d6
 dc.w $EDA0 ; ROM 0x01CB6C: asll %d6,%d0
 dc.w $CABC ; ROM 0x01CB6E: andl #536870911,%d5
 dc.w $1FFF
 dc.w $FFFF
 dc.w $8A80 ; ROM 0x01CB74: orl %d0,%d5
 dc.w $3F03 ; ROM 0x01CB76: movew %d3,%sp@-
 dc.w $3F02 ; ROM 0x01CB78: movew %d2,%sp@-
 dc.w $3F04 ; ROM 0x01CB7A: movew %d4,%sp@-
 dc.w $3F01 ; ROM 0x01CB7C: movew %d1,%sp@-
 dc.w $4EB9 ; ROM 0x01CB7E: jsr 0x81cb00
 dc.w $0081
 dc.w $CB00
 dc.w $7C1F ; ROM 0x01CB84: moveq #31,%d6
 dc.w $C086 ; ROM 0x01CB86: andl %d6,%d0
 dc.w $E148 ; ROM 0x01CB88: lslw #8,%d0
 dc.w $4840 ; ROM 0x01CB8A: swap %d0
 dc.w $4240 ; ROM 0x01CB8C: clrw %d0
 dc.w $CABC ; ROM 0x01CB8E: andl #-520093697,%d5
 dc.w $E0FF
 dc.w $FFFF
 dc.w $8A80 ; ROM 0x01CB94: orl %d0,%d5
 dc.w $4844 ; ROM 0x01CB96: swap %d4
 dc.w $4244 ; ROM 0x01CB98: clrw %d4
 dc.w $CABC ; ROM 0x01CB9A: andl #-16711681,%d5
 dc.w $FF00
 dc.w $FFFF
 dc.w $8A84 ; ROM 0x01CBA0: orl %d4,%d5
 dc.w $C4BC ; ROM 0x01CBA2: andl #255,%d2
 dc.w $0000
 dc.w $00FF
 dc.w $E18A ; ROM 0x01CBA8: lsll #8,%d2
 dc.w $CA7C ; ROM 0x01CBAA: andw #255,%d5
 dc.w $00FF
 dc.w $8A82 ; ROM 0x01CBAE: orl %d2,%d5
 dc.w $1A03 ; ROM 0x01CBB0: moveb %d3,%d5
 dc.w $2005 ; ROM 0x01CBB2: movel %d5,%d0
 dc.w $4CEE ; ROM 0x01CBB4: moveml %fp@(-20),%d2-%d6
 dc.w $007C
 dc.w $FFEC
 dc.w $4E5E ; ROM 0x01CBBA: unlk %fp
 dc.w $4E75 ; ROM 0x01CBBC: rts
 dc.w $4E56 ; ROM 0x01CBBE: linkw %fp,#0
 dc.w $0000
 dc.w $48E7 ; ROM 0x01CBC2: moveml %d2-%d4,%sp@-
 dc.w $3800
 dc.w $222E ; ROM 0x01CBC6: movel %fp@(8),%d1
 dc.w $0008
 dc.w $2601 ; ROM 0x01CBCA: movel %d1,%d3
 dc.w $4243 ; ROM 0x01CBCC: clrw %d3
 dc.w $4843 ; ROM 0x01CBCE: swap %d3
 dc.w $E04B ; ROM 0x01CBD0: lsrw #8,%d3
 dc.w $1003 ; ROM 0x01CBD2: moveb %d3,%d0
 dc.w $C03C ; ROM 0x01CBD4: andb #-32,%d0
 dc.w $00E0
 dc.w $6700 ; ROM 0x01CBD8: beqw 0x81cbea
 dc.w $0010
 dc.w $2401 ; ROM 0x01CBDC: movel %d1,%d2
 dc.w $781D ; ROM 0x01CBDE: moveq #29,%d4
 dc.w $E8AA ; ROM 0x01CBE0: lsrl %d4,%d2
 dc.w $B47C ; ROM 0x01CBE2: cmpw #5,%d2
 dc.w $0005
 dc.w $6300 ; ROM 0x01CBE6: blsw 0x81cbf0
 dc.w $0008
 dc.w $4240 ; ROM 0x01CBEA: clrw %d0
 dc.w $6000 ; ROM 0x01CBEC: braw 0x81cc22
 dc.w $0034
 dc.w $4267 ; ROM 0x01CBF0: clrw %sp@-
 dc.w $1F41 ; ROM 0x01CBF2: moveb %d1,%sp@(1)
 dc.w $0001
 dc.w $2001 ; ROM 0x01CBF6: movel %d1,%d0
 dc.w $E088 ; ROM 0x01CBF8: lsrl #8,%d0
 dc.w $4267 ; ROM 0x01CBFA: clrw %sp@-
 dc.w $1F40 ; ROM 0x01CBFC: moveb %d0,%sp@(1)
 dc.w $0001
 dc.w $2001 ; ROM 0x01CC00: movel %d1,%d0
 dc.w $4240 ; ROM 0x01CC02: clrw %d0
 dc.w $4840 ; ROM 0x01CC04: swap %d0
 dc.w $4267 ; ROM 0x01CC06: clrw %sp@-
 dc.w $1F40 ; ROM 0x01CC08: moveb %d0,%sp@(1)
 dc.w $0001
 dc.w $3F02 ; ROM 0x01CC0C: movew %d2,%sp@-
 dc.w $4EB9 ; ROM 0x01CC0E: jsr 0x81cb00
 dc.w $0081
 dc.w $CB00
 dc.w $3203 ; ROM 0x01CC14: movew %d3,%d1
 dc.w $C27C ; ROM 0x01CC16: andw #31,%d1
 dc.w $001F
 dc.w $B240 ; ROM 0x01CC1A: cmpw %d0,%d1
 dc.w $57C0 ; ROM 0x01CC1C: seq %d0
 dc.w $4880 ; ROM 0x01CC1E: extw %d0
 dc.w $4440 ; ROM 0x01CC20: negw %d0
 dc.w $4CEE ; ROM 0x01CC22: moveml %fp@(-12),%d2-%d4
 dc.w $001C
 dc.w $FFF4
 dc.w $4E5E ; ROM 0x01CC28: unlk %fp
 dc.w $4E75 ; ROM 0x01CC2A: rts
 dc.w $4E56 ; ROM 0x01CC2C: linkw %fp,#0
 dc.w $0000
 dc.w $3039 ; ROM 0x01CC30: movew 0x1d734,%d0
 dc.w $0001
 dc.w $D734
 dc.w $5279 ; ROM 0x01CC36: addqw #1,0x1d734
 dc.w $0001
 dc.w $D734
 dc.w $B07C ; ROM 0x01CC3C: cmpw #3,%d0
 dc.w $0003
 dc.w $6F00 ; ROM 0x01CC40: blew 0x81cc50
 dc.w $000E
 dc.w $2F3C ; ROM 0x01CC44: movel #-17965393,%sp@-
 dc.w $FEED
 dc.w $DEAF
 dc.w $4EB9 ; ROM 0x01CC4A: jsr 0x81ba38
 dc.w $0081
 dc.w $BA38
 dc.w $4E5E ; ROM 0x01CC50: unlk %fp
 dc.w $4E75 ; ROM 0x01CC52: rts
 dc.w $4E56 ; ROM 0x01CC54: linkw %fp,#0
 dc.w $0000
 dc.w $2F03 ; ROM 0x01CC58: movel %d3,%sp@-
 dc.w $2F02 ; ROM 0x01CC5A: movel %d2,%sp@-
 dc.w $242E ; ROM 0x01CC5C: movel %fp@(8),%d2
 dc.w $0008
 dc.w $52B9 ; ROM 0x01CC60: addql #1,0x1d730
 dc.w $0001
 dc.w $D730
 dc.w $2F02 ; ROM 0x01CC66: movel %d2,%sp@-
 dc.w $4EB9 ; ROM 0x01CC68: jsr 0x81cbbe
 dc.w $0081
 dc.w $CBBE
 dc.w $584F ; ROM 0x01CC6E: addqw #4,%sp
 dc.w $4A40 ; ROM 0x01CC70: tstw %d0
 dc.w $6700 ; ROM 0x01CC72: beqw 0x81cce4
 dc.w $0070
 dc.w $2002 ; ROM 0x01CC76: movel %d2,%d0
 dc.w $761D ; ROM 0x01CC78: moveq #29,%d3
 dc.w $E6A8 ; ROM 0x01CC7A: lsrl %d3,%d0
 dc.w $5340 ; ROM 0x01CC7C: subqw #1,%d0
 dc.w $B07C ; ROM 0x01CC7E: cmpw #4,%d0
 dc.w $0004
 dc.w $6200 ; ROM 0x01CC82: bhiw 0x81cd88
 dc.w $0104
 dc.w $C0BC ; ROM 0x01CC86: andl #65535,%d0
 dc.w $0000
 dc.w $FFFF
 dc.w $D080 ; ROM 0x01CC8C: addl %d0,%d0
 dc.w $303B ; ROM 0x01CC8E: movew %pc@(0x81cc96,%d0:l),%d0
 dc.w $0806
 dc.w $4EFB ; ROM 0x01CC92: jmp %pc@(0x81cc96,%d0:w)
 dc.w $0002
 dc.w $000A ; ROM 0x01CC96: 012
 dc.w $0042 ; ROM 0x01CC98: oriw #172,%d2
 dc.w $00AC
 dc.w $00BE ; ROM 0x01CC9C: oril #14950402,%d6
 dc.w $00E4
 dc.w $2002
 dc.w $4240 ; ROM 0x01CCA2: clrw %d0
 dc.w $4840 ; ROM 0x01CCA4: swap %d0
 dc.w $E140 ; ROM 0x01CCA6: aslw #8,%d0
 dc.w $2202 ; ROM 0x01CCA8: movel %d2,%d1
 dc.w $E089 ; ROM 0x01CCAA: lsrl #8,%d1
 dc.w $C27C ; ROM 0x01CCAC: andw #255,%d1
 dc.w $00FF
 dc.w $8041 ; ROM 0x01CCB0: orw %d1,%d0
 dc.w $33C0 ; ROM 0x01CCB2: movew %d0,0x1d736
 dc.w $0001
 dc.w $D736
 dc.w $2002 ; ROM 0x01CCB8: movel %d2,%d0
 dc.w $E180 ; ROM 0x01CCBA: asll #8,%d0
 dc.w $C07C ; ROM 0x01CCBC: andw #-256,%d0
 dc.w $FF00
 dc.w $33C0 ; ROM 0x01CCC0: movew %d0,0x1d738
 dc.w $0001
 dc.w $D738
 dc.w $4279 ; ROM 0x01CCC6: clrw 0x1d73a
 dc.w $0001
 dc.w $D73A
 dc.w $33FC ; ROM 0x01CCCC: movew #2,0x1d73c
 dc.w $0002
 dc.w $0001
 dc.w $D73C
 dc.w $6000 ; ROM 0x01CCD4: braw 0x81cd88
 dc.w $00B2
 dc.w $0C79 ; ROM 0x01CCD8: cmpiw #2,0x1d73c
 dc.w $0002
 dc.w $0001
 dc.w $D73C
 dc.w $6700 ; ROM 0x01CCE0: beqw 0x81ccf6
 dc.w $0014
 dc.w $52B9 ; ROM 0x01CCE4: addql #1,0x1d72c
 dc.w $0001
 dc.w $D72C
 dc.w $2F02 ; ROM 0x01CCEA: movel %d2,%sp@-
 dc.w $4EB9 ; ROM 0x01CCEC: jsr 0x81cc2c
 dc.w $0081
 dc.w $CC2C
 dc.w $6000 ; ROM 0x01CCF2: braw 0x81cd8e
 dc.w $009A
 dc.w $2002 ; ROM 0x01CCF6: movel %d2,%d0
 dc.w $4240 ; ROM 0x01CCF8: clrw %d0
 dc.w $4840 ; ROM 0x01CCFA: swap %d0
 dc.w $C07C ; ROM 0x01CCFC: andw #255,%d0
 dc.w $00FF
 dc.w $8079 ; ROM 0x01CD00: orw 0x1d738,%d0
 dc.w $0001
 dc.w $D738
 dc.w $33C0 ; ROM 0x01CD06: movew %d0,0x1d738
 dc.w $0001
 dc.w $D738
 dc.w $3202 ; ROM 0x01CD0C: movew %d2,%d1
 dc.w $33C1 ; ROM 0x01CD0E: movew %d1,0x1d73a
 dc.w $0001
 dc.w $D73A
 dc.w $3F01 ; ROM 0x01CD14: movew %d1,%sp@-
 dc.w $3F00 ; ROM 0x01CD16: movew %d0,%sp@-
 dc.w $3F39 ; ROM 0x01CD18: movew 0x1d736,%sp@-
 dc.w $0001
 dc.w $D736
 dc.w $4EB9 ; ROM 0x01CD1E: jsr 0x809de8
 dc.w $0080
 dc.w $9DE8
 dc.w $33FC ; ROM 0x01CD24: movew #1,0x1d73c
 dc.w $0001
 dc.w $0001
 dc.w $D73C
 dc.w $4279 ; ROM 0x01CD2C: clrw 0x1d73a
 dc.w $0001
 dc.w $D73A
 dc.w $4279 ; ROM 0x01CD32: clrw 0x1d738
 dc.w $0001
 dc.w $D738
 dc.w $4279 ; ROM 0x01CD38: clrw 0x1d736
 dc.w $0001
 dc.w $D736
 dc.w $6000 ; ROM 0x01CD3E: braw 0x81cd88
 dc.w $0048
 dc.w $C4BC ; ROM 0x01CD42: andl #16777215,%d2
 dc.w $00FF
 dc.w $FFFF
 dc.w $2F02 ; ROM 0x01CD48: movel %d2,%sp@-
 dc.w $4EB9 ; ROM 0x01CD4A: jsr 0x809e28
 dc.w $0080
 dc.w $9E28
 dc.w $6000 ; ROM 0x01CD50: braw 0x81cd88
 dc.w $0036
 dc.w $4267 ; ROM 0x01CD54: clrw %sp@-
 dc.w $1F42 ; ROM 0x01CD56: moveb %d2,%sp@(1)
 dc.w $0001
 dc.w $2002 ; ROM 0x01CD5A: movel %d2,%d0
 dc.w $E088 ; ROM 0x01CD5C: lsrl #8,%d0
 dc.w $4267 ; ROM 0x01CD5E: clrw %sp@-
 dc.w $1F40 ; ROM 0x01CD60: moveb %d0,%sp@(1)
 dc.w $0001
 dc.w $2002 ; ROM 0x01CD64: movel %d2,%d0
 dc.w $4240 ; ROM 0x01CD66: clrw %d0
 dc.w $4840 ; ROM 0x01CD68: swap %d0
 dc.w $4267 ; ROM 0x01CD6A: clrw %sp@-
 dc.w $1F40 ; ROM 0x01CD6C: moveb %d0,%sp@(1)
 dc.w $0001
 dc.w $4EB9 ; ROM 0x01CD70: jsr 0x809e3e
 dc.w $0080
 dc.w $9E3E
 dc.w $6000 ; ROM 0x01CD76: braw 0x81cd88
 dc.w $0010
 dc.w $C4BC ; ROM 0x01CD7A: andl #16777215,%d2
 dc.w $00FF
 dc.w $FFFF
 dc.w $2F02 ; ROM 0x01CD80: movel %d2,%sp@-
 dc.w $4EB9 ; ROM 0x01CD82: jsr 0x809f06
 dc.w $0080
 dc.w $9F06
 dc.w $4279 ; ROM 0x01CD88: clrw 0x1d734
 dc.w $0001
 dc.w $D734
 dc.w $242E ; ROM 0x01CD8E: movel %fp@(-8),%d2
 dc.w $FFF8
 dc.w $262E ; ROM 0x01CD92: movel %fp@(-4),%d3
 dc.w $FFFC
 dc.w $4E5E ; ROM 0x01CD96: unlk %fp
 dc.w $4E75 ; ROM 0x01CD98: rts
 dc.w $4E56 ; ROM 0x01CD9A: linkw %fp,#-4
 dc.w $FFFC
 dc.w $48E7 ; ROM 0x01CD9E: moveml %d2-%d6,%sp@-
 dc.w $3E00
 dc.w $4EB9 ; ROM 0x01CDA2: jsr 0x809e86
 dc.w $0080
 dc.w $9E86
 dc.w $2200 ; ROM 0x01CDA8: movel %d0,%d1
 dc.w $3039 ; ROM 0x01CDAA: movew 0x1d73e,%d0
 dc.w $0001
 dc.w $D73E
 dc.w $5340 ; ROM 0x01CDB0: subqw #1,%d0
 dc.w $B07C ; ROM 0x01CDB2: cmpw #4,%d0
 dc.w $0004
 dc.w $6200 ; ROM 0x01CDB6: bhiw 0x81ce14
 dc.w $005C
 dc.w $C0BC ; ROM 0x01CDBA: andl #65535,%d0
 dc.w $0000
 dc.w $FFFF
 dc.w $D080 ; ROM 0x01CDC0: addl %d0,%d0
 dc.w $303B ; ROM 0x01CDC2: movew %pc@(0x81cdca,%d0:l),%d0
 dc.w $0806
 dc.w $4EFB ; ROM 0x01CDC6: jmp %pc@(0x81cdca,%d0:w)
 dc.w $0002
 dc.w $000A ; ROM 0x01CDCA: 012
 dc.w $0010 ; ROM 0x01CDCC: orib #68,%a0@
 dc.w $0044
 dc.w $003E ; ROM 0x01CDD0: 076
 dc.w $003E ; ROM 0x01CDD2: 076
 dc.w $7402 ; ROM 0x01CDD4: moveq #2,%d2
 dc.w $6000 ; ROM 0x01CDD6: braw 0x81ce16
 dc.w $003E
 dc.w $B2B9 ; ROM 0x01CDDA: cmpl 0x1d74c,%d1
 dc.w $0001
 dc.w $D74C
 dc.w $6600 ; ROM 0x01CDE0: bnew 0x81cdf6
 dc.w $0014
 dc.w $5279 ; ROM 0x01CDE4: addqw #1,0x1d750
 dc.w $0001
 dc.w $D750
 dc.w $0C79 ; ROM 0x01CDEA: cmpiw #4,0x1d750
 dc.w $0004
 dc.w $0001
 dc.w $D750
 dc.w $6300 ; ROM 0x01CDF2: blsw 0x81ce02
 dc.w $000E
 dc.w $7403 ; ROM 0x01CDF6: moveq #3,%d2
 dc.w $4279 ; ROM 0x01CDF8: clrw 0x1d750
 dc.w $0001
 dc.w $D750
 dc.w $6000 ; ROM 0x01CDFE: braw 0x81ce16
 dc.w $0016
 dc.w $7404 ; ROM 0x01CE02: moveq #4,%d2
 dc.w $6000 ; ROM 0x01CE04: braw 0x81ce16
 dc.w $0010
 dc.w $7401 ; ROM 0x01CE08: moveq #1,%d2
 dc.w $6000 ; ROM 0x01CE0A: braw 0x81ce16
 dc.w $000A
 dc.w $7405 ; ROM 0x01CE0E: moveq #5,%d2
 dc.w $6000 ; ROM 0x01CE10: braw 0x81ce16
 dc.w $0004
 dc.w $7403 ; ROM 0x01CE14: moveq #3,%d2
 dc.w $4AB9 ; ROM 0x01CE16: tstl 0x1d74c
 dc.w $0001
 dc.w $D74C
 dc.w $6600 ; ROM 0x01CE1C: bnew 0x81ce22
 dc.w $0004
 dc.w $7403 ; ROM 0x01CE20: moveq #3,%d2
 dc.w $3002 ; ROM 0x01CE22: movew %d2,%d0
 dc.w $5340 ; ROM 0x01CE24: subqw #1,%d0
 dc.w $B07C ; ROM 0x01CE26: cmpw #4,%d0
 dc.w $0004
 dc.w $6200 ; ROM 0x01CE2A: bhiw 0x81cf16
 dc.w $00EA
 dc.w $C0BC ; ROM 0x01CE2E: andl #65535,%d0
 dc.w $0000
 dc.w $FFFF
 dc.w $D080 ; ROM 0x01CE34: addl %d0,%d0
 dc.w $303B ; ROM 0x01CE36: movew %pc@(0x81ce3e,%d0:l),%d0
 dc.w $0806
 dc.w $4EFB ; ROM 0x01CE3A: jmp %pc@(0x81ce3e,%d0:w)
 dc.w $0002
 dc.w $000A ; ROM 0x01CE3E: 012
 dc.w $0056 ; ROM 0x01CE40: oriw #158,%fp@
 dc.w $009E
 dc.w $0082 ; ROM 0x01CE44: oril #12209849,%d2
 dc.w $00BA
 dc.w $4EB9
 dc.w $0080 ; ROM 0x01CE4A: oril #-1634590656,%d0
 dc.w $9E92
 dc.w $2040
 dc.w $23D0 ; ROM 0x01CE50: movel %a0@,0x1d740
 dc.w $0001
 dc.w $D740
 dc.w $23E8 ; ROM 0x01CE56: movel %a0@(4),0x1d744
 dc.w $0004
 dc.w $0001
 dc.w $D744
 dc.w $23E8 ; ROM 0x01CE5E: movel %a0@(8),0x1d748
 dc.w $0008
 dc.w $0001
 dc.w $D748
 dc.w $2079 ; ROM 0x01CE66: moveal 0x1d74c,%a0
 dc.w $0001
 dc.w $D74C
 dc.w $2039 ; ROM 0x01CE6C: movel 0x1d740,%d0
 dc.w $0001
 dc.w $D740
 dc.w $90A8 ; ROM 0x01CE72: subl %a0@(16),%d0
 dc.w $0010
 dc.w $7C0C ; ROM 0x01CE76: moveq #12,%d6
 dc.w $ECA0 ; ROM 0x01CE78: asrl %d6,%d0
 dc.w $2239 ; ROM 0x01CE7A: movel 0x1d744,%d1
 dc.w $0001
 dc.w $D744
 dc.w $92A8 ; ROM 0x01CE80: subl %a0@(20),%d1
 dc.w $0014
 dc.w $ECA1 ; ROM 0x01CE84: asrl %d6,%d1
 dc.w $3A00 ; ROM 0x01CE86: movew %d0,%d5
 dc.w $E045 ; ROM 0x01CE88: asrw #8,%d5
 dc.w $1800 ; ROM 0x01CE8A: moveb %d0,%d4
 dc.w $3601 ; ROM 0x01CE8C: movew %d1,%d3
 dc.w $E043 ; ROM 0x01CE8E: asrw #8,%d3
 dc.w $6000 ; ROM 0x01CE90: braw 0x81cf16
 dc.w $0084
 dc.w $2079 ; ROM 0x01CE94: moveal 0x1d74c,%a0
 dc.w $0001
 dc.w $D74C
 dc.w $2239 ; ROM 0x01CE9A: movel 0x1d744,%d1
 dc.w $0001
 dc.w $D744
 dc.w $92A8 ; ROM 0x01CEA0: subl %a0@(20),%d1
 dc.w $0014
 dc.w $2039 ; ROM 0x01CEA4: movel 0x1d748,%d0
 dc.w $0001
 dc.w $D748
 dc.w $90A8 ; ROM 0x01CEAA: subl %a0@(24),%d0
 dc.w $0018
 dc.w $7C0C ; ROM 0x01CEAE: moveq #12,%d6
 dc.w $ECA0 ; ROM 0x01CEB0: asrl %d6,%d0
 dc.w $2A01 ; ROM 0x01CEB2: movel %d1,%d5
 dc.w $ECA5 ; ROM 0x01CEB4: asrl %d6,%d5
 dc.w $3800 ; ROM 0x01CEB6: movew %d0,%d4
 dc.w $E044 ; ROM 0x01CEB8: asrw #8,%d4
 dc.w $1600 ; ROM 0x01CEBA: moveb %d0,%d3
 dc.w $6000 ; ROM 0x01CEBC: braw 0x81cf16
 dc.w $0058
 dc.w $486E ; ROM 0x01CEC0: pea %fp@(-4)
 dc.w $FFFC
 dc.w $4EB9 ; ROM 0x01CEC4: jsr 0x809ea0
 dc.w $0080
 dc.w $9EA0
 dc.w $584F ; ROM 0x01CECA: addqw #4,%sp
 dc.w $1A2E ; ROM 0x01CECC: moveb %fp@(-4),%d5
 dc.w $FFFC
 dc.w $182E ; ROM 0x01CED0: moveb %fp@(-3),%d4
 dc.w $FFFD
 dc.w $162E ; ROM 0x01CED4: moveb %fp@(-2),%d3
 dc.w $FFFE
 dc.w $6000 ; ROM 0x01CED8: braw 0x81cf16
 dc.w $003C
 dc.w $4279 ; ROM 0x01CEDC: clrw 0x1d750
 dc.w $0001
 dc.w $D750
 dc.w $23C1 ; ROM 0x01CEE2: movel %d1,0x1d74c
 dc.w $0001
 dc.w $D74C
 dc.w $2A01 ; ROM 0x01CEE8: movel %d1,%d5
 dc.w $4245 ; ROM 0x01CEEA: clrw %d5
 dc.w $4845 ; ROM 0x01CEEC: swap %d5
 dc.w $2801 ; ROM 0x01CEEE: movel %d1,%d4
 dc.w $E08C ; ROM 0x01CEF0: lsrl #8,%d4
 dc.w $1601 ; ROM 0x01CEF2: moveb %d1,%d3
 dc.w $6000 ; ROM 0x01CEF4: braw 0x81cf16
 dc.w $0020
 dc.w $4EB9 ; ROM 0x01CEF8: jsr 0x809ec4
 dc.w $0080
 dc.w $9EC4
 dc.w $23C0 ; ROM 0x01CEFE: movel %d0,0x1d754
 dc.w $0001
 dc.w $D754
 dc.w $1A39 ; ROM 0x01CF04: moveb 0x1d755,%d5
 dc.w $0001
 dc.w $D755
 dc.w $1839 ; ROM 0x01CF0A: moveb 0x1d756,%d4
 dc.w $0001
 dc.w $D756
 dc.w $1639 ; ROM 0x01CF10: moveb 0x1d757,%d3
 dc.w $0001
 dc.w $D757
 dc.w $33C2 ; ROM 0x01CF16: movew %d2,0x1d73e
 dc.w $0001
 dc.w $D73E
 dc.w $52B9 ; ROM 0x01CF1C: addql #1,0x1d728
 dc.w $0001
 dc.w $D728
 dc.w $4267 ; ROM 0x01CF22: clrw %sp@-
 dc.w $1F43 ; ROM 0x01CF24: moveb %d3,%sp@(1)
 dc.w $0001
 dc.w $4267 ; ROM 0x01CF28: clrw %sp@-
 dc.w $1F44 ; ROM 0x01CF2A: moveb %d4,%sp@(1)
 dc.w $0001
 dc.w $4267 ; ROM 0x01CF2E: clrw %sp@-
 dc.w $1F45 ; ROM 0x01CF30: moveb %d5,%sp@(1)
 dc.w $0001
 dc.w $3F02 ; ROM 0x01CF34: movew %d2,%sp@-
 dc.w $4EB9 ; ROM 0x01CF36: jsr 0x81cb48
 dc.w $0081
 dc.w $CB48
 dc.w $4CEE ; ROM 0x01CF3C: moveml %fp@(-24),%d2-%d6
 dc.w $007C
 dc.w $FFE8
 dc.w $4E5E ; ROM 0x01CF42: unlk %fp
 dc.w $4E75 ; ROM 0x01CF44: rts
 dc.w $4E56 ; ROM 0x01CF46: linkw %fp,#0
 dc.w $0000
 dc.w $33FC ; ROM 0x01CF4A: movew #-1,0x1d73e
 dc.w $FFFF
 dc.w $0001
 dc.w $D73E
 dc.w $42B9 ; ROM 0x01CF52: clrl 0x1d74c
 dc.w $0001
 dc.w $D74C
 dc.w $4279 ; ROM 0x01CF58: clrw 0x1d734
 dc.w $0001
 dc.w $D734
 dc.w $42B9 ; ROM 0x01CF5E: clrl 0x1d72c
 dc.w $0001
 dc.w $D72C
 dc.w $42B9 ; ROM 0x01CF64: clrl 0x1d730
 dc.w $0001
 dc.w $D730
 dc.w $42B9 ; ROM 0x01CF6A: clrl 0x1d728
 dc.w $0001
 dc.w $D728
 dc.w $33FC ; ROM 0x01CF70: movew #1,0x1d752
 dc.w $0001
 dc.w $0001
 dc.w $D752
 dc.w $4E5E ; ROM 0x01CF78: unlk %fp
 dc.w $4E75 ; ROM 0x01CF7A: rts
 dc.w $0000 ; ROM 0x01CF7C: orib #0,%d0
 dc.w $0000
 dc.w $7880 ; ROM 0x01CF80: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CF82: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CF84: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CF86: moveq #-128,%d4
 dc.w $0000 ; ROM 0x01CF88: orib #-64,%d0
 dc.w $78C0
 dc.w $0000
 dc.w $0000
 dc.w $0000
 dc.w $0000
 dc.w $0000
 dc.w $0000
 dc.w $0000
 dc.w $0000
 dc.w $0000
 dc.w $0000
 dc.w $0000
 dc.w $0000
 dc.w $0000 ; ROM 0x01CFA4: orib #-128,%d0
 dc.w $7880
 dc.w $7880 ; ROM 0x01CFA8: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFAA: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFAC: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFAE: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFB0: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFB2: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFB4: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFB6: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFB8: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFBA: moveq #-128,%d4
 dc.w $0000 ; ROM 0x01CFBC: orib #-64,%d0
 dc.w $78C0
 dc.w $0000
 dc.w $0000
 dc.w $0000
 dc.w $0000
 dc.w $0000
 dc.w $0000
 dc.w $0000
 dc.w $0000
 dc.w $0000
 dc.w $0000
 dc.w $0000
 dc.w $0000
 dc.w $0000 ; ROM 0x01CFD8: orib #-128,%d0
 dc.w $7880
 dc.w $7880 ; ROM 0x01CFDC: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFDE: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFE0: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFE2: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFE4: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFE6: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFE8: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFEA: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFEC: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFEE: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFF0: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFF2: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFF4: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFF6: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFF8: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFFA: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFFC: moveq #-128,%d4
 dc.w $7880 ; ROM 0x01CFFE: moveq #-128,%d4
club_release_code_end::
