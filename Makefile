prefix = /usr/local
exec_prefix=$(prefix)
# GNU Make recommends $(prefix)/sbin, but this doesn't really make sense in practice
sbindir=/sbin
# GNU Make recommends $(prefix)/etc, but this doesn't really make sense in practice
sysconfdir=/etc
datarootdir=$(prefix)/share
datadir=$(datarootdir)

services = $(basename $(notdir $(wildcard src/services/*.sh)))
networks = $(shell tail -n +3 /proc/net/dev | grep -v lo | cut -d':' -f1 | xargs)
wireless = $(shell tail -n +3 /proc/net/wireless | cut -d':' -f1 | xargs)

.PHONY: all install install-conf install-nix check clean

out/%: src/%.sh src/path.sh $(foreach service,$(services),src/services/$(service).sh)
	sed \
	-e '/@services_include@/ {' \
		-e "i SERVICES=\"$(services))\"" \
		$(foreach service,$(services), -e 'r src/services/$(service).sh') \
	-e 'd' -e '}' \
	-e '/@path_include@/ {' \
		-e 'r src/path.sh' \
	-e 'd' -e '}' \
	-e '/@networks_include@/ {' \
		-e "i NETWORK_INTERFACES=\"$(networks)\"" \
	-e 'd' -e '}' \
	-e '/@wireless_include@/ {' \
		-e "i WIFI_INTERFACES=\"$(wireless)\"" \
	-e 'd' -e '}' \
	-e '/@daemons_include@/ {' \
		-e "i #DAEMONS=\"$(services)\"" \
	-e 'd' -e '}' \
	$< > $@
	chmod +x $@

all: out/rc out/shutdown out/busyrc.conf out/ifplugd.action out/udhcpc.script

install: all
	install -Dm755 out/rc $(DESTDIR)$(sbindir)/rc
	install -Dm644 src/_busyrc.sh $(DESTDIR)$(datadir)/zsh/site-functions/_busyrc
	install -Dm755 src/bbwrap.sh $(DESTDIR)$(sbindir)/bbwrap
	-mv $(DESTDIR)$(sbindir)/shutdown $(DESTDIR)$(sbindir)/shutdown.oldinit
	-mv /usr/lib/tmpfiles.d/systemd-nologin.conf /usr/lib/tmpfiles.d/systemd-nologin.conf.oldconf
	install -Dm755 out/shutdown $(DESTDIR)$(sbindir)/shutdown
	-for i in init halt poweroff reboot; do mv -n $(DESTDIR)$(sbindir)/$$i $(DESTDIR)$(sbindir)/$$i.oldinit; done
	for i in init halt poweroff reboot; do ln -sf $$(which busybox) $(DESTDIR)$(sbindir)/$$i; done

install-conf: all
	install -Dm644 out/busyrc.conf $(DESTDIR)$(sysconfdir)/busyrc/busyrc.conf
	install -Dm755 out/udhcpc.script $(DESTDIR)$(sysconfdir)/busyrc/udhcpc.script
	install -Dm755 out/ifplugd.action $(DESTDIR)$(sysconfdir)/busyrc/ifplugd.action
	install -Dm644 src/inittab $(DESTDIR)$(sysconfdir)/inittab
	
uninstall:
	-mv /usr/lib/tmpfiles.d/systemd-nologin.conf.oldconf /usr/lib/tmpfiles.d/systemd-nologin.conf
	-mv $(DESTDIR)$(sbindir)/shutdown.oldinit $(DESTDIR)$(sbindir)/shutdown
	for i in init halt poweroff reboot; do mv -n $(DESTDIR)$(sbindir)/$$i.oldinit $(DESTDIR)$(sbindir)/$$i; done
	
install-nix:
	install -Dm755 src/nixos-switch $(DESTDIR)$(sbindir)/nixos-switch

check:
	-shellcheck -ax -s dash src/rc
	-shellcheck -ax -s dash src/bbwrap
	-shellcheck -ax -s dash src/shutdown
	-shellcheck -ax -s dash src/services/*

clean:
	rm -f out/*
