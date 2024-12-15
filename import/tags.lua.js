import fs from 'fs'
import yaml from 'yaml'

const signals_railway_line = yaml.parse(fs.readFileSync('train_protection.yaml', 'utf8'))
const speed_railway_signals = yaml.parse(fs.readFileSync('speed_railway_signals.yaml', 'utf8'))
const signals_railway_signals = yaml.parse(fs.readFileSync('signals_railway_signals.yaml', 'utf8'))
const electrification_signals = yaml.parse(fs.readFileSync('electrification_signals.yaml', 'utf8'))

/**
 * Template that builds Lua functions used in the Osm2Psql Lua import, and taking the YAML configuration into account
 */
const lua = `
function train_protection(tags)${signals_railway_line.features.map((feature, featureIndex) => `
  if ${feature.tags.map(tag => `${tag.value ? `tags['${tag.tag}'] == '${tag.value}'`: `(${tag.values.map(value => `tags['${tag.tag}'] == '${value}'`).join(' or ')})`}`).join(' and ')} then return '${feature.train_protection}', ${signals_railway_line.features.length - featureIndex} end`).join('')}
  
  return nil, 0
end

local signal_tags = {${signals_railway_signals.tags.map(tag => `
  '${tag}',`).join('')}
}

local speed_tags = {${speed_railway_signals.tags.map(tag => `
  '${tag}',`).join('')}
}

local electrification_tags = {${electrification_signals.tags.map(tag => `
  '${tag}',`).join('')}
}

return {
  train_protection = train_protection,
  signal_tags = signal_tags,
  speed_tags = speed_tags,
  electrification_tags = electrification_tags,
}
`;

console.log(lua)
