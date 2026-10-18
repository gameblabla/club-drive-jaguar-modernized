/*
 *	allocpr.h
 */

void	*alloc(unsigned long);
void	free(void *);
char	*sbrk(unsigned long);
void    *PHalloc( unsigned long nb, long ph );
