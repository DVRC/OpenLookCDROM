/*
 * @(#)helplib.c 1.3 91/02/21 Copyright 1990-91 Sun Microsystems
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
#include <stdlib.h>

#include <NeWS/wire/wire.h>
#include <NeWS/jot/text.h>
#include <NeWS/jot/view.h>
#include <NeWS/jot/font.h>
#include "helplib_cps.h"
#include "help_file.h"
#include "helplib.h"

static JotView * Help_Jotview;
static JotText * Help_Jottext;
static int Help_SpotHelpTag;
static int Help_MoreHelpTag;
static int Help_HelpWindowToken;
static int * Help_Tagptrs[3];
static int * Help_Tokenptrs[2];
static char MoreHelpCmdBuf[BUFSIZ];
static boolean  moreHelpWanted = FALSE;
static boolean Help_gettext();

void Help_Initialize( w )
wire_Wire w;
{

  wire_Wire current_wire;
  char openwinpath[BUFSIZ];
  static char helppath[BUFSIZ];
  char * tmp;

  if (!wire_Valid(w)) {
    fprintf(stderr, "Invalid wire passed to Help_Initialize: %d\n",w);
    exit(1);
  }
  
  /* Set up the wire, allocate tags and token, register callbacks */
  current_wire = wire_Current();
  wire_SetCurrent(w);
  Help_Tagptrs[0] = &Help_SpotHelpTag;
  Help_Tagptrs[1] = &Help_MoreHelpTag;
  Help_Tagptrs[2] = NULL;
  Help_Tokenptrs[0] = &Help_HelpWindowToken;
  Help_Tokenptrs[1] = NULL;
  wire_AllocateNamedTags(Help_Tagptrs);
  wire_AllocateNamedTokens(w, Help_Tokenptrs);
  wire_RegisterTag(Help_SpotHelpTag, Help_RequestHelpHandler,NULL);
  wire_RegisterTag(Help_MoreHelpTag, Help_MoreHelpHandler,NULL);

  /* Store some stuff into the server */
  cps_HelpDefineTag("SpotHelpTag", Help_SpotHelpTag);
  cps_HelpDefineTag("MoreHelpTag", Help_MoreHelpTag);
  cps_HelpDefineToken("HelpWindowToken", Help_HelpWindowToken);

  /* Set up HELPPATH */
  strcpy(helppath,"HELPPATH=.:");
  if(tmp =  (char *)getenv("OPENWINHOME")) {
    strcpy(openwinpath, tmp);
    strcat(openwinpath,"/lib/help");
    strcat(helppath, openwinpath);
  }
  if(tmp =  (char *)getenv("HELPPATH")) {
    strcat(helppath, ":");
    strcat(helppath, tmp);
  }
  putenv(helppath);

  /* Do Jot initialization */
  Jot_Initialize(w);
  Help_Jottext = JotText_New(1024);
  Help_Jotview = JotView_New(Help_Jottext);
  JotView_SetReadOnly(Help_Jotview, TRUE);

  wire_SetCurrent(current_wire);
}

void Help_RequestHelpHandler(tag, data)
int tag;
caddr_t data;
{ 
  char  keywordString[256];
  float X,Y;
  int exists, hascanvas;
  
  wire_ReadString(keywordString);
  X = wire_ReadFloat();
  Y = wire_ReadFloat();

  /* The help window for this connection may not have been created,
     or, it may have been destroyed, and recreated by a subsequent call
     to /HandleHelp, so we'll check to see if it exists, and add a Jot
     canvas as necessary
  */
  cps_HelpWindowExists(Help_HelpWindowToken,&exists,&hascanvas);
  if (!exists) return;  /* If we create one here, who is its
			   basewindow?
			*/
  if (!hascanvas) {
    /* The window was just created in the server, but we have to
       add a Jot canvas
    */
    cps_Help_AddJotCanvas(Help_HelpWindowToken,
			  JotView_Canvas(Help_Jotview));
  }

  /* Get the text and insert into Jot buffer */
  if(!Help_gettext(keywordString)) {
    fprintf(stderr, "Help text specified by %s not found\n", keywordString);
    cps_NoHelpNotice();
    return;
  }
  
  /* Send the cursor coordinates to the window */
  cps_SetMagnifierCoordinates(Help_HelpWindowToken,X,Y);

  /* Open the window (no effect if already open) */
  cps_OpenHelpWindow(Help_HelpWindowToken);
  JotView_Update(Help_Jotview);
  ps_flush_PostScript();
}

static boolean Help_gettext(filekeystring)
char * filekeystring;
{
  char * dummy = NULL;
  char ** moreHelpCmd = &dummy;
  char * line;
  int pos = 0;
  int nc;
  int hasbutton;

  /* REMIND: internationalization here */

  if (help_get_arg(filekeystring, moreHelpCmd) != HELPNOERR)
    return FALSE;
  cps_HasMoreHelpButton(Help_HelpWindowToken, &hasbutton);
  if (*moreHelpCmd != NULL)  {
    strcpy(MoreHelpCmdBuf, *moreHelpCmd);
    if (!hasbutton)
	cps_AddMoreHelpButton(Help_HelpWindowToken);
  } else {
    MoreHelpCmdBuf[0] = '\0';
    if (hasbutton)
      cps_RemoveMoreHelpButton(Help_HelpWindowToken);
  }

  JotText_Clear(Help_Jottext);
  while ( (line = help_get_text()) != NULL ) {
    nc = JotText_InsertString(Help_Jottext, pos, line);
    pos += nc;
  }
  return TRUE;
}
  
void Help_MoreHelpHandler(tag, data)
int tag;
caddr_t data;
{
  moreHelpWanted = TRUE;
}


void Help_UpdateView()
{
  if (JotView_PendingUpdates())
    JotView_Update(Help_Jotview);

  if (moreHelpWanted)  {
    system(&MoreHelpCmdBuf[0]);
    moreHelpWanted = FALSE;
  }
}
