; ---------------------------------------------------------------------------
; CLUB DRIVE V15 -- VERIFIED HISTORICAL CPU OBJECT PADDING
; ---------------------------------------------------------------------------
; These two inter-module gaps are all zero in the modern RLN linked payload.
; The retail ROM contains 68000 NOP ($4E71) instructions at the very same
; file offsets. Restoring them here changes NO function or symbol address.
;
; RECOVERY NOTE (2026): original Atari comments were not available for
; these link-time fill words. The locations and counts were inferred by
; comparing a fully assembled source-linked executable to the retail ROM.
; They must only be inserted after checking that source slots are zero and
; the retail words are exactly NOP -- never over real executable bytes.
; ---------------------------------------------------------------------------
	.text
club_v15_cpu_alignment::
; ROM $00FB7C: gap between late PLAY/PLAYINP/TD source object areas, 4 bytes.
	nop
	nop
; ROM $010F9A: gap before GPUFIX/control-address data, 6 bytes.
	nop
	nop
	nop
club_v15_cpu_alignment_end::
; Assembles to five 68000 NOP instructions, ten bytes total.
