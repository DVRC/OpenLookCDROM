% @(#)helplib_cps.cps 1.5 91/02/21 Copyright 1990-91 Sun Microsystems
%
% This file is a product of Sun Microsystems, Inc. and is provided for
% unrestricted use provided that this legend is included on all tape
% media and as a part of the software program in whole or part.  Users
% may copy or modify this file without charge, but are not authorized to
% license or distribute it to anyone else except as part of a product
% or program developed by the user.
%
% THIS FILE IS PROVIDED AS IS WITH NO WARRANTIES OF ANY KIND INCLUDING THE
% WARRANTIES OF DESIGN, MERCHANTIBILITY AND FITNESS FOR A PARTICULAR
% PURPOSE, OR ARISING FROM A COURSE OF DEALING, USAGE OR TRADE PRACTICE.
%
% This file is provided with no support and without any obligation on the
% part of Sun Microsystems, Inc. to assist in its use, correction,
% modification or enhancement.
%
% SUN MICROSYSTEMS, INC. SHALL HAVE NO LIABILITY WITH RESPECT TO THE
% INFRINGEMENT OF COPYRIGHTS, TRADE SECRETS OR ANY PATENTS BY THIS FILE
% OR ANY PART THEREOF.
%
% In no event will Sun Microsystems, Inc. be liable for any lost revenue
% or profits or other special, indirect and consequential damages, even
% if Sun has been advised of the possibility of such damages.
%
% Sun Microsystems, Inc.
% 2550 Garcia Avenue
% Mountain View, California  94043

    
#define SYNCTAG 0

cdef cps_HelpDefineTag(string tagname, int tagnum)
    tagname cvn tagnum def

cdef cps_HelpDefineToken(string tokenname, int tokennum)
    tokenname cvn tokennum def

cdef cps_Help_AddJotCanvas(token window, token canvas)
    canvas /addJotCanvas window send

cdef cps_NoHelpNotice()
    /NoHelp where {
	begin NoHelp end				% notice
    } {
    	null framebuffer /new ClassNoHelpNotice send	% notice
	/NoHelp 1 index def				% notice
	/text 1 index send				% notice string
	[exch (Message lookup failed)]			% notice [str str]
	/settext 2 index send				% notice
    } ifelse						% notice
    /triggered? MenuService send {
	/CancelNotify MenuService send
    } if
    null /open 2 index send				% notice
    /new ClassEventMgr send /activate 3 -1 roll send

cdef cps_SetMagnifierCoordinates(token window,float X,float Y)
    X Y /showmagnify window send

cdef cps_OpenHelpWindow(token window)
    /triggered? MenuService send {
	/CancelNotify MenuService send
    } if
    /open window send

cdef cps_AddMoreHelpButton(token window)
    /addMoreHelpButton window send

cdef cps_RemoveMoreHelpButton(token window)
    /removeMoreHelpButton window send

cdef cps_HasMoreHelpButton(token window, int result) => SYNCTAG(result)
    /MoreHelpButton? window send
    {1} {0} ifelse
    SYNCTAG tagprint
    typedprint

cdef cps_HelpWindowExists(int tk,int exists,int can) => SYNCTAG(exists,can)
    tk getfileinputtoken dup null eq {
	pop 0 0
    } {	      	    	    	    	    	% help-window
	/jotadded? exch send {
	    1 1
	} {
	    0 1
	} ifelse
    } ifelse
    SYNCTAG tagprint
    typedprint
    typedprint
