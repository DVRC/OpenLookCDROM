# @(#)Makefile 1.34 91/02/21 Copyright 1990-91 Sun Microsystems
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

INCLUDES = -I. -I$(DESTDIR)/include -I$(OPENWINHOME)/include
DEFINES	 = 

SCCS_ARCH:sh	= ls SCCS/s.*
SCCS_FILES	= ${SCCS_ARCH:SCCS/s.%=%}

ALL_DEST	= $(DESTDIR)/lib $(DESTDIR)/include/NeWS/wire $(DESTDIR)/client/wire

.INIT:	$(SCCS_FILES)

TARGET = libwire.a

CFILES = connection.c error.c synch.c tag.c token.c util.c
	
CPSFILES = synch_cps.cps connection_cps.cps

PUBLICHEADERS = wire.h wire_types.h
PRIVATEHEADERS = wire_private.h
	
OBJS = 		${CFILES:.c=.o}
CPS_OUT_FILES =	${CPSFILES:.cps=.h}

CFLAGS	+= -O $(INCLUDES) $(DEFINES)

all:	NeWS $(TARGET)

NeWS:
	-ln -s .. NeWS

$(TARGET): $(OBJS)
	ar rv $(TARGET) $?
	ranlib $(TARGET)
	
install_headers: $(SCCS_FILES) $(DESTDIR)/include/NeWS/wire
	install -m 444 $(PUBLICHEADERS) $(DESTDIR)/include/NeWS/wire

install: $(SCCS_FILES) install_headers $(TARGET) $(ALL_DEST)
	install -m 644 $(TARGET) $(DESTDIR)/lib
	ranlib -t $(DESTDIR)/lib/$(TARGET)
	install -m 444 Makefile $(CFILES) $(CPSFILES) $(PUBLICHEADERS) \
		$(PRIVATEHEADERS) Makefile $(DESTDIR)/client/wire

$(ALL_DEST):	$(DESTDIR)
	-install -d -m 775 $@
	test -d $@

clean:
	rm -f $(OBJS) *~ %*% *%% *.BAK \#*\#

clobber:	clean
	rm -f $(TARGET)
	-sccs clean

lint:
	lint $(INCLUDES) *.c

tags:
	ctags *.[ch]
	
synch_cps.h: synch_cps.cps
	$(OPENWINHOME)/bin/cps synch_cps.cps

connection_cps.h: connection_cps.cps
	$(OPENWINHOME)/bin/cps connection_cps.cps

connection.o:	connection.c connection_cps.h

synch.o:	synch.c synch_cps.h

.KEEP_STATE:
