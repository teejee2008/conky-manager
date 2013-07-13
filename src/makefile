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
	mkdir -p $(DESTDIR)$(sharedir)/conky-manager
	mkdir -p $(DESTDIR)$(sharedir)/conky-manager/images
	mkdir -p $(DESTDIR)$(sharedir)/conky-manager/themepacks
	mkdir -p $(DESTDIR)$(sharedir)/pixmaps
	
	install -m 0755 conky-manager $(DESTDIR)$(bindir)
	install -m 0755 conky-manager.desktop $(DESTDIR)$(launcherdir)
	install -m 0755 ./images/conky-manager.png $(DESTDIR)$(sharedir)/pixmaps
	
	cp -dpr --no-preserve=ownership -t $(DESTDIR)$(sharedir)/conky-manager/images images/*
	cp -dpr --no-preserve=ownership -t $(DESTDIR)$(sharedir)/conky-manager/themepacks themepacks/*.cmtp.7z
	
uninstall:
	rm -f $(DESTDIR)$(bindir)/conky-manager
	rm -f $(DESTDIR)$(launcherdir)/conky-manager.desktop
	rm -f $(DESTDIR)$(sharedir)/pixmaps/conky-manager.png
	rm -rfd $(DESTDIR)$(sharedir)/conky-manager
    
