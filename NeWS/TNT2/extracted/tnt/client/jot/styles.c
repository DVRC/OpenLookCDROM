/*
 *	@(#)styles.c 1.19 91/02/20 Copyright 1990-91 Sun Microsystems
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

#define DECLARE_STYLES_GLOBALS

#include <stdio.h>
#include <varargs.h>
#include <NeWS/wire/wire.h>
#include "assert.h"
#include "cps.h"
#include "view.h"
#include "text.h"
#include "styles.h"
#include "font.h"
#include "color.h"
#include "span.h"
#include "undo.h"

#define text_styleref(t, n) \
    ((struct styleref *)& Bytestring_CharAt((t)->stylerefs,(n)*sizeof(struct styleref)))

/* A reference to a style from a text */
struct styleref {		/* BOGUS! */
    int         pos;		/* The position in the text of the
				 * reference */
    int         span;		/* The size of the reference */
    short       parent;		/* The smallest styleref that encloses this
				 * one */
    struct style *style;	/* The style referred to */
};

struct mparam {
    short       which;		/* What in the formatter paramater state this
				 * modifies */
    short       how;		/* How it modifies that state (M_REPLACE,
				 * M_ADD, M_OR) */
    int         value;		/* The value used in the modification */
};

#define mparam_ref(s, i) \
    ((struct mparam *) (& Bytestring_CharAt((s)->mods, (i) * sizeof (struct mparam))))

static void style_delete();
static void style_apply();

/* Locates the first style whose pos is >= pos.  There is always one
   style whose pos is just beyond the end of the text */

static int
locate_style(t, pos)
register JotText    *t;
register int	    pos;
{
    register struct styleref	*s;
    register int		lo, mid, hi;

    if (t->stylerefs == 0)
	return 0;
    lo = 0;
    hi = t->nstylerefs;
    while (lo < hi) {
	mid = (lo + hi) >> 1;
	s = text_styleref(t, mid);
	if (s->pos >= pos)
	    hi = mid;
	else
	    lo = mid + 1;
    }
    assert((s = text_styleref(t, lo))->pos >= pos);
    assert(lo == 0 || text_styleref(t, lo - 1)->pos < pos);
    return lo;
}

style_Find(text, pos, span, style)
JotText		*text;
int		pos, span;
struct style	*style;
{
    struct styleref *sr;
    int		    i;

    i = locate_style(text, pos);
    while (i < text->nstylerefs) {
	sr = text_styleref(text, i);
	if (sr->pos != pos)
	    break;
	if (sr->span == span && sr->style == style)
	    return i;
	i += 1;
    }
/*    printf("style_Find(%d, %d, %s) => -1\n", pos, span, style->name); */
    return -1;
}

/* Returns the enclosing style -1 if there is no enclosing style.
   Stores the pos of the next style change in next_style_pos. */
static
locate_enclosing_style(t, pos, style, next_style_pos)
JotText	    *t;
int	    *next_style_pos;
{
    struct styleref *sp, *nsp;

    sp = text_styleref(t, style);
    if (sp->pos == pos) {
	while (style < t->nstylerefs) {
	    nsp = text_styleref(t, style + 1);
	    if (nsp->pos != sp->pos) {
		*next_style_pos = nsp->pos;
		break;
	    }
	    style += 1;
	}
    } else {
	style -= 1;
	*next_style_pos = sp->pos;
    }
    /* If the pos of style == pos, then style is the innermost child
       that begins at pos.  Otherwise, style is the previous styleref.
       Either way, we look in style to see if POS is contained in it,
       and if it is, that is our starting point, otherwise we look in
       style's parent to see if we are contained in that.  Eventually
       we will be contained in a style, or we reach style = -1, which
       is the global style. */
    while (style >= 0) {
	sp = text_styleref(t, style);
	if (pos >= sp->pos && pos < sp->pos + sp->span)
	    break;
	style = sp->parent;
    }
    if (style >= 0)
	*next_style_pos = min(*next_style_pos, sp->pos + sp->span);

    return style;
}

