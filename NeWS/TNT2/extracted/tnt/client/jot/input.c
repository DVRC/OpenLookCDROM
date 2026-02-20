/*
 *	@(#)input.c 1.38 91/02/20 Copyright 1990-91 Sun Microsystems
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
#include "assert.h"
#include "view.h"
#include "text.h"
#include "font.h"
#include "color.h"
#include "input.h"
#include "search.h"
#include "psinter.h"

static int damage_tag, kbd_tag, scrollbar_tag, scrollinit_tag,
	    stringinput_tag, set_font_tag, obsolete_tag,
	    colors_tag, find_tag, undo_tag, redo_tag, mouse_tag,
	    damagestart_tag, reshape_tag;

static void damage_callback(), kbd_callback(),
	    scrollbar_callback(), scrollinit_callback(),
	    stringinput_callback(), set_font_callback(),
	    obsolete_callback(), colors_callback(),
	    find_callback(), undo_callback(), redo_callback(),
	    mouse_callback(), reshape_callback();

static struct tag_desc	input_tags[] = {
    "RESHAPE_TAG", &reshape_tag, reshape_callback,
    "DAMAGE_TAG", &damage_tag, damage_callback,
    "KBD_TAG", &kbd_tag, kbd_callback,
    "SCROLLBAR_TAG", &scrollbar_tag, scrollbar_callback,
    "SCROLLINIT_TAG", &scrollinit_tag, scrollinit_callback,
    "STRINGINPUT_TAG", &stringinput_tag, stringinput_callback,
    "SET-FONT", &set_font_tag, set_font_callback,
    "OBSOLETE", &obsolete_tag, obsolete_callback,
    "COLORS", &colors_tag, colors_callback,
    "FINDSELECTION", &find_tag, find_callback,
    "UNDO", &undo_tag, undo_callback,
    "REDO", &redo_tag, redo_callback,
    "MOUSE_EVENT", &mouse_tag, mouse_callback,
    "DAMAGESTART", &damagestart_tag, 0,
    0
};

/* This is called once ... */

Input_RegisterTags(tagtable)
struct tag_desc	*tagtable;
{
    for (; tagtable->tagname != 0; tagtable++) {
	int	tag;

	tag = *(tagtable->tagvalue) = wire_AllocateTags(1);
	if (tagtable->callback != 0)
	    wire_RegisterTag(tag, tagtable->callback, NULL);
    }
}

/* ... and this is called for each wire. */

Input_DefTags(tagtable)
struct tag_desc	*tagtable;
{
    for (; tagtable->tagname != 0; tagtable++) {
	int	tag;

	tag = *(tagtable->tagvalue);
	ps_deftag(tagtable->tagname, tag);
    }
}

/* These guys have to match the definitions in the jotcanvas on the
   server.  YUCK! */

#define SCROLL_ABSOLUTE	    0
#define SCROLL_LINE	    1
#define SCROLL_PAGE	    2
#define SCROLL_DOCUMENT	    3
#define SCROLL_HERETOTOP    4
#define SCROLL_TOPTOHERE    5

static int  process_event();

void
Jot_Initialize(connection)
wire_Wire   connection;
{
    static int	beenhere = 0;
    int	i;

    if (!wire_SetCurrent(connection))
	return;
    ps_startup();
    font_init();
    selection_init();
    if (!beenhere) {
	defaultinfo.parameters[F_TYPE] = FT_TEXT;
	defaultinfo.parameters[F_FONTFAMILY] = (int) JotFont_FindFamily("Times");
	defaultinfo.parameters[F_FACECODE] = 0;
	defaultinfo.parameters[F_POINTSIZE] = 12;
	defaultinfo.parameters[F_BASELINE] = 0;
	defaultinfo.parameters[F_LEFTMARGIN] = 0;
	defaultinfo.parameters[F_RIGHTMARGIN] = 0;
	defaultinfo.parameters[F_FIRSTMARGIN] = 0;
	defaultinfo.parameters[F_WIDTH] = 0;
	defaultinfo.parameters[F_HEIGHT] = 0;
	defaultinfo.parameters[F_LINESTYLE] = FL_JUSTIFIED;
	defaultinfo.parameters[F_LINESPACING] = 1;
	defaultinfo.parameters[F_COLOR_H] = 0;
	defaultinfo.parameters[F_COLOR_S] = 0;
	defaultinfo.parameters[F_COLOR_B] = 0;	/* black */
	defaultinfo.font = JotFont_New("Times-Roman", 12, 0);
	defaultinfo.color = color_create(0, 0, 0);

	Input_RegisterTags(input_tags);
	beenhere = 1;
    }
    Input_DefTags(input_tags);
}

