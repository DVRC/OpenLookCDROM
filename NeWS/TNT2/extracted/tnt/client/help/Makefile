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

# Makefile for libhelp.a

OPENWINHOME:sh	 = echo ${OPENWINHOME:-/usr/local/openwin}
PATH		+=:$(DESTDIR)/bin:$(OPENWINHOME)/bin

ALL_DEST	 = $(DESTDIR)/include/NeWS/help $(DESTDIR)/lib \
		   $(DESTDIR)/client/help

TARGET = libhelp.a

INCLUDES =-I. -I$(DESTDIR)/include -I$(OPENWINHOME)/include
CPPFLAGS = $(INCLUDES)
CCPS     = $(DESTDIR)/bin/CPS

EXPORTHEADERS	=	helplib.h
HEADERS		=	help_file.h helplib.h
SRC		=	helplib.c help_file.c
CPSSRC		=	helplib_cps.cps
OBJ		=	${SRC:.c=.o} ${CPSSRC:.cps=.o}


debug := DEBUG = -g -DDEBUG

CFLAGS += ${INCLUDES} ${DEBUG} ${OPTIMIZE}

all	debug : $(TARGET)

$(TARGET) 	: helplib.o helplib_cps.o help_file.o
	ar rcv libhelp.a helplib.o helplib_cps.o help_file.o
	ranlib libhelp.a

%.c + %.h :  %.cps
	$(CCPS) $(CPSFLAGS) -o portable $*.cps

helplib.o : helplib.c helplib_cps.h help_file.h
	$(COMPILE.c) $(CFLAGS) helplib.c -o $@

helplib_cps.o : helplib_cps.c
	$(COMPILE.c) $(CFLAGS) helplib_cps.c -o $@

help_file.o : help_file.c help_file.h
	$(COMPILE.c) $(CFLAGS) help_file.c -o $@

install_headers:	$(EXPORTHEADERS) $(DESTDIR)/include/NeWS/help
	install -m 444 $(EXPORTHEADERS) $(DESTDIR)/include/NeWS/help

install: install_headers $(TARGET) $(ALL_DEST)
	install -m 644 libhelp.a $(DESTDIR)/lib
	ranlib -t $(DESTDIR)/lib/libhelp.a
	install -m 444 $(HEADERS) $(SRC) $(CPSSRC) Makefile \
		 $(DESTDIR)/client/help

$(ALL_DEST):	$(DESTDIR)
	-install -d -m 775 $@
	test -d $@

clean:
	rm -f $(OBJ) $(TARGET) *_cps.[ch]
#	rm -f *~ %*% *%% *.BAK \#*\#
