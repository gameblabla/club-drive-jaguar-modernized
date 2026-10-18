	.include	'eq.s'
	.include	'externs.s'

	.bss
startbss::
;the address of olist must be on a 16 byte boundary
;each bit mapped object is 2 phrases (16 bytes)
;object is built in olist_ram, then copied into olistbld
stopobj::		ds.l	2					;2 longs for a stop object used by the 2 branch objects
			ds.l	2					;to make olist quad phrase aligned
olist::
branch0::		ds.l	2					;branch to stopobj if YPOS > vde
branch1::		ds.l	2					;branch to stopobj if YPOS < vdb
olistbld::	ds.l	(8*MAX_OBJS)			;8 longs for each bit mapped object
			ds.l	2					;2 longs for a stop object
olist_ram::	ds.l	(8*MAX_OBJS)			;8 longs for each bit mapped object
			ds.l	2					;2 longs for a stop object
;---------------------------------------

musicst::		ds.b	23000				;place for music score
patchst::		ds.b	1200					;place for voice tables used in music (80 bytes each)

	.phrase
.if 0
coverdta::	ds.b	2304					;8 x 288 screen cover
.else
coverdta::	ds.l	2					; 1 phrase
.endif
maskram::		ds.b	3072					;big enough for 256*96 (/8) mask

strt8bit::
copyrt::		ds.b	2688					;192 x 7, 16 bit	copyright 1994 Atari Corporation
car0icn::		ds.b	144					; 24 x 6			icons for select screen billboard
car1icn::		ds.b	144					; 24 x 6
car2icn::		ds.b	144					; 24 x 6
car3icn::		ds.b	144					; 24 x 6
car4icn::		ds.b	144					; 24 x 6
car5icn::		ds.b	144					; 24 x 6
curs0dta::	ds.b	104					;  8 x 13			cursor for editing high score names for player 1
curs1dta::	ds.b	104					;  8 x 13			cursor for editing high score names for player 2
volcdata::	ds.b	56					;  8 x 7			cursor for music and sound volume
selbar::		ds.b	264					;192 x 11, 1 bit	bar for select screen
rankbox::		ds.b	4608					; 96 x 24, 16 bit	box that rank is displayed in
fnt_a::		ds.b	56					;  8 x 7			font for select screen
fnt_b::		ds.b	56
fnt_c::		ds.b	56
fnt_d::		ds.b	56
fnt_e::		ds.b	56
fnt_f::		ds.b	56
fnt_g::		ds.b	56
fnt_h::		ds.b	56
fnt_i::		ds.b	56
fnt_j::		ds.b	56
fnt_k::		ds.b	56
fnt_l::		ds.b	56
fnt_m::		ds.b	56
fnt_n::		ds.b	56
fnt_o::		ds.b	56
fnt_p::		ds.b	56
fnt_q::		ds.b	56
fnt_r::		ds.b	56
fnt_s::		ds.b	56
fnt_t::		ds.b	56
fnt_u::		ds.b	56
fnt_v::		ds.b	56
fnt_w::		ds.b	56
fnt_x::		ds.b	56
fnt_y::		ds.b	56
fnt_z::		ds.b	56
fnt_com::		ds.b	56
fnt_per::		ds.b	56
fnt_col::		ds.b	56
fnt_sp::		ds.b	56
fnt_apos::	ds.b	56
num0::		ds.b	56
num1::		ds.b	56
num2::		ds.b	56
num3::		ds.b	56
num4::		ds.b	56
num5::		ds.b	56
num6::		ds.b	56
num7::		ds.b	56
num8::		ds.b	56
num9::		ds.b	56
f16_a::		ds.b	112					;  8 x 7			16 bit font
f16_b::		ds.b	112
f16_c::		ds.b	112
f16_d::		ds.b	112
f16_e::		ds.b	112
f16_f::		ds.b	112
f16_g::		ds.b	112
f16_h::		ds.b	112
f16_i::		ds.b	112
f16_j::		ds.b	112
f16_k::		ds.b	112
f16_l::		ds.b	112
f16_m::		ds.b	112
f16_n::		ds.b	112
f16_o::		ds.b	112
f16_p::		ds.b	112
f16_q::		ds.b	112
f16_r::		ds.b	112
f16_s::		ds.b	112
f16_t::		ds.b	112
f16_u::		ds.b	112
f16_v::		ds.b	112
f16_w::		ds.b	112
f16_x::		ds.b	112
f16_y::		ds.b	112
f16_z::		ds.b	112
f16_com::		ds.b	112
f16_per::		ds.b	112
f16_col::		ds.b	112
f16_sp::		ds.b	112
f16_apos::	ds.b	112
num16_0::		ds.b	112
num16_1::		ds.b	112
num16_2::		ds.b	112
num16_3::		ds.b	112
num16_4::		ds.b	112
num16_5::		ds.b	112
num16_6::		ds.b	112
num16_7::		ds.b	112
num16_8::		ds.b	112
num16_9::		ds.b	112
let_A::		ds.b	(16*14)				;font for credits (upper case)
let_B::		ds.b	(16*14)
let_C::		ds.b	(16*15)
let_D::		ds.b	(16*14)
let_E::		ds.b	(16*14)
let_F::		ds.b	(16*14)
let_G::		ds.b	(16*15)
let_H::		ds.b	(16*14)
let_I::		ds.b	(8*14)
let_J::		ds.b	(16*15)
let_K::		ds.b	(16*14)
let_L::		ds.b	(16*14)
let_M::		ds.b	(16*14)
let_N::		ds.b	(16*14)
let_O::		ds.b	(16*15)
let_P::		ds.b	(16*14)
let_Q::		ds.b	(16*15)
let_R::		ds.b	(16*14)
let_S::		ds.b	(16*15)
let_T::		ds.b	(16*14)
let_U::		ds.b	(16*15)
let_V::		ds.b	(16*14)
let_W::		ds.b	(16*14)
let_X::		ds.b	(16*14)
let_Y::		ds.b	(16*14)
let_Z::		ds.b	(16*14)
let_a::		ds.b	(16*15)				;font for credits (lower case)
let_b::		ds.b	(16*15)
let_c::		ds.b	(16*15)
let_d::		ds.b	(16*15)
let_e::		ds.b	(16*15)
let_f::		ds.b	(8*14)
let_g::		ds.b	(16*18)
let_h::		ds.b	(16*14)
let_i::		ds.b	(8*14)
let_j::		ds.b	(8*18)
let_k::		ds.b	(16*14)
let_l::		ds.b	(8*14)
let_m::		ds.b	(16*14)
let_n::		ds.b	(16*14)
let_o::		ds.b	(16*15)
let_p::		ds.b	(16*18)
let_q::		ds.b	(16*18)
let_r::		ds.b	(8*14)
let_s::		ds.b	(16*15)
let_t::		ds.b	(8*15)
let_u::		ds.b	(16*15)
let_v::		ds.b	(16*14)
let_w::		ds.b	(16*14)
let_x::		ds.b	(16*14)
let_y::		ds.b	(16*18)
let_z::		ds.b	(16*14)
let_per::		ds.b	(8*14)

