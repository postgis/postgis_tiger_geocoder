# TIGER GEOCODER

postgis_tiger_geocoder PostgreSQL extension used to be part of the postgis project base.
Project history notes, including the standalone split from PostGIS and recent
standalone changes, live in [NEWS.md](NEWS.md).

PostgreSQL 16 or higher is required.


## Building the extension
```sh
make
make -j check
```

`make check` builds the extension, installs it into a temporary location,
starts a temporary PostgreSQL cluster, runs the regressions, and removes the
scratch files afterward. This self-contained flow requires PostgreSQL 16 or
newer because it uses `extension_control_path`.

If a sibling checkout exists at `../address_standardizer`, `make check`
automatically includes the PAGC normalization regressions as part of the full
suite. You can force or disable that behavior explicitly:

```sh
WITH_ADDRESS_STANDARDIZER=1 ADDRESS_STANDARDIZER_SOURCE=/path/to/address_standardizer make check
WITH_ADDRESS_STANDARDIZER=0 make check
```

To keep the temporary install tree and cluster around for debugging:

```sh
KEEP_CHECK_ARTIFACTS=1 make check
```

For older PostgreSQL versions, use the installed-extension flow against an
existing server:

```sh
make
make installcheck
```

## Installing the extension

This is a trusted PostgreSQL extension, meaning a non-superuser can do
below.  Note it does assume non-trusted extensions postgis are already installed
if a non-super user is installing:

```sql
CREATE EXTENSION postgis_tiger_geocoder CASCADE;
```

After install, make sure to add tiger to your database search_path e.g.
Replace *mydb* with the name of your database.

```sql
ALTER DATABASE mydb SET search_path="$user",public,tiger;
```

For better address standardizing options also install
```sql
CREATE EXTENSION address_standardizer;
```

## Upgrading

```sql
ALTER EXTENSION postgis UPDATE;
ALTER EXTENSION postgis_tiger_geocoder UPDATE;
```

If you made custom entries or changes to **tiger.loader_platform** and **tiger.loader_variables** you may need to update these.


## Verifying install

To confirm your install is working correctly, run this sql in your database:

```sql
SELECT na.address, na.streetname,na.streettypeabbrev, na.zip
	FROM normalize_address('1 Devonshire Place, Boston, MA 02109') AS na;
```

will output:

```
 address | streetname | streettypeabbrev |  zip
---------+------------+------------------+-------
       1 | Devonshire | Pl               | 02109
(1 row)
```

# Pre-Data Load Requirements
## Linux/Unix/Mac users

You will need wget, shp2pgsql, and unzip installed.

Once you generate the scripts using loader function, EDIT IT TO ADD `set -e -u` AT THE TOP;

THIS SETTING WILL MAKE IT STOP ON ERROR OR UNINITIALIZED VARIABLE AND
MAKE IT EASIER TO DEBUG ANY PROBLEMS.

THEN RUN THE SCRIPT AT THE COMMAND LINE, REDIRECTING STANDARD OUTPUT AND
STANDARD ERROR TO USEFUL FILES.  YOU MAY WANT TO RUN `tail -f ` TO SEE THE
STANDARD ERROR AS IT GETS WRITTEN.  FOR EXAMPLE:

```sh
sh foo.sh 1>out 2>err; tail -f err
```

## Windows Users

You will need 7zip and wget.  7zip you can get
from http://www.7-zip.org/ and wget you can get from
https://eternallybored.org/misc/wget/


To generate a WINDOWS DOS script
this will generate the script to download the national layers
Note even if you want just specific states you need to
do this step since 2011 county, state tables are available only at national level

```sql
SELECT loader_generate_nation_script('windows');
```

This you do after the nation load and for states you want:

```sql
SELECT loader_generate_script(ARRAY['DC','RI'], 'windows');
```

If your script disappears without loading anything,
most likely one of your path settings is wrong.
To troubleshoot run the batch script by
first opening up a commandline and executing the file.

That will keep the window open for you to see the error.


## Loading data

PostGIS tiger geocoder includes loader scripts that are portable between Linux and
Windows but loads a full state of data at a time.  The loader helper tables and
functions are prefixed with *loader* and stored in the *tiger* schema.  If
you only want to load a county, revise the wget call that is generated
for the state to just download the statewide and specific counties or
just download them by hand.  The loader will only process files that
exist.



1. Create a folder called *gisdata* on root of server or your local pc
    if you have a fast network connection to the server. This folder is
    where the tiger files will be downloaded to.

    Note you may customize the location of this
    folder by editing `tiger.loader_variables.staging_fold` table column.

2. Create a folder called temp in the gisdata folder.
   This will be the folder where we extract the downloaded tiger data.

