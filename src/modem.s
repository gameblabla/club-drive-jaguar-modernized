test_modem equ 1
real_line equ 0
little equ 1
**************************************************************************
; (C)1994 ATARI CORP.       SECRET & CONFIDENTIAL       ALL RIGHTS RESERVED
;
;				uart.s
;
;       This program shows how to use the jaguar modem
;
;
;                                REVISION HISTORY
;
; REV.  DATE       BY            DESCRIPTION OF EDIT
; """"  """"       ""            """""""""""""""""""
; 100  08 Jun 94  DMS	 From uart.102
; 102  09 Jun 94  DMS	 Clean it up
; 103  09 Jun 94  RGM    ... rinse cycle
;      12 Jun 94  RGM    ... spin dry
;      15 Jun 94  ERS    Added C language interface
;      16 Jun 94  ERS    Made it interrupt driven (sort of)
;      29 Jul 94  KAR    Added call, answer & hangup code
;***************************************************************************
; error codes:
;
;  -1		General error code in uart.  look at upper word
;  -2		Handshake timed out
;  -3		Modem did not respond.  probably dead, off or unplugged
;  -4		Transmit timeout
;  -5		Command reply error
;  -6		Getdata got an unexpected packet
;  -7		Error during DTMF dialing
;  -8		No dial tone detected
;  -9		Data packet had bad data
; -10		Bad self test result from modem
; -11		Packet phase error - unexpected $f3
; -12		Call waiting signal
; -13		Lost line
; -14		Packet phase error - unexpected $f0
; -15		Wrong tone during DTMF handshake
; -16		User hangup
; -17		Handshake reply error
; -18		Synchronization byte error
; -19		Unexpected communication packet
; -20		Unexpected non-communication packet
;***************************************************************************
; Routines:
;
; mdm_init:		Initialise modem
; mdm_dial:		Dial string, and set up as caller
; mdm_wtone:		Wait 5 seconds for a dial tone
; wait_dtmf:		Not written yet
; shake_dtmf:		Not written yet
; mdm_shake:
; mdm_txp:		Transmit (4 byte) priority packet
; mdm_rxp:		Receive (4 byte) priority packet
; mdm_cmd:		Send 2 byte modem command, and get reply
; mdm_pair:		Send 2 bytes to modem.  Do not wait for reply
; uartinit:		Initialise Jaguar uart, and clear any errors
; Wait1:		Wait about 1 second
; Getb1:		Get 1 byte from modem
; sendb:		Send 1 byte to the modem
; hang_up:		Go on-hook
;***************************************************************************
;	.include	"jaguar.inc"
;	.include	"modem.inc"
	.include	"eq.s"
	.include	"externs.s"

;***************************************************************************
; MODEM SUBROUTINES
;***************************************************************************


;***************************************************************************
; mdm_init: 	Initialise the modem, and go off hook
;
;
; Returns:	d0.w		-ive if error
;		d1,d2,d3,d4	trashed
;***************************************************************************
_MDMinit::
	movem.l	d2-d4,-(sp)
	bsr	mdm_init
	movem.l	(sp)+,d2-d4
	rts
mdm_init:
	bsr	uartinit	; init Jerry's UART

	move.w	#UCLK_57600,u_clk	;set the uart to 57600 bps
	bsr	mdm_reset

	bmi	.foo2		; timeout - modem at 19,200?
	cmp.w	#M_TESTOK,d1	; check self test status
	bne	.err_test	; ..bad self test
	bra	.foo
.foo2:
	bsr	uartinit	; init Jerry's UART again

	move.w	#UCLK_19200,u_clk	;set the uart to 19200 bps
	bsr	mdm_reset

	bmi	.foo3		; timeout - no modem present???
	cmp.w	#M_TESTOK,d1	; check self test status
	bne	.err_test	; ..bad self test
	bra	.foo
.foo3:	move.w	#UCLK_57600,u_clk
	bsr	mdm_reset
	bmi	.lp3
	cmp.w	#M_TESTOK,d1
	bne	.err_test

.foo:
	bsr	uartinit	; init Jerry's UART again

	move.w	#$fffe,d1	;change modem to 19,200 bps
	bsr	mdm_pair	; send the command
	bmi	.lp3

.lp1:	move.w	u_stat,d0	;pick up transmit buffer empty status
	btst.l	#u_tbe,d0	;
	beq.b	.lp1		; retail uses 8-bit backward UART poll branch

	move.w	#85,d0
