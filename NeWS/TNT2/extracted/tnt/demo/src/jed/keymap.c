/*
 *	@(#)keymap.c 1.14 91/02/21 Copyright 1990-91 Sun Microsystems
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

#include <jot/jot.h>
#include <jot/view.h>
#include <jot/text.h>
#include <jot/color.h>
#include <jot/search.h>
#include "keymap.h"
#include "colors.h"
#include "buffer.h"
#include "utils.h"

static
nullproc()
{
    return 0;
}

struct keymap *
new_keymap()
{
    register struct keymap *ret;
    register    i;
    ret = (struct keymap *) malloc(sizeof *ret);
    ret->parent = 0;
    for (i = MAX_KEY; --i >= 0;)
	ret->func[i] = nullproc;
    return ret;
}

keymap_add(map, key, proc)
    register struct keymap *map;
    register int (*proc) ();
{
    if (key >= 0 && key <= MAX_KEY)
	map->func[key] = proc;
}

static
use_handler(v, handler)
JotView	*v;
{
    Buffer  *b;

    b = (Buffer *) JotView_Data(v);
    b->keystate.state = handler;
}

struct keymap *basic_map;
struct keymap *writeable_map;

static
LOOK_handler(v)
    register JotView *v;
{
    use_handler(v, LOOK_PREFIX);
}

static
CTLX_handler(v)
    register JotView *v;
{
    use_handler(v, CTLX_PREFIX);
}

static
ctlx_begin_handler(v)
JotView	*v;
{
    JotText_UndoBegin(JotView_Text(v));
}

static
ctlx_end_handler(v)
JotView	*v;
{
    JotText_UndoEnd(JotView_Text(v));
}


static
ESC_handler(v)
    register JotView *v;
{
    use_handler(v, ESC_PREFIX);
}

struct style	*style_bold, *style_italic, *style_subscript,
		    *style_superscript, *style_larger, *style_smaller,
		    *style_dimmer, *style_brighter, *style_quote;

style_init()
{
    style_bold = style_New("bold");
    style_Define(style_bold, F_FACECODE, M_OR, FC_BOLD, F_EOF);

    style_italic = style_New("italic");
    style_Define(style_italic, F_FACECODE, M_OR, FC_ITALIC, F_EOF);

    style_smaller = style_New("smaller");
    style_Define(style_smaller, F_POINTSIZE, M_ADDPSREL, -fixedi(1) / 5, F_EOF);

    style_larger = style_New("larger");
    style_Define(style_larger, F_POINTSIZE, M_ADDPSREL, fixedi(1) / 5, F_EOF);

    style_superscript = style_New("superscript");
    style_Define(style_superscript, F_BASELINE, M_ADDPSREL, fixedi(1) / 2,
		 F_EOF);
    style_Append(style_superscript, style_smaller);

    style_subscript = style_New("subscript");
    style_Define(style_subscript, F_BASELINE, M_ADDPSREL, -fixedi(1) / 2,
		 F_EOF);
    style_Append(style_subscript, style_larger);

    style_dimmer = style_New("dimmer");
    style_Define(style_dimmer, F_COLOR_S, M_ADD, 30, F_EOF);

    style_brighter = style_New("brighter");
    style_Define(style_brighter, F_COLOR_S, M_ADD, -30, F_EOF);

    style_quote = style_New("quoted-paragraph");
    style_Define(style_quote,
		 F_LEFTMARGIN, M_ADD, 36,
		 F_RIGHTMARGIN, M_ADD, 36,
		 F_POINTSIZE, M_ADDPSREL, -fixedi(1) / 5,
		 F_EOF);

}

void
maybe_apply_style(vw, style)
JotView	*vw;
struct style	*style;
{
    JotSpan *span;

    span = JotSelection_Span(JotView_Text(vw), Jot_PRIMARY);
    if (span == 0)
	return;
    if (JotSpan_Length(span) > 0)
	style_Apply(style, span);
}

static
look_CTLB_handler(vw)
    register JotView *vw;
{
    maybe_apply_style(vw, &style_blue);
}

static
look_CTLR_handler(vw)
    register JotView	*vw;
{
    maybe_apply_style(vw, &style_red);
}

look_BOLD_handler(vw)
JotView	*vw;
{
    maybe_apply_style(vw, style_bold);
}

look_ITALIC_handler(vw)
JotView	*vw;
{
    maybe_apply_style(vw, style_italic);
}

static
look_DIMMER_handler(vw)
JotView	*vw;
{
    maybe_apply_style(vw, style_dimmer);
}

look_BRIGHTER_handler(vw)
JotView	*vw;
{
    maybe_apply_style(vw, style_brighter);
}

static
look_CTLD_handler(vw, key)
    register JotView *vw;
{
    maybe_apply_style(vw, style_subscript);
}

static
look_CTLI_handler(vw, key)
    register JotView *vw;
{
    maybe_apply_style(vw, style_italic);
}

static
look_CTLL_handler(vw, key)
    register JotView *vw;
{
    maybe_apply_style(vw, style_larger);
}

static
look_CTLP_handler(vw, key)
    register JotView *vw;
{
    print_styles(vw->text);
}

static
look_CTLS_handler(vw, key)
    register JotView *vw;
{
    maybe_apply_style(vw, style_smaller);
}

static
look_CTLU_handler(vw, key)
    register JotView *vw;
{
    maybe_apply_style(vw, style_superscript);
}

static 
look_CTLQ_handler(v, key)
JotView	*v;
{
    maybe_apply_style(v, style_quote);
}

static
return_handler(vw, key)
    register JotView *vw;
{
    Buffer_InsertChar(View_Buffer(vw), '\n');
}

CTLL_handler(v, key)
JotView	*v;
{
    JotView_ScrollAbsolute(v, JotText_Caret(JotView_Text(v)),
			      JotView_Height(v) / 2);
}

CTLN_handler(v, key)
JotView	*v;
{
    JotView_ScrollRelative(v, Jot_LINES, 1);
}

CTLP_handler(v, key)
JotView	*v;
{
    JotView_ScrollRelative(v, Jot_LINES, -1);
}

CTLU_handler(v, key)
JotView	*v;
{
    JotText_Undo(JotView_Text(v));
    JotView_EnsurePositionVisible(v, JotText_Caret(JotView_Text(v)));
}

CTLR_handler(v, key)
JotView	*v;
{
    JotText_Redo(JotView_Text(v));
    JotView_EnsurePositionVisible(v, JotText_Caret(JotView_Text(v)));
}

static
insert_handler(vw, key)
    register JotView *vw;
{
    Buffer_InsertChar(View_Buffer(vw), key);
}

static
backspace_handler(vw, key)
    register JotView *vw;
{
    Buffer_DeleteChar(View_Buffer(vw), -1);
}

static
CTLD_handler(vw, key)
    register JotView *vw;
{
    Buffer_DeleteChar(View_Buffer(vw), 1);
}

static
CTLA_handler(vw, key)
    register JotView *vw;
{
    Buffer_BeginningOfLine(View_Buffer(vw));
}

static
CTLB_handler(vw, key)
    register JotView *vw;
{
    JotText *t = JotView_Text(vw);

    if (JotText_Caret(t) > 0) {
	JotText_SetCaret(t, JotText_Caret(t) - 1);
	JotView_EnsurePositionVisible(vw, JotText_Caret(t));
    }
}

static
CTLC_handler(vw, key)
    register JotView *vw;
{

}

static
CTLE_handler(vw, key)
    register JotView *vw;
{
    Buffer_EndOfLine(View_Buffer(vw));
}

static
CTLF_handler(vw, key)
    register JotView *vw;
{
    JotText *t = JotView_Text(vw);

    if (JotText_Caret(t) < JotText_Characters(t)) {
	JotText_SetCaret(t, JotText_Caret(t) + 1);
	JotView_EnsurePositionVisible(vw, JotText_Caret(t));
    }
}

static
CTLW_handler(vw, key)
    register JotView *vw;
{
    Buffer_DeleteWord(View_Buffer(vw), -1);
}

CTLS_handler(vw, key)
JotView	*vw;
{
    JotText		*text;
    char		*contents;

    text = JotView_Text(vw);
    contents = JotSelection_Contents(text, Jot_PRIMARY);
    JotSearch_Find(JotView_Text(vw), JotText_Caret(text),
		   (key == ('S' & 037)) ? Jot_FORWARD : Jot_BACKWARD,
		   contents);
    free(contents);
}

static
readonly_handler(v, key)
JotView	*v;
{
    JotView_SetReadOnly(v, !JotView_ReadOnly(v));
}

load_handler()
{
    map_popup("load");
}

save_handler()
{
    map_popup("save");
}

keymap_init()
{
    basic_map = new_keymap();
    basic_map->func['A' & 037] = CTLA_handler;
    basic_map->func['B' & 037] = CTLB_handler;
    basic_map->func['C' & 037] = CTLC_handler;
    basic_map->func['E' & 037] = CTLE_handler;
    basic_map->func['F' & 037] = CTLF_handler;
    basic_map->func['L' & 037] = LOOK_handler;
    basic_map->func['X' & 037] = CTLX_handler;
    basic_map->func['N' & 037] = CTLN_handler;
    basic_map->func['P' & 037] = CTLP_handler;
    basic_map->func['\\' & 037] = CTLS_handler;
    basic_map->func['S' & 037] = CTLS_handler;
    basic_map->func['W' & 037] = CTLW_handler;
    basic_map->func['l' | ESC_PREFIX] = load_handler;
    basic_map->func['s' | ESC_PREFIX] = save_handler;
    basic_map->func[033] = ESC_handler;

    writeable_map = new_keymap();
    writeable_map->parent = basic_map;

    writeable_map->func['b' | LOOK_PREFIX] = look_BOLD_handler;
    writeable_map->func['i' | LOOK_PREFIX] = look_ITALIC_handler;
    writeable_map->func['B' & 037 | LOOK_PREFIX] = look_CTLB_handler;
    writeable_map->func['D' & 037 | LOOK_PREFIX] = look_CTLD_handler;
    writeable_map->func['I' & 037 | LOOK_PREFIX] = look_CTLI_handler;
    writeable_map->func['L' & 037 | LOOK_PREFIX] = look_CTLL_handler;
    writeable_map->func['P' & 037 | LOOK_PREFIX] = look_CTLP_handler;
    writeable_map->func['Q' & 037 | LOOK_PREFIX] = look_CTLQ_handler;
    writeable_map->func['R' & 037 | LOOK_PREFIX] = look_CTLR_handler;
    writeable_map->func['S' & 037 | LOOK_PREFIX] = look_CTLS_handler;
    writeable_map->func['U' & 037 | LOOK_PREFIX] = look_CTLU_handler;
    writeable_map->func['<' | LOOK_PREFIX] = look_DIMMER_handler;
    writeable_map->func['>' | LOOK_PREFIX] = look_BRIGHTER_handler;

    writeable_map->func['(' | CTLX_PREFIX] = ctlx_begin_handler;
    writeable_map->func[')' | CTLX_PREFIX] = ctlx_end_handler;

    writeable_map->func['D' & 037] = CTLD_handler;
    writeable_map->func['H' & 037] = backspace_handler;
    writeable_map->func['M' & 037] = return_handler;
    writeable_map->func['U' & 037] = CTLU_handler;
    writeable_map->func['R' & 037] = CTLR_handler;
    writeable_map->func[0177] = backspace_handler;
    writeable_map->func['r' | CTLX_PREFIX] = readonly_handler;
    {	register i;
	for (i = ' '; i<0177; i++)
	    writeable_map->func[i] = insert_handler;
    }
    writeable_map->func['\t'] = insert_handler;
    writeable_map->func['\n'] = insert_handler;
}

void
keymap_dispatch(vw, ch)
JotView	*vw;
int	ch;
{
    register struct keymap  *map;
    struct keystate	    *ks;

    ks = &((Buffer *) JotView_Data(vw))->keystate;

    map = ks->map;
    ch |= ks->state;
    ks->state = 0;
    for (; map != 0 && (map->func[ch] == 0 || map->func[ch] == nullproc);
	 map = map->parent)
	;
    if (map != 0)
	(*map->func[ch])(vw, ch);
}
