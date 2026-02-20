/*
 *	@(#)formatter.c 1.37 91/02/20 Copyright 1990-91 Sun Microsystems
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
#include "styles.h"
#include "selection.h"
#include "view_private.h"
#include "view.h"
#include "font.h"
#include "color.h"
#include "psinter.h"
#include "span.h"

/* The central part of the formatter is the routine scan_and_apply.  It
   scans a line of the text, applies formatting directives, and calls
   routines at key points in the line: when a substring is fully
   assembled; when the end of the line is reached; and to deal with
   eraseing rectangles.  Which routines get called is determined by a set
   of procedure pointers passed in to scan_and_apply. */

static int null_proc();
static int measure_handleeol();
static int output_handlestring();
static int null_handleeol();
static int trytop();

static struct formatter_ops output_ops = {
    output_handlestring,
    null_handleeol
};

static struct formatter_ops null_ops = {
    null_proc,
    null_handleeol
};

static struct formatter_ops locate_ops = {
    null_proc,
    null_handleeol
};

static struct formatter_ops measure_ops = {
    null_proc,
    measure_handleeol
};

extern boolean	JotView_PartialUpdate(/* view */);

_scan_and_apply(li, fi, fo, xlimit, point)
struct lineinfo			*li;
struct formatter_info		*fi;
register struct formatter_ops   *fo;
fixed				xlimit;
struct view_coord		*point;
{
    register Bytestring	    *b = li->text->owner->data;
    register JotView	    *v = li->fs.v;
    register fixed	    *widths;
    register int	    pos = JotSpan_QuickP(li->text);
    register int	    bufptr = 0;
    register fixed	    newx;
    fixed		    spshim;
    char		    buf[512];
    int			    tabcount = 0;
    int			    plimit = pos + li->linelength;
    int			    pos_of_interest = -1;
    int			    tabwidth;
    boolean		    stylesincelastbreak;
    struct formatter_info   savefi;

    li->fs.x = fixedi(v->bbox.xl + fi->parameters[F_LEFTMARGIN]) + li->fs.xoffset;
    if (fo == &output_ops)
	li->cx0 = li->fs.x;
    li->fs.nsp = 0;
    if (plimit > b->size)
	plimit = b->size;
    li->modx = fixedi(2);
    li->fs.x0 = li->fs.x;
    widths = fi->font->width;
    if (li->fs.ntabs > 0)
	spshim = 0;
    else
	spshim = li->fs.spshim;
    newx = li->fs.x;

    if (point != 0)
	pos_of_interest = point->pos;

    tabwidth = floorfr(widths[' '] * 8);
    for (; pos < plimit; pos += 1, li->fs.x = newx) {
	register int	c = Bytestring_CharAt(b, pos);

	if (pos == li->modpos) {
	    bufptr = 0;
	    li->modx = li->fs.x0 = li->fs.x;
	}
	if (pos == fi->next_style_pos) {
	    if (pos > li->modpos)
		(*fo->handlestring)(&li->fs, fi, buf, bufptr, spshim);
	    li->fs.x0 = li->fs.x;
	    bufptr = 0;
	    if (!stylesincelastbreak) {
		li->fs.ascentatlastbreak = li->lineascent;
		li->fs.descentatlastbreak = li->linedescent;
		li->fs.fiatlastbreak = *fi;
		stylesincelastbreak = TRUE;
	    }
	    savefi = *fi;
	    calculate_formatter_info(li->fs.v, li, fi, pos);
	    widths = fi->font->width;
	}
	if (pos == pos_of_interest) {
	    point->where = li;
	    point->p.x = li->fs.x;
	    point->p.y = li->fs.y + fixedi(fi->parameters[F_BASELINE]);
	}
	if (c <= ' ') {
	    if (c == ' ' || c == '\n') {
		li->fs.posatlastbreak = pos;
		li->fs.xatlastbreak = li->fs.x;
		stylesincelastbreak = FALSE;
		if (c == '\n') {
		    pos++;
		    break;
		}
		li->fs.nsp++;
		buf[bufptr++] = ' ';
		newx = li->fs.x + widths[' '] + spshim;
		goto xcheck;
	    } else if (c == '\t') {
		stylesincelastbreak = FALSE;
		newx = li->fs.x +
		    fixedi(tabwidth - (floorfr(li->fs.x) - v->bbox.xl) % tabwidth);
		li->fs.posatlastbreak = -1;
		if (pos > li->modpos)
		    (*fo->handlestring)(&li->fs, fi, buf, bufptr, spshim);
		tabcount += 1;
		if (tabcount == li->fs.ntabs)
		    spshim = li->fs.spshim;
		li->fs.nsp = 0;
		li->fs.x0 = newx;
		bufptr = 0;
		goto xcheck;
	    } else {
		buf[bufptr++] = '^';
		newx += widths['^'];
		c = (c < ' ') ? c + '@' : '?';
	    }
	}
	newx += widths[c];
	if (widths[c] != 0)
	    buf[bufptr++] = c;
xcheck:	if (newx > xlimit) {
	    if (pos == savefi.next_style_pos)
		*fi = savefi;
	    if (fo == &locate_ops && (newx + li->fs.x) >> 1 < xlimit && pos + 1 < plimit)
		pos++;
	    break;
	}
    }

