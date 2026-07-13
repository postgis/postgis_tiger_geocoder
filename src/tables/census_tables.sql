DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_inherits i JOIN pg_catalog.pg_class pc ON pc.oid = i.inhparent JOIN pg_catalog.pg_namespace pn ON pn.oid = pc.relnamespace WHERE pn.nspname = 'tiger' AND pc.relname = 'tract') THEN
    ALTER TABLE tiger.tract RENAME TO tract_inherited;
  END IF;
END $$;
CREATE TABLE IF NOT EXISTS tiger.tract(
  gid serial NOT NULL,
  statefp varchar(2) NOT NULL,
  countyfp varchar(3),
  tractce varchar(6),
  tract_id varchar(11) NOT NULL,
  name varchar(7),
  namelsad varchar(20),
  mtfcc varchar(5),
  funcstat varchar(1),
  aland double precision,
  awater double precision,
  intptlat varchar(11),
  intptlon varchar(12),
  the_geom geometry(MULTIPOLYGON,4269),
  PRIMARY KEY (statefp, tract_id)
) PARTITION BY LIST (statefp);
CREATE INDEX IF NOT EXISTS idx_tiger_tract_the_geom_gist ON tiger.tract USING gist(the_geom);

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_inherits i JOIN pg_catalog.pg_class pc ON pc.oid = i.inhparent JOIN pg_catalog.pg_namespace pn ON pn.oid = pc.relnamespace WHERE pn.nspname = 'tiger' AND pc.relname = 'tabblock') THEN
    ALTER TABLE tiger.tabblock RENAME TO tabblock_inherited;
  END IF;
END $$;
CREATE TABLE IF NOT EXISTS tiger.tabblock(
  gid serial NOT NULL,
  statefp varchar(2) NOT NULL,
  countyfp varchar(3),
  tractce varchar(6),
  blockce varchar(4),
  tabblock_id varchar(16) NOT NULL,
  name varchar(20),
  mtfcc varchar(5),
  ur varchar(1),
  uace varchar(5),
  funcstat varchar(1),
  aland double precision,
  awater double precision,
  intptlat varchar(11),
  intptlon varchar(12),
  the_geom geometry(MultiPolygon,4269),
  PRIMARY KEY (statefp, tabblock_id)
) PARTITION BY LIST (statefp);

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_inherits i JOIN pg_catalog.pg_class pc ON pc.oid = i.inhparent JOIN pg_catalog.pg_namespace pn ON pn.oid = pc.relnamespace WHERE pn.nspname = 'tiger' AND pc.relname = 'tabblock20') THEN
    ALTER TABLE tiger.tabblock20 RENAME TO tabblock20_inherited;
  END IF;
END $$;
CREATE TABLE IF NOT EXISTS tiger.tabblock20(
  statefp character varying(2) NOT NULL,
  countyfp character varying(3),
  tractce character varying(6),
  blockce character varying(4),
  geoid character varying(15) NOT NULL,
  name character varying(10),
  mtfcc character varying(5),
  ur character varying(1),
  uace character varying(5),
  uatype character varying(1),
  funcstat character varying(1),
  aland double precision,
  awater double precision,
  intptlat character varying(11),
  intptlon character varying(12),
  the_geom geometry(MultiPolygon,4269), housing float, pop float,
  PRIMARY KEY (statefp, geoid)
) PARTITION BY LIST (statefp);
CREATE INDEX IF NOT EXISTS idx_tiger_tabblock20_the_geom_gist ON tiger.tabblock20 USING gist(the_geom);

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_inherits i JOIN pg_catalog.pg_class pc ON pc.oid = i.inhparent JOIN pg_catalog.pg_namespace pn ON pn.oid = pc.relnamespace WHERE pn.nspname = 'tiger' AND pc.relname = 'bg') THEN
    ALTER TABLE tiger.bg RENAME TO bg_inherited;
  END IF;
END $$;
CREATE TABLE IF NOT EXISTS tiger.bg(
  gid serial NOT NULL,
  statefp varchar(2) NOT NULL,
  countyfp varchar(3),
  tractce varchar(6),
  blkgrpce varchar(1),
  bg_id varchar(12) NOT NULL,
  namelsad varchar(13),
  mtfcc varchar(5),
  funcstat varchar(1),
  aland double precision,
  awater double precision,
  intptlat varchar(11),
  intptlon varchar(12),
  the_geom geometry(MultiPolygon,4269),
  PRIMARY KEY (statefp, bg_id)
) PARTITION BY LIST (statefp);
CREATE INDEX IF NOT EXISTS idx_tiger_bg_the_geom_gist ON tiger.bg USING gist(the_geom);
COMMENT ON TABLE tiger.bg IS 'block groups';
