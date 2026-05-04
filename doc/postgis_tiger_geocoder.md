# PostGIS Tiger Geocoder — Function Reference

A PL/pgSQL geocoder for US Census TIGER/Line data, installed into the `tiger` schema via `CREATE EXTENSION postgis_tiger_geocoder`. Covers address normalization, forward and reverse geocoding, data loaders, and topology utilities.

> **Note:** The `tiger` schema must be on the database `search_path` for all functions to resolve correctly.

Refer to the [README](../README.md#loading-data) for instructions how to load data.

---

## Table of Contents

- [Geocoding](#geocoding)
  - [Geocode](#geocode)
  - [Geocode\_Intersection](#geocode_intersection)
  - [Reverse\_Geocode](#reverse_geocode)
- [Address Normalization](#address-normalization)
  - [Normalize\_Address](#normalize_address)
  - [Pagc\_Normalize\_Address](#pagc_normalize_address)
  - [Pprint\_Addy](#pprint_addy)
- [Settings & Metadata](#settings--metadata)
  - [Get\_Geocode\_Setting](#get_geocode_setting)
  - [Set\_Geocode\_Setting](#set_geocode_setting)
  - [Get\_Tract](#get_tract)
- [Data Loaders](#data-loaders)
  - [Loader\_Generate\_Script](#loader_generate_script)
  - [Loader\_Generate\_Nation\_Script](#loader_generate_nation_script)
  - [Loader\_Generate\_Census\_Script](#loader_generate_census_script)
- [Index & Table Maintenance](#index--table-maintenance)
  - [Install\_Missing\_Indexes](#install_missing_indexes)
  - [Missing\_Indexes\_Generate\_Script](#missing_indexes_generate_script)
  - [Drop\_Indexes\_Generate\_Script](#drop_indexes_generate_script)
  - [Drop\_Nation\_Tables\_Generate\_Script](#drop_nation_tables_generate_script)
  - [Drop\_State\_Tables\_Generate\_Script](#drop_state_tables_generate_script)
- [Topology](#topology)
  - [Topology\_Load\_Tiger](#topology_load_tiger)

---

## Geocoding

### `Geocode`

Takes a US address string (or a pre-normalized `norm_addy`) and returns a set of possible matched locations. Each result includes a point geometry in NAD 83 lon/lat, a normalized address, and a numeric rating. **Lower rating = better match.** Results are sorted best-first.

**Synopsis**

```sql
setof record geocode(
    varchar   address,
    integer   max_results    = 10,
    geometry  restrict_region = NULL,
    norm_addy OUT addy,
    geometry  OUT geomout,
    integer   OUT rating
);

setof record geocode(
    norm_addy in_addy,
    integer   max_results    = 10,
    geometry  restrict_region = NULL,
    norm_addy OUT addy,
    geometry  OUT geomout,
    integer   OUT rating
);
```

**Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| `address` | `varchar` | Free-text US address, e.g. `'75 State Street, Boston MA 02109'`. |
| `in_addy` | `norm_addy` | Already-normalized address (alternative overload). |
| `max_results` | `integer` | Maximum candidates to return. Defaults to `10`. Use `1` for batch operations. |
| `restrict_region` | `geometry` | Optional geometry filter; only addresses within this region are considered. |

**Returns:** `setof record (addy norm_addy, geomout geometry, rating integer)`

**Example — single best result**

```sql
SELECT g.rating,
       ST_X(g.geomout) AS lon,
       ST_Y(g.geomout) AS lat,
       (addy).streetname,
       (addy).location,
       (addy).stateabbrev
FROM geocode('75 State Street, Boston MA 02109', 1) AS g;

-- rating=0 means exact match
```

**Example — batch geocoding**

```sql
UPDATE addresses_to_geocode
SET (rating, new_address, lon, lat) = (
    COALESCE(g.rating, -1),
    pprint_addy(g.addy),
    ST_X(g.geomout)::numeric(8,5),
    ST_Y(g.geomout)::numeric(8,5)
)
FROM (
    SELECT addid, address
    FROM addresses_to_geocode
    WHERE rating IS NULL
    ORDER BY addid LIMIT 100
) AS a
LEFT JOIN LATERAL geocode(a.address, 1) AS g ON true
WHERE a.addid = addresses_to_geocode.addid;
```

> Uses Tiger edges/faces/addr tables plus PostgreSQL fuzzy matching (`soundex`, `levenshtein`) and PostGIS line interpolation. The geocoded point is offset ~10 m from the centre-line to the correct side of the street. Enhanced in PostGIS 2.0 for Tiger 2010 structure.

---

### `Geocode_Intersection`

Geocodes a street intersection given two street names and a state, returning possible locations on the first street at the intersection point.

**Synopsis**

```sql
setof record Geocode_Intersection(
    varchar  roadway1,
    varchar  roadway2,
    varchar  in_state,
    varchar  in_city    = NULL,
    varchar  in_zip     = NULL,
    integer  max_results = 10,
    norm_addy OUT addy,
    geometry  OUT geomout,
    integer   OUT rating
);
```

**Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| `roadway1` | `varchar` | Primary street where the result point will be placed. |
| `roadway2` | `varchar` | Crossing/intersecting street name. |
| `in_state` | `varchar` | Two-character US state abbreviation, e.g. `'MA'`. |
| `in_city` | `varchar` | Optional city name to narrow candidates. |
| `in_zip` | `varchar` | Optional 5-digit ZIP code to narrow candidates. |
| `max_results` | `integer` | Maximum candidates. Defaults to `10`. |

**Returns:** `setof record (addy norm_addy, geomout geometry, rating integer)`

**Example**

```sql
SELECT pprint_addy(addy), ST_AsText(geomout), rating
FROM Geocode_Intersection(
    'State St', 'Devonshire St', 'MA',
    'Boston', '02109', 3
);
```

---

### `Reverse_Geocode`

Converts a point geometry into theoretically possible street addresses and nearby cross streets. Addresses are ordered closest-to-point first. Useful for converting GPS coordinates into human-readable addresses.

**Synopsis**

```sql
record Reverse_Geocode(
    geometry    pt,
    boolean     include_strnum_range = false,
    geometry[]  OUT intpt,
    norm_addy[] OUT addy,
    varchar[]   OUT street
);
```

**Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| `pt` | `geometry` | Input point in any known SRID; internally reprojected to Tiger's SRS. Must fall within a region where Tiger data has been loaded. |
| `include_strnum_range` | `boolean` | When `true`, cross streets include the house-number range (e.g. `'67 – 127 Massachusetts Ave'`). Defaults to `false`. |

**Returns:** `record (intpt geometry[], addy norm_addy[], street varchar[])`

| Output field | Description |
|---|---|
| `intpt` | Array of centre-line points on the nearest streets. |
| `addy` | Array of possible normalized addresses; `addy[1]` is most likely. |
| `street` | Array of cross streets or the street the point projects onto. |

**Example**

```sql
SELECT pprint_addy(r.addy[1])              AS address,
       array_to_string(r.street, ', ')     AS cross_streets
FROM reverse_geocode(
    ST_GeomFromText('POINT(-71.093902 42.359446)', 4269),
    true
) AS r;

-- → 67 Massachusetts Ave, Cambridge, MA 02139
--   67 - 127 Massachusetts Ave, 32 - 88 Vassar St
```

> Addresses are **interpolated** from Tiger street ranges, not from a building registry. A point near a corner may yield multiple candidates. Available since PostGIS 2.0; enhanced in 2.4.1 to resolve state/ZIP via zcta5 even without full state data loaded.

---

## Address Normalization

### `Normalize_Address`

Parses a free-text US street address into a structured `norm_addy` composite type. Works entirely from the lookup tables bundled in the `tiger` schema — no Census data download required.

**Synopsis**

```sql
norm_addy normalize_address(varchar in_address);
```

**Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| `in_address` | `varchar` | Free-form address string. Abbreviation variants are resolved via `direction_lookup`, `street_type_lookup`, and `state_lookup` tables in the `tiger` schema. |

**Returns:** `norm_addy` composite type

**`norm_addy` Fields**

| Field | Type | Description |
|-------|------|-------------|
| `address` | `integer` | Street number. |
| `predirAbbrev` | `varchar` | Directional prefix: `N`, `S`, `E`, `W`, `NE`, etc. |
| `streetName` | `varchar` | Street name stripped of type and directionals. |
| `streetTypeAbbrev` | `varchar` | Abbreviated street type: `St`, `Ave`, `Blvd`, `Cir`, etc. |
| `postdirAbbrev` | `varchar` | Directional suffix. |
| `internal` | `varchar` | Unit / suite / apartment designator. |
| `location` | `varchar` | City or governing province. |
| `stateAbbrev` | `varchar` | Two-character US state code. |
| `zip` | `varchar` | 5-digit ZIP code string. |
| `zip4` | `varchar` | ZIP+4 extension. *(PostGIS ≥ 2.4)* |
| `address_alphanumeric` | `varchar` | Full street number including alpha characters, e.g. `17R`. *(PostGIS ≥ 2.4)* |
| `parsed` | `boolean` | Set to `true` on successful normalization. |

**Example**

```sql
SELECT (g.na).streetname, (g.na).streettypeabbrev, (g.na).location
FROM (
    SELECT normalize_address('124 Mount Auburn St, Cambridge, MA 02138') AS na
) g;

-- streetname = 'Mount Auburn', streettypeabbrev = 'St', location = 'Cambridge'
```

---

### `Pagc_Normalize_Address`

Drop-in replacement for `Normalize_Address` using the PAGC address standardizer engine. Provides superior accuracy for alphanumeric street numbers and non-standard formats. Requires the `address_standardizer` extension.

**Synopsis**

```sql
norm_addy Pagc_Normalize_Address(varchar in_address);
```

**Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| `in_address` | `varchar` | Free-form address string. Parsed using `tiger.pagc_rules`, `tiger.pagc_gaz`, and `tiger.pagc_lex` tables, which can be customized for non-US data. |

**Returns:** `norm_addy` composite type (identical structure to `Normalize_Address`)

> Requires `CREATE EXTENSION address_standardizer` before use. The PAGC engine handles international address formats and alphanumeric house numbers better than the built-in normalizer. Available since PostGIS 2.1.

---

### `Pprint_Addy`

Formats a `norm_addy` composite back into a human-readable address string.

**Synopsis**

```sql
varchar Pprint_Addy(norm_addy in_addy);
```

**Example**

```sql
SELECT pprint_addy(normalize_address('529 Main Street, Boston MA, 02129'));
-- → '529 Main St, Boston, MA 02129'

-- Commonly used to display geocoded results:
SELECT pprint_addy(addy) AS matched_address
FROM geocode('77 Massachusetts Avenue, Cambridge, MA', 1);
```

---

## Settings & Metadata

### `Get_Geocode_Setting`

Retrieves the current value of a named setting from the `tiger.geocode_settings` control table.

**Synopsis**

```sql
text Get_Geocode_Setting(varchar setting_name);
```

**Example**

```sql
SELECT Get_Geocode_Setting('debug_geocode_address');
-- → 'false'

SELECT Get_Geocode_Setting('use_pagc_address_parser');
-- → 'false'
```

---

### `Set_Geocode_Setting`

Writes a value into the `tiger.geocode_settings` table to control geocoder behaviour.

**Synopsis**

```sql
text Set_Geocode_Setting(varchar setting_name, varchar setting_value);
```

**Common Settings**

| Setting name | Values | Description |
|---|---|---|
| `debug_geocode_address` | `'true'` / `'false'` | Enables verbose debug output for `Geocode`. |
| `debug_geocode_intersection` | `'true'` / `'false'` | Debug output for `Geocode_Intersection`. |
| `debug_normalize_address` | `'true'` / `'false'` | Debug output for `Normalize_Address`. |
| `debug_reverse_geocode` | `'true'` / `'false'` | Debug output for `Reverse_Geocode`. |
| `use_pagc_address_parser` | `'true'` / `'false'` | Switches the geocoder to use the PAGC parser internally. |

**Example**

```sql
SELECT Set_Geocode_Setting('debug_geocode_address', 'true');
```

---

### `Get_Tract`

Returns the census tract (or any other column from the Tiger tract table) that spatially contains the given geometry.

**Synopsis**

```sql
varchar Get_Tract(
    geometry the_point,
    varchar  output_field = 'name'
);
```

**Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| `the_point` | `geometry` | Input geometry (typically a point). Spatially queried against Tiger tract polygons. |
| `output_field` | `varchar` | Column from the tract table to return. Defaults to `'name'` (short tract name). Other options: `'tract_id'`, `'statefp'`, `'countyfp'`, `'namelsad'`. |

**Example**

```sql
SELECT Get_Tract(
    ST_GeomFromText('POINT(-71.1066 42.3554)', 4269),
    'tract_id'
);
-- → '25017354200'
```

---

## Data Loaders

### `Loader_Generate_Script`

Generates a platform-specific shell script that downloads Tiger/Line data for the specified states from the US Census Bureau, stages it, and loads it into the `tiger_data` schema. Each state is returned as a separate record.

**Synopsis**

```sql
setof varchar Loader_Generate_Script(
    varchar[] param_states,
    varchar   os
);
```

**Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| `param_states` | `varchar[]` | Array of two-character state abbreviations, e.g. `ARRAY['MA','RI','CT']`. |
| `os` | `varchar` | Target platform: `'sh'` (Unix/Linux/macOS) or `'windows'`. Must match a row in `tiger.loader_platform`. |

**Returns:** `setof varchar` — one shell script per state

**Example**

```sql
-- Generate load script for Massachusetts, save to file, and run
SELECT loader_generate_script(ARRAY['MA'], 'sh') AS script \gset
-- Copy the output to a .sh file, chmod +x, and run as the postgres OS user
```

> Supports Tiger 2010+ structural changes and loads census tracts, block groups, and blocks tables. The scripts reference paths configured in the `tiger.loader_platform` table — edit that table to match your environment before generating.

---

### `Loader_Generate_Nation_Script`

Generates a shell script that downloads and loads the **nationwide** county and state lookup tables required by the geocoder. Run this once before loading individual states.

**Synopsis**

```sql
varchar Loader_Generate_Nation_Script(varchar os);
```

**Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| `os` | `varchar` | Target platform: `'sh'` or `'windows'`. |

**Example**

```sql
SELECT Loader_Generate_Nation_Script('sh');
-- Save output to nation_load.sh, then run it
```

> As of PostGIS 2.4.1, optional zcta5 tabulation area loading is included in this script when enabled (off by default; adds 20–60 minutes and significant disk space). Enabling it allows `Reverse_Geocode` to resolve state/ZIP even without full per-state data.

---

### `Loader_Generate_Census_Script`

Generates a shell script that downloads only census tract, block group, and tabulation block tables for the given states. Useful when tract-level resolution is needed without full geocoding capability.

**Synopsis**

```sql
setof varchar Loader_Generate_Census_Script(
    varchar[] param_states,
    varchar   os
);
```

**Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| `param_states` | `varchar[]` | Array of two-character state abbreviations. |
| `os` | `varchar` | Target platform: `'sh'` or `'windows'`. |

**Returns:** `setof varchar` — one script per state

---

## Index & Table Maintenance

### `Install_Missing_Indexes`

Identifies all Tiger tables that are missing indexes on columns used in geocoder join and filter conditions, then **immediately creates** those indexes. Run after loading new state data to ensure optimal geocoding performance.

**Synopsis**

```sql
void Install_Missing_Indexes();
```

**Example**

```sql
SELECT Install_Missing_Indexes();
-- No output if all required indexes already exist.
```

---

### `Missing_Indexes_Generate_Script`

Like `Install_Missing_Indexes`, but returns the DDL `CREATE INDEX` statements as text instead of executing them. Useful for review or for running outside a superuser session.

**Synopsis**

```sql
text Missing_Indexes_Generate_Script();
```

**Example**

```sql
SELECT Missing_Indexes_Generate_Script();
-- Returns CREATE INDEX ... statements; review and execute manually.
```

---

### `Drop_Indexes_Generate_Script`

Generates SQL to drop all non-primary-key, non-unique indexes on the `tiger` schema and a specified data schema. Useful before a bulk data reload to speed up bulk inserts.

**Synopsis**

```sql
text Drop_Indexes_Generate_Script(varchar schema_name = 'tiger_data');
```

**Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| `schema_name` | `varchar` | Target data schema. Defaults to `tiger_data`. |

**Example**

```sql
SELECT Drop_Indexes_Generate_Script('tiger_data');
-- Returns DROP INDEX statements; execute before reloading data.
```

---

### `Drop_Nation_Tables_Generate_Script`

Generates SQL to drop all nationwide lookup tables in the specified schema — those prefixed with `county_all`, `state_all`, or a state code followed by `county` or `state`. Run before re-executing the nation loader script.

**Synopsis**

```sql
text Drop_Nation_Tables_Generate_Script(varchar schema_name = 'tiger_data');
```

**Example**

```sql
SELECT Drop_Nation_Tables_Generate_Script('tiger_data');
```

---

### `Drop_State_Tables_Generate_Script`

Generates SQL to drop all tables in the given schema prefixed with a specific US state abbreviation. Run before reloading a single state's data.

**Synopsis**

```sql
text Drop_State_Tables_Generate_Script(
    varchar state_code,
    varchar schema_name = 'tiger_data'
);
```

**Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| `state_code` | `varchar` | Two-character state abbreviation whose tables are targeted, e.g. `'MA'`. |
| `schema_name` | `varchar` | Target schema. Defaults to `tiger_data`. |

**Example**

```sql
SELECT Drop_State_Tables_Generate_Script('MA');
-- Outputs DROP TABLE statements for ma_addr, ma_edges, ma_faces, ma_place, etc.
```

---

## Topology

### `Topology_Load_Tiger`

Loads Tiger road and face data for a defined bounding region into an existing PostGIS Topology, reprojecting to the topology's spatial reference system and snapping to its precision tolerance.

**Synopsis**

```sql
varchar Topology_Load_Tiger(
    varchar topo_name,
    varchar region_by,
    varchar region_filter
);
```

**Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| `topo_name` | `varchar` | Name of the target PostGIS topology. Must already exist via `CreateTopology()`. |
| `region_by` | `varchar` | Defines how the region is specified: `'place'`, `'county'`, `'tract'`, or `'zip'`. |
| `region_filter` | `varchar` | The filter value matching `region_by` — a place name, county FIPS code, tract ID, or ZIP code. |

**Returns:** `varchar` — summary of nodes, edges, and faces loaded

**Example**

```sql
-- 1. Create topology in Massachusetts State Plane (SRID 26986)
SELECT CreateTopology('boston_topo', 26986);

-- 2. Load Tiger data for the City of Boston
SELECT Topology_Load_Tiger('boston_topo', 'place', 'Boston');
-- → 'Loaded 1234 nodes, 4567 edges, 890 faces'
```