    if (pos == b->size || li->fs.posatlastbreak == -1) {
	li->fs.posatlastbreak = pos;
	li->fs.xatlastbreak = li->fs.x;
	stylesincelastbreak = FALSE;
    }

    if (!stylesincelastbreak) {
	li->fs.ascentatlastbreak = li->lineascent;
	li->fs.descentatlastbreak = li->linedescent;
	li->fs.fiatlastbreak = *fi;
    }
    if (pos > li->modpos)
	(*fo->handlestring) (&li->fs, fi, buf, bufptr, li->fs.spshim);
    pos = (*fo->handleeol) (&li->fs, fi, li, pos, tabcount);

    if (fo == &output_ops) {
	li->cx1 = li->fs.x + fixedi(2);
		/* + 1 because fill doesn't fill last pixel, + 2 because
		   printermatched off by one error ... */
	if (li->cx1 > xlimit)
	    li->cx1 = xlimit;
    }
    return pos;
}

static
null_proc()
{
}

static
null_handleeol(fs, fi, li, pos, ntabs)
struct formatter_state	*fs;
struct formatter_info	*fi;
struct lineinfo		*li;
int			pos;
{
    return pos;
}


/* End-of-line handler when measuring & laying out a line.  It's major
   task is trimming trailing spaces & determining how much to add to the
   width of each space character (fs->spshim). */

static
measure_handleeol(fs, fi, li, pos, tabcount)
register struct formatter_state	*fs;
register struct formatter_info	*fi;
register struct lineinfo	*li;
register int			pos;
int				tabcount;
{
    register Bytestring	*b;
    register int	c;

    b = li->text->owner->data;

    JotSpan_QuickSetL(li->text, (pos - JotSpan_QuickP(li->text)) +
		      (pos == Bytestring_Length(b)));
    li->fs.ntabs = tabcount;
    /* When checking out linestyle, use whatever linestyle was in effect
       at the beginning of the line.  Linestyle changes in the middle of
       the line don't make much sense I don't think. */
    if (li->fi.parameters[F_LINESTYLE] < FL_CHARWRAP) {
	register fixed	err;

	err = fixedi(fs->v->bbox.xr - fi->parameters[F_RIGHTMARGIN])
	    - fs->xatlastbreak;
	pos = fs->posatlastbreak;
	li->linelength = pos - JotSpan_QuickP(li->text);

	while (pos > 0 && (c = Bytestring_CharAt(b, pos - 1)) == ' ') {
	    pos--;
	    fs->nsp--;
	    err += fi->font->width[' '];
	}

	switch (li->fi.parameters[F_LINESTYLE]) {
	case FL_JUSTIFIED:
	    if (fs->nsp > 1 && fs->posatlastbreak < b->size
		    && Bytestring_CharAt(b, fs->posatlastbreak) != '\n')
		fs->spshim = err / (short) (fs->nsp - 1);
	    break;

	case FL_LEFTRIGHT:	/* first line of a paragraph is left flushed,
				 * the rest are right flushed */
	    if (JotSpan_QuickP(li->text) <= 0 ||
		Bytestring_CharAt(b, JotSpan_QuickP(li->text) - 1) == '\n')
		break;
	    /* Fall into ... */

	case FL_RIGHTFLUSH:
 	    fs->xoffset = err;
	    break;

	case FL_CENTERED:
	    fs->xoffset = err / 2;
	    break;
	}
	pos = fs->posatlastbreak;
	if (li->modpos >= JotSpan_QuickP(li->text) + li->linelength)
	    li->modx = li->fs.xatlastbreak;
	c = -1;
	while (pos < b->size && (c = Bytestring_CharAt(b, pos)) == ' ')
	    pos++;
    } else {
	li->linelength = pos - JotSpan_QuickP(li->text);
	if (Bytestring_CharAt(b, pos - 1) == '\n')
	    li->linelength -= 1;
	if (li->modpos >= JotSpan_QuickP(li->text) + li->linelength)
	    li->modx = li->fs.x;
	if (fi->parameters[F_LINESTYLE] == FL_CHARCHOP) {
	    pos = fs->posatlastbreak;
	    while (pos < b->size && (c = Bytestring_CharAt(b, pos)) != '\n')
		pos++;
	}
    }
    if (c == '\n')
	pos++;

    li->usedlength = pos - JotSpan_QuickP(li->text);
    if (JotSpan_QuickL(li->text) < li->usedlength)
	JotSpan_QuickSetL(li->text, li->usedlength);
    return pos;
}

