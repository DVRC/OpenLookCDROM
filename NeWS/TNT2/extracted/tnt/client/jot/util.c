/*
 *	@(#)util.c 1.5 91/02/20 Copyright 1990-91 Sun Microsystems
 *
 * This file is a product of Sun Microsystems, Inc. and is provided for
 * unrestricted use provided that this legend is included on all tape
 * media and as a part of the software program in whole or part.  Users
 * may copy or modify this file without charge, but are not authorized to
 * license or distribute it to anyone else except as part of a product
 * or program developed by the user.
 * 
 * THIS FILE IS PROVIDED AS IS WITH NO WARRANTIES OF ANY KIND INCLUDING THE
 * WARRANTIES OF DESIGN, MERCHANTIBILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE, OR ARISING FROM A COURSE OF DEALING, USAGE OR TRADE PRACTICE.
 * 
 * This file is provided with no support and without any obligation on the
 * part of Sun Microsystems, Inc. to assist in its use, correction,
 * modification or enhancement.
 * 
 * SUN MICROSYSTEMS, INC. SHALL HAVE NO LIABILITY WITH RESPECT TO THE
 * INFRINGEMENT OF COPYRIGHTS, TRADE SECRETS OR ANY PATENTS BY THIS FILE
 * OR ANY PART THEREOF.
 * 
 * In no event will Sun Microsystems, Inc. be liable for any lost revenue
 * or profits or other special, indirect and consequential damages, even
 * if Sun has been advised of the possibility of such damages.
 * 
 * Sun Microsystems, Inc.
 * 2550 Garcia Avenue
 * Mountain View, California  94043
 */

/* utility routines */

#include "jot.h"
#include "jot_private.h"
#include "util.h"

int Jot_Errno;

char *
jot_alloc(size)
int size;
{
    char    *ptr;

    ptr = malloc(size);
    if (ptr == 0)
	Jot_Errno = Jot_EMEMORY;

    return ptr;
}

char *
jot_realloc(ptr, size)
char	*ptr;
int	size;
{
    if (ptr == 0)
	return jot_alloc(size);
    if ((ptr = realloc(ptr, size)) == 0)
	Jot_Errno = Jot_EMEMORY;

    return ptr;
}

void
jot_free(ptr)
char	*ptr;
{
    (void) free(ptr);
}

boolean
wire_RememberToken(tarray, wire, token)
wire_TokenArray	*tarray;
wire_Wire	wire;
int		token;
{
    int ocount = tarray->count;

    if (wire >= ocount) {
	int nbytes, n, *ip;

	tarray->count = wire + 1;
	nbytes = sizeof (int) * tarray->count;
	if (ocount == 0)
	    tarray->array = (int *) malloc(nbytes);
	else
	    tarray->array = (int *) realloc(tarray->array, nbytes);
	n = tarray->count - ocount;
	for (ip = &tarray->array[ocount]; --n >= 0; )
	    *ip++ = -1;
    }
    tarray->array[wire] = token;

    return TRUE;
}
