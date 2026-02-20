#	Automatically Generated Makefile for Prototype

#	This make file assumes that the standard rules for
#	C++ files are included in your default rule set.  This will
#	be the case if you are running SunOS 4.1 or later, or if C++
#	has been properly installed on your machine.  If not, see
#	Appendix F of the Sun C++ Programmer's Guide.

INCLUDES	=-I. -I$(TNTHOME)/include -I$(TNTGUIDEHOME) -I$(OPENWINHOME)/include
CPPFLAGS	= $(CCDEFINES) $(INCLUDES)
CCFLAGS		= -g
CCDEFINES	= -DDEBUG 
LDFLAGS		= -L. -L$(TNTHOME)/lib -L$(TNTGUIDEHOME) -L$(OPENWINHOME)/lib
LDLIBS		= -ljot -lwire -lALERT -lcps -lTODO
CCPS		= $(TNTGUIDEHOME)/CPS

%.c + %.h :	%.cps
	$(CCPS) $(CPSFLAGS) -o portable $*.cps

default::	all

all::	todo_min

todo_min:	todo_min.o todo_min_cps.o
	$(LINK.cc) -o $@ \
		todo_min.o todo_min_cps.o $(LDLIBS)

todo_min.o: todo_min.cc todo_min.h todo_min_cps.h
	$(COMPILE.cc) $(OUTPUT_OPTION) todo_min.cc

todo_min_cps.o: todo_min_cps.c
	$(COMPILE.c) $(OUTPUT_OPTION) todo_min_cps.c

clean::
	rm -f todo_min*.o todo_min_gen.ps todo_min_cps.h todo_min_cps.c todo_min.G.BAK 

clobber::	clean
	rm -f todo_min todo_min.h todo_min.cc todo_min.ps
	rm -f todo_min.make todo_min_cps.* todo_min*.new

