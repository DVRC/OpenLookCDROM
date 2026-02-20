# Sun Common Lisp/XView Library Interface
#
#	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
#	Sun design patents pending in the U.S. and foreign countries.
#	See LEGAL_NOTICE file for terms of the license.
#

OPENWINHOME = /usr/local/openwin
CFLAGS = -O -I$(OPENWINHOME)/include/ 
ARCH = sun4

all: macros.$(ARCH).o 
	
macros.$(ARCH).o: macros.c
	cc $(CFLAGS) -c macros.c
	mv macros.o macros.$(ARCH).o

