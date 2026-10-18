DIR		=	.
INCDIR		= ..\include
ALN		=	newaln
#ALN		=	aln
ALNFLAGS	=	-w -l -a 802000 81d000 4000
O		=	ofiles
OFILES	=	$(O)\game.o $(O)\sys.o $(O)\input.o $(O)\title.o $(O)\select.o \
			$(O)\credits.o $(O)\hiscore.o $(O)\eeprim.o $(O)\sound.o $(O)\tables.o $(O)\remote.o \
			$(O)\play.o $(O)\mkmat.o $(O)\blit.o $(O)\gpufix.o $(O)\playinp.o $(O)\td.o $(O)\modem.o \
			$(O)\readjoy.o fulsyn.oj

COFILES	=	$(O)\playdata.o $(O)\mktp.o $(O)\alloc.o $(O)\lattice.o $(O)\inflate.o $(O)\packet.o
ASM		=	mac -i$(INCDIR) -o $(O)
INCFILES	=	$(INCDIR)\jaguar.inc $(INCDIR)\blit.inc $(INCDIR)\joypad.inc $(INCDIR)\objlist.inc
DSINC = 3dds.inc car.inc bndhead.inc

#CC		=	lc -m0 -v -b0 -w -z2 -r0 -o$(O)
CC		=	gcc
CFLAGS		=	-mshort -O2

BIN		=	$(DIR)\bin
CRY		=	$(DIR)\cry
ARENA		=	$(DIR)\arenas
HOUSE		=	$(DIR)\house
WESTWRLD	=	$(DIR)\westwrld
CITYWRLD	=	$(DIR)\citywrld
RACEWRLD	=	$(DIR)\racewrld
WORLDADDR	=	80000

JPGDIR	=	$(DIR)\jpg
MASKDIR	=	$(DIR)\masks
SOUNDDIR	=	$(DIR)\sounds

TITLE	=	-i titlebk.jag titlebk -i rokltrs.jag rokltrs -i ttlcar.z ttlcar

SELECT	=	-i seamap.jag seamap -i mp_bill.jag mp_bill -i mp_club.jag mp_club

CREDITS	=	-i credits.jag credits

LOADART	=	-i loadsf.jag loadsf -i loadwst.jag loadwst -i loadhs.jag loadhs -i loadvp.jag loadvp -i loadtod.jag loadtod -i loadgrc.jag loadgrc

BINFILES	=	3d.bin casbeg.bin racbeg.bin tagbeg.bin comp.bin ren.bin casend.bin racend.bin tagend.bin \
			precomp.bin preren.bin $(O)\gpunzip.bin
BININC		=	-I 3d.bin gpprog -I casbeg.bin casbeg -I tagbeg.bin tagbeg -I racbeg.bin racbeg -I comp.bin cgpprog \
			-I ren.bin rgpprog -I casend.bin casend -I tagend.bin tagend -I racend.bin racend \
			-I $(O)\gpunzip.bin _gpunzip -I precomp.bin precomp -I preren.bin preren

MASKS	=	-i mp_fut.m mp_futm -i mp_sf.m mp_sfm -i mp_wst.m mp_wstm -i mp_hs.m mp_hsm -i mp_hs2.m mp_hs2m\
			-i mp_bill.m mp_bilm -i mp_club.m mp_clbm

