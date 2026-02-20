/*
 *	@(#)text.c 1.23 91/02/20 Copyright 1990-91 Sun Microsystems
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

#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include "assert.h"
#include "jot.h"
#include "bytestring.h"
#include "util.h"
#include "text.h"
#include "styles.h"
#include "selection.h"
#include "view_private.h"
#include "view.h"
#include "psinter.h"
#include "span.h"

void	JotText_ModifyViews(/* text */);

JotText *
JotText_New(length)
int length;
{
    register JotText	*t;
    Bytestring		*b;

    b = Bytestring_New(length);
    if (b == 0)
	return 0;
    t = (JotText *) jot_alloc(sizeof (JotText));
    if (t != 0) {
	bzero((char *) t, sizeof (JotText));
	t->eh.max = 16;
	t->data = b;
	t->caret = JotSpan_NewI(t, 0, 0);
	if (t->caret == 0) {
	    JotText_Free(t);
	    return 0;
	}
	t->caret->rightside = 1;
    }
    return t;
}

/* This returns the user token used to refer to the text object on the
   server side.  That object is what handles selection requests, like
   contents, or delete, or deselect. */

int
JotText_Holder(t, w)
JotText	    *t;
wire_Wire   w;
{
    int	holder;

    if ((holder = wire_RetrieveToken(&t->holders, w)) != -1)
	return holder;

    holder = wire_AllocateTokens(w, 1);
    wire_RegisterToken(w, holder, (caddr_t) t);
    wire_RememberToken(&t->holders, w, holder);
    ps_createtext(holder);

    return holder;
}

void
JotText_Free(t)
register JotText    *t;
{
    JotView *v, *viewnext;
    JotSpan *s, *spannext;
    int	    i;

    Bytestring_Free(t->data);
    if (t->stylerefs != 0)
	Bytestring_Free(t->stylerefs);
    if (t->caret != 0)
	JotSpan_Free(t->caret);
    for (v = t->views; v != 0; v = viewnext) {
	viewnext = v->viewnext;
	JotView_SetText(v, (JotText *) 0);
    }

    /* now initialize all the marks we have left */
    for (s = t->spans; s != 0; s = spannext) {
	spannext = s->next;
	JotSpan_SetText(s, (JotText *) 0, 0, 0);
	s = spannext;
    }
    for (i = 0; i < wire_MAXWIRES; i++) {
	wire_Wire   wire = wire_IntToWire(i);
	int	    token;

	if ((token = wire_RetrieveToken(&t->holders, wire)) != -1) {
	    wire_SetCurrent(wire);
	    ps_destroytext(token);
	    wire_RememberToken(&t->holders, wire, -1);
	    wire_DeallocateTokens(wire, token, 1);
	}
    }
}

boolean
JotText_SetCaret(t, pos)
register JotText    *t;
register int	    pos;
{
    if (JotSpan_Position(t->caret) != pos) {
	if (!JotSpan_SetPosition(t->caret, pos))
	    return FALSE;
	JotText_ModifyViews(t);
    }
    JotText_UndoBreak(t);

    return TRUE;
}

int
JotText_CharacterAt(t, pos)
register JotText    *t;
register int	    pos;
{
    if (pos < 0 || pos >= JotText_Characters(t)) {
	Jot_Errno = Jot_ERANGECHECK;
	return EOF;
    }
    return Bytestring_CharAt(t->data, pos);
}

void
JotText_ModifyViews(t)
register JotText    *t;
{
    register JotView	*v;

    for (v = t->views; v != 0; v = v->viewnext)
	JotView_Modify(v);
}

void
JotText_Modify(t)
JotText *t;
{
    t->modified += 1;
    JotText_ModifyViews(t);
}

/* Inform various interested people that bytes have been deleted
   from the text.  Interested people include the spans, styles,
   and undo.  The order here is important.  The styles come before
   undo, so that when this operation is redone, the text is
   inserted before the styles are applied.

   It's not really important for BytesInserted since inserting
   bytes does change the overall structure of the styles.  At
   least I think this is the case. */

static void
JotText_BytesDeleted(t, pos, n)
register JotText    *t;
register int	    pos, n;
{
    if (n > 0) {
	if (t->nstylerefs > 0)
	    JotStyle_BytesDeleted(t, pos, n);
	JotText_UndoBytesDeleted(t, pos, n);
	JotSpan_BytesDeleted(t->spans, pos, n);
	JotText_Modify(t);
    }
}

static void
JotText_BytesInserted(t, pos, n)
register JotText    *t;
register int	    pos, n;
{
    if (n > 0) {
	if (t->nstylerefs > 0)
	    JotStyle_BytesInserted(t, pos, n);
	JotText_UndoBytesInserted(t, pos, n);
	JotSpan_BytesInserted(t->spans, pos, n);
	JotText_Modify(t);
    }
}

static boolean
check_constrain(t, pos, n)
JotText    *t;
int	    pos, n;
{
    register JotView	*v;

    for (v = JotText_FirstView(t); v != 0; v = JotText_NextView(v))
	if (v->constrain) {
	    JotView_Modify(v);
	    JotSpan_BytesInserted(t->spans, pos, n);
	    JotView_PartialUpdate(v);
	    JotSpan_BytesDeleted(t->spans, pos, n);
	    if (v->bottom != JotText_Characters(t))
		return TRUE;
	}
    return FALSE;
}

