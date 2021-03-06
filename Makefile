PREFIX ?= /usr/local
DESTDIR ?=
MANDIR ?= man/man
INSTALLDIR = install -d
INSTALLBIN = install -m 755
INSTALLMAN = install -m 644

POSIX_SHELL ?= /bin/sh

LDFLAGS = `pkg-config --libs taglib_c`

OPTIM ?= -Os
DEBUG ?= -ggdb

CC = cc
CXX = c++

PROJECT = taggit
HEADERS = taggit.h bsdgetopt.c
SOURCES = taggit.c info.c list.c list_human.c list_machine.c setup.c tag.c
OBJS = taggit.o info.o list.o list_human.o list_machine.o setup.o tag.o
CFLAGS += $(ADDTO_CFLAGS) `pkg-config --cflags taglib` -W -Wall -Wextra -Wmissing-declarations -ansi
CFLAGS += $(OPTIM) $(DEBUG)
REALLYJUSTCFLAGS += -Wnested-externs -Wmissing-prototypes -Wstrict-prototypes -std=c99

SRCXX = taglib_ext.cpp
OBJXX = taglib_ext.o
HDRXX = taglib_ext.h
CXXFLAGS = $(CFLAGS)
CXXFLAGS += -std=c++98

all:
	@$(MAKE) _info
	@$(MAKE) $(PROJECT)

_info: version-magic.sh
	@$(POSIX_SHELL) ./version-magic.sh

depend:
	@$(MAKE) _info
	@$(MAKE) _depend

-include version-magic.make

_depend: $(SOURCES) $(SRCXX)
	mkdep $(CFLAGS) $(SOURCES) $(SRCXX)

install:
	$(INSTALLDIR) $(DESTDIR)$(PREFIX)/bin
	$(INSTALLBIN) taggit $(DESTDIR)$(PREFIX)/bin/
	$(INSTALLDIR) $(DESTDIR)$(PREFIX)/$(MANDIR)1
	$(INSTALLMAN) taggit.1 $(DESTDIR)$(PREFIX)/$(MANDIR)1/

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/taggit
	rm -f $(DESTDIR)$(PREFIX)/$(MANDIR)1/taggit.1

taglib_ext.o: taglib_ext.cpp taglib_ext.h
	$(CXX) $(CXXFLAGS) -o taglib_ext.o -c taglib_ext.cpp

.c.o:
	$(CC) $(CFLAGS) $(REALLYJUSTCFLAGS) -o $@ -c $<

$(PROJECT): $(OBJS) $(OBJXX) $(HEADERS) $(HDRXX)
	$(CC) $(CFLAGS) $(REALLYJUSTCFLAGS) $(LDFLAGS) -o $@ $(OBJXX) $(OBJS)

clean:
	rm -f *.o taggit *.1 .depend git-version.h version-magic.make

distclean: clean
	rm -f tags TAGS
	rm -Rf devdoc

doc: $(PROJECT).1

tag: tags

tags:
	# This creates "tags".
	ctags . *.c *.cpp *.h
	# And this creates "TAGS" which is in emacs' etags format.
	ctags -e . *.c *.cpp *.h

devdoc:
	doxygen doxygen.taggit

lint:
	-splint -preproc -linelen 128 -standard -warnposix -booltype boolean +charintliteral -nullassign $(SOURCES)

$(PROJECT).1: $(PROJECT).t2t
	txt2tags --target man -o- $(PROJECT).t2t | sed -e '/^$$/d' -e 's/^\\e$$//' > $(PROJECT).1

-include .depend

.PHONY: all depend doc clean install uninstall tags tag devdoc distclean _depend _info lint
