/*
 *	@(#)selection.c 1.19 91/02/20 Copyright 1990-91 Sun Microsystems
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
#include "assert.h"
#include "jot_private.h"
#include "jot.h"
#include "cps.h"
#include "sel_cps.h"
#include "psinter.h"
#include "view.h"
#include "text.h"
#include "span.h"
#include "selection.h"
#include "bytestring.h"
#include "input.h"
#include "color.h"

/* There is one of these selection objects for each selection in
   existance.  There can only be at most one of each kind of selection
   per connection.  There can only ever be one selection inprogress for
   any connection at any given time.  That means that once we initiate
   a selection, we know that all subsequent mouse events are directed
   at that selection, until the mouse button is released, that is, until
   Preview? is false.  Since we know all mouse events on that connection
   should be directed to that selection, all we need to send up is x/y
   coordinates.  When Preview? goes false, we send up a different event,
   one which stops the selection (inprogress = FALSE). */

typedef struct selection {
    JotView	*view;		/* view this selection is being made on */
    JotSpan	*span;		/* selection contents */
    int		pivot_pos;	/* selection pivots around pivot_pos */
    short	rank;		/* PRIMARY or SECONDARY */
    short	level;		/* char, word, line, paragraph, etc. */
    unsigned	pd:1;		/* pending delete? */
    unsigned	style:2;	/* 0-2 (see below) */
    unsigned	inprogress:1;	/* is mouse button still down? */
    unsigned	server_valid:1;	/* does server side has copy of contents? */
} Selection;

static struct s_connection {
    Selection	selections[Jot_N_SELECTIONS];
    short	current;
} *connection_info = 0;

/* different ways to attach the insertion point to a selection */
#define LOW_END	    0
#define HIGH_END    1
#define NEAR_END    2
#define FAR_END	    3
#define AT_POINT    4

/* selection highlighting style */
#define STYLE_DEFAULT		0
#define STYLE_UNDERSCORE	1
#define STYLE_STRIKETHRU	2
#define NSTYLES			3

static int  max_connection = 0;

static int  t_selectat, t_adjustdown, t_adjustdrag, t_adjuststop,
	    t_deselect, t_inselection, t_attach, t_contentsascii,
	    t_deleteselection, t_querystart;

static void selection_start(), selection_adjust(), selection_deselect(),
	    selection_finish(), selection_inselection(),
	    selection_attach_insertion_point(), selection_contentsascii(),
	    selection_delete(), selection_querystart();

struct tag_desc	selection_tags[] = {
    "SELECT_DOWN", &t_selectat, selection_start,
    "ADJUST_DOWN", &t_adjustdown, selection_start,
    "ADJUST_DRAG", &t_adjustdrag, selection_adjust,
    "ADJUST_STOP", &t_adjuststop, selection_finish,
    "DESELECT", &t_deselect, selection_deselect,
    "INSELECTION", &t_inselection, selection_inselection,
    "ATTACH-INSERTION-POINT", &t_attach, selection_attach_insertion_point,
    "CONTENTSASCII", &t_contentsascii, selection_contentsascii,
    "DELETESELECTION", &t_deleteselection, selection_delete,
    "SELECTION_QUERY_START", &t_querystart, selection_querystart,
    0
};

selection_init()
{
    static int	beenhere = 0;

    if (!beenhere) {
	beenhere = TRUE;
	Input_RegisterTags(selection_tags);
    }
    Input_DefTags(selection_tags);
    ps_selection_startup();
}

static Selection *
get_selection(wire, rank)
wire_Wire   wire;
int	    rank;
{
    Selection	*s;
    int		w;

    if ((w = wire_WireToInt(wire)) >= max_connection)
	return 0;
    s = &connection_info[w].selections[rank];
    if (s->span == 0 || JotSpan_Text(s->span) == 0)
	return 0;
    return s;
}

static Selection *
active_selection(wire)
wire_Wire   wire;
{
    Selection	*s;
    int		w, which;

    w = wire_WireToInt(wire);

    assert(w < max_connection);
    which = connection_info[w].current;
    assert(which != -1);

    return &connection_info[w].selections[which];
}

