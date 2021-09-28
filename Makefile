prefix = /usr/local
exec_prefix=$(prefix)
sbindir=$(exec_prefix)/sbin
sysconfdir=$(prefix)/etc
datarootdir=$(prefix)/share
datadir=$(datarootdir)

.PHONY: all install check

all:

install:
	install -Dm755 rc $(DESTDIR)$(sbindir)/rc
	install -Dm644 minirc.conf $(DESTDIR)$(sysconfdir)/minirc.conf
	install -Dm644 inittab $(DESTDIR)$(sysconfdir)/inittab
	install -Dm644 extra/_minirc $(DESTDIR)$(datadir)/zsh/site-functions/_minirc
	install -Dm755 extra/shutdown.sh $(DESTDIR)$(sbindir)/shutdown
	for i in init halt poweroff reboot; do ln -sf $$(which busybox) $(DESTDIR)$(sbindir)/$$i; done

check:
	shellcheck -ax -s dash rc
