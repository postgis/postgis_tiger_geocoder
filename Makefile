
all install uninstall noop clean distclean:
	$(MAKE) -C postgis_tiger_geocoder $@

installcheck:
	$(MAKE) -C postgis_tiger_geocoder $@