;during game
digitfont::	ds.b	184
cmpssfont::	ds.b	128
speedfont::	ds.b	576
tnyfont::		ds.b	96
car1_ram::	ds.b	4096
car2_ram::	ds.b	4096
dash::		ds.b	(320*30)
car_dat::		ds.b	(40*6)



		.phrase
gpram::		ds.b	512				; memory for 3d.bin
bgpram::		ds.b	4096				; memory for 3dbeg.bin
cgpram::		ds.b	4096				; memory for comp.bin
rgpram::		ds.b	4096				; memory for ren.bin
egpram::		ds.b	4096				; memory for 3dend.bin
pcram::		ds.b	4096				; memory for precomp.bin
prram::		ds.b	2048				; memory for preren.bin
stackspace::	ds.b	4096
stacktop::	ds.b	2
ramend::							; must be below $20000

STKSIZ		=	4096

mapWorld		==	$80000
startWorld	==	mapWorld+(96*24*2)

PWRBALL		==	startWorld+540000		; leave enough room for largest arena
TPNTADDR	==	PWRBALL+200000			; storage for tPNTS arrays
TPNTEND		==	TPNTADDR+196000			; NOTE: TPNTADDR-mapWorld must give room for largest world

;
; the load screen stuff can share the TPNTs array, since those aren't used until after the loading is finished
;
STARTICON	==	TPNTADDR
FINISHICON	==	STARTICON+(64*64*2)		; must follow STARTICON
olist_l1	==	FINISHICON+(64*64*2)
olist_l2	==	olist_l1+(32*MAX_OBJS)
olist_l3	==	olist_l2+(32*MAX_OBJS)
olist_l4	==	olist_l3+(32*MAX_OBJS)
olist_l5	==	olist_l4+(32*MAX_OBJS)
olist_l6	==	olist_l5+(32*MAX_OBJS)
olist_l7	==	olist_l6+(32*MAX_OBJS)
olist_l8	==	olist_l7+(32*MAX_OBJS)
ldtext		==	olist_l8+(32*MAX_OBJS)