SOUNDS	=	-i woo1.f16 winsnd -i aescrash.f16 crashsnd -i right7.f16 p1yea -i yes1.f16 p2yea -i flush20k.f16 flushsnd\
			-i pno2_20k.f16 pianosnd -i meow30k.f16 meowsnd -i mouse20k.f16 mousesnd -i door_20k.f16 doorsnd -i ouch_17k.f16 ouchsnd\
			-i conga.scr congams -i brushsnr.f16 tsnare -i conga.f16 tconga -i kick2.f16 tkick -i marimba2.f16 marimba\
			-i honky.scr honky -i honkyc2.f16 tmtwo -i honkyc3.f16 tmthree -i honkyc4.f16 tmfour -i pnotri.f16 tritone\
			-i sfjazz.scr sfjazz -i kick.f16 sfkick -i bass.f16 sfbass -i trumpet.f16 trumpet -i clsd_hat.f16 clsd_hat\
				-i open_hat.f16 open_hat -i snare.f16 sfsnare -i ride.f16 ride -i rim.f16 rim -i toms.f16 toms\
			-i techno.scr tech \
			-i gang.scr rapmus -i balloon.f16 balloon -i raphat.f16 raphat -i rapkick.f16 rapkick -i rappiano.f16 rappiano\
			-i rapsnr1.f16 rapsnr1 -i rapsnr2.f16 rapsnr2 -i sax.f16 squeekie -i wahguitr.f16 wahguitr\
			-i reggae.scr reggae -i chord1.f16 chord1 -i chord2.f16 chord2 -i cabassa1.f16 cabas1 -i cabassa3.f16 cabas3\
			-i clubwave.scr clubwave -i sawwave2.f16 sawwave -i roksnare.f16 roksnare -i rockkick.f16 rockkick
		
WORLDDEPS	=	studio.z future4.z garage.z westa.z bighouse.z westw.z city.z race.z ramps.z toyrace.z garace.z \
			$(JPGDIR)\sky.z $(JPGDIR)\garasky.z $(JPGDIR)\pwrball.z $(JPGDIR)\pausecry.z \
			$(JPGDIR)\ldtext.z $(JPGDIR)\coltext.z $(JPGDIR)\p2txt

WORLDS		=	-i studio.z studio -i future4.z future -i garage.z garage -i westa.z westa -i ramps.z toya \
			-i bighouse.z bighouse -i westw.z westw -i city.z city -i race.z racew -i toyrace.z toyw -i garace.z garr \
			-i $(JPGDIR)\sky.z o_SKY -i $(JPGDIR)\garasky.z o_GARASKY -i $(JPGDIR)\pwrball.z o_PWRBALL \
			-i $(JPGDIR)\pausecry.z o_PAUSECRY -i $(JPGDIR)\ldtext.z o_ldtext -i $(JPGDIR)\coltext.z o_coltxt \
			-i $(JPGDIR)\p2txt o_p2txt

game.txt: $(OFILES) $(O)\titleart.o $(O)\selart.o $(O)\credart.o $(O)\loadart.o\
		$(O)\adjblack.bin $(O)\uncomp.bin $(O)\lighten.bin $(O)\cross.bin $(O)\fade.bin $(O)\masks.o $(O)\sounds.o\
		$(BINFILES) $(COFILES) $(WORLDDEPS) art.z
	$(ALN) -y $(BIN) $(ALNFLAGS) -o game $(OFILES)\
		-i dehuff.abs dehuff -i dq75.abs q75 -i dq85.abs q85\
		$(O)\titleart.o $(O)\selart.o $(O)\credart.o $(O)\loadart.o\
		-i dejag.bin dejagst\
		-i $(O)\adjblack.bin adblack -i $(O)\uncomp.bin uncomp -i $(O)\lighten.bin lighten\
		-i $(O)\cross.bin cross -i $(O)\fade.bin fade\
		-i art.z art\
		$(O)\masks.o\
		$(O)\sounds.o\
		$(BININC)\
		$(COFILES)\
		-i $(JPGDIR)\startico.z o_STARTICON\
		$(WORLDS) -i $(JPGDIR)\hoodcry.z o_HOOD -i $(JPGDIR)\gameovr.z gameovr -i $(JPGDIR)\rewind.cry REWIND\
		-i $(JPGDIR)\waitplay.cry WAITPLAY
	filefix game.abs
	rm game.abs

$(O)\game.o:		game.s eq.s $(INCFILES)
	$(ASM)\game.o game.s

$(O)\sys.o:		sys.s eq.s $(DSINC) $(INCFILES)
	$(ASM)\sys.o sys.s
$(O)\input.o:		input.s eq.s $(INCFILES)
	$(ASM)\input.o input.s
$(O)\title.o:		title.s eq.s $(INCFILES)
	$(ASM)\title.o title.s
