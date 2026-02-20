/*
 *	@(#)menu_cmds.c 1.14 91/02/21 Copyright 1990-91 Sun Microsystems
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
#include <NeWS/jot/jot.h>
#include <NeWS/jot/view.h>
#include <NeWS/jot/text.h>
#include <NeWS/jot/color.h>
#include <NeWS/jot/search.h>
#include <NeWS/jot/span.h>
#include "keymap.h"
#include "colors.h"
#include "utils.h"
#include "jed_cps.h"
#include "buffer.h"

static int  tag_zero = -1;

static void c_LoadFile(), c_SaveFile(), c_WriteFile(),
	c_SetDirectory(), c_InsertFile(), c_EmptyBuffer(),
	c_SelectLineNumber(), c_Position(), c_HereToTop(),
	c_CaretToBottom(), c_CaretToTop(), c_WordWrap(),
	c_CharacterWrap(), c_Truncate(), c_UndoLast(),
	c_UndoAll(), c_RedoLast(), c_CopySelection(),
	c_CutSelection(), c_PasteSelection(), c_FindAndReplace(),
	c_FindForward(), c_FindBackward(), c_ReplaceExpand(),
	c_ReplaceNext(), c_ReplacePrevious(), c_LinesJustified(),
	c_LinesLeftFlush(), c_LinesRightFlush(), c_LinesCentered(),
	c_LinesLeftRight(), c_ShiftLines(),

	c_Quit(),

	filter_selection();

static struct cmds {
    char    *name;
    void    (*cmd)();
} cmds[] = {
    "LoadFile",	c_LoadFile,
    "SaveFile", c_SaveFile,
    "WriteFile", c_WriteFile,
    "SetDirectory", c_SetDirectory,
    "InsertFile", c_InsertFile,
    "EmptyBuffer", c_EmptyBuffer,

    "SelectLineNumber", c_SelectLineNumber,
    "Position", c_Position,
    "HereToTop", c_HereToTop,
    "CaretToTop", c_CaretToTop,
    "CaretToBottom", c_CaretToBottom,

    "WordWrap", c_WordWrap,
    "CharacterWrap", c_CharacterWrap,
    "Truncate", c_Truncate,

    "UndoLast", c_UndoLast,
    "UndoAll", c_UndoAll,
    "RedoLast", c_RedoLast,

    "CopySelection", c_CopySelection,
    "CutSelection", c_CutSelection,
    "PasteSelection", c_PasteSelection,

    "FindAndReplace", c_FindAndReplace,
    "FindForward", c_FindForward,
    "FindBackward", c_FindBackward,

    "ReplaceExpand", c_ReplaceExpand,
    "ReplaceNext", c_ReplaceNext,
    "ReplacePrevious", c_ReplacePrevious,

    "LinesJustified", c_LinesJustified,
    "LinesLeftFlush", c_LinesLeftFlush,
    "LinesRightFlush", c_LinesRightFlush,
    "LinesCentered", c_LinesCentered,
    "LinesLeftRight", c_LinesLeftRight,
 
    "ShiftLines", c_ShiftLines,

    "QUIT", c_Quit,	/* this is called from main menu, not ched menu */
    0
};

static void menu_callback();

menu_cmds_init()
{
    int	i, tag;

    for (i = 0; cmds[i].name != 0; i++) {
	tag = wire_AllocateTags(1);
	ps_ched_deftag(cmds[i].name, tag);
	if (tag_zero == -1)
	    tag_zero = tag;
	wire_RegisterTag(tag, menu_callback, NULL);
    }
    tag = wire_AllocateTags(1);
    ps_ched_deftag("FilterSelection", tag);
    wire_RegisterTag(tag, filter_selection, NULL);
}
	
extern JotView	*vw;

static void
menu_callback(tag)
int tag;
{
    int	    vid;

/*    ps_menu(&vid);
    v = JotView_View(wire_Current(), vid); */
    (*cmds[tag - tag_zero].cmd)(vw);
}

static void
c_LoadFile(v)
JotView	*v;
{
    map_popup("load");
}

static void
c_SaveFile(v)
JotView	*v;
{
    Buffer_SaveFile(View_Buffer(v));
}

static void
c_WriteFile(v)
JotView	*v;
{
    map_popup("save");
}

static void
c_InsertFile(v)
JotView	*v;
{
    map_popup("include");
}

static void
c_EmptyBuffer(v)
JotView	*v;
{
    JotText_Clear(v->text);
}

static void
c_SelectLineNumber(v)
JotView	*v;
{
    char    *lineno;
    Buffer  *b = View_Buffer(v);

    lineno = JotSelection_Contents(b->text, Jot_PRIMARY);
    if (lineno != 0) {
	int n, pos;

	if (!isdigit(*lineno))
	    signal_warning("Please select a number.");
	n = atoi(lineno);
	free(lineno);
	pos = JotText_ScanCharacter(b->text, 0, '\n', n - 1);
	JotText_SetCaret(b->text, pos + 1);
	Buffer_CaretVisible(b);
    }
}

