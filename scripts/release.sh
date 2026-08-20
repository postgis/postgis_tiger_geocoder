#!/bin/sh
# Build extension tarballs and prepare release metadata for postgis_tiger_geocoder.
#
# Usage: CI_COMMIT_TAG=x.y sh scripts/release.sh
#    or: sh scripts/release.sh x.y
#
# Produces in the working directory:
#   postgis_tiger_geocoder-pg{16,17,18,19}-<version>.tar.gz
#   release_title.txt
#   release_notes.md
set -e

VERSION="${1:-${CI_COMMIT_TAG:-}}"
if [ -z "$VERSION" ]; then
	echo "usage: $0 VERSION" >&2
	exit 1
fi

REPO_URL="https://gitea.osgeo.org/postgis/postgis_tiger_geocoder.git"

# ── extension tarballs ────────────────────────────────────────────────
for PGVER in 16 17 18 19; do
	export PATH="/usr/lib/postgresql/${PGVER}/bin:${PATH}"
	echo "building for PostgreSQL ${PGVER}"
	pg_config --version

	make clean
	make

	PKG="postgis_tiger_geocoder-pg${PGVER}-${VERSION}"
	rm -rf "${PKG}" "${PKG}.tar.gz"
	mkdir -p "${PKG}/share/extension"

	echo "POSTGIS_TIGER_GEOCODER: ${VERSION} ${REPO_URL}" > "${PKG}/version.txt"
	cp *.control          "${PKG}/share/extension/"
	cp data/*.sql         "${PKG}/share/extension/"
	cp README.md          "${PKG}/"
	tar -czf "${PKG}.tar.gz" "${PKG}"
	rm -rf "${PKG}"
	echo "  ${PKG}.tar.gz"
done

# ── release notes ────────────────────────────────────────────────────
echo "${VERSION}" > release_title.txt

sed -n "/^# ${VERSION}/,/^# /{ /^# ${VERSION}/d; /^#/d; p; }" NEWS.md > release_notes.md

echo "release metadata written to release_title.txt and release_notes.md"
