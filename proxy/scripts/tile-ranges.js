/**
 * Script to  generate nginx configuration for capturing tile ranges per zoom level.
 *
 * Invoke with x_min, x_max, y_min, y_max and the upstream name.
 * For example:
 *   node proxy/tile-ranges.js 7 10 7 15 TILES_UPSTREAM_AFRICA
 */

const toRegexRange = require("to-regex-range");

// Zoom 4
let xmin = parseInt(process.argv[2])
let xmax = parseInt(process.argv[3])
let ymin = parseInt(process.argv[4])
let ymax = parseInt(process.argv[5])

const upstream = process.argv[6]

for (let zoom = 4; zoom <= 14; zoom++) {
  if (zoom >= 8) {
    const xregex = toRegexRange(xmin, xmax, {capture: true})
    const yregex = toRegexRange(ymin, ymax, {capture: true})

    console.log(`# Zoom ${zoom}: x=${xmin}..${xmax} y=${ymin}..${ymax}`)
    console.log(`"~^/[^/]+/${zoom}/${xregex}/${yregex}\$" http://\${${upstream}};`)
  }

  xmin *= 2
  xmax *= 2
  xmax += 1
  ymin *= 2
  ymax *= 2
  ymax += 1
}
