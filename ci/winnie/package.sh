#!/usr/bin/env bash
### this script is used to zip up the compiled binaries
## PostgreSQL, OS_BUILD denote the last build to be packaged
## and are passed in by the jenkins job process
###

. $(dirname $0)/winnie_common.sh
cd ${WORKSPACE}

export REL_PGVER=${PG_VER//./} #strip the period


export RELDIR=${PROJECTS}/postgis_tiger_geocoder/builds/${TG_VER}
export RELVERDIR=postgis_tiger_geocoder-pg${REL_PGVER}-${TG_VER}w${OS_BUILD}${GCC_TYPE}

outdir="${RELDIR}/${RELVERDIR}"
package="${RELDIR}/${RELVERDIR}.zip"
verfile="${RELDIR}/${RELVERDIR}/version.txt"
rm -rf $outdir
rm -f $package
mkdir -p $outdir
mkdir -p $outdir/share/extension

echo "POSTGIS_TIGER_GEOCODER: ${TG_VER} https://gitea.osgeo.org/postgis/postgis_tiger_geocoder.git" > $verfile

cp -r *.control ${outdir}/share/extension
cp -r data/*.sql ${outdir}/share/extension
cp -r README.md ${outdir}/


cd ${RELDIR}
zip -r $package ${RELVERDIR}
md5sum $package > ${package}.md5

cp $package ${PROJECTS}/postgis/win_web/download/windows/pg${REL_PGVER}/buildbot
cp ${package}.md5 ${PROJECTS}/postgis/win_web/download/windows/pg${REL_PGVER}/buildbot

