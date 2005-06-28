VERSION=3.4
NAME=SuSEfirewall2
NVER=$(NAME)-$(VERSION)
ARCHIVE=$(NVER).tar.bz2
SCRIPTS=SuSEfirewall2-batch \
	SuSEfirewall2-open \
	SuSEfirewall2-showlog \
	SuSEfirewall2-rpcinfo \
	SuSEfirewall2-bashhash \
	SuSEfirewall2-qdisc \
	SuSEfirewall2-oldbroadcast \
	SuSEfirewall2-autointerface.sh 

DESTDIR=

allfiles= \
	SuSEfirewall2_init \
	SuSEfirewall2_setup \
	$(SCRIPTS) \
	SuSEfirewall2-custom.sysconfig \
	SuSEfirewall2 \
	SuSEfirewall2.sysconfig \
	SuSEfirewall2.update-message \
	SuSEfirewall2.update-message.broadcast \
	Makefile \
	LICENCE

tar: $(ARCHIVE)

$(ARCHIVE): $(allfiles) doc
	rm -rf $(NVER)
	mkdir $(NVER)
	for i in $(allfiles); do \
		ln $$i $(NVER)/$$i; \
	done
	ln doc/SuSEfirewall2-doc.desktop $(NVER)/SuSEfirewall2-doc.desktop
	for i in doc/*SuSEfirewall2.html; do \
		dest=$${i/.SuSEfirewall2/}; \
		dest=$${dest##*/}; \
		ln $$i $(NVER)/$$dest; \
	done
	for i in doc/*.txt; do \
		dest=$${i%.SuSEfirewall2.txt} \
		dest=$${dest##*/}; \
		ln $$i $(NVER)/$$dest; \
	done
	ln doc/susebooks.css $(NVER)/
	tar --owner=root --group=root -cjf $(ARCHIVE) $(NVER)
	rm -rf $(NVER)

install:
	install -d -m 755 $(DESTDIR)/sbin
	install -d -m 755 $(DESTDIR)/etc/init.d
	install -d -m 755 $(DESTDIR)/etc/sysconfig/scripts
	install -m 755 SuSEfirewall2 $(DESTDIR)/sbin
	install -m 755 SuSEfirewall2_init $(DESTDIR)/etc/init.d
	install -m 755 SuSEfirewall2_setup $(DESTDIR)/etc/init.d
	rm -f $(DESTDIR)/sbin/rcSuSEfirewall2
	ln -s /etc/init.d/SuSEfirewall2_setup $(DESTDIR)/sbin/rcSuSEfirewall2
	for i in $(SCRIPTS); do \
		install -m 644 $$i $(DESTDIR)/etc/sysconfig/scripts; \
	done
	install -m 755 SuSEfirewall2-custom.sysconfig $(DESTDIR)/etc/sysconfig/scripts/SuSEfirewall2-custom

doc:
	$(MAKE) -C doc

clean:
	rm -f $(ARCHIVE)

.PHONY: clean doc
