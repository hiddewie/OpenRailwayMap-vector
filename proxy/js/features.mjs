import fs from 'fs'
import yaml from 'yaml'

const signals_railway_line = yaml.parse(fs.readFileSync('train_protection.yaml', 'utf8')).signals_railway_line
const speed_railway_signals = yaml.parse(fs.readFileSync('speed_railway_signals.yaml', 'utf8')).speed_railway_signals
const signals_railway_signals = yaml.parse(fs.readFileSync('signals_railway_signals.yaml', 'utf8')).signals_railway_signals
const electrification_signals = yaml.parse(fs.readFileSync('electrification_signals.yaml', 'utf8')).electrification_signals
const loading_gauges = yaml.parse(fs.readFileSync('loading_gauge.yaml', 'utf8')).loading_gauges

// TODO add links to documentation

const generateSignalFeatures = features =>
  features.flatMap(feature =>
    [{
      feature: feature.icon.default,
      country: feature.country,
      description: feature.description,
      type: feature.type,
    }].concat(
      feature.icon.match
        ? feature.icon.cases.map(iconCase => ({
          // TODO dynamic match for speed signals, need difference between feature and icon
          feature: iconCase.example ?? iconCase.value,
          country: feature.country,
          description: iconCase.description
            ? `${feature.description} (${feature.description} (${iconCase.description})`
            : feature.description,
        }))
        : []
    ),
  );

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

fs.writeFileSync('speed-signals.json', JSON.stringify(speedSignals));
fs.writeFileSync('train-protection.json', JSON.stringify(trainProtection));
fs.writeFileSync('train-protection-signals.json', JSON.stringify(trainProtectionSignals));
fs.writeFileSync('electrification-signals.json', JSON.stringify(electrificationSignals));
fs.writeFileSync('loading-gauges.json', JSON.stringify(loadingGauges));
