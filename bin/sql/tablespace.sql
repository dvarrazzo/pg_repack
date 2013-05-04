SET client_min_messages = warning;

--
-- Tablespace features tests
--
-- Note: in order to pass this test you must create a tablespace called 'testts'
--

SELECT
    case when 0 = (select count(*) FROM pg_tablespace WHERE spcname = 'testts')
    then 'You must create a ''testts'' tablespace to run these tests'::text
    else null end;

CREATE TABLE testts1 (id serial primary key, data text);
CREATE INDEX testts1_partial_idx on testts1 (id) where (id > 0);
CREATE INDEX testts1_with_idx on testts1 (id) with (fillfactor=80);
INSERT INTO testts1 (data) values ('a');
INSERT INTO testts1 (data) values ('b');
INSERT INTO testts1 (data) values ('c');

-- can move the tablespace from default
\! pg_repack --dbname=contrib_regression --no-order --table=testts1 --tablespace testts

SELECT relname, spcname
FROM pg_class JOIN pg_tablespace ts ON ts.oid = reltablespace
WHERE relname ~ '^testts1'
ORDER BY relname;

SELECT * from testts1 order by id;

-- tablespace stays where it is
\! pg_repack --dbname=contrib_regression --no-order --table=testts1

SELECT relname, spcname
FROM pg_class JOIN pg_tablespace ts ON ts.oid = reltablespace
WHERE relname ~ '^testts1'
ORDER BY relname;

-- can move the ts back to default
\! pg_repack --dbname=contrib_regression --no-order --table=testts1 -s pg_default

SELECT relname, spcname
FROM pg_class JOIN pg_tablespace ts ON ts.oid = reltablespace
WHERE relname ~ '^testts1'
ORDER BY relname;

-- can move the table together with the indexes
\! pg_repack --dbname=contrib_regression --no-order --table=testts1 --tablespace testts --moveidx

SELECT relname, spcname
FROM pg_class JOIN pg_tablespace ts ON ts.oid = reltablespace
WHERE relname ~ '^testts1'
ORDER BY relname;

-- can't specify --moveidx without --tablespace
\! pg_repack --dbname=contrib_regression --no-order --table=testts1 --moveidx
\! pg_repack --dbname=contrib_regression --no-order --table=testts1 -S

-- not broken with order
\! pg_repack --dbname=contrib_regression -o id --table=testts1 --tablespace pg_default --moveidx