$(O)\select.o:		select.s eq.s $(INCFILES)
	$(ASM)\select.o select.s
$(O)\play.o:		play.s eq.s car1.mdl car2.mdl car3.mdl car4.mdl car5.mdl car6.mdl $(DSINC) $(INCFILES)
	$(ASM)\play.o play.s
$(O)\remote.o:		remote.s eq.s $(DSINC) $(INCFILES)
	$(ASM)\remote.o remote.s
$(O)\playinp.o:		playinp.s eq.s $(DSINC) $(INCFILES)
	$(ASM)\playinp.o playinp.s
$(O)\td.o:		td.s eq.s $(DSINC) $(INCFILES)
	$(ASM)\td.o td.s
$(O)\modem.o:		modem.s eq.s $(INCFILES)
	$(ASM)\modem.o modem.s
$(O)\mkmat.o:		mkmat.s $(DSINC) $(INCFILES)
	$(ASM)\mkmat.o mkmat.s
$(O)\gpufix.o:		gpufix.s $(DSINC) $(INCFILES)
	$(ASM)\gpufix.o gpufix.s
$(O)\blit.o:		blit.s $(DSINC) $(INCFILES)
	$(ASM)\blit.o blit.s
$(O)\credits.o:	credits.s eq.s $(INCFILES)
	$(ASM)\credits.o credits.s
$(O)\hiscore.o:	hiscore.s eq.s $(DSINC) $(INCFILES)
	$(ASM)\hiscore.o hiscore.s
$(O)\eeprim.o:	eeprim.s $(INCFILES)
	$(ASM)\eeprim.o eeprim.s
$(O)\sound.o:		sound.s eq.s $(DSINC) $(INCFILES)
	$(ASM)\sound.o sound.s
$(O)\tables.o:		tables.s eq.s $(INCFILES)
	$(ASM)\tables.o tables.s
$(O)\lattice.o:	lattice.s
	$(ASM)\lattice.o lattice.s
$(O)\readjoy.o:	readjoy.s
	$(ASM)\readjoy.o readjoy.s

$(O)\playdata.o: playdata.s car.dat $(CRY)\score.cry $(CRY)\dashpal.cry
	mac -i$(CRY) -o $(O)\playdata.o playdata.s

$(O)\start.rgb: pics\start.tga
	tga2cry -binary -f rgb -o $(O)\start.rgb pics\start.tga
$(O)\finish.rgb: pics\finish.tga
	tga2cry -binary -f rgb -o $(O)\finish.rgb pics\finish.tga

# C files
$(O)\alloc.o: alloc.s
	mac -u -o $(O)\alloc.o alloc.s
$(O)\mktp.o: mktp.s
	mac -u -o $(O)\mktp.o mktp.s
$(O)\packet.o: packet.s
	mac -u -o $(O)\packet.o packet.s
$(O)\inflate.o: inflate.s
	mac -u -o $(O)\inflate.o inflate.s

alloc.s:	alloc.c alloc.h allocpr.h
	$(CC) $(CFLAGS) -S -o alloc.gns alloc.c
	mit2mot -o alloc.s alloc.gns
	rm alloc.gns
mktp.s:		mktp.c bndhead.h allocpr.h
	$(CC) $(CFLAGS) -S -o mktp.gns mktp.c
	mit2mot -o mktp.s mktp.gns
	rm mktp.gns
inflate.s:	inflate.c
	$(CC) $(CFLAGS) -S -o inflate.gns inflate.c
	mit2mot -o inflate.s inflate.gns
	rm inflate.gns
packet.s:	packet.c
	$(CC) $(CFLAGS) -S -o packet.gns packet.c
	mit2mot -o packet.s packet.gns
	rm packet.gns

$(O)\titleart.o:	makefile
	$(ALN) -y $(JPGDIR) -w -p -o $(O)\titleart $(TITLE)

$(O)\selart.o:	makefile
	$(ALN) -y $(JPGDIR) -w -p -o $(O)\selart $(SELECT)

$(O)\credart.o:	makefile
	$(ALN) -y $(JPGDIR) -w -p -o $(O)\credart $(CREDITS)