.loop:	move.l	(a7),(a7)	;burn up some cycles
	dbra	d0,.loop

	move.w	#UCLK_19200,u_clk	; baud rate to 19,200
.if test_modem
	move.w	#M_SPKRLOW,d1	; Send 'Enable Speaker'
	bsr	mdm_cmd		; !!!! FOR DEBUG ONLY !!!!
	bmi	.lp3		; !!!! FINAL VERSION HAS NO SPEAKER !!!!
	cmp.w	#M_SPKRLOW,d1
	bne	.err_cmd
.endif
	bra	.ok_init

.err_test:
	move.l	#MDM_ERR_BAD_SELFTEST,d0
	move.w	d1,d0
	bra	.lp3
.err_cmd:
	move.l	#MDM_ERR_CMD_REPLY,d0		; Command reply error
	move.w	d1,d0
	bra	.lp3

.ok_init:
	sub.l	d0,d0
.lp3:
	rts

*****************************************************************************
*	mdm_reset - resets the modem
*
*
*****************************************************************************

mdm_reset:

	move.l	#250000,d2	; 1 second timeout
.lp1:
	move.w	u_stat,d0	;pick up transmit buffer empty status
	btst.l	#u_tbe,d0	;
	bne	.lp4		;br if transmit buffer empty
	sub.l	#1,d2
	bne.b	.lp1	; retail short back-edge
	bra	.err4
.lp4:
	move.w	#$ffff,u_data	; send the first byte of the reset
.lp7:
	move.w	u_stat,d0	;pick up transmit buffer empty status
	btst.l	#u_tbe,d0	;
	beq.b	.lp7		;wait for the buffer to empty (retail short)

	move.w	#254,d1
.lp6:
	move.l	(a7),(a7)
	dbra	d1,.lp6		;spin for 7600 cycles

	move.w	#$ffff,u_data	; send the next byte
.lp8:
	move.w	u_stat,d0	;pick up transmit buffer empty status
	btst.l	#u_tbe,d0	;
	beq.b	.lp8		;br if transmit buffer full (retail short)

	move.w	#58,d1
.lp9:
	move.l	(a7),(a7)
	dbra	d1,.lp9		;spin for 1700 cycles

	move	#$2700,sr
	move.l	#0,_MDMin	;clear incoming data buffer
	move.w	#UCLK_57600,u_clk	; baud rate to 57,600
	move	#$2000,sr

	move.l	#59000,d1	; duration of reset is ~800ms, set timeout to ~1s
	bsr	getb		;get kludge byte
	bmi	.lp3

	moveq	#50,d1	; retail MOVEQ encoding
	bsr	getb		; get first status byte
	bmi	.lp3
	move.b	d1,d2

	moveq	#50,d1	; retail MOVEQ encoding
	bsr	getb		; get next status byte
	bmi	.lp3
.if little
	lsl.w	#8,d1
	move.b	d2,d1
.else
	lsl.w	#8,d2
	move.b	d1,d2
	move.w	d2,d1
.endif
	sub.w	d0,d0

.lp3:	tst.l	d0
	rts

.err4:	move.w	d0,d1
	move.l	#MDM_ERR_TX_TIMEOUT,d0		; transmit timeout
	move.w	d1,d0
	bra.b	.lp3	; retail short error return

;***************************************************************************
; mdm_shake: Starts handshake and waits for result
;
; Returns:	d0.w	-ive if error. 0 if ok
;		d1.w	connection status (see Phylon Docs)
;			in the form of: 86yz
;			y = connection Rate
;				0	Undetermined
;				1	1200/75
;				2	75/1200
;				3	0-300
;				4	1200
;				5	2400
;				6	4800
;				7	7200
;				8	9600 Non-trellis
;				9	9600
;				A	12000
;				B	14400
;				C	16800
;				D	19200
;			z = connection mode
;				0	Undetermined
;				1	V.32
;				2	V.32terbo/V.32bis
;				3	V.22bis
;				4	V.22
;				5	Bell 212
;				7	V.21
;				8	Bell 103
;				9	V.23
;				A	V.27
;				B	V.29
;				C	V.33
;				D	V.17
;				
;		d2,3,4	trashed
; Will timeout after n seconds
; so only call this when Answerer is ready to handshake too
; 'Speaker is turned off if handshake succeeds
;***************************************************************************
;
; _MDMshake: like mdm_shake, but returns positive success code of
;    00yz (see above) in d0.w
;
_MDMshake::
	movem.l	d2-d4,-(sp)
	bsr	mdm_shake
	bmi.b	.ret
	move.w	d1,d0
	and.w	#$00ff,d0
