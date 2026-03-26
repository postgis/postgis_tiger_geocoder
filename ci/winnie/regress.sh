#!/usr/bin/env bash

. $(dirname $0)/winnie_common.sh
cd ${WORKSPACE}
#make sql/postgis_tiger_geocoder--TEMPLATED--TO--ANY.sql
make clean
make
make install
export ADDRESS_STANDARDIZER='address_standardizer'
export err_status=0
cp data/*.sql ${PGPATHEDB}/share/extension/
cp *.control ${PGPATHEDB}/share/extension/
make installcheck
err_status=$?

if [ -d $PGDATA/postmaster.pid ] ; then
	$PGCTL stop -D $PGDATA -s -m fast
fi
exit $err_status

