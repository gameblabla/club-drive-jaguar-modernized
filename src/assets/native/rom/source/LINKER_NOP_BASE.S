; ----------------------------------------------------------------------
; CLUB DRIVE / GPU RESOURCE ALIGNMENT (1994 RETAIL LINKER BEHAVIOUR)
; ----------------------------------------------------------------------
; The original toolchain pads the end of Jerry's FULSYN DSP object with two
; Motorola NOP words, before the first GPU container at cartridge $813578.
; Modern RLN aligns the same region with zero words.  Its four-byte gap is
; replaced with these source-assembled instructions during cartridge packing.
; Input: none; these words are never executed in ordinary game flow.
; Output: exactly two 68000 NOPs at ROM offsets $013574-$013577.
; Safety: only patch when the reserved linker gap is four zero bytes.
;	.text
legacy_gpu_padding::
	nop                             ; padding word 1: $4E71
	nop                             ; padding word 2: $4E71