$(O)\loadart.o:	makefile
	$(ALN) -y $(JPGDIR) -w -p -o $(O)\loadart $(LOADART)

$(O)\masks.o:	makefile
	$(ALN) -y $(MASKDIR) -w -p -o $(O)\masks $(MASKS)

$(O)\sounds.o:	makefile
	$(ALN) -y $(SOUNDDIR) -w -p -o $(O)\sounds $(SOUNDS)

$(O)\adjblack.bin:	adjblack.gas eq.s
	gasm -I$(INCDIR) -o adjblack.gas
	ltxconv -a -o$(O)\adjblack adjblack
	rm adjblack.ltx
	rm $(O)\adjblack.sym

$(O)\uncomp.bin:	uncomp.gas eq.s
	gasm -I$(INCDIR) -o uncomp.gas
	ltxconv -a -o$(O)\uncomp uncomp
	rm uncomp.ltx
	rm $(O)\uncomp.sym

$(O)\lighten.bin:	lighten.gas eq.s
	gasm -I$(INCDIR) -o lighten.gas
	ltxconv -a -o$(O)\lighten lighten
	rm lighten.ltx
	rm $(O)\lighten.sym

$(O)\cross.bin:	cross.gas eq.s
	gasm -I$(INCDIR) -o cross.gas
	ltxconv -a -o$(O)\cross cross
	rm cross.ltx
	rm $(O)\cross.sym

$(O)\fade.bin:	fade.gas eq.s
	gasm -I$(INCDIR) -o fade.gas
	ltxconv -a -o$(O)\fade fade
	rm fade.ltx
	rm $(O)\fade.sym

$(O)\gpunzip.bin:	gpunzip.gas
	gasm -I$(INCDIR) -o gpunzip.gas
	ltxconv -a -o$(O)\gpunzip gpunzip
	rm gpunzip.ltx
	rm $(O)\gpunzip.sym

comp.bin:	comp.gas mktp.gas rot.gas clp.gas shade.gas 3to2.gas edge.gas bf.gas subscomp.gas 68kequ.inc 3d.inc time.gas $(DSINC)
	gasm -I$(INCDIR) -R2 -o -c comp.gas
	ltxconv -a -ocomp comp
	rm comp.ltx comp.sym
	align comp.bin

precomp.bin:	precomp.gas sky2.gas rotdot.gas 68kequ.inc 3d.inc time.gas $(DSINC)
	gasm -I$(INCDIR) -R2 -o -c precomp.gas
	ltxconv -a -oprecomp precomp
	rm precomp.ltx precomp.sym
	align precomp.bin

ren.bin:	ren.gas surf.gas tex.gas drawdot.gas 68kequ.inc tree.gas tree.inc 3d.inc time.gas $(DSINC)
	gasm -I$(INCDIR) -R2 -o -c ren.gas
	ltxconv -a -oren ren
	rm ren.ltx ren.sym
	align ren.bin

preren.bin:	preren.gas marktree.gas 68kequ.inc 3d.inc time.gas $(DSINC)
	gasm -I$(INCDIR) -R2 -o -c preren.gas
	ltxconv -a -opreren preren
	rm preren.ltx preren.sym
	align preren.bin

casbeg.bin:	casbeg.gas 3dbeg.gas portrot.gas utime.gas sky1.gas ortho.gas othcarrt.gas camera.gas 68kequ.inc 3d.inc time.gas $(DSINC)
	gasm -I$(INCDIR) -R2 -o -c casbeg.gas
	ltxconv -a -ocasbeg casbeg
	rm casbeg.ltx casbeg.sym
	align casbeg.bin
#casbeg.bin: racbeg.bin
#	cp racbeg.bin casbeg.bin

racbeg.bin:	racbeg.gas 3dbeg.gas portrot.gas utime.gas sky1.gas ortho.gas othcarrt.gas camera.gas 68kequ.inc 3d.inc time.gas $(DSINC)
	gasm -I$(INCDIR) -R2 -o -c racbeg.gas
	ltxconv -a -oracbeg racbeg
	rm racbeg.ltx racbeg.sym
	align racbeg.bin
