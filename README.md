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

This is a trusted PostgreSQL extension, meaning a non-superuser can do:

```sql
CREATE EXTENSION postgis_tiger_geocoder;
```

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
    folder by editing `tiger.loader_variables.staging_fold` table column

2. Create a folder called temp in the gisdata folder.
   This will be the folder where we extract the downloaded tiger data.

3. Run the following commands at psql or pgAdmin query window to
    generate the script, replacing 'DC', 'RI' with list of states you want
    and save contents to a .bat or sh file in YOUR CURRENT DIRECTORY. This
    will generate CODE for each state and append it to the script.

    (IF YOU ARE AT A PSQL PROMPT, FIRST RUN "\a", "\t", AND "\o
    script.xxx".  THIS WILL MAKE YOUR OUTPUT UNALIGNED AND REDIRECT IT TO
    script.xxx.  WITHOUT "\a" and "\t", THE SCRIPT WILL HAVE EXTRA
    WHITESPACE AND POSSIBLY NON-SCRIPT CHARACTERS THAT CAUSE IT TO BREAK.)

    ### UNIX /LINUX USERS
    Note even if you want just specific states you need to
    do this step since county, state tables are available only at national level

    ```sql
    SELECT loader_generate_nation_script('sh');
    ```

    After the nation load, generate a bash script suitable for Unix command lines
    for your desired states.

    ```sql
    SELECT loader_generate_script(ARRAY['DC','RI'], 'sh');
    ```

    ONCE YOU GENERATE THIS SCRIPT, EDIT IT TO ADD `set -e -u` AT THE TOP;

    THIS SETTING WILL MAKE IT STOP ON ERROR OR UNINITIALIZED VARIABLE AND
    MAKE IT EASIER TO DEBUG ANY PROBLEMS.

    THEN RUN THE SCRIPT AT THE COMMAND LINE, REDIRECTING STANDARD OUTPUT AND
    STANDARD ERROR TO USEFUL FILES.  YOU MAY WANT TO RUN `tail -f ` TO SEE THE
    STANDARD ERROR AS IT GETS WRITTEN.  FOR EXAMPLE:

    ```sh
    sh foo.sh 1>out 2>err; tail -f err
    ```
    ### WINDOWS USERS

    You will need 7zip and wget.  7zip you can get
    from http://www.7-zip.org/ and wget you can get from
    http://gnuwin32.sourceforge.net/packages/wget.htm


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

4. Next run the script to install any missing indexes.

    ```sql
    SELECT install_missing_indexes();
    ```

    Alternatively if you want to see what indexes will be created before
    you create them run the below and manually run the steps generated:
    SELECT missing_indexes_generate_script();


5. Copy and paste the generated script into a .bat or .sh file and put
    in gisdata folder you created and then run it, OR IF YOU REDIRECTED
    THE OUTPUT TO A FILE WITH "\o" MOVE THAT FILE TO GISDATA.

6. Test out the geocoder run these queries

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
