/*
 *	@(#)span.h 1.11 91/02/20 Copyright 1990-91 Sun Microsystems
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

#ifndef _SPAN_INCLUDED_
#define _SPAN_INCLUDED_

#include <NeWS/c_varieties.h>

/*
 * A marker for a place in a bytestring.  A marker marks a position a span
 * that starts from there.
 */
struct JotSpan {
    JotSpan	*next, *prev;	/* the span chain */
    JotText	*owner;		/* the text object that owns span */
    int         pos;		/* the starting byte position */
    int         length;		/* the number of bytes marked */
    int		mod_offset;	/* offset from s->pos of modification */
    unsigned int modified:1;	/* true if some text in the spanned region was
				 * modified */
    unsigned int posmodified:1;	/* true iff the position of the span was
				 * modified, but not its contents */
    unsigned int rightside:1;	/* If bytes are inserted exactly at the
				 * span, and rightside!=0, the span stays
				 * on the right side of them */
    unsigned int internal:1;	/* this span is internal to jot */
};

EXTERN_FUNCTION( int	  JotSpan_Contents,	(JotSpan* span, char* buffer) );
EXTERN_FUNCTION( int	  JotSpan_DeleteContents,	(JotSpan* span) );
EXTERN_FUNCTION( void	  JotSpan_Free,		(JotSpan* span) );
EXTERN_FUNCTION( int	  JotSpan_Length,	(JotSpan* span) );
EXTERN_FUNCTION( JotSpan *JotSpan_New,		(JotText* text, int pos, int length) );
EXTERN_FUNCTION( JotSpan *JotSpan_NewI,		(JotText* text, int pos, int length) );
EXTERN_FUNCTION( int	  JotSpan_Position,	(JotSpan* span) );
EXTERN_FUNCTION( int	  JotSpan_Replace,	(JotSpan* oldspan, JotSpan* newspan) );
EXTERN_FUNCTION( boolean  JotSpan_Set,		(JotSpan *span, int pos, int length) );
EXTERN_FUNCTION( boolean  JotSpan_SetLength,	(JotSpan *span, int length) );
EXTERN_FUNCTION( boolean  JotSpan_SetText,	(JotSpan* span, JotText* text, int pos, int length) );
EXTERN_FUNCTION( boolean  JotSpan_SetPosition,	(JotSpan *span, int pos) );


#define JotSpan_ClearModified(s)    ((s)->modified = 0, (s)->mod_offset = -1)
#define JotSpan_Modified(s)	    ((s)->modified)
#define JotSpan_Text(s)		    ((s)->owner)

/* internal fast macros, when error checking is not desired or necessary */

#define JotSpan_QuickL(s)	    ((s)->length)
#define JotSpan_QuickP(s)	    ((s)->pos)
#define JotSpan_QuickSet(s, p, l)   ((s)->pos = (p), (s)->length = (l))
#define JotSpan_QuickSetL(s, l)	    ((s)->length = (l))
#define JotSpan_QuickSetP(s, p)	    ((s)->pos = (p))

#endif
