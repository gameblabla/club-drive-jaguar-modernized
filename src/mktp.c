/* mktp.c - make tPoly structure */

#define CAR_RADIUS 0x4000

#include "bndhead.h"
#include "allocpr.h"

#if 0
/* find the normalizer for a vector */
int
normi(long vx, long vy, long vz)
{
	long temp;
	int exp;
	if (vx < 0) vx = -vx;
	if (vy < 0) vy = -vy;
	if (vz < 0) vz = -vz;
	temp = vx | vy | vz;
	exp = 0;
	while (temp > 32767) {
		temp >>= 1;
		exp++;
	}
	return exp;
}
#endif

/*
 * allocate memory for the transformed data structures
 * return 1 for success, 0 for failure
 */
int alloc_it(struct bndheader *bnd)
{
	int numCPs, cp, numsides;
	int *polys;
	long tpolysize;

	bnd->tvectors = (int *)alloc(6L*bnd->numvectors);
	if (!bnd->tvectors) return 0;
	if (bnd->numcolors) {
		bnd->tcolors = (int *)alloc(2L*bnd->numcolors);
		if (!bnd->tcolors) return 0;
	} else {
		bnd->tcolors = 0;
	}
	bnd->tedges = (int *)alloc(16L*bnd->numedges);
	if (!bnd->tedges) return 0;
	bnd->tdividers = (int *)alloc((long)bnd->numdividers);
	if (!bnd->tdividers) return 0;
	bnd->tclose_list = (int *)alloc(2L*bnd->numdividers);
	if (!bnd->tclose_list) return 0;

	if (bnd->matrix) {
		bnd->rotpoints = (int *)alloc(6L*(bnd->numpnts+bnd->numvectors));
		if (!bnd->rotpoints) return 0;
	} else {
		bnd->rotpoints = bnd->points;
	}
	if ((bnd->flags & 1) == 0) {	/* collision detection is possible */
		tpolysize = 0;

		numCPs = bnd->numcps;
		polys = bnd->surfs;
		for (cp = 0; cp < numCPs; cp++) {
			while ((numsides = (*polys++) & 0x0f) != 0) {
				tpolysize += 12+(6*numsides);
				polys += 2+numsides;
			}
		}
		bnd->tpolys = (int *)alloc(tpolysize);
		if (!bnd->tpolys) return 0;
		bnd->tinit = 2;
	} else {
		bnd->tpolys = 0;
		bnd->tinit = 1;
	}
	return 1;
}


#if 0
void mktp(struct bndheader *bnd)
	{
	int *normals;
	int *dividers;
	int *edges, *points;
	int *polys, *tPolys, *polyBase;
	int numCPs; /* real value when we get bnd headers */
	int i, cp, numSides;
	long nx, ny, nz;
	long vx, vy, vz;
	int ve;
	long avgX=0, avgY=0, avgZ=0;
	int pnt, pntLast;
	long distance, maxDistance;
	/*------------------------------*/

	numCPs = bnd->numcps;
	normals = bnd->points+3*bnd->numpnts;
	dividers = bnd->dividers;
	edges = bnd->edges;
	points = bnd->points - 3;
	tPolys = bnd->tpolys;

	tPolys += 5;	/* 2 for radius (long) + 3 for center */
	polyBase = polys = bnd->surfs;

	for (cp=0; cp<numCPs; cp++) {
		while ((numSides = (*polys++) & 0xff) != 0) {
			i = 3*dividers[1+2*(*polys++)];
			/* get normal */
			nx = normals[i];
			ny = normals[i+1];
			nz = normals[i+2];
			/* get first point */
			pntLast = 3 * edges[2*(polys[0]&0x7fff) + ((polys[0]<0) ? 1:0)];
			avgX = avgY = avgZ = 0;

			for (i=0; i<numSides; i++) {
				/* get next pont */
				pnt = 3 * edges[2*(polys[i]&0x7fff) + ((polys[i]>=0) ? 1:0)];
				/* add for average */
				avgX += points[pnt];
				avgY += points[pnt+1];
				avgZ += points[pnt+2];

				/* cross prod for edge vector */
				vx = ny*(points[pnt+2]-points[pntLast+2]) - nz*(points[pnt+1]-points[pntLast+1]);
				vy = nz*(points[pnt  ]-points[pntLast  ]) - nx*(points[pnt+2]-points[pntLast+2]);
				vz = nx*(points[pnt+1]-points[pntLast+1]) - ny*(points[pnt  ]-points[pntLast  ]);
				ve = normi(vx, vy, vz);
				tPolys[i*3  ] = (int)(vx >> ve);
				tPolys[i*3+1] = (int)(vy >> ve);
				tPolys[i*3+2] = (int)(vz >> ve);
				/* next = last point */
				pntLast = pnt;
				}
			/* find center */
			tPolys[-3] = (int)(avgX /= numSides);
			tPolys[-2] = (int)(avgY /= numSides);
			tPolys[-1] = (int)(avgZ /= numSides);
			/* find radius */
			for (maxDistance=i=0; i<numSides; i++) {
				/* get next pont */
				pnt = 3 * edges[2*(polys[i]&0x7fff) + ((polys[i]>=0) ? 1:0)];
				if (maxDistance<(distance=(avgX-points[pnt])*(avgX-points[pnt])+
									(avgY-points[pnt+1])*(avgY-points[pnt+1])+
									(avgZ-points[pnt+2])*(avgZ-points[pnt+2])))
					maxDistance=distance;
				/* next = last point */
				pntLast = pnt;
				}
			*((long *)(tPolys-5)) = maxDistance + CAR_RADIUS;
			tPolys += 5 + (3*numSides);  /* don't bother long aligning */
			polys += 1 + numSides;
			}
		}
	}

#endif

void
free_bnd(struct bndheader *oldbnd) {
	struct bndheader **blist, *bnd;

	if (oldbnd) {
		blist = oldbnd->bnd_list;
		for(;;) {
			bnd = *blist++;
			if (!bnd) break;
			--bnd->use_count;
			if (bnd->use_count <= 0) {
				if (bnd->tvectors)
					free(bnd->tvectors);
				if (bnd->tcolors)
					free(bnd->tcolors);
				if (bnd->tedges)
					free(bnd->tedges);
				if (bnd->tdividers)
					free(bnd->tdividers);
				if (bnd->tclose_list)
					free(bnd->tclose_list);
				if (bnd->matrix)
					free(bnd->rotpoints);
				if (bnd->tpolys)
					free(bnd->tpolys);
				bnd->tvectors = 0;
				bnd->tcolors = 0;
				bnd->tedges = 0;
				bnd->tdividers = 0;
				bnd->tclose_list = 0;
				bnd->tpnts = 0;
				bnd->tpolys = 0;
				bnd->tinit = 0;
				bnd->rotpoints = 0;
			}
		}
	}
}

/*
 * start to use a new band, replacing the old band
 */

void
use_bnd(struct bndheader *newbnd, struct bndheader *oldbnd)
{
	struct bndheader *bnd, **blist;
	extern void fatal();
/*
 * first, free the old band
 */
	free_bnd(oldbnd);

	if (!newbnd) fatal(0x11111111L);
/*
 * secondly, initialize the new bands that need it
 */
	blist = newbnd->bnd_list;
	for(;;) {
		bnd = *blist++;
		if (!bnd) break;
		if (!(bnd->tinit)) {
			if (!alloc_it(bnd)) {
				fatal(0xddddddddL);
			}
			bnd->use_count = 1;
		} else {
			bnd->use_count++;
		}
	}
}