void
JotStyle_BytesInserted(t, pos, n)
JotText *t;
int	    pos, n;
{
    struct styleref	*s;
    int			i, dummy;
    int			style;
    int			enclosing_style;

    /* Locate the first style >= pos, and then the enclosing style.
       Have to locate the enclosing style before we update POS. */

    style = locate_style(t, pos);
    enclosing_style = locate_enclosing_style(t, pos, style, &dummy);
    for (i = style; i <= t->nstylerefs; i++) {
	s = text_styleref(t, i);
	s->pos += n;
    }
    pos += n;
    while (enclosing_style != -1) {
	s = text_styleref(t, enclosing_style);
	if (pos > s->pos)
	    s->span += n;
	enclosing_style = s->parent;
    }
}

void
JotStyle_BytesDeleted(t, pos, n)
JotText *t;
int	    pos, n;
{
    struct styleref	*s;
    int			i, dummy;
    int			style;

    if (n < 0) {
	pos += n;
	n = -n;
    }
    style = 0;
    JotText_UndoBegin(t);
    while (style < t->nstylerefs) {
	s = text_styleref(t, style);
	if (pos <= s->pos) {
	    if (pos + n <= s->pos)
		s->pos -= n;
	    else if (pos + n >= s->pos + s->span) {
		style_delete(t, style);
/*		printf("Wow! Deleted style %d\n", style); */
		continue;
	    } else {
		s->span -= (pos + n) - s->pos;
		s->pos = pos;
	    }
	} else if (pos > s->pos) {
	    if (pos + n <= s->pos + s->span) {
		s->span -= n;
	    } else if (pos <= s->pos + s->span)
		s->span -= s->pos + s->span - pos;
	}
	assert(s->span > 0);
	style += 1;
    }
    JotText_UndoEnd(t);
}

print_styles(d)
    register JotText *d;
{
    register    slot;
    if (d->nstylerefs <= 0) {
	printf("no styles\n");
	return;
    }
    printf("%d styles\n", d->nstylerefs);
    printf("  #  pos1  pos2  span  parent what\n");
    for (slot = 0; slot < d->nstylerefs; slot++) {
	register struct styleref *s = text_styleref(d, slot);
	char	*comment = NULL;

	if (s->style == 0)
	    comment = "NULL";
	else
	    comment = s->style->name;
	if (comment == NULL)
	    comment = "?";

	printf("%3d%6d%6d%6d%8d  %s\n", slot, s->pos, s->pos + s->span,
	       s->span, s->parent, comment);
    }
}

/* This has a maximum of 128 nested stylerefs.  This routine used to
   be implemented recursively, but I decided to speed it up by maintaining
   a stack of style refs. */
static void
cfi_aux(t, fi, si)
JotText		*t;
struct formatter_info	*fi;
int			si;	/* style index */
{
    struct style    *s;
    struct styleref *sr, *sr_stack[128];
    int		    sp = 0;	/* stack pointer */

    if (si == -1)
	return;
    
    do {
	sr = text_styleref(t, si);
	sr_stack[sp++] = sr;
	si = sr->parent;
    } while (si != -1);

    while (--sp >= 0) {
	int i;

	sr = sr_stack[sp];

	for (i = 0, s = sr->style; i < s->nmods; i++) {
	    struct mparam   *mod = mparam_ref(s, i);
	    int		    *value_slot = &fi->parameters[mod->which];

	    switch (mod->how) {
	    case M_REPLACE:
		*value_slot = mod->value;
		break;

	    case M_ADD:
		*value_slot += mod->value;
		break;

	    case M_OR:
		*value_slot |= mod->value;
		break;

	    case M_ADDPSREL:
		*value_slot += floorfr(fi->parameters[F_POINTSIZE] * mod->value);
		break;

	    default:
		fprintf(stderr, "Unknown formatting modifier: %d\n", mod->how);
		abort();
	    }
	}
    }
}

