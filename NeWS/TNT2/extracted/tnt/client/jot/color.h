/*
 *	@(#)color.h 1.9 91/02/20 Copyright 1990-91 Sun Microsystems
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

#ifndef _COLOR_INCLUDED_
#define _COLOR_INCLUDED_

#include <NeWS/c_varieties.h>
#include <NeWS/jot/color_cps.h>

struct color {
    unsigned char    h, s, b;	/* 0-255 */
    wire_TokenArray tokens;	/* server file token indexed by wire */
    struct color    *next;	/* next in hash chain */
};

EXTERN_FUNCTION( struct color	*color_create,	(int r, int g, int b) );
extern struct color	*current_color;

#define color_usecolor(c, w) \
    (((c) != current_color) ? \
     (current_color = c, \
      ps_usecolor(wire_RetrieveToken(&(c)->tokens, (w)))) : \
     0)

#define color_invalidate(w) (current_color = 0)

#endif
