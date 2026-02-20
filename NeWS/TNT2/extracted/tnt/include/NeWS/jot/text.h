/*
 *	@(#)text.h 1.15 91/02/20 Copyright 1990-91 Sun Microsystems
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

#ifndef _TEXT_INCLUDED_
#define _TEXT_INCLUDED_

#include <NeWS/c_varieties.h>
#include <NeWS/wire/wire.h>
#include <NeWS/jot/bytestring.h>


/* A singing & dancing text */
struct JotText {
    Bytestring	    *data;	    /* the data data part of the text */
    Bytestring	    *stylerefs;	    /* the array of style sheet references */
    short	    nstylerefs;	    /* the number of style references */
    struct {
	Bytestring	edits;	    /* array of molecules */
	unsigned short	index;	    /* current index into list */
	unsigned short	count;	    /* number of existing molecules */
	unsigned short	max;	    /* user settable limit */
	short		bundle;	    /* while this is > 0, add to the current
				       molecule, don't begin a new one */
	unsigned	enabled:1;  /* are we currently recording? */
	unsigned	in_undo:1;  /* while we're undoing an operation, don't
				       record any edits we make */
	unsigned	new_grp:1;  /* begin a new group regardless */
    } eh;			    /* edit history for undo/redo */
    int		    modified;	    /* number of modifications */
    JotSpan	    *spans;	    /* spans that refer to this text */
    JotSpan	    *caret;	    /* the caret for this text */
    JotView	    *views;	    /* the views on this document */
    wire_TokenArray holders;	    /* server side handles for text object */
};

EXTERN_FUNCTION( int	    JotText_CharacterAt,	(JotText* text, int pos) );
EXTERN_FUNCTION( void	    JotText_Clear,		(JotText* text) );
EXTERN_FUNCTION( int	    JotText_DeleteCharacters,	(JotText* text, int pos, int n) );
EXTERN_FUNCTION( JotSpan   *JotText_FirstSpan,		(JotText *text) );
EXTERN_FUNCTION( JotView   *JotText_FirstView,		(JotText *text) );
EXTERN_FUNCTION( void	    JotText_Free,		(JotText* text) );
EXTERN_FUNCTION( int	    JotText_InsertCharacters,	(JotText* text, int pos, char* buffer, int n) );
EXTERN_FUNCTION( int	    JotText_InsertString,	(JotText* text, int pos, char* string) );
EXTERN_FUNCTION( JotText   *JotText_New,		(int length) );
EXTERN_FUNCTION( int	    JotText_Newlines,		(JotText* text) );
EXTERN_FUNCTION( JotSpan   *JotText_NextSpan,		(JotSpan *span) );
EXTERN_FUNCTION( JotView   *JotText_NextView,		(JotView *view) );
EXTERN_FUNCTION( int	    JotText_Read,		(JotText* text, int pos, int fp) );
EXTERN_FUNCTION( int	    JotText_ReplaceCharacters,	(JotText* text, int pos, int length, char* rstring, int rlength) );
EXTERN_FUNCTION( int	    JotText_ScanCharacter,	(JotText* text, int pos, int c, int n) );
EXTERN_FUNCTION( boolean    JotText_SetCaret,		(JotText* text, int pos) );
EXTERN_FUNCTION( int	    JotText_Write,		(JotText* text, int pos, int length, int fp) );


#define JotText_Caret(t)		JotSpan_Position((t)->caret)
#define JotText_Characters(t)		Bytestring_Length((t)->data)
#define JotText_FastCharacterAt(t, p)	Bytestring_CharAt((t)->data, (p))
#define JotText_FirstView(t)		((t)->views)
#define JotText_Modified(t)		((t)->modified)
#define JotText_NextView(v)		((v)->viewnext)

#endif
