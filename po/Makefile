MO_PATH=../locale/

LOCALIZABLE=../bin/*.pl ../modules/*.pm

TEMPLATE=ptna.pot

.PHONY: compile update clean help

compile:
	@for i in $$(ls *.po); do \
	    mkdir -p $(MO_PATH)$${i%.po}/LC_MESSAGES ; \
	    msgfmt -v $$i -o $(MO_PATH)$${i%.po}/LC_MESSAGES/ptna.mo; \
	    echo "$$i -> $(MO_PATH)$${i%.po}/LC_MESSAGES/ptna.mo"; \
	done

up update: $(LOCALIZABLE)
	@echo Gathering translations...
	@xgettext --language Perl \
	    --keyword=gettext --keyword=ngettext \
	    --from-code utf-8 \
	    --no-location \
	    --add-comments=xgettext \
	    --package-name=ptna \
	    --package-version=2.0.1 \
	    --msgid-bugs-address='osm-ToniE@web.de' \
	    --output $(TEMPLATE) $(LOCALIZABLE)
	@echo Merging...
	@for i in $$(ls *.po); do \
	    cp $$i $$i.save; \
	    echo -n "$$i "; \
	    msgmerge $$i.save $(TEMPLATE) > $$i; \
	done
	@echo

clean:
	@rm -f *.save

help:
    @echo 'Available goals: compile, update, clean, help.'
