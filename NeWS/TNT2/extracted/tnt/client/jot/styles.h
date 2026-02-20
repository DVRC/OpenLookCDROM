/*
 *	@(#)styles.h 1.9 91/02/20 Copyright 1990-91 Sun Microsystems
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

#ifndef _STYLES_INCLUDED_

#define _STYLES_INCLUDED_

#include <NeWS/c_varieties.h>

#if defined(EXTERN)
#undef EXTERN
#endif

#if defined(DECLARE_STYLES_GLOBALS)
#define	EXTERN
#else
#define	EXTERN	extern
#endif

/* Well known formatter parameters */
#define F_TYPE 0		/* Object type */
#define F_FONTFAMILY 1
#define F_FACECODE 2
#define F_POINTSIZE 3
#define F_BASELINE 4
#define F_LEFTMARGIN 5
#define F_RIGHTMARGIN 6
#define F_FIRSTMARGIN 7
#define F_WIDTH 8		/* set iff the object has a fixed size */
#define F_HEIGHT 9
#define F_LINESTYLE 10
#define F_LINESPACING 11
#define F_COLOR_H 12
#define F_COLOR_S 13
#define F_COLOR_B 14
#define F_NPARAMS 15
#define F_EOF F_NPARAMS

/* A snapshot of the values of the various formatter parameters, and
   other pertinent info. */
struct formatter_info {
    int		    parameters[F_NPARAMS];
    int		    next_style_pos;	/* pos of next style change */
    struct font	    *font;		/* font resulting from current state
					   of parameters */
    struct color    *color;		/* color resulting from current state
					   of parameters */
};

/* line fill styles */
#define FL_JUSTIFIED 0
#define FL_LEFTFLUSH 1
#define FL_RIGHTFLUSH 2
#define FL_CENTERED 3
#define FL_LEFTRIGHT 4
#define FL_CHARWRAP 5
#define FL_CHARCHOP 6

EXTERN struct formatter_info defaultinfo;

struct style {
    struct bytestring	*mods;	    /* parameter modifications */
    char		*name;	    /* name of this style */
    int			nmods;	    /* number of mods */
};

/* Style modification types */
#define M_REPLACE 0
#define M_ADD 1
#define M_OR 2
#define M_ADDPSREL 3

/* Well known object types */
#define FT_TEXT 0
#define FT_ILLUSTRATION 1

/* Known facecodes - bits OR'd together. */
#define FC_ROMAN 0
#define FC_BOLD 1
#define FC_ITALIC 2
#define N_FACECODES 4	    /* Roman, Bold, Italic, BoldItalic */

EXTERN_FUNCTION( struct style	*style_New,	(char *name) );
EXTERN_FUNCTION( void		 style_Initialize,	(struct style *style, char *name) );
EXTERN_FUNCTION( void		 style_Free,	(struct style *style) );
EXTERN_FUNCTION( char		*style_Name,	(struct style *style) );
EXTERN_FUNCTION( void		 style_Define,	(struct style *style, DOTDOTDOT) );
EXTERN_FUNCTION( void		 style_Clear,	(struct style *style) );
EXTERN_FUNCTION( void		 style_Apply,	(struct style *style, JotSpan *span) );
EXTERN_FUNCTION( void		 style_Append, (struct style *s1, struct style *s2));

#endif