yourit		==	TPNTEND
youwin		==	yourit+4096
SKY		==	youwin+4096
_end		==	SKY+200000			; space for an 800x125 bitmap

_slide		==	$1f7000			; temp storage for unzip code

.if 0
ramstart::	ds.b	1900000
.else
ramstart == $20000
.endif

;TITLE SCREEN
backgr0	==	ramstart					; 258048			448 * 288
backgr1	==	backgr0+(448*288*2)			; 258048			448 * 288
									; 516096	 516096
titlescr	==	backgr1+(448*288*2)			; 258048			448 * 288
stonedta	==	titlescr+(448*288*2)		; 258048			448 * 288
tcardta	==	stonedta+(448*288*2)		;  36864			256 *  72
									; 552960	1069056
selscr	==	tcardta+(256*72*2)			; 258048	1327104		448 * 288
futdta	==	selscr+(448*288*2)			;  30016			224 *  67
sfdta	==	futdta+(224*67*2)			;  43392			192 * 113
wstdta	==	sfdta+(192*113*2)			;  40768			224 *  91
housdta	==	wstdta+(224*91*2)			;  49152			256 *  96
hmskdta	==	housdta+(256*96*2)			;  20160			224 *  45		covers bottom of sign as sign rises
clubdta	==	hmskdta+(224*45*2)			;  25600			160 *  80
selsign	==	clubdta+(160*80*2)			;  36864			192 *  96
seltext	==	selsign+(192*96*2)			;  14592			192 *  76		8 bit
seltexta	==	seltext+(192*76)			;  14592			192 *  76		8 bit
ltnbufr	==	seltexta+(192*76)			;  49152			big enough for biggest map piece
									; 582336	1651392

									;		1327104
credscr	==	futdta					; 258048			448 * 288
credsgn0	==	credscr+(448*288*2)			;   2784			 32 *  87	8 bit
credsgn1	==	credsgn0+(32*87)			;   2784			 32 *  87	8 bit
credsgn2	==	credsgn1+(32*87)			;   2784			 32 *  87	8 bit
credsgn3	==	credsgn2+(32*87)			;   2784			 32 *  87	8 bit
credsgn4	==	credsgn3+(32*87)			;   2784			 32 *  87	8 bit
credsgn5	==	credsgn4+(32*87)			;   2784			 32 *  87	8 bit
credsgn6	==	credsgn5+(32*87)			;   2784			 32 *  87	8 bit
credtext	==	credsgn6+(32*87)			;  19488			224 *  87	8 bit
									;  38976	1624128
hitxtdta	==	credtext+(224*87)			;  19488			224 *  87
									;		1643616

;OBJECT HEADERS
scrcover::		ds.b	OBJ_SIZE			;screen cover

ldscrobj::		ds.b	OBJ_SIZE
ld_start::		ds.b	OBJ_SIZE
ld_finish::		ds.b	OBJ_SIZE
ld_text::		ds.b	OBJ_SIZE

;Title screen
titlobjs::
t_scr_m::			ds.b	OBJ_SIZE			;object with release flag on
t_scr::			ds.b	OBJ_SIZE			;title screen background
t_car::			ds.b	OBJ_SIZE			;car
t_sign_l::		ds.b	OBJ_SIZE			;left half of club drive letters
t_sign_r::		ds.b	OBJ_SIZE			;right half of stone club drive letters

selobjs::
s_scr_l::			ds.b	OBJ_SIZE			;left side of select screen background
s_scr_m::			ds.b	OBJ_SIZE			;object with release on
s_scr_r::			ds.b	OBJ_SIZE			;right side of select screen background
s_club::			ds.b	OBJ_SIZE			;club drive sign
s_sign::			ds.b	OBJ_SIZE			;billboard
s_bar::			ds.b	OBJ_SIZE			;frame around current selection on sign
s_text::			ds.b	OBJ_SIZE			;text that goes on billboard
s_mask::			ds.b	OBJ_SIZE			;covers billboard as it rises
mvolcurs::		ds.b	OBJ_SIZE			;shows current music volume level
svolcurs::		ds.b	OBJ_SIZE			;shows current sound volume level
s_sign_l::		ds.b	OBJ_SIZE			;left half of club drive letters
s_sign_r::		ds.b	OBJ_SIZE			;right half of stone club drive letters

