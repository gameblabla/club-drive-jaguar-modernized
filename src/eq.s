	.include	"jaguar.inc"
	.include	"objlist.inc"
	.include	"blit.inc"
	.include	"joypad.inc"

;*********** VIDEO ***********************************************
vclk			equ	376

horiz_per		equ	317778
sync_per		equ	46050
eq_per		equ	23500
front_porch	equ	17450
line_blank	equ	109500
disp_width	equ	1306
disp_height	equ	240					;this is in lines
p_disp_height	equ	287					;this is in lines

; Horizontal computations

n_hp			equ	horiz_per/vclk
n_hbb		equ	((horiz_per-sync_per-front_porch)/vclk)+$400
n_hbe		equ	(line_blank-sync_per-front_porch)/vclk
n_hs			equ	((horiz_per-sync_per)/vclk)+$400
n_hvs		equ	(horiz_per-(2*sync_per))/vclk
n_heq		equ	(horiz_per-eq_per)/vclk
n_hde		equ	((disp_width/2)-1)+$400
n_hdb1		equ	((n_hp)-(disp_width/2))
n_hdb2		equ	n_hdb1

n_vp			equ	523
n_vee		equ	6
n_vbe		equ	40
n_vdb		equ	n_vbe-2
n_vde		equ	n_vdb+(disp_height*2)
n_vbb		equ	n_vde
n_vs			equ	n_vp-10
n_veb		equ	n_vs-n_vee

p_hdb1		equ	175
p_hdb2		equ	p_hdb1
p_hde		equ	((disp_width/2)-1)+$400
p_vdb		equ	35
p_vde		equ	611

N_SCRN_TOP	equ	n_vdb				;ypos of first line at top of screen
N_SCRN_BOTTOM	equ	n_vde				;xpos of first line below screen
P_SCRN_TOP	equ	p_vdb				;ypos of first line at top of screen
P_SCRN_BOTTOM	equ	p_vde				;xpos of first line below screen

SCRN_RIGHT	equ	320					;xpos of first pixel off right side of screen

;*******************************************************************

MAX_OBJS		equ	12					;this determines how much ram is reserved for the object lists

TITLE_OBJS	equ	5
;object with release flag on
;background
;car
;left half of stone letters
;right half of stone letters

SEL_OBJS		equ	12
;left half of background
;object with release flag on
;right half of background
;club drive sign
;sign
;bar on sign
;text on sign
;cover for sign rising
;cursor for music volume
;cursor for sound volume
;left half of stone letters
;right half of stone letters

CREDIT_OBJS	equ	8
;background
;7 credit strips

HISCORE_OBJS	equ	4
;background
;text
;cursor for player 1
;cursor for player 2

PLAY_OBJS	equ	8
;player1 screen
;player1 hud
;map
;dashboard
;player2 screen (only in split screen)
;player2 hud	(only in split screen)
;player1 hood	(only in 1 player)
;"pause" icon

LOAD_OBJS	equ	4
; map
; "start" icon
; "finish" icon
; text

;gamemode
TITLE_MODE		equ	0			;title screen
SELECT_MODE		equ	1
CREDITS_MODE		equ	2
HISCORE_MODE		equ	3
PLAY_MODE		equ	4

;levels
FUTURE_LEVEL		equ	0
SF_LEVEL			equ	1
WEST_LEVEL		equ	2
HOUSE_LEVEL		equ	3
SECRET_LEVEL		equ	4
SF2P_LEVEL		equ	5

;for uncomp GPU code
UNCOMP_PRG	equ	$F03400			;start of program
UNCOMP_START	equ	$F03FE8			;holds starting address of compressed data
UNCOMP_DEST	equ	$F03FEC			;holds destination address for uncompressed data
UNCOMP_END	equ	$F03FF0			;end address for uncompressed data
UNCOMP_DONE	equ	$F03FF4			;1 when uncomp is done

;adjblack program uses the last part of GPU ram that is not used by the DEJAG code
;adjblack gets loaded into the GPU once at the beginning of the program and stays there
ADJBLACK_PRG	equ	$F03F80			;start of program
ADJBLACK_START	equ	$F03FE8			;holds start address for adjblack
ADJBLACK_END	equ	$F03FEC			;holds end address for adjblack
ADJBLACK_DONE	equ	$F03FF0			;1 when adjblack is done

