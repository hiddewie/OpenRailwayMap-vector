CREATE OR REPLACE FUNCTION railway_to_int(value TEXT) RETURNS INTEGER AS $$
BEGIN
  IF value ~ '^-?[0-9]+$' THEN
    RETURN value::INTEGER;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql
    IMMUTABLE
    LEAKPROOF
    PARALLEL SAFE;

CREATE OR REPLACE FUNCTION localize(store hstore, prefix TEXT, languages TEXT[]) RETURNS text
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  LEAKPROOF
  PARALLEL SAFE
RETURN (
  SELECT store[prefix || trim(both from lang)]
  FROM unnest(languages) lang
  WHERE store ? (prefix || trim(both from lang))
  LIMIT 1
);
