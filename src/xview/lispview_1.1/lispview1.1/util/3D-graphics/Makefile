# 	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
#	Sun design patents pending in the U.S. and foreign countries. 
#	See LEGAL_NOTICE file for terms of the license.
#
# Sun Common Lisp/XGL Library Interface
#
# Note: The interface-generating tool (etranslate.el) is not being distributed
# publicly because of an internal dependency.


# Sorry for wiring this next one in
ARCH = sun4

XGLUTDIR = $(XGLHOME)/demo/xgl
XGL_INC_DIR = $(XGLHOME)/include
WS_INC_DIR = $(OPENWINHOME)/include

WS_OPT = -DXVIEW -DNEW_XVIEW
CPPFLAGS = $(WS_OPT) -I$(WS_INC_DIR) -I$(XGL_INC_DIR) 
CFLAGS = -g ${FLOAT_TYPE} -fsingle

FILES_FOR_IMAGE = xgl.$(ARCH).o xgl-h.lisp xglut xglut/libxglut.a

all: $(FILES_FOR_IMAGE)

lisp-xgl: $(FILES_FOR_IMAGE)
	create-lisp-xgl

xgl.$(ARCH).o: xgl.c
	cc -c -I$(XGLHOME)/include xgl.c -o xgl.$(ARCH).o

xgl-h.lisp: include-xgl.h-gint
	include-xgl.h-gint > xgl-h.lisp   

xglut:
	mkdir xglut

xglut/libxglut.a: xglut
	cd xglut ;    \
	ln -s $(XGLUTDIR)/Makefile ;  \
	ln -s $(XGLUTDIR)/xglut* . ;  \
	make libxglut.a

include-xgl.h-gint: include-xgl.h-gint.c
	cc  $(CPPFLAGS) $(CFLAGS) include-xgl.h-gint.c -o include-xgl.h-gint

etranslate.elc: etranslate.el
	@echo "You have to byte compile etranslate.el!" ; exit 1

clean:
	rm -rf *.o include-xgl.h-gint xgl-h.lisp  *.sbin lisp-xgl \
	lisp-xgl-2.0.tar.Z \
	xglut

LISPFILES = build.lisp xgl.lisp foreign-c.lisp \
            other-xgl-stuff.lisp \
	    xgl-functions.lisp xgl-ut-functions.lisp

TARFILES = README Makefile \
	   create-lisp-xgl include-xgl.h-gint.c $(LISPFILES) xgl.c  \
	   polyhedra

lisp-xgl-2.0.tar.Z: $(TARFILES)
	tar cf - $(TARFILES) | compress >  lisp-xgl-2.0.tar.Z
