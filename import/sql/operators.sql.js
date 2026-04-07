import fs from 'fs'
import yaml from 'yaml'

const operators = yaml.parse(fs.readFileSync('operators.yaml', 'utf8'))

const operatorsByName = operators.operators
  .flatMap(({names, color}) => names.map(name => ({name, color})));

// #ab4
const rgb = /^#[0-9a-fA-F]{3}$/
// #abcd45
const rrggbb = /^#[0-9a-fA-F]{6}$/
// rgb(123, 0,255)
const rgbf = /^rgb\(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]), *([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]), *([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\)$/
// hsl(123, 0%, 34%)
const hslf = /^hsl\(([0-9]|[1-9][0-9]|[12][0-9]{2}|3[0-5][0-9]), *([0-9]|[1-9][0-9]|100)%, *([0-9]|[1-9][0-9]|100)%\)$/

// Taken from https://stackoverflow.com/a/9493060/711129
function hslToRgb(h, s, l) {
  let r, g, b;

  if (s === 0) {
    r = g = b = l; // achromatic
  } else {
    const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    const p = 2 * l - q;
    r = hueToRgb(p, q, h + 1/3);
    g = hueToRgb(p, q, h);
    b = hueToRgb(p, q, h - 1/3);
  }

  return [r * 255,g * 255 , b * 255];
}

function hueToRgb(p, q, t) {
  if (t < 0) t += 1;
  if (t > 1) t -= 1;
  if (t < 1/6) return p + (q - p) * 6 * t;
  if (t < 1/2) return q;
  if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
  return p;
}

// See https://www.w3.org/WAI/GL/wiki/Relative_luminance and https://beta.stackoverflow.com/q/3942878#3943023
function rgbLuminance(r, g, b) {
  function coefficient(value) {
    const c = value / 255.0
    if (c <= 0.03928) {
      return c / 12.92
    } else {
      return Math.pow((c + 0.055) / 1.055, 2.4)
    }
  }

  return 0.2126 * coefficient(r) + 0.7152 * coefficient(g) + 0.0722 * coefficient(b)
}

function isBright(luminance) {
  return luminance >= 0.179
}

function brightColor(name, color) {
  if (color.match(rgb)) {
    const red = parseInt(color[1] + color[1], 16)
    const green = parseInt(color[2] + color[2], 16)
    const blue = parseInt(color[3] + color[3], 16)

    return isBright(rgbLuminance(red, green, blue))
  } else if (color.match(rrggbb)) {
    const red = parseInt(color.substring(1, 3), 16)
    const green = parseInt(color.substring(3, 5), 16)
    const blue = parseInt(color.substring(5, 7), 16)

    return isBright(rgbLuminance(red, green, blue))
  } else if (color.match(rgbf)) {
    const matches = color.match(rgbf);
    const red = parseInt(matches[1])
    const green = parseInt(matches[2])
    const blue = parseInt(matches[3])

    return isBright(rgbLuminance(red, green, blue))
  } else if (color.match(hslf)) {
    const matches = color.match(hslf);
    const hue = parseInt(matches[1])
    const saturation = parseInt(matches[2])
    const lightness = parseInt(matches[3])

    const [red, green, blue] = hslToRgb(hue / 360.0, saturation/ 100.0, lightness/ 100.0)
    return isBright(rgbLuminance(red, green, blue))
  } else {
    throw new Error(`Could not match color '${color}' against known color patterns`)
  }
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
    ('${name}', '${color}', ${brightColor(name, color)})`).join(',')}
  ) operator_data (name, color, bright);

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
