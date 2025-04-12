import fs from 'fs'
import yaml from 'yaml'

const signals_railway_line = yaml.parse(fs.readFileSync('features/train_protection.yaml', 'utf8'))
const all_signals = yaml.parse(fs.readFileSync('features/signals_railway_signals.yaml', 'utf8'))
const loading_gauges = yaml.parse(fs.readFileSync('features/loading_gauge.yaml', 'utf8'))
const poi = yaml.parse(fs.readFileSync('features/poi.yaml', 'utf8'))
const stations = yaml.parse(fs.readFileSync('features/stations.yaml', 'utf8'))

const signal_types = all_signals.types;

const speed_railway_signals = all_signals.features.filter(feature => feature.tags.find(tag => tag.tag === 'railway:signal:speed_limit' || tag.tag === 'railway:signal:speed_limit_distant'))
const signals_railway_signals = all_signals.features.filter(feature => !feature.tags.find(tag => tag.tag === 'railway:signal:speed_limit' || tag.tag === 'railway:signal:speed_limit_distant' || tag.tag === 'railway:signal:electricity'))
const electrification_signals = all_signals.features.filter(feature => feature.tags.find(tag => tag.tag === 'railway:signal:electricity'))

// TODO add links to documentation

const requireUniqueEntries = array => {
  const count = Object.groupBy(array, it => it[0]);
  if (Object.values(count).some(it => it.length > 1)) {
    const offendingEntries = Object.entries(count).filter(it => it[1].length > 1).map(it => it[0]).join(', ');
    throw new Error(`entries must be unique, offending entries: ${offendingEntries}`);
  }
  return Object.fromEntries(array);
}

const links = {
  wikimedia_commons: 'https://commons.wikimedia.org/wiki/%s',
  wikipedia: 'https://wikipedia.org/wiki/%s',
  wikidata: 'https://www.wikidata.org/wiki/%s',
  image: '%s',
  mapillary: 'https://www.mapillary.com/app/?pKey=%s',
};

const generateSignalFeatures = (features, types) =>
  requireUniqueEntries([
    ...features.flatMap(feature => [
      [
        feature.icon.default,
        {
          country: feature.country,
          name: feature.description,
          type: feature.type,
        }
      ],
      ...(
        feature.icon.match
          ? feature.icon.cases.map(iconCase => [iconCase.value, {
            country: feature.country,
            name: `${feature.description}${iconCase.description ? ` (${iconCase.description})` : ''}`,
          }])
          : []
      )
    ]),
    ...types.map(type => [
      `general/signal-unknown-${type.type}`,
      {
        name: `Unknown signal (${type.type})`,
      }
    ]),
  ]);

// TODO move icon SVGs to proxy
const railwayLineFeatures = {
  labelProperty: 'standard_label',
  features: {
    rail: {
      name: 'Railway',
      type: 'line',
    },
    tram: {
      name: 'Tram',
      type: 'line',
    },
    light_rail: {
      name: 'Light rail',
      type: 'line',
    },
    subway: {
      name: 'Subway',
      type: 'line',
    },
    monorail: {
      name: 'Monorail',
      type: 'line',
    },
    narrow_gauge: {
      name: 'Narrow gauge railway',
      type: 'line',
    },
    miniature: {
      name: 'Miniature railway',
      type: 'line',
    },
  },
  properties: {
    state: {
      name: 'State',
    },
    usage: {
      name: 'Usage',
    },
    service: {
      name: 'Service',
    },
    highspeed: {
      name: 'Highspeed',
    },
    preferred_direction: {
      name: 'Preferred direction',
    },
    tunnel: {
      name: 'Tunnel',
    },
    bridge: {
      name: 'Bridge',
    },
    ref: {
      name: 'Reference',
    },
    track_ref: {
      name: 'Track',
    },
    speed_label: {
      name: 'Speed',
    },
    train_protection: {
      name: 'Train protection',
      format: {
        lookup: 'train_protection',
      }
    },
    train_protection_construction: {
      name: 'Train protection under construction',
      format: {
        lookup: 'train_protection',
      }
    },
    electrification_state: {
      name: 'Electrification',
    },
    frequency: {
      name: 'Frequency',
      format: {
        template: '%.2d Hz',
      },
    },
    voltage: {
      name: 'Voltage',
      format: {
        template: '%d V',
      },
    },
    future_frequency: {
      name: 'Future frequency',
      format: {
        template: '%.2d Hz',
      },
    },
    future_voltage: {
      name: 'Future voltage',
      format: {
        template: '%d V',
      },
    },
    gauge_label: {
      name: 'Gauge',
    },
    loading_gauge: {
      name: 'Loading gauge',
      format: {
        lookup: 'loading_gauge',
      },
    },
    track_class: {
      name: 'Track class',
    },
    reporting_marks: {
      name: 'Reporting marks',
    },
    operator: {
      name: 'Operator',
    },
    traffic_mode: {
      name: 'Traffic mode',
    },
    radio: {
      name: 'Radio',
    },
    wikidata: {
      name: 'Wikidata',
      link: links.wikidata,
    },
    wikimedia_commons: {
      name: 'Wikimedia',
      link: links.wikimedia_commons,
    },
    image: {
      name: 'Image',
      link: links.image,
    },
    mapillary: {
      name: 'Mapillary',
      link: links.mapillary,
    },
    wikipedia: {
      name: 'Wikipedia',
      link: links.wikipedia,
    },
    note: {
      name: 'Note',
      paragraph: true,
    },
    description: {
      name: 'Description',
      paragraph: true,
    },
  },
};