credobjs::
c_scr::			ds.b	OBJ_SIZE			;billboard screen background
c_sign0::			ds.b	OBJ_SIZE			;text pieces
c_sign1::			ds.b	OBJ_SIZE
c_sign2::			ds.b	OBJ_SIZE
c_sign3::			ds.b	OBJ_SIZE
c_sign4::			ds.b	OBJ_SIZE
c_sign5::			ds.b	OBJ_SIZE
c_sign6::			ds.b	OBJ_SIZE

highobjs::
h_scr::			ds.b	OBJ_SIZE			;billboard screen
h_text::			ds.b	OBJ_SIZE			;high score info
cursor0::			ds.b	OBJ_SIZE			;cursor for player 1
cursor1::			ds.b	OBJ_SIZE			;cursor for player 2

playobjs::
p1_scr::			ds.b	OBJ_SIZE			; player 1 screen
p1_hood::			ds.b	OBJ_SIZE			; player 1 hood
p1_hud::			ds.b	OBJ_SIZE			; player 1 HUD
map_scr::			ds.b	OBJ_SIZE			; map
bar_scr::			ds.b	OBJ_SIZE			; dashboard
p2_scr::			ds.b	OBJ_SIZE			; player 2 screen
p2_hud::			ds.b	OBJ_SIZE			; player 2 HUD
pause_scr::			ds.b	OBJ_SIZE			; pause icon

	.long
seed::			ds.l 6				;6 seeds for random numbers

joyedge::			ds.l	1				;used by readpad for input
joycur::			ds.l	1				;used by readpad for input
joybothe::		ds.l	1				;joyedge for both players combined
joybothc::		ds.l	1				;joycur for both players combined

joyedge2::		ds.l	1				;controller 2
joycur2::			ds.l	1				;controller 2

anajoy1::			ds.l	1				;used by steering wheel input
anajoy2::			ds.l	1				;used by steering wheel input

joyeacc::			ds.l	1				;edge accumulator stuf
joyehold::		ds.l	1				;
joyeacc2::		ds.l	1				;edge accumulator 2
joyehol2::		ds.l	1				;
joyesem::			ds.b	1				;
stufqueue::		ds.b 1				;bool for interupt routine to call push_joypad
	.even

gamemode::		ds.w	1				;title, select, game, congrats, etc
oldgmode::		ds.w	1				;previous gamemode setting

showcoord::		ds.b	1				;1 if we should use the HUD for debugging
debugflg::		ds.b	1				;special debugging flag, normally 0
muteflag::		ds.b	1				;0 music on, 1 music off
keepmus::		ds.b	1				;1 if title screen music should not restart after a jump to 'restart'
gmovrhs::		ds.b	1				;flag for hiscores: 0 = normal hiscore, 1 = hiscore on "game over" screen

	.even
mus_vol::			ds.w	1				;volume level for music
jpit2val::		ds.w	1				;JPIT2 value for current music (for mute)
songnum::			ds.l	1				;current music
snd_vol::			ds.w	1				;volume level for sound
soundvol::		ds.l	TOTAL_SOUNDS		;adjusted volume for each sound
radiocnt::		ds.w	1				;counter for the sound for changing music

cont_opt::		ds.w	1				;controller option
steeropt::		ds.w	1				;steering option
speedopt::		ds.w	1				;speed option
speedvar::		ds.w	1				;speed multiplier
engoffopt::		ds.w	1				;flag for engine sounds (0=on, 1=off)

titlestp::		ds.w	1				;title screen animation counter
tcaryend::		ds.w	1				;end ypos for title screen car
bright::			ds.l	1				;brightness level for fade
crosscnt::		ds.l	1				;counter for cross fade
loadsdn::			ds.w	1				;flag for when all background screens have been loaded

scrlbytes::		ds.b	24				; scrolling text on billboard
			.even
scrollstr::		ds.l	1				; string that's being scrolled
scrollpos::		ds.w	1				; position in scrolling string
scrolloff::		ds.w	1				; offset for blit of scrolling string