static Selection *
get_selection_ptr(wire, rank)
wire_Wire   wire;
int	    rank;
{
    int	w;

    w = wire_WireToInt(wire);

    if (max_connection <= w) {
	int n;

	n = max_connection;
	max_connection = w + 1;
	connection_info = (struct s_connection *)
	    jot_realloc(connection_info,
			sizeof (struct s_connection) * max_connection);
	if (connection_info == 0) {
	    fprintf(stderr, "Cannot allocate space for selection table.\n");
	    abort();
	}
	bzero((char *) &connection_info[n],
	      sizeof (struct s_connection) * (max_connection - n));
    }
    return &connection_info[w].selections[rank];
}

static Selection *
set_active_selection(wire, rank)
wire_Wire   wire;
int	    rank;
{
    Selection	*s;

    s = get_selection_ptr(wire, rank);
    connection_info[wire_WireToInt(wire)].current = rank;

    return s;
}

static void
unset_active_selection(wire)
wire_Wire   wire;
{
    connection_info[wire_WireToInt(wire)].current = -1;
}

void
selection_expand(s, v)
Selection   *s;
JotView	    *v;
{
    register int	pos0, pos1;

    pos0 = JotSpan_QuickP(s->span);
    pos1 = pos0 + JotSpan_QuickL(s->span);

    switch (s->level) {
    case Jot_WORD:
	{
	    register Bytestring	*b = v->text->data;;

	    if (isalnum(Bytestring_CharAt(b, pos0)))
		while (pos0 > 0 && isalnum(Bytestring_CharAt(b, pos0 - 1)))
		    pos0 -= 1;
	    if (isalnum(Bytestring_CharAt(b, pos1)))
		while (pos1 < b->size && isalnum(Bytestring_CharAt(b, pos1)))
		    pos1 += 1;
	    break;
	}

    case Jot_LINE:
	{
	    register struct lineinfo	*l, *end;

	    l = v->lineinfo;
	    end = &v->lineinfo[v->vlines];

	    /* First find the line with pos0 in it, and expand it.  Then
	       find the line with pos1 in it.  This currently doesn't work
	       if either end point isn't currently visible. */
	    while (l < end && l->text != 0) {
		if (pos0 >= JotSpan_QuickP(l->text) && pos0 - JotSpan_QuickP(l->text) < l->usedlength) {
		    pos0 = JotSpan_QuickP(l->text);
		    break;
		}
		l++;
	    }
	    while (l < end && l->text != 0) {
		if (pos1 - JotSpan_QuickP(l->text) <= l->usedlength) {
		    pos1 = JotSpan_QuickP(l->text) + l->usedlength;
		    break;
		}
		l++;
	    }
	    break;
	}

    case Jot_BUFFER:
	pos0 = 0;
	pos1 = JotText_Characters(v->text);
	break;
    }
    JotSpan_QuickSet(s->span, pos0, pos1 - pos0);
}

static void
set_selection(selection, pos, action)
Selection   *selection;
int	    pos, action;
{
    JotSpan *span;

    span = selection->span;
    if (action == t_selectat) {		/* select down */
	JotSpan_QuickSet(span, pos, 0);
	selection->pivot_pos = pos;
    } else {
	if (action == t_adjustdown) {
	    selection->pivot_pos = JotSpan_QuickP(span);
	    if (pos < selection->pivot_pos + (JotSpan_QuickL(span) >> 1))
		selection->pivot_pos += JotSpan_QuickL(span);
	}
	if (pos < selection->pivot_pos)
	    JotSpan_QuickSet(span, pos, selection->pivot_pos - pos);
	else
	    JotSpan_QuickSet(span, selection->pivot_pos,
			     pos - selection->pivot_pos);
    }
    selection_expand(selection, selection->view);
    if (selection->server_valid) {
	selection->server_valid = 0;
	ps_invalidate_selection(selection->rank);
    }
    if (selection->view->c_sel_alter != JotView_SelectionAlterDefault)
	(*selection->view->c_sel_alter)(selection->view, selection->rank);

    JotText_ModifyViews(JotSpan_Text(span));
}

static int  CurrentMouseButton = 0;

