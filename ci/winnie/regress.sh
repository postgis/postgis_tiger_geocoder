#!/usr/bin/env bash

. $(dirname $0)/winnie_common.sh
cd ${WORKSPACE}
make sql/postgis_tiger_geocoder--TEMPLATED--TO--ANY.sql
make
make install
cp data/*.sql ${PGPATHEDB}/share/extension/
cp *.control ${PGPATHEDB}/share/extension/
make installcheck