/* Calculate the formatter info for POS in the document viewed by
   V.  This works by going back to the root of the stylerefs and
   THEN modifying FI on the way back down.

   This routine also returns the position of the next style
   change.  The next style (I'm glad I'm writing this down!)
   change happens either at the end of the current styleref,
   or at the beginning of the next styleref.  It depends on
   whether pos of the next styleref begins BEFORE or AFTER
   the span of the current one. */

min(a, b)
int a, b;
{
    return (a < b) ? a : b;
}

max(a, b)
int a, b;
{
    return (a > b) ? a : b;
}

void
calculate_formatter_info(v, lni, fi, pos)
JotView			*v;
struct lineinfo		*lni;
struct formatter_info	*fi;
int			pos;
{
    struct font	    *f;
    struct color    *c;
    struct styleref *sp, *nsp;
    JotText	    *t = v->text;
    int		    style, parent;
    int		    ascent;

    *fi = v->defaultinfo;
    fi->next_style_pos = 1 + JotText_Characters(t);	/* just past eob */

    if (t->nstylerefs > 0) {
	style = locate_style(t, pos);
	style = locate_enclosing_style(t, pos, style, &fi->next_style_pos);
	cfi_aux(t, fi, style);
    }

    f = fi->font;
    if (f->size != fi->parameters[F_POINTSIZE] ||
	f->family != (struct fontfamily *) fi->parameters[F_FONTFAMILY] ||
	f->facecode != fi->parameters[F_FACECODE])
	fi->font = f = (struct font *) JotFont_FontFromFamily((struct fontfamily *) fi->parameters[F_FONTFAMILY],
				   fi->parameters[F_FACECODE],
				   fi->parameters[F_POINTSIZE],
				   f->pmatched);
    lni->lineascent = max(fi->parameters[F_BASELINE] + floorfr(f->ascent),
			  lni->lineascent);
    lni->linedescent = max(-fi->parameters[F_BASELINE] + floorfr(f->descent),
			   lni->linedescent);
    c = fi->color;
    if (c->h != fi->parameters[F_COLOR_H] ||
	c->s != fi->parameters[F_COLOR_S] ||
	c->b != fi->parameters[F_COLOR_B])
	fi->color = color_create(fi->parameters[F_COLOR_H],
				 fi->parameters[F_COLOR_S],
				 fi->parameters[F_COLOR_B]);
}


#define Allocate(t) ((t *) malloc(sizeof (t)))

char *
copystr(s)
char	*s;
{
    char    *ns;
    int	    len;

    len = strlen(s);
    ns = (char *) malloc(len + 1);
    bcopy(s, ns, len + 1);  /* include the null in the copy */

    return ns;
}

void
style_Initialize(s, name)
struct style	*s;
char		*name;
{
    bzero((char *) s, sizeof (struct style));
    s->name = copystr(name);
}

struct style *
style_New(name)
char	*name;
{
    struct style    *s;

    s = Allocate(struct style);
    style_Initialize(s, name);

    return s;
}

void
style_Free(s)
struct style	*s;
{
    Bytestring_Free(s->mods);
    free((char *) s);
}

char *
style_Name(s)
struct style	*s;
{
    return s->name;
}

void
style_Define(va_alist)
va_dcl
{
    struct mparam	mod;
    struct style	*s;
    va_list		ap;

    va_start(ap);
    s = va_arg(ap, struct style *);
    if (s->mods == 0)
	s->mods = Bytestring_New(sizeof (mod));
    while ((mod.which = va_arg(ap, int)) != F_EOF) {
	mod.how = va_arg(ap, int);
	mod.value = va_arg(ap, int);
	Bytestring_Insert(s->mods, s->nmods * sizeof (mod), &mod, sizeof (mod));
	s->nmods += 1;
    }
    va_end(ap);
}

void
style_Append(s1, s2)
struct style	*s1, *s2;
{
    int	i;

    if (s1->mods == 0)
	s1->mods = Bytestring_New(sizeof (struct mparam));
    for (i = 0; i < s2->nmods; i++) {
	Bytestring_Insert(s1->mods, s1->nmods * sizeof (struct mparam),
			  mparam_ref(s2, i), sizeof (struct mparam));
	s1->nmods += 1;
    }
}