.ret:
	movem.l	(sp)+,d2-d4
	rts

mdm_shake::
	jsr	_Msg3ToUser	; report beginning of handshake
;	move.w	#$b0ff,d1	;turn voice off
;	bsr	mdm_cmd
;	bmi	.out
;	cmp.w	#$b0ff,d1
;	bne	.err_cmd
	move.w	#M_SHAKE,d1	; Send 'Start Handshake'
	bsr	mdm_cmd
	bmi	.out
	cmp.w	#M_SHAKE,d1
	bne	.err_cmd

	moveq	#-1,d4	; retail short form; timeout after 64 seconds
.lp1:
	move.w	#M_HSTATUS,d1	; Poll handshake status
	bsr	mdm_cmd
	bmi	.out		; error received
	move.w	d1,d0
	and.w	#$ff00,d0
	cmp.w	#M_HDONE,d0
	beq	.ok_shake

.lp4:	and.w	#$f000,d0
	cmp.w	#$8000,d0
	bne	.err_reply

	move.w	#27000,d3
.ll0:	move.l	(a7),(a7)
	dbra	d3,.ll0			;wait

	sub.l	#1,d4
	bne.b	.lp1	; retail short 8-bit loop branch
	move.l	#MDM_ERR_HS_TIMEOUT,d0		; timeout on handshake
	move.w	#M_HSTATUS,d0		; last command sent
	bra	.out

.err_cmd:
	move.l	#MDM_ERR_CMD_REPLY,d0		; Command reply error
	move.w	#M_SHAKE,d0		; last command sent
	bra	.out

.err_reply:
	move.l	#MDM_ERR_HANDSHAKE,d0		;status reply error
	move.w	d1,d0
	bra	.out

.ok_shake:
.if test_modem
	move.w	#$0002,d1
	bsr	mdm_cmd		;turn speaker off
	bmi	.out
	cmp.w	#$0002,d1
	beq .foo ;	.lp3b
	move.l	#MDM_ERR_CMD_REPLY,d0
	bra	.out
.endif
.foo:	bsr	_Wait1
	bsr	_MDMtxp
;.lp3:	jsr	_MDMstat
;	bmi	.out
;	cmp.w	#15,d0
;	bne	.lp3
	bsr	mdm_rxp
;	bmi	.out
;	move.w	#$b000,d1
;	bsr	mdm_cmd
;	bmi	.out
;	cmp.w	#$b000,d1
;	beq	.lp3b
;	move.l	#MDM_ERR_CMD_REPLY,d0
;	bra	.out
.lp3b:	moveq	#0,d0
.out:	tst.l	d0
	rts


;*****************************************
; Wait 1 second
; Gets:		Nowt
; Returns:	Nowt
;*****************************************
_Wait1::	                ; load up a countdown
	movem.l	d0-d1,-(a7)
        move.w  #20,d1		; about a second
.loopwt2:
	move.w	#-1,d0
.loopwt1:
        dbra    d0,.loopwt1
        dbra    d1,.loopwt2
	movem.l	(a7)+,d0-d1
	rts			; end of wait 
;*****************************************
;Initialize the Jag UART
;*****************************************
uartinit::
	move.w	#UCLK_57600,u_clk	; baud rate
	move.w	#clrerr+ctl_init,u_ctrl	; clear all errors

	move.w	#-1,d0			; wait
.lp1:	dbra	d0,.lp1

	move.w	#clrerr+ctl_init,u_ctrl	; clear all errors again
	move.w	u_data,d0		; read any old data
	move.w	#clrerr+ctl_init,u_ctrl	; clear all errors again
	move.w	u_data,d0		; ... both buffers
	move.w	#clrerr+ctl_init,u_ctrl	; clear all errors again

	move.l	#0,_MDMin

	move.w	#$10, $F10020	; async serial irq
	rts
