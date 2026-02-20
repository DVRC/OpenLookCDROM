/*
 * Compile this with something like:
 * cc -c ol_pixmap_label.c -I/usr/local/openwin/include
 * Be sure to specify an OpenWindows Version 2 include directory here.
 */

#include <stdio.h>
#include <X11/Xlib.h>
#include "olgx_impl.h"
/*
 * This is what the above looks like in olgx/ol_button.c:
 * #include <olgx_private/olgx_impl.h>
 */
/*
 * Versions of olgx_impl.h and olgx.h [included by olgx_impl.h]
 * used in compiling this patch [3-dec-91]:
 * @(#) olgx_impl.h 1.11 90/10/26
 * @(#) olgx.h 1.31 90/10/22
 */

void
olgx_draw_pixmap_label(info, win, pix, x, y, width, height, state)
    Graphics_info  *info;
    Window          win;
    Pixmap          pix;
    int             x, y, width, height, state;
{


    unsigned long   savebg1;
    unsigned long   savebg2;
    Window              root;
    int                 x_dummy,y_dummy;
    unsigned int        w_dummy,h_dummy,bw_dummy;
    unsigned int        depth;


    if (!info->gc_rec[OLGX_TEXTGC]) {

	olgx_initialise_gcrec(info, OLGX_TEXTGC);
	/* The following added 2-dec-91 to make this patch compatible with
	 * LispView version of libolgx.
	 */
	if (!info->three_d)
	    olgx_initialise_gcrec(info, OLGX_TEXTGC_REV);
	
    }
    if ((state & OLGX_INVOKED) && (info->three_d)) {

	/*
	 * reset the value of the textgc background from bg1 to bg2 in
	 * invoked mode to get the transparent pixmap effect
	 */

	savebg1 = olgx_get_single_color(info, OLGX_BG1);
	savebg2 = olgx_get_single_color(info, OLGX_BG2);
	olgx_set_single_color(info, OLGX_BG1, savebg2, OLGX_SPECIAL);
    }
    /*
     * Performance Problem - RoundTrip request
     * Depth should be passed as part of Pixlabel struct
     */
 
    XGetGeometry(info->dpy,pix,&root,&x_dummy,&y_dummy,&w_dummy,
                 &h_dummy,&bw_dummy,&depth);
    if (depth > 1)
        XCopyArea(info->dpy,
                  pix,          /* src */
                  win,          /* dest */
                  info->gc_rec[OLGX_TEXTGC]->gc,
                  0, 0,         /* src x,y */
                  width, height,
                  x, y);
    else
	XCopyPlane(info->dpy,
		   pix,		/* src */
		   win,		/* dest */
		   info->gc_rec[OLGX_TEXTGC]->gc,
		   0, 0,		/* src x,y */
		   width, height,
		   x, y,
		   (unsigned long) 1);	/* bit plane */

    /* Restore the original colors to the textgc  */

    if ((state & OLGX_INVOKED) && (info->three_d))
	olgx_set_single_color(info, OLGX_BG1, savebg1, OLGX_SPECIAL);

}