/* start or continue a selection */
static void
selection_start(action, data)
int	action;
caddr_t	data;
{
    JotView	*view;
    wire_Wire	wire;
    int		canvas, rank, pd, level, pos, style;
    fixed	x, y;
    Selection	*selection;

    ps_selection_initiate(&canvas, &CurrentMouseButton, &rank, &level,
			  &pd, &style, &x, &y);
    wire = wire_Current();
    view = JotView_View(wire, canvas);
    selection = set_active_selection(wire, rank);
    selection->view = view;
    selection->rank = rank;
    selection->level = level;
    selection->pd = pd;
    selection->style = style;
    selection->inprogress = 1;
    pos = locate_mouse(view, x, y);
    if (selection->span == 0)
	selection->span = JotSpan_NewI(view->text, pos, 0);
    else if (JotSpan_Text(selection->span) != view->text)
	JotSpan_SetText(selection->span, view->text, pos, 0);
    set_selection(selection, pos, action);
    if (rank == Jot_PRIMARY)
	view->display_caret = 0;
    if (view->c_mouse != JotView_MouseDefault)
	(*view->c_mouse)(view, CurrentMouseButton, Jot_BUTTONDOWN, pos);
}

/* adjust the current selection */
static void
selection_adjust(tag)
{
    JotView	*v;
    Selection	*s;
    fixed	fx, fy;
    int		pos, y;

    ps_selection_adjust(&fx, &fy);
    y = floorfr(fy);
    s = active_selection(wire_Current());
    v = s->view;
    pos = locate_mouse(v, fx, fy);
    if (y >= v->bbox.yt) {
	if (pos > 0) {
	    JotView_ScrollAbsolute(v, JotSpan_QuickP(v->top),
				   JotView_LinePosition(v, 0) -
				    (y - v->bbox.yt));
	    JotView_Update(v);
	    pos = locate_mouse(v, fx, fixedi(JotView_LinePosition(v, 0)));
	}
    } else if (y < 0) {
	if (pos < JotText_Characters(v->text)) {
	    JotView_ScrollAbsolute(v,
				   locate_mouse(v, 0, fixedi(JotView_LinePosition(v, 0) + y)),
				   JotView_LinePosition(v, 0));
	    JotView_Update(v);
	    pos = locate_mouse(v, fx, fixedi(JotView_LinePosition(v, JotView_Lines(v) - 1)));
	}
    }
    set_selection(s, pos, t_adjustdrag);
    if (v->c_mouse != JotView_MouseDefault)
	(*v->c_mouse)(v, CurrentMouseButton, Jot_MOUSEDRAGGED, pos);
}

static void
selection_finish(tag)
{
    JotView	*v;
    Selection	*s;
    fixed	x, y;
    wire_Wire	wire;
    int		pos;

    ps_selection_adjust(&x, &y);
    s = active_selection(wire = wire_Current());
    v = s->view;
    pos = locate_mouse(v, x, y);
    set_selection(s, pos, t_adjustdrag);
    s->inprogress = 0;
    unset_active_selection(wire);
    if (v->c_mouse != JotView_MouseDefault)
	(*v->c_mouse)(v, CurrentMouseButton, Jot_BUTTONUP, pos);
    CurrentMouseButton = 0;
}

static void
clear_selection(wire, rank)
wire_Wire   wire;
int	    rank;
{
    Selection	*s;

    s = get_selection(wire, rank);
    JotText_ModifyViews(JotSpan_Text(s->span));
    JotSpan_SetText(s->span, (JotText *) 0, 0, 0);
    s->view = 0;
}

static void
selection_deselect()
{
    wire_Wire	wire;
    int		rank;

    wire = wire_Current();	
    ps_deselect(&rank);
    clear_selection(wire, rank);
}

static void
selection_contentsascii(tag)
{
    register JotText	*t;
    wire_Wire		wire;
    int			canvas, rank, length;
    char		*buffer;
    Selection		*s;
    JotView		*v;

    wire = wire_Current();
    ps_contentsascii(&canvas, &rank);
    v = JotView_View(wire, canvas);
    s = get_selection(wire, rank);
    length = JotSpan_Length(s->span);
    if (length > 0) {
	if (length >= (1 << 16)) {
	    fprintf(stderr, "Selection too large - must be less than %d bytes.\n", (1 << 16));
	    buffer = 0;
	    length = 0;
	} else {
	    buffer = malloc(length);
	    if (buffer == 0 || JotSpan_Contents(s->span, buffer) != length) {
		printf("Can't allocate memory for selection request!\n");
		buffer = "";
		length = 0;
	    }
	}
    }
    ps_sendcontentsascii(canvas, buffer, length);
    s->server_valid = 1;
}

static void
selection_delete(tag)
{
    register struct text    *t;
    register Selection	    *s;
    wire_Wire		    wire;
    int			    id, rank;

    wire = wire_Current();
    ps_deleteselection(&id, &rank);
    t = (struct text *) wire_TokenData(wire, id);
    s = get_selection(wire, rank);
    if (s->view == 0 || !s->view->readonly) {
	JotSpan_DeleteContents(s->span);
	ps_invalidate_selection(rank);
    }
}

