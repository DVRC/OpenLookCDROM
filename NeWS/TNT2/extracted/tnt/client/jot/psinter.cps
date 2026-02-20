%	@(#)psinter.cps 1.28 91/02/20 Copyright 1990-91 Sun Microsystems
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

cdef ps_usecanvas(token canvas) canvas setcanvas
cdef ps_donecanvas() DONECV
cdef ps_makecanvas(index) index MKCV
cdef ps_keyboard(canvas, char) => (canvas, char)
cdef ps_scrollbar(canvas, motion, value) => (canvas, value, motion)
cdef ps_scrollinit(canvas, enabled) => (canvas, enabled)
cdef ps_stringinput(canvas, x, y, nbytes) => (canvas, x, y, nbytes)
cdef ps_set_font(wid, string name, int size, pmatch) => (wid, name, size, pmatch)
cdef ps_obsolete(wid) => (wid)
cdef ps_colors(cv) => (cv)
cdef ps_findselection(cv, rank, dir) => (cv, rank, dir)
cdef ps_undo(cv) => (cv)
cdef ps_redo(cv) => (cv)
cdef ps_selection_querystart(cv, fixed x, fixed y) => (cv, x, y)
cdef ps_mouse_event(cv, button, action, fixed x, fixed y) =>  (cv, button, action, x, y)

cdef ps_damage(canvas) => (canvas)
cdef ps_damagestart(token cv, int y1, y2, tag) => tag (y1, y2)
    /DamageStart cv send
cdef ps_reshape(cv, w, h) => (cv, w, h)
cdef ps_damageend(token cv) /DamageEnd cv send
cdef ps_erasecanvas(token cv) /EraseCanvas cv send

cdef ps_createtext(id)
    id /new ClassJotText send dup def

cdef ps_destroytext(token id)
    userdict id undef
    /destroy id send

cdef ps_deftag(string name, int value)
    name cvn value JotTags /wire_DefineTagInDict ClassWireClient send

cdef ps_startup()
    /JotTags growabledict def

    true setpacking

    /MKCV {	% token => -
	framebuffer /new ClassJotCanvas send	% token cv
	dup dup def exch			% cv token
	JotTags /initialize 4 -1 roll send	% -
    } def

    /MVR { % delta height ymin => -	Move a rectangle
	0 exch moveto 3000 exch rect 0 exch copyarea
    } def

    /SETSBAR { % vtop viewsize max jotcanvas => -
	/scrollbar get				% vtop vbot max sb
	/setparameters exch send
    } def

    /WSBAR { % canvas => - ; warp the scrollbar
	/scrollbar get 
	/warpcursor exch send
    } def

    /GETSEL { % rankno tag => -
	tagprint			    % rankno
	/RanknoToRank ClassJotCanvas send   % rank
	getselection dup null eq {	    % selection|null
	    pop -1 typedprint
	} {
	    /ContentsAscii /query 3 -1 roll send {
		dup length typedprint print
	    } {
		-1 typedprint
	    } ifelse
	} ifelse
    } def

cdef ps_cwidthshow(fixed x, cstring s) x 0 32 s widthshow
cdef ps_cashow(fixed x, cstring s) x 0 s ashow
cdef ps_cawidthshow(ch, fixed sp, cstring s) sp 0 32 ch 0 s awidthshow
cdef ps_showN(cstring s) s show
cdef ps_moverect(fixed ymin, fixed height, fixed delta) delta height ymin MVR
cdef ps_fmoveto(fixed x, fixed y) x y moveto
cdef ps_flineto(fixed x, fixed y) x y lineto
cdef ps_rectpath(fixed x, fixed y, fixed w, fixed h)
    x y w h rectpath

cdef ps_setscrollbar(token canvas, top, viewsize, max)
    top viewsize max canvas SETSBAR

cdef ps_warpsbar(token canvas)
    canvas WSBAR

cdef ps_setholder(token canvas, token holder)
    holder /setselectionholder canvas send

cdef ps_return_boolean(token client, int bool)
    bool 0 ne /wire_setreturnvalue client send

cdef ps_destroy(token obj)
     obj null def	% remove reference from user dict
    /destroy obj send

cdef ps_get_selection(rank, nbytes, tag) => tag (nbytes)
    rank tag GETSEL

cdef ps_beep() beep

cdef ps_setqueryselectionstart(token cv, bool)
    cv /QuerySelectionStart? bool 0 ne put

cdef ps_settrackable(token cv, bool)
    bool 0 ne /settrackable cv send
