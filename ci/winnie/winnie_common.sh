# Common code for all winnie scripts
#
# TODO: add more shared code, I guess
#

set -e

export PROJECTS=/projects
# Don't convert paths
# See https://trac.osgeo.org/postgis/ticket/5436#comment:5
export MSYS2_ARG_CONV_EXCL=/config/tags
#jenkins configs
#export PG_VER=18
#export OS_BUILD=64
#export GCC_TYPE=
export PGPORT=540${PG_VER}

export LZ4_PATH=${PROJECTS}/lz4/rel-lz4-${LZ4_VER}w${OS_BUILD}${GCC_TYPE}
echo ${PATH}

PATH="/mingw64/bin:/usr/local/bin:/usr/bin:/bin:/c/Windows/System32:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl"

export PROJECTS=/projects
export MINGPROJECTS=/projects
export OS_BUILD=64
export GCC_TYPE=


if [ "$OS_BUILD" == "64" ] ; then
	export MINGHOST=x86_64-w64-mingw32
else
	export MINGHOST=i686-w64-mingw32
fi;

# wORKSPACE passed in by jenkins
#export WORKSPACE=

echo Workspace is: $WORKSPACE

echo PATH BEFORE: $PATH

export PGUSER=postgres
#export GEOS_VER=3.4.0dev
#export GDAL_VER=1.9.1
export PGPATH=${PROJECTS}/postgresql/rel/pg${PG_VER}w${OS_BUILD}${GCC_TYPE}
export PGPATHEDB=${PROJECTS}/postgresql/rel/pg${PG_VER}w${OS_BUILD}${GCC_TYPE}edb

export PATH="${PGPATH}/bin:${PGPATH}/lib:${PATH}"
CPPFLAGS="-I${PGPATH}/include"

#add lz4
export PATH="${LZ4_PATH}/bin:${LZ4_PATH}/lib:${PATH}"

if  [[ "${OVERRIDE}" == '' ]] ; then
	export GEOS_VER=3.15
	export GDAL_VER=3.9.2
	export PROJ_VER=8.2.1
	export SFCGAL_VER=2.2.0
	export CGAL_VER=6.0.1
	export ICON_VER=1.17
	export ZLIB_VER=1.2.13
	export PROTOBUF_VER=3.2.0
	export PROTOBUFC_VER=1.2.1
	export JSON_VER=0.16
	export PROJSO=libproj_8_2.dll
	export LZ4_VER=1.9.3
fi;

#set to something even if override is on but not set
if  [[ "${LIBXML_VER}" == '' ]] ; then
  export LIBXML_VER=2.12.5
fi;

export PROJ_PATH=${PROJECTS}/proj/rel-proj-${PROJ_VER}w${OS_BUILD}${GCC_TYPE}
export PROJ_DATA=/${PROJECTS}/proj/rel-proj-${PROJ_VER}w${OS_BUILD}${GCC_TYPE}/share/proj
export PROJ_LIB=/${PROJECTS}/proj/rel-proj-${PROJ_VER}w${OS_BUILD}${GCC_TYPE}/share/proj

export PATH="${PROJECTS}/geos/rel-${GEOS_VER}w${OS_BUILD}${GCC_TYPE}/bin:${PROJECTS}/gdal/rel-${GDAL_VER}w${OS_BUILD}${GCC_TYPE}/bin:${PROJECTS}/rel-libiconv-${ICON_VER}w${OS_BUILD}${GCC_TYPE}/lib:${PROJECTS}/rel-libiconv-${ICON_VER}w${OS_BUILD}${GCC_TYPE}/include:${PROJECTS}/rel-libiconv-${ICON_VER}w${OS_BUILD}${GCC_TYPE}/bin:${PROJ_PATH}/bin:${PROJECTS}/libxml/rel-libxml2-${LIBXML_VER}w${OS_BUILD}${GCC_TYPE}/bin:${PROJECTS}/zlib/rel-zlib-${ZLIB_VER}w${OS_BUILD}${GCC_TYPE}/bin:${PROJECTS}/zlib/rel-zlib-${ZLIB_VER}w${OS_BUILD}${GCC_TYPE}/lib:${PATH}"



#add protobuf
export PATH="${PROJECTS}/protobuf/rel-${PROTOBUF_VER}w${OS_BUILD}${GCC_TYPE}/bin:${PROJECTS}/protobuf/rel-${PROTOBUF_VER}w${OS_BUILD}${GCC_TYPE}/lib:${PATH}"
cd ${WORKSPACE}
#
# To set the version,from control file if not passed in
#
if  [[ "${TG_VER}" == '' ]] ; then
	export TG_VER=$(shell grep default postgis_tiger_geocoder.control | cut -f2 -d'=' | tr -d "' ")
fi;

echo "PATH AFTER: $PATH"
