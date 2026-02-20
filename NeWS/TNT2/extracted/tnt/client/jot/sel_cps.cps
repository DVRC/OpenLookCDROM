%	@(#)sel_cps.cps 1.12 91/02/20 Copyright 1990-91 Sun Microsystems
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

cdef ps_selection_initiate(int canvas, mousebutton, rank, level, pd, style, fixed x, fixed y) =>
     (canvas, mousebutton, rank, level, pd, style, x, y)
cdef ps_selection_adjust(fixed x, fixed y) => (x, y)
cdef ps_deselect(rank) => (rank)
cdef ps_contentsascii(canvas, rank) => (canvas, rank)
cdef ps_deleteselection(canvas, rank) => (canvas, rank)
cdef ps_insertion_point(canvas, rank, fixed x, fixed y, where) => (canvas, rank, x, y, where)
cdef ps_inselection(cv, rank, fixed x, fixed y) => (cv, rank, x, y)

cdef ps_selection_startup()
    /CRT {	% draw caret: x y CRT => -
	moveto 5 -8 rlineto -10 0 rlineto /fill XOR-op
    } def

    % Invalidate the selection of the specified rank.  This is possibly
    % called when there is no selection of that rank (in the case of a
    % secondary selection ... the selection is gone by the time the client
    % side gets around to invalidating it), or the selection has been
    % transfered to someone else, which doesn't know how to invalidate
    % itself.  So this only does something if the selection exists and
    % it understands the /invalidate message.  REMIND: This seems a little
    % hokey.
    /IVS { % rank => -
	/RanknoToRank ClassJotCanvas send
	getselection dup null ne {
	    dup /invalidate /understands? 3 -1 roll send {
		/invalidate exch send
	    } {
		pop
	    } ifelse
	} {
	    pop
	} ifelse
    } def

    /XOR-op {  % op => - ; execute OP with XOR as current raster op
	currentrasteropcode		    % op <rop-code>
	    6 setrasteropcode exch 	    % <rop-code> op
	    cvx exec			    % <rop-code>
	setrasteropcode			    % 
    } def	

cdef ps_setpixel(int pixel) pixel setpixel
cdef ps_caretat(fixed x, fixed y) x y CRT
cdef ps_sel_fill() /fill XOR-op
cdef ps_sel_stroke() /stroke XOR-op

cdef ps_sendcontentsascii(token canvas, cstring contents)
    contents /ReceiveContentsAscii canvas send

cdef ps_own_selection(token holder, rank)
    rank /OwnSelection holder send

cdef ps_invalidate_selection(rank) rank IVS

cdef ps_clear_selection(rank)
    rank /RanknoToRank ClassJotCanvas send clearselection
