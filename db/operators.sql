-- Taken from https://stackoverflow.com/questions/22098706/how-to-use-regular-expression-with-any-array-operator
CREATE OR REPLACE FUNCTION commuted_regexp_match(text, text) RETURNS BOOL AS
  'SELECT $2 ~ $1;'
  LANGUAGE sql;

CREATE OPERATOR ~!@# (
  procedure = commuted_regexp_match(text, text),
  leftarg = text,
  rightarg = text
);
