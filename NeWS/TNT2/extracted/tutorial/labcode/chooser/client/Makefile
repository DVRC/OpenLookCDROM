#	Automatically Generated Makefile for Prototype

INCLUDES	=-I. -I$(TNTHOME)/include -I$(TNTGUIDEHOME) -I$(OPENWINHOME)/include
CPPFLAGS	= $(CCDEFINES) $(INCLUDES)
CFLAGS		= -g -DDEVELOP
LDFLAGS		= -L. -L$(TNTHOME)/lib -L$(TNTGUIDEHOME) -L$(OPENWINHOME)/lib
LDLIBS		= -lwire -lalert -lcps
CCPS		= $(TNTGUIDEHOME)/CPS

%.c + %.h :	%.cps
	$(CCPS) $(CPSFLAGS) -o portable $*.cps

default::	all

all::	chooser

chooser:	chooser.o chooser_cps.o
	$(LINK.c) -o $@\
		chooser.o chooser_cps.o $(LDLIBS)

chooser.o: chooser.c  chooser_cps.h

chooser_cps.o: chooser_cps.c
	$(COMPILE.c) $(OUTPUT_OPTION) chooser_cps.c

clean::
	rm -f chooser*.o chooser_gen.ps chooser_cps.h chooser_cps.c chooser.G.BAK 

clobber::	clean
	rm -f chooser chooser.h chooser.c chooser.ps
	rm -f chooser.make chooser_cps.* chooser*.new