int
JotText_InsertCharacters(t, pos, s, n)
register JotText    *t;
int		    pos, n;
char		    *s;
{
    register JotView	*v;

    JotSelection_BytesInserted(t, &pos, n);
    if (Bytestring_Insert(t->data, pos, s, n) != n)
	return -1;
    if (check_constrain(t, pos, n)) {
	(void) Bytestring_Delete(t->data, pos, n);
	return_error(-1, Jot_ECONSTRAIN);
    }
    JotText_BytesInserted(t, pos, n);

    return n;
}

int
JotText_InsertString(t, pos, s)
register JotText    *t;
int		    pos;
char		    *s;
{
    return JotText_InsertCharacters(t, pos, s, strlen(s));
}

int
JotText_DeleteCharacters(t, pos, n)
register JotText    *t;
register int	    pos, n;
{
    if (n < 0)
	pos += n, n = -n;
    if (pos < 0 || pos + n > Bytestring_Length(t->data))
	return_error(-1, Jot_ERANGECHECK);
    JotText_BytesDeleted(t, pos, n);
    n = Bytestring_Delete(t->data, pos, n);

    return n;
}

/* For now this returns the net change in characters.  This means that
   if there is an error, 0 will be returned.  This is a problem because
   there is no way to tell whether we have had an error or not. */

int
JotText_ReplaceCharacters(t, pos, length, rstring, rlength)
register JotText    *t;
int		    pos, length, rlength;
char		    *rstring;
{
    if (length < 0 || pos < 0 || length + pos >= Bytestring_Length(t->data))
	return_error(0, Jot_ERANGECHECK);
    if (length < rlength && !Bytestring_RoomFor(t->data, rlength - length))
	return_error(0, Jot_Errno);

    JotText_UndoBegin(t);
	JotText_DeleteCharacters(t, pos, length);
	JotText_InsertCharacters(t, pos, rstring, rlength);
    JotText_UndoEnd(t);

    return (length - rlength);
}

void
JotText_Clear(t)
JotText	*t;
{
    (void) JotText_DeleteCharacters(t, 0, JotText_Characters(t));
}

/* Read from fd until EOF.  If fd is a file and we can fstat it to get
   its size, we do the read all in one chunk, first making sure the
   buffer gap is big enough.  Otherwise we read the file 8k at a time
   until we get EOF. */

int
JotText_Read(t, pos, fd)
register JotText    *t;
int		    pos, fd;
{
    struct stat	    stbuf;
    int		    bytes_read, length;

    if (fstat(fd, &stbuf) < 0) {
	char	buf[0x2000];
	int	cc;

	JotText_UndoBegin(t);
	while ((cc = read(fd, buf, sizeof (buf))) > 0) {
	    if (JotText_InsertCharacters(t, pos, buf, cc) == -1) {
		JotText_UndoEnd(t);
		return_error(bytes_read, Jot_Errno);
	    }
	    bytes_read += cc;
	    pos += cc;
	}
	JotText_UndoEnd(t);
    } else {
	if (!Bytestring_RoomFor(t->data, stbuf.st_size))
	    return_error(-1, Jot_Errno);
	Bytestring_MoveGap(t->data, pos);
	bytes_read = read(fd, &Bytestring_CharAt(t->data, pos - 1) + 1, stbuf.st_size);
	if (bytes_read == -1)
	    return_error(-1, errno);
	Bytestring_BytesInserted(t->data, pos, bytes_read);
	if (check_constrain(t, pos, bytes_read)) {
	    (void) Bytestring_Delete(t->data, pos, bytes_read);
	    return_error(-1, Jot_ECONSTRAIN);
	}

	JotText_BytesInserted(t, pos, bytes_read);
    }

    return bytes_read;
}

int
JotText_Write(t, pos, length, fd)
register JotText    *t;
register int	    pos, length, fd;
{
    int	n;

    if (length < 0 || pos < 0 || pos + length > Bytestring_Length(t->data))
	return_error(-1, Jot_ERANGECHECK);
    Bytestring_MoveGap(t->data, pos);	/* make all chars contiguous (no gap) */

    if ((n = write(fd, &Bytestring_CharAt(t->data, pos), length)) != length)
	return_error(n, errno);
    return n;
}

int
JotText_ScanCharacter(text, pos, c, n)
register JotText    *text;
register int	    pos, c, n;
{
    if (n < 0) {	    /* scan backward */
	n = -n;
	while (--n >= 0) {
	    while (--pos >= 0 && JotText_FastCharacterAt(text, pos) != c)
		;
	    if (pos < 0)
		return -1;
	}
    } else {		    /* scan forward like a normal person */
	register int	limit = JotText_Characters(text);

	pos -= 1;	    /* so I can ++pos in general */
	while (--n >= 0) {
	    while (++pos < limit && JotText_FastCharacterAt(text, pos) != c)
		;
	    if (pos >= limit)
		return -1;
	}
    }
    return pos;
}

int
JotText_Newlines(t)
register JotText    *t;
{
    register int    n, pos, limit;

    pos = n = 0;
    limit = Bytestring_Length(t->data);
    while ((pos = Bytestring_Scan(t->data, pos, 1, '\n', limit)) >= 0) {
	pos += 1;
	n += 1;
    }

    return n;
}

JotSpan *
JotText_FirstSpan(text)
JotText	*text;
{
    register JotSpan	*s;

    for (s = text->spans; s != 0; s = s->next)
	if (!s->internal)
	    break;

    return s;
}

JotSpan *
JotText_NextSpan(span)
register JotSpan    *span;
{
    if (span)
	span = span->next;
    for (; span != 0; span = span->next)
	if (!span->internal)
	    break;

    return span;
}
