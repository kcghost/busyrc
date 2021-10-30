prefix = /usr/local
exec_prefix=$(prefix)
sbindir=$(exec_prefix)/sbin
sysconfdir=$(prefix)/etc
datarootdir=$(prefix)/share
datadir=$(datarootdir)

services = alsa bitlbee dbus dockerd dhcpdc icecast iptables lighttpd nixdaemon ntpd polipo privocy pulseaudio sshd tmpfiles upowerd vsftpd wpa_supplicant acpid

.PHONY: all install check clean

rc: src/rc $(foreach service,$(services),src/services/$(service).sh)
	sed -e '/@services_include@/ {' $(foreach service,$(services), -e 'r src/services/$(service).sh') -e 'd' -e '}' $< > $@

all: rc

install: rc
	install -Dm755 rc $(DESTDIR)$(sbindir)/rc
	install -Dm644 src/busyrc.conf $(DESTDIR)$(sysconfdir)/busyrc.conf
	install -Dm644 src/inittab $(DESTDIR)$(sysconfdir)/inittab
	install -Dm644 src/_busyrc $(DESTDIR)$(datadir)/zsh/site-functions/_busyrc
	install -Dm755 src/shutdown $(DESTDIR)$(sbindir)/shutdown
	install -Dm755 src/bbwrap $(DESTDIR)$(sbindir)/bbwrap
	for i in init halt poweroff reboot; do ln -sf $$(which busybox) $(DESTDIR)$(sbindir)/$$i; done

check:
	-shellcheck -ax -s dash src/rc
	-shellcheck -ax -s dash src/bbwrap
	-shellcheck -ax -s dash src/shutdown
	-shellcheck -ax -s dash src/services/*

clean:
	rm -f rc
