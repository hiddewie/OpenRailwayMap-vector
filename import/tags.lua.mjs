import fs from 'fs'
import yaml from 'yaml'

const signals_railway_line = yaml.parse(fs.readFileSync('train_protection.yaml', 'utf8'))
const signals_railway_signals = yaml.parse(fs.readFileSync('signals_railway_signals.yaml', 'utf8'))
const pois = yaml.parse(fs.readFileSync('poi.yaml', 'utf8'))
const station_references = yaml.parse(fs.readFileSync('stations.yaml', 'utf8')).references
const track_classes = yaml.parse(fs.readFileSync('track_class.yaml', 'utf8')).track_classes

const trainProtectionTags = [...new Set(signals_railway_line.features.flatMap(feature => feature.tags).map(tag => tag.tag))].toSorted();

/**
 * Template that builds Lua functions used in the Osm2Psql Lua import, and taking the YAML configuration into account
 */
const lua = `
function train_protection(tags, prefix)
  -- Match a known system
  local systems = {}
  local rank = 0
  local has_systems = false
  local excluded = {}
  ${signals_railway_line.features.map((feature, featureIndex) => `
  if (not excluded['${feature.train_protection}']) and ${feature.tags.map(tag => `${tag.value ? `tags[prefix .. '${tag.tag}'] == '${tag.value}'`: `(${tag.values.map(value => `tags[prefix .. '${tag.tag}'] == '${value}'`).join(' or ')})`}`).join(' and ')} then table.insert(systems, '${feature.train_protection}'); rank = math.max(rank, ${signals_railway_line.features.length - featureIndex + 1}); has_systems = true${feature.exclude ? `;${feature.exclude.map(exclude => ` excluded['${exclude}'] = true;`).join('')}`: ''} end`).join('')}

  if has_systems then
    return systems, rank
  end

  -- Match explicit no train protection system
  local any_tag_set_to_no = ${trainProtectionTags.map(tag => `tags[prefix .. '${tag}'] == 'no'`).join(' or ')}
  local all_tags_set_to_no_or_empty = ${trainProtectionTags.map(tag => `(tags[prefix .. '${tag}'] or 'no') == 'no'`).join(' and ')}
  
  if any_tag_set_to_no and all_tags_set_to_no_or_empty then
    return {'none'}, 1  
  end
    
  -- Unknown
  return nil, nil
end

local signal_tags = {${signals_railway_signals.tags.map(tag => `
  { tag = '${tag.tag}', type = '${tag.type ?? 'string'}' },`).join('')}
}

local poi_railway_values = {${pois.features.flatMap(feature => [...(feature.variants || []), feature]).flatMap(feature => feature.tags).filter(tag => tag.tag === 'railway').flatMap(tag => tag.value ? [tag.value] : (tag.values ? tag.values : [])).map(tag => `
  '${tag}',`).join('')}
}

function poi(tags)${pois.features.flatMap(feature => [...(feature.variants || []).map(variant => ({...variant, minzoom: feature.minzoom, type: feature.type })), feature]).map((feature, featureIndex) => `
  if ${feature.tags.map(tag => `${tag.value ? `tags['${tag.tag}'] == '${tag.value}'`: `(${tag.values.map(value => `tags['${tag.tag}'] == '${value}'`).join(' or ')})`}`).join(' and ')} then return '${feature.feature}', ${featureIndex + 1}, ${feature.minzoom}, '${feature.type}' end`).join('')}
  
  return nil, 0, 100
end

function map_station_reference(tags)
  return ${station_references.filter(ref => ref.map).flatMap(tag => tag.tags).map(tag => `tags['${tag}']`).join(` or
    `)}
end
local station_references = {${station_references.map(ref => `
  { id = '${ref.id}', description = '${ref.description}'${ref.country ? `, country = '${ref.country}'` : ''}, tags = {${ref.tags.map(tag => `'${tag}'`).join(', ')}} },`).join('')}
}

local track_class_axle_load = {${track_classes.filter(({axle_load}) => axle_load).map(({value, axle_load}) => `
  ["${value}"] = ${axle_load},`).join('')}
}
local track_class_metre_load = {${track_classes.filter(({metre_load}) => metre_load).map(({value, metre_load}) => `
  ["${value}"] = ${metre_load},`).join('')}
}

return {
  train_protection = train_protection,
  signal_tags = signal_tags,
  poi_railway_values = poi_railway_values,
  poi = poi,
  station_references = station_references,
  map_station_reference = map_station_reference,
  track_class_axle_load = track_class_axle_load,
  track_class_metre_load = track_class_metre_load,
}
`;

console.log(lua)