;***************************************************************************
;
; Send a 16-bit command to modem
;
;
; Gets: 	d1.w	16 bit command
; Returns:	d0	-ive if error
;		d1	16 bit reply
;		d2	trashed
;***************************************************************************
;
; _MDMcmd: like mdm_cmd, but takes command on stack
;
_MDMcmd::
	move.w	4(sp),d1
	move.l	d2,-(sp)
	bsr	mdm_cmd
	move.l	(sp)+,d2
	rts

mdm_cmd:
	bsr	mdm_pair	; send the command
	bmi	.lp3
.lp7:
	bsr	getb1		;get kludge byte
	bmi	.lp3
	cmp.b	#$ff,d1
	beq	.lp1
	cmp.b	#$fe,d1
	beq	.lp1
	move.l	#MDM_ERR_SYNC,d0
	move.b	d1,d0
	bra	.lp3

.lp1: 	bsr	getb1		; get first status byte
	bmi	.lp3
	move.b	d1,d2

	bsr	getb1		; get next status byte
	bmi	.lp3
.if little
	lsl.w	#8,d1
	move.b	d2,d1
	move.w	d1,d2
.else
	lsl.w	#8,d2
	move.b	d1,d2
	move.w	d2,d1
.endif
	and.w	#$ff00,d2
	cmp.w	#$a400,d2
	bne	.lp2
	btst	#0,d1
	beq.b	.lp7	; original 8-bit retry branch
	move.l	#MDM_ERR_LOST_LINE,d0	;lost line
	move.w	d1,d0
	bra	.lp3
.lp2:	cmp.w	#$f000,d2
	beq	.lp6
	cmp.w	#$f300,d2
	bne	.lp5
.lp6:	move.l	#MDM_ERR_UNX_COMM,d0	;unexpected communication packet
	move.w	d1,d0
	bra	.lp3
.lp5:	cmp.w	#$b100,d2
	bne	.lp4
	move.l	#MDM_ERR_CALL_WAITING,d0	;call waiting signal
	move.w	d1,d0
	bra	.lp3
.lp4:
	sub.l	d0,d0
	move.w	d1,d0
.lp3:	tst.l	d0		;set the condition codes correctly
	rts

***************************************************************************
*
*  Reads a triplet from the buffer.  Handles $A4 packets, call waiting,
*  and bogus kludge bytes.
*
***************************************************************************
mdm_getdata::
	bsr	getb1		;get kludge byte
	bmi	.lp3
	cmp.b	#$ff,d1
	beq	.lp1
	cmp.b	#$fe,d1
	beq	.lp1
	move.l	#MDM_ERR_SYNC,d0
	move.b	d1,d0
	bra	.lp3

.lp1: 	bsr	getb1		; get first data byte
	bmi	.lp3
	move.b	d1,d2

	bsr	getb1		; get next data byte
	bmi	.lp3
.if little
	lsl.w	#8,d1
	move.b	d2,d1
	move.w	d1,d2
.else
	lsl.w	#8,d2
	move.b	d1,d2
	move.w	d2,d1
.endif
	and.w	#$ff00,d2
	cmp.w	#$a400,d2
	bne	.lp2
	btst	#0,d1
	beq.b	mdm_getdata	; original 8-bit retry branch
	move.l	#MDM_ERR_LOST_LINE,d0	;lost line
	move.w	d1,d0
	bra	.lp3
.lp2:	cmp.w	#$b100,d2
	bne	.lp4
	move.l	#MDM_ERR_CALL_WAITING,d0	;call waiting signal
	move.w	d1,d0
	bra	.lp3
.lp4:	cmp.w	#$f000,d2
	beq	.lp5
	cmp.w	#$f300,d2
	beq	.lp5
	move.l	#MDM_ERR_UNX_NONCOMM,d0
	move.w	d1,d0
	bra	.lp3
.lp5:	sub.l	d0,d0
	move.w	d1,d0
.lp3:	tst.l	d0		;set the condition codes correctly
	rts

;***************************************************************************
;
; Send a 16-bit command to modem, without waiting for a reply
;
;
; Gets: 	d1.w	16 bit command
; Returns:	d0	-4 if error
;		d1	16 bit reply
;		d2	trashed
;***************************************************************************
mdm_pair:			; send a pair of bytes
	move.l	#250000,d2	; 1 second timeout
.lp1:
	move.w	u_stat,d0	;pick up transmit buffer empty status
	btst.l	#u_tbe,d0	;
	bne	.lp4		;br if transmit buffer full
	sub.l	#1,d2
	bne.b	.lp1	; retail short modem UART transmit poll
	bra	.err4
