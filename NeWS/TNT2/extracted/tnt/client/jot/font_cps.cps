%	@(#)font_cps.cps 1.12 91/02/20 Copyright 1990-91 Sun Microsystems
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

cdef ps_fontinit()
    /FontStyleDict dictbegin	% set of case-style statement-lists
	/6x10 {
	    /Default { /6x10 }
	} def

	/6x12 {
	    /Default { /6x12 }
	} def

	/6x13 {
	    /b { /6x13bold }
	    /Default { /6x13 }
	} def

	/AvantGarde-Book {
	    /i { /AvantGarde-BookOblique }
	    /Default { /AvantGarde-Book }
	} def

	/AvantGarde-Demi {
	    /i { /AvantGarde-DemiOblique }
	    /Default { /AvantGarde-Demi }
	} def

	/Bembo {
	    /b { /Bembo-Bold }
	    /bi { /Bembo-BoldItalic }
	    /i { /Bembo-Italic }
	    /Default { /Bembo }
	} def

	/Bookman-Demi {
	    /i { /Bookman-DemiItalic }
	    /Default { /Bookman-Demi }
	} def

	/Bookman-Light {
	    /i { /Bookman-LightItalic }
	    /Default { /Bookman-Light }
	} def
	
	/Boston {
	    /Default { /Boston }
	} def

	/Charter-Black {
	    /i { /Charter-Black-Italic }
	    /Default { /Charter-Black }
	} def

	/Charter-Roman {
	    /i { /Charter-Italic }
	    /Default { /Charter-Roman }
	} def

	/Courier {
	    /b { /Courier-Bold }
	    /bi { /Courier-BoldOblique }
	    /i { /Courier-Oblique }
	    /Default { /Courier }
	} def

	/GillSans {
	    /b { /GillSans-Bold }
	    /bi { /GillSans-BoldItalic }
	    /i { /GillSans-Italic }
	    /Default { /GillSans }
	} def

	/Helvetica {
	    /b { /Helvetica-Bold }
	    /bi { /Helvetica-BoldOblique }
	    /i { /Helvetica-Oblique }
	    /Default { /Helvetica }
	} def

	/Helvetica-Narrow {
	    /b { /Helvetica-Narrow-Bold }
	    /bi { /Helvetica-Narrow-BoldOblique }
	    /i { /Helvetica-Narrow-Oblique }
	    /Default { /Helvetica-Narrow }
	} def
	
	/Lucida-Bright {
	    /i { /Lucida-BrightItalic }
	    /bi { /Lucida-BrightDemiBoldItalic }
	    /b { /Lucida-BrightDemiBold }
	    /Default { /Lucida-Bright }
	} def

	/LucidaSans {
	    /b { /LucidaSans-Bold }
	    /bi { /LucidaSans-BoldItalic }
	    /i { /LucidaSans-Italic }
	    /Default { /LucidaSans }
	} def

	/LucidaSansTypewriter {
	    /b { /LucidaSansTypewriter-Bold }
	    /Default { /LucidaSansTypewriter }
	} def

	/NewCenturySchlbk {
	    /b { /NewCenturySchlbk-Bold }
	    /bi { /NewCenturySchlbk-BoldItalic }
	    /i { /NewCenturySchlbk-Italic }
	    /Default { /NewCenturySchlbk-Roman }
	} def

	/Palatino {
	    /b { /Palatino-Bold }
	    /bi { /Palatino-BoldItalic }
	    /i { /Palatino-Italic }
	    /Default { /Palatino-Roman }
	} def

	/Rockwell {
	    /b { /Rockwell-Bold }
	    /bi { /Rockwell-BoldItalic }
	    /i { /Rockwell-Italic }
	    /Default { /Rockwell }
	} def

	/Screen {
	    /b { /Screen-Bold }
	    /Default { /Screen }
	} def

	/Times {
	    /b { /Times-Bold }
	    /bi { /Times-BoldItalic }
	    /i { /Times-Italic }
	    /Default { /Times-Roman }
	} def

    dictend def

    /Ytransform { % Yvalue => Y pixel boundery
	0 exch dtransform round
	idtransform exch pop
    } def

    /locatefont { % name => -
	cvn {
	    findfont
	} stopped {
	    pop 0
	} {
	    pop 1
	} ifelse typedprint
    } def

    /assignfont { % token pmatched size name => -
	findfont /ModifyFont ClassDrawable send	    % t_id pmatched? size font
	exch scalefont				    % t_id pmatched? font
	exch printermatchfont			    % t_id font
	exch setfileinputtoken			    % -
    } def

    /uploadfont { % font => -
	begin
	    currentdict dup

	    fontheight Ytransform typedprint
	    fontdescent Ytransform typedprint
	    WidthArray dup length 2 idiv typedprint
	    aload length 2 idiv {
		pop typedprint	    % pop height send up width
	    } repeat
	end
    } def


cdef ps_locatefont(string name, int success, tag) => tag (success)
    tag tagprint
    name locatefont

cdef ps_assignfont(string name, size, pmatched, token_id)
    token_id pmatched 0 ne size name assignfont

cdef ps_uploadfont(token font, int length, fixed bbheight, fixed descent, int tag) => tag (bbheight, descent, length)
    tag tagprint
    font uploadfont

cdef ps_uploadfontfamilies(int nfamilies, tag) => tag (nfamilies)
    tag tagprint
    FontStyleDict dup length typedprint
    { pop 256 string cvs typedprint } forall

cdef ps_get_font_name(string family, string facecode, string buffer, int tag) => tag (buffer)
    FontStyleDict family get facecode cvn exch case
    tag tagprint 256 string cvs typedprint

cdef ps_getint(fixed x) => (x)
cdef ps_getstring(string s) => (s)
cdef ps_usefont(token font) font setfont
