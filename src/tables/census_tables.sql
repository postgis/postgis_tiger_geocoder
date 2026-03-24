CREATE TABLE tiger.tract(
	gid serial NOT NULL,
	statefp varchar(2),
	countyfp varchar(3),
	tractce varchar(6),
	tract_id varchar(11) PRIMARY KEY,
	name varchar(7),
	namelsad varchar(20),
	mtfcc varchar(5),
	funcstat varchar(1),
	aland double precision,
	awater double precision,
	intptlat varchar(11),
	intptlon varchar(12),
	the_geom geometry(MULTIPOLYGON,4269)
);


CREATE TABLE tiger.tabblock
(
	gid serial NOT NULL,
	statefp varchar(2),
	countyfp varchar(3),
	tractce varchar(6),
	blockce varchar(4),
	tabblock_id varchar(16) PRIMARY KEY,
	name varchar(20),
	mtfcc varchar(5),
	ur varchar(1),
	uace varchar(5),
	funcstat varchar(1),
	aland double precision,
	awater double precision,
	intptlat varchar(11),
	intptlon varchar(12),
	the_geom geometry(MultiPolygon,4269)
);



CREATE TABLE tiger.tabblock20
(
    statefp character varying(2) ,
    countyfp character varying(3) ,
    tractce character varying(6) ,
    blockce character varying(4) ,
    geoid character varying(15) ,
    name character varying(10) ,
    mtfcc character varying(5) ,
    ur character varying(1) ,
    uace character varying(5) ,
    uatype character varying(1) ,
    funcstat character varying(1) ,
    aland double precision,
    awater double precision,
    intptlat character varying(11) ,
    intptlon character varying(12) ,
    the_geom geometry(MultiPolygon,4269), housing float, pop float,
    CONSTRAINT pk_tabblock20 PRIMARY KEY (geoid)
);



CREATE TABLE tiger.bg
(
	gid serial NOT NULL,
	statefp varchar(2),
	countyfp varchar(3),
	tractce varchar(6),
	blkgrpce varchar(1),
	bg_id varchar(12) PRIMARY KEY,
	namelsad varchar(13),
	mtfcc varchar(5),
	funcstat varchar(1),
	aland double precision,
	awater double precision,
	intptlat varchar(11),
	intptlon varchar(12),
	the_geom geometry(MultiPolygon,4269)
);
COMMENT ON TABLE tiger.bg IS 'block groups';


CREATE TABLE IF NOT EXISTS tiger.tract
(
	gid serial NOT NULL,
	statefp varchar(2),
	countyfp varchar(3),
	tractce varchar(6),
	tract_id varchar(11) PRIMARY KEY,
	name varchar(7),
	namelsad varchar(20),
	mtfcc varchar(5),
	funcstat varchar(1),
	aland double precision,
	awater double precision,
	intptlat varchar(11),
	intptlon varchar(12),
	the_geom geometry(MultiPolygon,4269)
);