.lp4:
	move.w	d1,u_data	; send that byte

	move.l	#250000,d2	; 1 second timeout
	lsr.l	#8,d1
.lp2:
	move.w	u_stat,d0	;pick up transmit buffer empty status
	btst.l	#u_tbe,d0	;
	bne	.lp5		;br if transmit buffer full
	sub.l	#1,d2
	bne.b	.lp2	; retail short modem UART transmit poll
	bra	.err4
.lp5:
	move.w	d1,u_data	; send that byte

	sub.w	d0,d0
.lp3:
	rts

.err4:	move.l	#MDM_ERR_TX_TIMEOUT,d0		; transmit timeout
	bra.b	.lp3	; retail 8-bit backward branch

;***************************************************************************
; get a byte...
;
; Gets:		nowt
;		d1.l	timeout/4us
; Returns:	d0.w	-1 if error.  upper word = u_stat
;		d1.b	data byte 
; Will timeout after about 4 seconds
;***************************************************************************
getb1:
  	move.l	#250000,d1	; 4	 seconds.  Loop is 226 cycles
;
; wait for a byte to arrive
;
getb:
	movem.l	d1/a0/a1,-(sp)
	jsr	_MDMget
	movem.l	(sp)+,d1/a0/a1
	tst.w	d0		; did we get a byte?
	bpl.b	.ret
	subq.l	#1,d1
	bne.b	getb
.err:
	move.l	#MDM_ERR_DEAD,d0
	rts
.ret:
	move.l	d0,d1
	sub.l	d0,d0
	rts

;***************************************************************************
;
; Send a 4 byte priority Data Packet to modem
;
;
; Gets: 	d1.l		4 byte data packet. Sent LSByte first
; Returns:	d0		-1 if error
;		d1,d2,d3,d4	trashed
;***************************************************************************
; _MDMtxp: like mdm_txp, but data byte comes in on stack
_MDMtxp::
	move.l	4(sp),d1
	movem.l	d2-d4,-(sp)
	bsr	mdm_txp
	movem.l	(sp)+,d2-d4
	rts

mdm_txp:
	move.l	d1,d3		; save the data
	move.w	#3,d4		; counter
 
.lp1:	move.w	#M_TXDATA,d1	; transmit data command
	move.b	d3,d1		; ..plus data byte
	lsr.l	#8,d3		; (shift ready for next one)
	bsr	mdm_pair	; send it
	bmi	.lp2
	dbra	d4,.lp1
	sub.l	d0,d0
.lp2:
	rts

;***************************************************************************
;
; Get a 4 byte priority Data Packet from modem
; Will wait almost forever (about 64 seconds)
;
; Gets: 	nowt
; Returns:	d0.w	-ive if error
;		d1-d4	trashed
;		d5.l	data packet
;***************************************************************************
;_MDMrxp: like mdm_rxp, but a pointer to where to put the data packet gets
; sent in on the stack
;
_MDMrxp::
	movem.l	d2-d5,-(sp)
	bsr	mdm_rxp
	move.l	d5,d1
	movem.l	(sp)+,d2-d5
	move.l	4(sp),a0
	move.l	d1,(a0)
	rts

mdm_rxp:

	move.w	#3,d3		; get 4 bytes
	sub.l	d5,d5		; clear result register

.lp1:
	bsr	mdm_getdata
	bmi	.exit
	move.w	d0,d1
	and.w	#$ff00,d1
	cmp.w	#$f300,d1
	beq	.err1
	ror.l	#8,d5
	and.w	#$00ff,d0
	rol.w	#8,d0
	swap	d5
	or.w	d0,d5
	swap	d5
	dbra	d3,.lp1

	bsr	mdm_getdata
	bmi	.exit
	move.w	d0,d1
	and.w	#$ff00,d1
	cmp.w	#$f300,d1
	bne	.err2		;not $f3, must be $f0.  Oops.
	move.w	d0,d1
	cmp.w	#$f301,d1	;is the packet OK?
	beq	.out
	move.l	#MDM_ERR_CHECKSUM,d0
	move.w	d1,d0
.out:	tst.l	d0
.exit:	rts
.err1:	move.w	d0,d1
	move.l	#MDM_ERR_PHASE_F3,d0
	move.w	d1,d0
	bra.b	.out
.err2:	move.w	d0,d1
	move.l	#MDM_ERR_PHASE_F0,d0
	move.w	d1,d0
	bra.b	.out

