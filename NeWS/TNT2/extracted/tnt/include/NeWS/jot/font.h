/*
 *	@(#)font.h 1.17 91/02/20 Copyright 1990-91 Sun Microsystems
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

#include <NeWS/c_varieties.h>

#include <NeWS/jot/font_cps.h>

struct fontfamily {
    struct fontfamily	*next;
    char		*name;			/* family name */
    JotFont		*fonts[N_FACECODES];	/* a sample font per facecode */
};

typedef struct fontfamily   JotFontFamily;

EXTERN_FUNCTION( struct fontfamily    *JotFont_FindFamily, (char *name) );

#define fontfamily_Name(ff) ((ff)->name)

struct font {
    struct fontfamily	*family;
    struct font	*next;	/* next in chain */
    char    *name;	/* font name */
    int	    facecode;	/* FC_ROMAN, FC_BOLD, FC_ITALIC, FC_BOLDITALIC */
    int	    size;	/* size in points */
    fixed   bbheight;	/* height from highest ascender to lowest descender */
    fixed   descent;	/* distance from lowest descender to baseline */
    fixed   ascent;	/* distance from baseline to highest ascender */
    unsigned short nchars;	/* The number of characters in the font */
    char    pmatched;	/* is the font printermatched? */
    wire_TokenArray tokens;	/* server token values (one per wire) */
    fixed   width[1];	/* The array of widths */
};

EXTERN_FUNCTION( JotFont	*JotFont_New,	(char *name, int size, int matched) );
EXTERN_FUNCTION( void		 JotFont_Free,	(JotFont font) );
EXTERN_FUNCTION( JotFont	*JotFont_FontFromFamily,
		(JotFontFamily *family, int facecode, int size, boolean pm));

extern JotFont	*current_font;

#define font_usefont(f, w) \
    (((f) != current_font) ? \
     (current_font = (f), \
      ps_usefont(wire_RetrieveToken(&(f)->tokens, (w)))) : \
     0)

#define Font_Width(f, c)    floorfr((f)->width[(c)])
#define Font_Height(f)	    floorfr((f)->bbheight)
