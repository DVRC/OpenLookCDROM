/*
 *	@(#)buffer.c 1.13 91/02/21 Copyright 1990-91 Sun Microsystems
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

#include <strings.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <setjmp.h>
#include <NeWS/jot/view.h>
#include <NeWS/jot/text.h>
#include <NeWS/jot/span.h>
#include "buffer.h"
#include "keymap.h"
#include "utils.h"

#define CHECK_POINT_THRESH  150

Buffer *
Buffer_New(view)
JotView	*view;
{
    Buffer  *b;

    b = (Buffer *) jot_alloc(sizeof (Buffer));
    bzero((char *) b, sizeof (Buffer));
    b->keystate.state = 0;
    b->keystate.map = writeable_map;
    b->view = view;
    JotView_SetData(view, (long) b);
    b->frame_id = wire_AllocateTokens(wire_Current(), 1);
    b->text = JotView_Text(view);
    return b;
}

char *
Buffer_MakeFilename(b, name)
Buffer	*b;
char	*name;
{
    static char	filename[1024];
    char	*cp;

    if (name[0] == '/')
	strcpy(filename, name);
    else
	sprintf(filename, "%s/%s", b->directory, name);

    if ((cp = index(filename, '\n')) != 0)
	*cp = '\0';

    return filename;
}

void
Buffer_SetFileName(b, name)
Buffer	*b;
char	*name;
{
    struct stat	stbuf;

    b->filename = name;
    if (name != 0) {
	if (stat(name, &stbuf) < 0) {
	    b->dev = 0;
	    b->ino = 0;
	} else {
	    b->dev = stbuf.st_dev;
	    b->ino = stbuf.st_ino;
	}
    }
    b->update_modeline = 1;
}

Buffer_SetDirectory(b, dname)
Buffer	*b;
char	*dname;
{
    char    *cp;

    if ((cp = index(dname, '\n')) != 0)
	*cp = '\0';
    b->directory = (char *) copystr(dname);
    b->update_modeline = 1;
}

void
Buffer_InsertFile(b, filename)
Buffer	*b;
char	*filename;
{
    JotText *text;
    JotView *v = b->view;
    FILE    *fp;
    int	    nbytes;
    char    *fname;

    if (filename == 0)
	return;
    fname = Buffer_MakeFilename(b, filename);
    if ((fp = fopen(fname, "r")) == NULL)
	signal_warning("Cannot open %s\n", fname);
    text = JotView_Text(v);
    nbytes = JotText_Read(text, JotText_Caret(text), fileno(fp));
    JotView_EnsurePositionVisible(v, JotText_Caret(text) - 1);
    frame_message(v, "\"%s\" - %d bytes.", fname, nbytes);
    fclose(fp);
}

Buffer_UnModified(b)
Buffer	*b;
{
    JotText *text;

    text = JotView_Text(b->view);
    b->last_saved = JotText_Modified(text);
}

void
Buffer_LoadFile(b, name)
Buffer	*b;
char	*name;
{
    JotText *text;

    text = JotView_Text(b->view);
    if (JotText_Modified(text) > b->last_saved)
	if (!ask_yes_no("\nBuffer is modified.  Loading a file will erase those changes.  Do you really want to do this?"))
	    return;

    JotText_Clear(text);

    Buffer_FlushUndo(b);
    Buffer_InsertFile(b, name);
    Buffer_EnableUndo(b);

    Buffer_SetFileName(b, name);
    JotText_SetCaret(text, 0);
    JotView_EnsurePositionVisible(b->view, 0);
    Buffer_UnModified(b);
    frame_modeline(b->view);
}

error()
{
    extern jmp_buf  mainloop;

    longjmp(mainloop, 1);
}

boolean
Buffer_ConfirmWrite(b, filename)
Buffer	*b;
char	*filename;
{
    struct stat	stbuf;

    if (filename == 0)
	return;
    if (stat(filename, &stbuf) < 0)
	return;
    if (((stbuf.st_dev != b->dev) ||
	 (stbuf.st_ino != b->ino)) &&
	(b->filename == 0 || strcmp(filename, b->filename) != 0)) {
	if (!ask_yes_no("\n\n\"%s\" already exists.  Are you sure you want to overwrite it?", filename))
	    error();
    }
}

boolean
Buffer_WriteFile(b, filename, do_warnings)
Buffer	*b;
char	*filename;
{
    extern char	*sys_errlist[];
    extern int	errno;
    JotText *text;
    FILE    *fp;
    int	    nbytes;
    char    *fname;

    if (filename == 0)
	return FALSE;
    fname = Buffer_MakeFilename(b, filename);
    if ((fp = fopen(fname, "w")) == NULL) {
	if (do_warnings)
	    signal_warning("\n\nCouldn't create \"%s\".", fname);
	return FALSE;
    }
    text = JotView_Text(b->view);
    nbytes = JotText_Write(text, 0, JotText_Characters(text), fileno(fp));
    fclose(fp);
    if (nbytes != JotText_Characters(text)) {
	if (do_warnings)
	    signal_warning("\n\nError \"%s\" occurred while writing to %s - be careful!",
			   sys_errlist[errno], fname);
	return FALSE;
    }
    frame_message(b->view, "\"%s\" -- %d bytes written.",
		  fname, nbytes);

    return TRUE;
}

#define Buffer_ResetCheckpoint(b) \
    (b)->check_point = JotText_Modified((b)->text)

Buffer_MaybeCheckpoint(b)
Buffer	*b;
{
    if (JotText_Modified(b->text) < b->check_point)
	Buffer_ResetCheckpoint(b);    /* we must have undo'd or something */
    else if (JotText_Modified(b->text) - b->check_point >= CHECK_POINT_THRESH)
	Buffer_Checkpoint(b);
}