static void
reshape_callback(tag)
{
    register struct lineinfo	*ln;
    register JotView		*v;
    int				cv, w, h;

    ps_reshape(&cv, &w, &h);
    v = JotView_View(wire_WireToInt(wire_Current()), cv);
    v->width = w;
    v->height = h;
    v->sbar_abs = FALSE;
    JotView_CalculateBBox(v);
    JotView_DamageView(v);
    v->damagedonce = 0;
}

static void
damage_callback()
{
    extern JotView		*current_view;
    register struct lineinfo	*ln;
    register JotView		*v;
    int				canvas, ytop, ybottom, w, i;

    w = wire_WireToInt(wire_Current());

    ps_damage(&canvas);
    v = JotView_View(w, canvas);
    v->damagedonce = TRUE;
    wire_DrainSync(v->wire, NULL);
    ps_damagestart(canvas, &ytop, &ybottom, damagestart_tag);
    JotView_HandleDamage(v, ytop, ybottom);
    ps_damageend(canvas);
}

static void
kbd_callback()
{
    register JotView	*v;
    int				canvas, c, w;

    w = wire_WireToInt(wire_Current());
    ps_keyboard(&canvas, &c);
    v = JotView_View(w, canvas);
    (*v->c_kbd)(v, c);
}

int
JotView_LinePosition(v, line)
JotView	*v;
int	line;
{
    if (line >= v->vlines)
	return 0;
    return floorfr(v->lineinfo[line].fs.y);
}

static void
scrollbar_callback()
{
    register JotView	*v;
    int			canvas, motion, w, arg;

    ps_scrollbar(&canvas, &motion, &arg);
    w = wire_Current();
    v = JotView_View(w, canvas);
    v->sbarwarp = TRUE;
    v->sbar_abs = FALSE;

    switch (motion) {
    case SCROLL_ABSOLUTE:
	JotView_ScrollAbsolute(v, arg, JotView_LinePosition(v, 0));
	v->sbar_abs = TRUE;
	break;

    case SCROLL_LINE:
	(void) JotView_ScrollRelative(v, Jot_LINES, arg);
	break;

    case SCROLL_PAGE:
	JotView_ScrollRelative(v, Jot_PAGES, arg);
	break;

    case SCROLL_DOCUMENT:
	{
	    int	pos;

	    if (arg == -1)
		pos = 0;
	    else
		pos = JotText_Characters(JotView_Text(v));
	    (void) JotView_EnsurePositionVisible(v, pos);
	    break;
	}

    case SCROLL_HERETOTOP:
	JotView_ScrollAbsolute(v, locate_mouse(v, 0, fixedi(arg)),
			       JotView_LinePosition(v, 0));
	break;

    case SCROLL_TOPTOHERE:
	JotView_ScrollAbsolute(v, JotSpan_Position(v->top), arg);
	break;

    }
}

static void
scrollinit_callback()
{
    register JotView	*v;
    int				canvas, scrolls, w;

    w = wire_WireToInt(wire_Current());

    ps_scrollinit(&canvas, &scrolls);
    v = JotView_View(w, canvas);
    v->scrollable = scrolls;
    v->scrollbar.top = v->scrollbar.bottom = v->scrollbar.size = -1;
}

