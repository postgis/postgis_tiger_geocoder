# postgis_tiger_geocoder 2025.1dev

2026/xx/xx

## Breaking Changes

- `postgis_tiger_geocoder` moved out of the main PostGIS tree into its own
  repository during the PostGIS 3.7 cycle (Paul Ramsey)

## Enhancements

- #6013, update the geocoder to load TIGER 2025 data (Regina Obe)

## Bug Fixes

- #1599, improve country-aware address normalization in `normalize_address()`
  and related wrapper paths (Darafei Praliaskouski)
- #2459, speed up `pagc_normalize_address()` by avoiding redundant wrapper
  parsing while preserving ZIP+4 and country details from the structured parser
  (Darafei Praliaskouski)
- #1461, `geocode_intersection()` now tolerates irregular spacing in highway
  names such as `I- 635` vs `I-635` (Darafei Praliaskouski)
- Restore PAGC tables and `pagc_normalize_address()` support in `CREATE
  EXTENSION` builds when `address_standardizer` is used for geocoding
  (Regina Obe)
- Schema qualify extension dependencies for PostgreSQL 16 and above
  (Regina Obe)