/* Output a completely assembled substring of the current line */
static
output_handlestring(fs, fi, buf, n, spshim)
register struct formatter_state	*fs;
register struct formatter_info	*fi;
register char			*buf;
{
    while (1) {
	if (n <= 0)
	    return;
	if (buf[n - 1] != ' ')
	    break;
	n--;
    }
    ps_fmoveto(fs->x0, fs->y + fixedi(fi->parameters[F_BASELINE]));
    font_usefont(fi->font, fs->v->wire);
    color_usecolor(fi->color, fs->v->wire);
    if (spshim == 0)
	ps_showN(buf, n);
    else
	ps_cwidthshow(spshim, buf, n);
}

static
layoutline(li, oli, y, v, fi)
register struct lineinfo    *li;
struct lineinfo		    *oli;
register JotView	    *v;
struct formatter_info	    *fi;
fixed			    y;
{
    struct font	*f;
    int		next;

    if (JotSpan_QuickP(li->text) == fi->next_style_pos)
	calculate_formatter_info(v, li, fi, JotSpan_QuickP(li->text));
    else {
	li->lineascent = fi->parameters[F_BASELINE] + floorfr(fi->font->ascent);
	li->linedescent = -fi->parameters[F_BASELINE] + floorfr(fi->font->descent);
    }

    li->fi = *fi;
    li->fs.v = v;
    li->fs.y = y;
    li->fs.spshim = 0;
    li->fs.ntabs = 1 << 30;	/* more than can fit on one line */
    li->fs.xoffset = 0;
    li->fs.posatlastbreak = -1;
    JotSpan_QuickSetL(li->text, 1 << 30);
    li->linelength = 0x7FFF;
    next = _scan_and_apply(li, fi, &measure_ops,
			   fixedi(li->fs.v->bbox.xr -
				  fi->parameters[F_RIGHTMARGIN]),
			   (struct view_coord *) 0);

    /* NOTE:  If a line is being redrawn and it's not in the same
       place as the last time it was drawn, it can't do the
       just-to-eol optimization. */

    if (li->fs.spshim != 0 ||
	li->fs.spshim != oli->fs.spshim ||
	li->fs.xoffset != 0 ||
	li->fs.xoffset != oli->fs.xoffset) {
	li->modx = fixedi(2);
	li->modpos = -1;
    }

    return next;
}

/* Layout the entire document until we consume POS, and return that
   line number. */

int
JotView_LineFromPosition(v, pos)
register JotView    *v;
register int	    pos;
{
    struct lineinfo	    li;
    static JotSpan	    *span = 0;
    register int	    lines, scanned_pos;
    struct formatter_info   fi;

    if (pos < 0 || pos > JotText_Characters(v->text))
	return_error(-1, Jot_ERANGECHECK);
    if (v->text == 0)
	return_error(-1, Jot_ETEXT);
    if (span == 0) {
	span = JotSpan_NewI(v->text, 0, 0);
	if (span == 0)
	    return -1;	    /* REMIND: This is not a documented error. */
    } else
	JotSpan_SetText(span, v->text, 0, 0);
    lines = 0;
    scanned_pos = 0;
    li.text = span;
    calculate_formatter_info(v, &li, &fi, JotSpan_QuickP(li.text));
    for (;;) {
	if (scanned_pos == pos)
	    break;
	JotSpan_QuickSetP(span, scanned_pos);
	scanned_pos = layoutline(&li, &li, 0, v, &fi);
	if (scanned_pos > pos)
	    break;
	lines += 1;
    }

    return lines;
}

int
JotView_PositionFromLine(v, line)
JotView	*v;
int	line;
{
    if (!JotView_PartialUpdate(v))
	return -1;
    if (line < 0 || line >= v->vlines)
	return_error(-1, Jot_ERANGECHECK);
    return JotSpan_Position(v->validinfo[line].text);
}

boolean
JotView_LineBoundingBox(v, r, line)
register JotView    *v;
JotBoundingBox	    *r;
int		    line;
{
    struct lineinfo	    *li;
    struct formatter_info   fi;

    if (!JotView_PartialUpdate(v))
	return FALSE;
    if (line < 0 || line >= v->vlines)
	return_error(FALSE, Jot_ERANGECHECK);
    li = &v->newinfo[line];
    fi = li->fi;
    _scan_and_apply(li, &fi, &null_ops, FIXED_HUGE,
		    (struct view_coord *) 0);

    r->x = li->fi.parameters[F_LEFTMARGIN] + floorfr(li->fs.xoffset);
    r->y = floorfr(li->fs.y) - li->linedescent;
    r->width = (floorfr(li->fs.x) + 2) - r->x;
    r->height = li->linedescent + li->lineascent;
    
    return TRUE;
}

static
outputline(li, ops)
register struct lineinfo    *li;
struct formatter_ops	    *ops;
{
    struct formatter_info fi;

    fi = li->fi;
    return _scan_and_apply(li, &fi, ops, FIXED_HUGE,
			   (struct view_coord *) 0);
}

