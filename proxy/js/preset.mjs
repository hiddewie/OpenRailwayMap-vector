import fs from 'fs'
import yaml from 'yaml'
import { create } from 'xmlbuilder2'

// const signals_railway_line = yaml.parse(fs.readFileSync('features/train_protection.yaml', 'utf8'))
const all_signals = yaml.parse(fs.readFileSync('features/signals_railway_signals.yaml', 'utf8'))
// const loading_gauges = yaml.parse(fs.readFileSync('features/loading_gauge.yaml', 'utf8'))
// const poi = yaml.parse(fs.readFileSync('features/poi.yaml', 'utf8'))
// const stations = yaml.parse(fs.readFileSync('features/stations.yaml', 'utf8'))


/*



  - description: Verschubverbot
    country: AT
    icon:
      match: 'railway:signal:shunting:height'
      cases:
        - { regex: '^dwarf$', value: 'at/verschubverbot-aufgehoben-dwarf', description: 'zwerg' }
      default: 'at/verschubverbot-aufgehoben'
    tags:
      - { tag: 'railway:signal:shunting', value: 'AT-V2:verschubsignal' }
      - { tag: 'railway:signal:shunting:form', value: 'light' }

 */

const preset = {
  presets: {
    '@xmlns': 'http://josm.openstreetmap.de/tagging-preset-1.0',
    author: 'Hidde Wieringa',
    version: '1.0',
    shortdescription: 'OpenRailwayMap preset',
    description: 'Preset to tag railway infrastructure such as railway lines, signals and railway places of interest',

    group: [
      {
        '@name': 'Austrian signals',
        // '@icon': '', // TODO

        // TODO specify region

        item: [
          {
            '@type': 'node',
            '@name': 'Verschubverbot',
            '@icon': 'symbols/at/verschubverbot-aufgehoben.svg',
            label: [
              { '@text': 'Verschubverbot' },
            ],
            key: [
              {
                '@key': 'railway:signal:shunting',
                '@value': 'AT-V2:verschubsignal',
              },
              {
                '@key': 'railway:signal:shunting:form',
                '@value': 'light',
              }
            ]
          }
        ],
      }
    ],
  }
};

//
// const root = create({ version: '1.0' })
//   .ele('root', { att: 'val' })
//     .ele('foo')
//       .ele('bar').txt('foobar').up()
//     .up()
//     .ele('baz').up()
//   .up();

// const builder = new XMLBuilder();

const document = create({version: '1.0', encoding:'utf-8'}, preset);
const xml = document.end({ prettyPrint: true });
// const preset = builder.build({
//   '?xml': ''
//   presets: [
//     {
//
//     },
//   ],
// });

if (import.meta.url.endsWith(process.argv[1])) {
  console.log(xml)
}
