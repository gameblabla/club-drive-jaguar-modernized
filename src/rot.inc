;- Rotation register defines ----------------------------------------------

; rotation matrix
m0		REGEQU	R0	; matrix[0]		| m0 m1 m2 |
m1		REGEQU	R1	; matrix[1]		| m3 m4 m5 |
m2		REGEQU	R2	; matrix[2]		| m6 m7 m8 |
m3		REGEQU	R3	; matrix[3]
m4		REGEQU	R4	; matrix[4]
m5		REGEQU	R5	; matrix[5]
m6		REGEQU	R6	; matrix[6]
m7		REGEQU	R7	; matrix[7]
m8		REGEQU	R8	; matrix[8]

xo		REGEQU	R9	; origin coords for translation
yo		REGEQU	R10
zo		REGEQU	R11

; computed data
resultX	REGEQU	R12
resultY	REGEQU	R13
resultZ	REGEQU	R14

; pointers
source	REGEQU	R15
dest		REGEQU	R16
dest2	REGEQU	R17
dest3	REGEQU	R18
numPnts	REGEQU	R19

x		REGEQU	R20	; original data
y		REGEQU	R21
z		REGEQU	R22

xaz		REGEQU	R20	; edge computed data
yaz		REGEQU	R21
ze		REGEQU	R22

rightSd	REGEQU	R23	; slopes of the edge of the view cone
bottomSd	REGEQU	R24

dataHi	REGEQU	R25
sectors	REGEQU	R26

;innerLoop	REGEQU	R27

;---------------------------------------------------------------------------