static 
update_selection_flags(v)
JotView	*v;
{
    register struct view_region	*r;
    register struct lineinfo	*li, *end;
    register int		i;

    for (i = 0; i < Jot_N_SELECTIONS; i++) {
	if ((r = &v->highlights[i])->begin.where == 0)
	    continue;
	for (li = v->newinfo, end = &v->newinfo[v->vlines - 1];
	     li <= end; li++)
	    if (li->modified && li->hasselection &&
		(JotSpan_QuickP(li->text) < r->begin.pos ||
		 JotSpan_QuickP(li->text) > r->end.pos))
		li->hasselection = 0;
    }
}

static void
erase_dirty_lines(v)
JotView	*v;
{
    register struct lineinfo   *nli, *first, *end;
    fixed		    y;
    int			    something_to_erase = 0;

    for (nli = v->newinfo, end = &v->newinfo[v->vlines]; nli < end; nli++)
	if (nli->modified && nli->hasselection) {
	    JotView_EraseHighlights(v);
	    break;
	}

    for (first = 0, nli = v->newinfo; nli < end; nli++) {
	if (nli->modified) {
	    if (first == 0) {
		first = nli;
		continue;
	    } else if (first->modx == nli->modx)
		continue;
	} else if (first == 0)
	    continue;
	y = nli[-1].fs.y - fixedi(nli[-1].linedescent);
	ps_rectpath(first->modx, y,
		    fixedi(v->width) - first->modx,
		    (first->fs.y + fixedi(first->lineascent)) - y);
	first = nli->modified ? nli : 0;
	something_to_erase = 1;
    }
    if (first != 0) {
	y = nli[-1].fs.y - fixedi(nli[-1].linedescent);
	ps_rectpath(first->modx, y,
		    fixedi(v->width) - first->modx,
		    (first->fs.y + fixedi(first->lineascent)) - y);
	something_to_erase = 1;
    }

    y = end[-1].fs.y - fixedi(end[-1].linedescent);
    if (v->lowest_y < y) {
	ps_rectpath(fixedi(v->bbox.xl), v->lowest_y,
		    fixedi(v->width - v->bbox.xl),
		    y - v->lowest_y);
	something_to_erase = 1;
    }
    v->lowest_y = y;

    if (something_to_erase) {
	color_usecolor(v->bgcolor, v->wire);
	ps_fill();
    }
}

/* Format all the lines of a text visible in a view.  Each view has an
   array of lineinfo structs that describe the visible lines.  A line is
   redraw if the contents of the line has changed or if a change in a
   previous line has caused some ripple-through. */

#define Y_TOP(v)    fixedi((v)->bbox.yt - 1)
#define Y_BOTTOM(v) fixedi(1)

JotView	*current_view = 0;

#define UseCanvas(c)	(((c) != current_view) ? \
			 (current_view = (c), ps_usecanvas(c->viewport)) : 0)