;***************************************************************************
; mdm_dial
; dtmf (tone) dial a string, and set up this modem as the caller
; NOTE: CALLER MUST ALWAYS CALL THIS ROUTINE, EVEN IF DIAL STRING =$FF (NULL)
; 
; Gets: 	a0		pointer to dtmf string.
;
; Returns:	d0.w		-ive if error
;		d1,2,3,4	trashed
;
; DTMF String format:
; dc.b	$xn		x = 0, n  = 0 1 2 3 4 5 6 7 8 9 a b c d e f
;			dtmf tone = 0 1 2 3 4 5 6 7 8 9 * # a b c d
;			x = 1, n  = 0 --> pause 1 second
;			x = f, n  = f --> string terminator
;***************************************************************************
;
; _MDMdial: dummy for now, must be called
;
dummydial:
	dc.b	$ff,$ff

_MDMdial::
	movem.l	d2-d4,-(sp)
	lea	dummydial,a0
	bsr	mdm_dial
	movem.l	(sp)+,d2-d4
	rts

mdm_dial:
	move.w	#M_CONFG1,d1	; Set up this modem as the caller
	bsr	mdm_cmd		; (this is necessary if no digit is dialled)
.lp5:
.finish:	;wait for dialing to finish
	move.w	#$8c00,d1
	bsr	mdm_cmd
	bmi	.err
	and.b	#$f0,d1
	cmp.b	#$10,d1
	beq.b	.finish

	move.b	(a0)+,d1	; Build the command
	cmp.b	#$ff,d1
	beq	.ok_dial
	cmp.b	#$10,d1		; pause
	bne	.lp1
	bsr	_Wait1
.lp1:
	andi.w	#$000f,d1
	ori.w	#M_DIALD,d1		
	move.w	d1,d3
	bsr	mdm_cmd
	bmi	.lp2
	cmp.w	d1,d3		; response ok?
	beq.b	.lp5
.err:	move.l	#MDM_ERR_DIAL+$8c00,d0	; mdm_dial response error
	tst.l	d0		;pass the error on up
.lp2:	rts
.ok_dial:
	sub.l	d0,d0		; all done ok
	rts

;***************************************************************************
; mdm_wtone
; wait 5 seconds for dial tone
;
; Gets:		nowt
;
; Returns:	d0.w		-ive if error
;		d1,d2,d3	trashed
;***************************************************************************************
mdm_wtone:
	move.w	#5000,d3	; wait up to 5 seconds for tone
.lp4:
	move.w	#M_DTDET,d1	; Look for dial tone
	bsr	mdm_cmd		;
	bmi	.lp2
	cmp.w	#M_DTDET,d1	;
	beq	.ok_tone
	dbra	d3,.lp4
.err_tone:
	move.l	#MDM_ERR_NO_TONE,d0		; No mdm_dial tone
	bra	.lp2
.ok_tone:
	sub.l	d0,d0
.lp2:
	rts

;***************************************************************************
; mdm_hangup
; 
; Gets: 	nothing
;
; Returns:	d0.w		-ive if error
;		d1,d2		trashed
;***************************************************************************
;
;

_MDMhangup::
mdm_hangup:
	move.w	#$9000,d1
	bsr	mdm_cmd
	bmi	.lp2
	cmp.w	#$9000,d1
	bne.b	mdm_hangup
.lp1:
;	move.w	#$a040,d1
;	bsr	mdm_cmd
;	bmi	.lp2
;	cmp.w	#$a040,d1
;	bne	.lp1
	sub.l	d0,d0
.lp2:	rts


;***************************************************************************
; mdm_call
; 
; Gets: 	nothing
;
; Returns:	d0.w		-ive if error
;		d1,d2		trashed
;***************************************************************************
;
;

callSequence:
	dc.w $000f	;Enable command echo
	dc.w $b000	;Enable analog line to headset connection
	dc.w $2c80	;set modem as caller, enable call waiting detection
	dc.w $3952	;set misc. configuration
	dc.w $a021	;Set target error rate to better than 1 in 1.0e+6 bits (ie minimum)
	dc.w $f207	;Enable unsolicited error detection codes
	dc.w $b602	;Enable error detection mode
	dc.w $b504	;Set data packet size to $04 bytes
	dc.w $b405	;Set voice packet size to 80 bytes
	dc.w $a3fe ;$a37e	;Enable loss of line detection
	dc.w $a060	;Go off hook

