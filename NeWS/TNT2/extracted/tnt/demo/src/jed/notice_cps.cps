%   @(#)notice_cps.cps 1.14 91/02/21 Copyright 1990-91 Sun Microsystems
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

cdef ps_make_notice(int token, token frame, int callbacktag)
    frame framebuffer /new ClassNotice send		    % N
    ChedEventMgr /activate 2 index send			    % N
    dup soften token setfileinputtoken			    % N
    /Calculated framebuffer /new ClassButtons send	    % N B
    {	% index buttongroup
	/close /Parent 2 index send send
	callbacktag tagprint /item exch send typedprint
    } /setnotifier 2 index send				    % N B
    /setbuttons 2 index send				    % N
    dup def

cdef ps_notice_map(token n)
    /buttons n send 0 0 /preferredsize 3 index send
    /reshape 6 -1 roll send
%    /basewindow n send /open n send
    [lasteventx lasteventy] /open n send

cdef ps_notice_unmap(token n)
    /close n send

cdef ps_notice_addbutton(token n, string buttonstring)
    dictbegin
	/invalidate n send
	/b /buttons n send def
	/itemcount b send 0 eq {
	    0 buttonstring [/West { /West PARENT POSITION } ]
		/insertitem b send
	    0 /setdefault b send
	} {
	    buttonstring [/West { /East PREVIOUS POSITION 10 0 xyadd } ]
		/appenditem b send
	} ifelse
    dictend

cdef ps_notice_settext(token n, string s)
    s /settext n send
