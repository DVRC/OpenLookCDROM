/*
 *	@(#)view.h 1.28 91/02/20 Copyright 1990-91 Sun Microsystems
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

#ifndef _VIEW_INCLUDED_
#define _VIEW_INCLUDED_

#include <NeWS/c_varieties.h>
#include <NeWS/jot/text.h>
#include <NeWS/jot/view_private.h>
#include <NeWS/jot/selection.h>

typedef struct JotBoundingBox {
    int	x;
    int	y;
    int	width;
    int	height;
};

/* A view on a text. */

struct JotView {
    JotText	    *text;	/* the text being viewed */

    JotView	    *viewnext;
    JotView	    *viewprev;	/* the set of views on this text */
    JotView	    *allnext;
    JotView	    *allprev;	/* the set of all views */

    JotSpan	    *top;	/* the top of the view */
    int		    bottom;	/* last character visible in view */
    struct lineinfo *lineinfo;	/* the properties of each line on the screen */
    struct lineinfo *newinfo;	/* the properties of each line after updating */
    struct lineinfo *validinfo;	/* Either newinfo or lineinfo, depending on
				   which one was most recently formatted
				   into (partial updates vs. normal updates). */
    struct formatter_info defaultinfo;
				/* default info for the view */
    int		    width, height;
    struct {
	int left, right, top, bottom;
    } borders;
    struct {
	int xl, yb, xr, yt;
    } bbox;			/* bounding box of view (within canvas) */

    unsigned short  alines;	/* number of lines allocated in the view */
    unsigned short  vlines;	/* number of visible lines in view */

    /* various flags */
    unsigned	damagedonce:1;	/* cv been damaged yet? */
    unsigned    display_caret:1;/* true iff we should show caret */
    unsigned    modified:1;	/* true if view needs updating */
    unsigned	scrollable:1;	/* has scrollbar we have to update */
    unsigned	sbarwarp:1;	/* warp scrollbar on next update */
    unsigned	sbar_abs:1;	/* scrollbar motion was absolute */
    unsigned	readonly:1;	/* readonly textview => no caret displayed */
    unsigned	gotsetfont:1;	/* initial ps set font happened */
    unsigned	dontsetfont:1;	/* set font happened from C side, so ignore
				   initial ps set font */
    unsigned	constrain:1;	/* constrain text to view */
    int		frame_pos;	/* >= 0 means make that buffer position
				   visible after the next redisplay */
    short	frame_how;	/* how to make frame_pos visible is scrolling
				   is necessary */
    int		lasttextmodified; /* value of text's modified after last
				     redisplay */

    /* controllers */
    void	(*c_kbd)();	/* called when character is typed */
    void	(*c_mouse)();	/* called on mouse hits that aren't
				   selection events */
    boolean	(*c_sel_start)(); /* called when a request to begin a
				     a selection is made */
    void	(*c_sel_alter)(); /* called whenever a selection changes */

    wire_Wire	wire;		/* wire this view is on */
    short	viewport;	/* user token */
    long	client_data;	/* it's up to the client to decide */

    /* scrollbar info */
    struct {
	int	top;		/* value of top at last scrollbar update */
	int	bottom;		/* of bottom */
	int	size;		/* size of document */
    } scrollbar;

    /* highlighted regions (selections) */
    struct view_region	highlights[Jot_N_SELECTIONS];
    struct view_region	new_highlights[Jot_N_SELECTIONS];

    /* position of caret, when visible */
    struct view_coord	caret, new_caret;

    /* misc */
    fixed	lowest_y;	/* lowest value of Y that was drawn into,
				   the last time redisplay was called */
    struct color    *bgcolor;	/* background color */
    int		    xor_pixel;	/* xor color */
};

extern int  JotView_DirtyViews;
#define JotView_PendingUpdates()    (JotView_DirtyViews > 0)

