# Makefile for minimal C++ library for todo_min (tntclass)

libTODO.a : todofile.o itementry.o
	ar rcv libTODO.a todofile.o itementry.o
	ranlib libTODO.a

todofile.o : todofile.cc
	$(COMPILE.cc)  todofile.cc -o $@

itementry.o : itementry.cc
	$(COMPILE.cc) itementry.cc -o $@
