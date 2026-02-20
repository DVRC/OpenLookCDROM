/*
 *	@(#)undo.c 1.10 91/02/20 Copyright 1990-91 Sun Microsystems
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

#include "assert.h"
#include "bytestring.h"
#include "undo.h"
#include "text.h"
#include "span.h"

static void molecule_Delete();

#define molecule_Nth(t, n)  \
    ((UndoMolecule *) &Bytestring_CharAt(&(t)->eh.edits, (n) * sizeof (UndoMolecule)))

/* Add a molecule to the end of the edit history of TEXT.  If currently
   have the maximum number of molecules (as defined by SetLevel) then we
   deleted the oldest one. */
static void
molecule_Add(text)
JotText	*text;
{
    UndoMolecule    new;

    assert(text->eh.index == text->eh.count);
    if (text->eh.index == text->eh.max)
	molecule_Delete(text, 0);
    new.leader = 0;
    new.modified = JotText_Modified(text);
    Bytestring_Insert(&text->eh.edits, text->eh.index * sizeof (UndoMolecule),
		      (char *) &new, sizeof (UndoMolecule));
    text->eh.count += 1;
    text->eh.index += 1;
}

/* Free the atoms of a molecule. */

static void
molecule_FreeAtoms(m)
UndoMolecule	*m;
{
    UndoAtom	*ua;

    /* release atoms ... slowly */
    ua = m->leader;
    while (ua != 0) {
	UndoAtom    *next = ua->next;

	if (ua->kind == undo_insertion || ua->kind == undo_deletion)
	    Bytestring_Finalize(&ua->D.text.text);
	free((char *) ua);
	ua = next;
    }
    m->leader = 0;
}

/* Delete molecule WHICH from TEXT. */
static void
molecule_Delete(text, which)
JotText	*text;
int	which;
{
    UndoMolecule    *m, new;

    m = molecule_Nth(text, which);
    molecule_FreeAtoms(m);
    Bytestring_Delete(&text->eh.edits, which * sizeof (UndoMolecule),
		      sizeof (UndoMolecule));
    text->eh.count -= 1;
    if (which < text->eh.index)
	text->eh.index -= 1;
}

/* Prepare for an undo operation.  This basically decides whether to
   create a new molecule based on where we are in history.  If we decide
   not to create a new molecule here, it is still possible that the
   insert handler and delete handlers will decide to create one
   themselves.  But they won't do that if we've already done it here. */

static int
undo_Prepare(text)
JotText	    *text;
{
    int	new = 0;

    /* if we were in the middle of a redo, delete the history from the
       place we're at to the end */
    if (text->eh.index != text->eh.count) {
/*	assert(text->eh.bundle == 0); */
	while (text->eh.index != text->eh.count)
	    molecule_Delete(text, text->eh.count - 1);
	new = 1;
    } else if (text->eh.count == 0 || text->eh.new_grp == 1)
	new = 1;
    text->eh.new_grp = 0;
    if (new)
	molecule_Add(text);
}

void
JotText_UndoBytesInserted(text, pos, length)
JotText	*text;
int	pos, length;
{
    UndoMolecule    *m;
    UndoAtom	    *ua;
    int		    new_molecule = 0;

    if (!text->eh.enabled || text->eh.in_undo || length == 0)
	return;		/* don't record operations that are part of an undo */

    undo_Prepare(text);
    assert(text->eh.index == text->eh.count);
    ua = (m = molecule_Nth(text, text->eh.count - 1))->leader;
    if (!(ua != 0 && (ua->kind == undo_insertion) &&
	  (ua->D.text.pos + Bytestring_Length(&ua->D.text.text) == pos))) {
	if (ua != 0 && text->eh.bundle == 0) {
	    molecule_Add(text);
	    m = molecule_Nth(text, text->eh.index - 1);
	}
	ua = (UndoAtom *) malloc(sizeof (UndoAtom));
	ua->prev = 0;
	ua->next = m->leader;
	if (ua->next != 0)
	    ua->next->prev = ua;
	m->leader = ua;
	ua->kind = undo_insertion;
	ua->D.text.pos = pos;
	Bytestring_Initialize(&ua->D.text.text, length);
    }
    Bytestring_Copy(text->data, pos, &ua->D.text.text,
		    Bytestring_Length(&ua->D.text.text), length);
}

