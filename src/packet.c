/*
 * club drive packet handler
 */

#include "packet.h"
#include "bndhead.h"

long PACKsent;
long PACKerr;
long PACKrec;

/*
 * calculate a checksum
 */
int
chksum(int type, int data1, int data2, int data3)
{
	int csum;

	csum = 17*type + 11*data1 + 7*data2 + 3*data3; 
	return csum & CHKSUM_MASK;
}

/*
 * create a 4 byte packet, including checksum
 */
static long
buildpacket(int type, int data1, int data2, int data3)
{
	union P_or_L u;

	data1 &= 0x00ff;
	data2 &= 0x00ff;
	data3 &= 0x00ff;

	u.P.type = type;
	u.P.chksum = chksum(type,data1,data2,data3);
	u.P.data1 = data1;
	u.P.data2 = data2;
	u.P.data3 = data3;

	return u.L;
}

/*
 * check for a valid packet: this is one that passes
 * checksum, and has a good data type
 */
static int
validpacket(Packet P)
{
	int c;

	if (P.type < MIN_TYPE || P.type > MAX_TYPE)
		return 0;
	c = chksum(P.type, P.data1, P.data2, P.data3);
	if (c != P.chksum)
		return 0;
	return 1;
}

/*
 * procedure: try to resync the data stream
 */
static int num_consecutive_errors;

static void
resync(union P_or_L u)
{
	long c;

/* allow for a few bad packets before panicking */
	if (num_consecutive_errors++ < 4) {
		return;
	}
#if 0
	for(;;) {
		c = MDMget();		/* try getting some data */
		if (c < 0) break;
		u.L= (u.L << 8) | (c & 0x00ff);
		c = MDMget();
		if (c < 0) break;
		if ((c & 0x00ff) != 0xf0)	/* expect an M_RXDATA */
			break;
		if (validpacket(u.P)) break;
	}
#else
	fatal(0xfeeddeaf);
#endif
}

/*
 * functions in play.s
 */
extern void setrelposn(int, int, int);
extern void setband(long);
extern void setangles(int, int, int);
extern long *getposn(void);
extern struct bndheader *getband(void);
extern void getangles(char *);
extern long getscore(void);
extern void setscore(long);

/*
 * process a 4 byte packet
 */
static int deltax, deltay, deltaz;
static int expectpos;			/* set when we're expecting a P_POSABS2 packet */

void
recpacket(long pl)
{
	union P_or_L u;

	u.L = pl;
	PACKrec++;

	if (!validpacket(u.P)) {
		PACKerr++;
		resync(u);
		return;
	}

	switch (u.P.type) {
	case P_POSABS1:
		/* we don't care about dropped P_POSABS2 packets, so don't check expectpos */
		deltax = (u.P.data1 << 8) | (u.P.data2);
		deltay = (u.P.data3 << 8);
		deltaz = 0;
		expectpos = P_POSABS2;
		break;
	case P_POSABS2:
		if (expectpos != P_POSABS2) {
			PACKerr++;
			resync(u);
			return;
		}
		deltay |= u.P.data1;
		deltaz = (u.P.data2 << 8) | (u.P.data3);
		setrelposn(deltax, deltay, deltaz);
		expectpos = P_POSABS1;
		deltax = deltay = deltaz = 0;
		break;
	case P_BAND:
		setband((u.L) & 0x00ffffffL);
		break;
	case P_ANGLES:
		setangles((int)u.P.data1, (int)u.P.data2, (int)u.P.data3);
		break;
	case P_SCORE:
		setscore((u.L) & 0x00ffffffL);
		break;
	default:
		break;
	}
	num_consecutive_errors = 0;
}


/*
 * figure out what 4 byte packet to send next
 * band info and score info should have the lowest priority,
 * except when one or the other have changed; then
 * they get the highest priority
 */
static int lastpack;			/* last packet type sent */
static long lastx, lasty, lastz;	/* last X,Y,Z position sent */
static struct bndheader *lastbnd;	/* last band reported */
static unsigned skippedband;
static int oddframe;
static long lastscore;

long
sendpacket(void)
{
	int nextpack;
	long nextband;
	int dx,dy,dz;
	struct bndheader *bnd;
	unsigned char d1,d2,d3;
	unsigned char angletemp[3];
	long *pos;

#if 0
	if (oddframe) {
		oddframe = 0;
		return 0L;		/* send no packet! */
	}
	oddframe = 1;
#endif

	bnd = getband();

	switch (lastpack) {
	case P_POSABS1:
		nextpack = P_POSABS2;
		break;
	case P_POSABS2:
		if (bnd != lastbnd || (++skippedband > 4)) {
			nextpack = P_BAND;
			skippedband = 0;
		} else
			nextpack = P_ANGLES;
		break;
	case P_ANGLES:
	case P_SCORE:
		nextpack = P_POSABS1;
		break;
	case P_BAND:
		nextpack = P_SCORE;
		break;
	default:		/* if in doubt, send the current band */
		nextpack = P_BAND;
		break;
	}

	if (!lastbnd)
		nextpack = P_BAND;

	switch (nextpack) {
	case P_POSABS1:
		pos = getposn();
		lastx = pos[0];
		lasty = pos[1];
		lastz = pos[2];
		dx = (lastx - lastbnd->ox) >> 12L;	/* remember, numbers are in 20.12 format! */
		dy = (lasty - lastbnd->oy) >> 12L;
		dz = (lastz - lastbnd->oz) >> 12L;
		d1 = (dx >> 8);
		d2 = (dx & 0x00ff);
		d3 = (dy >> 8);
		break;
	case P_POSABS2:
		dx = (lastx - lastbnd->ox) >> 12L;	/* remember, numbers are in 20.12 format! */
		dy = (lasty - lastbnd->oy) >> 12L;
		dz = (lastz - lastbnd->oz) >> 12L;
		d1 = (dy & 0x00ff);
		d2 = (dz >> 8);
		d3 = (dz & 0x00ff);
		break;
	case P_ANGLES:
		getangles(angletemp);
		d1 = angletemp[0];
		d2 = angletemp[1];
		d3 = angletemp[2];
		break;
	case P_BAND:
		skippedband = 0;
		lastbnd = bnd;
		nextband = (long)bnd;
		d1 = (nextband & 0x00ff0000L) >> 16;
		d2 = (nextband & 0x0000ff00L) >> 8;
		d3 = (nextband & 0x00ffL);
		break;
	case P_SCORE:
		lastscore = getscore();
		d1 = (lastscore & 0x00ff0000L) >> 16;
		d2 = (lastscore & 0x0000ff00L) >> 8;
		d3 = (lastscore & 0x00ffL);
		break;
	}

	lastpack = nextpack;
	PACKsent++;
	return buildpacket(nextpack,d1,d2,d3);
}

void
initpackets()
{
	lastpack = -1;		/* force a band report to start with */
	lastbnd = 0;
	num_consecutive_errors = 0;
	PACKsent = PACKrec = PACKerr = 0;
	oddframe = 1;		/* skip a frame */
}
