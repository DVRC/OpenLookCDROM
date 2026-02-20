%   @(#)jed_cps.cps 1.16 91/02/21 Copyright 1990-91 Sun Microsystems
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

cdef ps_initcanvas(token cv, int win)
    win cv INITC
    ChedMenu /setmenu cv send

cdef ps_set_preferred_size(token cv, width, height)
    /preferredsize { width height } /installmethod cv send

cdef ps_place_frame(token frame)
    /place frame send

cdef ps_map_frame(token frame)
    /validate frame send
    /map frame send    

cdef ps_newlinestyle(style) => (style)

cdef ps_ched_deftag(string name, value)
    name cvn value ChedDefTag

cdef ps_menu(cv) => (cv)

cdef ps_filter(cv, string cmd) => (cv, cmd)

cdef ps_frame_label(token frame, string label)
    label /setlabel frame send

cdef ps_frame_footer(token frame, string left, string right)
    left right /setfooter frame send

cdef ps_icon_label(token frame, string label)
    label /seticonlabel frame send

cdef ps_initialize()
#   include "jed.ps"

cdef ps_bell() beep
