/*
 * @(#)help_file.c 1.4 91/02/21 Copyright 1990-91 Sun Microsystems
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

#include <stdio.h>
#include <sys/types.h>
#include <string.h>

#include "help_file.h"


static FILE    *help_file;
static char     help_buffer[128];

/*
 * Finds a keyword in the help file, determines if it is spot help or
 * more help; if more help, reads name of command to be executed,
 * otherwise positions file pointer to line following keyword
 */
static int
help_search_file(key, more_help)	
char           *key;	   /* Spot Help key */
char	  **more_help;     /* OUTPUT parameter: More Help system cmd */
{
    char           *entry;
    char	   *more_help_cmd;
    static char	    more_help_cmd_buffer[MAX_MORE_HELP_CMD];

    fseek(help_file, 0, 0);

    while (entry = fgets(help_buffer, sizeof(help_buffer), help_file))
	if (*entry++ == ':') {
	    entry = strtok(entry, ":\n");  /* parse Spot Help key */
	    if (entry && !strcmp(entry, key)) {
		/* Found requested Spot Help key */
		more_help_cmd = strtok(NULL, "\n"); /* parse More Help system
						     * command */
		if (more_help_cmd) {
		    strncpy(more_help_cmd_buffer, more_help_cmd,
			    MAX_MORE_HELP_CMD);
		    *more_help = &more_help_cmd_buffer[0];
		} else
		    *more_help = NULL;
		return HELPNOERR;
	    }
	}
    return HELPKEYNOTFND;
}

/*
 *  Locates a help file in $HELPPATH
 */
FILE * help_find_file(filename)
char	   *filename;
{
    FILE	   *file_ptr;
    char	   *helpdir = NULL;
    char	   *helppath;
    char	   *helppath_copy;

    helppath = (char *) getenv("HELPPATH");
    if (!helppath)
	helppath = DEFAULT_HELP_DIRECTORY;
    helppath_copy = (char *) malloc(strlen(helppath) + 1);
    strcpy(helppath_copy, helppath);
    helpdir = strtok(helppath_copy, ":");
    /* For a single path, just finds the null at the end
       of the string
       */
    do {
	sprintf(help_buffer, "%s/%s", helpdir, filename);
	if ((file_ptr = fopen(help_buffer, "r")) != NULL) {
	    break;
	}
    } while (helpdir=strtok(NULL, ":"));
    free(helppath_copy);
    return file_ptr;
}

/*
 *  Takes a filename:keyword string, and an optional "More help"
 *  string, and locates the file using help_find_file(), then
 *  positions the file pointer to the line following the keyword;
 *  returns HELPNOERR, HELPKEYNOTFND, HELPBADSYNTAX, or HELPFILENOTFND
 */
int help_get_arg(data, more_help)	
char           *data;	           /* "file:key" */
char	  **more_help;             /* OUTPUT parameter */
{
    char	    data_copy[64];
    char	   *filename;
    char	   *key;
    static char     last_filename[64];

    if (data == NULL)
	return HELPKEYNOTFND;	/* No key supplied */

    strncpy(data_copy, data, sizeof(data_copy));
    data_copy[sizeof(data_copy) - 1] = '\0';
    if (!(filename = strtok(data_copy, ":")) || 
	!(key = strtok(NULL, "")))
	return HELPBADSYNTAX;	               /* File or key missing */
    /* filename contains the name of the help file to search.
       key is the keyword
    */
    if (strcmp(last_filename, filename)) {
	/* Last  filename != new  filename */
	if (help_file) {
	    fclose(help_file);
	    last_filename[0] = '\0';
	}
	help_file = help_find_file(filename);
	if (help_file) {
	    strcpy(last_filename,filename);
	    return help_search_file(key, more_help);
	} else
	    return HELPFILENOTFND;
    }
    return (help_search_file(key, more_help));
}

/*  Gets a single line of help text from the help file. Ignores lines
    beginning with keywords (:blah) or # (comments).
    To be called repeatedly after keyword is found, until NULL returned.
*/
char * help_get_text()
{
    char *ptr = fgets(help_buffer, sizeof(help_buffer), help_file);

    return (ptr && *ptr != ':' && *ptr != '#' ? ptr : NULL);
}
