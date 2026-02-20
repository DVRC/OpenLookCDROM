/*
 *	@(#)search.h 1.6 91/02/20 Copyright 1990-91 Sun Microsystems
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

#ifndef _SEARCH_INCLUDED_
#define _SEARCH_INCLUDED_

#include <NeWS/c_varieties.h>


#define Jot_MAX_ALTS	16	/* number of alternate search strings */
#define NSUBMATCHES	10	/* number of \( pairs */

#define Jot_FORWARD	1	/* direction to search */
#define Jot_BACKWARD	-1

typedef struct {
    Bytestring	*buf;			/* compiled expression */
    short	alts[Jot_MAX_ALTS];	/* index into expression */

    int		sm_begin[NSUBMATCHES];	/* index into buffer */
    int		sm_end[NSUBMATCHES];	/* index into buffer */
    JotText	*text;			/* text we last searched in */

    int		alt_count;		/* number of alts */
    int		firstc;			/* aid in quick comparison */
    int		error;			/* compilation error no. */
    unsigned	anchored : 1;		/* is this anchored to bol? */
} JotSearch;

/* possible compilation errors (stored in expr->error) */

#define Jot_NOERROR	    0	/* everything's cool - look out bay area! */
#define Jot_PEOP	    1   /* premature end of pattern */
#define Jot_PARENCOUNT	    2   /* too many parens specified */
#define Jot_UNMATCHED	    3   /* unmatched parens or brackets */
#define Jot_ALTCOUNT	    4   /* too many alternates specified */
#define Jot_FORWARDREF	    5   /* \<n> is a forward reference */
#define Jot_EMPTYCHRCLASS   6	/* [] was specified */

EXTERN_FUNCTION( boolean    JotSearch_CompileExpression,(JotSearch *expr, char *string, int regular) );
EXTERN_FUNCTION( void	    JotSearch_Free,		(JotSearch *expr) );
EXTERN_FUNCTION( boolean    JotSearch_Find,		(JotText *text, int pos, int direction, char *string) );
EXTERN_FUNCTION( JotSearch* JotSearch_New,		(_VOID_) );
EXTERN_FUNCTION( boolean    JotSearch_MatchPattern,	(JotSearch *expr, JotSpan *range, JotSpan *match, int direction, boolean ignorecase) );
EXTERN_FUNCTION( boolean    JotSearch_MatchString,	(char *string, JotSpan *range, JotSpan *match, int direction, boolean ignorecase) );
EXTERN_FUNCTION( boolean    JotSearch_Substring,	(JotSearch *expr, int substring, JotSpan *match) );

#endif