callSequenceLength	equ 11

callerGuardToneSequence:
	dc.b 1,2,3,4,5,6,7,8,9,0

callerGuardSequenceLength	equ 10


_MDMcall::
	movem.l	d1-d4,-(sp)
	move.w	#callSequenceLength-1,d3
	lea	callSequence,a0
.loop:	move.w	(a0),d1
	bsr	mdm_cmd
	bmi	.out
	cmp.w	(a0)+,d1
	bne	.cmderr
	dbra	d3,.loop
.if real_line
	bsr	mdm_wtone	;wait 5 seconds for dial tone
	bmi	.out
.endif
	move.l	20(sp),a0	; get address of phone number
	bsr	mdm_dial
	bmi	.out

	move.w	#answerGuardSequenceLength-1,d4
	lea	answerGuardToneSequence,a0
.tloop:
	jsr	_OfferHangup
	bne	.hangup
	move.w	#$6800,d1
	bsr	mdm_cmd
	bmi	.out
.tloop1:
	cmp.w	#$fffe,d1
	beq.b	.tloop		;no tone yet
	cmp.b	(a0)+,d1
	bne	.wrong		;wrong tone
	move.w	d1,d3	;save the current tone
.wait:	move.w	#$6800,d1
	bsr	mdm_cmd
	bmi	.out
	cmp.w	d1,d3
	beq.b	.wait	;wait until it stops
	dbra	d4,.tloop1	;go get the next one

	move.w	#61000,d4	;wait a long time to let the line go silent
.spin:	move.l	(a7),(a7)
	move.l	(a7),(a7)
	move.l	(a7),(a7)
	move.l	(a7),(a7)
	move.l	(a7),(a7)
	dbra	d4,.spin

	move.w	#callerGuardSequenceLength-1,d4
	lea	callerGuardToneSequence,a0
.sloop:	move.w	#$8a20,d1
	or.b	(a0)+,d1
	move.w	d1,d3
	bsr	mdm_cmd
	bmi	.out 
	cmp.w	d1,d3
	bne	.cmderr

.finish:	;wait for dialing to finish
	jsr	_OfferHangup
	bne	.hangup
	move.w	#$8c00,d1
	bsr	mdm_cmd
	bmi	.out
	and.b	#$f0,d1
	cmp.b	#$0,d1
	bne.b	.finish

	dbra	d4,.sloop

	move.w	#$2c80,d1	;make this modem a caller
	bsr	mdm_cmd
	bmi	.out
	bsr	mdm_shake
	bmi	.out
	bsr	_Wait1
	sub.l	d0,d0
	move.b	d1,d0
.out:	tst.l	d0
	movem.l	(sp)+,d1-d4
	rts
.wrong:
	move.l	#MDM_ERR_WRONG_TONE,d0
	move.w	d1,d0
	bra.b	.out
.cmderr:
	move.l	#MDM_ERR_CMD_REPLY,d0
	move.w	d1,d0
	bra.b	.out
.hangup:
	bsr	mdm_hangup
	move.l	#MDM_ERR_USER_HANGUP,d0
	bra.b	.out
  
;***************************************************************************
; mdm_answer
; 
; Gets: 	nothing
;
; Returns:	d0.w		-ive if error
;			d0.w		handshake status, unless error
;		d1,d2		trashed
;***************************************************************************
;
;

answerSequence:
	dc.w $000f	;Enable command echo
	dc.w $b000	;Enable analog line to headset connection
	dc.w $2480	;set modem as answerer, enable call waiting detection
	dc.w $3952	;set misc. configuration
	dc.w $a021	;Set target error rate to better than 1 in 1.0e+6 bits (ie minimum)
	dc.w $f207	;Enable unsolicited error detection codes
	dc.w $b602	;Enable error detection mode
	dc.w $b504	;Set data packet size to $04 bytes
	dc.w $b405	;Set voice packet size to 80 bytes
	dc.w $a3fe ;$a37e	;Enable loss of line detection
	dc.w $a060	;Go off hook

answerSequenceLength	equ 11

answerGuardToneSequence:
	dc.b 0,9,8,7,6,5,4,3,2,1

answerGuardSequenceLength	equ 10


_MDMreconnect::
	movem.l	d1-d4/a0,-(sp)
	bra	mdm_reconnect

