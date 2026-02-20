% @(#)synch_cps.cps 1.11 91/02/21 Copyright 1990-91 Sun Microsystems
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

cdef ps_initsync(tag)
	/wire_SyncTag tag def
	/wire_Listener [ currentprocess dup /Stdout get ] def

cdef ps_wakesync(int id)
	id wire_SyncWake

cdef ps_startsync()
	wire_SyncStart

cdef ps_endsync()
	wire_SyncEnd wire_SyncFinal

cdef ps_bindoverride()
	currentprocess /wire_OverrideLevel 2 copy known {
	    % nested overrides; increment number of levels
	    2 copy get 2 add
	} {
	    % first level override; set even/odd to show original state
	    currentprocess /BindOverride 2 copy get 3 1 roll true put
	    1 2 ifelse
	} ifelse			% process /w_OL level
	put

cdef ps_bindrestore()
	currentprocess /wire_OverrideLevel 2 copy get 2 sub
	dup 0 le {
	    % restoring original state; -1 => true, 0 => false
	    currentprocess /BindOverride 3 -1 roll 0 ne put
	    undef
	} {
	    % undoing only one of multiple nested overrides
	    put
	} ifelse

cdef ps_getsyncID(int id) => (id)

cdef ps_expectedsyncdone(wire, tag)
	tag tagprint
	wire typedprint