static void
make_ckp_name(b, filebuf)
Buffer	*b;
char	*filebuf;
{
    char    *fnp;

    fnp = Buffer_MakeFilename(b, b->filename);
    sprintf(filebuf, "%s.CKP", fnp);
}

Buffer_CleanUp(b)
Buffer	*b;
{
    char    filename[512];

    if (b->check_pointed) {
	make_ckp_name(b, filename);
	unlink(filename);
    }
}

Buffer_Checkpoint(b)
Buffer	*b;
{
    char    filename[512];

    if (b->filename != 0) {
	b->check_pointed = 1;
	make_ckp_name(b, filename);
	(void) Buffer_WriteFile(b, filename, FALSE);
    }
    Buffer_ResetCheckpoint(b);
}

void
Buffer_SaveFile(b)
Buffer	*b;
{
    if (Buffer_WriteFile(b, b->filename, FALSE)) {
	Buffer_UnModified(b);
	Buffer_ResetCheckpoint(b);
    }
}

void
Buffer_InsertChar(b, c)
Buffer	*b;
int	c;
{
    JotText *t = JotView_Text(b->view);

    if (JotView_ReadOnly(b->view)) {
	ring_bell();
	return;
    }
    if (c >= ' ' || c == '\n' || c == '\t') {
	char    str;

	str = c;
	JotText_InsertCharacters(t, JotText_Caret(t), &str, 1);
    }
    JotView_EnsurePositionVisible(b->view, JotText_Caret(t));
    Buffer_MaybeCheckpoint(b);
}

void
Buffer_DeleteChar(b, dir)
Buffer	*b;
int	dir;
{
    JotText *t = JotView_Text(b->view);
    JotSpan *s;

    if (JotView_ReadOnly(b->view)) {
	ring_bell();
	return;
    }
    if ((s = JotSelection_Span(t, Jot_PRIMARY)) != 0 && JotSpan_Text(s) == t &&
	JotSpan_Length(s) > 0) {
	JotSpan_DeleteContents(s);
	JotSelection_Clear(t, Jot_PRIMARY);
    } else    
	JotText_DeleteCharacters(t, JotText_Caret(t), dir);
    Buffer_MaybeCheckpoint(b);
}

void
Buffer_BeginningOfLine(b)
Buffer	*b;
{
    JotText *t = JotView_Text(b->view);
    int	    line, pos;

    line = JotView_RelativeLineFromPosition(b->view, JotText_Caret(t));
    if (line >= 0)
	JotText_SetCaret(t, JotView_PositionFromLine(b->view, line));
    else {
	pos = JotText_Caret(t);
	while (pos > 0 && JotText_FastCharacterAt(t, pos - 1) != '\n')
	    pos -= 1;
	JotText_SetCaret(t, pos);
    }
    Buffer_CaretVisible(b);
}

Buffer_EndOfLine(b)
Buffer	*b;
{
    JotText *t = JotView_Text(b->view);
    int	    line, pos, limit;

    line = JotView_RelativeLineFromPosition(b->view, JotText_Caret(t));
    if (line >= 0) {
	if (line == JotView_Lines(b->view) - 1)
	    pos = JotView_PositionFromLine(b->view, 0) +
		JotView_Characters(b->view);
	else
	    pos = JotView_PositionFromLine(b->view, line + 1) - 1;
	JotText_SetCaret(t, pos);
    } else {
	pos = JotText_Caret(t);
	limit = JotText_Characters(t);
	while (pos < limit && JotText_FastCharacterAt(t, pos) != '\n')
	    pos += 1;
	JotText_SetCaret(t, pos);
    }
    Buffer_CaretVisible(b);
}

Buffer_ToTop(b)
Buffer	*b;
{
    JotText_SetCaret(b->text, 0);
    Buffer_CaretVisible(b);
}

Buffer_ToBottom(b)
Buffer	*b;
{
    JotText_SetCaret(b->text, JotText_Characters(b->text));
    Buffer_CaretVisible(b);
}

Buffer_CaretVisible(b)
Buffer	*b;
{
    JotView_EnsurePositionVisible(b->view, JotText_Caret(b->text));
}

Buffer_DeleteWord(b, n)
Buffer	*b;
int	n;
{
    int	pos;

    if (JotView_ReadOnly(b->view)) {
	ring_bell();
	return;
    }

    pos = JotText_Caret(b->text);

    if (n > 0) {
	int limit = JotText_Characters(b->text);
	while (--n >= 0) {
	    while (pos < limit && !isalnum(JotText_FastCharacterAt(b->text, pos)))
		pos += 1;
	    while (pos < limit && isalnum(JotText_FastCharacterAt(b->text, pos)))
		pos += 1;
	}
    } else {
	n = -n;
	while (--n >= 0) {
	    while (pos > 0 && !isalnum(JotText_FastCharacterAt(b->text, pos - 1)))
		pos -= 1;
	    while (pos > 0 && isalnum(JotText_FastCharacterAt(b->text, pos - 1)))
		pos -= 1;
	}
    }
    JotText_DeleteCharacters(b->text, pos, JotText_Caret(b->text) - pos);
}