3.  Create a new record in `tiger.loader_platform` table with the paths of your executables and server.
    This insures your customizations aren't overwritten if you upgrade.
    There is a sample `sh` and `windows` provided.

    So for example to create a profile called **debbie** that follows `sh` convention. You would do:

    ```sql
    INSERT INTO tiger.loader_platform(os, declare_sect, pgbin, wget, unzip_command, psql, path_sep,
            loader, environ_set_command, county_process_command)
    SELECT 'debbie', declare_sect, pgbin, wget, unzip_command, psql, path_sep,
        loader, environ_set_command, county_process_command
    FROM tiger.loader_platform
    WHERE os = 'sh';
    ```
    And then edit the paths in the declare_sect column to those that fit Debbie's pg, unzip,shp2pgsql, psql, etc path locations.

    If you don't edit this loader_platform table, it will just contain common case locations of items and you'll have to edit the generated script after the script is generated.

4.  The Zip code-5 digit tabulation area zcta5 load step is turned off by default because it takes quite a bit of time to load (20 to 60 minutes)
    , takes up quite a bit of disk space, and is not used that often.

    To enable it, do the following. Note this takes a longer time to load because of cleanup after processing applied to split into states.

    ```sql
    UPDATE tiger.loader_lookuptables SET load = true WHERE table_name = 'zcta520';
    ```

    If present the Geocode function can use it if a boundary filter is added to limit to just zips in that boundary. The Reverse_Geocode function uses it if the returned address is missing a zip, which often happens with highway reverse geocoding.

5.  Then run the `Loader_Generate_Nation_Script` SQL function make sure to use the name of your
    custom profile and copy the script to a .sh or .bat file. So for example to build the nation load:

    Note even if you want just specific states you need to
    do this step since county, state tables are available only at national level

    If you want to dump directly to file, use PSQL
    ```bash
    psql -c "SELECT Loader_Generate_Nation_Script('debbie')" -h localhost -d geocoder -tA > /gisdata/nation_script_load.sh
    ```

    or alternatively just copy and paste the commands from SQL output
    ```sql
    SELECT Loader_Generate_Nation_Script('debbie');
    ```



6. After you are done running the nation script, you should have three tables in your tiger_data schema and they should be filled with data. Confirm you do by doing the following queries from psql or pgAdmin

    ```sql
    SELECT count(*) FROM tiger_data.county_all;
    ```
    ```
     count
    -------
    3235
    (1 row)
    ```

    ```sql
    SELECT count(*) FROM tiger_data.state_all;
    ```
    ```
    count
    -------
        56
    (1 row)
    ```

    ```sql
    SELECT count(*) FROM tiger_data.zcta5_all;
    ```
    ```
    count
    -------
      33933
    (1 row)
    ```

7.  By default the tables corresponding to **bg**, **tract**, **tabblock20** are not loaded.
    These tables are not used by the geocoder but are used by folks for population statistics.
    If you wish to load them as part of your state loads, run the following statement to enable them.

    ```sql
    UPDATE tiger.loader_lookuptables SET load = true WHERE load = false AND lookup_name IN('tract', 'bg', 'tabblock20');
    ```
8. Next load states:

    ```sql
    psql -c "SELECT Loader_Generate_Script(ARRAY['DC','MA'], 'debbie')" -d geocoder -tA > /gisdata/dc_ma_load.sh
    ```
9. Next run the script to install any missing indexes and vacuum and analyze

    If you want to see what indexes will be created before
    you create them run the below and manually run the steps generated if you prefer:

    ```sql
    SELECT missing_indexes_generate_script();
    ```

    This will actually execute the create index steps without showing
    ```sql
    SELECT install_missing_indexes();
    ```

    Then analyze your tables so stats are up to date

    ```sql
    vacuum (analyze, verbose) tiger.addr;
    vacuum (analyze, verbose) tiger.edges;
    vacuum (analyze, verbose) tiger.faces;
    vacuum (analyze, verbose) tiger.featnames;
    vacuum (analyze, verbose) tiger.place;
    vacuum (analyze, verbose) tiger.cousub;
    vacuum (analyze, verbose) tiger.county;
    vacuum (analyze, verbose) tiger.state;
    vacuum (analyze, verbose) tiger.zcta5;
    vacuum (analyze, verbose) tiger.zip_lookup_base;
    vacuum (analyze, verbose) tiger.zip_state;
    vacuum (analyze, verbose) tiger.zip_state_loc;
    ```



10. Test out the geocoder run these queries

    To get the best rated answer
    this is generally faster

    ```sql
    SELECT g.rating,
        ST_X(geomout) As lon,
        ST_Y(geomout) As lat, (addy).*
    FROM geocode('1731 New Hampshire Avenue Northwest, Washington, DC 20010', 1) As g;
    ```

    To get multiple answers if there is more than 1:

    ```sql
    SELECT g.rating,
        ST_X(geomout) As lon,
        ST_Y(geomout) As lat, (addy).*
    FROM geocode('1731 New Hampshire Avenue Northwest, Washington, DC 20010') As g;
    ```

## CI Status

**Winnie**: [![Build Status](https://winnie.postgis.net/view/postgis_tiger_geocoder/job/postgis_tiger_geocoder_main/badge/icon)](https://winnie.postgis.net/view/postgis_tiger_geocoder/job/postgis_tiger_geocoder_main/)

**Woodie**: [![status-badge](https://woodie.osgeo.org/api/badges/131/status.svg)](https://woodie.osgeo.org/repos/131)