static void
stringinput_callback()
{
    register JotView	*v;
    register PSFILE	*psf;
    int			canvas, nbytes, w, pos, x, y;

    w = wire_WireToInt(wire_Current());
    psf = wire_PSinput(wire_Current());
    ps_stringinput(&canvas, &x, &y, &nbytes);
    v = JotView_View(w, canvas);
    if (x == -1 && y == -1) {
	pos = JotText_Caret(v->text);
	JotView_EnsurePositionVisible(v, pos);
    } else
	pos = locate_mouse(v, fixedi(x), fixedi(y));
    if (!JotView_ReadOnly(v))
	JotSelection_BytesInserted(v->text, &pos, nbytes);
    if (nbytes >= 0) {
	char	*string;

	string = malloc(nbytes + 1);
	wire_ReadString(string);
	if (!JotView_ReadOnly(v))
	    JotText_InsertCharacters(v->text, pos, string, nbytes);
	free(string);
    }
}

static void
set_font_callback()
{
    struct font	    *f;
    JotView *v;
    char	    name[100];
    int		    size, wid, pmatched;

    ps_set_font(&wid, name, &size, &pmatched);
    v = JotView_View(wire_Current(), wid);
    v->gotsetfont = 1;
    if (v->dontsetfont)
	v->dontsetfont = 0;
    else {
	f = JotFont_New(name, size, pmatched);
	JotView_SetFont(v, f);
    }
}

static void
obsolete_callback()
{
    JotView *v;
    int		    canvas;

    ps_obsolete(&canvas);
    v = JotView_View(wire_Current(), canvas);
    JotView_FreeInternal(v);
}

static struct color *
read_color()
{
    int		    h, s, b;

    h = wire_ReadInt();
    s = wire_ReadInt();
    b = wire_ReadInt();
    return color_create(h, s, b);
}

static void
colors_callback(tag)
int tag;
{
    struct color    *c;
    JotView	    *v;
    int		    cv;

    ps_colors(&cv);
    v = JotView_View(wire_Current(), cv);

    v->bgcolor = read_color();	    /* back ground (fill) color */

    c = read_color();
    v->defaultinfo.parameters[F_COLOR_H] = c->h;
    v->defaultinfo.parameters[F_COLOR_S] = c->s;
    v->defaultinfo.parameters[F_COLOR_B] = c->b;
    v->defaultinfo.color = c;

    v->xor_pixel = wire_ReadInt();
}

static void
find_callback(tag)
int tag;
{
    int	    cv, rank, forward;
    JotView *view;
    char    *string;

    ps_findselection(&cv, &rank, &forward);
    view = JotView_View(wire_Current(), cv);
    string = JotSelection_Contents(view->text, rank);
    if (string == 0)
	ps_beep();
    else {
	if (!JotSearch_Find(view->text, JotText_Caret(view->text),
			    forward ? Jot_FORWARD : Jot_BACKWARD, string))
	    ps_beep();
	else
	    JotView_EnsurePositionVisible(view, JotText_Caret(view->text));
	free(string);
    }
}

static void
undo_callback(tag)
{
    JotView *v;
    JotText *t;
    int	    cv;

    ps_undo(&cv);
    v = JotView_View(wire_Current(), cv);
    JotText_Undo(t = JotView_Text(v));
    JotView_EnsurePositionVisible(v, JotText_Caret(t));
}

static void
redo_callback(tag)
{
    JotView *v;
    JotText *t;
    int	    cv;

    ps_redo(&cv);
    v = JotView_View(wire_Current(), cv);
    JotText_Redo(t = JotView_Text(v));
    JotView_EnsurePositionVisible(v, JotText_Caret(t));
}

static void
mouse_callback(tag)
{
    JotView *v;
    int	    cv, button, action;
    fixed   x, y;

    ps_mouse_event(&cv, &button, &action, &x, &y);
    v = JotView_View(wire_Current(), cv);
    (*v->c_mouse)(v, button, action, locate_mouse(v, x, y));
}
