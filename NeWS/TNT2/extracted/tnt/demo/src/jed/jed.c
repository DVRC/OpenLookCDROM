/*
 *	@(#)jed.c 1.23 91/02/21 Copyright 1990-91 Sun Microsystems
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

#include <sys/ioctl.h>
#include <signal.h>
#include <setjmp.h>
#include <wire/wire.h>
#include <jot/jot.h>
#include <jot/view.h>
#include <jot/text.h>
#include <jot/font.h>
#include <jot/search.h>
#include "keymap.h"
#include "buffer.h"
#include "jed_cps.h"

JotView *vw = 0;
jmp_buf	mainloop;

char	*helptext =
"Welcome to jed.  You got this message because you did not specify \
a filename to edit.  When you are done reading this message you \
can hit the UNDO key and it will go away.  In normal usage you \
fire up jed like this:\n\
\n\
	jed filename\n\
\n\
This will bring up jed and read the filename if it exists.  Once \
you are in jed, it should feel similar to textedit on xview. \
Some things still feel like sunview, though.  For instance, to \
search for some text, you must highlight it and then hit the FIND \
key.  Not nearly everything is implemented though.  Bring up the \
menu and you can tell which items are implemented by whether or not \
they are enabled or disabled.\n\
\n\
Here are a few keyboard commands that you might want to know \
about:\n\
\n\
    ^A - move to beginning of line\n\
    ^B - backward character\n\
    ^D - delete character after caret\n\
    ^E - move to end of line\n\
    ^F - forward character\n\
    Delete - delete character before caret\n\
    ^W - delete previous word\n\
    ^U - same as UNDO key\n\
    ^R - same as AGAIN (redo) key\n\
\n\
The UNDO, AGAIN (redo), COPY, PASTE, COPY, and FIND keys work. \
Undo works differently in jed than it does with textedit.  It is a \
multi-level undo mechanism.  Undo undoes an operation.  If you \
change your mind about undoing that operation, hit the AGAIN key, \
which in jed is the REDO function.  This redoes the operation you \
undid.  You can think of UNDO as moving backward in time and REDO \
as moving forward again.  When you are back in time and you start \
making changes, you can no longer move forward in time, so be \
careful.\n\
\n\
The default font is LucidaSansTypewriter, a fixed width font, \
suitable for editing code, etc.  This message is being viewed with \
a LucidaSans 15 point, variable width font as a demo.  The \
default size is 13 point. You can specify a different font \
and/or a different size on the command line:\n\
\n\
	jed -fFontName -sNN\n\
\n\
\n\
This is not a product.  JED is based on JOT, and JOT will become \
part of the TNT product.  The JOT library is a low level text \
library.  JED (a textedit look-alike) is just one example of the \
kind of application you can build with JOT.  It is being released \
with the hopes that people will use it so that I can find bugs in \
JOT.  But another reason for making this available for use is \
so it can be used as a bench mark for comparing tnt 1.0 to the new \
version.\n";

int
checkpoint_then_quit()
{
    Buffer_Checkpoint(View_Buffer(vw));
    exit(1);
}

Ched_Quit(v)
JotView	*v;
{
    Buffer  *b;

    b = View_Buffer(v);
    if (Buffer_Modified(b))
	if (!ask_yes_no("\nBuffer is modified.  Quitting will erase those changes.  Do you really want to do this?"))
	    error();
    Buffer_CleanUp(b);
    exit(0);
}

my_sel_start(vw, pos)
JotView	*vw;
int	pos;
{
    int	yes;

    yes = rand()%2;
    printf("Returning %d from start selection\n", yes);

    return yes;
}

my_mouse_event(v, button, action, pos)
JotView	*v;
int	button, action, pos;
{
    printf("Mouse event: button = %d, action = %d, pos = %d\n",
	   button, action, pos);
}

main(argc, argv)
    char      **argv;
{
    wire_Wire	wire;
    JotText	*text;
    char	*docname = 0;
    char	*fontname = "LucidaSansTypewriter";
    char	*fontsize = "13";
    boolean	last_modified = FALSE;
    boolean	size_specified = FALSE;
    int		RandomSelections = 0;
    Buffer	*buffer;
    char	pwd[256];
    struct font *font;
    int		readonly = 0;

    while (--argc > 0)
	if ((++argv)[0][0] == '-')
	    switch (argv[0][1]) {
	    case 'f':
		fontname = &argv[0][2];
		break;

	    case 's':
		fontsize = &argv[0][2];
		size_specified = TRUE;
		break;

	    default:
		fprintf(stderr, "Illegal switch: %s\n", argv[0]);
		exit(1);
	    }
	else
	    docname = argv[0];

    if ((wire = wire_Open(NULL)) == wire_INVALID_WIRE) {
	wire_Perror("jed:");
	exit(1);
    }

    Jot_Initialize(wire);
    color_init();
    style_init();
    keymap_init();

    /* ps initialization */
    ps_initialize();
    menu_cmds_init();

    /* now create a text and a textview object */
    text = JotText_New(0);
    vw = JotView_New(text);
    buffer = Buffer_New(vw);
    Buffer_SetDirectory(buffer, getwd(pwd));

    if (docname != 0) {
	JotFontFamily   *ff;

	ff = JotFont_FindFamily(fontname);
	if (ff == NULL) {
	    printf("Cannot find font (family) = %s\n", fontname);
	    exit(1);
	}
	font = JotFont_FontFromFamily(ff, FC_ROMAN, atoi(fontsize), FALSE);
	JotView_SetLineStyle(vw, FL_CHARWRAP);
    } else {
	int pointsize;

	if (size_specified)
	    pointsize = atoi(fontsize);
	pointsize = 15;
	font = JotFont_FontFromFamily(JotFont_FindFamily("LucidaSans"),
				      FC_ROMAN, pointsize, FALSE);
	JotView_SetLineStyle(vw, FL_JUSTIFIED);
    }

    JotView_SetFont(vw, font);
    Buffer_EnableUndo(buffer);
    ps_set_preferred_size(JotView_Canvas(vw), 575, 600);
    ps_initcanvas(JotView_Canvas(vw), buffer->frame_id);
    JotView_SetControllers(vw, keymap_dispatch, 0, 0, 0);
    ps_place_frame(buffer->frame_id);
    ps_map_frame(buffer->frame_id);

    if (docname != 0)
	Buffer_LoadFile(buffer, docname);
    else
	JotText_InsertString(text, 0, helptext);

    text = JotView_Text(buffer->view);

    if (setjmp(mainloop) == 0) {
	signal(SIGHUP, checkpoint_then_quit);
	signal(SIGSEGV, checkpoint_then_quit);
	signal(SIGINT, checkpoint_then_quit);
    }

    /* "Off on your way, hit the open road, there is magic at your fingers.
	For the spirit ever lingers, undemanding contact in your happy
	solitude."  (Rush - The Spirit of Radio) */

