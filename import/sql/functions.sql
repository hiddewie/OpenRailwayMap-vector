CREATE OR REPLACE FUNCTION railway_no_to_null(value TEXT) RETURNS TEXT AS $$
BEGIN
  IF value = 'no' THEN
    RETURN NULL;
  END IF;
  RETURN value;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION railway_to_float(value TEXT) RETURNS FLOAT AS $$
BEGIN
  IF value ~ '^[0-9.]+$' THEN
    RETURN value::FLOAT;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION railway_to_int(value TEXT) RETURNS INTEGER AS $$
BEGIN
  IF value ~ '^-?[0-9]+$' THEN
    RETURN value::INTEGER;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

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
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION railway_pos_round(km_pos TEXT) RETURNS NUMERIC AS $$
DECLARE
  pos_part1 TEXT;
  km_float NUMERIC(8, 3);
  int_part INTEGER;
BEGIN
  pos_part1 := railway_get_first_pos(km_pos);
  IF pos_part1 IS NULL THEN
    RETURN NULL;
  END IF;
  km_float := pos_part1::NUMERIC(8, 3);
  km_float := round(km_float, 1);
  RETURN trunc(km_float, 1);
END;
$$ LANGUAGE plpgsql;


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
$$ LANGUAGE plpgsql;

-- Is this speed in imperial miles per hour?
-- Returns 1 for true, 0 for false
CREATE OR REPLACE FUNCTION railway_speed_imperial(value TEXT) RETURNS INTEGER AS $$
BEGIN
  IF value ~ '^[0-9]+(\.[0-9]+)? ?mph$' THEN
    RETURN 1;
  END IF;
  RETURN 0;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION railway_imperial_flags(value1 TEXT, value2 TEXT) RETURNS INTEGER[] AS $$
BEGIN
  RETURN ARRAY[railway_speed_imperial(value1), railway_speed_imperial(value2)];
END;
$$ LANGUAGE plpgsql;


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
$$ LANGUAGE plpgsql;

-- Convert a speed number from text to integer but not convert units
CREATE OR REPLACE FUNCTION railway_speed_int_noconvert(value TEXT) RETURNS INTEGER AS $$
BEGIN
  IF value ~ '^[0-9]+(\.[0-9]+)?$' THEN
    RETURN value::DOUBLE PRECISION;
  END IF;
  IF value ~ '^[0-9]+(\.[0-9]+)? ?mph$' THEN
    RETURN substring(value FROM '^([0-9]+(\.[0-9]+)?)')::DOUBLE PRECISION;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;


-- Get the largest speed from a list of speed values (common at light speed signals)
CREATE OR REPLACE FUNCTION railway_largest_speed_noconvert(value TEXT) RETURNS INTEGER AS $$
DECLARE
  parts TEXT[];
  elem TEXT;
  largest_value INTEGER := NULL;
  this_value INTEGER;
BEGIN
  IF value IS NULL OR value = '' THEN
    RETURN NULL;
  END IF;
  parts := regexp_split_to_array(value, ';');
  FOREACH elem IN ARRAY parts
  LOOP
    IF elem = '' THEN
      CONTINUE;
    END IF;
    this_value := railway_speed_int_noconvert(elem);
    IF largest_value IS NULL OR largest_value < this_value THEN
      largest_value := this_value;
    END IF;
  END LOOP;
  RETURN largest_value;
END;
$$ LANGUAGE plpgsql;

-- Get dominant speed for coloring
CREATE OR REPLACE FUNCTION railway_dominant_speed(preferred_direction TEXT, speed TEXT, forward_speed TEXT, backward_speed TEXT) RETURNS INTEGER AS $$
BEGIN
  IF speed IS NOT NULL AND (forward_speed IS NOT NULL OR backward_speed IS NOT NULL) THEN
    RETURN NULL;
  END IF;
  IF speed IS NOT NULL THEN
    RETURN railway_speed_int(speed);
  END IF;
  IF preferred_direction = 'forward' THEN
    RETURN COALESCE(railway_speed_int(forward_speed), railway_speed_int(speed));
  END IF;
  IF preferred_direction = 'backward' THEN
    RETURN COALESCE(railway_speed_int(backward_speed), railway_speed_int(speed));
  END IF;
  RETURN railway_speed_int(forward_speed);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION null_to_dash(value TEXT) RETURNS TEXT AS $$
BEGIN
  IF value IS NULL OR VALUE = '' THEN
    RETURN '–';
  END IF;
  RETURN value;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION railway_add_unit_to_label(speed INTEGER, is_imp_flag INTEGER) RETURNS TEXT AS $$
