%/*
% * This file is a product of Sun Microsystems, Inc. and is provided for
% * unrestricted use provided that this legend is included on all tape
% * media and as a part of the software program in whole or part.  Users
% * may copy or modify this file without charge, but are not authorized to
% * license or distribute it to anyone else except as part of a product
% * or program developed by the user.
% * 
% * THIS FILE IS PROVIDED AS IS WITH NO WARRANTIES OF ANY KIND INCLUDING THE
% * WARRANTIES OF DESIGN, MERCHANTIBILITY AND FITNESS FOR A PARTICULAR
% * PURPOSE, OR ARISING FROM A COURSE OF DEALING, USAGE OR TRADE PRACTICE.
% * 
% * This file is provided with no support and without any obligation on the
% * part of Sun Microsystems, Inc. to assist in its use, correction,
% * modification or enhancement.
% * 
% * SUN MICROSYSTEMS, INC. SHALL HAVE NO LIABILITY WITH RESPECT TO THE
% * INFRINGEMENT OF COPYRIGHTS, TRADE SECRETS OR ANY PATENTS BY THIS FILE
% * OR ANY PART THEREOF.
% * 
% * In no event will Sun Microsystems, Inc. be liable for any lost revenue
% * or profits or other special, indirect and consequential damages, even
% * if Sun has been advised of the possibility of such damages.
% * 
% * Sun Microsystems, Inc.
% * 2550 Garcia Avenue
% * Mountain View, California  94043
% *
% * Copyright (c) 1990 by Sun Microsystems, Inc.
% *
% *   @(#)gaintool_cps.cps 1.5 91/02/11
% */


#if defined (COMPILE_POSTSCRIPT)
    cdef cps_startup(int tag) => tag ()
#include "gaintool.ps"
	tag tagprint
#endif


  cdef	cps_set_object (int tag, int tok, postscript obj)
      obj tok setfileinputtoken
      /client_tagnum tag /setproperty obj send


  cdef	cps_quit_gainWindow(token tok)
      /ConfirmedQuit tok send
    

  cdef	cps_open_windows()
      %
      % Activate all windows and open those mapped true
      %
      emgr /activate gainWindow send
      /map gainWindow send

      % We need to do a paint here so that the Pause/Resume button size
      % will be set before any attempt to change the text...
      /paint gainWindow send


  cdef cps_get_item_string(token Obj, int Index, string Val, int Tag)
      => Tag (Val)
      Tag tagprint
      /ItemList Obj send Index get getdisplaystring typedprint


  cdef cps_set_slider(token Obj, int Val)
      Val /setvalue Obj send


  cdef cps_set_choice(token Obj, int Val)
      [ Val ] /setvalue Obj send


  cdef cps_set_icon(token win, cstring bits)
      bits /seticonimage win send


  cdef cps_relabel_button (token Obj, string Val)
      % We should be able to do this with the /replaceitem method,
      % but that currently doesn't do quite the what we want with
      % respect to location, notifier, color overrides, etc.
      % 0 Val /replaceitem Obj send
      0 /Item Obj send /DisplayItem Val put

      % We initialized the button to be big enough for the longest
      % expected string, so we don't have to worry about resizing
      % or validating layout.
      
      % And repaint...
      /paint Obj send