#define JotView_Canvas(v)	    ((v)->viewport)
#define JotView_ConstrainText(v, b) ((v)->constrain = (b))
#define JotView_Data(v)		    ((v)->client_data)
#define JotView_Height(v)	    ((v)->bbox.yt - (v)->bbox.yb)
#define JotView_ReadOnly(v)	    ((v)->readonly)
#define JotView_ScrollAutomatic(v, c)	((v)->frame_how = (c))
#define JotView_SetData(v, data)    ((v)->client_data = (data))
#define JotView_Text(v)		    ((v)->text)
#define JotView_Width(v)	    ((v)->bbox.xr - (v)->bbox.xl)
#define JotView_Wire(v)		    ((v)->wire)

EXTERN_FUNCTION( boolean  JotView_BindViewToCanvas,	    (JotView* view, int canvas, wire_Wire wire));
EXTERN_FUNCTION( void	  JotView_BoundingBox,		    (JotView* view, JotBoundingBox* rectangle_ptr) );
EXTERN_FUNCTION( int	  JotView_Characters,		    (JotView* view) );
EXTERN_FUNCTION( boolean  JotView_EnsurePositionVisible,    (JotView* view, int pos) );
EXTERN_FUNCTION( void	  JotView_Free,			    (JotView* view) );
EXTERN_FUNCTION( void	  JotView_KeyboardDefault,	    (JotView* view, int ch) );
EXTERN_FUNCTION( boolean  JotView_LineBoundingBox,	    (JotView* view, JotBoundingBox* rectangle, int line) );
EXTERN_FUNCTION( int	  JotView_LineFromPosition,	    (JotView* view, int position) );
EXTERN_FUNCTION( int	  JotView_Lines,		    (JotView* view) );
EXTERN_FUNCTION( void	  JotView_MouseDefault,		    (JotView* view, int button, int action, int pos) );
EXTERN_FUNCTION( JotView *JotView_New,			    (JotText* text) );
EXTERN_FUNCTION( JotView *JotView_NewNoCanvas,		    (_VOID_) );
EXTERN_FUNCTION( boolean  JotView_ScrollRelative,	    (JotView* view, int units, int count) );
EXTERN_FUNCTION( int	  JotView_PositionFromLine,	    (JotView* view, int line) );
EXTERN_FUNCTION( int	  JotView_RelativeLineFromPosition, (JotView* view, int position) );
EXTERN_FUNCTION( void	  JotView_ScrollAbsolute,	    (JotView* view, int position, int y) );
EXTERN_FUNCTION( void	  JotView_SelectionAlterDefault,    (JotView* view, int rank) );
EXTERN_FUNCTION( boolean  JotView_SelectionStartDefault,    (JotView* view, int rank, int pos) );
EXTERN_FUNCTION( void	  JotView_SetControllers,
		(JotView*,
		 void	 (*)(JotView*, int),
		 void	 (*)(JotView*, int, int, int),
		 boolean (*)(JotView*, int),
		 void	 (*)(JotView*, int)) );
EXTERN_FUNCTION( void	  JotView_SetMargins, (JotView *view, int left, int right, int top, int bottom));
EXTERN_FUNCTION( void	  JotView_SetReadOnly,		    (JotView* view, boolean on_off) );
EXTERN_FUNCTION( void	  JotView_SetText,		    (JotView* view, JotText* t) );
EXTERN_FUNCTION( boolean  JotView_Update,		    (JotView* view) );
EXTERN_FUNCTION( void	  JotView_UpdateViews,		    (_VOID_) );
EXTERN_FUNCTION( JotView *JotView_View,			    (wire_Wire wire, int canvas) );
EXTERN_FUNCTION( void	  JotView_SetFont, (JotView *view, JotFont *font));

/* constants for the scrolling routines */
#define Jot_LINES   1
#define Jot_PAGES   2

/* mouse event actions */
#define Jot_BUTTONDOWN	    1
#define Jot_BUTTONUP	    2
#define Jot_MOUSEDRAGGED    3

/* mouse event buttons */
#define Jot_SELECTBUTTON    1
#define Jot_ADJUSTBUTTON    2

#endif