boolean
JotView_Redisplay(v, just_format, full_update)
register JotView    *v;
{
    register struct lineinfo	*lni;
    register struct lineinfo	*nlni;
    register Bytestring		*b = v->text->data;
    register JotSpan		*m;
    int				pos, startpos, endpos, ln, i;
    fixed			y;
    int				update_scrollbar = 0;
    struct formatter_info	fi;
    boolean			fi_accurate;
    int				out_of_y;
    int				mod_line_count = 0;

    if (v->text == 0)
	return_error(FALSE, Jot_ETEXT);
    if (!wire_SetCurrent(v->wire))
	return FALSE;
    /* make sure there is something there */
    if (b->bytes == 0) {
	Bytestring_Insert(b, 0, " ", 1);
	Bytestring_Delete(b, 0, 1);
    }
again:
    ln = 0;
    out_of_y = 0;
    y = Y_TOP(v);
    if (v->constrain)
	JotSpan_QuickSetP(v->top, 0);
    pos = JotSpan_QuickP(v->top);
    startpos = pos;
    fi_accurate = FALSE;
    v->validinfo = v->newinfo;

    /* first we make a pass over the lines in the view to lay them out */
    for (;;) {
	int new_pos;

	/* Entend the line table if the view has grown. */
	if (v->alines <= ln) {
	    register    sz;
	    if (v->alines == 0) {
		v->alines = 10;
		sz = v->alines * sizeof(struct lineinfo);
		v->lineinfo = (struct lineinfo *) jot_alloc(sz);
		v->newinfo = (struct lineinfo *) jot_alloc(sz);
	    } else {
		register    nnl = ln * 3 / 2;
		v->lineinfo = (struct lineinfo *) jot_realloc(v->lineinfo,
					      nnl * sizeof(struct lineinfo));
		v->newinfo = (struct lineinfo *) jot_realloc(v->newinfo,
					      nnl * sizeof(struct lineinfo));
		sz = (nnl - v->alines) * sizeof(struct lineinfo);
		v->alines = nnl;
	    }
	    if (v->lineinfo == 0 || v->newinfo == 0)
		return FALSE;
	    bzero(&v->lineinfo[ln], sz);
	    bzero(&v->newinfo[ln], sz);
	}

	lni = &v->lineinfo[ln];
	nlni = &v->newinfo[ln];
	if ((m = lni->text) == 0) {
	    m = lni->text = JotSpan_NewI(v->text, 0, 0);
	    if (m == 0)
		return FALSE;
	    JotSpan_QuickSetP(m, -1);
	}
	if (nlni->text == 0) {
	    nlni->text = JotSpan_NewI(v->text, 0, 0);
	    if (nlni->text == 0)
		return FALSE;
	    JotSpan_QuickSetP(nlni->text, -1);
	}

	if (m->modified || JotSpan_QuickP(m) != pos) {
	    nlni->modpos = -1;
	    if (m->modified && JotSpan_QuickP(m) == pos) {
		if (lni->linelength < m->mod_offset)
		    nlni->modpos = pos + lni->linelength;
		else
		    nlni->modpos = pos + m->mod_offset;
	    }
	    JotSpan_QuickSetP(nlni->text, pos);

	    if (!fi_accurate) {
		calculate_formatter_info(v, nlni, &fi, pos);
		fi_accurate = TRUE;
	    }
	    new_pos = layoutline(nlni, lni, y, v, &fi);
	    if (y - fixedi(nlni->lineascent + nlni->linedescent) < Y_BOTTOM(v)) {
		out_of_y = 1;
		break;
	    }
	    nlni->cx0 = lni->cx0;
	    nlni->cx1 = lni->cx1;
	    nlni->modified = 1;
	    nlni->hascaret = lni->hascaret;
	    nlni->hasselection = lni->hasselection;
	} else {
	    /* Don't have to redraw this line, but also, let's make sure
	       it still fits. */

	    fi_accurate = FALSE;
	    if (y - fixedi(lni->lineascent + lni->linedescent) < Y_BOTTOM(v)) {
		out_of_y = 1;
		break;
	    }
	    m = nlni->text;
	    *nlni = *lni;
	    nlni->text = m;

	    JotSpan_ClearModified(nlni->text);
	    JotSpan_QuickSet(nlni->text, JotSpan_QuickP(lni->text),
			     JotSpan_QuickL(lni->text));
	    new_pos = JotSpan_QuickP(lni->text) + lni->usedlength;
	}
	ln++;
	assert(new_pos >= pos);

	y -= fixedi(nlni->lineascent);
	if (!nlni->modified && nlni->fs.y != y)
	    nlni->modified = 1;
	nlni->fs.y = y;
	y -= fixedi(nlni->linedescent);
	if (nlni->fs.y != lni->fs.y) {
	    nlni->modpos = -1;		/* can't do this optimization */
	    nlni->modx = fixedi(2);
	}

	if (nlni->modified)
	    mod_line_count += 1;
	if ((new_pos == b->size) &&
	    (Bytestring_CharAt(b, new_pos - 1) != '\n')) {
	    pos = new_pos;
	    break;
	} else if (new_pos == pos)
	    break;
	pos = new_pos;
    }

    if (v->alines == 0)
	return TRUE;
    v->vlines = ln;	/* vlines reflects lineinfo when a full update
			   is done, and reflects newinfo when only a
			   partial (logical) update is completed */

    nlni = &v->newinfo[ln - 1];

    if (out_of_y && pos > 0 || pos > b->size)
	pos -= 1;   /* pos is now the last character we displayed, not
		       the first character NOT displayed */
    v->bottom = endpos = pos;

    /* Now delete any lines which are no longer being used, which
       happens when we change the size of the window, or when we
       run out of text to display. */

    if (ln < v->alines && v->newinfo[ln].text != 0) {
	struct lineinfo	*lp = &v->newinfo[ln];
	int		i = ln;

	while (i++ < v->alines && lp->text != 0) {
	    JotSpan_Free(lp->text);
	    lp->text = 0;
	    lp += 1;
	}
    }

    /* Now make sure we hit dot (if we are forcing it to be visible). */
    if (v->frame_pos >= 0 &&
	(startpos > v->frame_pos || endpos < v->frame_pos)) {

	scroll_automatically(v, v->frame_pos);
	if (startpos != JotSpan_QuickP(v->top))
	    goto again;
	/* otherwise, don't bother, we'll only end up here again */
    }

    if (just_format)
	return TRUE;

    v->frame_pos = -1;

    current_view = 0;
    current_color = 0;
    current_font = 0;
    UseCanvas(v);

    /* Erase the selection if we have made any textual changes to the
       buffer.  This way scrolling is still smart about not erasing
       the selection, but other commands that modified the buffer will
       erase it.  This is not optimal but it is much better than the way
       things were (not erasing when it should and leaving turds on the
       screen). */
    if (v->text->modified != v->lasttextmodified) {
	JotView_EraseHighlights(v);
	v->lasttextmodified = v->text->modified;
    }

    /* Next, run through all the lines looking for any that can be copied
       from elsewhere.  First setup lni to be the last valid line from the
       previous redisplay. */

    if (mod_line_count > 0) {
	int i = v->vlines;

	lni = &v->lineinfo[ln];
	while (i < v->alines && lni->text != 0) {
	    i++;
	    lni++;
	}
	JotView_EraseCaret(v);
	if (tryrop(v->lineinfo, v->newinfo, lni - 1, nlni)) {
	    update_scrollbar = 1;
	    update_selection_flags(v);
	}
    }

    if (v->scrollable) {
	if ((update_scrollbar ||
	     (startpos != v->scrollbar.top) ||
	     (abs(endpos - v->scrollbar.bottom) > 20) ||
	     (abs(JotText_Characters(v->text) - v->scrollbar.size) > 20))) {
	    if (!v->sbar_abs) {
		ps_setscrollbar(v->viewport, startpos, endpos - startpos,
				JotText_Characters(v->text));
		if (v->sbarwarp)
		    ps_warpsbar(v->viewport);
		v->scrollbar.top = startpos;
		v->scrollbar.bottom = endpos;
		v->scrollbar.size = JotText_Characters(v->text);
	    }
	}
	v->sbarwarp = FALSE;
	v->sbar_abs = FALSE;
    }

    /* free unused lineinfo lines */
    lni = &v->lineinfo[v->vlines];
    while (ln++ < v->alines && lni->text != 0) {
	JotSpan_Free(lni->text);
	lni->text = 0;
	lni += 1;
    }

    /* Now run through all the lines that need clearing, and do
       them all at once.  Since they aren't all contiguous, make a
       path of a bunch of rectangles, and erase that path at the
       end.  If we are doing a full update, the screen has already
       been erased by PaintCanvas. */

    if (!full_update)
	erase_dirty_lines(v);

    /* finally, run through all the lines and redraw those that need it */
    lni = v->lineinfo;
    nlni = v->newinfo;
    for (ln = v->vlines; --ln >= 0; lni++, nlni++) {
	if (lni->text != 0)
	    JotSpan_ClearModified(lni->text);
	if (nlni->text != 0) {
	    if (nlni->modified) {
		JotSpan_ClearModified(nlni->text);
		outputline(nlni, &output_ops);
		nlni->modpos = -1;
		nlni->modified = 0;
	    }
	}
    }

    JotView_CalculateSelection(v);
    JotView_DrawSelection(v);

    lni = v->lineinfo;
    v->lineinfo = v->newinfo;
    v->newinfo = lni;

    JotView_Unmodify(v);

    return TRUE;
}

