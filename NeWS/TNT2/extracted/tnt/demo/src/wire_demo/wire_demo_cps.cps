% @(#)wire_demo_cps.cps 1.6 91/02/21 Copyright 1990-91 Sun Microsystems
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

%
% Create the slider and position it at (x,y). Give it the standard
% height and make it "width" wide. The executable array is the
% slider's notify proc. In this case it simply tagprints the
% client tag, and typedprints its value.
%
% Note that the server_handle is passed in as an int because the
% usertoken hasn't been initialized yet.
%
cdef ps_create_slider(int client_handle, int quit_tag, int server_handle,
    int x, int y, int width)

    % Make a window with a calculated pane.
    /pan /Calculated framebuffer /new ClassPanel send def
    /win pan framebuffer /new ClassBaseWindow send def
    (Wire Service Demo) /setlabel win send
    (Value 10) (extends slider) /setfooter win send
    
    % Make a slider.
    /slider framebuffer /new ClassHSlider send def
    
    % Turn on the end boxes.  Don't bother with end labels.
    true /setendboxes slider send
    
    % Let's start out with a range of 0..20
    0 20 /setrange slider send
    
    % And let's set tic marks every two units.
    2 /settickmarks slider send

    % Make values integers.
    { round cvi } /setnormalizer slider send
    
    % Set up slider target, notifier, and previewer.
    win /settarget slider send
    
    { % Notifier:				% value slider
	client_handle tagprint
	1 index typedprint
	
	% Tell target (our window) to set its footer.
	exch (%) sprintf			% s (v)
	(Slider Notify) exch			% s (SN) (v)
	/setfooter /sendtarget 5 -1 roll	% (SN) (v) /sf /st s
	send					% -
    } /setnotifier slider send
    
    { % Previewer:				% value slider
	% Tell target (our window) to set its footer.
	exch (%) sprintf			% s (v)
	(Slider Preview) exch		% s (SN) (v)
	/setfooter /sendtarget 5 -1 roll	% (SN) (v) /sf /st s
	send				%
    } /setpreviewer slider send
    
    % Put the slider in the center of the panel.
    /slider slider [/Center {/Center PARENT POSITION}]
    /addclient pan send
    
    % Size it
    x y width /minsize slider send exch pop
    /reshape slider send
    
    /QuitFromUser { % CallingControl => -
	pop
	quit_tag tagprint
	/QuitFromUser super send
    } /installmethod win send

    % Reshape and activate the window.
    20 40 20 40 /setgaps win send
    /place win send
    /new ClassEventMgr send /activate win send
    /map win send

    % Now associate the server_handle token with the slider
    slider server_handle setfileinputtoken


%
% Grow the slider. Don't ask me why.
%
% Note that server_handle is declared as a token so that the usertoken
% lookup will be performed.
%
cdef ps_grow_slider(token server_handle, int delta)
    /bbox server_handle send
    exch delta add exch
    /reshape server_handle send

    /bbox win send  /preferredsize win send
    xymax /reshape win send