curlevel::		ds.w	1				;current level (determines which map piece is selected)
cur_act::			ds.w	1				;currently selected activity
cur_car0::		ds.w	1				;currently selected type of car for player 1
cur_car1::		ds.w	1				;currently selected type of car for player 2
bar_pos::			ds.w	1				;which line of text is selected on sign
menuflag::		ds.b	1				;0 if on main menu, 1 if changing activity, 2 if changing options
signmove::		ds.b	1				;0 if not moving, 1 if moving up, 2 if moving down
	.even
rac1laps::		ds.w	1				;laps for 1 player racing
rac2laps::		ds.w	1				;laps for 2 player racing
tagtime::			ds.w	1				;time for 2 player tag
tagtune0::		ds.w	1				;tag tune for player 1
tagtune1::		ds.w	1				;tag tune for player 2
col1dots::		ds.w	1				;dots for 1 player collect
col2dots::		ds.w	1				;dots for 2 player collect
num_dec::			ds.b	4				;decimal digits for lap,time,dots options
joydelay::		ds.b	6				;joypad delay counter for select screen (main, activity, setting, tunes, steering, controls)
	.even

ctxtcnt::			ds.w	1				;counter for changing billboard text
ctxtnum::			ds.w	1				;which billboard text is being displayed

prevscr0::		ds.l	1				;score from last game for player 1
prevscr1::		ds.l	1				;score from last game for player 2
rankplr0::		ds.w	1				;ranking for player 1
rankplr1::		ds.w	1				;ranking for player 2
hilstptr::		ds.l	1				;holds address of list of top scores being used
htxtcnt::			ds.w	1				;counter for changing high score info
htxtnum::			ds.w	1				;which high score info is being displayed
showrank::		ds.w	1				;1 if rank should be displayed after a game
gothiscore::		ds.b	1				;1 if we got a high score

high_dec::		ds.b	HISCORE_DIGITS+2	;one byte for each character	XX:XX.X
	.even
pbhighs::			ds.l	TOTAL_HI_SCORES*2	;1 long for score, 1 long for name
pbtemp::			ds.l	2				;temporary score and name for sorting
rac0high::		ds.l	TOTAL_HI_SCORES*2	;1 long for score, 1 long for name
rac0temp::		ds.l	2				;temporary score and name for sorting
rac1high::		ds.l	TOTAL_HI_SCORES*2	;1 long for score, 1 long for name
rac1temp::		ds.l	2				;temporary score and name for sorting
rac2high::		ds.l	TOTAL_HI_SCORES*2	;1 long for score, 1 long for name
rac2temp::		ds.l	2				;temporary score and name for sorting
rac3high::		ds.l	TOTAL_HI_SCORES*2	;1 long for score, 1 long for name
rac3temp::		ds.l	2				;temporary score and name for sorting
racShigh::		ds.l	TOTAL_HI_SCORES*2	;1 long for score, 1 long for name
racStemp::		ds.l	2				;temporary score and name for sorting
curs0col::		ds.w	1				;current column for player 1 high score name cursor
curs0row::		ds.w	1				;current row for player 1 high score name cursor
curs1col::		ds.w	1				;current column for player 2 high score name cursor
curs1row::		ds.w	1				;current row for player 2 high score name cursor
highedit::		ds.b	1				;0 if not in editing mode, bit 0 set for for player 1, bit 1 set for player 2
joydel0::			ds.b	1				;counter for holding down joypad to change high score name for player 1
joydel1::			ds.b	1				;counter for holding down joypad to change high score name for player 2

pal_ntsc::		ds.b	1				;0 if NTSC, 1 if PAL
	.even

; stuff for the "play" interrupt routine
		.phrase
olist_sec::	ds.l	(8*MAX_OBJS)
		ds.l	2					; 2 longs for a stop object
olist_pau::	ds.l	(8*MAX_OBJS)
		ds.l	2					; 2 longs for a stop object
olist_stp::
		ds.l	2					; just a stop object

listgood::	ds.w	1					; flag: 1 == listAddr is valid
		.long
