; ---------------------------------------------------------------------
; CLUB DRIVE / RELEASE GPU CONTAINERS (1994 ORIGINAL LINK ORDER)
; ---------------------------------------------------------------------
; Entry:    68000 cartridge memory, aligned to eight-byte phrases.
; Input:    GPU programs assembled from the preserved Atari .GAS sources.
; Output:   8-byte Jaguar GPU load descriptor followed by GPU opcodes.
; Register use: none at 68000 runtime; this is constant, read-only data.
; Link note: follow the DSP object, preceding the C/68000 helpers.
; RELEASE_OVERLAY recovery note: only padding words are recovered from retail.
; This is *not* 68000 executable code: the 68000 loader copies it to GPU RAM.
; ---------------------------------------------------------------------
	.text
club_gpu_begin::
; 3D       ROM 0x013578; GPU RAM destination $00F03000, instructions 46 bytes
; Source: 3D.GAS (via build/gpu_link/3d.bin).
gpprog::
	incbin "build/gpu_link/3d.bin"
; 2 historical alignment byte(s) at $0135AE; not GPU instructions.
	dc.w $3030
; CASBEG   ROM 0x0135b0; GPU RAM destination $00F03038, instructions 2688 bytes
; Source: CASBEG.GAS (via build/gpu_link/casbeg.bin).
casbeg::
	incbin "build/gpu_link/casbeg.bin"
; TAGBEG   ROM 0x014038; GPU RAM destination $00F03038, instructions 1864 bytes
; Source: TAGBEG.GAS (via build/gpu_link/tagbeg.bin).
tagbeg::
	incbin "build/gpu_link/tagbeg.bin"
; RACBEG   ROM 0x014788; GPU RAM destination $00F03038, instructions 2452 bytes
; Source: RACBEG.GAS (via build/gpu_link/racbeg.bin).
racbeg::
	incbin "build/gpu_link/racbeg.bin"
; 4 historical alignment byte(s) at $015124; not GPU instructions.
	dc.w $0000,$0000
; COMP     ROM 0x015128; GPU RAM destination $00F03038, instructions 3654 bytes
; Source: COMP.GAS (via build/gpu_link/comp.bin).
cgpprog::
	incbin "build/gpu_link/comp.bin"
; 2 historical alignment byte(s) at $015F76; not GPU instructions.
	dc.w $3030
; REN      ROM 0x015f78; GPU RAM destination $00F03038, instructions 3750 bytes
; Source: REN.GAS (via build/gpu_link/ren.bin).
rgpprog::
	incbin "build/gpu_link/ren.bin"
; 2 historical alignment byte(s) at $016E26; not GPU instructions.
	dc.w $3030
; CASEND   ROM 0x016e28; GPU RAM destination $00F03038, instructions 3702 bytes
; Source: CASEND.GAS (via build/gpu_link/casend.bin).
casend::
	incbin "build/gpu_link/casend.bin"
; 2 historical alignment byte(s) at $017CA6; not GPU instructions.
	dc.w $3030
; TAGEND   ROM 0x017ca8; GPU RAM destination $00F03038, instructions 3830 bytes
; Source: TAGEND.GAS (via build/gpu_link/tagend.bin).
tagend::
	incbin "build/gpu_link/tagend.bin"
; 2 historical alignment byte(s) at $018BA6; not GPU instructions.
	dc.w $3030
; RACEND   ROM 0x018ba8; GPU RAM destination $00F03038, instructions 3766 bytes
; Source: RACEND.GAS (via build/gpu_link/racend.bin).
racend::
	incbin "build/gpu_link/racend.bin"
; 2 historical alignment byte(s) at $019A66; not GPU instructions.
	dc.w $3030
; GPUNZIP  ROM 0x019a68; GPU RAM destination $00F03000, instructions 960 bytes
; Source: GPUNZIP.GAS (via build/gpu_link/gpunzip.bin).
_gpunzip::
	incbin "build/gpu_link/gpunzip.bin"
; PRECOMP  ROM 0x019e30; GPU RAM destination $00F03038, instructions 2732 bytes
; Source: PRECOMP.GAS (via build/gpu_link/precomp.bin).
precomp::
	incbin "build/gpu_link/precomp.bin"
; 4 historical alignment byte(s) at $01A8E4; not GPU instructions.
	dc.w $0000,$0000
; PREREN   ROM 0x01a8e8; GPU RAM destination $00F03038, instructions 1302 bytes
; Source: PREREN.GAS (via build/gpu_link/preren.bin).
preren::
	incbin "build/gpu_link/preren.bin"
; 2 historical alignment byte(s) at $01AE06; not GPU instructions.
	dc.w $3030
club_gpu_end::