;for lighten GPU code
LIGHTEN_PRG	equ	$F03800			;start of program
LIGHTEN_START	equ	$F03FE8			;holds starting address of area to lighten
LIGHTEN_END	equ	$F03FEC			;end address for lightened data
LIGHTEN_DONE	equ	$F03FF0			;1 when lighten is done

;for crossfade GPU code
CROSS_PRG		equ	$F03000			;start of program
CROSS_PIC1	equ	$F03F00			;source pic 1
CROSS_PIC1_END	equ	$F03F04			;end of source pic 1
CROSS_PIC2	equ	$F03F08			;source pic 2
CROSS_CNT		equ	$F03F0C			;crossfade counter (0-16)
CROSS_DEST	equ	$F03F10			;where to write combined data
CROSS_DONE	equ	$F03F14			;1 when crossfade is done
MAX_CROSSCNT	equ	16

;for fade GPU code
FADE_PRG		equ	$F03800			;start of program
FADE_START	equ	$F03FE8			;holds starting address of area to fade
FADE_END		equ	$F03FEC			;end address for data
FADE_DEST		equ	$F03FF0			;where to write the new data
BRIGHTNESS	equ	$F03FF4			;brightness level (0-16)
FADE_DONE		equ	$F03FF8			;1 when fade is done
MAX_BRIGHT	equ	16