listAddr:: 	ds.l 	1 		; address of current non munged object list
timestamp::	ds.l	1 		; time stamp - updated each vInt by fTime
packtime::	ds.l	1		; time last packet was sent
fTime::		ds.w	1 		; number of 300th/s in a frame (5 for NTSC;6 for PAL)
buffNum::	ds.w	1
buffShn::	ds.w	1
playspd::	ds.w	1		; speed (in 300ths) of playback at end of game
leftx::		ds.w	1		; x coordinate for right side of screen (0 for NTSC, 4 for PAL)
topy::		ds.w	1		; y coordinate offset for top of screen (0 for NTSC,44 for PAL)

		.phrase
dotloc::	ds.l	4		; location of current dot for crash and score game: band,x,y,z
dotimg::	ds.l	1		; (pointer to) image of powerball
scoreMax::	ds.w	1		; maximum possible score (currently, always 60)
twoplayer::	ds.w	1		; flag: 0 = one player, 1 = two players
splitscreen::	ds.w	1		; flag: 0 = 1 large screen, 1 = split screen
gametype::	ds.w	1		; type of game
gameover::	ds.w	1		; flag for game over
winner::	ds.l	1		;which player won a 2 player race (will contain PLAYER1 or PLAYER2)

		.long
screen_addr::	ds.l	1		; current drawing address for GPU functions
last_screen::	ds.l	1		; last screen drawn by the GPU
mapscale::	ds.l	1		; Y (high word) and X scaling factors (as 0.15 fractions) for current map
maporig::	ds.l	1		; Y and X origin for drawing map
scoreinc::	ds.l	1		; score increment: add this to score when something good happens

player::	ds.l	1		; address of current player's structure
itCar::		ds.l	1
waitTime::	ds.w	1		; must follow itCar
lastItCar::	ds.l	1
itHUD::		ds.l	1
changeIT::	ds.w	1
chkPlayer::	ds.l	1

gpu_do::	ds.w	1		; what should the GPU do this frame?
framedone::	ds.w	1

alpha::		ds.w	1
beta::		ds.w	1
gamma::		ds.w	1

_outptr::	ds.l	1
_inptr::	ds.l	1

car1clr::	ds.w	1
car2clr::	ds.w	1

modem::		ds.w	1		; is there a modem connected?
curpacket::	ds.l	1		; current packet received from other machine

fps::		ds.w	1
framecnt::	ds.w	1

		.long
animprog::	ds.l	1	; GPU function for doing animation, or NULL
animparam::	ds.l	1	; parameter for above function
animinit::	ds.l	1	; 68K initialization routine for animation

worldsky::	ds.l	1	; sky for this world
mbands::	ds.l	6	; space for 2 moving bands and a null tag
hoodptr::	ds.l	1	; pointer to storage for hood (1 player game)

cur_voice_snd::	ds.l	8	; what sound is being played in what voice

SKYHIGH::	ds.l	1	; where to put the sky relative to the screen
SEALEVEL::	ds.l	1	; where the sea level is for this world

lasttime::	ds.l	1	; storage for event timer (e.g. flashing "REWIND" sign)

_MDMin::	ds.b	2+2+MDM_BUFSIZ
		.even
_MDMcnt::	ds.w	1
_MDMdrop::	ds.l	1
_MDMerr::	ds.l	1
_MDMferr::	ds.l	1
_MDMperr::	ds.l	1
_MDMoerr::	ds.l	1
_MDMrec::	ds.l	1

		.even
	.text

looptable::		dc.l	titleloop,selloop,credloop,highloop,playloop

;table for loading compressed graphics
;address of compressed data, destination address, width/8, width for blitter
titlebkg::
	dc.l		titlebk,	titlescr,		56,	WID448		;title screen background
ttlmore::
	dc.l		rokltrs,	stonedta,		56,	WID448		;stone club drive letters
seldcm::
	dc.l		seamap,	selscr,		56,	WID448		;select screen background
seldcm1::
	dc.l		mp_club,	clubdta,		20,	WID160		;club drive sign
	dc.l		mp_bill,	selsign,		24,	WID192		;billboard
credbkg::
	dc.l		credits,	credscr,		56,	WID448		;credits screen background

;table for loading masks
;A1_BASE				destination address
;width for blitter
;B_COUNT				height, width
;UNCOMP_START			address of compressed mask
;size of mask in bytes	(height * width / 8)
msk_sel::
	dc.l		futdta,		WID224,	$004300E0,	mp_futm,	(224*67/8)
	dc.l		sfdta,		WID192,	$007100C0,	mp_sfm,	(192*113/8)
	dc.l		wstdta,		WID224,	$005B00E0,	mp_wstm,	(224*91/8)
	dc.l		housdta,		WID256,	$00600100,	mp_hsm,	(256*96/8)
	dc.l		hmskdta,		WID224,	$002D00E0,	mp_hs2m,	(224*45/8)
	dc.l		clubdta,		WID160,	$005000A0,	mp_clbm,	(160*80/8)
	dc.l		selsign,		WID192,	$006000C0,	mp_bilm,	(192*96/8)

