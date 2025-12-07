import fs from 'fs'
import yaml from 'yaml'

const operators = yaml.parse(fs.readFileSync('operators.yaml', 'utf8'))

const operatorsByName = operators.operators
  .flatMap(({names, color}) => names.map(name => ({name, color})));

/**
 * Template that builds the SQL view taking the YAML configuration into account
 */
const sql = `
CREATE OR REPLACE VIEW railway_operator_view AS
  SELECT
    row_number() over () as id,
    name,
    color
  FROM (VALUES${operatorsByName.map(({name, color}) => `
    ('${name}', '${color}')`).join(',')}
  ) operator_data (name, color);

-- Use the view directly such that the query in the view can be updated
CREATE MATERIALIZED VIEW IF NOT EXISTS railway_operator AS
  SELECT
    *
  FROM
    railway_operator_view;

CREATE INDEX IF NOT EXISTS railway_operator_name
  ON railway_operator
    USING btree(name);
`

console.log(sql);