_MDManswer::
mdm_answer:
	movem.l	d1-d4/a0,-(sp)
	move.w	#answerSequenceLength-1,d3
	lea	answerSequence,a0
.loop:	move.w	(a0),d1
	bsr	mdm_cmd
	bmi	.out
	cmp.w	(a0)+,d1
	bne	.cmderr
	dbra	d3,.loop
	bra	mdm_reconnect
.out:	movem.l	(sp)+,d1-d4/a0
	rts
.cmderr:
	move.l	#MDM_ERR_CMD_REPLY,d0
	move.w	d1,d0
	bra.b	.out

mdm_reconnect::
	jsr	_Msg1ToUser	;Prompt user to hang up other lines
	bne	.hangup		;He told us to quit

	move.w	#answerGuardSequenceLength-1,d4
	lea	answerGuardToneSequence,a0
.sloop:	move.w	#$8a20,d1
	or.b	(a0)+,d1
	move.w	d1,d3
	bsr	mdm_cmd
	bmi	.out
	cmp.w	d1,d3
	bne	.cmderr

.finish:	;wait for dialing to finish
	jsr	_OfferHangup
	bne	.hangup
	move.w	#$8c00,d1
	bsr	mdm_cmd
	bmi	.out
	and.b	#$f0,d1
	cmp.b	#$10,d1
	beq.b	.finish

	dbra	d4,.sloop

	move.w	#48000,d4	;wait awhile
.spin:	move.l	(a7),(a7)
	move.l	(a7),(a7)
	dbra	d4,.spin

	move.l	#10000,timeout	;adjust this to suit
	move.w	#callerGuardSequenceLength-1,d4
	lea	callerGuardToneSequence,a0
.tloop:
	subq.l	#1,timeout
	bpl	.guard_tone_ok
	jsr	_Msg2ToUser	;tell the user that there's no response
	bne	.hangup
	bra	mdm_reconnect
.guard_tone_ok:
	move.w	#$6800,d1
	bsr	mdm_cmd
	bmi	.out
.tloop1:
	cmp.w	#$fffe,d1
	beq.b	.tloop		;no tone yet
	cmp.b	(a0)+,d1
	bne	.wrong		;wrong tone
	move.w	d1,d3	;save the current tone
.wait:	move.w	#$6800,d1
	bsr	mdm_cmd
	bmi	.out
	cmp.w	d1,d3
	beq.b	.wait	;wait until it stops
	dbra	d4,.tloop1	;go get the next one
	
	move.w	#$2480,d1	;make this modem an answerer
	bsr	mdm_cmd
	bmi	.out
	bsr	mdm_shake
	bmi	.out
	bsr	_Wait1
	sub.l	d0,d0
	move.b	d1,d0
.out:	movem.l	(sp)+,d1-d4/a0
	rts
.wrong:
	move.l	#MDM_ERR_WRONG_TONE,d0
	move.w	d1,d0
	bra.b	.out
.cmderr:
	move.l	#MDM_ERR_CMD_REPLY,d0
	move.w	d1,d0
	bra.b	.out
.hangup:
	bsr	mdm_hangup
	move.l	#MDM_ERR_USER_HANGUP,d0
	bra.b	.out


**************************************************************************
*
*  This is a stub for a user routine that offers the player the option to
*  interrupt the handshaking sequence and hang up the phone.  If it returns
*  nonzero, the main code will interrupt.
*
**************************************************************************
_OfferHangup::
	sub.l	d0,d0
	rts

**************************************************************************
*
*  This is a stub for a user routine that asks the player to hang up other
*  phone lines.  It returns zero for "ok, proceed" and nonzero for "hang up"
*
*
**************************************************************************
_Msg1ToUser::
	sub.l	d0,d0
	rts

**************************************************************************
*
*  This is a stub for a user routine that tells the player that the other 
*  modem has not responded to the tone sequence.  It returns zero for "ok,
*  proceed" and nonzero for "hang up".
*
**************************************************************************
_Msg2ToUser::
	sub.l	d0,d0
	rts

**************************************************************************
*
*  This is a stub for a user routine that to tell the player that the modem
*  handshake is in progress.  It has no return value.
*
**************************************************************************
_Msg3ToUser::
	rts
	; The 1994 object layout reserved two 68000 NOP words before READJOY.S.
	nop
	nop

.bss


timeout:
	ds.l	1
.end
 
