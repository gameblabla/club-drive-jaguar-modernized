; =======================================================================
; Jaguar 1994 linker compatibility — release C-module separator NOPs
; =======================================================================
; The historical ALN linker inserted executable NOP words between some
; source object modules. RLN fills these same address slots with zeroes.
; The instruction words below are compiled from source and inserted into
; their verified, already allocated padding slots (no executable shifted).
; Each pair of instructions is accompanied by its ROM file offset:
;   $01B2CE        end of ALLOC.S, before LATTICE.S  (one NOP)
;   $01B544–01B547 end of LATTICE.S, before INFLATE.S (two NOPs)
;   $01C394–01C397 end of INFLATE.S, before PACKET.S (two NOPs)
; These are linker padding words, not a newly invented gameplay routine.
; =======================================================================
    .text
club_v13_helper_nops::
    nop          ; $01B2CE
    nop          ; $01B544
    nop          ; $01B546
    nop          ; $01C394
    nop          ; $01C396
