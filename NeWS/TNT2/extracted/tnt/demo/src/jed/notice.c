/*
 *	@(#)notice.c 1.10 91/02/21 Copyright 1990-91 Sun Microsystems
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
#include <ctype.h>
#include <wire/wire.h>
#include <jot/jot.h>
#include <jot/view.h>
#include <jot/text.h>
#include <jot/font.h>
#include "keymap.h"
#include "buffer.h"
#include "notice_cps.h"
#include "jed_cps.h"

static void notice_callback();

static char notice_buttonstring[256];
static int  StopNotice = FALSE;
static int  ButtonCallbackTag = -1;
extern JotView  *vw;

int
Notice_New()
{
    int	notice;

    if (ButtonCallbackTag == -1) {
	ButtonCallbackTag = wire_AllocateTags(1);
	wire_RegisterTag(ButtonCallbackTag, notice_callback, NULL);
    }
    notice = wire_AllocateTokens(wire_Current(), 1);
    ps_make_notice(notice, View_Buffer(vw)->frame_id, ButtonCallbackTag);

    return notice;
}

Notice_SetButtons(n, buttons)
int n;
char	**buttons;
{
    int	i;

    for (i = 0; buttons[i] != 0; i++)
	ps_notice_addbutton(n, buttons[i]);
}

Notice_Ask(n, string)
int n;
char	*string;
{
    static int in_here = 0;
    JotText	    *t;

    if (in_here != 0) {
	ring_bell();
	return 0;
    }

    in_here = 1;

    ps_notice_settext(n, string);
    ps_notice_map(n);
    StopNotice = FALSE;
    while (wire_Notify(NULL)) {
	if (JotView_PendingUpdates())
	    JotView_UpdateViews();
	if (StopNotice)
	    break;
    }

    in_here = 0;
    return 1;
}

static void
notice_callback()
{
    wire_ReadString(notice_buttonstring);
    StopNotice = TRUE;
}

boolean
ask_yes_no(fmt, a1, a2, a3)
char	*fmt;
{
    static int	YesNoNotice = -1;
    char	string[512];
    static char	*buttons[] = {
	"No", "Yes", 0
    };
    char	*response;

    if (YesNoNotice == -1) {
	YesNoNotice = Notice_New();
	Notice_SetButtons(YesNoNotice, buttons);
    }

    sprintf(string, fmt, a1, a2, a3);

    Notice_Ask(YesNoNotice, string);
    return notice_buttonstring[0] == 'Y';
}

signal_warning(fmt, a1, a2, a3)
char	*fmt;
{
    static int	OKnotice = -1;
    char	    string[512], *response;
    static char	*buttons[] = {
	"Press To Continue", 0
    };

    if (OKnotice == -1) {
	OKnotice = Notice_New();
	Notice_SetButtons(OKnotice, buttons);
    }

    sprintf(string, fmt, a1, a2, a3);
    if (Notice_Ask(OKnotice, string) != 0)
	error();
}
