import fs from 'fs'
import yaml from 'yaml'
import { XMLBuilder } from 'fast-xml-parser'

// const signals_railway_line = yaml.parse(fs.readFileSync('features/train_protection.yaml', 'utf8'))
// const all_signals = yaml.parse(fs.readFileSync('features/signals_railway_signals.yaml', 'utf8'))
// const loading_gauges = yaml.parse(fs.readFileSync('features/loading_gauge.yaml', 'utf8'))
// const poi = yaml.parse(fs.readFileSync('features/poi.yaml', 'utf8'))
// const stations = yaml.parse(fs.readFileSync('features/stations.yaml', 'utf8'))

const builder = new XMLBuilder();
const preset = builder.build({
  bla: 'test',
});

if (import.meta.url.endsWith(process.argv[1])) {
  console.log(preset)
}