static void
selection_attach_insertion_point(tag)
{
    JotView	*v;
    JotSpan	*sp;
    wire_Wire	wire;
    int		canvas, rank, where, point;
    fixed	x, y;

    ps_insertion_point(&canvas, &rank, &x, &y, &where);
    v = JotView_View(wire = wire_Current(), canvas);
    sp = get_selection(wire, rank)->span;
    switch (where) {
    case LOW_END:
	point = JotSpan_QuickP(sp);
	break;

    case HIGH_END:
	point = JotSpan_QuickP(sp) + JotSpan_QuickL(sp);
	break;

    case NEAR_END:
    case FAR_END:
	{
	    int pos0, pos1;

	    point = locate_mouse(v, x, y);
	    pos0 = JotSpan_QuickP(sp);
	    pos1 = pos0 + JotSpan_QuickL(sp);
	    if ((where == NEAR_END && point - pos0 < pos1 - point) ||
		(where == FAR_END && point - pos0 > pos1 - point))
		point = pos0;
	    else
		point = pos1;
	    break;
	}

    case AT_POINT:
	point = locate_mouse(v, x, y);
	break;
    }
    JotText_SetCaret(v->text, point);
    v->display_caret = 1;
}

static void
selection_inselection(tag)
{
    Selection	*s;
    JotSpan	*sp;
    JotView	*view;
    wire_Wire	wire;
    int		rank, canvas, pos, is_in = 0;
    fixed	x, y;

    ps_inselection(&canvas, &rank, &x, &y);
    wire = wire_Current();
    view = JotView_View(wire, canvas);
    s = get_selection(wire, rank);
    pos = locate_mouse(view, x, y);
    sp = s->span;
    is_in = (pos >= JotSpan_QuickP(sp) &&
	     pos < JotSpan_QuickP(sp) + JotSpan_QuickL(sp));
    ps_return_boolean(canvas, is_in);
}

static void
selection_querystart(tag)
{
    JotView *v;
    fixed   x, y;
    int	    cv;

    ps_selection_querystart(&cv, &x, &y);
    v = JotView_View(wire_Current(), cv);
    if ((*v->c_sel_start)(v, locate_mouse(v, x, y)))
	ps_return_boolean(cv, TRUE);
    else
	ps_return_boolean(cv, FALSE);
}

static void
update_caret(v)
JotView	*v;
{
    register struct lineinfo	*li, *end;
    struct view_coord		*old, *new;

    ps_setpixel(v->xor_pixel);
    color_invalidate(v->wire);
    if (v->caret.where)
	ps_caretat(v->caret.p.x, v->caret.p.y);
    v->caret = v->new_caret;
    if (v->caret.where)
	ps_caretat(v->caret.p.x, v->caret.p.y);
    bzero((char *) &v->new_caret, sizeof (v->new_caret));
}

static void
default_middle(li, x, y, w)
struct lineinfo	*li;
register fixed	x, y, w;
{
    ps_rectpath(x, y - fixedi(li->linedescent),
		w, fixedi(li->lineascent + li->linedescent));
}

static void
underscore_middle(li, x, y, w)
struct lineinfo	*li;
register fixed	x, y, w;
{
    ps_fmoveto(x, y);
    ps_flineto(x + w, y);
}

static void
strikethru_middle(li, x, y, w)
struct lineinfo	*li;
register fixed	x, y, w;
{
    y = y - fixedi(li->linedescent) +
	    fixedi(li->lineascent + li->linedescent) / 2;
    ps_fmoveto(x, y);
    ps_flineto(x + w, y);
}

static void
highlight_fill(v)
JotView	*v;
{
    ps_setpixel(v->xor_pixel);
    color_invalidate(v->wire);
    ps_sel_fill();
}

static void
highlight_stroke(v)
JotView	*v;
{
    ps_setpixel(v->xor_pixel);
    color_invalidate(v->wire);
    ps_sel_stroke();
}

static struct highlighting {
    void    (*proc)();
    void    (*commit)();
} highlight_ops[NSTYLES] = {
    default_middle, highlight_fill,
    underscore_middle, highlight_stroke,
    strikethru_middle, highlight_stroke,
};

