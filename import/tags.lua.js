import fs from 'fs'
import yaml from 'yaml'

const signals_railway_line = yaml.parse(fs.readFileSync('train_protection.yaml', 'utf8'))
const signals_railway_signals = yaml.parse(fs.readFileSync('signals_railway_signals.yaml', 'utf8'))
const pois = yaml.parse(fs.readFileSync('poi.yaml', 'utf8'))
const station_references = yaml.parse(fs.readFileSync('stations.yaml', 'utf8')).references

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

local poi_railway_values = {${pois.features.flatMap(feature => [...(feature.variants || []), feature]).flatMap(feature => feature.tags).filter(tag => tag.tag === 'railway').flatMap(tag => tag.value ? [tag.value] : (tag.values ? tag.values : [])).map(tag => `
  '${tag}',`).join('')}
}

function poi(tags)${pois.features.flatMap(feature => [...(feature.variants || []).map(variant => ({...variant, minzoom: feature.minzoom, layer: feature.layer })), feature]).map((feature, featureIndex) => `
  if ${feature.tags.map(tag => `${tag.value ? `tags['${tag.tag}'] == '${tag.value}'`: `(${tag.values.map(value => `tags['${tag.tag}'] == '${value}'`).join(' or ')})`}`).join(' and ')} then return '${feature.feature}', ${featureIndex + 1}, ${feature.minzoom}, '${feature.layer}' end`).join('')}
  
  return nil, 0, 100
end

function map_station_reference(tags)
  return ${station_references.filter(ref => ref.map).flatMap(tag => tag.tags).map(tag => `tags['${tag}']`).join(` or
    `)}
end
local station_references = {${station_references.map(ref => `
  { id = '${ref.id}', description = '${ref.description}'${ref.country ? `, country = '${ref.country}'` : ''}, tags = {${ref.tags.map(tag => `'${tag}'`).join(', ')}} },`).join('')}
}

return {
  train_protection = train_protection,
  signal_tags = signal_tags,
  poi_railway_values = poi_railway_values,
  poi = poi,
  station_references = station_references,
  map_station_reference = map_station_reference,
}
`;

console.log(lua)
