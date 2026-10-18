; ---------------------------------------------------------------------------
; CLUB DRIVE V14: recovered 1994 linker separator NOP instructions
; ---------------------------------------------------------------------------
; ALN emitted these NOPs in seven gaps between 68000 source objects.
; RLN emits 0x0000 into the SAME preallocated slots.  Do not change the
; lengths or place these bytes at arbitrary positions: the release builder
; verifies each original ROM position is zero and the retail words are NOPs.
; All seven sections were recovered from the supplied cartridge; function
; and linker semantics were checked against adjacent surviving .S modules.
; These comments are NEW recovery annotations (not original Atari comments).
; ---------------------------------------------------------------------------
	.text
club_v14_early_module_padding::
; ROM $002256: GAME/SYS boundary, 1 68000 NOP(s)
	nop
; ROM $002FE4: SYS/INPUT boundary, 2 68000 NOP(s)
	nop
	nop
; ROM $0031B2: INPUT/TITLE boundary, 3 68000 NOP(s)
	nop
	nop
	nop
; ROM $0060A4: TITLE/SELECT boundary, 2 68000 NOP(s)
	nop
	nop
; ROM $00778E: CREDITS/HISCORE boundary, 1 68000 NOP(s)
	nop
; ROM $009B5C: HISCORE/PLAYDATA area, 2 68000 NOP(s)
	nop
	nop
; ROM $00A056: SOUND/GPU support area, 1 68000 NOP(s)
	nop
club_v14_early_module_padding_end::
; Total: 24 bytes / twelve 68000 NOP instructions.