static
highlight_region(v, start, end, style)
struct textview	*v;
register struct view_coord  *start, *end;
{
    if (start->where == 0)
	return;
    assert(start->where->fs.y >= end->where->fs.y);
    if (start->where->fs.y == end->where->fs.y) {
	if (start->p.x == end->p.x)
	    return;
	(*highlight_ops[style].proc)(start->where, start->p.x,
				     start->where->fs.y,
				     end->p.x - start->p.x);
    } else {
	register struct lineinfo    *li = start->where;

	/* first line */
	(*highlight_ops[style].proc) (li, start->p.x,
				      start->where->fs.y,
				      li->cx1 - start->p.x);

	/* the middle lines */
	for (li = li + 1; li->fs.y > end->where->fs.y; li += 1)
	    (*highlight_ops[style].proc)(li, li->cx0, li->fs.y,
					 li->cx1 - li->cx0);

	/* the last line */
	(*highlight_ops[style].proc)(li, li->cx0, li->fs.y,
				     end->p.x - li->cx0);
    }
}

static void
update_highlight(v, rank)
JotView	*v;
int	rank;
{
    register struct lineinfo	*li;
    struct view_coord		begin, end;
    struct view_region		*new, *old;
    int				style;

    new = &v->new_highlights[rank];
    old = &v->highlights[rank];
    style = new->style;
    if (new->begin.where == 0 || old->begin.where == 0 ||
	new->end.pos < old->begin.pos || old->end.pos < new->begin.pos) {
	highlight_region(v, &old->begin, &old->end, old->style);
	(*highlight_ops[old->style].commit)(v);
	highlight_region(v, &new->begin, &new->end, new->style);
	(*highlight_ops[new->style].commit)(v);
    } else {
	if (old->begin.p.y > new->begin.p.y) {
	    begin = old->begin;
	    end = new->begin;
	} else {
	    begin = new->begin;
	    end = old->begin;
	}
	highlight_region(v, &begin, &end, style);

	if (old->end.p.y > new->end.p.y) {
	    begin = old->end;
	    end = new->end;
	} else {
	    begin = new->end;
	    end = old->end;
	}
	highlight_region(v, &begin, &end, style);
	(*highlight_ops[style].commit)(v);
    }
    *old = *new;
}

static void
update_highlights(v)
register JotView    *v;
{
    register struct lineinfo	*li, *end;
    register int		i;

    for (i = 0; i < Jot_N_SELECTIONS; i++)
	update_highlight(v, i);
    bzero((char *) v->new_highlights, sizeof (v->new_highlights));
}

static
null_proc()
{
}

static
scan_handleeol(fs, fi, li, pos, ntabs)
struct formatter_state	*fs;
struct formatter_info	*fi;
struct lineinfo		*li;
int			pos;
{
    return pos;
}

static struct formatter_ops scan_ops = {
    null_proc,
    scan_handleeol
};

/* Calculate the selection.  This means find the begin and end points of each
   visible selection, and then figure out how to highlight it, given what
   is currently highlighted (if anything).  If we're lucky, this view isn't
   even part of the selection! */

