/*
 *	@(#)view.c 1.31 91/02/20 Copyright 1990-91 Sun Microsystems
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

#include <ctype.h>
#include "jot.h"
#include "assert.h"
#include "view.h"
#include "font.h"
#include "text.h"
#include "psinter.h"
#include "color.h"
#include "span.h"

void	JotView_Modify();

static JotView	*viewroot;	/* the set of all views on texts */

void
JotView_KeyboardDefault(v, c)
JotView    *v;
int	    c;
{
}

void
JotView_MouseDefault(v, button, action, pos)
JotView	*v;
int	button, action, pos;
{
    fprintf(stderr, "Warning: default Mouse controller called erroneously!\n");
}

boolean
JotView_SelectionStartDefault(v, rank, pos)
JotView	*v;
int	rank, pos;
{
    fprintf(stderr, "Warning: default SelectionStart controller called erroneously!\n");
    return TRUE;	/* default is to always begin selections */
}

void
JotView_SelectionAlterDefault(v, rank)
JotView	*v;
int	rank;
{
}

int JotView_DirtyViews = 0;

/* If a view object exists, it is in the list of ALL views.  If it has
   an associated text object, it is in that text object's list of views.
   It has a server canvas associated with it if viewport >= 0.

   So, we have a routine to create a view, with no server canvas.  One
   which takes a view and a canvas token/wire pair and associate them
   (this is for the text server).  And we have one which takes a view and
   a text object, and associate them. */

JotView *
JotView_NewNoCanvas()
{
    JotView *v;

    v = (JotView *) jot_alloc(sizeof (JotView));
    if (v != 0) {
	bzero((char *) v, sizeof (JotView));

	/* link this guy into the world list of views */
	v->allprev = 0;
	if ((v->allnext = viewroot) != 0)
	    v->allnext->allprev = v;
	viewroot = v;
    }
    JotView_SetMargins(v, 10, 10, 0, 0);
    v->defaultinfo = defaultinfo;
    v->bgcolor = color_create(0, 0, 256);
    return v;
}

boolean
JotView_BindViewToCanvas(v, canvas, wire)
JotView	    *v;
wire_Wire   wire;
int	    canvas;
{
    v->wire = wire;
    v->viewport = canvas;
    JotView_SetControllers(v, JotView_KeyboardDefault,
			   JotView_MouseDefault,
			   JotView_SelectionStartDefault,
			   JotView_SelectionAlterDefault);

    return wire_RegisterToken(v->wire, canvas, (caddr_t) v);
}

void
JotView_SetText(v, t)
register JotView    *v;
register JotText    *t;
{
    if (v->text == t)
	return;
    /* if old one exists, unlink ourselves, and reset the marks */
    if (v->text != 0) {
	int i;

	if (v->viewnext)
	    v->viewnext->viewprev = v->viewprev;
	if (v->viewprev)
	    v->viewprev->viewnext = v->viewnext;
	else {
	    assert(v->text->views == v);
	    v->text->views = v->viewnext;
	}
	for (i = v->alines; --i >= 0;)
	    if (v->newinfo[i].text != 0)
		JotSpan_SetText(v->newinfo[i].text, t, -1, 0);
	JotView_DamageView(v);	/* this delete's lineinfo spans  */
	JotSpan_SetText(v->top, t, 0, 0);
    } else {
	v->top = JotSpan_NewI(t, 0, 0);
	JotView_Modify(v);
    }

    /* now link ourself into the list of views for this text */
    v->text = t;
    if (t != 0) {
	if (v->viewnext = t->views)
	    v->viewnext->viewprev = v;
	t->views = v;
	v->viewprev = 0;

	if (!wire_SetCurrent(v->wire)) {
	    fprintf(stderr, "JotView not attached to a valid wire.\n");
	    abort(0);
	}
	ps_setholder(v->viewport, JotText_Holder(t, v->wire));
	v->display_caret = 1;
	v->lasttextmodified = v->text->modified;
    }
}

JotView *
JotView_New(t)
register JotText	*t;
{
    register JotView	*v;
    wire_Wire		wire;
    int			canvas;

    wire = wire_Current();
    v = JotView_NewNoCanvas();
    if (v != 0) {
	canvas = wire_AllocateTokens(wire, 1);
	ps_makecanvas(canvas);
	wire_DrainSync(wire, NULL);
	if (!JotView_BindViewToCanvas(v, canvas, wire)) {
	    JotView_Free(v);
	    v = 0;
	} else
	    JotView_SetText(v, t);
    }
    return v;
}

JotView *
JotView_View(w, c)
wire_Wire   w;
int	    c;
{
    return (JotView *) wire_TokenData(w, c);
}

void
JotView_FreeInternal(v)
register JotView    *v;
{
    register int    i;

    for (i = v->alines; --i >= 0;) {
	if (v->lineinfo[i].text)
	    JotSpan_Free(v->lineinfo[i].text);
	if (v->newinfo[i].text)
	    JotSpan_Free(v->newinfo[i].text);
    }
    if (v->top != 0)
	JotSpan_Free(v->top);
    if (v->lineinfo != 0) {
	free((char *) v->lineinfo);
	free((char *) v->newinfo);
    }

    /* unlink from list of all views */
    if (v->allnext)
	v->allnext->allprev = v->allprev;
    if (v->allprev)
	v->allprev->allnext = v->allnext;
    else {
	assert(viewroot == v);
	viewroot = v->allnext;
    }
    wire_DeallocateTokens(v->wire, v->viewport, 1);
    v->viewport = -1;
    free((char *) v);
}

