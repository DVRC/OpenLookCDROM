# Makefile for xloadimage.  this replaces the multiple makefiles used in
# versions prior to xloadimage 1.07.

SYSPATHFILE=.
INSTALLDIR=.
STD_CC= cc
GCC= gcc
CP= cp
LN= ln -s
RM= rm -f
LIBS= -lX11 -lm
CFLAGS= -O -DSYSPATHFILE=\"$(SYSPATHFILE)\" $(EXTRAFLAGS)
OWNFLAGS= -I"$(OPENWINHOME)/include"
GCCFLAGS= -fstrength-reduce -finline-functions
GCC137FLAGS= -fforce-mem -fforce-addr -fstrength-reduce -finline-functions -DSYSPATHFILE=\"$(SYSPATHFILE)\"

MISC= Imakefile Makefile README VMS-CHANGES buildshar.c xloadimage.man \
      patchlevel pbm.h rle.h sunraster.h xloadimage.h xwd.h

INCS= cmuwmraster.h copyright.h fbm.h g3.h gif.h hash.h image.h imagetypes.h \
      kljcpyrght.h mac.h mit.cpyrght mrmcpyrght.h options.h

SRCS= bright.c clip.c cmuwmraster.c compress.c dither.c faces.c fbm.c \
      fill.c g3.c gif.c halftone.c hash.c imagetypes.c mac.c merge.c misc.c \
      new.c options.c path.c pbm.c reduce.c rle.c rlelib.c root.c \
      rotate.c send.c smooth.c sunraster.c value.c window.c xbitmap.c \
      xloadimage.c xpixmap.c xwd.c zio.c zoom.c 

OBJS= bright.o clip.o cmuwmraster.o compress.o dither.o faces.o fbm.o \
      fill.o g3.o gif.o halftone.o hash.o imagetypes.o mac.o merge.o misc.o \
      new.o options.o path.o pbm.o reduce.o rle.o rlelib.o root.o \
      rotate.o send.o smooth.o sunraster.o value.o window.o xbitmap.o \
      xloadimage.o xpixmap.o xwd.o zio.o zoom.o

ALL= $(MISC) $(INCS) $(SRCS)

# standard target.  this is for BSD-like environments, generally, although
# it will also work in many System-V environments.

std:
	@echo "Building standard distribution.  If this fails, consider trying"
	@echo "'make sysv'.  To build under Sun's Openwindows try 'make own'."
	make xloadimage CC=$(STD_CC)

# system-v target.  use this if you have a system-v compliant system.
	
sysv:
	@echo "Building standard distribution for System-V."
	make xloadimage CC=$(STD_CC) EXTRAFLAGS=-DSYSV

# openwindows target.  use this if you are using openwindows on a sun.

own:
	@echo "Building distribution for Sun's Openwindows."
	@echo "Using Sun standard cc compiler."
	make xloadimage CC=$(STD_CC) EXTRAFLAGS="$(OWNFLAGS)"

# gcc target.  use this if you have a gcc that is not version 1.37.  you
# should add -DSYSV between the quotes in EXTRAFLAGS if your system is
# system-v compliant as well. 

gcc:
	@echo "Building distribution with GNU cc."
	@echo "If something doesn't work, try using 'make gcc-1-37' and then"
	@echo "'make std' before reporting a bug."
	make xloadimage CC=$(GCC) EXTRAFLAGS="$(GCCFLAGS)"

sysv-gcc:
	@echo "Building System-V distribution with GNU cc."
	@echo "If something doesn't work, try using 'make sysv-gcc-1-37' and"
	@echo "then 'make std' before reporting a bug."
	make xloadimage CC=$(GCC) EXTRAFLAGS="-DSYSV $(GCCFLAGS)"

own-gcc:
	@echo "Building distribution for Sun's Openwindows with GNU cc."
	@echo "If something doesn't work, try using 'make own-gcc-1-37'"
	@echo "before reporting a bug."
	make xloadimage CC=$(GCC) EXTRAFLAGS="$(OWNFLAGS) $(GCCFLAGS)"

# this target is for systems which use gcc 1.37.  there is a compiler bug
# in gcc 1.37 which causes some xloadimage functions to fail with the
# standard optimizations.  use this if GIF loading and colormap reduction
# product black pictures.

gcc-1-37:
	@echo "Building distribution with GNU cc using flags for gcc 1.37."
	@echo "If something doesn't work, try using std before reporting"
	@echo "a bug."
	make xloadimage CC=$(GCC) EXTRAFLAGS="$(GCC137FLAGS)"

sysv-gcc-1-37:
	@echo "Building System-V distribution with GNU cc using flags for"
	@echo "gcc 1.37.  If something doesn't work, try using std before"
	@echo "reporting a bug."
	make xloadimage CC=$(GCC) EXTRAFLAGS="-DSYSV $(GCC137FLAGS)"

own-gcc-1-37:
	@echo "Building distribution for Sun's Openwindows with GNU cc"
	@echo "using flags for gcc 1.37."
	@echo "If something doesn't work, try using std before reporting"
	@echo "a bug."
	make xloadimage CC=$(GCC) EXTRAFLAGS="$(OWNFLAGS) $(GCC137FLAGS)"

install: $(SYSPATHFILE)
	$(RM) $(INSTALLDIR)/xloadimage
	$(RM) $(INSTALLDIR)/xsetbg
	$(RM) $(INSTALLDIR)/xview
	$(CP) xloadimage $(INSTALLDIR)/xloadimage
	$(LN) $(INSTALLDIR)/xloadimage $(INSTALLDIR)/xsetbg
	$(LN) $(INSTALLDIR)/xloadimage $(INSTALLDIR)/xview

xloadimage: $(OBJS)
	$(CC) $(CFLAGS) -o xloadimage $(OBJS) $(LIBS)

.c.o: xloadimage.h
	$(CC) -c $(CFLAGS) $*.c

clean:
	rm -f *.o *~ xloadimage buildshar doshar shar.* *.tar *.tar.Z

$(SYSPATHFILE):
	@echo "*** Creating default $(SYSPATHFILE) since you"
	@echo "*** don't have one. This file is used to set up default places"
	@echo "*** and names to look for images.  You probably want to edit"
	@echo "*** it for your site.  See the xloadimage manual page for"
	@echo "*** details on the contents of this file."
	cp /dev/null $(SYSPATHFILE)
	echo "path= /usr/local/images" \
		>> $(SYSPATHFILE)
	echo "extension=.csun .msun .sun .face .xbm .bm .gif .im8 .im1 .im24" \
		>>$(SYSPATHFILE)

# these targets are for building shar distributions

buildshar: buildshar.o
	$(CC) -o buildshar buildshar.o

shar: buildshar
	rm -f shar.* doshar
	./buildshar $(ALL) > doshar
	sh doshar
	rm doshar

# targets for building tar distributions

tar: xloadimage.tar

tar.Z: xloadimage.tar
	compress xloadimage.tar

xloadimage.tar:
	tar cf xloadimage.tar $(ALL)

# these targets are for those of us who have Saber-C

# load all objects in saber.  useful if you then swap the portions to debug
# for source.

objinsaber:
	#setopt ccargs -g -DSYSPATHFILE=\\\"$(SYSPATHFILE)\\\"
	#load $(OBJS) $(LIBS)
	#link

# load all sources in saber.  not as useful as the last one.

srcinsaber:
	#setopt load_flags -DSYSPATHFILE=\\\"$(SYSPATHFILE)\\\"
	#load $(SRCS) $(LIBS)
	#link