void
JotView_CalculateSelection(v)
JotView	*v;
{
    register struct lineinfo	*li, *end;
    JotSpan			*span;
    Selection			*s;
    struct view_coord		*points[1 + Jot_N_SELECTIONS * 2];
    int				npoints = 0;
    int				top, bottom, rank, point;

    if (v->vlines == 0)
	return;
    top = JotSpan_QuickP(v->top);
    bottom = v->bottom;

    v->new_caret.pos = JotText_Caret(v->text);
    if (v->display_caret && !v->readonly)
	points[npoints++] = &v->new_caret;

    for (li = v->newinfo, end = &v->newinfo[v->vlines]; li <= end; li++)
	li->hasselection = li->hascaret = 0;

    for (rank = 0; rank < Jot_N_SELECTIONS; rank++) {
	struct view_region  *r;
	int		    pos0, pos1;

	s = get_selection(v->wire, rank);
	if (s == 0 || s->view->text != v->text)
	    continue;
	r = &v->new_highlights[rank];
	r->style = s->style;

	span = s->span;
	pos0 = JotSpan_QuickP(span);
	pos1 = pos0 + JotSpan_QuickL(span);
	r->begin.pos = pos0;
	r->end.pos = pos1;
	if (pos1 <= top)
	    continue;
	if (pos0 > bottom)
	    continue;
	if (pos0 < top) {
	    r->begin.where = v->newinfo;
	    r->begin.p.x = v->newinfo[0].cx0;
	    r->begin.p.y = v->newinfo[0].fs.y;
	    r->begin.pos = top;
	}
	if (pos1 > bottom) {
	    struct lineinfo *li;

	    li = &v->newinfo[v->vlines - 1];
	    r->end.where = li;
	    r->end.p.x = li->cx1;
	    r->end.p.y = li->fs.y;
	    r->end.pos = bottom;
	}
	if (r->begin.where == 0)
	    points[npoints++] = &r->begin;
	if (r->end.where == 0)
	    points[npoints++] = &r->end;
    }

    /* now find the lines which contain those points, and
       call scan_and_apply */
    for (point = 0; point < npoints; point++) {
	register int	    pos, i;
	struct view_coord   *p;

	p = points[point];
	pos = p->pos;
	for (li = v->newinfo, i = v->vlines; --i >= 0; li++) {
	    if (pos < JotSpan_QuickP(li->text) || pos > bottom)
		break;
	    if (JotSpan_QuickP(li->text) <= pos &&
		JotSpan_QuickP(li->text) + li->usedlength >= pos) {
		struct formatter_info	fi;

		calculate_formatter_info(v, li, &fi, JotSpan_QuickP(li->text));
		p->where = li;
		p->p.x = li->cx1;
		p->p.y = li->fs.y;
		_scan_and_apply(li, &fi, &scan_ops, FIXED_HUGE, points[point]);
	    }
	}
    }

    for (rank = 0; rank < Jot_N_SELECTIONS; rank++) {
	if ((li = v->new_highlights[rank].begin.where) == 0)
	    continue;
	end = v->new_highlights[rank].end.where;
	for (; li <= end; li++)
	    li->hasselection = 1;
    }
    if (v->new_caret.where != 0)
	v->new_caret.where->hascaret = 1;
}

JotView_DrawSelection(v)
JotView	*v;
{
    update_caret(v);
    update_highlights(v);
}

void
Selection_ViewDamaged(v)
JotView	*v;
{
    int	i;

    v->caret.where = 0;
    for (i = 0; i < Jot_N_SELECTIONS; i++)
	v->highlights[i].begin.where = 0;
}

void
JotView_EraseHighlights(v)
JotView	*v;
{
    update_highlights(v);
}

void
JotView_EraseCaret(v)
JotView	*v;
{
    update_caret(v);
}

void
JotSelection_BytesInserted(t, pos, n)
JotText	*t;
int	*pos, n;
{
    JotSpan *sp;

    if ((sp = JotSelection_Span(t, Jot_PRIMARY)) != 0 &&
	JotSpan_Text(sp) == t &&
	(*pos >= JotSpan_Position(sp) && *pos <= JotSpan_Position(sp) + JotSpan_Length(sp)) &&
	(JotSelection_PendingDelete(t, Jot_PRIMARY) == TRUE)) {
	JotSpan_DeleteContents(sp);
	JotSelection_Clear(t, Jot_PRIMARY);
	*pos = JotSpan_Position(sp);
    }
}

void
JotSelection_LinesMoved(v, new, old, span)
JotView		*v;
struct lineinfo	*new, *old;
int		span;
{
    struct view_region	*r;
    struct lineinfo	*n, *o;
    int			i;

    for (i = 0; i < Jot_N_SELECTIONS; i++) {
	if ((r = &v->highlights[i])->begin.where == 0)
	    continue;

	n = new - span;
	for (o = old - span; o < old; o++)
	    if (o->hasselection)
		break;
	if (o == old) {
	    o = old - span;
	    if ((o->fs.y < r->end.p.y && n->fs.y >= r->begin.p.y) ||
		(o->fs.y > r->begin.p.y && new[-1].fs.y <= r->end.p.y))
		r->begin.where = 0;
	    continue;
	} else {
	    /* if we're scrolling half a selection, take the thing down */
	    if (o > v->lineinfo && o[-1].hasselection && o[-1].text->modified) {
		JotView_EraseHighlights(v);
		return;
	    }
	}

	o = old - span;

	/* check for beginning of selection */
	for (o = old - span; n < new && o < r->begin.where; n++, o++)
	    ;
	if (o > r->begin.where)
	    r->begin.p.x = o->cx0;	/* x is same, y is different */
	r->begin.p.y = n->fs.y;
	r->begin.where = n;

	/* now check the end */
	for (; n < new && o < r->end.where; n++, o++)
	    ;
	if (o == old) {
	    o -= 1;	    /* = old - 1 */
	    n -= 1;
	}
	if (o < r->end.where)
	    r->end.p.x = o->cx1;	/* x is same, y is different */
	r->end.p.y = n->fs.y;
	r->end.where = n;
    }
    update_caret(v);
}