void
JotView_HandleDamage(v, y1, y2)
JotView	*v;
{
    register struct lineinfo	*lni;
    register int		ln;

    current_view = 0;
    current_color = 0;
    current_font = 0;
    UseCanvas(v);

    lni = v->lineinfo;
    for (ln = 0; ln < v->vlines; ln++, lni++)
	if (floorfr(lni->fs.y) - lni->linedescent <= y2)
	    break;
    while (ln < v->vlines && floorfr(lni->fs.y) + lni->lineascent >= y1) {
	outputline(lni, &output_ops);
	lni += 1;
	ln += 1;
    }
    bcopy((char *) v->highlights, (char *) v->new_highlights,
	  sizeof (v->new_highlights));
    v->new_caret = v->caret;
    Selection_ViewDamaged(v);
    JotView_DrawSelection(v);
}

/* Scroll POS to the right place as defined by frame_how. */

scroll_automatically(v, pos)
JotView	*v;
int	pos;
{
    int	ytarget, forward;

    if (v->frame_how == 0)
	ytarget = v->bbox.yt / 2;
    else {
	if (pos < JotSpan_QuickP(v->top)) {	    /* going backwards */
	    if (v->frame_how < 0)
		ytarget = v->bbox.yb;
	    else
		ytarget = v->bbox.yt;
	    ytarget -= v->frame_how;
	} else {
	    if (v->frame_how < 0)
		ytarget = v->bbox.yt;
	    else
		ytarget = v->bbox.yb;
	    ytarget += v->frame_how;
	}
    }
    JotView_ScrollAbsolute(v, pos, ytarget);
}
	
boolean
JotView_PartialUpdate(v)
JotView	*v;
{
    if (v->modified)
	return JotView_Redisplay(v, TRUE, FALSE);
    return TRUE;
}

boolean
JotView_Update(v)
JotView	*v;
{
    return JotView_Redisplay(v, FALSE, FALSE);
}