/* Pos and pos + length are within the text bounds.  length is always
   >= 0. */
void
JotText_UndoBytesDeleted(text, pos, length)
JotText	*text;
int	pos, length;
{
    UndoMolecule    *m;
    UndoAtom	    *ua;
    Bytestring	    *srcb, *undob;

    if (!text->eh.enabled || text->eh.in_undo || length == 0)
	return;		/* don't record operations that are part of an undo */
    undo_Prepare(text);
    ua = (m = molecule_Nth(text, text->eh.count - 1))->leader;
    srcb = text->data;
    if ((ua != 0) && (ua->kind == undo_deletion)) {
	undob = &ua->D.text.text;
	if (pos == ua->D.text.pos) {
	    Bytestring_Copy(srcb, pos, undob,
			    Bytestring_Length(undob), length);
	    return;
	} else if (pos + length == ua->D.text.pos) {
	    ua->D.text.pos = pos;
	    Bytestring_Copy(srcb, pos, undob, 0, length);
	    return;
	}
    }
    if (ua != 0 && text->eh.bundle == 0) {
	molecule_Add(text);
	m = molecule_Nth(text, text->eh.index - 1);
    }
    ua = (UndoAtom *) malloc(sizeof (UndoAtom));
    ua->prev = 0;
    ua->next = m->leader;
    if (ua->next != 0)
	ua->next->prev = ua;
    m->leader = ua;
    ua->kind = undo_deletion;
    ua->D.text.pos = pos;
    Bytestring_Initialize(&ua->D.text.text, length);
    Bytestring_Copy(srcb, pos, &ua->D.text.text, 0, length);
}

void
JotText_UndoStyle(text, pos, span, style, kind)
JotText		*text;
int		pos, span;
struct style	*style;
undo_kind	kind;
{
    UndoMolecule    *m;
    UndoAtom	    *ua;
    int		    new_molecule = 0;

    if (!text->eh.enabled || text->eh.in_undo)
	return;

/*    printf("Style inserted at pos = %d, span = %d\n", pos, span); */
    undo_Prepare(text);
    ua = (m = molecule_Nth(text, text->eh.count - 1))->leader;
    ua = (UndoAtom *) malloc(sizeof (UndoAtom));
    ua->prev = 0;
    ua->next = m->leader;
    if (ua->next != 0)
	ua->next->prev = ua;
    m->leader = ua;
    ua->kind = kind;
    ua->D.sr.pos = pos;
    ua->D.sr.span = span;
    ua->D.sr.style = style;
}

void
JotText_SetUndo(text, level)
JotText	*text;
int	level;
{
    while (level < text->eh.count)
	molecule_Delete(text, 0);
    assert(text->eh.count <= level);
    text->eh.max = level;
    if (level <= 0)
	text->eh.enabled = 0;
    else
	text->eh.enabled = 1;
}

