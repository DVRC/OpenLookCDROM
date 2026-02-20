/*
 *	@(#)span.c 1.7 91/02/20 Copyright 1990-91 Sun Microsystems
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

#include "jot_private.h"
#include "assert.h"
#include "jot.h"
#include "bytestring.h"
#include "text.h"
#include "span.h"

void
JotSpan_BytesInserted(s, pos, n)
register JotSpan    *s;
register int	    pos, n;
{
    for (; s != 0; s = s->next)
	if (s->pos > pos || s->rightside && s->pos == pos) {
	    s->pos += n;
	    s->posmodified = 1;
	} else if (s->pos + s->length > pos) {	/* s->pos <= pos */
	    s->length += n;
	    if (s->modified)
		s->mod_offset = min(pos - s->pos, s->mod_offset);
	    else {
		s->modified = 1;
		s->mod_offset = pos - s->pos;
	    }
	}
}

void
JotSpan_BytesDeleted(s, pos, n)
register JotSpan    *s;
register int	    pos, n;
{
    for (; s != 0; s = s->next)
	if (s->pos + s->length >= pos)
	    if (s->pos >= pos + n) {
		s->pos -= n;
		s->posmodified = 1;
	    } else {	    /* s->pos < pos + n */
		if (s->pos >= pos) {
		    /* pos <= s->pos < pos+n */
		    s->length -= n - pos + s->pos;
		    if (s->length < 0)
			s->length = 0;
		    s->pos = pos;
		} else {    /* s->pos < pos && s->pos + s->length > pos */
		    if (s->pos + s->length > pos + n)
			s->length -= n;
		    else
			s->length = pos - s->pos;
		}
		if (!s->modified)
		    s->mod_offset = pos - s->pos;
		else
		    s->mod_offset = min(s->mod_offset, pos - s->pos);
		s->modified = 1;
	    }
}

JotSpan *
JotSpan_New(t, pos, length)
register JotText    *t;
{
    register JotSpan	*span;

    span = (JotSpan *) jot_alloc(sizeof (JotSpan));
    if (span != 0) {
	bzero((char *) span, sizeof (JotSpan));
	if (!JotSpan_SetText(span, t, pos, length)) {
	    JotSpan_Free(span);
	    span = 0;
	}
    }

    return span;
}

JotSpan *
JotSpan_NewI(t, pos, length)
register JotText    *t;
{
    register JotSpan	*span;

    span = JotSpan_New(t, pos, length);
    span->internal = 1;

    return span;
}


void
JotSpan_Unlink(span)
register JotSpan    *span;
{
    if (span->owner == 0)
	return;
    if (span->next)
	span->next->prev = span->prev;
    if (span->prev)
	span->prev->next = span->next;
    else {
	assert(span->owner->spans == span);
	span->owner->spans = span->next;
    }
    bzero((char *) span, sizeof (JotSpan));
}

void
JotSpan_Free(span)
register JotSpan    *span;
{
    JotSpan_Unlink(span);
    free((char *) span);
}

boolean
JotSpan_Set(s, pos, length)
register JotSpan    *s;
register int	    pos, length;
{
    register int    limit;

    if (s->owner == 0)
	return_error(FALSE, Jot_ETEXT);
    limit = JotText_Characters(s->owner);
    if (pos < 0 || length < 0 || pos > limit || pos + length > limit)
	return_error(FALSE, Jot_ERANGECHECK);
    s->pos = pos;
    s->length = length;

    return TRUE;
}

boolean
JotSpan_SetLength(s, length)
JotSpan	*s;
int	length;
{
    return JotSpan_Set(s, s->pos, length);
}

boolean
JotSpan_SetPosition(s, pos)
JotSpan	*s;
int	pos;
{
    return JotSpan_Set(s, pos, s->length);
}

boolean
JotSpan_SetText(span, text, pos, length)
register JotSpan    *span;
register JotText    *text;
int		    pos, length;
{
    if (span->owner != text) {
	if (span->owner != 0)
	    JotSpan_Unlink(span);
	span->owner = text;
	if (text != 0) {
	    span->prev = 0;
	    span->next = text->spans;
	    if (text->spans != 0)
		text->spans->prev = span;
	    text->spans = span;
	}
    }
    span->modified = 0;
    span->mod_offset = -1;
    span->rightside = 0;
    if (text != 0)
	return JotSpan_Set(span, pos, length);
    return TRUE;
}

int
JotSpan_Length(s)
register JotSpan    *s;
{
    if (s->owner == 0)
	return_error(-1, Jot_ETEXT);
    return s->length;
}

int
JotSpan_Position(s)
register JotSpan    *s;
{
    if (s->owner == 0)
	return_error(-1, Jot_ETEXT);
    return s->pos;
}

int
JotSpan_DeleteContents(span)
register JotSpan    *span;
{
    int	len;

    if (span->owner == 0)
	return_error(-1, Jot_ETEXT);
    len = span->length;
    return JotText_DeleteCharacters(span->owner, span->pos, span->length);
}

/* Allocates and returns a string and stores the contents of the text
   object defined by SPAN into it.  The returned string will be null
   terminated, but that doesn't mean there can't be nulls elsewhere in
   the string. */

int
JotSpan_Contents(span, buffer)
register JotSpan    *span;
register char	    *buffer;
{
    register int	len;
    register JotText    *t;

    if ((t = span->owner) == 0)
	return_error(-1, Jot_ETEXT);
    len = JotSpan_Length(span);
    Bytestring_MoveGap(t->data, span->pos);
    bcopy(&Bytestring_CharAt(t->data, span->pos), buffer, len);

    return len;
}

int
JotSpan_Replace(old, new)
register JotSpan    *old, *new;
{
    char    *contents;
    int	    length;

    if (old->owner == 0 || new->owner == 0)
	return_error(0, Jot_ETEXT);

    contents = jot_alloc(JotSpan_Length(new));
    if (JotSpan_Contents(new, contents) < 0)
	return;
    length = JotSpan_Length(new);

    length = JotText_ReplaceCharacters(old->owner, old->pos, old->length,
				       contents, length);
    jot_free(contents);

    return length;
}

JotSpan_ModifyInRange(sp, pos, endpos)
JotSpan	*sp;
int	pos, endpos;
{
    /* Now modify any spans that are involved with the new style, so
       that the redisplay occurs correctly. */
    for (; sp != 0; sp = sp->next) {
	if (JotSpan_Position(sp) + JotSpan_Length(sp) < pos)
	    continue;
	if (endpos < sp->pos)
	    continue;
	sp->modified = 1;
    }
}
