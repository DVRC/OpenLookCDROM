There are some Makefiles with the LispView source release that refer to
the OPENWINHOME environment variable.  The present version of LispView is
based on OpenWindows 2.0, and $(OPENWINHOME)/include/ is assumed
to hold the OpenWindows 2.0 "include" files.  If you are just modifying Lisp
source code and not recompiling any foreign code, the build will not use
this variable.

If you are working with the foreign code, then you should have
OPENWINHOME set appropriately for your purposes.  The following files
refer to OPENWINHOME (you will probably need to modify the first of
these):
<lv-top-level-dir>/xview/Makefile -- explicitly sets OPENWINHOME to
	a path used on our local systems
<lv-top-level-dir>/xview/xloadimage/{Makefile.lispview, Makefile}
	-- use the OPENWINHOME environment variable

[Note: <lv-top-level-dir>/xview/Makefile also explicitly sets ARCH = sun4]
