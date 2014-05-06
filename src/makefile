prefix = /usr
bindir = $(prefix)/bin
sharedir = $(prefix)/share
launcherdir = $(sharedir)/applications
mandir = $(sharedir)/man
man1dir = $(mandir)/man1
CFLAGS = --std=c99

all:
	valac -X -D'GETTEXT_PACKAGE="conky-manager"' --Xcc="-lm" "Main.vala" "MainWindow.vala" "EditWindow.vala" "SettingsWindow.vala" "DonationWindow.vala" "CreateThemeWindow.vala" "GeneratePreviewWindow.vala" "AboutWindow.vala" "Utility.vala" -o conky-manager --pkg glib-2.0 --pkg gio-unix-2.0 --pkg posix --pkg gtk+-3.0 --pkg gee-1.0 --pkg libsoup-2.4 --pkg json-glib-1.0 

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
	mkdir -p $(DESTDIR)$(sharedir)/pixmaps

	#binary
	install -m 0755 conky-manager $(DESTDIR)$(bindir)
	
	#launcher
	install -m 0755 conky-manager.desktop $(DESTDIR)$(launcherdir)
	
	#app icon
	install -m 0755 share/pixmaps/conky-manager.png $(DESTDIR)$(sharedir)/pixmaps
	
	#shared files
	cp -dpr --no-preserve=ownership -t "$(DESTDIR)$(sharedir)/conky-manager" ./share/conky-manager/*
	chmod --recursive 0755 $(DESTDIR)$(sharedir)/conky-manager/*
	
	#translations
	#msgfmt --check --verbose -o "$(DESTDIR)$(localedir)/it_IT/LC_MESSAGES/conky-manager.mo" ../po/conky-manager-it.po
	
uninstall:
	#binary
	rm -f $(DESTDIR)$(bindir)/conky-manager
	
	#launcher
	rm -f $(DESTDIR)$(launcherdir)/conky-manager.desktop
	
	#app icon
	rm -f $(DESTDIR)$(sharedir)/pixmaps/conky-manager.png
	
	#shared files
	rm -rf $(DESTDIR)$(sharedir)/conky-manager
    
    #translations
    #rm -f "$(DESTDIR)$(localedir)/*/LC_MESSAGES/conky-manager.mo"
