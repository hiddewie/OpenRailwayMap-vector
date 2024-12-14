import fs from 'fs'
import yaml from 'yaml'

const signals_railway_line = yaml.parse(fs.readFileSync('features/train_protection.yaml', 'utf8'))
const speed_railway_signals = yaml.parse(fs.readFileSync('features/speed_railway_signals.yaml', 'utf8'))
const signals_railway_signals = yaml.parse(fs.readFileSync('features/signals_railway_signals.yaml', 'utf8'))
const electrification_signals = yaml.parse(fs.readFileSync('features/electrification_signals.yaml', 'utf8'))
const loading_gauges = yaml.parse(fs.readFileSync('features/loading_gauge.yaml', 'utf8'))
const poi = yaml.parse(fs.readFileSync('features/poi.yaml', 'utf8'))
const stations = yaml.parse(fs.readFileSync('features/stations.yaml', 'utf8'))

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

const trainProtection = signals_railway_line.train_protections.map(feature => ({
  feature: feature.train_protection,
  description: feature.legend,
}));

const loadingGauges = loading_gauges.loading_gauges.map(feature => ({
  feature: feature.value,
  description: feature.legend,
}));

const railwayLineFeatures = {
  features: {
    rail: {
      name: 'Railway',
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
  },
};

const stationFeatures = {
  featureProperty: 'railway',
  features: Object.fromEntries(
    stations.features.map(feature => [feature.feature, {name: feature.description}])
  ),
}

// TODO add properties for use in labels
// TODO add name / label property of feature
// TODO move examples here
const features = {
  'high-railway_line_high': railwayLineFeatures,
  'openrailwaymap_low-railway_line_low': railwayLineFeatures,
  'openrailwaymap_med-railway_line_med': railwayLineFeatures,
  'standard_railway_text_stations_low-standard_railway_text_stations_low': stationFeatures,
  'standard_railway_text_stations_med-standard_railway_text_stations_med': stationFeatures,
  'openrailwaymap_standard-standard_railway_text_stations': stationFeatures,
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
  },
  'openrailwaymap_speed-speed_railway_signals': {
    features: generateSignalFeatures(speed_railway_signals.features),
  },
  'openrailwaymap_signals-signals_railway_signals': {
    features: generateSignalFeatures(signals_railway_signals.features),
  },
  'openrailwaymap_signals-signals_signal_boxes': {
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
  },
  'openrailwaymap_electrification-electrification_signals': {
    features: generateSignalFeatures(electrification_signals.features),
  },
};

if (import.meta.url.endsWith(process.argv[1])) {
  console.log(JSON.stringify(features))
}
