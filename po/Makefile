MO_PATH=../locale/

LOCALIZABLE=../bin/*.pl ../modules/*.pm ../modules/GTFS/*.pm

TEMPLATE=ptna.pot

.PHONY: check up update pull txpull push txpush compile www clean help

help:
	@echo 'Available goals: help, check, update, txpush, txpull, compile, www, clean'
	@echo 'make check'
	@echo 'make update'
	@echo 'make push'
	@echo 'Translate @ Transifex - https://www.transifex.com/'
	@echo 'make pull'
	@echo 'make compile'
	@echo 'make www'

check:
	@echo "From ptna-routes.pl"
	@ptna-check-strings.pl --file=../bin/ptna-routes.pl
	@echo "From RoutesList.pm"
	@ptna-check-strings.pl --file=../modules/RoutesList.pm
	@echo "From PtnaSQLite.pm"
	@ptna-check-strings.pl --file=../modules/GTFS/PtnaSQLite.pm


up update: $(TEMPLATE)

$(TEMPLATE): $(LOCALIZABLE)
	@echo Gathering translations from PTNA code ...
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

compile:
	@echo Creating message catalogs ...
	@for i in $$(ls *.po); do \
	    mkdir -p $(MO_PATH)$${i%.po}/LC_MESSAGES ; \
	    msgfmt -v $$i -o $(MO_PATH)$${i%.po}/LC_MESSAGES/ptna.mo; \
	    echo "$$i -> $(MO_PATH)$${i%.po}/LC_MESSAGES/ptna.mo"; \
	done

www:
	@echo Publishing to ptna-wwww ...
	@ptna-list-strings.pl --what=messages --language=en 	> ../../ptna-www/en/message-table.inc
	@ptna-list-strings.pl --what=messages --language=de 	> ../../ptna-www/de/message-table.inc
	@ptna-list-strings.pl --what=messages --language=fr 	> ../../ptna-www/fr/message-table.inc
	@ptna-list-strings.pl --what=messages --language=pl_PL 	> ../../ptna-www/pl_PL/message-table.inc
	@ptna-list-strings.pl --what=options  --language=en 	> ../../ptna-www/en/option-table.inc
	@ptna-list-strings.pl --what=options  --language=de 	> ../../ptna-www/de/option-table.inc
	@ptna-list-strings.pl --what=options  --language=fr 	> ../../ptna-www/fr/option-table.inc
	@ptna-list-strings.pl --what=options  --language=pl_pl 	> ../../ptna-www/pl_PL/option-table.inc

clean:
	@rm -f *.save