void
style_Clear(s)
struct style	*s;
{
    Bytestring_Delete(s->mods, 0, Bytestring_Length(s->mods));
    s->nmods = 0;
}

style_Delete(t, slot)
JotText	*t;
int	slot;
{
    JotText_UndoBegin(t);
    style_delete(t, slot);
    JotText_UndoEnd(t);
}

/* Delete styleref SLOT.  This has to reparent all the children of SLOT,
   and then decrement all the parent fields that are > SLOT. */

static void
style_delete(t, slot)
register JotText    *t;
register int	    slot;
{
    register struct styleref	*s = text_styleref(t, slot);
    register int		child;
    short			parent;

    if (slot < 0 || slot >= t->nstylerefs)
	return;
    JotSpan_ModifyInRange(t->spans, s->pos, s->pos + s->span);
    JotText_UndoStyle(t, s->pos, s->span, s->style, undo_styledelete);
    parent = s->parent;
    child = slot + 1;
    while (child < t->nstylerefs) {
	s = text_styleref(t, child);
	if (s->parent == slot)
	    s->parent = parent;
	else if (s->parent > slot)
	    s->parent -= 1;
	child += 1;
    }
    Bytestring_Delete(t->stylerefs, slot * sizeof(struct styleref),
		      sizeof(struct styleref));
    t->nstylerefs -= 1;
}

static void
split_stylerefs(text, slot, endslot, pos)
JotText	*text;
int	slot, endslot, pos;
{
    struct styleref *s;
    struct style    *style;
    int		    start, middle, end;
    short	    parent_slot;

    if (slot == endslot)
	return;
    s = text_styleref(text, slot);
    style = s->style;
    parent_slot = s->parent;
    start = s->pos;
    middle = pos;
    end = start + s->span;

    /* If we need to split the thing, delete it, split any
       parents that need splitting, and then apply the two
       halfs of the split.  Otherwise, just because we don't
       need splitting, it doesn't mean one of our parents
       doesn't as well. */
    if (!(start == middle || middle == end)) {
	style_delete(text, slot);
	split_stylerefs(text, parent_slot, endslot, pos);
	style_apply(text, start, pos - start, style);
	style_apply(text, pos, end - pos, style);
    } else
	split_stylerefs(text, parent_slot, endslot, pos);
}		

/* Create the new styleref, put it in the right place, splitting existing
   styles as necessary, and then go modify all the spans in the text
   object that are affected by this change. */

void
style_Apply(style, span)
struct style	*style;
JotSpan		*span;
{
    JotText_UndoBegin(JotSpan_Text(span));
    style_apply(JotSpan_Text(span), JotSpan_Position(span),
		JotSpan_Length(span), style);
    JotText_UndoEnd(JotSpan_Text(span));
}

static void
style_apply(t, pos, length, style)
JotText		*t;
int		pos, length;
struct style	*style;
{
    register struct styleref *s;
    struct styleref	    new;
    JotSpan		    *sp;
    short		    slot, slot1, slot2, parent;
    int			    i, endpos, dummy;

    if (length <= 0 || style == 0)
	return;

    /* First, make sure there is at least one style reference at the
       end of the document. */
    if (t->stylerefs == 0) {
	struct styleref new;

	t->stylerefs = Bytestring_New(4 * sizeof (new));
	new.style = 0;
	new.pos = t->data->size;
	new.span = 0;
	new.parent = -1;
	Bytestring_Insert(t->stylerefs, 0, &new, sizeof new);
    }

    /* Now find the right place to insert this new styleref.  We
       find the span that encloses POS and the span that ENDPOS.
       If they are the same span, then we create the new styleref
       and reparent all the children.  That's the easy case.  If
       POS and ENDPOS are not children of the same span, then we
       have to split their enclosing spans and their parents until
       we reach a common parent for both POS and ENDPOS.  God this
       is hairy! */

    endpos = pos + length;
    slot = locate_style(t, pos);
    slot1 = locate_enclosing_style(t, pos, slot, &dummy);
    slot2 = locate_enclosing_style(t, endpos, locate_style(t, endpos), &dummy);