#racbeg.bin: tagbeg.bin
#	cp tagbeg.bin racbeg.bin

tagbeg.bin:	tagbeg.gas 3dbeg.gas portrot.gas utime.gas sky1.gas ortho.gas othcarrt.gas camera.gas 68kequ.inc 3d.inc time.gas $(DSINC)
	gasm -I$(INCDIR) -R2 -o -c tagbeg.gas
	ltxconv -a -otagbeg tagbeg
	rm tagbeg.ltx tagbeg.sym
	align tagbeg.bin

casend.bin:	casend.gas 3dend.gas close.gas carcrash.gas crash.gas drive.gas carrot.gas turt.gas 68kequ.inc subsend.gas 3d.inc time.gas $(DSINC)
	gasm -I$(INCDIR) -R2 -o -c casend.gas
	ltxconv -a -ocasend casend
	rm casend.ltx casend.sym
	align casend.bin
#casend.bin: racend.bin
#	cp racend.bin casend.bin

racend.bin:	racend.gas 3dend.gas close.gas carcrash.gas crash.gas drive.gas carrot.gas turt.gas 68kequ.inc subsend.gas 3d.inc time.gas $(DSINC)
	gasm -I$(INCDIR) -R2 -o -c racend.gas
	ltxconv -a -oracend racend
	rm racend.ltx racend.sym
	align racend.bin

#racend.bin: tagend.bin
#	cp tagend.bin racend.bin

tagend.bin:	tagend.gas 3dend.gas close.gas carcrash.gas crash.gas drive.gas carrot.gas turt.gas 68kequ.inc subsend.gas 3d.inc time.gas $(DSINC)
	gasm -I$(INCDIR) -R2 -o -c tagend.gas
	ltxconv -a -otagend tagend
	rm tagend.ltx tagend.sym
	align tagend.bin
3d.bin:		3d.gas 68kequ.inc $(DSINC)
	gasm -I$(INCDIR) -R2 -o -c 3d.gas
	ltxconv -a -o3d 3d
	rm 3d.ltx 3d.sym
	align 3d.bin

#fulsyn.oj:	fulsyn.das eq.s
#	gasm -I$(INCDIR) -o -S -CDSP fulsyn.das
#	ltxconv -l -o$(O)\tgasm fulsyn
#	mv $(O)\tgasm.o $(O)\fulsyn.oj
#	rm fulsyn.ltx

#
# here's how to build the worlds
#

gpustud.bin:	gpustud.gas 68kequ.inc $(DSINC)
	gasm -I$(INCDIR) -R2 -o -c gpustud.gas
	ltxconv -a -ogpustud gpustud
	rm gpustud.ltx gpustud.sym
	align gpustud.bin

gpuhouse.bin:	gpuhouse.gas 68kequ.inc $(DSINC)
	gasm -I$(INCDIR) -R2 -o -c gpuhouse.gas
	ltxconv -a -ogpuhouse gpuhouse
	rm gpuhouse.ltx gpuhouse.sym
	align gpuhouse.bin

gpugara.bin:	gpugara.gas 68kequ.inc $(DSINC)
	gasm -I$(INCDIR) -R2 -o -c gpugara.gas
	ltxconv -a -ogpugara gpugara
	rm gpugara.ltx gpugara.sym
	align gpugara.bin

gpucity.bin:	gpucity.gas 68kequ.inc $(DSINC)
	gasm -I$(INCDIR) -R2 -o -c gpucity.gas
	ltxconv -a -ogpucity gpucity
	rm gpucity.ltx gpucity.sym
	align gpucity.bin

studio.z: studio.s gpustud.bin $(ARENA)\studio.mdl
	mac -i$(ARENA) studio.s
	$(ALN) -a $(WORLDADDR) x x studio.o -I gpustud.bin gpustud
	fixrom studio.abs
	mv studio.abs studio
	rm -f studio.z
	gzip studio
	rm studio.o

