CREATE OR REPLACE FUNCTION fmod(
  dividend double precision,
  divisor double precision
) RETURNS double precision
  LANGUAGE sql IMMUTABLE AS
    'SELECT dividend - floor(dividend / divisor) * divisor';

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
