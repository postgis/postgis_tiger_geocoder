.DEFAULT_GOAL := all

.PHONY: all check install installcheck uninstall noop clean distclean

all install installcheck uninstall noop clean distclean:
	+@$(MAKE) -f Makefile $@

check:
	+@PG_CONFIG="$(PG_CONFIG)" MAKE="$(MAKE)" \
		WITH_ADDRESS_STANDARDIZER="$(WITH_ADDRESS_STANDARDIZER)" \
		ADDRESS_STANDARDIZER_SOURCE="$(ADDRESS_STANDARDIZER_SOURCE)" \
		sh tools/run-check.sh
