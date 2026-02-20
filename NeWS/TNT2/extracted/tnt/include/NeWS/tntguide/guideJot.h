/*
 * @(#)guideJot.h 1.7 91/02/21 Copyright 1990-91 Sun Microsystems
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

/*
 * API for guideJot.cc
 */

#include <NeWS/jot/jot.h>
#include <NeWS/jot/view.h>

/*
 * In the following, `word' is as defined by JotSearch for word-beginning
 * and word-end regexp elements.  `Display line' indicates a single
 * horizontal line of text, as currently displayed.  Since jot canvases
 * normally wrap lines at word breaks, display lines are not necessarily
 * terminated by a NL character.
 */
typedef enum {
    GJ_NOOP,			/* Do nothing */
    GJ_CHAR_FORWARD,		/* Move caret forward one character */
    GJ_CHAR_BACKWARD,		/* Move caret backward one character */
    GJ_CHAR_DELETE_FORWARD,	/* Delete character after caret */
    GJ_CHAR_DELETE_BACKWARD,	/* Delete character before caret */
    GJ_CHAR_INSERT_SELF,	/* Insert character at caret & advance */
    GJ_CHAR_INSERT_NL,		/* Insert NewLine at caret & advance */
    GJ_WORD_FORWARD,		/* Move caret forward one word */
    GJ_WORD_BACKWARD,		/* Move caret backward one word */
    GJ_WORD_DELETE_FORWARD,	/* Delete word after caret */
    GJ_WORD_DELETE_BACKWARD,	/* Delete word before caret */
    GJ_LINE_BACKWARD,		/* Move caret backward one display line */
    GJ_LINE_FORWARD,		/* Move caret forward one display line */
    GJ_LINE_DELETE_FORWARD,	/* Delete from caret to end of display line */
    GJ_LINE_START,		/* Move caret to beginning of display line */
    GJ_LINE_END,		/* Move caret to end of display line */
    GJ_DOC_START,		/* Move caret to start of document */
    GJ_DOC_END,			/* Move caret to end of document */
    GJ_UNDO,			/* Undo last change */
    GJ_REDO,			/* Redo undone change */
    GJ_ENUM_LIMIT		/* Place and limit holder */
} guide_jot_edit_function ;



#define guide_DefaultKeys	guide_EmacsKeys


EXTERN_FUNCTION( void guide_JotEdit,		(JotView *, char, guide_jot_edit_function) );
EXTERN_FUNCTION( void guide_EmacsKeys,		(JotView *, int) );