BEGIN
  -- note: NULL || TEXT returns NULL
  IF is_imp_flag = 1 THEN
    RETURN speed::TEXT || ' mph';
  END IF;
  RETURN speed::TEXT;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION railway_speed_label(speed_arr INTEGER[]) RETURNS TEXT AS $$
BEGIN
  IF speed_arr[3] = 7 THEN
    RETURN NULL;
  END IF;
  IF speed_arr[3] = 4 THEN
    RETURN railway_add_unit_to_label(speed_arr[1], speed_arr[4]);
  END IF;
  IF  speed_arr[3] = 3 THEN
    RETURN null_to_dash(railway_add_unit_to_label(speed_arr[1], speed_arr[4])) || '/' || null_to_dash(railway_add_unit_to_label(speed_arr[2], speed_arr[5]));
  END IF;
  IF speed_arr[3] = 2 THEN
    RETURN null_to_dash(railway_add_unit_to_label(speed_arr[2], speed_arr[5])) || ' (' || null_to_dash(railway_add_unit_to_label(speed_arr[1], speed_arr[4])) || ')';
  END IF;
  IF speed_arr[3] = 1 THEN
    RETURN null_to_dash(railway_add_unit_to_label(speed_arr[1], speed_arr[4])) || ' (' || null_to_dash(railway_add_unit_to_label(speed_arr[2], speed_arr[5])) || ')';
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;


-- Add flags indicating imperial units to an array of speeds
CREATE OR REPLACE FUNCTION railway_speed_array_add_unit(arr INTEGER[]) RETURNS INTEGER[] AS $$
BEGIN
  RETURN arr || railway_speed_array_add_unit(arr[1]) || railway_speed_array_add_unit(2);
END;
$$ LANGUAGE plpgsql;

-- Get the speed limit in the primary and secondary direction.
-- No unit conversion is preformed.
-- Returns an array with 3 integers:
--   * forward speed
--   * backward speed
--   * has primary direction is line direction (1), is opposite direction of line (2), has no primary direction (3), all direction same speed (4), primary direction invalid (5), contradicting speed values (6), no speed information (7)
--   * forward unit: kph (0), mph (1)
--   * backward unit: kph (0), mph (1)
CREATE OR REPLACE FUNCTION railway_direction_speed_limit(preferred_direction TEXT, speed TEXT, forward_speed TEXT, backward_speed TEXT) RETURNS INTEGER[] AS $$
BEGIN
  IF speed IS NULL AND forward_speed IS NULL AND backward_speed IS NULL THEN
    RETURN ARRAY[NULL, NULL, 7, 0, 0];
  END IF;
  IF speed IS NOT NULL AND forward_speed IS NULL AND backward_speed IS NULL THEN
    RETURN ARRAY[railway_speed_int_noconvert(speed), railway_speed_int_noconvert(speed), 4] || railway_imperial_flags(speed, speed);
  END IF;
  IF speed IS NOT NULL THEN
    RETURN ARRAY[railway_speed_int_noconvert(speed), railway_speed_int_noconvert(speed), 6] || railway_imperial_flags(speed, speed);
  END IF;
  IF preferred_direction = 'forward' THEN
    RETURN ARRAY[railway_speed_int_noconvert(forward_speed), railway_speed_int_noconvert(backward_speed), 1] || railway_imperial_flags(forward_speed, backward_speed);
  END IF;
  IF preferred_direction = 'backward' THEN
    RETURN ARRAY[railway_speed_int_noconvert(backward_speed), railway_speed_int_noconvert(forward_speed), 2] || railway_imperial_flags(backward_speed, forward_speed);
  END IF;
  IF preferred_direction = 'both' OR preferred_direction IS NULL THEN
    RETURN ARRAY[railway_speed_int_noconvert(forward_speed), railway_speed_int_noconvert(backward_speed), 3] || railway_imperial_flags(forward_speed, backward_speed);
  END IF;
  RETURN ARRAY[railway_speed_int_noconvert(forward_speed), railway_speed_int_noconvert(backward_speed), 4] || railway_imperial_flags(forward_speed, backward_speed);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION merc_dist_to_earth_dist(y_avg FLOAT, dist FLOAT) RETURNS FLOAT AS $$
DECLARE
  lat_radians FLOAT;
  scale FLOAT;
BEGIN
  lat_radians := 2 * atan(exp(y_avg / 6378137)) - 0.5 * pi();
  scale := 1 / cos(lat_radians);
  RETURN dist / scale;
END;
$$ LANGUAGE plpgsql;


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
$$ LANGUAGE plpgsql;

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
$$ LANGUAGE plpgsql;

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
$$ LANGUAGE plpgsql;
