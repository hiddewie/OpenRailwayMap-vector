import fs from 'fs'
import yaml from 'yaml'

const operators = yaml.parse(fs.readFileSync('operators.yaml', 'utf8'))

const operatorsByName = operators.operators
  .flatMap(({names, color}) => names.map(name => ({name, color})));

const rgb = /^#[0-9a-fA-F]{3}/
const rrggbb = /^#[0-9a-fA-F]{6}/
const rgbf = /^rgb\(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]), *([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]), *([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\)/
const hslf = /^hsl\(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]), *([0-9]|[1-9][0-9]|100)%, *([0-9]|[1-9][0-9]|100)%\)/

function brightColor(color) {
  return true;
}

/**
 * Template that builds the SQL view taking the YAML configuration into account
 */
const sql = `
CREATE OR REPLACE VIEW railway_operator_view AS
  SELECT
    row_number() over () as id,
    name,
    color,
    bright
  FROM (VALUES${operatorsByName.map(({name, color}) => `
    ('${name}', '${color}', ${brightColor(color)})`).join(',')}
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
