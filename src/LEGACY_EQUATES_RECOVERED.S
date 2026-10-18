; Recovered hardware and synth compatibility aliases
; F14000 is the JOYSTICK read/write register in Jaguar hardware map.
; Audio addresses below come from the original FULSYN.OJ symbol table.
	.globl JOYIN,JOYOUT,SCORE_ADD,TIMER_ADD,DSPORG,VOLUME,PATCHLOC,FULSYN_E
JOYIN	EQU	$F14000
JOYOUT	EQU	$F14000
SCORE_ADD	EQU	$F1BB54
TIMER_ADD	EQU	$F1BB58
DSPORG	EQU	$F1B000
VOLUME	EQU	$F1B030
PATCHLOC	EQU	$F1BB5C
FULSYN_E	EQU	$F1BB94
; The original showcoord flag is exported by tables.s; no duplicate BSS byte.
