# 2025.1

2026/06/22
This version requires PostgreSQL 16 and above

## Breaking Changes

- Remove support for PostgreSQL < 16 (Regina Obe)
- `postgis_tiger_geocoder` moved out of the main PostGIS tree into its own
  repository during the PostGIS 3.7 cycle (Paul Ramsey, Regina Obe)
- quote_ident tiger loader schema and table names (Paul Ramsey)
- No longer set search path of database to include tiger.
  Users are expected to do this themselves.
- Refer to [README](https://gitea.osgeo.org/postgis/postgis_tiger_geocoder#readme) for guidance (Regina Obe)

## Security

- [GT-26](https://gitea.osgeo.org/postgis/postgis_tiger_geocoder/pulls/26), quote_ident tiger loader schema and table names (Paul Ramsey)
- [GT-3](https://gitea.osgeo.org/postgis/postgis_tiger_geocoder/pulls/3), Prefix operators with system name space (Paul Ramsey)

## Enhancements

- [TR-6013](https://trac.osgeo.org/postgis/ticket/6013), update the geocoder to load TIGER 2025 data (Regina Obe)

## Bug Fixes

- [GT-2](https://gitea.osgeo.org/postgis/postgis_tiger_geocoder/issues/2), strip trailing country
  names before built-in `normalize_address()` parsing
- [GT-10](https://gitea.osgeo.org/postgis/postgis_tiger_geocoder/issues/10), support `SH` and compact
  `SH121` input for state-highway geocoding
- [GT-13](https://gitea.osgeo.org/postgis/postgis_tiger_geocoder/issues/13), generate SP-GiST indexes
  for `missing_indexes_generate_script()` LIKE-search helpers
- [GT-20](https://gitea.osgeo.org/postgis/postgis_tiger_geocoder/issues/20), escape user-provided address fragments before
  interpolating them into `normalize_address()` regular expressions
- [GT-24](https://gitea.osgeo.org/postgis/postgis_tiger_geocoder/pulls/24), create `tiger_data` schema from shell tiger loader scripts
			  (Darafei Praliaskouski)
- [TR-1599](https://trac.osgeo.org/postgis/ticket/1599), [73892dce](https://gitea.osgeo.org/postgis/postgis_tiger_geocoder/commit/73892dce), improve country-aware address normalization in `normalize_address()`
  and related wrapper paths (Darafei Praliaskouski)
- [TR-2459](https://trac.osgeo.org/postgis/ticket/2459), [73892dce](https://gitea.osgeo.org/postgis/postgis_tiger_geocoder/commit/73892dce), speed up `pagc_normalize_address()` by avoiding redundant wrapper
  parsing while preserving ZIP+4 and country details from the structured parser
  (Darafei Praliaskouski)
- [TR-1461](https://trac.osgeo.org/postgis/ticket/1461), [73892dce](https://gitea.osgeo.org/postgis/postgis_tiger_geocoder/commit/73892dce), `geocode_intersection()` now tolerates irregular spacing in highway
  names such as `I- 635` vs `I-635` (Darafei Praliaskouski)
