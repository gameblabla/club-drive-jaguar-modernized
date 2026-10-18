;------------------------------------------------------------------
; 3dds.inc
;	defines addresses for 3d data structures
;------------------------------------------------------------------

;PHRASE_ALIGN equ			((@1 + 7) & $fffffff8)

HUD1		equ	$60000		; player 1 heads up display
HUD2		equ	$61000		; player 2 HUD
PAUSECRY	equ	$62000		; "paused" bitmap

DS_BASE		equ	$6a200

ASCRN1		equ	$20000		; player 1 screen 1
BSCRN1		equ	$2ed80		; player 2 screen 1
ASCRN2		equ	$40000
BSCRN2		equ	$4ed80		; player 2 screen 2
ATOGGLE		equ	$60000

MARKADDR	EQU	$1fff00
LASTTIME	EQU	$1feefc
TIMEARRAY	EQU	$1ff000
DEBUG		EQU	$1ffe00

; data sizes for fixed structures (fixed in terms of global 3d coords)
MAX_VECTORS		equ	200 ; normals + verticie vectors
MAX_POINTS		equ	810;380 ; vertices
MAX_SURFS			equ	550;300 ; polygons
MAX_EDGES			equ	1200;600 ; edges
MAX_DIVIDERS		equ	550;300 ; dividing planes

; data sizes for mobile (car) structures
MAX_MVECTORS		equ	100 ; normals + verticie vectors
MAX_COLORS		equ	200  ; the only kind of colors computed ; 90
MAX_MPOINTS		equ	200 ; vertices
MAX_MSURFS		equ	90  ; trigons
MAX_MEDGES		equ	300 ; edges
MAX_MDIVIDERS		equ	100 ; dividing vectors

; player car driving data structures
	.include "car.inc"
	PLAYER1				equ	DS_BASE
	PLAYER2				equ	PLAYER1 + CAR_DS_SIZE

GEO_DS_BASE		equ		(( PLAYER2 + CAR_DS_SIZE					+ 3) & $fffffffc) ;LONG ALIGN

; what the variables mean:
; GEO_BND_PTR points to the current band
; BANDS is the list of bands we should do calculations on, which is
; the union of the camera's band list and the floor's; normally the
; camera and floor are in the same band. We also stuff any extra bands
; (e.g. the cars) into this list
; The list is null terminated, and can have at most 100 entries

GEO_BND_PTR		equ	GEO_DS_BASE
CURBND			equ	GEO_BND_PTR+4			; for ren and 3dend: points to band we're currently looking at
BANDS			equ	CURBND+4			; in comp: list of bands (see above)
DISPBANDS		equ	BANDS+404			; band to be displayed, and Z value for it
								; (sorted by Z)
; addresses of computed data structs
	SEMAPHORE			equ	DISPBANDS+800
	SIDES				equ	SEMAPHORE+16			; sides of viewing area
	DRAWRECT			equ	SIDES+8				; blitter rectangle to draw in
	XCENTER				equ	DRAWRECT+4			; (X,Y) of center of screen
	YCENTER				equ	XCENTER+4
	ASPECTR				equ	YCENTER+4			; aspect ratio of viewing area
	LOOPCNT				equ	ASPECTR+4			; loop counter for GPU loops
	PWRBALLX			equ	LOOPCNT+4			; transformed (screen) X coordinate for power ball
	PWRBALLY			equ	PWRBALLX+4			; screen Y coord for power ball
	PWRBALLZ			equ	PWRBALLY+4
	PWRBALLR			equ	PWRBALLZ+4			; radius for power ball
	tEND				equ	PWRBALLR+4
	GP_STACK			equ	((tEND+7) & $fffffff8)		; phrase align

	QUEUES				equ	GP_STACK+8192			; queues for playback/record
	GEO_END				equ	QUEUES+64000

;------------------------------------------------------------------
; addresses of structures in GPU RAM

POLYGON					equ	BASE + $3f20	; room for 12 points
CORNERS					equ	BASE + $3fe0	; x,y for the four corners - TLBR

;------------------------------------------------------------------
; edge bit numbers

TOP_EDGE		equ	0
LEFT_EDGE		equ	1
BOTTOM_EDGE	equ	2
RIGHT_EDGE	equ	3

.include "bndhead.inc"

