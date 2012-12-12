SCRIPTS=SuSEfirewall2-batch \
	SuSEfirewall2-open \
	SuSEfirewall2-showlog \
	SuSEfirewall2-rpcinfo \
	SuSEfirewall2-qdisc \
	SuSEfirewall2-oldbroadcast \

DESTDIR=

allfiles= \
	SuSEfirewall2_init \
	SuSEfirewall2_setup \
	SuSEfirewall2_init.service \
	SuSEfirewall2.service \
	$(SCRIPTS) \
	SuSEfirewall2_ifup \
	SuSEfirewall2-custom.sysconfig \
	SuSEfirewall2 \
	SuSEfirewall2.sysconfig \
	SuSEfirewall2.service.TEMPLATE \
	SuSEfirewall2.update-message \
	SuSEfirewall2.update-message.broadcast \
	Makefile \
	LICENCE

all:

install:
	install -d -m 755 $(DESTDIR)/sbin
	install -d -m 755 $(DESTDIR)/etc/init.d
	install -d -m 755 $(DESTDIR)/etc/sysconfig/scripts
	install -d -m 755 $(DESTDIR)/etc/sysconfig/network/scripts
	install -d -m 755 $(DESTDIR)/etc/sysconfig/network/if-up.d
	install -d -m 755 $(DESTDIR)/etc/sysconfig/SuSEfirewall2.d/services
	install -d -m 755 $(DESTDIR)/etc/sysconfig/SuSEfirewall2.d/defaults
	install -d -m 755 $(DESTDIR)/usr/share/SuSEfirewall2/defaults
	install -m 755 SuSEfirewall2 $(DESTDIR)/sbin
	install -m 755 -d $(DESTDIR)/lib/systemd/system
	install -m 644 SuSEfirewall2_init.service $(DESTDIR)/lib/systemd/system
	install -m 644 SuSEfirewall2.service $(DESTDIR)/lib/systemd/system
	rm -f $(DESTDIR)/sbin/rcSuSEfirewall2
	ln -s /etc/init.d/SuSEfirewall2_setup $(DESTDIR)/sbin/rcSuSEfirewall2
	for i in $(SCRIPTS); do \
		install -m 644 $$i $(DESTDIR)/etc/sysconfig/scripts; \
	done
	install -m 755 SuSEfirewall2_ifup $(DESTDIR)/etc/sysconfig/network/scripts/SuSEfirewall2
	ln -sf /etc/sysconfig/network/scripts/SuSEfirewall2 $(DESTDIR)/etc/sysconfig/network/if-up.d
	ln -sf SuSEfirewall2 $(DESTDIR)/etc/sysconfig/network/scripts/firewall
	install -m 755 SuSEfirewall2-custom.sysconfig $(DESTDIR)/etc/sysconfig/scripts/SuSEfirewall2-custom
	install -m 644 SuSEfirewall2.service.TEMPLATE $(DESTDIR)/etc/sysconfig/SuSEfirewall2.d/services/TEMPLATE
	install -m 644 SuSEfirewall2.defaults $(DESTDIR)/usr/share/SuSEfirewall2/defaults/50-default.cfg
	install -m 644 rpcusers $(DESTDIR)/usr/share/SuSEfirewall2/rpcusers

pkgdocdir=/usr/share/doc/packages/SuSEfirewall2
install_doc:
	install -d -m 755 $(DESTDIR)$(pkgdocdir)
	@for i in doc/*SuSEfirewall2.html; do \
		dest=$${i/.SuSEfirewall2/}; \
		dest=$${dest##*/}; \
		set -- install -m 644 $$i $(DESTDIR)$(pkgdocdir)/$$dest; \
		echo "$$@"; \
		"$$@"; \
	done
	@for i in doc/*.txt; do \
		dest=$${i%.SuSEfirewall2.txt} \
		dest=$${dest##*/}; \
		set -- install -m 644 $$i $(DESTDIR)$(pkgdocdir)/$$dest; \
		echo "$$@"; \
		"$$@"; \
	done
	install -m 644 doc/susebooks.css $(DESTDIR)$(pkgdocdir)/
	install -m 644 LICENCE $(DESTDIR)$(pkgdocdir)/
	install -m 644 SuSEfirewall2.sysconfig $(DESTDIR)$(pkgdocdir)/

package:
	@./obs/mkpackage

doc:
	$(MAKE) -C doc

clean:
	rm -f $(ARCHIVE)

.PHONY: clean doc package install install_doc all