    if (slot1 != slot2) {
	short	p1, p2;

	p1 = slot1;
	p2 = slot2;
	while (p1 != p2) {
	    if (p1 < p2)
		p2 = text_styleref(t, p2)->parent;
	    else
		p1 = text_styleref(t, p1)->parent;
	}
	parent = p1;

	/* OK, split the spans at slot2 BEFORE slot1, since any
	   additions into the styleref's array will not affect
	   the slot numbers of earlier ones (I think). */
	split_stylerefs(t, slot2, parent, endpos);
	assert(slot1 == locate_enclosing_style(t, pos, slot, &dummy));
	split_stylerefs(t, slot1, parent, pos);
	slot = locate_style(t, pos);
    } else
	parent = slot1;

    /* Now we have split any stylerefs that would have been overlapped
       by this one.  slot now points at the first styleref whose pos is
       >= POS.  So, now we figure out where we fit.

       If our POS is the same as the slot's pos, then we just figure out
       where we fit.  To do this we find the first styleref starting with
       SLOT that is smaller than the one we are trying to create, and
       insert ourselves there.  Then we reparent all the refs following
       that we enclose.  NOTE:  If the new style ref has the same position
       and size as an existing one, it must become the child of that
       existing span.

       If our POS is < slot's POS, we just insert ourselves there, and
       reparent all siblings at that level that we enclose. */

    s = text_styleref(t, slot);
    if (s->pos == pos) {
	while (slot <= t->nstylerefs) {
	    s = text_styleref(t, slot);
	    if (s->pos > pos || s->pos + s->span < endpos)
		break;
	    slot += 1;
	}
	if (s->pos == pos)
	    parent = s->parent;
	else
	    parent = slot - 1;
    }

    slot1 = slot;	/* remember starting slot */
    new.style = style;
    new.pos = pos;
    new.span = length;
    new.parent = parent;
    JotText_UndoStyle(t, pos, length, style, undo_styleapply);
    Bytestring_Insert(t->stylerefs, slot1 * sizeof(struct styleref),
		      &new, sizeof new);
    t->nstylerefs++;

    /* We've just inserted a new styleref at position SLOT.  Now we
       have to go through the all the stylerefs and find the ones
       with parent's that are >= to the slot we just moved over, and
       bump their parent ref by one. */
    for (i = slot1 + 1; i < t->nstylerefs; i++) {
	s = text_styleref(t, i);
	if (s->parent >= slot1) {
	    s->parent += 1;
	    assert(s->parent < i);
	}
    }

    slot = slot1 + 1;
    while (slot < t->nstylerefs) {
	s = text_styleref(t, slot);
	if (s->pos + s->span <= endpos) {
	    if (s->parent < slot1)
		s->parent = slot1;
	} else
	    break;
	slot += 1;
    }

    JotText_Modify(t);

    JotSpan_ModifyInRange(t->spans, pos, endpos);
}

static char *parameter_names[] = {
    "type",
    "fontfamily",
    "facecode",
    "pointsize",
    "baseline",
    "leftmargin",
    "rightmargin",
    "firstmargin",
    "width",
    "height",
    "linestyle",
    "linespacing",
    "h",
    "s",
    "b",
    0
};

static char *function_names[] = {
    "replace",
    "add",
    "or",
    "addpsrelative",
    0
};

int
name_to_parameter(name)
char	*name;
{
    int	i;

    for (i = 0; parameter_names[i] != 0; i++)
	if (strcmp(parameter_names[i], name) == 0)
	    return i;
    fprintf(stderr, "Unknown parameter: %s\n", name);
    return -1;
}

int
name_to_function(name)
char	*name;
{
    int	i;

    for (i = 0; function_names[i] != 0; i++)
	if (strcmp(function_names[i], name) == 0)
	    return i;
    fprintf(stderr, "Unknown function: %s\n", name);
    return -1;
}

