;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Header File: OBJLIST.INC
;              Jaguar Object List Equates
;
; NOTICE: The EQU's in this file have been mostly removed from Atari
;         include file updates. Those EQU's remaining have been moved
;         to JAGUAR.INC. This file is for compatibility reasons only.
;
        

; Restored Club Drive's pre-1995 pseudo-object offsets and flags.
; The newer SDK's objlist.inc had dropped the original definitions.
OBJ_SIZE    EQU 26
O_XPOS      EQU 0
O_YPOS      EQU 2
O_DATA      EQU 4
O_HEIGHT    EQU 8
O_DWIDTH    EQU 10
O_IWIDTH    EQU 12
O_FLAGS     EQU 14
O_FIRSTPIX  EQU 15
O_TYPE      EQU 16
O_DEPTH     EQU 17
O_PITCH     EQU 18
O_INDEX     EQU 19
O_DESC      EQU 20
O_SCALE     EQU 22
O_HSCALE    EQU 25
DELETE_OBJ EQU $80
RELEASE_ON  EQU 8
RELEASE_OFF EQU 0
TRANS_ON    EQU 4
TRANS_OFF   EQU 0
RMW_ON      EQU 2
RMW_OFF     EQU 0
REFLECT_ON  EQU 1
REFLECT_OFF EQU 0
