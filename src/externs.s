	.extern	scrlbytes,scrollstr,scrollpos,scrolloff
	.extern	mainloop
	.extern	initonce,initstuff
	.extern	gamemode,oldgmode
	.extern	gotitle,goselect,gocredit,gohiscor,gohiedit,goplay
	.extern	eoghiscores,sv_defhi
	.extern	retrnsel
	.extern	looptable,titleloop,selloop,credloop,highloop,playloop
	.extern	random,seed
	.extern	wait_int
	.extern	clearscr,scrcover,scrcov,coverdta
	.extern	ldscrobj,ldscrcv
	.extern	ld_start,ld_finish,ldtext,o_ldtext
	.extern	o_coltxt, o_p2txt
	.extern	olist_l1,olist_l2,olist_l3,olist_l4,olist_l5,olist_l6,olist_l7,olist_l8
	.extern	STARTICON,FINISHICON
	.extern	o_STARTICON,o_FINISHICON
	.extern REWIND
	.extern	do_mask,maskram
	.extern	adjblak,adblack
	.extern	dehuff,dejagst,q75,q85
	.extern	load_q85,load_q75
	.extern	ld_decmp,dodecomp
	.extern	palette
	.extern	input,joyedge,joycur,joyedge2,joycur2,joybothe,joybothc
	.extern	uncmpart
	.extern	uncomp,ld_uncmp
	.extern	lighten,ld_ltn
	.extern	build
	.extern	listgood
	.extern	olist,olist_ram,olist_sec,olist_stp,olist_pau,olistbld
	.extern	titlolst,selolst,lotolst,credolst,higholst,playolst
	.extern	titlobjs,selobjs,lotobjs,credobjs,highobjs,playobjs
	.extern	stopobj,branch0,branch1
	.extern	t_sign_l,t_sign_r,t_scr,t_scr_m,t_car
	.extern	s_scr_l,s_scr_m,s_scr_r,s_club,s_sign,s_text,s_bar,s_mask,mvolcurs,svolcurs,s_sign_l,s_sign_r
	.extern	c_scr,c_sign0,c_sign1,c_sign2,c_sign3,c_sign4,c_sign5,c_sign6
	.extern	h_scr,h_text,cursor0,cursor1
	.extern	load_gpu
	.extern	init_snd,startsnd,voicesoff,set_svol,set_mvol
	.extern	eng_on,eng_off,engpitch
	.extern	muteflag,mute,dsp_off
	.extern	musicst,patchst
	.extern	winsnd,p1yea,p2yea,crashsnd,flushsnd,pianosnd,meowsnd,mousesnd,doorsnd,ouchsnd
	.extern	speedopt,steeropt,cont_opt,mus_vol,snd_vol,engoffopt
	.extern	playmus,it_music,songnum
	.extern	ck_radio,adjradio,radiocnt
	.extern	keepmus
	.extern	soundvol
	.extern	save_opt
	.extern	mkMatrix
	.extern	jpit2val