style_Read(s, fp)
struct style	*s;
FILE		*fp;
{
    char    name[256], line[512], fcn[128];
    int	    value, pno, fno;

    /* Now read the parameter definitions. */
    while (fgets(line, sizeof line, fp) != NULL) {
	if (strcmp(line, "}\n") == 0)
	    break;
	if (sscanf(line, "\t%[^:]:%[^:]:%d\n", name, fcn, &value) != 3) {
	    fprintf(stderr, "Syntax error in styleread: sscanf fails.\n");
	    break;
	}
	pno = name_to_parameter(name);
	fno = name_to_function(fcn);
	if (pno < 0 || fno < 0)
	    break;
	style_Define(s, pno, fno, value, F_EOF);
    }
}

style_Write(s, fp)
struct style	*s;
FILE		*fp;
{
    int	i;

    for (i = 0; i < s->nmods; i++) {
	struct mparam	*m = mparam_ref(s, i);

	fprintf(fp, "\t%s:%s:%d\n", parameter_names[m->which],
		function_names[m->how], m->value);
    }
    fprintf(fp, "}\n");
}

struct stylesheet {
    short		nstyles;
    struct bytestring	*styleptrs;
};

#define get_style(s, i) \
    ((struct style *) &Bytestring_CharAt((s)->styleptrs, \
					 (i) * sizeof(struct style *)))

struct stylesheet *
stylesheet_New()
{
    struct stylesheet	*s;

    s = Allocate(struct stylesheet);
    bzero((char *) s, sizeof (struct stylesheet));

    return s;
}

void
stylesheet_Free(s)
struct stylesheet   *s;
{
    free((char *) s);
}

stylesheet_FreeStyles(s)
struct stylesheet   *s;
{
    int	i;

    for (i = 0; i < s->nstyles; i++)
	style_Free(get_style(s, i));
    s->nstyles = 0;
}

stylesheet_Add(s, style)
struct stylesheet   *s;
struct style	    *style;
{
    int	i;

    for (i = 0; i < s->nstyles; i++)
	if (style == get_style(s, i))
	    return;
    Bytestring_Insert(s->styleptrs, s->nstyles * sizeof (struct style *),
		      &style, sizeof (struct style *));
    s->nstyles += 1;
}

stylesheet_Remove(s, style)
struct stylesheet   *s;
struct style	    *style;
{
    int	i;

    for (i = 0; i < s->nstyles; i++)
	if (style == get_style(s, i))
	    break;
    if (i == s->nstyles)
	return;
    Bytestring_Delete(s->styleptrs, i * sizeof (struct style *),
		      sizeof (struct style *));
    s->nstyles -= 1;
}

struct style *
stylesheet_Find(s, name)
struct stylesheet   *s;
char		    *name;
{
    struct style    *style;
    int		    i;

    for (i = 0; i < s->nstyles; i++)
	if (strcmp(name, (style = get_style(s, i))->name) == 0)
	    break;
    return (i == s->nstyles) ? NULL : style;
}

/* This is called after the main reading routine has spotted
    \defstyle{

   It is up to us to read the name of the style, and then call
   style_Read().  style_Read() knows to stop when it reads a
   line with a }. */

stylesheet_Read(s, fp)
struct stylesheet   *s;
FILE		    *fp;
{
    struct style    *style;
    char	    name[256];
    char	    needs_adding = TRUE;
    int		    len;

    if (fgets(name, sizeof name, fp) == NULL)
	return NULL;
    if (name[(len = strlen(name)) - 1] != '\n') {
	fprintf(stderr, "Syntax error in styledef.\n");
	return NULL;
    }
    name[len - 1] = '\0';
    if ((style = stylesheet_Find(s, name)) != 0) {
	style_Clear(style);
	needs_adding = FALSE;
    } else
	style = style_New(name);

    style_Read(style, fp);
    if (needs_adding)
	stylesheet_Add(s, style);
}

stylesheet_Write(s, fp)
struct stylesheet   *s;
FILE		    *fp;
{
    struct style    *style;
    int		    i;

    for (i = 0; i < s->nstyles; i++) {
	style = get_style(s, i);
	fprintf(fp, "\\defstyle{%s\n", style->name);
	style_Write(style, fp);
    }
}
