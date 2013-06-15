prefix = /usr
bindir = $(prefix)/bin
sharedir = $(prefix)/share
launcherdir = $(sharedir)/applications
mandir = $(sharedir)/man
man1dir = $(mandir)/man1
CFLAGS = --std=c99

all:
	valac -X -D'GETTEXT_PACKAGE="conky-manager"' --Xcc="-lm" "Main.vala" "MainWindow.vala" "Utility.vala" --pkg glib-2.0 --pkg gio-unix-2.0 --pkg posix --pkg gtk+-3.0 --pkg gee-1.0 -o conky-manager 

clean:
	rm -rf *.o conky-manager
	
install:
	mkdir -p $(DESTDIR)
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(sharedir)
	mkdir -p $(DESTDIR)$(mandir)
	mkdir -p $(DESTDIR)$(man1dir)
	mkdir -p $(DESTDIR)$(launcherdir)
	install -m 0755 conky-manager $(DESTDIR)$(bindir)
	
uninstall:
	rm -f /usr/bin/selene
