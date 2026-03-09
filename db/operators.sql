-- Taken from https://stackoverflow.com/questions/22098706/how-to-use-regular-expression-with-any-array-operator
CREATE OR REPLACE FUNCTION commuted_regexp_match(text, text) RETURNS BOOL AS
  'SELECT $2 ~ $1;'
  LANGUAGE sql;

-- Taken from https://stackoverflow.com/a/8142998/711129
CREATE OR REPLACE FUNCTION unnest_nd_1d(a anyarray, OUT a_1d anyarray)
  RETURNS SETOF anyarray
  LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE STRICT AS
$func$
BEGIN
  IF a = '{}' THEN
    a_1d = '{}';
    RETURN NEXT;
  ELSE
    FOREACH a_1d SLICE 1 IN ARRAY a LOOP
      RETURN NEXT;
    END LOOP;
  END IF;
END
$func$;

CREATE OPERATOR ~!@# (
  procedure = commuted_regexp_match(text, text),
  leftarg = text,
  rightarg = text
);

-- Taken from https://stackoverflow.com/a/42939388/711129
create aggregate hstore_agg(hstore) (
  sfunc = hs_concat(hstore, hstore),
  stype = hstore
);
