; structures for sort trees

;; Say it in english doc! -----------------------------------------------
;// node types
;
;// THE node - all nodes in a sort tree are tNodes
;struct tNode {
;	short int nDivs;	// number of dividers
;	short int nNodes;	// number of nodes (max of 16)
;	int dList[nDivs];
;	int nList[nNodes];	// high order bit tells node type (0-CP, 1-tNode)
;	nyble oList[2^nDivs][nNodes];
;	}
;
;; ----------------------------------------------------------------------

;struct tNode {
	tnNDs	equ	0
	tnNNs	equ	1
;	int dList[nDs];
		tnDList		equ	2
		tnDLSz		equ	2
;	int nList[nDs];
		tnNLSz		equ	2

;	nyble oList[2^tnNDs][tnNNs]

MACRO	RTS_TREE
		subqt	#8, R10
		loadp	(R10), R28
		movei	#G_HIDATA, R29 ;dataHi
		jump		(R28)
		subqt	#8, R10
ENDM

;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
