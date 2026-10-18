;------------------------------------------------------------------
; car.inc
;	defines structures for car
;	all addresses are relative
;------------------------------------------------------------------

CAR_POSN		equ	0										; x, y, z longwords of position
CAR_MATRIX	equ	12										; 3x3 matrix of words
CAR_VELOCITY	equ	(( CAR_MATRIX + 18			+ 3) & $fffffffc)	; vx, vy, vz longwords
CAR_OMEGA		equ	CAR_VELOCITY + 12				; wx, wy, wz longwords - rotational velocity
CAR_SPIN		equ	CAR_OMEGA + 12					; total absolute value of CAR_OMEGA since last time all wheels in contact
CAR_FORCE		equ	CAR_SPIN + 4					; 
CAR_TORQUE	equ	CAR_FORCE + 12					; CAR_TORQUE must immediately follow CAR_FORCE
CAR_POSNS		equ	CAR_TORQUE + 12				; x, y, z words of the 20 control points on the car
	CAR_NUM_PNTS	equ	38						; number of control points on a car
CAR_SHOCKS	equ	(( CAR_POSNS + (CAR_NUM_PNTS*6)+ 3) & $fffffffc)	; position of suspension extention for use in shock dampening
CAR_OSHOCKS	equ	CAR_SHOCKS + 16						; position of suspension extention for use in shock dampening
CAR_TIRE_SPD	equ	CAR_OSHOCKS + 16						; last known speed of wheel
CAR_SLIDE		equ	CAR_TIRE_SPD + 16				; some quantity of skid
CAR_SURFDATA	equ	CAR_SLIDE + 16					; floor properties for various wheels
CAR_CTRL		equ	CAR_SURFDATA + 16				; joystick bits
CAR_TURN		equ	CAR_CTRL + 4					; amount to rotate front tire
CAR_GAS		equ	CAR_TURN + 2					; amount of thrust
CAR_GEAR		equ	CAR_TURN + 4					; state of car's transmission
CAR_SKD_VCE	equ	CAR_GEAR + 4					; voice number of the car's skid sound

CAR_HEAD		equ	CAR_SKD_VCE + 4					; angle of car heading (beta)
CAR_ANGLE		equ	CAR_HEAD + 4					; other angles (alpha, gamma)
MAP_POS			equ	CAR_ANGLE + 4					; position of car on map

CAR_MODEL		equ	MAP_POS + 4					; pointer to car 3d model
FLOOR_MODEL		equ	CAR_MODEL+4					; pointer to band the car is in
NEW_FLOOR		equ	FLOOR_MODEL+4					; pointer to the band the car is going to be in
; the next 4 things must go together
CUR_PORTAL		equ	NEW_FLOOR+4					; current portal by which to teleport
CUR_SOUND		equ	CUR_PORTAL + 4					; sound to make when crashing
SND_VOL			equ	CUR_SOUND+4					;	volume for sound
SND_POS			equ	SND_VOL+4					;	position for sound ($7fff = left, 0 = right)

GAME_DATA		equ	SND_POS + 4					; data for game play (16 bits)
QTIME			equ	GAME_DATA + 2					; timer for playback/record
CAR_TOTFRAME		equ	QTIME + 2					; time stamp at beginning of ani cycle (value of intCount)
CAR_FRAME		equ	CAR_TOTFRAME + 4				; time for this frame
CAR_TIMER		equ	CAR_FRAME + 4					; value to display in "time" field of dashboard
WAIT_TIME		equ	CAR_TIMER + 4					; time to wait for some event
SCORE			equ	WAIT_TIME + 4					; timer ticks or spot total
PRV_SCORE		equ	SCORE + 4					; td.s assumes SCORE, PRV_SCORE, and SCOREPIX
SCOREPIX		equ	PRV_SCORE + 4					;   all come together
TIMERPIX		equ	SCOREPIX+4

QSTART			equ	TIMERPIX+4					; start of playback queue
QEND			equ	QSTART+4
QHEAD			equ	QEND+4						; pointer within playback queue
QTAIL			equ	QHEAD+4						; pointer within playback queue
QPLAY			equ	QTAIL+4						; position of playback head
QREC			equ	QPLAY+4						; position of record head

NEW_CAMERA		equ	QREC+4						; band the camera is going to be in next frame
CAMERA_MODEL		equ	NEW_CAMERA+4					; band the camera is currently in
CAMERA_POSN		equ	CAMERA_MODEL+4					; X,Y,Z (32 bits) for camera position
CAMERA_MATRIX		equ	CAMERA_POSN+12					; viewing matrix for camera
CAMERA_FLAG		equ	CAMERA_MATRIX+18				; what kind of camera to use
CAMERA_TURN		equ	CAMERA_FLAG+2					; angle to turn camera in X-Z plane

CAMLIST_BEG		equ	CAMERA_TURN+4					; start of camera list
CAMLIST_END		equ	CAMLIST_BEG+4					; end of camera list
CAMLIST_POS		equ	CAMLIST_END+4					; current position in camera list

PORTAL_ROT		equ	CAMLIST_POS+4					; rotation imposed by portal
AUTO_REW		equ	PORTAL_ROT+4					; automatic rewind is in effect
CAR_DOWN		equ	AUTO_REW + 4
CAR_QUEUE		equ	CAR_DOWN + 4					;player input queue

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
CAR_DS_SIZE	equ	CAR_QUEUE + (32*4) + 4						; it takes this many bytes
CAR_RADIUS	equ	$4000									; all points of the car are closer to the car center than this

QENTRYSIZ		equ	30		; 12 bytes for matrix, 4 for band, 12 for position, 2 for game data
QNUMENTRY		equ	1000		; number of entries in playback queue
QUANTUM			equ	30		; number of 300ths per recorder entry

