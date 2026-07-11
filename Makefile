include upgradeable_versions.mk
EXTENSION    = postgis_tiger_geocoder
EXTVERSION = $(shell grep default $(EXTENSION).control | cut -f2 -d'=' | tr -d "' ")
GREP = grep
PERL = perl
PG_CONFIG = pg_config
MICRO_NUMBER  = $(shell echo $(EXTVERSION) | \
						$(PERL) -pe 's/\d.\d.(\d+)[a-zA-Z]*\d*/$1/'

PREREL_NUMBER = $(shell echo $(EXTVERSION) | \
                        $(PERL) -pe 's/\d\.\d\.(.*)/\1/' | \
                        $(GREP) "[a-zA-Z]" | \
                        $(PERL) -pe 's/\d+[a-zA-Z]+(\d+)/\1/'

MICRO_PREV    = $(shell if test "$(MICRO_NUMBER)x" != "x"; then expr $(MICRO_NUMBER) - 1; fi)
PREREL_PREV   = $(shell if test "$(PREREL_NUMBER)x" != "x"; then expr $(PREREL_NUMBER) - 1; fi)

PREREL_PREFIX = $(shell echo $(EXTVERSION) | \
                        $(PERL) -pe 's/\d\.\d\.(.*)/\1/' | \
                        $(GREP) "[a-zA-Z]" | \
                        $(PERL) -pe 's/(\d+[a-zA-Z]+)\d*/\1/'

DATA_built = \
	data/$(EXTENSION).sql \
	data/$(EXTENSION)--$(EXTVERSION).sql \
	data/$(EXTENSION)--$(EXTVERSION)--ANY.sql \
	data/$(EXTENSION)--ANY--$(EXTVERSION).sql \
	$(UPGRADEABLE_VERSIONS:%=data/$(EXTENSION)--%--ANY.sql) \
	$(NULL)

REGRESS = test-normalize_address test-geocode_intersection_spacing test-upgrade
REGRESS_OPTS = --load-extension=fuzzystrmatch --load-extension=postgis --load-extension=$(EXTENSION)
TAG_UPGRADE=$(EXTENSION)--TEMPLATED--TO--ANY.sql

SQL_BITS     = $(wildcard sql_bits/*.sql)
EXTRA_CLEAN = ${SQL} expected
ADDRESS_STANDARDIZER ?=

ifeq ($(ADDRESS_STANDARDIZER),address_standardizer)
REGRESS += test-pagc_normalize_address
REGRESS_OPTS += --load-extension=address_standardizer
endif

all: data/$(TAG_UPGRADE) sql/$(EXTENSION)_pre.sql data/$(EXTENSION)--$(EXTVERSION).sql data/$(EXTENSION)--$(EXTVERSION)--ANY.sql data/$(EXTENSION)--ANY--$(EXTVERSION).sql $(UPGRADEABLE_VERSIONS:%=data/$(EXTENSION)--%--ANY.sql) sql/test-normalize_address.sql sql/test-geocode_intersection_spacing.sql sql/test-pagc_normalize_address.sql expected/test-normalize_address.out expected/test-geocode_intersection_spacing.out expected/test-pagc_normalize_address.out sql/test-upgrade.sql expected/test-upgrade.out


.PHONY: expected
expected:
	mkdir -p $@

sql:
	mkdir -p $@

data:
	mkdir -p $@

data/$(TAG_UPGRADE): | data
	echo '-- Just tag extension $(EXTENSION) version as "ANY"' > $@
	echo '-- Installed by $(EXTENSION) $(EXTVERSION)' >> $@

data/$(EXTENSION)--$(EXTVERSION).sql: data/$(EXTENSION).sql | data
	cp $< $@

data/$(EXTENSION)--$(EXTVERSION)--ANY.sql: data/$(TAG_UPGRADE) | data
	cp $< $@

expected/test-normalize_address.out: sql_bits/test_tuples_only_unaligned.sql.expected.in src/regress/normalize_address_regress | expected
	cat $^ > $@

expected/test-geocode_intersection_spacing.out: sql_bits/test_tuples_only_unaligned.sql.expected.in sql_bits/test-geocode_intersection_spacing.out.in | expected
	cat $^ > $@

expected/test-pagc_normalize_address.out: sql_bits/test_tuples_only_unaligned.sql.expected.in src/regress/pagc_normalize_address_regress | expected
	cat $^ > $@

## adding \t .. to force output to be the same as what get in regular regress in tiger folder
sql/test-normalize_address.sql: sql_bits/test_tuples_only_unaligned.sql.in src/regress/normalize_address_regress.sql | sql
	cat $^ > $@

sql/test-geocode_intersection_spacing.sql: sql_bits/test_tuples_only_unaligned.sql.in sql_bits/test-geocode_intersection_spacing.sql.in | sql
	cat $^ > $@

sql/test-upgrade.sql: sql_bits/test_tuples_only_unaligned_plain.sql.in | sql
	cat $^ > $@
	echo 'ALTER EXTENSION ${EXTENSION} UPDATE TO "ANY"; ALTER EXTENSION ${EXTENSION} UPDATE TO "$(EXTVERSION)";' >> $@
	echo "SELECT 'GT-24', position('CREATE SCHEMA IF NOT EXISTS tiger_data' in loader_generate_script(ARRAY['RI'], 'sh')) > 0;" >> $@

expected/test-upgrade.out: sql_bits/test_upgrade.out.in | expected
	cat $^ > $@

sql/test-pagc_normalize_address.sql: sql_bits/test_tuples_only_unaligned.sql.in src/regress/pagc_normalize_address_regress.sql | sql
	cat $^ > $@

sql/$(EXTENSION)_pre.sql: sql/tiger_geocoder.sql  sql_bits/mark_editable_objects.sql.in | sql
	cat $^ > $@

data/$(EXTENSION).sql: sql/$(EXTENSION)_pre.sql | data
	cat $^ > $@

data/$(EXTENSION)--ANY--$(EXTVERSION).sql: sql/tiger_geocoder_upgrade_minor.sql sql_bits/mark_editable_objects.sql.in | data
	cat $^ > $@

sql/tiger_geocoder_upgrade_minor.sql: src/utility/set_search_path.sql \
  	sql_bits/upgrade_before.sql.in \
  	src/geocode_settings.sql \
  	src/tiger_loader.sql \
	src/utility/utmzone.sql \
	src/utility/cull_null.sql \
	src/utility/regex_escape.sql \
	src/utility/nullable_levenshtein.sql \
	src/utility/levenshtein_ignore_case.sql \
	src/normalize/end_soundex.sql \
	src/normalize/count_words.sql \
	src/normalize/state_extract.sql \
	src/normalize/get_last_words.sql \
	src/normalize/location_extract_countysub_exact.sql \
	src/normalize/location_extract_countysub_fuzzy.sql \
	src/normalize/location_extract_place_exact.sql \
	src/normalize/location_extract_place_fuzzy.sql \
	src/normalize/location_extract.sql \
	src/normalize/normalize_address.sql \
	src/normalize/pprint_addy.sql \
	src/pagc_normalize/pagc_tables.sql \
  	src/pagc_normalize/pagc_normalize_address.sql \
	src/geocode/other_helper_functions.sql \
	src/geocode/rate_attributes.sql \
	src/geocode/includes_address.sql \
	src/geocode/interpolate_from_address.sql \
	src/geocode/geocode_address.sql \
	src/geocode/geocode_location.sql \
	src/geocode/geocode_intersection.sql \
	src/geocode/geocode.sql \
	src/geocode/reverse_geocode.sql \
	src/geocode/census_tracts_functions.sql \
	| sql
	cat $^ > $@

#also remove tiger_data from extension if it is part of it so data gets backed up
sql/tiger_geocoder.sql: sql_bits/norm_addy_create.sql.in \
	src/utility/set_search_path.sql \
	src/geocode_settings.sql \
	src/tables/lookup_tables_2011.sql \
	src/tables/census_tables.sql \
	src/tiger_loader.sql \
	src/utility/set_search_path.sql \
	src/utility/utmzone.sql \
	src/utility/cull_null.sql \
	src/utility/regex_escape.sql \
	src/utility/nullable_levenshtein.sql \
	src/utility/levenshtein_ignore_case.sql \
	src/normalize/end_soundex.sql \
	src/normalize/count_words.sql \
	src/normalize/state_extract.sql \
	src/normalize/get_last_words.sql \
	src/normalize/location_extract_countysub_exact.sql \
	src/normalize/location_extract_countysub_fuzzy.sql \
	src/normalize/location_extract_place_exact.sql \
	src/normalize/location_extract_place_fuzzy.sql \
	src/normalize/location_extract.sql \
	src/normalize/normalize_address.sql \
	src/normalize/pprint_addy.sql \
	src/pagc_normalize/pagc_tables.sql \
    src/pagc_normalize/pagc_normalize_address.sql \
	src/geocode/other_helper_functions.sql \
	src/geocode/rate_attributes.sql \
	src/geocode/includes_address.sql \
	src/geocode/interpolate_from_address.sql \
	src/geocode/geocode_address.sql \
	src/geocode/geocode_location.sql \
	src/geocode/geocode_intersection.sql \
	src/geocode/geocode.sql \
	src/geocode/reverse_geocode.sql \
	src/geocode/census_tracts_functions.sql \
	src/topology/tiger_topology_loader.sql \
	| sql
	cat $^ > $@

.PHONY: upgrade

upgrade: $(UPGRADEABLE_VERSIONS:%=data/$(EXTENSION)--%--ANY.sql)

# Pattern rule: builds data/$(EXTENSION)--<version>--ANY.sql for each
# version in UPGRADEABLE_VERSIONS. Named to match what DATA_built (and
# PGXS's "all" target) actually asks for, unlike the old rule which only
# defined phony targets named after the bare version numbers.
data/$(EXTENSION)--%--ANY.sql: data/$(TAG_UPGRADE) | data
	cp "$<" "$@"

#only extension files
EXTRA_CLEAN += $(wildcard expected/*--*.out) $(wildcard results/*--*.out)

#include upgrade-paths-rules.mk

distclean: clean

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
