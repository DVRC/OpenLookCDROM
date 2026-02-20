/*
 *	@(#)font.c 1.20 91/02/20 Copyright 1990-91 Sun Microsystems
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

#include <NeWS/wire/wire.h>
#include "assert.h"
#include "jot_private.h"
#include "jot.h"
#include "cps.h"
#include "styles.h"
#include "font.h"
#include "psinter.h"
#include "util.h"

struct font *current_font;

/* Fonts are stored in a font hash table.  A font is hashed on the
   name, and then the linear search checks the size and
   printermatched flag.  This should be changed later.  Anyway, a
   request can be made for a font explicitely, with JotFont_New()
   or with JotFont_FontFromFamily().  FontFromFamily() takes a
   family name, a facecode (italics, bold, etc) and point size and
   a printermatched.  That routine looks in the family structure
   to find out the name of the font which corresponds to the
   name/facecode pair, and then looks up in the normal font table
   for actual font.  This might be too slow.  We'll see. */

static char *fontdict_keynames[] = {
    "Default",
    "b",
    "i",
    "bi"
};

static int  locatefont_tag, uploadfont_tag;

static JotFontFamily    *fontfamilyroot = 0;

extern char *copystr();

JotFontFamily *
JotFont_FindFamily(name)
char	*name;
{
    JotFontFamily   *ff;

    for (ff = fontfamilyroot; ff != 0; ff = ff->next)
	if (strcmp(ff->name, name) == 0)
	    break;
    return ff;
}

JotFont *
JotFont_FontFromFamily(family, facecode, size, printermatch)
struct fontfamily   *family;
int		    facecode, size;
boolean		    printermatch;
{
    static int	tag = -1;
    JotFont	*font;
    char	fontnamebuf[256], *fontname;

    if (tag == -1)
	tag = wire_AllocateTags(1);
    font = family->fonts[facecode];
    if (font == 0) {		    /* go ask the server for the name */
	wire_DrainSync(wire_Current(), NULL);
	ps_get_font_name(family->name, fontdict_keynames[facecode],
			 fontnamebuf, tag);
	fontname = fontnamebuf;
    } else
	fontname = font->name;
    font = JotFont_New(fontname, size, printermatch);
    if (font == 0)
	printf("Error looking up font - family = %s, facecode = 0%o, font = %s\n",
	       family->name, facecode, fontname);
    else {
	font->family = family;
	if (family->fonts[facecode] == 0)
	    family->fonts[facecode] = font;
    }

    return font;
}

static
fontfamily_init()
{
    struct fontfamily	*ff;
    char		familyname[256];
    int			nfamilies;
    int			tag;

    wire_DrainSync(wire_Current(), NULL);
    tag = wire_AllocateTags(1);
    ps_uploadfontfamilies(&nfamilies, tag);
    while (--nfamilies >= 0) {
	ps_getstring(familyname);
	ff = (struct fontfamily *) malloc(sizeof *ff);
	bzero((char *) ff, sizeof *ff);
	ff->name = copystr(familyname);
	ff->next = fontfamilyroot;
	fontfamilyroot = ff;
    }
}

#define HASHSIZE    128

static JotFont	*font_hashtable[HASHSIZE];

static int
fontname_hash(s)
register char	*s;
{
    register int    c, hashval = 0;

    while (c = *s++)
	hashval = (hashval >> 2) + c;

    return hashval % HASHSIZE;
}

JotFont *
JotFont_Lookup(name, size, pmatched)
register char	    *name;
register int	    size;
register boolean    pmatched;
{
    register JotFont	*font;
    int			hashval;

    hashval = fontname_hash(name);
    for (font = font_hashtable[hashval]; font != 0; font = font->next)
	if (font->size == size && font->pmatched == pmatched &&
	    strcmp(font->name, name) == 0)
	    break;
    return font;
}

JotFont *
JotFont_New(name, size, pmatched)
char	*name;
int	size, pmatched;
{
    struct fontfamily	*ff;
    JotFont		*font;
    wire_Wire		wire;

    font = JotFont_Lookup(name, size, pmatched);
    wire = wire_Current();
    if (font == 0 || wire_RetrieveToken(&font->tokens, wire) == -1) {
	int	    i, nbytes, token, hashval, length, success;
	fixed	    bbheight, descent;

	wire_DrainSync(wire, NULL);
	ps_locatefont(name, &success, locatefont_tag);
	if (success == FALSE)
	    return 0;
	token = wire_AllocateTokens(wire, 1);
	ps_assignfont(name, size, pmatched, token);

	ps_uploadfont(token, &length, &bbheight, &descent, uploadfont_tag);

	nbytes = sizeof(struct font) + length * sizeof (font->width[0])
		+ strlen(name) + 1;
	font = (struct font *) jot_alloc(nbytes);
	if (font == 0)
	    return_error((JotFont *) 0, Jot_Errno);

	bzero((char *) font, sizeof (struct font));
	font->size = size;
	font->pmatched = pmatched;
	font->nchars = length;
	font->name = (char *) &font->width[font->nchars];
	strcpy(font->name, name);
	font->bbheight = bbheight;
	font->descent = descent < 0 ? -descent : descent;
	font->ascent = font->bbheight - font->descent;
	for (i = font->nchars; --i >= 0; )
	    ps_getint(&font->width[i]);

	hashval = fontname_hash(name);
	font->next = font_hashtable[hashval];
	font_hashtable[hashval] = font;

	wire_RememberToken(&font->tokens, wire, token);
    }
    return font;
}	

/* don't do anything for now */
void
JotFont_Free(f)
JotFont	*f;
{
}

void
font_init()
{
    locatefont_tag = wire_AllocateTags(2);
    uploadfont_tag = locatefont_tag + 1;
    ps_fontinit();
    fontfamily_init();
}
