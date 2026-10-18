/*
 * data packet definitions for club drive
 * modem support
 */

typedef struct {
	unsigned	type:3;		/* packet type: see below */
	unsigned	chksum:5;	/* packet checksum */
#define CHKSUM_MASK	0x1f
	unsigned char	data1;
	unsigned char	data2;
	unsigned char	data3;
} Packet;

union P_or_L {
	Packet	P;
	long	L;
};

/* packet types */
/* type 0 is reserved */

#define P_POSABS1	1
	/* absolute position packet, part 1: X position, high byte of Y position */
#define P_POSABS2	2
	/* absolute position packet, part 2: lo byte of Y position, Z position */
#define P_BAND		3
	/* current band packet: lo 3 bytes are band header address */
#define P_ANGLES	4
	/* alpha, beta, gamma for car matrix */
#define P_SCORE		5
	/* my score (hi), my score (lo), extra: the extra byte is either a power ball index, or a marker for who's it */

#define MIN_TYPE 1
#define MAX_TYPE 5