static int
tryrop(old, new, olimit, nlimit)
register struct lineinfo    *old, *new, *olimit, *nlimit;
{
    register JotView	*v = new->fs.v;
    int			success = 0;

    while (1) {
	register int	span = 0;

	while (1) {		/* skip lines that are already in the right
				 * place */
	    if (new > nlimit || old > olimit)
		return success;
	    if (new->modified)
		break;
	    new++;
	    old++;
	}

	/* Now get new and old pointing to same buffer position. */
	while (1) {
	    if (new > nlimit)
		return success;
	    if (JotSpan_QuickP(new->text) >= JotSpan_QuickP(old->text))
		break;
	    new++;
	}

	while (1) {
	    if (old > olimit)
		return success;
	    if (JotSpan_QuickP(old->text) >= JotSpan_QuickP(new->text))
		break;
	    old++;
	}
	while (new <= nlimit && old <= olimit &&
	       JotSpan_QuickP(new->text) == JotSpan_QuickP(old->text) &&
		new->modified &&
		!old->text->modified && new->linelength == old->linelength &&
		new->fs.y != old->fs.y) {
	    span++;
	    new++;
	    old++;
	    if (new > nlimit || old > olimit)
		break;
	}
	if (span > 0) {		/* we've found a block that can be moved */
	    register fixed ymin;

	    success = 1;

	    if (new[-1].fs.y > old[-1].fs.y)
		(void) tryrop(old, new, olimit, nlimit);

	    JotSelection_LinesMoved(v, new, old, span);

	    ymin = old[-1].fs.y - fixedi(old[-1].linedescent);
	    ps_moverect(ymin,
		   old[-span].fs.y - ymin + fixedi(old[-span].lineascent),
		   new[-1].fs.y - old[-1].fs.y);

	    while (span > 0) {
		new[-span].modified = 0;
		new[-span].cx0 = old[-span].cx0;
		new[-span].cx1 = old[-span].cx1;
		span--;
	    }

	    if (new[-1].fs.y < old[-1].fs.y)
		(void) tryrop(old, new, olimit, nlimit);
	} else
	    new++, old++;
    }
    /* NOTREACHED */
}

/* Remove marks in view so that line gets completely redraw.
   This removes the marks as opposed to just setting the mark
   modified because if the mark is still there then tryrop
   may try something (which is wrong if damage has occurred,
   since /fix clears the damaged region automatically), and
   the end of the loop which clears any extra lines may clear
   what's just been drawn if the window is smaller than it used
   to be (trust me ...) */

void
JotView_DamageView(v)
register JotView    *v;
{
    register int    ln;

    for (ln = 0; ln < v->alines; ln++) {
	register struct lineinfo    *li = &v->lineinfo[ln];

	if (li->text != 0) {
	    JotSpan_Free(li->text);
	    li->text = 0;
	}
    }
    v->vlines = 0;
    Selection_ViewDamaged(v);
    JotView_Modify(v);
}

print_info(v)
JotView	*v;
{
    struct lineinfo *li, *ni;
    int		    i;
    JotSpan	    dummy_mark;

    dummy_mark.pos = -1;
    dummy_mark.length = -1;

    for (i = 0, li = v->lineinfo, ni = v->newinfo; i < v->alines; i++, li++, ni++) {
	JotSpan	*mli, *mni;

	mli = li->text;
	mni = ni->text;
	if (mli == 0 || mni == 0) {
	    printf("Rest are empty\n");
	    break;
	}
	if (mli == 0)
	    mli = &dummy_mark;
	if (mni == 0)
	    mni = &dummy_mark;
	printf("(%d:[%s%s,%s%s]) pos(%d,%d), span(%d,%d), y(%d,%d), mod(%c, %c)\n",
	       i,
	       li->hascaret ? "^" : "", li->hasselection ? "|" : "",
	       ni->hascaret ? "^" : "", ni->hasselection ? "|" : "",
	       JotSpan_QuickP(mli), JotSpan_QuickP(mni),
	       JotSpan_QuickL(mli), JotSpan_QuickL(mni),
	       li->fs.y / 65536, ni->fs.y / 65536,
	       mli->modified ? '*' : '-',
	       mni->modified ? '*' : '-');
    }
}

locate_mouse(v, x, y)		/* Locate a mouse hit in a view */
register JotView    *v;
fixed		    x, y;
{
    register struct lineinfo	*ln = v->lineinfo;
    struct formatter_info	fi;
    register int		i;

    if (ln == 0)
	return 0;
    for (i = 0; i < v->vlines; i++, ln++) {
	if (ln->fs.y - fixedi(ln->linedescent) < y) {
	    fi = ln->fi;
	    return _scan_and_apply(ln, &fi, &locate_ops, x,
				   (struct view_coord *) 0);
	}
    }
    if (v->vlines > 0) {
	ln = &v->lineinfo[v->vlines - 1];
	return JotSpan_QuickP(ln->text) + ln->usedlength;
    }
    return 0;
}

static void
settoppos(v, pos)
register JotView    *v;
{
    if (pos != JotSpan_QuickP(v->top)) {
	JotSpan_QuickSetP(v->top, pos);
	JotView_Modify(v);
    }
}

/* Try to scroll the text so that the line containing POS is at
   coordinate y in the canvas.  That is, the baseline of that line
   is at ytarget. */

