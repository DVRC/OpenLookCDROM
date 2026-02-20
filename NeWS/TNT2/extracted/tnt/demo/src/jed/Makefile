#!/bin/make
#
#	@(#)Makefile 1.24 91/02/21 Copyright 1990-91 Sun Microsystems
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
#
# jed for tnt 2.0
#
# Expects OPENWINHOME to point to a valid OpenWindows release directory.
#
# Expects DESTDIR to point to the destination TNT release hierarchy.
#   If doing a make in place (no install), DESTDIR=$OPENWINHOME may be used.

LIBDIR		= $(DESTDIR)/lib
INCLUDES	= -I. -I$(DESTDIR)/include	\
		  -I$(DESTDIR)/include/NeWS -I${OPENWINHOME}/include
LINTFLAGS	= $(INCLUDES)
RELEASE		= -DRELEASE
CFLAGS	       += -O ${RELEASE} ${INCLUDES}

JEDSRC		= jed.c menu_cmds.c colors.c utils.c buffer.c keymap.c \
		  notice.c popups.c
JEDOBJ		= ${JEDSRC:.c=.o} 
HEADERS		= colors.h utils.h buffer.h keymap.h notice.h
CPSFILES	= jed_cps.cps notice_cps.cps popups_cps.cps
CPSOBJ		= ${CPSFILES:.cps=.o}
PSFILES		= jed.ps notice.ps popups.ps

ALL_DEST	= $(DESTDIR)/demo/bin $(DESTDIR)/demo/src/jed

BACKUPS = $(JEDSRC) $(HEADERS) $(CPSFILES) $(PSFILES) Makefile

all:	jed

jed: $(JEDOBJ) $(CPSOBJ)
	$(CC) -o jed ${CFLAGS} $(JEDOBJ) $(CPSOBJ) /usr/lib/debug/malloc.o \
		-L$(LIBDIR) -L$(OPENWINHOME)/lib -ljot -lcps -lwire

# Sun make complains about: 	%_cps.h + %_cps.c: %_cps.cps %.ps
# so we will sccs get all of the .ps files before any cps processing...
#
%.h + %.c: %.cps $(PSFILES)
	$(DESTDIR)/bin/CPS -i $(RELEASE) $*.cps


# Sun make doesn't provide transitive closure, so these files must
# appear in some target, even to get the default rules...
# There doesn't seem to be any to specify a generic rule to handle this.
#
jed_cps.o:	jed_cps.c jed_cps.h
notice_cps.o:	notice_cps.c notice_cps.h
popups_cps.o:	popups_cps.c popups_cps.h

buffer.o:	buffer.c buffer.h keymap.h utils.h
jed.o:		jed.c jed_cps.h keymap.h buffer.h
keymap.o:	keymap.c keymap.h colors.h buffer.h utils.h
menu_cmds.o:	menu_cmds.c keymap.h colors.h utils.h jed_cps.h buffer.h
notice.o:	notice.c keymap.h buffer.h notice_cps.h jed_cps.h
popups.o:	popups.c popups_cps.h buffer.h
utils.o:	utils.c jed_cps.h

install:	$(ALL_DEST) $(BACKUPS) jed 
	install -m 755 jed $(DESTDIR)/demo/bin
	install -m 444 $(BACKUPS) $(DESTDIR)/demo/src/jed

$(ALL_DEST):	$(DESTDIR)
	install -d -m 775 $@

clean:
	rm -f *.BAK *~ \#*\#
	rm -f $(JEDOBJ) $(CPSOBJ) $(CPSFILES:.cps=.c) $(CPSFILES:.cps=.h)

clobber:	clean
	sccs clean
	rm -f .make.state .nse_depinfo jed

backup:
	tar cf jed.tar $(BACKUPS)

tags:
	ctags *.[ch]
