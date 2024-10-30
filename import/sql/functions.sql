CREATE OR REPLACE FUNCTION railway_no_to_null(value TEXT) RETURNS TEXT AS $$
BEGIN
  IF value = 'no' THEN
    RETURN NULL;
  END IF;
  RETURN value;
END;
$$ LANGUAGE plpgsql
    IMMUTABLE
    LEAKPROOF
    PARALLEL SAFE;

CREATE OR REPLACE FUNCTION railway_to_float(value TEXT) RETURNS FLOAT AS $$
BEGIN
  IF value ~ '^[0-9.]+$' THEN
    RETURN value::FLOAT;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql
    IMMUTABLE
    LEAKPROOF
    PARALLEL SAFE;

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

CREATE OR REPLACE FUNCTION railway_get_first_pos(pos_value TEXT) RETURNS TEXT AS $$
DECLARE
  pos_part1 TEXT;
BEGIN
  pos_part1 := substring(pos_value FROM '^(-?[0-9]+(\.[0-9]+)?)(;|$)');
  IF char_length(pos_part1) = 0 THEN
    RETURN NULL;
  END IF;
  RETURN pos_part1;
END;
$$ LANGUAGE plpgsql
    IMMUTABLE
    LEAKPROOF
    PARALLEL SAFE;

CREATE OR REPLACE FUNCTION railway_pos_round(km_pos TEXT) RETURNS NUMERIC AS $$
DECLARE
  pos_part1 TEXT;
  km_float NUMERIC(8, 3);
BEGIN
  pos_part1 := railway_get_first_pos(km_pos);
  IF pos_part1 IS NULL THEN
    RETURN NULL;
  END IF;
  km_float := pos_part1::NUMERIC(8, 3);
  km_float := round(km_float, 1);
  RETURN trunc(km_float, 1);
END;
$$ LANGUAGE plpgsql
    IMMUTABLE
    LEAKPROOF
    PARALLEL SAFE;

CREATE OR REPLACE FUNCTION railway_pos_decimal(km_pos TEXT) RETURNS CHAR AS $$
DECLARE
  pos_part1 TEXT;
  pos_parts TEXT[];
BEGIN
  IF km_pos LIKE '%,%' THEN
    RETURN 'y';
  END IF; -- a
  pos_part1 := railway_get_first_pos(km_pos);
  IF pos_part1 IS NULL THEN
    RETURN 'x';
  END IF; -- b
  pos_parts := regexp_split_to_array(pos_part1, '\.');
  IF array_length(pos_parts, 1) = 1 THEN
    RETURN '0';
  END IF; -- c
  IF pos_parts[2] SIMILAR TO '^0{0,}$' THEN
    RETURN '0';
  END IF;
  RETURN substring(pos_parts[2] FROM 1 FOR 1);
END;
$$ LANGUAGE plpgsql
    IMMUTABLE
    LEAKPROOF
    PARALLEL SAFE;

-- Convert a speed number from text to integer and miles to kilometre
CREATE OR REPLACE FUNCTION railway_speed_int(value TEXT) RETURNS INTEGER AS $$
BEGIN
  IF value ~ '^[0-9]+(\.[0-9]+)?$' THEN
    RETURN value::DOUBLE PRECISION;
  END IF;
  IF value ~ '^[0-9]+(\.[0-9]+)? ?mph$' THEN
    RETURN (substring(value FROM '^([0-9]+(\.[0-9]+)?)')::DOUBLE PRECISION) * 1.609344;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql
    IMMUTABLE
    LEAKPROOF
    PARALLEL SAFE;

-- Check whether a key is present in a hstore field and if its value is not 'no'
CREATE OR REPLACE FUNCTION railway_has_key(tags HSTORE, key TEXT) RETURNS BOOLEAN AS $$
DECLARE
  value TEXT;
BEGIN
  value := tags->key;
  IF value IS NULL THEN
    RETURN FALSE;
  END IF;
  IF value = 'no' THEN
    RETURN FALSE;
  END IF;
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql
    IMMUTABLE
    LEAKPROOF
    PARALLEL SAFE;

-- Get name for labelling in standard style depending whether it is a bridge, a tunnel or none of these two.
CREATE OR REPLACE FUNCTION railway_label_name(name TEXT, tunnel TEXT, tunnel_name TEXT, bridge TEXT, bridge_name TEXT) RETURNS TEXT AS $$
BEGIN
  IF tunnel IS NOT NULL AND tunnel != 'no' THEN
    RETURN COALESCE(tunnel_name, name);
  END IF;
  IF bridge IS NOT NULL AND bridge != 'no' THEN
    RETURN COALESCE(bridge_name, name);
  END IF;
  RETURN name;
END;
$$ LANGUAGE plpgsql
    IMMUTABLE
    LEAKPROOF
    PARALLEL SAFE;

-- Get label for electrification
CREATE OR REPLACE FUNCTION railway_electrification_label(voltage INT, frequency REAL) RETURNS TEXT AS $$
DECLARE
  volt_int INTEGER;
  volt_text TEXT;
BEGIN
  -- Grounded sections
  IF voltage = 0 THEN
    RETURN '0V';
  END IF;
  -- Round voltage nicely
  volt_int := voltage::INT;
  IF volt_int < 1000 THEN
    volt_text := voltage || 'V';
  ELSIF volt_int % 1000 = 0 THEN
    volt_text := (volt_int/1000)::TEXT || 'kV';
  ELSE
    volt_text := round((volt_int::FLOAT / 1000::FLOAT)::numeric, 1) || 'kV';
  END IF;
  -- Output voltage and frequency
  IF frequency = 0 THEN
    RETURN volt_text || ' =';
  END IF;
  IF frequency IS NOT NULL THEN
    RETURN volt_text || ' ' || frequency || 'Hz';
  END IF;
  RETURN volt_text;
END;
$$ LANGUAGE plpgsql
    IMMUTABLE
    LEAKPROOF
    PARALLEL SAFE;
