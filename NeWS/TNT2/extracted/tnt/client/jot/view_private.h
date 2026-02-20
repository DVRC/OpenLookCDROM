/*
 *	@(#)view_private.h 1.9 91/02/20 Copyright 1990-91 Sun Microsystems
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

#if !defined (VIEW_PRIVATE_H)
#define VIEW_PRIVATE_H

struct formatter_ops {		/* The set of procedure passed to
				 * scan_and_apply */
    int	(*handlestring) ();
    int	(*handleeol) ();
};

#include <NeWS/jot/cps.h>
#include <NeWS/jot/styles.h>

/* extra state information used by the formatter */
struct formatter_state {
    fixed       x0;		/* The x position of the string currently
				 * being assembled */
    fixed       x,
                y;		/* The current coordinate */
    fixed       spshim;		/* The size of the shim being added to spaces */
    fixed	xoffset;	/* Indentation that applies to this line */
    short       nsp;		/* The number of spaces in the line */
    short	ntabs;		/* number of tabs in a line */

    int         posatlastbreak;	/* The position in the text at the last
				 * word break */
    fixed       xatlastbreak;	/* The x coordinate at the last word break */
    struct formatter_info  fiatlastbreak;
    short	ascentatlastbreak;
    short	descentatlastbreak;
    JotView	*v;		/* view we're in */
};

struct lineinfo {		/* information about one line visible in a
				 * view */
    JotSpan	*text;		/* The text in the line */
    short	linelength;	/* The number of characters in the line */
    short	usedlength;	/* number of chars involved in line */
    unsigned	modified:1;	/* true iff this line has to be redrawn */
    unsigned	hascaret:1;	/* caret on this line? */
    unsigned	hasselection:1;	/* has one of the selections? */
    struct formatter_info fi;	/* properties at the beginning of the line */
    struct formatter_state fs;	/* formatter state information */
    fixed       cx0,
                cx1;		/* The first and last x coordinates on this
				 * line, for use in drawing selections */
    fixed	modx;		/* x position of first modified char in line */
    int		modpos;		/* position of first modification in line */
    short	lineascent;	/* maximum font ascent for this line */
    short	linedescent;	/* maximum font descent for this line */
};

struct fpoint {
    fixed       x,
                y;
};

/* position in a view */
struct view_coord {
    int		    pos;	/* pos we're matching against */
    struct fpoint   p;		/* X & Y coordinates */
    struct lineinfo *where;	/* the relevant line */
};

struct view_region {
    struct view_coord	begin;
    struct view_coord	end;
    int			style;	/* INVERT, UNDERLINE, STRIKETHRU */
};


#endif	/* VIEW_PRIVATE_H */