void
olgx_draw_button(info, win, x, y, width, height, label, state)
    Graphics_info  *info;
    Window          win;
    int             x, y, width, height;
    void           *label;
    int             state;
{
    XTextItem       item;
    char            string[STRING_SIZE];
    short           add_ins[STRING_SIZE];
    register int    i;
    int             num_add;
    int             inside_width;	/* width minus endcaps */
    int             top_color, bottom_color, fill_color;


    inside_width = width - (2 * info->endcap_width);

    num_add = calc_add_ins(inside_width - 1, add_ins);
    item.nchars = 2 + num_add;
    item.font = None;
    item.chars = string;
    item.delta = 0;


    if (height)
	/* variable height button-- possibly a pixmap label */
	olgx_draw_varheight_button(info, win, x, y, width, height, state);

    else {
	if (info->three_d) {
	    /*
	     * 3d determine what colors we should draw in
	     */
	    if (state & OLGX_INVOKED) {	/* invoked button */
		top_color = OLGX_BG3;
		bottom_color = OLGX_WHITE;
		fill_color = OLGX_BG2;
	    } else if ((state & OLGX_DEFAULT) && (state & OLGX_MENU_ITEM)) {
		/* default menu item */
		top_color = bottom_color = OLGX_BLACK;
		fill_color = OLGX_BG1;
	    } else if (state & OLGX_MENU_ITEM && state & OLGX_BUSY) {
		/* busy menu item */
		fill_color = top_color = bottom_color = OLGX_BG1;
	    } else if (state & OLGX_MENU_ITEM) {
		/* normal menu item */
		fill_color = top_color = bottom_color = NONE;
	    } else {		/* normal panel button */
		top_color = OLGX_WHITE;
		bottom_color = OLGX_BG3;
		fill_color = OLGX_BG1;
	    }

	    if (state & OLGX_BUSY) {
		/*
		 * This routine changes GC information on-the-fly, but it is
		 * assumed that OLGX_BUSY won't be called often, so it makes
		 * sense to use the same GC rather than one for ` each color.
		 */
		if (!info->gc_rec[OLGX_BUSYGC])
		    olgx_initialise_gcrec(info, OLGX_BUSYGC);
		fill_color = OLGX_BUSYGC;
	    }
	    /* only check erase on transparent items */
	    if (fill_color == NONE) {
		if (state & OLGX_ERASE) {
		    /*
		     * to improve performance, we erase a rectangle the size
		     * of a button rather than drawing a real button.
		     */
		    XFillRectangle(info->dpy, win, info->gc_rec[OLGX_BG1]->gc, x, y,
				   width, Button_Height(info));
		}
	    } else {
		/* if not transparent, actually draw the button */


		if (top_color != NONE) {
		    /* draw the top part of the button */
		    string[0] = BUTTON_UL;
		    VARIABLE_LENGTH_MACRO(1, BUTTON_TOP_1);
		    string[i + 1] = BUTTON_UR;
		    XDrawText(info->dpy, win,
			      info->gc_rec[top_color]->gc, x, y, &item, 1);
		}
		if (bottom_color != NONE) {
		    /* draw the bottom part of the button */
		    string[0] = BUTTON_LL;
		    VARIABLE_LENGTH_MACRO(1, BUTTON_BOTTOM_1);
		    string[i + 1] = BUTTON_LR;
		    XDrawText(info->dpy, win,
			    info->gc_rec[bottom_color]->gc, x, y, &item, 1);
		}
		/* Fill in the button */
		string[0] = BUTTON_LEFT_ENDCAP_FILL;
		VARIABLE_LENGTH_MACRO(1, BUTTON_FILL_1);
		string[i + 1] = BUTTON_RIGHT_ENDCAP_FILL;
		XDrawText(info->dpy, win,
			  info->gc_rec[fill_color]->gc, x, y, &item, 1);

		/* draw the inner border of a default button (not menu item) */
		if (!(state & OLGX_MENU_ITEM) && (state & OLGX_DEFAULT)) {
		    string[0] = DFLT_BUTTON_LEFT_ENDCAP;
		    VARIABLE_LENGTH_MACRO(1, DFLT_BUTTON_MIDDLE_1);
		    string[i + 1] = DFLT_BUTTON_RIGHT_ENDCAP;
		    XDrawText(info->dpy, win,
			      info->gc_rec[OLGX_BLACK]->gc, x, y, &item, 1);
		}
	    }			/* Not transparent */
	}
	/* End 3D */
	else {			/* draw 2d button */

	    if (state & OLGX_ERASE)
		XFillRectangle(info->dpy, win, info->gc_rec[OLGX_WHITE]->gc, x, y,
			       width + 1, Button_Height(info));


	    if ((state & OLGX_INVOKED)) {
		string[0] = BUTTON_FILL_2D_LEFTENDCAP;
		VARIABLE_LENGTH_MACRO(1, BUTTON_FILL_2D_MIDDLE_1);
		string[i + 1] = BUTTON_FILL_2D_RIGHTENDCAP;
		XDrawText(info->dpy, win,
			  info->gc_rec[OLGX_BLACK]->gc, x, y, &item, 1);
	    } else if (state & OLGX_BUSY) {
		if (!info->gc_rec[OLGX_BUSYGC])
		    olgx_initialise_gcrec(info, OLGX_BUSYGC);
		string[0] = BUTTON_FILL_2D_LEFTENDCAP;
		VARIABLE_LENGTH_MACRO(1, BUTTON_FILL_2D_MIDDLE_1);
		string[i + 1] = BUTTON_FILL_2D_RIGHTENDCAP;
		XDrawText(info->dpy, win,
			  info->gc_rec[OLGX_BUSYGC]->gc, x, y, &item, 1);

	    } else if (!(state & OLGX_MENU_ITEM) && (state & OLGX_DEFAULT)) {
		/* draw the 2d default ring if not menu-item */
		string[0] = DFLT_BUTTON_LEFT_ENDCAP;
		VARIABLE_LENGTH_MACRO(1, DFLT_BUTTON_MIDDLE_1);
		string[i + 1] = DFLT_BUTTON_RIGHT_ENDCAP;
		XDrawText(info->dpy, win,
			  info->gc_rec[OLGX_BLACK]->gc, x, y, &item, 1);
	    } else if (state & OLGX_DEFAULT) {
		/* draw the 2d default ring for menu item */
		string[0] = MENU_DFLT_OUTLINE_LEFT_ENDCAP;
		VARIABLE_LENGTH_MACRO(1, MENU_DFLT_OUTLINE_MIDDLE_1);
		string[i + 1] = MENU_DFLT_OUTLINE_RIGHT_ENDCAP;
		XDrawText(info->dpy, win,
			  info->gc_rec[OLGX_BLACK]->gc, x, y, &item, 1);
	    }
	    /* draw the button if it is not a menu item */
	    if (!(state & OLGX_MENU_ITEM)) {
		string[0] = BUTTON_OUTLINE_LEFT_ENDCAP;
		VARIABLE_LENGTH_MACRO(1, BUTTON_OUTLINE_MIDDLE_1);
		string[i + 1] = BUTTON_OUTLINE_RIGHT_ENDCAP;
		XDrawText(info->dpy, win,
			  info->gc_rec[OLGX_BLACK]->gc, x, y, &item, 1);
	    }
	}
    }

    /*
     * Place the label, if specified.
     */
    if (label) {
	if (state & OLGX_LABEL_IS_PIXMAP) {
	    int             centerx, centery;

	    centerx = (width - ((Pixlabel *) label)->width >> 1);
	    centery = (height - ((Pixlabel *) label)->height >> 1);
	    olgx_draw_pixmap_label(info, win,
				   ((Pixlabel *) label)->pixmap,
				   x + ((centerx > 0) ? centerx : 0),
				   y + ((centery > 0) ? centery : 0),
				   ((Pixlabel *) label)->width,
			(height) ? ((Pixlabel *) label)->height : Button_Height(info) - 2, state);
	} else {
	    olgx_draw_text(info, win, (char *) label,
			   x + info->endcap_width,
			   y + info->button_height - info->base_off,
			   inside_width -
			   ((state & OLGX_MENU_MARK) ?
			    info->mm_width : 0),
			   state);
	}
    }
    /*
     * Place the menu mark, if desired.
     */
    if (state & OLGX_MENU_MARK) {
	/*
	 * draw the menu mark. (fill_color != OLGX_BG2) causes the menu mark
	 * to be filled in only when necessary
	 */
	if (info->three_d)
	    olgx_draw_menu_mark(info, win,
			  x + (width - info->endcap_width - info->mm_width),
				y + (info->button_height - info->mm_height -
				     info->base_off),
				state, (fill_color != OLGX_BG2));
	else
	    olgx_draw_menu_mark(info, win,
			  x + (width - info->endcap_width - info->mm_width),
				y + (info->button_height - info->mm_height -
				     info->base_off),
				state, 0);
    }
    /*
     * Mark the item as inactive, if specified
     */
    if (state & OLGX_INACTIVE) {
	olgx_stipple_rect(info, win, x, y, width, (height) ? height + 8 : Button_Height(info));
    }
}
