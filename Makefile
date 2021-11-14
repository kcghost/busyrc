prefix = /usr/local
exec_prefix=$(prefix)
# GNU Make recommends $(prefix)/sbin, but this doesn't really make sense in practice
sbindir=/sbin
libexecdir = $(exec_prefix)/libexec
# GNU Make recommends $(prefix)/etc, but this doesn't really make sense in practice
sysconfdir=/etc
datarootdir=$(prefix)/share
datadir=$(datarootdir)

services = $(basename $(notdir $(wildcard src/services/*.sh)))

.PHONY: all install install-conf install-nix check clean

out/%: src/%.sh src/path.sh $(foreach service,$(services),src/services/$(service).sh)
	sed \
	-e '/@services_include@/ {' \
		-e "i SERVICES=\"$(foreach service,$(services),$(service))\"" \
		$(foreach service,$(services), -e 'r src/services/$(service).sh') \
	-e 'd' -e '}' \
	-e '/@path_include@/ {' \
		-e 'r src/path.sh' \
	-e 'd' -e '}' \
	$< > $@
	chmod +x $@

all: out/rc out/shutdown out/busyrc-ifplugd.action out/busyrc-udhcpc.script

install: all
	install -Dm755 out/rc $(DESTDIR)$(sbindir)/rc
	install -Dm755 out/shutdown $(DESTDIR)$(sbindir)/shutdown
	install -Dm755 out/busyrc-udhcpc.script $(DESTDIR)$(libexecdir)/busyrc-udhcpc.script
	install -Dm755 out/busyrc-ifplugd.action $(DESTDIR)$(libexecdir)/busyrc-ifplugd.action
	install -Dm644 src/_busyrc.sh $(DESTDIR)$(datadir)/zsh/site-functions/_busyrc
	install -Dm755 src/bbwrap.sh $(DESTDIR)$(sbindir)/bbwrap
	for i in init halt poweroff reboot; do ln -sf $$(which busybox) $(DESTDIR)$(sbindir)/$$i; done

install-conf:
	install -Dm644 src/busyrc.conf.sh $(DESTDIR)$(sysconfdir)/busyrc.conf
	install -Dm644 src/inittab $(DESTDIR)$(sysconfdir)/inittab

install-nix:
	install -Dm755 src/nixos-switch $(DESTDIR)$(sbindir)/nixos-switch

check:
	-shellcheck -ax -s dash src/rc
	-shellcheck -ax -s dash src/bbwrap
	-shellcheck -ax -s dash src/shutdown
	-shellcheck -ax -s dash src/services/*

clean:
	rm -f out/*

