allhtml := $(patsubst %.xml,%.html,$(wildcard *.xml))
alltxt := $(patsubst %.xml,%.txt,$(wildcard *.xml))

-include Make.rules

EXAMPLES.html:
	ln -s EXAMPLES.SuSEfirewall2.html EXAMPLES.html

README.html:
	ln -s README.SuSEfirewall2.html README.html

FAQ.html:
	ln -s FAQ.SuSEfirewall2.html FAQ.html

links: EXAMPLES.html FAQ.html README.html

.PHONY: links