static void
scroll_to(v, pos, ytarget)
register JotView    *v;
register int	    pos;
fixed		    ytarget;
{
    struct formatter_info   fi;
    register Bytestring	    *b = v->text->data;
    int			    lastpos;
    fixed		    targetheight;

    if (pos < 0)
	pos = 0;
    if (pos > b->size)
	pos = b->size;
    lastpos = pos;

    fi = v->defaultinfo;	/* REMIND: this is not quite right */
    targetheight = Y_TOP(v) - (ytarget - fi.font->descent);
    if (targetheight < 0)
	return;

    while (1) {
	if (pos > 0)
	    do
		pos--;
	    while (pos > 0 && Bytestring_CharAt(b, pos - 1) != '\n');
	{
	    struct scrollinfo {
		int         pos;
		fixed	    height;
	    };
	    static struct scrollinfo	*info;
	    static int			infosize;
	    static JotSpan		text_span;
	    static struct lineinfo	lni;
	    register int		ln = 0;
	    register int		fpos = pos;
	    fixed			height = 0;

	    calculate_formatter_info(v, &lni, &fi, fpos);
	    while (fpos < lastpos) {
		int new_pos;

		if (infosize <= ln) {	/* Entend the line table since the
					 * view has grown */
		    if (infosize == 0) {
			infosize = 10;
			info = (struct scrollinfo *) malloc(infosize * sizeof(struct scrollinfo));
		    } else {
			infosize = ln * 3 / 2;
			info = (struct scrollinfo *) realloc(info,
				       infosize * sizeof(struct scrollinfo));
		    }
		}
		if (lni.text == 0)
		    lni.text = &text_span;
		text_span.owner = v->text;	/* THIS IS IMPORTANT! */
		JotSpan_QuickSetP(lni.text, fpos);
		info[ln].pos = fpos;
		info[ln].height = height;
		new_pos = layoutline(&lni, &lni, 0, v, &fi);
		if (new_pos == fpos)
		    break;
		fpos = new_pos;
		height += fixedi(lni.lineascent + lni.linedescent);
		ln++;
	    }
	    if (height >= targetheight) {
		while (ln > 0) {
		    ln--;
		    if ((height - info[ln].height) >= targetheight)
			break;
		    fpos = info[ln].pos;
		}
		settoppos(v, fpos);
		return;
	    }
	    targetheight -= height;
	    lastpos = pos;
	}
	if (pos <= 0) {
	    settoppos(v, 0);
	    return;
	}
    }
}

boolean
JotView_ScrollRelative(v, units, count)
register JotView    *v;
register int	    units, count;
{
    int	top;

    if (v->text == 0)
	return_error(FALSE, Jot_ETEXT);

    top = JotSpan_QuickP(v->top);

    switch (units) {
    case Jot_LINES:
	if (count > 0) {
	    struct lineinfo	    li;
	    static JotSpan	    *span = 0;
	    register int	    lines, scanned_pos;
	    struct formatter_info   fi;

	    if (span == 0)
		span = JotSpan_NewI(v->text, 0, 0);
	    else
		JotSpan_SetText(span, v->text, 0, 0);
	    scanned_pos = JotSpan_QuickP(v->top);
	    li.text = span;
	    fi = v->defaultinfo;
	    while (--count >= 0) {
		JotSpan_QuickSetP(span, scanned_pos);
		scanned_pos = layoutline(&li, &li, 0, v, &fi);
		if (scanned_pos == JotSpan_QuickP(span))
		    break;
	    }
	    settoppos(v, scanned_pos);
	} else {
	    count = -count;
	    while (count > 0 && JotSpan_QuickP(v->top) > 0) {
		int n = (count > v->vlines) ? v->vlines : count;

		scroll_to(v, JotSpan_QuickP(v->top) - 1,
			  v->lineinfo[n - 1].fs.y - fixedi(v->lineinfo[n - 1].lineascent));
		count -= n;
	    }
	}
	break;

    case Jot_PAGES:
	if (count > 0) {
	    register int	ln;

	    for (ln = 0; ln < v->alines && v->lineinfo[ln].text != 0; ln++)
		;
	    ln -= 1;
	    if (ln > 0)
		settoppos(v, JotSpan_QuickP(v->lineinfo[ln].text));
	} else {
	    count = -count;
	    while (--count >= 0) {
		int pos;

		if (JotSpan_QuickP(v->top) == 0)
		    break;
		if (v->vlines >= 2)
		    pos = JotSpan_QuickP(v->lineinfo[1].text);
		else
		    pos = JotSpan_QuickP(v->top);
		scroll_to(v, pos, 0);
	    }
	}
	break;
    }
    return (top != JotSpan_QuickP(v->top));
}

void
JotView_ScrollAbsolute(v, pos, y)
JotView	*v;
int	pos, y;
{
    scroll_to(v, pos, fixedi(y));
}
