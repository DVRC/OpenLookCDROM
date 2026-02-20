/*
 *	@(#)color.c 1.8 91/02/20 Copyright 1990-91 Sun Microsystems
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

#include <NeWS/wire/wire.h>
#include "cps.h"
#include "view.h"
#include "color.h"
#include "util.h"

struct color	*current_color;

#define HASHSIZE	64	/* power of two, please! */
#define hash(h, s, b)	(((h) << 3) + ((s) << 2) + ((b) << 1))

static struct color *color_ht[HASHSIZE];

static struct color *
color_lookup(h, s, b)
{
    struct color    *c;
    int		    hashval;

    hashval = hash(h, s, b) & (HASHSIZE - 1);
    for (c = color_ht[hashval]; c != 0; c = c->next)
	if (c->h == h && c->s == s && c->b == b)
	    break;

    return c;
}

static struct color *
color_add(h, s, b)
{
    struct color    *c;
    int		    hashval;

    if (h >= 256)
	h = 255;
    if (s >= 256)
	s = 255;
    if (b >= 256)
	b = 255;

    hashval = hash(h, s, b) & (HASHSIZE - 1);
    for (c = color_ht[hashval]; c != 0; c = c->next)
	if (c->h == h && c->s == s && c->b == b)
	    break;
    if (c == 0) {
	c = (struct color *) malloc(sizeof (struct color));
	bzero((char *) c, sizeof (struct color));
	c->h = h;
	c->s = s;
	c->b = b;
	c->next = color_ht[hashval];
	color_ht[hashval] = c;
    }

    return c;
}

/* create a color */
struct color *
color_create(h, s, b)
{
    struct color    *c;
    int		    token;
    wire_Wire	    wire;

    c = color_add(h, s, b);

    wire = wire_Current();
    if ((token = wire_RetrieveToken(&c->tokens, wire)) == -1) {
	wire_RememberToken(&c->tokens, wire, token = wire_AllocateTokens(wire, 1));
	ps_createhsbcolor(fixedi(c->h) / 256, fixedi(c->s) / 256,
			  fixedi(c->b) / 256, token);
    }
    return c;
}