boolean
JotText_Undo(text)
JotText	*text;
{
    UndoMolecule    *m;
    UndoAtom	    *ua;
    int		    modified;

    if (text->eh.index == 0)
	return FALSE;
    JotText_UndoBreak(text);
    text->eh.in_undo = 1;
    text->eh.index -= 1;
    m = molecule_Nth(text, text->eh.index);
    modified = text->modified;

    for (ua = m->leader; ua != 0; ua = ua->next) {
	switch (ua->kind) {
	case undo_insertion:
	    JotText_SetCaret(text, ua->D.text.pos);
	    JotText_DeleteCharacters(text, ua->D.text.pos,
				     Bytestring_Length(&ua->D.text.text));
	    break;

	case undo_deletion:
	    {
		register Bytestring	*b = &ua->D.text.text;
		
		JotText_SetCaret(text, ua->D.text.pos);
		Bytestring_MoveGap(b, Bytestring_Length(b));
		JotText_InsertCharacters(text, ua->D.text.pos,
					 &Bytestring_CharAt(b, 0),
					 Bytestring_Length(b));
		break;
	    }

	case undo_styledelete:
	    {
		JotSpan	*s;

/*		printf("Style un-inserted at pos = %d, span = %d\n",
		       ua->D.sr.pos, ua->D.sr.span); */
		s = JotSpan_New(text, ua->D.sr.pos, ua->D.sr.span);
		style_Apply(ua->D.sr.style, s);
		JotSpan_Free(s);
		break;
	    }

	case undo_styleapply:
/*	    printf("Style un-deleted at pos = %d, span = %d\n",
		   ua->D.sr.pos, ua->D.sr.span); */
	    style_Delete(text, style_Find(text, ua->D.sr.pos,
					  ua->D.sr.span,
					  ua->D.sr.style));
	    break;
	}
    }
    text->eh.in_undo = 0;
    text->modified = m->modified;
    m->modified = modified;

    return TRUE;
}

boolean
JotText_Redo(text)
JotText	*text;
{
    UndoMolecule    *m;
    UndoAtom	*ua;
    int		modified;

    if (text->eh.index == text->eh.count)
	return FALSE;

    JotText_UndoBreak(text);
    m = molecule_Nth(text, text->eh.index);
    ua = m->leader;
    text->eh.index += 1;
    if (ua == 0)
	return;

    modified = text->modified;
    /* now go to end of the list so that we can redo things in the
       order they were originally done in */
    while (ua->next != 0)
	ua = ua->next;

    text->eh.in_undo = 1;
    for (; ua != 0; ua = ua->prev) {
	JotText_SetCaret(text, ua->D.text.pos);
	switch (ua->kind) {
	case undo_insertion:
	    {
		register Bytestring *b = &ua->D.text.text;

		Bytestring_MoveGap(b, Bytestring_Length(b));
		JotText_InsertCharacters(text, ua->D.text.pos,
					 &Bytestring_CharAt(b, 0),
					 Bytestring_Length(b));
		break;
	    }

	case undo_deletion:
	    JotText_DeleteCharacters(text, ua->D.text.pos,
				     Bytestring_Length(&ua->D.text.text));
	    break;


	case undo_styleapply:
	    {
		JotSpan	*s;

/*		printf("Style re-inserted at pos = %d, span = %d\n",
		       ua->D.sr.pos, ua->D.sr.span); */
		s = JotSpan_New(text, ua->D.sr.pos, ua->D.sr.span);
		style_Apply(ua->D.sr.style, s);
		JotSpan_Free(s);
		break;
	    }

	case undo_styledelete:
/*	    printf("Style re-deleted at pos = %d, span = %d\n",
		   ua->D.sr.pos, ua->D.sr.span); */
	    style_Delete(text, style_Find(text, ua->D.sr.pos,
					  ua->D.sr.span,
					  ua->D.sr.style));
	    break;
	}
    }
    text->eh.in_undo = 0;

    text->modified = m->modified;
    m->modified = modified;

    return TRUE;
}

int
JotText_UndoCount(text)
JotText	*text;
{
    if (!text->eh.enabled)
	return -1;
    return text->eh.index;
}

JotText_RedoCount(text)
JotText	*text;
{
    if (!text->eh.enabled)
	return -1;
    return text->eh.count - text->eh.index;
}

void
JotText_UndoBreak(text)
JotText	*text;
{
    if (!text->eh.enabled)
	return;
    if (text->eh.bundle == 0)
	text->eh.new_grp = 1;
}

void
JotText_UndoBegin(text)
JotText	*text;
{
    if (!text->eh.enabled)
	return;
    if (text->eh.bundle == 0)
	JotText_UndoBreak(text);
    text->eh.bundle += 1;
}

void
JotText_UndoEnd(text)
JotText	*text;
{
    if (!text->eh.enabled)
	return;
    if (text->eh.bundle > 0)
	text->eh.bundle -= 1;
    if (text->eh.bundle == 0)
	JotText_UndoBreak(text);
}