boolean
JotSelection_SetLevel(view, rank, level)
JotView	*view;
int	rank, level;
{
    Selection	*s;

    s = get_selection(view->wire, rank);
    if (s == 0 || level < Jot_CHARACTER || level > Jot_BUFFER ||
	s->view->text != view->text)
	return_error(FALSE, Jot_ERANGECHECK);
    s->level = level;
    selection_expand(s, view);

    return TRUE;
}

boolean
JotSelection_Clear(text, rank)
JotText	*text;
int	rank;
{
    Selection	*s;

    if (text->views == 0)
	return_error(FALSE, Jot_ESELECTION);
    s = get_selection(text->views->wire, rank);
    if (s == 0 || s->view->text != text)
	return_error(FALSE, Jot_ERANGECHECK);
    if (!wire_SetCurrent(s->view->wire))
	return_error(FALSE, wire_Errno);    /* REMIND: pretty bogus, eh? */
    ps_clear_selection(rank);

    return TRUE;
}

JotSpan *
JotSelection_Span(text, rank)
JotText	*text;
int	rank;
{
    Selection	*s;

    if (text->views == 0)
	return_error((JotSpan *) 0, Jot_ESELECTION);
    s = get_selection(text->views->wire, rank);
    if (s == 0)
	return_error((JotSpan *) 0, Jot_ESELECTION);
    return s->span;
}

boolean
JotSelection_Set(span, rank, pending)
JotSpan	*span;
int	rank, pending;
{
    Selection	*s;
    JotText	*text;
    JotView	*view;
    wire_Wire	wire;

    if (rank != Jot_PRIMARY)
	return_error(FALSE, Jot_ERANGECHECK);
    if ((text = JotSpan_Text(span)) == 0)
	return_error(FALSE, Jot_ETEXT);

    view = text->views;
    s = get_selection_ptr(view->wire, rank);
    s->level = Jot_CHARACTER;
    s->view = view;
    s->rank = rank;
    s->pd = pending;
    s->style = STYLE_DEFAULT;	    /* REMIND: this needs work */
    s->inprogress = 0;
    if (s->span == 0)
	s->span = JotSpan_NewI(text, 0, 0);
    else if (JotSpan_Text(s->span) != text)
	JotSpan_SetText(s->span, text, 0, 0);
    wire = wire_Current();
	wire_SetCurrent(view->wire);
	set_selection(s, JotSpan_QuickP(span), t_selectat);
	set_selection(s, JotSpan_QuickP(span) + JotSpan_QuickL(span),
		      t_adjustdown);
	ps_own_selection(JotText_Holder(text, view->wire), rank);
    wire_SetCurrent(wire);
}

/* Returns the contents of a selection in a malloc'd string.  It's
   up to the user to free this up. */
char *
JotSelection_Contents(text, rank)
JotText	*text;
{
    static int	    tag = -1;
    char	    *cp, *contents;
    int		    nbytes = 0;
    PSFILE	    *psin;    
    JotSpan	    *s;

    if ((s = JotSelection_Span(text, rank)) != 0) {
	contents = jot_alloc(JotSpan_Length(s) + 1);
	JotSpan_Contents(s, contents);
	contents[JotSpan_Length(s)] = '\0';
	return contents;
    }

    if (tag == -1)
	tag = wire_AllocateTags(1);

    ps_get_selection(rank, &nbytes, tag);
    if (nbytes == -1)
	return NULL;
    cp = contents = jot_alloc(nbytes + 1);
    psin = wire_PSinput(wire_Current());
    while (--nbytes >= 0) {
	int c;

	c = psio_getc(psin);
	if (cp != 0)
	    *cp++ = c;
    }
    if (cp != 0)
	*cp++ = '\0';

    return contents;
}

boolean
JotSelection_PendingDelete(text, rank)
JotText	*text;
int	rank;
{
    Selection	*s;

    if (text->views == 0)
	return FALSE;
    s = get_selection(text->views->wire, rank);

    return (s->pd == 1) ? TRUE : FALSE;
}
