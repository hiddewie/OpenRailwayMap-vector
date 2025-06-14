import fs from 'fs'
import yaml from 'yaml'

const signals_railway_line = yaml.parse(fs.readFileSync('train_protection.yaml', 'utf8'))
const signals_railway_signals = yaml.parse(fs.readFileSync('signals_railway_signals.yaml', 'utf8'))
const pois = yaml.parse(fs.readFileSync('poi.yaml', 'utf8'))

/**
 * Template that builds Lua functions used in the Osm2Psql Lua import, and taking the YAML configuration into account
 */
const lua = `
function train_protection(tags, prefix)${signals_railway_line.features.map((feature, featureIndex) => `
  if ${feature.tags.map(tag => `${tag.value ? `tags[prefix .. '${tag.tag}'] == '${tag.value}'`: `(${tag.values.map(value => `tags[prefix .. '${tag.tag}'] == '${value}'`).join(' or ')})`}`).join(' and ')} then return '${feature.train_protection}', ${signals_railway_line.features.length - featureIndex} end`).join('')}
  
  return nil, 0
end

local signal_tags = {${signals_railway_signals.tags.map(tag => `
  { tag = '${tag.tag}', type = '${tag.type}' },`).join('')}
}

function signal_deactivated(tags)
  return (${signals_railway_signals.types.map((type, typeIndex) => `
    tags['railway:signal:${type.type}:deactivated']${(typeIndex < signals_railway_signals.types.length - 1) ? ' or' : ''}`).join('')}
  ) == 'yes'
end

local poi_railway_values = {${pois.features.flatMap(feature => [...(feature.variants || []), feature]).flatMap(feature => feature.tags).filter(tag => tag.tag === 'railway').flatMap(tag => tag.value ? [tag.value] : (tag.values ? tag.values : [])).map(tag => `
  '${tag}',`).join('')}
}

function poi(tags)${pois.features.flatMap(feature => [...(feature.variants || []).map(variant => ({...variant, minzoom: feature.minzoom, layer: feature.layer })), feature]).map((feature, featureIndex) => `
  if ${feature.tags.map(tag => `${tag.value ? `tags['${tag.tag}'] == '${tag.value}'`: `(${tag.values.map(value => `tags['${tag.tag}'] == '${value}'`).join(' or ')})`}`).join(' and ')} then return '${feature.feature}', ${featureIndex + 1}, ${feature.minzoom}, '${feature.layer}' end`).join('')}
  
  return nil, 0, 100
end

return {
  train_protection = train_protection,
  signal_tags = signal_tags,
  signal_deactivated = signal_deactivated,
  poi_railway_values = poi_railway_values,
  poi = poi,
}
`;

console.log(lua)
