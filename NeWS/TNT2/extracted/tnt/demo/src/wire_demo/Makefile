#!/usr/bin/make
#
# @(#)Makefile 1.6 91/02/21 Copyright 1990-91 Sun Microsystems
#
# This file is a product of Sun Microsystems, Inc. and is provided for
# unrestricted use provided that this legend is included on all tape
# media and as a part of the software program in whole or part.  Users
# may copy or modify this file without charge, but are not authorized to
# license or distribute it to anyone else except as part of a product
# or program developed by the user.
#
# THIS FILE IS PROVIDED AS IS WITH NO WARRANTIES OF ANY KIND INCLUDING THE
# WARRANTIES OF DESIGN, MERCHANTIBILITY AND FITNESS FOR A PARTICULAR
# PURPOSE, OR ARISING FROM A COURSE OF DEALING, USAGE OR TRADE PRACTICE.
#
# This file is provided with no support and without any obligation on the
# part of Sun Microsystems, Inc. to assist in its use, correction,
# modification or enhancement.
#
# SUN MICROSYSTEMS, INC. SHALL HAVE NO LIABILITY WITH RESPECT TO THE
# INFRINGEMENT OF COPYRIGHTS, TRADE SECRETS OR ANY PATENTS BY THIS FILE
# OR ANY PART THEREOF.
#
# In no event will Sun Microsystems, Inc. be liable for any lost revenue
# or profits or other special, indirect and consequential damages, even
# if Sun has been advised of the possibility of such damages.
#
# Sun Microsystems, Inc.
# 2550 Garcia Avenue
# Mountain View, California  94043

# REMIND: Remove TNTHOME stuff when TNT V2 is merged into OPENWINHOME.

#
# If no DESTDIR was specified, use the TNTHOME environment variable.
DESTDIR:sh	= echo ${DESTDIR:-$TNTHOME}
ALL_DEST	= $(DESTDIR)/demo/bin $(DESTDIR)/demo/src/wire_demo


OPTIMIZE	= -g
INCLUDES	=-I. -I$(DESTDIR)/include -I$(OPENWINHOME)/include
CPPFLAGS	= $(CCDEFINES) $(INCLUDES) $(COMPILE_PS)
CFLAGS		= ${OPTIMIZE}
LDFLAGS		= $(STATIC) -L. -L$(DESTDIR)/lib -L$(OPENWINHOME)/lib
LDLIBS		= -lwire -lcps
CCPS		= $(DESTDIR)/bin/CPS

OBJ		= wire_demo.o wire_demo_cps.o

SCCS_SOURCES:sh	= echo SCCS/s.*
BACKUPS		= $(SCCS_SOURCES:SCCS/s.%=%)

%.c + %.h :	%.cps
	$(CCPS) -o functions $(CPSFLAGS) $*.cps

default:	all

all:		wire_demo

wire_demo:	$(BACKUPS) $(OBJ)
	$(LINK.c) -o $@ $(OBJ) $(LDLIBS)

wire_demo.o:		wire_demo.c wire_demo_cps.h

wire_demo_cps.o:	wire_demo_cps.c
	$(COMPILE.c) -c wire_demo_cps.c

clean:
	rm -f wire_demo*.o wire_demo_cps.h wire_demo_cps.c
	rm -f *~ *%% %*% *.BAK \#*\#

clobber:	clean
	rm -f wire_demo
	-sccs clean

install:	$(ALL_DEST) wire_demo
	install -m 775 wire_demo $(DESTDIR)/demo/bin
	install	-m 444 $(BACKUPS) $(DESTDIR)/demo/src/wire_demo

$(ALL_DEST):	$(DESTDIR)
	-install -d -m 775 $@
