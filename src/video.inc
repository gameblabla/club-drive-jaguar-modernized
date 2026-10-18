; Note that the horizontal timing numbers are for NTSC
; in units of 100 ps

vclk		equ	376
ivclk		equ	vclk

horiz_per	equ	317778
sync_per	equ	46050
eq_per		equ	23500
front_porch	equ	17450
line_blank	equ	109500
disp_width	equ	1280 ;1155	;(this is in pixels + 1) * pix_size
disp_height	equ	234	;this is in lines - if this displays one line beyond vbb, the last line error is hidden

; Horizontal computations

n_hp			equ	horiz_per/ivclk
n_hbb		equ	((horiz_per-sync_per-front_porch)/ivclk)+$400
n_hbe		equ	(line_blank-sync_per-front_porch)/ivclk
n_hs			equ	((horiz_per-sync_per)/ivclk)+$400
n_hvs		equ	(horiz_per-(2*sync_per))/ivclk
n_heq		equ	(horiz_per-eq_per)/ivclk
n_hde		equ	((disp_width/2)-1)+$400
n_hdb1		equ	((n_hp)-(disp_width/2))
n_hdb2		equ	n_hdb1

n_vmode		equ	$c1

; Vertical

n_vp			equ	523
n_vee		equ	6
n_vbe		equ	40
n_vdb		equ	n_vbe-2 ;+6
n_vde		equ	n_vdb+(disp_height*2)
n_vbb		equ	n_vde ; if this blanks one line before vde, the last line error is hidden (n_vde+2 shows all lines)
n_vs			equ	n_vp-10
n_veb		equ	n_vs-n_vee

n_vi		equ	5