// TODO move tram / metro stops to stations
const stationFeatures = {
  featureProperty: 'railway',
  labelProperty: 'name',
  features: requireUniqueEntries(
    stations.features.map(feature => [feature.feature, {name: feature.description}])
  ),
  properties: {
    station: {
      name: 'Type',
    },
    label: {
      name: 'Reference',
    },
    uic_ref: {
      name: 'UIC reference',
    },
    operator: {
      name: 'Operator',
    },
    network: {
      name: 'Network',
    },
    wikidata: {
      name: 'Wikidata',
      link: links.wikidata,
    },
    wikimedia_commons: {
      name: 'Wikimedia',
      link: links.wikimedia_commons,
    },
    image: {
      name: 'Image',
      link: links.image,
    },
    mapillary: {
      name: 'Mapillary',
      link: links.mapillary,
    },
    wikipedia: {
      name: 'Wikipedia',
      link: links.wikipedia,
    },
    note: {
      name: 'Note',
      paragraph: true,
    },
    description: {
      name: 'Description',
      paragraph: true,
    },
  },
}

// TODO move examples here
// TODO add icon
const features = {
  'high-railway_line_high': railwayLineFeatures,
  'openrailwaymap_low-railway_line_high': railwayLineFeatures,
  'openhistoricalmap-transport_lines': {
    labelProperty: 'name',
    featureProperty: 'type',
    features: {
      rail: {
        name: 'Railway',
        type: 'line',
      },
      tram: {
        name: 'Tram',
        type: 'line',
      },
      light_rail: {
        name: 'Light rail',
        type: 'line',
      },
      subway: {
        name: 'Subway',
        type: 'line',
      },
      monorail: {
        name: 'Monorail',
        type: 'line',
      },
      narrow_gauge: {
        name: 'Narrow gauge railway',
        type: 'line',
      },
      miniature: {
        name: 'Miniature railway',
        type: 'line',
      },
      construction: {
        name: 'Railway under construction',
        type: 'line',
      },
      proposed: {
        name: 'Proposed railway',
        type: 'line',
      },
      disused: {
        name: 'Disused railway',
        type: 'line',
      },
      abandoned: {
        name: 'Abandoned railway',
        type: 'line',
      },
    },
    properties: {
      usage: {
        name: 'Usage',
      },
      service: {
        name: 'Service',
      },
      highspeed: {
        name: 'Highspeed',
      },
      preferred_direction: {
        name: 'Preferred direction',
      },
      tunnel: {
        // TODO: broken because of 0 / 1 usage
        name: 'Tunnel',
      },
      bridge: {
        // TODO: broken because of 0 / 1 usage
        name: 'Bridge',
      },
      ref: {
        name: 'Reference',
      },
      electrified: {
        name: 'Electrified',
      },
      start_date: {
        name: 'Since',
      },
      end_date: {
        name: 'Until',
      },
    },
  },
  'standard_railway_text_stations_low-standard_railway_text_stations_low': stationFeatures,
  'standard_railway_text_stations_med-standard_railway_text_stations_med': stationFeatures,
  'openrailwaymap_standard-standard_railway_text_stations': stationFeatures,
  'openrailwaymap_standard-standard_railway_grouped_stations': stationFeatures,
  'openrailwaymap_standard-standard_railway_turntables': {
    features: {
      turntable: {
        name: 'Turntable',
        type: 'polygon',
      },
      traverser: {
        name: 'Transfer table',
        type: 'polygon',
      },
    },
  },
  'openrailwaymap_standard-standard_railway_symbols': {
    features: Object.fromEntries(
      poi.features.flatMap(feature =>
        [
          [feature.feature, {name: feature.description}]
        ].concat(
          (feature.variants || []).map(variant => [variant.feature, {name: `${feature.description}${variant.description ? ` (${variant.description})` : ''}`}])
        ))
    ),
    properties: {
      ref: {
        name: 'Reference',
      },
      wikidata: {
        name: 'Wikidata',
        link: links.wikidata,
      },
      wikimedia_commons: {
        name: 'Wikimedia',
        link: links.wikimedia_commons,
      },
      image: {
        name: 'Image',
        link: links.image,
      },
      mapillary: {
        name: 'Mapillary',
        link: links.mapillary,
      },
      wikipedia: {
        name: 'Wikipedia',
        link: links.wikipedia,
      },
      note: {
        name: 'Note',
        paragraph: true,
      },
      description: {
        name: 'Description',
        paragraph: true,
      },
    },
  },
  "high-railway_text_km": {
    featureProperty: 'railway',
    features: {
      milestone: {
        name: 'Milestone',
      },
      level_crossing: {
        name: 'Level crossing',
      },
      crossing: {
        name: 'Crossing',
      },
    },
    properties: {
      pos: {
        name: 'Position',
      },
      operator: {
        name: 'Operator',
      },
      wikidata: {
        name: 'Wikidata',
        link: links.wikidata,
      },
      wikimedia_commons: {
        name: 'Wikimedia',
        link: links.wikimedia_commons,
      },
      image: {
        name: 'Image',
        link: links.image,
      },
      mapillary: {
        name: 'Mapillary',
        link: links.mapillary,
      },
      wikipedia: {
        name: 'Wikipedia',
        link: links.wikipedia,
      },
      note: {
        name: 'Note',
        paragraph: true,
      },
      description: {
        name: 'Description',
        paragraph: true,
      },
    },
  },
  'openrailwaymap_standard-standard_railway_switch_ref': {
    featureProperty: 'railway',
    features: {
      switch: {
        name: 'Switch',
      },
      railway_crossing: {
        name: 'Railway crossing',
      }
    },
    properties: {
      ref: {
        name: 'Reference',
      },
      type: {
        name: 'Type',
      },
      turnout_side: {
        name: 'Turnout side',
      },
      local_operated: {
        name: 'Operated locally',
      },
      resetting: {
        name: 'Resetting',
      },
      wikidata: {
        name: 'Wikidata',
        link: links.wikidata,
      },
      wikimedia_commons: {
        name: 'Wikimedia',
        link: links.wikimedia_commons,
      },
      image: {
        name: 'Image',
        link: links.image,
      },
      mapillary: {
        name: 'Mapillary',
        link: links.mapillary,
      },
      wikipedia: {
        name: 'Wikipedia',
        link: links.wikipedia,
      },
      note: {
        name: 'Note',
        paragraph: true,
      },
      description: {
        name: 'Description',
        paragraph: true,
      },
    },
  },
  'openrailwaymap_speed-speed_railway_signals': {
    featureProperty: 'feature0',
    features: generateSignalFeatures(speed_railway_signals, signal_types.filter(type => type.layer === 'speed')),
    properties: {
      feature1: {
        name: 'Secondary signal',
        format: {
          // Recursive feature lookup
          lookup: 'openrailwaymap_speed-speed_railway_signals',
        },
      },
      ref: {
        name: 'Reference',
      },
      caption: {
        name: 'Caption',
      },
      type: {
        name: 'Type',
      },
      deactivated: {
        name: 'Deactivated',
      },
      speed_limit_speed: {
        name: 'Speed limit',
      },
      speed_limit_distant_speed: {
        name: 'Distant speed limit',
      },
      direction_both: {
        name: 'both directions',
      },
    },
  },
  'openrailwaymap_signals-signals_railway_signals': {
    featureProperty: 'feature0',
    features: generateSignalFeatures(signals_railway_signals, signal_types.filter(type => !['speed', 'electrification'].includes(type.layer))),
    properties: {
      feature1: {
        name: 'Secondary signal',
        format: {
          // Recursive feature lookup
          lookup: 'openrailwaymap_signals-signals_railway_signals',
        },
      },
      feature2: {
        name: 'Tertiary signal',
        format: {
          // Recursive feature lookup
          lookup: 'openrailwaymap_signals-signals_railway_signals',
        },
      },
      feature3: {
        name: 'Quaternary signal',
        format: {
          // Recursive feature lookup
          lookup: 'openrailwaymap_signals-signals_railway_signals',
        },
      },
      feature4: {
        name: 'Quinary signal',
        format: {
          // Recursive feature lookup
          lookup: 'openrailwaymap_signals-signals_railway_signals',
        },
      },
      ref: {
        name: 'Reference',
      },
      caption: {
        name: 'Caption',
      },
      type: {
        name: 'Type',
      },
      deactivated: {
        name: 'Deactivated',
      },
      direction_both: {
        name: 'both directions',
      },
    },
  },
  'openrailwaymap_signals-signals_signal_boxes': {
    labelProperty: 'name',
    features: {
      'signal_box': {
        name: 'Signal box',
      },
      'crossing_box': {
        name: 'Crossing box',
      },
      'blockpost': {
        name: 'Block post',
      }
    },
    properties: {
      ref: {
        name: 'Reference',
      },
      wikidata: {
        name: 'Wikidata',
        link: links.wikidata,
      },
      wikimedia_commons: {
        name: 'Wikimedia',
        link: links.wikimedia_commons,
      },
      image: {
        name: 'Image',
        link: links.image,
      },
      mapillary: {
        name: 'Mapillary',
        link: links.mapillary,
      },
      wikipedia: {
        name: 'Wikipedia',
        link: links.wikipedia,
      },
      note: {
        name: 'Note',
        paragraph: true,
      },
      description: {
        name: 'Description',
        paragraph: true,
      },
    },
  },
  'openrailwaymap_electrification-electrification_signals': {
    featureProperty: 'feature',
    features: generateSignalFeatures(electrification_signals, signal_types.filter(type => type.layer === 'electrification')),
    properties: {
      direction_both: {
        name: 'both directions',
      },
      ref: {
        name: 'Reference',
      },
      caption: {
        name: 'Caption',
      },
      type: {
        name: 'Type',
      },
      deactivated: {
        name: 'Deactivated',
      },
      frequency: {
        name: 'Frequency',
        format: {
          template: '%.2d Hz',
        },
      },
      voltage: {
        name: 'Voltage',
        format: {
          template: '%d V',
        },
      },
    },
  },

  // Search results

  search: {
    labelProperty: 'label',
    features: [],
    properties: {
      name: {
        name: 'Name',
      },
      railway: {
        name: 'Railway',
      },
    },
  },

  // Features not part of a data source but for lookups

  train_protection: {
    features: Object.fromEntries(signals_railway_line.train_protections.map(feature => [
      feature.train_protection,
      {
        name: feature.legend,
      },
    ])),
  },
  loading_gauge: {
    features: Object.fromEntries(loading_gauges.loading_gauges.map(feature => [
      feature.value,
      {
        name: feature.legend,
      },
    ])),
  },
};

if (import.meta.url.endsWith(process.argv[1])) {
  console.log(JSON.stringify(features))
}
