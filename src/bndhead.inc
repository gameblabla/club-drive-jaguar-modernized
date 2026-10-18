;
; data structure for per-band data

; Constants that are always present

BND_FLAGS	EQU	0		; flags for the band
					;	bit 0: band cannot be collided with
					;	bit 1: draw a cloudy sky with this band
					;	bit 2: band is a bonus world (don't count time, don't draw map)

					;	bit 13: (set in code): 0 if band has been visited by "comp"
					;			       1 if band is in comp list but not yet computed
					;	bit 14: (set in code): band has been clipped from view

NUM_PNTS	EQU	BND_FLAGS+4	; number of points in the band
NUM_VECTORS	EQU	NUM_PNTS+2	; number of vectors -- NOTE: this must immediately follow NUM_PNTS

NUM_DIVIDERS	EQU	NUM_VECTORS+2	; number of dividers
NUM_EDGES	EQU	NUM_DIVIDERS+2	; number of edges

NUM_CPS		EQU	NUM_EDGES+2	; number of CPs
NUM_COLORS	EQU	NUM_CPS+2	; number of entries in color table (normally 0)

;; Make sure the stuff below is long aligned
FILLER		EQU	NUM_COLORS+0	; make it NUM_COLORS+2 if stuff is inserted above

XORIG		EQU	FILLER+2	; X origin in global coordinates
YORIG		EQU	XORIG+4
ZORIG		EQU	YORIG+4
RADIUS		EQU	ZORIG+4		; square of the band's radius

PROP_LIST	EQU	RADIUS+4	; pointer to special surface properties

; static band data

DIVIDER_LIST	EQU	PROP_LIST+4
EDGE_LIST	EQU	DIVIDER_LIST+4
PNT_LIST	EQU	EDGE_LIST+4
SURF_LIST	EQU	PNT_LIST+4
SURFS_END	EQU	SURF_LIST+4
TREE		EQU	SURFS_END+4
TEXTURES	EQU	TREE+4
COLOR_LIST	EQU	TEXTURES+4	; colors for dynamic coloring (if applicable)
CAMERA		EQU	COLOR_LIST+4	; pointer to camera list (if applicable)

; pointers to allocated global memory

ROTPNT_LIST	EQU	CAMERA+4	; pointer to rotated points
tVECTORS	EQU	ROTPNT_LIST+4
tCOLORS		EQU	tVECTORS+4
tEDGES		EQU	tCOLORS+4
tDIVIDERS	EQU	tEDGES+4
tCLOSE_LIST	EQU	tDIVIDERS+4
tPNTS		EQU	tCLOSE_LIST+4
tPOLYS		EQU	tPNTS+4

; statistics about this band
BND_MATRIX	EQU	tPOLYS+4		; pointer to matrix for rotating band
tNUM_EXTRAS	EQU	BND_MATRIX+4		; extra points added when rendering
tINITED		EQU	tNUM_EXTRAS+4		; flag: set to 1 if the bnd is initialized, 0 if not, 2 if memory allocated but not inited
USE_COUNT	EQU	tINITED+2		; number of times band is used (if 0, allocated memory may be freed)

; finally: the list of bands which must be drawn when a
; car is in this band. This list will usually be non-empty,
; since the band itself should be drawn!
; the list is 0 terminated

BND_LIST	EQU	USE_COUNT+2



;
; Flags used in polygon structures
; the first 12 bits of the "numsides" word for each polygon are flags, used as follows:
; 	(the "fXXX" macros are masks for or'ing; the "bXXX" macros are the corresponding bits
;	for btst)

fGLASS		EQU	$8000			; flag for transparent polygon
bGLASS		EQU	15

fTEXTURE	EQU	$4000			; flag for texture mapped polygon (?)
bTEXTURE	EQU	14

fFLASH		EQU	$2000			; flag for flashing objects (in general, this
bFLASH		EQU	13			; means the object's color must be computed)

fSPSURF		EQU	$1000			; flag for special surfaces
bSPSURF		EQU	12

mSPSURF		EQU	$0f00			; up to 16 special surfaces per model

fNOCOLLIDE	EQU	$0080			; object can't be collided with
bNOCOLLIDE	EQU	7

fNODRAW		EQU	$0040			; don't draw object
bNODRAW		EQU	6

;
; offsets for polygon special surface structure
; crash.gas assumes that this is 32 bytes long
;
PORTAL_BND	EQU	0			; band associated with a portal, or 0 if not a portal
PORTAL_X	EQU	PORTAL_BND+4
PORTAL_Y	EQU	PORTAL_X+4
PORTAL_Z	EQU	PORTAL_Y+4
SP_SOUND	EQU	PORTAL_Z+4
SURF_PROP	EQU	SP_SOUND+4
POWER_UP	EQU	SURF_PROP+4
PROTATE		EQU	POWER_UP+4		; sine and cosine of rotation angle for portal

;
; world startup structure
;
STARTP1		EQU	0			; player 1 starting band, x, y, z (4*4 bytes)
STARTH1		EQU	16			; player 1 starting angle (2 bytes)
STARTP2		EQU	18			; player 2 starting band, x, y, z (4*4 bytes)
STARTH2		EQU	34			; player 2 starting angle (2 bytes)
MSCALE		EQU	36			; map scale (y then x: 2*2 bytes)
MCENTER		EQU	40			; map center (y then x: 2*2 bytes)
STARTANIM	EQU	44			; pointer to animation function info, or 0
STARTDOTS	EQU	48			; 64 (band, x, y, z) quadruples for powerball locations
