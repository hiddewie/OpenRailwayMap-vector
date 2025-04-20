import fs from 'fs'
import yaml from 'yaml'
import { create } from 'xmlbuilder2'

// const signals_railway_line = yaml.parse(fs.readFileSync('features/train_protection.yaml', 'utf8'))
const all_signals = yaml.parse(fs.readFileSync('features/signals_railway_signals.yaml', 'utf8'))
// const loading_gauges = yaml.parse(fs.readFileSync('features/loading_gauge.yaml', 'utf8'))
// const poi = yaml.parse(fs.readFileSync('features/poi.yaml', 'utf8'))
// const stations = yaml.parse(fs.readFileSync('features/stations.yaml', 'utf8'))

const preset = {
  presets: {
    '@xmlns': 'http://josm.openstreetmap.de/tagging-preset-1.0',
    author: 'Hidde Wieringa',
    version: '1.0',
    shortdescription: 'OpenRailwayMap preset',
    description: 'Preset to tag railway infrastructure such as railway lines, signals and railway places of interest',

    group: [
      {
        '@name': 'Railway signals',

        item: all_signals.features.map(feature => ({
          '@type': 'node',
          '@name': `${feature.country ? `${feature.country}: ` : ''}${feature.description}`, // TODO group by country?
          '@icon': `symbols/${feature.icon.default}.svg`,
          '@regions': feature.country,
          '@preset_name_label': true,

          link: {
            '@wiki': 'Tag:railway=signal', // TODO better link to country specific tagging
          },

          space: '',
          key: feature.tags
            .filter(tag => tag.value)
            .map(tag => ({
              '@key': tag.tag,
              '@value': tag.value,
            })),
          // TODO better support a combo or multiselect of valid values
          text: feature.icon.match
            ? [
              {
                '@text': feature.icon.match, // TODO generate proper label
                '@key': feature.icon.match,
              }
            ]
            : [],
          combo: feature.tags
            .filter(tag => tag.values)
            .map(tag => ({
              '@text': tag.tag, // TODO generate proper label
              '@key': tag.tag,
              '@values': tag.values.join(','),
              '@match': 'keyvalue!',
              '@use_last_as_default': true,
            })),
        })),
        optional: '',
      }
    ],
  }
};

const document = create({version: '1.0', encoding:'utf-8'}, preset);
const xml = document.end({ prettyPrint: true });

if (import.meta.url.endsWith(process.argv[1])) {
  console.log(xml)
}
