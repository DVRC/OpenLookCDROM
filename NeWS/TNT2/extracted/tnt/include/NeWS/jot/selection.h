/*
 *	@(#)selection.h 1.8 91/02/20 Copyright 1990-91 Sun Microsystems
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


#if !defined(JOT_SELECTION_H)
#define JOT_SELECTION_H

#include <NeWS/c_varieties.h>

/* selection constants */

#define Jot_PRIMARY	    0
#define Jot_SECONDARY	    1
#define Jot_N_SELECTIONS    2

/* text units */
#define Jot_CHARACTER	    1
#define Jot_WORD	    2
#define Jot_LINE	    3
#define Jot_BUFFER	    4


EXTERN_FUNCTION( boolean	 JotSelection_Clear,	(JotText *text, int rank) );
EXTERN_FUNCTION( char		*JotSelection_Contents,	(JotText *text, int rank) );
EXTERN_FUNCTION( boolean	 JotSelection_PendingDelete,	(JotText *text, int rank) );
EXTERN_FUNCTION( boolean	 JotSelection_Set,	(JotSpan *span, int rank, int pendint) );
EXTERN_FUNCTION( boolean	 JotSelection_SetLevel,	(JotView *view, int rank, int level) );
EXTERN_FUNCTION( JotSpan	*JotSelection_Span,	(JotText *text, int rank) );

#endif	/* JOT_SELECTION_H */
