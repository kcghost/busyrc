prefix = /usr/local
exec_prefix=$(prefix)
sbindir=$(exec_prefix)/sbin
sysconfdir=$(prefix)/etc
datarootdir=$(prefix)/share
datadir=$(datarootdir)

.PHONY: all install check

all:

install:
	install -Dm755 src/rc $(DESTDIR)$(sbindir)/rc
	install -Dm644 src/minirc.conf $(DESTDIR)$(sysconfdir)/minirc.conf
	install -Dm644 src/inittab $(DESTDIR)$(sysconfdir)/inittab
	install -Dm644 src/_minirc $(DESTDIR)$(datadir)/zsh/site-functions/_minirc
	install -Dm755 src/shutdown $(DESTDIR)$(sbindir)/shutdown
	install -Dm755 src/bbwrap $(DESTDIR)$(sbindir)/bbwrap
	for i in init halt poweroff reboot; do ln -sf $$(which busybox) $(DESTDIR)$(sbindir)/$$i; done

check:
	-shellcheck -ax -s dash src/rc
	-shellcheck -ax -s dash src/bbwrap
	-shellcheck -ax -s dash src/shutdown
