import fs from 'fs'
import yaml from 'yaml'

const signals_railway_line = yaml.parse(fs.readFileSync('features/train_protection.yaml', 'utf8')).signals_railway_line
const speed_railway_signals = yaml.parse(fs.readFileSync('features/speed_railway_signals.yaml', 'utf8')).speed_railway_signals
const signals_railway_signals = yaml.parse(fs.readFileSync('features/signals_railway_signals.yaml', 'utf8')).signals_railway_signals
const electrification_signals = yaml.parse(fs.readFileSync('features/electrification_signals.yaml', 'utf8')).electrification_signals
const loading_gauges = yaml.parse(fs.readFileSync('features/loading_gauge.yaml', 'utf8')).loading_gauges
const poi = yaml.parse(fs.readFileSync('features/poi.yaml', 'utf8')).poi

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

const loadingGauges = loading_gauges.map(feature => ({
  feature: feature.value,
  description: feature.legend,
}));

const features = {
  'high-railway_line_high': {
    features: {
      rail: {
        name: 'Railway',
        type: 'line',
      },
      construction: {
        name: 'Railway under construction',
      },
      proposed: {
        name: 'Proposed railway',
      },
      abandoned: {
        name: 'Abandoned railway',
      },
      razed: {
        name: 'Razed railway',
      },
      disused: {
        name: 'Disused railway',
      },
      preserved: {
        name: 'Preserved railway',
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
  'openrailwaymap_standard-standard_railway_text_stations': {
    featureProperty: 'railway',
    features: {
      // TODO process light rail and subway station / halt
      'station': {
        name: 'Station',
      },
      'halt': {
        name: 'Halt',
      },
      'tram_stop': {
        name: 'Tram stop',
      },
      'service_station': {
        name: 'Service station',
      },
      'yard': {
        name: 'Railway yard',
      },
      'junction': {
        name: 'Junction',
      },
      'spur_junction': {
        name: 'Spur junction',
      },
      'site': {
        name: 'Railway site',
      },
      'crossover': {
        name: 'Crossover',
      },
    },
  },
  'openrailwaymap_speed-speed_railway_signals': {
    features: {
      ...generateSignalFeatures(speed_railway_signals.features),
    },
  },
  'openrailwaymap_signals-signals_railway_signals': {
    features: {
      ...generateSignalFeatures(signals_railway_signals.features),
    },
  },
  'openrailwaymap_electrification-electrification_signals': {
    features: {
      ...generateSignalFeatures(electrification_signals.features),
    },
  },
};

if (import.meta.url.endsWith(process.argv[1])) {
  console.log(JSON.stringify(features))
}