loop:
    while (wire_Notify(NULL)) {
	if (wire_WouldNotify(vw->wire))
	    continue;
	if (JotView_PendingUpdates())
	    JotView_UpdateViews();
	if ((buffer->update_modeline) ||
	    ((buffer->last_saved < JotText_Modified(text)) != last_modified)) {
	    last_modified = (buffer->last_saved < JotText_Modified(text));
	    frame_modeline(vw);
	}
    }
    if (wire_Errno == wire_EINTR)
	goto loop;
    checkpoint_then_quit();	/* connection to server died? */
}

frame_message(view, fmt, a1, a2, a3)
JotView	*view;
char	*fmt;
{
    Buffer  *b;
    char    buffer[256];

    b = (Buffer *) JotView_Data(view);
    sprintf(buffer, fmt, a1, a2, a3);
    ps_frame_footer(b->frame_id, buffer, "");
}

char *
basename(name)
char	*name;
{
    char    *cp;

    if (name == 0)
	return "No File";
    if (cp = (char *) rindex(name, '/'))
	name = cp + 1;
    return name;
}

static char *
filename_of(b)
Buffer	*b;
{
    if (b->filename == 0)
	return "(NONE)";
    if (strncmp(b->filename, b->directory, strlen(b->directory)) == 0)
	return b->filename + strlen(b->directory) + 1;
    return b->filename;
}

frame_modeline(v)
JotView	*v;
{
    JotText *text;
    Buffer  *b;
    char    buffer[256];

    b = (Buffer *) JotView_Data(v);
    text = JotView_Text(v);
    sprintf(buffer, "JOT Editor - %s %s dir: %s",
	    filename_of(b),
	    b->last_saved < JotText_Modified(text) ? "(Edited)" : "",
	    b->directory);
    ps_frame_label(b->frame_id, buffer);
    ps_icon_label(b->frame_id, basename(b->filename));
    b->update_modeline = 0;
}
