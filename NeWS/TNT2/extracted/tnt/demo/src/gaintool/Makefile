#!/usr/bin/make
#
# Copyright (c) 1990, Sun Microsystems, Inc.  RESTRICTED RIGHTS LEGEND:
# Use, duplication, or disclosure by the Government is subject to
# restrictions as set forth in subparagraph (c)(1)(ii) of the Rights in
# Technical Data and Computer Software clause at DFARS 52.227-7103 and
# in similar clauses in the FAR and NASA FAR Supplement.
#
#	@(#) Makefile 1.13 91/02/12
#

# REMIND: Remove TNTHOME stuff when TNT V2 is merged into OPENWINHOME.

#
# If no DESTDIR was specified, use the TNTHOME environment variable.
DESTDIR:sh	= echo ${DESTDIR:-$TNTHOME}
MAN_DIR		= $(DESTDIR)/share/man/man6
ALL_DEST	=				\
		$(DESTDIR)/demo/bin		\
		$(DESTDIR)/demo/src/gaintool	\
		$(MAN_DIR)


#
# Define COMPILE_PS to -DCOMPILE_POSTSCRIPT to have gaintool.ps
# compiled into the executable so that it need not be accessable
# at execution time.
#
COMPILE_PS	= -DCOMPILE_POSTSCRIPT

OPTIMIZE	= -g
INCLUDES	=-I. -I$(DESTDIR)/include -I$(OPENWINHOME)/include
CPPFLAGS	= $(CCDEFINES) $(INCLUDES) $(COMPILE_PS)
CFLAGS		= ${OPTIMIZE}
LDFLAGS		= $(STATIC) -L. -L$(DESTDIR)/lib -L$(OPENWINHOME)/lib
LDLIBS		= -lwire -lalert -lcps -lm
CCPS		= $(DESTDIR)/bin/CPS

OBJ		= gaintool.o gaintool_cps.o

SCCS_SOURCES:sh	= ls SCCS/s.*
BACKUPS		= $(SCCS_SOURCES:SCCS/s.%=%)

%.c + %.h :	%.cps
	$(CCPS) -o functions $(CPSFLAGS) $(COMPILE_PS) $*.cps

default:	all

all:		gaintool

gaintool:	$(BACKUPS) $(OBJ)
	$(LINK.c) -o $@ $(OBJ) $(LDLIBS)

gaintool.o:	gaintool.c gaintool_cps.h

gaintool_cps.c:	gaintool_cps.cps $(COMPILE_PS:-DCOMPILE_POSTSCRIPT=gaintool.ps)

gaintool_cps.o:	gaintool_cps.c
	$(COMPILE.c) $(OUTPUT_OPTION) gaintool_cps.c

clean:
	rm -f gaintool*.o gaintool_cps.h gaintool_cps.c
	rm -f *~ *%% %*% *.BAK \#*\#

clobber:	clean
	rm -f gaintool
	-sccs clean

install:	$(ALL_DEST) gaintool
	install -m 775 gaintool $(DESTDIR)/demo/bin
	install	-m 444 $(BACKUPS) $(DESTDIR)/demo/src/gaintool
	install -m 444 gaintool.6 $(MAN_DIR)

$(ALL_DEST):	$(DESTDIR)
	-install -d -m 775 $@
