/*
 * C definitions for band data
 */

/*
 * special surface structure
 */
struct spsurf {
	long	portal_bnd;	/* pointer to destination band, or 0 if not a portal */
	long	x,y,z;		/* location of arrival within destination band */
	long	sound;		/* info about sounds to be played on collision, or 0 */
	long	surf_prop;	/* special surface properties, or 0 */
	long	powerup;	/* 2 more longs, reserved, to make 32 bytes in all */
	long	dummy;
};

struct bndheader {
	long	flags;
	int	numpnts;
	int	numvectors;
	int	numdividers;
	int	numedges;
	int	numcps;
	int	numcolors;

	long	ox,oy,oz;
	long	radius;

	struct spsurf *prop_list;

	int	*dividers;
	int	*edges;
	int	*points;
	int	*surfs;
	int	*surfs_end;
	int	*tree;
	int	*textures;
	int	*colors;
	long	*cameras;

	int	*rotpoints;
	int	*tvectors;
	int	*tcolors;
	int	*tedges;
	int	*tdividers;
	int	*tclose_list;
	int	*tpnts;
	int	*tpolys;

	int	*matrix;
	long	num_extras;
	int	tinit;
	int	use_count;
	struct	bndheader *bnd_list[1];
};

