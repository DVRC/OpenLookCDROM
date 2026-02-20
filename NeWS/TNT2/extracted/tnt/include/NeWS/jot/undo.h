/*
 *	@(#)undo.h 1.11 91/02/20 Copyright 1990-91 Sun Microsystems
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

#ifndef _UNDO_INCLUDED_
#define _UNDO_INCLUDED_

#include <NeWS/c_varieties.h>

/* REMIND: this is for the boolean typedef */
#include <NeWS/wire/wire.h>

/* An undo atom describes one kind of change to a buffer.  Right now the
   only known changes are insertions and deletions.  Actions are
   described as they are executed, and the smarts to undo them are
   described in code.  As opposed to describing the undo for an action,
   and storing that.  This way, redo is easy.  Undo_atom's have pointers
   to the rest of the undo action, when undo actions should be grouped.
   For instance, reformatting a paragraph involves many deletes and
   insertions, and the would be described by a list of atoms.

   A text object has an undo history object associated with it.  That is
   an array of undoable operations.  Each element in that array is a list
   of operations that should be considered one undoable operation, like
   reformatting a paragraph.  Operations on text add entries to the undo
   history.  Undo just backs up in the history.  Redo just reexecutes the
   operation we just undid.  If we have undone a few operations, and THEN
   do some other editor operation that need recording in the history, all
   the redoable operations are flushed at that point. */

typedef enum {
    undo_null = 0,
    undo_insertion,
    undo_deletion,
    undo_styleapply,
    undo_styledelete,
} undo_kind;

typedef struct undo_atom {
    struct undo_atom	*next, *prev;
    undo_kind		kind;
    union {
	struct {
	    int			pos;	/* position of operation */
	    Bytestring		text;	/* characters inserted or deleted */
	} text;
	struct {
	    int		    pos;
	    int		    span;
	    struct style    *style;
	} sr;				/* style ref */
    } D;
} UndoAtom;

typedef struct undo_molecule {
    UndoAtom	*leader;
    int		modified;	/* value of modified after we're done */
} UndoMolecule;
    
EXTERN_FUNCTION( boolean  JotText_Redo,		(JotText* text) );
EXTERN_FUNCTION( boolean  JotText_Undo,		(JotText* text) );
EXTERN_FUNCTION( int	  JotText_RedoCount,	(JotText* text) );
EXTERN_FUNCTION( int	  JotText_UndoCount,	(JotText* text) );
EXTERN_FUNCTION( void	  JotText_SetUndo,	(JotText* text, int level) );
EXTERN_FUNCTION( void	  JotText_UndoBegin,	(JotText* text) );
EXTERN_FUNCTION( void	  JotText_UndoBreak,	(JotText* text) );
EXTERN_FUNCTION( void	  JotText_UndoEnd,	(JotText* text) );

#endif
