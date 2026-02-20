/*
 *	@(#)popups.c 1.4 91/02/21 Copyright 1990-91 Sun Microsystems
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

#include <sys/types.h>
#include <strings.h>
#include <stdio.h>
#include <NeWS/wire/wire.h>
#include <NeWS/jot/view.h>
#include "popups_cps.h"
#include "buffer.h"

static void
build_filename(ctlname, buffer)
char	*ctlname, *buffer;
{
    static int	tag = -1;
    char    dir_ctl[64], file_ctl[64], dir_name[256], file_name[128];

    if (tag == -1)
	tag = wire_AllocateTags(1);

    sprintf(dir_ctl, "%s_directory", ctlname);
    sprintf(file_ctl, "%s_file", ctlname);
    cps_gettext(dir_ctl, dir_name, tag);
    cps_gettext(file_ctl, file_name, tag);
    if (dir_name[0] == '\0')
	strcpy(dir_name, ".");
    if (file_name[0] == '/')
	strcpy(buffer, file_name);
    else
	sprintf(buffer, "%s/%s", dir_name, file_name);
}

static void
load_file(tag, data)
{
    extern JotView  *vw;
    char	    filename[256];

    build_filename("load", filename);
    Buffer_LoadFile(View_Buffer(vw), filename);
    cps_maybeunmap("load_popup");
}

static void
save_file(tag, data)
{
    extern JotView  *vw;
    char	    filename[256];

    build_filename("save", filename);
    Buffer_ConfirmWrite(View_Buffer(vw), filename);
    (void) Buffer_WriteFile(View_Buffer(vw), filename, TRUE);
    Buffer_SetFileName(View_Buffer(vw), filename);
    cps_maybeunmap("save_popup");
}

static void
include_file(tag, data)
{
    extern JotView  *vw;
    char	    filename[256];

    build_filename("save", filename);
    Buffer_InsertFile(View_Buffer(vw), filename);
    cps_maybeunmap("include_popup");
}


load_popups()
{
    static int	beenhere = FALSE;
    int		tags;

    if (!beenhere) {
	extern JotView  *vw;
	Buffer  *b;

	cps_load_popups();
	beenhere = TRUE;
	tags = wire_AllocateTags(3);
	cps_setnotifier("load_button", tags);
	cps_setnotifier("load_file", tags);
	cps_setnotifier("save_button", tags + 1);
	cps_setnotifier("save_file", tags + 1);
	cps_setnotifier("include_button", tags + 2);
	cps_setnotifier("include_file", tags + 2);
	wire_RegisterTag(tags, load_file, NULL);
	wire_RegisterTag(tags + 1, save_file, NULL);
	wire_RegisterTag(tags + 2, include_file, NULL);

	b = View_Buffer(vw);
	if (b->directory != 0) {
	    cps_settext("load_directory", b->directory);
	    cps_settext("save_directory", b->directory);
	    cps_settext("include_directory", b->directory);
	}
    }
}

map_popup(name)
char	*name;
{
    char    ctlname[64];

    load_popups();
    sprintf(ctlname, "%s_popup", name);
    cps_map(ctlname);
    sprintf(ctlname, "%s_directory", name);
}