;	.extern	FULSYN_S,FULSYN_E,DSPORG,SCORE_ADD,TIMER_ADD,PATCHLOC,VOLUME
	.extern	SYNTH_S,SYNTH_E,DSPORG,SCORE_ADD,TIMER_ADD,PATCHLOC,VOLUME

	.extern	p1_scr,p1_hud,map_scr,bar_scr,p2_scr,p2_hud,p1_hood,pause_scr
	.extern	titlebk,rokltrs,ttlcar,ttlcarm
	.extern	titlescr,stonedta,tcardta
	.extern	titlestp,tcaryend

	.extern	mp_futm,mp_sfm,mp_hsm,mp_wstm,mp_bill,mp_club,mp_hs2m
	.extern	mp_bilm,mp_clbm
	.extern	seamap
	.extern	selscr,futdta,sfdta,wstdta,housdta,hmskdta,clubdta
	.extern	selsign,seltext,seltexta,ltnbufr
	.extern	curlevel
	.extern	bar_pos
	.extern	cur_act,cur_car0,cur_car1
	.extern	menuflag
	.extern	signmove
	.extern	rac1laps,rac2laps,tagtime,tagtune0,tagtune1,col1dots,col2dots
	.extern	num_dec
	.extern	joydelay

	.extern	credits,credscr,ctxtcnt,ctxtnum,credsgn0,credsgn1,credsgn2,credsgn3,credsgn4,credsgn5,credsgn6,credtext

	.extern	hitxtdta
	.extern	hilstptr,htxtcnt,htxtnum
	.extern	defhighs,addhiscr
	.extern	pbhighs,rac0high,rac1high,rac2high,rac3high,racShigh
	.extern	high_dec
	.extern	curs0row,curs0col,curs1row,curs1col
	.extern	highedit
	.extern	joydel0,joydel1
	.extern	gmovrhs

	.extern	showcoord

	.extern	fTime
	.extern leftx,topy
	.extern	timestamp
	.extern	lasttime
	.extern	packtime
	.extern	listAddr
	.extern	buffNum
	.extern	buffShn

	.extern	fontaddr,font_wid

	.extern	art,strt8bit
	.extern	copyrt
	.extern	car0icn,car1icn,car2icn,car3icn,car4icn,car5icn
	.extern	curs0dta,curs1dta,volcdata,selbar,rankbox
	.extern	fnt_a,fnt_b,fnt_c,fnt_d,fnt_e,fnt_f,fnt_g,fnt_h,fnt_i,fnt_j,fnt_k,fnt_l,fnt_m
	.extern	fnt_n,fnt_o,fnt_p,fnt_q,fnt_r,fnt_s,fnt_t,fnt_u,fnt_v,fnt_w,fnt_x,fnt_y,fnt_z
	.extern	fnt_col,fnt_com,fnt_per,fnt_sp,fnt_apos
	.extern	num0,num1,num2,num3,num4,num5,num6,num7,num8,num9
	.extern	f16_a,f16_b,f16_c,f16_d,f16_e,f16_f,f16_g,f16_h,f16_i,f16_j,f16_k,f16_l,f16_m
	.extern	f16_n,f16_o,f16_p,f16_q,f16_r,f16_s,f16_t,f16_u,f16_v,f16_w,f16_x,f16_y,f16_z
	.extern	f16_col,f16_com,f16_per,f16_sp,f16_apos
	.extern	num16_0,num16_1,num16_2,num16_3,num16_4,num16_5,num16_6,num16_7,num16_8,num16_9
	.extern	let_A,let_B,let_C,let_D,let_E,let_F,let_G,let_H,let_I,let_J,let_K,let_L,let_M
	.extern	let_N,let_O,let_P,let_Q,let_R,let_S,let_T,let_U,let_V,let_W,let_X,let_Y,let_Z
	.extern	let_a,let_b,let_c,let_d,let_e,let_f,let_g,let_h,let_i,let_j,let_k,let_l,let_m
	.extern	let_n,let_o,let_p,let_q,let_r,let_s,let_t,let_u,let_v,let_w,let_x,let_y,let_z
	.extern	let_per

	.extern	eeread,eewrite

	.extern	pal_ntsc

	.extern	titlebkg,ttlmore
	.extern	seldcm,seldcm1
	.extern	credbkg

	.extern	msk_ttl,msk_sel

	.extern	screen_addr,last_screen
	.extern	player
	.extern	twoplayer,splitscreen
	.extern	chkPlayer

	.extern	set_palette
	.extern	bar_palette
	.extern	car1_head
	.extern	car1_ram
	.extern	car2_head
	.extern	car2_ram
	.extern	_init_alloc
	.extern	gametype,gameover
	.extern	player
	.extern	winner
	.extern	itCar,lastItCar,changeIT,itHUD
	.extern	scoreMax
	.extern	origdash
	.extern	dash
	.extern	alpha
	.extern	beta
	.extern	gamma
	.extern	waitTime
	.extern	screen_addr
	.extern	do_gpufixups
	.extern	mapscale,maporig
	.extern	startWorld,mapWorld

	.extern	scoreinc
	.extern	dotloc,dotimg
	.extern	acop_trans
	.extern	PWRBALL
	.extern	gpram,bgpram,cgpram,egpram,rgpram,pcram
	.extern	blit_rect,blit_pic

	.extern	cur_voice_snd

	.extern	worldsky

	.extern	o_SKY,o_GARASKY,SKY
	.extern	o_car_dat,car_dat
	.extern	o_PWRBALL,PWRBALL
	.extern	o_digitfont
	.extern	o_cmpssfont
	.extern	o_spdfont,o_tnyfont
	.extern	o_yourit
	.extern	o_youwin
	.extern	digitfont
	.extern	cmpssfont
	.extern	speedfont,tnyfont
	.extern	yourit
	.extern	youwin

	.extern	o_PAUSECRY
	.extern	gameovr

	.extern	debugflg
	.extern	animprog,animparam,animinit
	.extern	_inflate,_inptr,_outptr

	.extern	cinf_pal,cinfntsc

	.extern	backgr0,backgr1
	.extern	cross,fade
	.extern	do_cross,do_fade
	.extern	crosscnt,bright
	.extern	loadsdn

	.extern	loadhs,loadsf,loadwst,loadvp,loadtod,loadgrc

	.extern	prevscr0,prevscr1
	.extern	rankplr0,rankplr1
	.extern	showrank
	.extern gothiscore

	.extern	mbands
	.extern gpu_do
	.extern	drawrank

	.extern	Frame,LDFrame,COLFrame,TAGFrame
	.extern	o_HOOD
	.extern	framedone
	.extern	fps, framecnt
	.extern	playspd
	.extern	hoodptr
	.extern	stacktop
	.extern	getpwrball

	.extern	SKYHIGH
	.extern	SEALEVEL

	.extern	_MDMin,_MDMrec,_MDMerr,_MDMperr, _MDMferr, _MDMoerr, _MDMdrop
	.extern	_MDMinit,_MDMcall,_MDManswer,_MDMcmd
	.extern	_MDMtxp,_MDMrxp,_MDMstat,_MDMflush, _MDMget
	.extern _MDMhangup
	.extern	modem,curpacket

;
; modem packet handling functions in packet.c
;
	.extern	_recpacket,_sendpacket,_initpackets