palette::
;$10 billboard cursor
;$11 select screen bar
;$12 volume bars
;$13 volume cursor
;$50 - $7F car icons
;$EF scrcover
	dc.w	$0000,$0000,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dc.w	$F800,$F800,$07C0,$FFFF,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dc.w	$0001,$0000,$290A,$41CF,$5252,$6296,$6B19,$7B5B,$839E,$8BE0,$9422,$9C64,$A4A6,$ACE8,$B52A,$BD6C
	dc.w	$C5AD,$CDAF,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dc.w	$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dc.w	$685C,$FAD6,$CA10,$D000,$194A,$41D0,$798C,$8908,$D084,$A884,$F842,$E800,$5908,$6296,$D14A,$C000
	dc.w	$541C,$50D6,$3565,$3522,$FFFF,$649E,$398E,$735C,$2CE0,$2CDC,$AD6B,$6B1A,$9C65,$649E,$314C,$5294
	dc.w	$9362,$F03D,$48D2,$310C,$D835,$6ADA,$1108,$D837,$002F,$077B,$0780,$0001,$0001,$0001,$0001,$0001
	dc.w	$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dc.w	$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dc.w	$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dc.w	$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dc.w	$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dc.w	$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dc.w	$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0000
	dc.w	$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$FFFF

;OBJECT HEADERS
scrcov::
	dc.w		0			;xpos
	dc.w		0			;ypos
	dc.l		coverdta		;data
	dc.w		288			;height
	dc.w		0	;1			;dwidth
	dc.w		112	;80			;iwidth
	dc.b		0			;flags
	dc.b		0			;firstpix
	dc.b		0			;type
	dc.b		4	;0			;depth
	dc.b		0			;pitch
	dc.b		119			;index  use colors $EE,$EF
	dc.w		0			;desc
	dc.l		0			;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------

ldscrcv::
; load map
	dc.w		$30			;xpos
	dc.w		$aa			;ypos
	dc.l		0			;data
	dc.w		104			;height
	dc.w		80			;dwidth
	dc.w		80			;iwidth
	dc.b		0			;flags
	dc.b		0			;firstpix
	dc.b		0			;type
	dc.b		4			;depth
	dc.b		1			;pitch
	dc.b		0			;index
	dc.w		0			;desc
	dc.l		$00202020		;unused byte, remainder, vscale, hscale
; "start" sign
	dc.w		40			;xpos
	dc.w		170			;ypos
	dc.l		STARTICON		;data
	dc.w		64			;height
	dc.w		16			;dwidth
	dc.w		16			;iwidth
	dc.b		TRANS_ON		;flags
	dc.b		0			;firstpix
	dc.b		0			;type
	dc.b		4			;depth
	dc.b		1			;pitch
	dc.b		0			;index
	dc.w		0			;desc
	dc.l		$00202020		;unused byte, remainder, vscale, hscale
; "finish" sign
	dc.w		130			;xpos
	dc.w		170			;ypos
	dc.l		FINISHICON		;data
	dc.w		64			;height
	dc.w		16			;dwidth
	dc.w		16			;iwidth
	dc.b		TRANS_ON		;flags
	dc.b		0			;firstpix
	dc.b		0			;type
	dc.b		4			;depth
	dc.b		1			;pitch
	dc.b		0			;index
	dc.w		0			;desc
	dc.l		$00202020		;unused byte, remainder, vscale, hscale
; text ("Press Fire to Continue")
	dc.w		120			;xpos
	dc.w		400			;ypos
	dc.l		ldtext			;data
	dc.w		16			;height
	dc.w		48			;dwidth
	dc.w		48			;iwidth
	dc.b		TRANS_ON		;flags
	dc.b		0			;firstpix
	dc.b		0			;type
	dc.b		4			;depth
	dc.b		1			;pitch
	dc.b		0			;index
	dc.w		0			;desc
	dc.l		$00202020		;unused byte, remainder, vscale, hscale
;---------------------------------------------------------------------

	.phrase

