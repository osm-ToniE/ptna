MO_PATH=../locale/

LOCALIZABLE=../bin/*.pl ../modules/*.pm ../modules/GTFS/*.pm

TEMPLATE=ptna.pot

.PHONY: compile up update pull txpull push txpush clean help

compile:
	@echo Creating message catalogs ...
	@for i in $$(ls *.po); do \
	    mkdir -p $(MO_PATH)$${i%.po}/LC_MESSAGES ; \
	    msgfmt -v $$i -o $(MO_PATH)$${i%.po}/LC_MESSAGES/ptna.mo; \
	    echo "$$i -> $(MO_PATH)$${i%.po}/LC_MESSAGES/ptna.mo"; \
	done

up update: $(TEMPLATE)

$(TEMPLATE): $(LOCALIZABLE)
	@echo Gathering translations ...
	@xgettext --language Perl \
	    --keyword=gettext --keyword=ngettext \
	    --from-code utf-8 \
	    --no-location \
	    --add-comments=xgettext \
	    --package-name=ptna \
	    --package-version=2.0.2 \
	    --msgid-bugs-address='osm-ToniE@web.de' \
	    --output $(TEMPLATE) $(LOCALIZABLE)

push txpush:
	@echo Pushing pot source file to Transifex ...
	@cd .. && tx push -s

pull txpull:
	@echo Pulling translations from Transifex ...
	@cd .. && tx pull

clean:
	@rm -f *.save

help:
	@echo 'Available goals: compile, update, txpush, txpull, clean, help.'
