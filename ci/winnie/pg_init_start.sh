#!/usr/bin/env bash
#This is script to launch custom compiled PostgreSQL
. $(dirname $0)/winnie_common.sh


export PGDATA=$PGPATHEDB/data_${PGPORT}
# What to use to shut down the postmaster
PGCTL="$PGPATHEDB/bin/pg_ctl"

if [ -d $PGDATA/postmaster.pid ] ; then
	$PGCTL stop -D $PGDATA -s -m fast
fi

rm -rf $PGDATA
export PGLOG="$PGDATAEDB/pgsql_${PGPORT}.log"
# What to use to start up the postmaster
DAEMON="$PGPATHEDB/bin/pg_ctl -D $PGDATA -l $PGDATAEDB/logfile_${PGPORT} start"



# remove cluster if exists
if [ -d $PGDATA ] ; then
    if [ -d $PGDATA/postmaster.pid] ; then
    	$PGCTL stop -D $PGDATA -s -m fast
    fi;

    rm -rf $PGDATA
fi;

#initialize cluster
$PGPATHEDB/bin/initdb -E UTF8 -U postgres -A trust

echo -n "Starting PostgreSQL: "
$DAEMON &
#sleep a bit because sometimes postgres takes a bit to start up
sleep 50
echo "ok"
exit 0
