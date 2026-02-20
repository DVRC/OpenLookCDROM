/*
 *	@(#)buffer.h 1.8 91/02/21 Copyright 1990-91 Sun Microsystems
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

/* The client data field in a JotView points at a buffer.  Each buffer
   has keystate and filename and other stuff. */

#ifndef _BUFFER_INCLUDED_
#define _BUFFER_INCLUDED_

#include <jot/view.h>
#include "keymap.h"

typedef struct buffer {
    JotView	    *view;	    /* view displaying this buffer */
    JotText	    *text;	    /* convenience pointer */
    struct keystate keystate;	    /* key bindings */
    char	    *filename;	    /* default file name */
    char	    *directory;	    /* directory */
    dev_t	    dev;	    /* uniquely identify a file */
    ino_t	    ino;
    int		    frame_id;	    /* frame to which we display status */
    int 	    last_saved;	    /* JotText_Modified() at last save */
    int		    check_point;  /* JotText_Modified() at last chkpnt */
    unsigned 	    update_modeline:1;
    unsigned	    check_pointed:1; /* has been checkpointed at least once */
    unsigned	    check_failed:1; /* checkpoint failed - disabled */
} Buffer;

extern Buffer	*Buffer_New(/* view */);
extern void	Buffer_InsertFile(/* buffer, filename */);
extern void	Buffer_LoadFile(/* buffer, filename */);
extern void	Buffer_SaveFile(/* buffer */);
extern void	Buffer_SetFileName(/* buffer, filename */);
extern boolean	Buffer_WriteFile(/* buffer, filename, do_warnings */);

#define View_Buffer(v)		((Buffer *) JotView_Data(v))
#define Buffer_Modified(b)	(JotText_Modified((b)->text) > b->last_saved)
#define Buffer_FlushUndo(b)	JotText_SetUndo((b)->text, 0)
#define Buffer_EnableUndo(b)	JotText_SetUndo((b)->text, 50);

#endif