static void
c_Position(v)
JotView	*v;
{
    JotText *t;
    int	    targetpos, pos, linenum;

    t = JotView_Text(v);
    targetpos = JotText_Caret(t);
    pos = -1;
    linenum = 0;
    do {
	linenum += 1;
	pos = JotText_ScanCharacter(t, pos + 1, '\n', 1);
	if (pos < 0)
	    break;
    } while (pos < targetpos);
    signal_warning("Caret is displayed on line %d.", linenum);
}

static void
c_CaretToTop(v)
JotView	*v;
{
    Buffer_ToTop(View_Buffer(v));
}

static void
c_CaretToBottom(v)
JotView	*v;
{
    Buffer_ToBottom(View_Buffer(v));
}

static void
c_HereToTop(v)
JotView	*v;
{
    JotView_ScrollAbsolute(v, JotText_Caret(JotView_Text(v)),
			   JotView_LinePosition(v, 1));
}

static void
c_WordWrap(v)
JotView	*v;
{
    JotView_SetLineStyle(v, FL_LEFTFLUSH);
}

static void
c_CharacterWrap(v)
JotView	*v;
{
    JotView_SetLineStyle(v, FL_CHARWRAP);
}

static void
c_Truncate(v)
JotView	*v;
{
    JotView_SetLineStyle(v, FL_CHARCHOP);
}

static void
c_UndoLast(v)
JotView	*v;
{
    (void) JotText_Undo(JotView_Text(v));
    Buffer_CaretVisible(View_Buffer(v));
}

static void
c_UndoAll(v)
JotView	*v;
{
    while (JotText_Undo(JotView_Text(v)))
	;
    Buffer_CaretVisible(View_Buffer(v));
}

static void
c_RedoLast(v)
JotView	*v;
{
    (void) JotText_Redo(JotView_Text(v));
    Buffer_CaretVisible(View_Buffer(v));
}

static void
c_CopySelection()
{
}

static void
c_CutSelection()
{
}

static void
c_PasteSelection()
{
}

static void
c_FindAndReplace()
{
}

static void
c_FindForward()
{
}

static void
c_FindBackward()
{
}

static void
c_ReplaceExpand()
{
}

static void
c_ReplaceNext()
{
}

static void
c_ReplacePrevious()
{
}

static void
c_LinesJustified(v)
JotView	*v;
{
    JotView_SetLineStyle(v, FL_JUSTIFIED);
}

static void
c_LinesLeftFlush(v)
JotView	*v;
{
    JotView_SetLineStyle(v, FL_LEFTFLUSH);
}

static void
c_LinesRightFlush(v)
JotView	*v;
{
    JotView_SetLineStyle(v, FL_RIGHTFLUSH);
}

static void
c_LinesCentered(v)
JotView	*v;
{
    JotView_SetLineStyle(v, FL_CENTERED);
}

static void
c_LinesLeftRight(v)
JotView	*v;
{
    JotView_SetLineStyle(v, FL_LEFTRIGHT);
}

static void
c_ShiftLines()
{
}

static void
c_Quit(v)
JotView	*v;
{
    Ched_Quit(v);
}

static void
c_SetDirectory(v)
JotView	*v;
{
    char    *dir;

    dir = JotSelection_Contents(JotView_Text(v), Jot_PRIMARY);
    if (dir != 0)
	Buffer_SetDirectory(View_Buffer(v), dir);
}

static void
filter_selection(tag)
int tag;
{
    int	    cv, p[2], pid, fd, pos, n;
    char    filter[512], buf[512], tmp[64];
    char    *template = "/tmp/jotXXXXXX";
    char    *shell;
    JotSpan *s;
    JotView *v;
    JotText *t;

    ps_filter(&cv, filter);
    v = JotView_View(wire_Current(), cv);
    if (JotView_ReadOnly(v)) {
	ring_bell();
	return;
    }
    t = JotView_Text(v);
    s = JotSelection_Span(t, Jot_PRIMARY);
    if (s == 0 || JotSpan_Text(s) != t) {
	ring_bell();
	return;
    }
    printf("Filtering selection through %s\n", filter);
    sprintf(tmp, template);
    mktemp(tmp);
    if ((fd = creat(tmp, 0600)) == -1) {
	printf("Couldn't create %s for filter.\n", tmp);
	return;
    }
    JotText_Write(t, JotSpan_Position(s), JotSpan_Length(s), fd);
    sprintf(buf, "%s < %s", filter, tmp);
    shell = getenv("SHELL");
    if (shell == 0)
	shell = "/bin/sh";
    if (pipe(p) == -1) {
	fprintf(stderr, "Pipe failed for filter.\n");
	return;
    }
    switch (pid = vfork()) {
    case -1:
	printf("Fork failed!\n");
	goto cleanup;

    case 0:
	close(p[0]);
	close(1);
	dup2(p[1], 1);
	close(p[1]);
	execl(shell, shell, "-c", buf, (char *) 0);
	fprintf(stderr, "Execl failed!\n");
	exit(-1);
    }
    close(p[1]);
    JotText_UndoBegin(t);
	pos = JotSpan_Position(s);
	JotSpan_DeleteContents(s);
	while ((n = read(p[0], buf, sizeof (buf))) > 0) {
	    JotText_InsertCharacters(t, pos, buf, n);
	    pos += n;
	}
    JotText_UndoEnd(t);
    while (wait(0) != pid)
	;
cleanup:
    unlink(tmp);
    close(p[0]);
}
