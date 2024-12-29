import fs from 'fs'
import yaml from 'yaml'

const signals_railway_line = yaml.parse(fs.readFileSync('features/train_protection.yaml', 'utf8'))
const all_signals = yaml.parse(fs.readFileSync('features/signals_railway_signals.yaml', 'utf8'))
const loading_gauges = yaml.parse(fs.readFileSync('features/loading_gauge.yaml', 'utf8'))
const poi = yaml.parse(fs.readFileSync('features/poi.yaml', 'utf8'))
const stations = yaml.parse(fs.readFileSync('features/stations.yaml', 'utf8'))

const speed_railway_signals = all_signals.features.filter(feature => feature.tags.find(tag => tag.tag === 'railway:signal:speed_limit' || tag.tag === 'railway:signal:speed_limit_distant'))
const signals_railway_signals = all_signals.features.filter(feature => !feature.tags.find(tag => tag.tag === 'railway:signal:speed_limit' || tag.tag === 'railway:signal:speed_limit_distant' || tag.tag === 'railway:signal:electricity'))
const electrification_signals = all_signals.features.filter(feature => feature.tags.find(tag => tag.tag === 'railway:signal:electricity'))

// TODO add links to documentation

const generateSignalFeatures = features =>
  Object.fromEntries(features.flatMap(feature =>
    [
      [
        feature.icon.default,
        {
          country: feature.country,
          name: feature.description,
          type: feature.type,
        }
      ]
    ].concat(
      feature.icon.match
        // TODO dynamic match for speed signals, need difference between feature and icon
        ? feature.icon.cases.map(iconCase => [iconCase.example ?? iconCase.value, {
          country: feature.country,
          name: iconCase.description,
        }])
        : []
    ),
  ));

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
    construction: {
      name: 'Railway under construction',
      type: 'line',
    },
    proposed: {
      name: 'Proposed railway',
      type: 'line',
    },
    abandoned: {
      name: 'Abandoned railway',
      type: 'line',
    },
    razed: {
      name: 'Razed railway',
      type: 'line',
    },
    disused: {
      name: 'Disused railway',
      type: 'line',
    },
    preserved: {
      name: 'Preserved railway',
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
    // TODO replace railway with `state`
    railway: {
      name: 'Railway',
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
  },
};

// TODO move tram / metro stops to stations
const stationFeatures = {
  featureProperty: 'railway',
  labelProperty: 'name',
  features: Object.fromEntries(
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
  },
}

// TODO move examples here
// TODO add icon
const features = {
  'high-railway_line_high': railwayLineFeatures,
  'openrailwaymap_low-railway_line_low': railwayLineFeatures,
  'openrailwaymap_med-railway_line_med': railwayLineFeatures,
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
          (feature.variants || []).map(variant => [variant.feature, {name: variant.description}])
        ))
    ),
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
      railway_local_operated: {
        name: 'Operated locally',
      },
    },
  },
  'openrailwaymap_speed-speed_railway_signals': {
    features: generateSignalFeatures(speed_railway_signals),
    properties: {
      direction_both: {
        name: 'both directions',
      },
      ref: {
        name: 'Reference',
      },
      type: {
        name: 'Type',
      },
      deactivated: {
        name: 'Deactivated',
      },
      speed: {
        name: 'Speed limit',
      },
    },
  },
  'openrailwaymap_signals-signals_railway_signals': {
    features: generateSignalFeatures(signals_railway_signals),
    properties: {
      direction_both: {
        name: 'both directions',
      },
      ref: {
        name: 'Reference',
      },
      type: {
        name: 'Type',
      },
      deactivated: {
        name: 'Deactivated',
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
    },
  },
  'openrailwaymap_electrification-electrification_signals': {
    features: generateSignalFeatures(electrification_signals),
    properties: {
      direction_both: {
        name: 'both directions',
      },
      ref: {
        name: 'Reference',
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
