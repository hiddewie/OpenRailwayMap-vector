import fs from 'fs'
import yaml from 'yaml'

const signals_railway_line = yaml.parse(fs.readFileSync('train_protection.yaml', 'utf8')).signals_railway_line
const speed_railway_signals = yaml.parse(fs.readFileSync('speed_railway_signals.yaml', 'utf8')).speed_railway_signals
const signals_railway_signals = yaml.parse(fs.readFileSync('signals_railway_signals.yaml', 'utf8')).signals_railway_signals
const electrification_signals = yaml.parse(fs.readFileSync('electrification_signals.yaml', 'utf8')).electrification_signals
const loading_gauges = yaml.parse(fs.readFileSync('loading_gauge.yaml', 'utf8')).loading_gauges

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

const speedSignals = generateSignalFeatures(speed_railway_signals.features);
const trainProtectionSignals = generateSignalFeatures(signals_railway_signals.features);
const electrificationSignals = generateSignalFeatures(electrification_signals.features);

const loadingGauges = loading_gauges.map(feature => ({
  feature: feature.value,
  description: feature.legend,
}));

const features = {
  'high-railway_line_high': {
    rail: {
      name: 'Railway',
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
  'openrailwaymap_standard-standard_railway_symbols': {
    'general/crossing': {
      name: 'Crossing'
    },
    'general/level-crossing': {
      name: 'Level crossing'
    },
    'general/level-crossing-light': {
      name: 'Level crossing with lights'
    },
    'general/level-crossing-barrier': {
      name: 'Level crossing with barrier'
    },
    'general/phone': {
      name: 'Phone',
    },
    'general/tram-stop': {
      name: 'Tram stop',
    },
    'general/border': {
      name: 'Border crossing',
    },
    'general/owner-change': {
      name: 'Owner change',
    },
    'general/lubricator': {
      name: 'Lubricator',
    },
    'general/fuel': {
      name: 'Fuel',
    },
    'general/sand_store': {
      name: 'Sand store',
    },
    'general/aei': {
      name: 'Automatic equipment identification',
    },
    'general/buffer_stop': {
      name: 'Buffer stop',
    },
    'general/derail': {
      name: 'Derailer',
    },
    'general/defect_detector': {
      name: 'Defect detector',
    },
    'general/hump_yard': {
      name: 'Hump yard',
    },
    'general/loading_gauge': {
      name: 'Loading gauge',
    },
    'general/preheating': {
      name: 'Preheating',
    },
    'general/compressed_air_supply': {
      name: 'Compressed air supply',
    },
    'general/waste_disposal': {
      name: 'Waste disposal',
    },
    'general/coaling_facility': {
      name: 'Coaling facility',
    },
    'general/wash': {
      name: 'Wash',
    },
    'general/water_tower': {
      name: 'Water tower',
    },
    'general/water_crane': {
      name: 'Water crane',
    },
    'general/radio-mast': {
      name: 'Radio mast',
    },
    'general/radio-antenna': {
      name: 'Radio antenna',
    },
    'general/vacancy-detection-axle-counter': {
      name: 'Axle counter',
    },
    'general/vacancy-detection-insulated-rail-joint': {
      name: 'Insulated rail joint',
    },
  },
  'openrailwaymap_signals-signals_railway_signals': {
    ...trainProtectionSignals,
  }
};

if (import.meta.url.endsWith(process.argv[1])) {
  console.log(JSON.stringify(features))
}
