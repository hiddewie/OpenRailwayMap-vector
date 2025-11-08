// @ts-check
import { promises as fs } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import yaml from 'yaml';
import chroma from 'chroma-js';

//
// This file loads the taginfo.json file, and automatically adds
// every tag that it finds in the `features/*.yaml` files. Tags
// that are used in other parts of the code can be manually added
// to the taginfo.json template file.
//
// The generated file is saved to `taginfo.json` and
// served by the proxy.
//

const BASE_URL = 'https://raw.githubusercontent.com/hiddewie/OpenRailwayMap-vector/master';

const countryNames = new Intl.DisplayNames(['en'], { type: 'region' });

const __dirname = dirname(fileURLToPath(import.meta.url));

/** @type {import('taginfo-projects').Schema} */
const taginfo = JSON.parse(
  await fs.readFile(join(__dirname, '../taginfo.template.json'), 'utf8'),
);

taginfo.data_updated = new Date().toISOString().replaceAll(/(:|-|\.\d+)/g, '');

taginfo.tags.shift(); // remove the first line, which is just a comment

/** @param {string} fileName @returns {Promise<any>} */
const readYamlFile = (fileName) =>
  fs
    .readFile(join(__dirname, '../../features', fileName), 'utf8')
    .then(yaml.parse);

// loading_gauge
const { loading_gauges } = await readYamlFile('loading_gauge.yaml');
for (const item of loading_gauges) {
  const color = chroma(item.color).hex().slice(1);

  taginfo.tags.push({
    key: 'loading_gauge',
    value: item.value,
    description: item.legend,
    icon_url: `https://placehold.co/64x64/${color}/${color}`,
  });
}

// poi
const poi = await readYamlFile('poi.yaml');
for (const feature of poi.features) {
  for (const tag of feature.tags) {
    taginfo.tags.push({
      key: tag.tag,
      value: tag.value,
      description: `[POI] ${feature.description}`,
      icon_url: `${BASE_URL}/symbols/${feature.feature}.svg`,
    });
    for (const variant of feature.variants || []) {
      for (const tag of variant.tags) {
        const values = tag.values || [tag.value];
        for (const value of values) {
          taginfo.tags.push({
            key: tag.tag,
            value,
            description: `[POI] “${feature.description}” → “${variant.description}”`,
            icon_url: `${BASE_URL}/symbols/${variant.feature}.svg`,
          });
        }
      }
    }
  }
}

// railway_line
const tracks = await readYamlFile('railway_line.yaml');
for (const feature of tracks.features) {
  taginfo.tags.push({
    key: 'railway',
    value: feature.type,
    description: feature.description,
  });
}

// signals_railway_signals
const signals = await readYamlFile('signals_railway_signals.yaml');
for (const tag of signals.tags) {
  taginfo.tags.push({
    key: tag.tag,
    description: tag.description,
  });
}
for (const signal of signals.features) {
  const region = signal.country ? countryNames.of(signal.country) : 'Worldwide';
  const icon_url = `${BASE_URL}/symbols/${signal.exampleIcon ?? signal.icon[0].default}.svg`;

  for (const tag of signal.tags) {
    if (tag.tag.endsWith(':form') || tag.tag.endsWith(':type')) continue; // don't include these tags multiple times

    for (const value of tag.any || [tag.value]) {
      taginfo.tags.push({
        key: tag.tag,
        value,
        description: `[Signal] [${region}] ${signal.description}`,
        icon_url,
      });
    }
  }
  if (signal.icon.match) {
    taginfo.tags.push({
      key: signal.icon.match,
      description: `[Signal] [${region}] Determines the icon for “${signal.description}”`,
      icon_url,
    });
  }
}

// stations
const stations = await readYamlFile('stations.yaml');
for (const station of stations.features) {
  taginfo.tags.push({
    key: 'railway',
    value: station.feature,
    description: `[Station] “${station.description}”`,
    icon_url: `${BASE_URL}/symbols/general/${station.feature}.svg`,
  });
}

// loading_gauge
const { track_classes } = await readYamlFile('track_class.yaml');
for (const item of track_classes) {
  const color = chroma(item.color).hex().slice(1);

  taginfo.tags.push({
    key: 'railway:track_class',
    value: item.value,
    icon_url: `https://placehold.co/64x64/${color}/${color}`,
  });
}

// train_protection
const train_protection = await readYamlFile('train_protection.yaml');

// first group all tags by the ID
/** @type {Record<string, Set<string>>} */
const grouped = {};
for (const item of train_protection.features) {
  grouped[item.train_protection] ||= new Set();
  for (const tag of item.tags) {
    for (const value of tag.values || [tag.value]) {
      grouped[item.train_protection].add(`${tag.tag}=${value}`);
    }
  }
}
for (const key in grouped) {
  const def = train_protection.train_protections.find(
    (system) => system.train_protection === key,
  );
  const color = chroma(def.color).hex().slice(1);

  for (const tag of grouped[key]) {
    const [key, value] = tag.split('=');
    taginfo.tags.push({
      key,
      value,
      description: def.legend,
      icon_url: `https://placehold.co/64x64/${color}/${color}`,
    });
  }
}

if (import.meta.url.endsWith(process.argv[1])) {
  console.log(JSON.stringify(taginfo, null, 2))
}