garage.z: garage.s $(ARENA)\garage.mdl gpugara.bin garage.rec
	mac -i$(ARENA) garage.s
	$(ALN) -a $(WORLDADDR) x x garage.o -I gpugara.bin gpugara -I garage.rec gararec
	fixrom garage.abs
	mv garage.abs garage
	rm -f garage.z
	gzip garage
	rm garage.o

garace.z: garace.s $(ARENA)\garace.mdl
	mac -i$(ARENA) garace.s
	$(ALN) -a $(WORLDADDR) x x garace.o
	fixrom garace.abs
	mv garace.abs garace
	rm -f garace.z
	gzip garace
	rm garace.o

future4.z: future4.s $(ARENA)\future4.mdl
	mac -i$(ARENA) future4.s
	$(ALN) -a $(WORLDADDR) x x future4.o
	fixrom future4.abs
	mv future4.abs future4
	rm -f future4.z
	gzip future4
	rm future4.o

westa.z: westa.s $(ARENA)\west.mdl
	mac -i$(ARENA) westa.s
	$(ALN) -a $(WORLDADDR) x x westa.o
	fixrom westa.abs
	mv westa.abs westa
	rm -f westa.z
	gzip westa
	rm westa.o

bighouse.z: bighouse.s $(HOUSE)\map.cry $(HOUSE)\mausrec.o $(HOUSE)\catrec.o gpuhouse.bin
	mac -i$(HOUSE) bighouse.s
	$(ALN) -a $(WORLDADDR) x x bighouse.o -I gpuhouse.bin gpuhouse $(HOUSE)\mausrec.o $(HOUSE)\catrec.o
	fixrom bighouse.abs
	rm bighouse.o
	mv bighouse.abs bighouse
	rm -f bighouse.z
	gzip bighouse


westw.z: westw.s $(WESTWRLD)\map.cry
	mac -i$(WESTWRLD) westw.s
	$(ALN) -a $(WORLDADDR) x x westw.o
	fixrom westw.abs
	rm westw.o
	mv westw.abs westw
	rm -f westw.z
	gzip westw

city.z: city.s $(CITYWRLD)\map.cry gpucity.bin
	mac -i$(CITYWRLD) city.s
	$(ALN) -a $(WORLDADDR) x x city.o $(CITYWRLD)\cabrec.o -I gpucity.bin gpucity 
	rm -f city.o city.z
	fixrom city.abs
	mv city.abs city
	gzip city

sky.z: pics\sky.tga
	tga2cry -binary -o sky -dither -resize 768,120 pics\sky.tga
	gzip sky

garasky.z: pics\garasky.tga
	tga2cry -binary -o garasky -dither -resize 768,120 pics\garasky.tga
	gzip garasky

pwrball.z: pwrball.s
	mac -i$(CRY) pwrball.s
	$(ALN) -a 0 x x pwrball.o
	fixrom pwrball.abs
	rm -f pwrball.z pwrball.o
	mv pwrball.abs pwrball
	gzip pwrball

pausecry.z: pics\pause.tga
	tga2cry -binary -o pausecry pics\pause.tga
	gzip pausecry

toyrace.z: toyrace.s arenas\toyrace.mdl
	mac -i$(ARENA) toyrace.s
	$(ALN) -a $(WORLDADDR) x x toyrace.o
	fixrom toyrace.abs
	rm -f toyrace.z toyrace.o
	mv toyrace.abs toyrace
	gzip toyrace

ramps.z: ramps.s arenas\ramps.mdl
	mac -i$(ARENA) ramps.s
	$(ALN) -a $(WORLDADDR) x x ramps.o
	fixrom ramps.abs
	rm -f ramps.z ramps.o
	mv ramps.abs ramps
	gzip ramps

race.z: race.s
	mac -i$(RACEWRLD) race.s
	$(ALN) -a $(WORLDADDR) x x race.o
	fixrom race.abs
	rm -f race.z race.o
	mv race.abs race
	gzip race

art.z: ART.S
	mac ART.S
	$(ALN) -a 0 x x art.o
	fixrom art.abs
	rm -f art.z art.o
	mv art.abs art
	gzip art