/* Free'ing a JotView sends /destroy to the server object, which will
   send a callback up the wire saying this object has gone obsolete. */

void
JotView_Free(v)
register JotView    *v;
{
    if (v->viewport >= 0)
	ps_destroy(v->viewport);
}

int
JotView_Characters(v)
register JotView    *v;
{
    register int    pos0;
    struct lineinfo *li;

    if (v->text == 0)
	return_error(-1, Jot_ETEXT);
    JotView_PartialUpdate(v);

    return v->bottom - JotSpan_QuickP(v->top);
}

int
JotView_Lines(v)
register JotView    *v;
{
    if (!JotView_PartialUpdate(v))
	return -1;

    return v->vlines;
}

void
JotView_BoundingBox(v, r)
register JotView	*v;
register JotBoundingBox	*r;
{
    r->x = v->bbox.xl;
    r->y = v->bbox.yb;
    r->width = v->bbox.xr - v->bbox.xl;
    r->height = v->bbox.yt - v->bbox.yb;
}

void
JotView_CalculateBBox(v, left, right, top, bottom)
JotView	*v;
{
    v->bbox.xl = v->borders.left;
    v->bbox.yb = v->borders.bottom;
    v->bbox.xr = v->width - v->borders.right;
    v->bbox.yt = v->height - v->borders.top;
}    

void
JotView_SetMargins(v, left, right, top, bottom)
JotView	*v;
{
    v->borders.left = left;
    v->borders.right = right;
    v->borders.top = top;
    v->borders.bottom = bottom;
}

int
JotView_RelativeLineFromPosition(v, pos)
register JotView    *v;
register int	    pos;
{
    register struct lineinfo	*li;
    register int		i;

    if (!JotView_PartialUpdate(v))
	return -1;
    if (JotSpan_Position(v->top) > pos)
	return_error(-1, Jot_ERANGECHECK);
    for (li = v->validinfo, i = 0; i < v->vlines; i++, li++)
	if (JotSpan_Position(li->text) <= pos &&
	    pos < JotSpan_Position(li->text) + li->usedlength)
	    return i;
    return_error(-1, Jot_ERANGECHECK);
}

void
JotView_SetFont(v, font)
JotView	    *v;
struct font *font;
{
    if (!v->gotsetfont)
	v->dontsetfont = 1;
    v->defaultinfo.font = font;
    v->defaultinfo.parameters[F_FONTFAMILY] = (int) font->family;
    v->defaultinfo.parameters[F_POINTSIZE] = font->size;
    JotView_DamageView(v);
}

void
JotView_UpdateViews()
{
    register JotView	*vw;
    register int	count, i;

    for (count = JotView_DirtyViews, vw = viewroot;
	 vw != 0 && count > 0;
	 vw = vw->allnext)
	if (vw->modified) {
	    if (vw->damagedonce)
		JotView_Redisplay(vw, FALSE, FALSE);
	    count -= 1;
	}
}

void
JotView_Modify(v)
register JotView    *v;
{
    if (v->modified)
	return;
    v->modified = 1;
    JotView_DirtyViews += 1;
}

boolean
JotView_EnsurePositionVisible(v, pos)
JotView	    *v;
int	    pos;
{
    if (pos < 0 || pos > JotText_Characters(v->text))
	return_error(FALSE, Jot_ERANGECHECK);
    v->frame_pos = pos;
    JotView_Modify(v);

    return TRUE;
}

void
JotView_Unmodify(v)
register JotView    *v;
{
    if (!v->modified)
	return;
    v->modified = 0;
    JotView_DirtyViews -= 1;
    assert(JotView_DirtyViews >= 0);
}

void
JotView_SetReadOnly(v, on)
JotView	*v;
boolean		on;
{
    if ((on == TRUE) != v->readonly) {
	v->readonly = !v->readonly;
	JotView_Modify(v);
    }
}

void
JotView_SetLineStyle(v, linestyle)
JotView	*v;
int	linestyle;
{
    if (v->defaultinfo.parameters[F_LINESTYLE] != linestyle) {
	v->defaultinfo.parameters[F_LINESTYLE] = linestyle;
	JotView_DamageView(v);
    }
}

void
JotView_SetControllers(v, kbd, mouse, sel_start, sel_alter)
JotView	*v;
void	(*kbd)(), (*mouse)(), (*sel_alter)();
boolean	(*sel_start)();
{
    if (kbd != 0)
	v->c_kbd = kbd;
    if (sel_start != 0) {
	v->c_sel_start = sel_start;
	ps_setqueryselectionstart(JotView_Canvas(v),
				  sel_start != JotView_SelectionStartDefault);
    }
    if (mouse != 0) {
	v->c_mouse = mouse;
	ps_settrackable(JotView_Canvas(v),
			(mouse != JotView_MouseDefault &&
			 v->c_sel_start != JotView_SelectionStartDefault));
    }
    if (sel_alter != 0)
	v->c_sel_alter = sel_alter;
}