;dejag
DQ_Adr		equ	$F03E00			;The start of DQ??.ABS (Dequantize table)
In_Adr		equ	$F03F40			;Points to start of JAG data
Out_Adr		equ	$F03F44			;Points to start of output area
Dehuff_Adr	equ	$F03F48			;Points to start of DEHUFF.ABS
Out_Width		equ	$F03F4C			;Width of the output space in blocks
Out_E_Width	equ	$F03F50			;Encloded pixel width (#WID320 for example)
All_Done		equ	$F03F54			;Contains: 1-In progress $12345678-Done
dj_done		equ	$12345678			;All_Done is set to this when dejag is finished


;SOUND STUFF
;______________________________________________________________________________
;Tables are positioned every 80 bytes. The first long word of an entry is
;always the module type. A module type of zero indicates the end of the list.
;A module tpye of -4 is skipped.


TIMELEFT	equ	D_RAM+16+12
EFFBUFF         equ     $401000			; Used when there are effects
BUFFLEN         equ     $ffff			; Used when there are effects
STACKPOS        equ     D_RAM+16

OLDSYNTH	equ	1
.if OLDSYNTH
tablestart      equ     D_RAM+$C00
ENV_ADDR	equ	$F1C200
.else
tablestart	equ     D_RAM+$e00		; THE voice table
ENV_ADDR	equ	$F1C600
.endif

taboff          equ     20*4

WAVE_TECH		equ	ENV_ADDR		;512

ENV_CONGA0	equ	WAVE_TECH+512		;64

ENV_TECH0		equ	ENV_CONGA0+64		;64
ENV_TECH1		equ	ENV_TECH0+64		;64
ENV_TECH2		equ	ENV_TECH1+64		;64
ENV_TECH3		equ	ENV_TECH2+64		;32
ENV_TECH4		equ	ENV_TECH3+32		;64

ENV_GANG0		equ	ENV_TECH4+64		;32
ENV_GANG1		equ	ENV_GANG0+32		;32

ENV_REG0		equ	ENV_GANG1+32		;32
ENV_REG1		equ	ENV_REG0+32		;32

ENV_CW		equ	ENV_REG1+32		;32

MAX_VOICES	equ	8


MAX_SPEED		equ	300				;for engine sound
;MAX_SPEED		equ	200				;for engine sound (if max is about 60 mph)

;music (order must match the order in mus_info table in sound.s)
CONGA_MUSIC	equ	0
HONKY_MUSIC	equ	1
JAZZ_MUSIC	equ	2
TECHNO_MUSIC	equ	3
RAP_MUSIC		equ	4
REGGAE_MUSIC	equ	5
CLUBWAVE_MUSIC	equ	6
TOTAL_SONGS	equ	7

;sounds (all samples must be first)
WOO_SND		equ	0		; the first sound is always played
CRASH_SND		equ	1		; remaining sounds are listed in reverse order
FLUSH_SND		equ	2		; of priority; CRASH_SND should always be "1"
PIANO_SND		equ	3
MEOW_SND		equ	4
MOUSE_SND		equ	5
DOOR_SND		equ	6
OUCH_SND		equ	7
P1_YES_SND	equ	8		; the "YES" sounds must always come last
P2_YES_SND	equ	9

FIRST_FM		equ	10
FIRST_ENGINE	equ	FIRST_FM
ENGINE0		equ	FIRST_ENGINE
ENGINE1		equ	ENGINE0+1
ENGINE2		equ	ENGINE1+1
ENGINE3		equ	ENGINE2+1
ENGINE4		equ	ENGINE3+1
ENGINE5		equ	ENGINE4+1
LAST_ENGINE	equ	ENGINE5

RADIO_SND	equ	LAST_ENGINE+1
SKID_SND	equ	RADIO_SND+1
TOTAL_SOUNDS	equ	SKID_SND+1

PLAYER1_ENG_SOUND	equ	ENGINE0
PLAYER2_ENG_SOUND	equ	ENGINE0

; defines for voices
P1SNDV		equ	4
P2SNDV		equ	5
P1ENGV		equ	6
P2ENGV		equ	7

RADIO_STEPS		equ	26		;total frames for the sound for changing music

TOTAL_HI_SCORES	equ	5
HISCORE_DIGITS		equ	5


;eeprom stuff		64 words total
EE_HEADER			equ	0					;word 0
EE_PBSCORE_START	equ	1					;words 1-10 (5 scores)
EE_R0SCORE_START	equ	11					;words 11-20 (5 scores)
EE_R1SCORE_START	equ	21					;words 21-30 (5 scores)
EE_R2SCORE_START	equ	31					;words 31-40 (5 scores)
EE_R3SCORE_START	equ	41					;words 41-50 (5 scores)
EE_RSSCORE_START	equ	51					;words 51-60 (5 scores)
EE_CONTROL		equ	61					;word 61
EE_MVOLUME		equ	62					;word 62
EE_SVOLUME		equ	63					;word 63

DEFAULT_SPEED		equ	0					;default setting for speed_opt - car speed
MAX_OPTSPEED		equ	1					;maximum controller setting for speed_opt
DEFAULT_CONT		equ	0					;default controller setting for cont_opt
MAX_CONTROL		equ	5					;maximum controller setting for cont_opt
DEFAULT_ENGOPT		equ	0					;default steering setting for engoffopt
MAX_ENGOPT		equ	1					;maximum controller setting for engoffopt
DEFAULT_MVOL		equ	$7F					;default volume setting for mus_vol
DEFAULT_SVOL		equ	$7F					;default volume setting for snd_vol
MAX_VOLUME		equ	$7F					;maximum volume setting for mus_vol or snd_vol

;pal_ntsc settings
NTSC			equ	0
PAL			equ	1


;activities (for cur_act)
RACE1PLR			equ	0
RACE2PLR			equ	1
TAG2PLR			equ	2
COLL1PLR			equ	3
COLL2PLR			equ	4
MAX_ACTIVITIES		equ	5

CAR_WHITE			equ	0
CAR_YELLOW		equ	1
CAR_RED			equ	2
CAR_BLUE			equ	3
CAR_CYAN			equ	4
CAR_GREEN			equ	5
MAX_CAR_TYPES		equ	6			;total number of different cars

;modem stuff
MDM_NONE	equ	0			;no modem at all
MDM_CALL	equ	1			;we're the caller
MDM_ANSW	equ	2			;we're the callee

;default settings
DEF_ACTIVITY		equ	COLL1PLR		;default activity

DEF_CAR0			equ	CAR_YELLOW	;default car for player 1
DEF_CAR1			equ	CAR_RED		;default car for player 2

DEF_LAPS			equ	1			;default laps for 1 or 2 player racing
DEF_TAGTIME		equ	1			;default time for 2 player tag
DEF_TAGTUNE1		equ	HONKY_MUSIC	;default tag tune for player 1
DEF_TAGTUNE2		equ	JAZZ_MUSIC	;default tag tune for player 2
DEF_COLLTIME		equ	1			;default time for 1 player collect
DEF_DOTS			equ	1			;default dots for 2 player collect

DEF_LEVEL		equ	HOUSE_LEVEL		;default world to play in

DEF_MDM			equ	MDM_NONE

MIN_LAPS			equ	0			;minimum laps for 1 or 2 player racing
MAX_LAPS			equ	5			;maximum laps for 1 or 2 player racing
MIN_TAGTIME		equ	0			;minimum time for 2 player tag
MAX_TAGTIME		equ	4			;maximum time for 2 player tag
MIN_COLLTIME		equ	0			;minimum time for 1 player collect
MAX_COLLTIME		equ	4			;maximum time for 1 player collect
MIN_DOTS			equ	0			;minimum dots for 2 player collect
MAX_DOTS			equ	4			;maximum dots for 2 player collect

MAX_RANK	equ	15			;maximum rank for rankplr0 or rankplr1

; defines for gpu_do flags
; bit 0: do the rendering calculations
; bit 1: draw score, time, and map position
; bit 2: update score
; bit 3: do collision detection and drive

GPU_DO_NORMAL	equ	$f			; do all of the above
GPU_DO_REWIND	equ	$3			; don't do score or collision detection
GPU_DO_REMOTE	equ	$2			; only draw score
GPU_DO_END	equ	$2			; only draw score
GPU_DO_REPLAY	equ	$1			; only draw -- no score calculations

;***************************************************************************
; Jaguar UART registers and bits
;
;***************************************************************************

u_clk		equ	$f10034
u_ctrl		equ	$f10032
u_stat		equ	$f10032
u_data		equ	$f10030
u_err		equ	15
u_rbf		equ	7
u_tbe		equ	8
ctl_init	equ	%100001		; First stop bit = ODD
					; Txd Start bit = 1 (inverted)
					; Rxd non inverted
					; No parity, receiver ints
					;
clrerr		equ	$0040		; clear errors

PCLK		equ	26593900	; CPU clock (good enough for PAL/NTSC)
UCLK_57600	equ	28  ;((PCLK/(16*57600))-1)	; value for 57600 baud
UCLK_19200	equ	86  ;((PCLK/(16*19200))-1)	;value for 19,200 baud

;Phylon modem specific stuff

;Commands

M_RESET		equ	$ffff
M_SPKRLOW	equ	$0102
M_SPKROFF	equ	$0002
M_CONFG1	equ	$2c80	;$2c00
M_OFFHK		equ	$a060
M_SHAKE		equ	$8000
M_HSTATUS	equ	$8100
M_TXDATA	equ	$f000
M_DIALD		equ	$8a20	; 8a2n
M_DTDET		equ	$8c01	; Dial tone detect

;Responses

M_TESTOK	equ	$b800
M_HDONE		equ	$8600
M_RXDATA	equ	$f0

;size of buffer for modem; 15 bytes/packet, 60 packets/sec -> 900 bytes/sec
;make this odd so that an even number of bytes fits in it
MDM_BUFSIZ	equ	2049


; Error codes - these encode the high half of the longword response.  There
; will generally be additional information encoded in the low word.  Note
; that non-error cases also return information in the low word, with a zero
; in the high word.

MDM_ERR_NONE		equ $00000000
MDM_ERR_GENERAL		equ $ffff0000
MDM_ERR_HS_TIMEOUT	equ $fffe0000
MDM_ERR_DEAD		equ $fffd0000
MDM_ERR_TX_TIMEOUT	equ $fffc0000
MDM_ERR_CMD_REPLY	equ $fffb0000
MDM_ERR_UNX_PKT		equ $fffa0000
MDM_ERR_DIAL		equ $fff90000
MDM_ERR_NO_TONE		equ $fff80000
MDM_ERR_CHECKSUM	equ $fff70000
MDM_ERR_BAD_SELFTEST	equ $fff60000
MDM_ERR_PHASE_F3	equ $fff50000
MDM_ERR_CALL_WAITING	equ $fff40000
MDM_ERR_LOST_LINE	equ $fff30000
MDM_ERR_PHASE_F0	equ $fff20000
MDM_ERR_WRONG_TONE	equ $fff10000
MDM_ERR_USER_HANGUP	equ $fff00000
MDM_ERR_HANDSHAKE	equ $ffef0000
MDM_ERR_SYNC		equ $ffee0000
MDM_ERR_UNX_COMM	equ $ffed0000
MDM_ERR_UNX_NONCOMM	equ $ffec0000

