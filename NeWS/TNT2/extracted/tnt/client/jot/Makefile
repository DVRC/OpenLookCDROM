#	@(#)Makefile 1.34 91/02/20 Copyright 1990-91 Sun Microsystems
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

OPENWINHOME:sh	 = echo ${OPENWINHOME:-/usr/local/openwin}
PATH		+=:$(DESTDIR)/bin:$(OPENWINHOME)/bin

ALL_DEST	 = $(DESTDIR)/include/NeWS/jot $(DESTDIR)/lib \
			$(DESTDIR)/client/jot

TARGET = libjot.a

SRC = bytestring.c font.c text.c formatter.c styles.c view.c input.c \
	color.c span.c undo.c util.c selection.c search.c
CPSSRC = psinter.cps font_cps.cps color_cps.cps sel_cps.cps
CPSOBJ = ${CPSSRC:.cps=.o}
OBJ = ${SRC:.c=.o} $(CPSOBJ)
LOCALHEADERS = assert.h input.h
EXPORTHEADERS = bytestring.h cps.h font.h color.h styles.h \
	span.h text.h jot.h view.h font_cps.h color_cps.h jot_private.h \
	view_private.h undo.h selection.h search.h util.h
HEADERS = $(LOCALHEADERS) $(EXPORTHEADERS)

BACKUPS = $(SRC) $(HEADERS) Makefile

INCLUDES = -I. -I$(DESTDIR)/include -I$(OPENWINHOME)/include
LINTFLAGS = $(INCLUDES)

debug := DEBUG = -g -DDEBUG
opt := CFLAGS += -O2
profile := CFLAGS += -pg

INIT = psinter.h font_cps.h color_cps.h sel_cps.h $(HEADERS)

CFLAGS += ${INCLUDES} ${DEBUG} ${OPTIMIZE}

all:	NeWS $(TARGET)

.INIT: $(INIT)

NeWS:
	-ln -s .. NeWS

install debug opt profile : $(TARGET)

$(TARGET): $(OBJ)
	ar rv $(TARGET) $?
	ranlib $(TARGET)

lint:
	lint $(LINTFLAGS) $(SRC)

install_headers:	$(EXPORTHEADERS) $(DESTDIR)/include/NeWS/jot
	install -m 444 $(EXPORTHEADERS) $(DESTDIR)/include/NeWS/jot

install: install_headers $(TARGET) $(ALL_DEST)
	install -m 644 libjot.a $(DESTDIR)/lib
	ranlib -t $(DESTDIR)/lib/libjot.a
	install -m 444 $(HEADERS) $(SRC) $(CPSSRC) Makefile $(DESTDIR)/client/jot

$(ALL_DEST):	$(DESTDIR)
	-install -d -m 775 $@
	test -d $@

clean:
	rm -f $(OBJ) $(TARGET) psinter.c psinter.h *_cps.[ch]
	rm -f *~ %*% *%% *.BAK \#*\#

psinter.c + psinter.h : psinter.cps
	$(OPENWINHOME)/bin/cps -i psinter.cps

font_cps.h + font_cps.c : font_cps.cps
	$(OPENWINHOME)/bin/cps -i font_cps.cps

color_cps.h + color_cps.c : color_cps.cps
	$(OPENWINHOME)/bin/cps -i color_cps.cps

sel_cps.h + sel_cps.c : sel_cps.cps
	$(OPENWINHOME)/bin/cps -i sel_cps.cps

.KEEP_STATE:
