/*
 *	@(#)colors.c 1.6 91/02/21 Copyright 1990-91 Sun Microsystems
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

#include <wire/wire.h>
#include <jot/cps.h>
#include <jot/view.h>
#include <jot/color.h>

struct style	style_gold, style_black, style_skyblue, style_blue,
		style_slateblue, style_gray, style_green, style_brown,
		style_cyan, style_turquoise, style_violet, style_white,
		style_yellow, style_orange, style_magenta, style_maroon,
		style_green, style_pink, style_red;

struct styled_color {
    char	    *name;
    unsigned char    h, s, b;
    struct style    *style;
} StyledColors[] = {
    "gold", 28, 255, 192, &style_gold,
    "black", 0, 0, 0, &style_black,
    "skyblue", 135, 255, 192, &style_skyblue,
    "blue", 171, 255, 255, &style_blue,
    "slateblue", 149, 255, 255, &style_slateblue,
    "gray", 0, 0, 127, &style_gray,
    "green", 85, 255, 255, &style_green,
    "brown", 7, 255, 192, &style_brown,
    "cyan", 128, 255, 255, &style_cyan,
    "turquoise", 128, 64, 255, &style_turquoise,
    "violet", 213, 130, 63, &style_violet,
    "white", 0, 0, 255, &style_white,
    "yellow", 43, 255, 255, &style_yellow,
    "orange", 7, 255, 192, &style_orange,
    "magenta", 213, 255, 255, &style_magenta,
    "maroon", 242, 194, 127, &style_maroon,
    "green", 85, 255, 255, &style_green,
    "pink", 0, 86, 192, &style_pink,
    "red", 0, 255, 255, &style_red,
    0
};

/* Initialize the colors by installing all the named colors into the
   color hash table.  This is called once for each wire.  color_create()
   is called every time.  That ensures that there is a color defined on
   the server for that color.  The style building is done only once. */
void
color_init()
{
    struct styled_color    *sc;
    struct color	    *c;
    struct style	    *s;

    for (sc = StyledColors; sc->name != 0; sc += 1) {
	c = color_create(sc->h, sc->s, sc->b);
	s = sc->style;

	style_Initialize(s, sc->name);
	style_Define(s, F_COLOR_H, M_REPLACE, (int) c->h,
			F_COLOR_S, M_REPLACE, (int) c->s,
			F_COLOR_B, M_REPLACE, (int) c->b,
			F_EOF);
    }
}

style_test(fp)
FILE	*fp;
{
    struct style    style;
    int		    i;

    while (!feof(fp)) {
	style_Read(&style, fp);
	style_Write(&style, stdout);
	fflush(stdout);
    }	
}
