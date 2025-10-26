import fs from 'fs'
import yaml from 'yaml'

const signals_railway_line = yaml.parse(fs.readFileSync('features/train_protection.yaml', 'utf8'))
const all_signals = yaml.parse(fs.readFileSync('features/signals_railway_signals.yaml', 'utf8'))
const loading_gauges = yaml.parse(fs.readFileSync('features/loading_gauge.yaml', 'utf8'))
const poi = yaml.parse(fs.readFileSync('features/poi.yaml', 'utf8'))
const stations = yaml.parse(fs.readFileSync('features/stations.yaml', 'utf8'))
const railway_lines = yaml.parse(fs.readFileSync('features/railway_line.yaml', 'utf8'))

const signal_types = all_signals.types;

const speed_railway_signals = all_signals.features.filter(feature => feature.tags.find(tag => all_signals.types.some(type => type.layer === 'speed' && `railway:signal:${type.type}` === tag.tag)))
const signals_railway_signals = all_signals.features.filter(feature => feature.tags.find(tag => all_signals.types.some(type => type.layer === 'signals' && `railway:signal:${type.type}` === tag.tag)))
const electrification_signals = all_signals.features.filter(feature => feature.tags.find(tag => all_signals.types.some(type => type.layer === 'electrification' && `railway:signal:${type.type}` === tag.tag)))

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
  mapillary: 'https://www.mapillary.com/app/?pKey=%s',
};

const featureLinks = {
  openstreetmap: {
    view: 'https://www.openstreetmap.org/{osm_type}/{osm_id}',
    edit: 'https://www.openstreetmap.org/edit?{osm_type}={osm_id}',
  },
  openhistoricalmap: {
    view: 'https://www.openhistoricalmap.org/{osm_type}/{osm_id}#date={date}-01-01&layers=R',
    edit: 'https://www.openhistoricalmap.org/edit?{osm_type}={osm_id}',
  },
};

const generateSignalFeatures = (features, types) =>
  requireUniqueEntries([
    ...features.flatMap(feature => [
      [
        feature.icon.default,
        {
          country: feature.country,
          name: feature.description,
        }
      ],
      ...(
        feature.icon.match
          ? [
            ...[...new Set(
              feature.icon.cases
                .filter(iconCase => !iconCase.description)
                .map(iconCase => iconCase.value)
            )].map(iconCaseValue => [iconCaseValue, {
              country: feature.country,
              name: feature.description,
            }]),
            ...feature.icon.cases
              .filter(iconCase => iconCase.description)
              .map(iconCase => [iconCase.value, {
                country: feature.country,
                name: `${feature.description} (${iconCase.description})`,
              }]),
          ]
          : []
      ),
    ]),
    ...types.map(type => [
      `general/signal-unknown-${type.type}`,
      {
        name: `Unknown signal (${type.type})`,
      }
    ]),
    [
      'general/signal-unknown',
      {
        name: 'Unknown signal',
      },
    ],
  ]);

// TODO move icon SVGs to proxy
const railwayLineFeatures = {
  labelProperty: 'standard_label',
  featureLinks: featureLinks.openstreetmap,
  features: Object.fromEntries(
    railway_lines.features.map(feature => [
      feature.type,
      {
        name: feature.description,
        type: 'line',
      },
    ])
  ),
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
      name: 'High speed',
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
    owner: {
      name: 'Owner',
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
    mapillary: {
      name: 'Mapillary',
      link: links.mapillary,
    },
    wikipedia: {
      name: 'Wikipedia',
      link: links.wikipedia,
      format: {
        country_prefix: {}
      },
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

const poiFeatures = layer => ({
  featureLinks: featureLinks.openstreetmap,
  features: Object.fromEntries(
    poi.features
      .filter(feature => feature.layer === layer)
      .flatMap(feature =>
        [
          [feature.feature, {name: feature.description}]
        ].concat(
          (feature.variants || []).map(variant => [variant.feature, {name: `${feature.description}${variant.description ? ` (${variant.description})` : ''}`}])
        )
      )
  ),
  properties: {
    ref: {
      name: 'Reference',
    },
    position: {
      name: 'Position',
    },
    wikidata: {
      name: 'Wikidata',
      link: links.wikidata,
    },
    wikimedia_commons: {
      name: 'Wikimedia',
      link: links.wikimedia_commons,
    },
    mapillary: {
      name: 'Mapillary',
      link: links.mapillary,
    },
    wikipedia: {
      name: 'Wikipedia',
      link: links.wikipedia,
      format: {
        country_prefix: {}
      },
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
})

// TODO move tram / metro stops to stations
const stationFeatures = {
  featureProperty: 'feature',
  labelProperty: 'name',
  featureLinks: featureLinks.openstreetmap,
  features: requireUniqueEntries(
    stations.features.map(feature => [feature.feature, {name: feature.description}])
  ),
  properties: {
    station: {
      name: 'Type',
    },
    state: {
      name: 'State',
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
    position: {
      name: 'Position',
    },
    wikidata: {
      name: 'Wikidata',
      link: links.wikidata,
    },
    wikimedia_commons: {
      name: 'Wikimedia',
      link: links.wikimedia_commons,
    },
    mapillary: {
      name: 'Mapillary',
      link: links.mapillary,
    },
    wikipedia: {
      name: 'Wikipedia',
      link: links.wikipedia,
      format: {
        country_prefix: {}
      },
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
  'standard_railway_line_low-standard_railway_line_low': railwayLineFeatures,
  'speed_railway_line_low-speed_railway_line_low': railwayLineFeatures,
  'signals_railway_line_low-signals_railway_line_low': railwayLineFeatures,
  'electrification_railway_line_low-electrification_railway_line_low': railwayLineFeatures,
  'gauge_railway_line_low-gauge_railway_line_low': railwayLineFeatures,
  'loading_gauge_railway_line_low-loading_gauge_railway_line_low': railwayLineFeatures,
  'track_class_railway_line_low-track_class_railway_line_low': railwayLineFeatures,
  'operator_railway_line_low-operator_railway_line_low': railwayLineFeatures,
  'openhistoricalmap-transport_lines': {
    labelProperty: 'name',
    featureProperty: 'type',
    featureLinks: featureLinks.openhistoricalmap,
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
      funicular: {
        name: 'Funicular',
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
        name: 'Tunnel',
        format: {
          lookup: 'boolean',
        },
      },
      bridge: {
        name: 'Bridge',
        format: {
          lookup: 'boolean',
        },
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
  'openhistoricalmap-transport_points_centroids': {
    featureProperty: 'type',
    labelProperty: 'name',
    featureLinks: featureLinks.openhistoricalmap,
    features: {
      station: {
        name: 'Station',
      },
      halt: {
        name: 'Halt',
      },
    },
  },
  'standard_railway_text_stations_low-standard_railway_text_stations_low': stationFeatures,
  'standard_railway_text_stations_med-standard_railway_text_stations_med': stationFeatures,
  'openrailwaymap_standard-standard_railway_text_stations': stationFeatures,
  'openrailwaymap_standard-standard_railway_grouped_stations': stationFeatures,
  'openrailwaymap_standard-standard_railway_grouped_station_areas': {
    featureLinks: featureLinks.openstreetmap,
    features: {
      station_area_group: {
        name: 'Station area group',
        type: 'relation',
      },
    },
  },
  'openrailwaymap_standard-standard_railway_turntables': {
    featureLinks: featureLinks.openstreetmap,
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
  'openrailwaymap_standard-standard_railway_platforms': {
    featureLinks: featureLinks.openstreetmap,
    features: {
      platform: {
        name: 'Platform',
        type: 'polygon',
      },
    },
    labelProperty: 'name',
    properties: {
      ref: {
        name: 'Reference',
      },
      height: {
        name: 'Height',
        format: {
          template: '%.2d m',
        },
      },
      surface: {
        name: 'Surface',
      },
      elevator: {
        name: 'Elevator',
      },
      shelter: {
        name: 'Shelter',
      },
      lit: {
        name: 'Lit',
      },
      bin: {
        name: 'Bin',
      },
      bench: {
        name: 'Bench',
      },
      wheelchair: {
        name: 'Wheelchair accessible',
      },
      departures_board: {
        name: 'Departures board',
      },
      tactile_paving: {
        name: 'Tactile paving',
      },
    }
  },
  'openrailwaymap_standard-standard_railway_platform_edges': {
    featureLinks: featureLinks.openstreetmap,
    features: {
      platform_edge: {
        name: 'Platform edge',
        type: 'line',
      },
    },
    labelProperty: 'ref',
    properties: {
      height: {
        name: 'Height',
        format: {
          template: '%.2d m',
        },
      },
      tactile_paving: {
        name: 'Tactile paving',
      },
    }
  },
  'openrailwaymap_standard-standard_station_entrances': {
    featureLinks: featureLinks.openstreetmap,
    featureProperty: 'type',
    features: {
      subway: {
        name: 'Subway entrance',
      },
      train: {
        name: 'Train station entrance',
      },
    },
    properties: {
      name: {
        name: 'Name',
      },
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
  'openrailwaymap_standard-standard_railway_symbols': poiFeatures('standard'),
  "high-railway_text_km": {
    featureProperty: 'railway',
    featureLinks: featureLinks.openstreetmap,
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
      pos_exact: {
        name: 'Exact position',
      },
      type: {
        name: 'Type',
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
    featureLinks: featureLinks.openstreetmap,
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
      position: {
        name: 'Position',
      },
      wikidata: {
        name: 'Wikidata',
        link: links.wikidata,
      },
      wikimedia_commons: {
        name: 'Wikimedia',
        link: links.wikimedia_commons,
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
    featureProperty: 'railway',
    featureLinks: featureLinks.openstreetmap,
    features: {
      signal: {
        name: 'Signal',
      },
      buffer_stop: {
        name: 'Buffer stop',
      },
      derail: {
        name: 'Derailer',
      },
      vacancy_detection: {
        name: 'Vacancy detection',
      },
    },
    properties: {
      feature0: {
        name: 'Primary signal',
        format: {
          lookup: 'speed_railway_signals',
        },
      },
      feature1: {
        name: 'Secondary signal',
        format: {
          lookup: 'speed_railway_signals',
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
      deactivated0: {
        name: 'Primary deactivated',
      },
      deactivated1: {
        name: 'Secondary deactivated',
      },
      direction_both: {
        name: 'both directions',
      },
      ...Object.fromEntries(all_signals.tags.map(tag => [tag.tag, { name: tag.title, description: tag.description, format: tag.format }])),
      position: {
        name: 'Position',
      },
      wikidata: {
        name: 'Wikidata',
        link: links.wikidata,
      },
      wikimedia_commons: {
        name: 'Wikimedia',
        link: links.wikimedia_commons,
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
  'openrailwaymap_signals-signals_railway_signals': {
    featureProperty: 'railway',
    featureLinks: featureLinks.openstreetmap,
    features: {
      signal: {
        name: 'Signal',
      },
      buffer_stop: {
        name: 'Buffer stop',
      },
      derail: {
        name: 'Derailer',
      },
      vacancy_detection: {
        name: 'Vacancy detection',
      },
    },
    properties: {
      feature0: {
        name: 'Primary signal',
        format: {
          lookup: 'signals_railway_signals',
        },
      },
      feature1: {
        name: 'Secondary signal',
        format: {
          lookup: 'signals_railway_signals',
        },
      },
      feature2: {
        name: 'Tertiary signal',
        format: {
          lookup: 'signals_railway_signals',
        },
      },
      feature3: {
        name: 'Quaternary signal',
        format: {
          lookup: 'signals_railway_signals',
        },
      },
      feature4: {
        name: 'Quinary signal',
        format: {
          lookup: 'signals_railway_signals',
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
      deactivated0: {
        name: 'Primary deactivated',
      },
      deactivated1: {
        name: 'Secondary deactivated',
      },
      deactivated2: {
        name: 'Tertiary deactivated',
      },
      deactivated3: {
        name: 'Quaternary deactivated',
      },
      deactivated4: {
        name: 'Quinary deactivated',
      },
      direction_both: {
        name: 'both directions',
      },
      ...Object.fromEntries(all_signals.tags.map(tag => [tag.tag, { name: tag.title, description: tag.description, format: tag.format }])),
      position: {
        name: 'Position',
      },
      wikidata: {
        name: 'Wikidata',
        link: links.wikidata,
      },
      wikimedia_commons: {
        name: 'Wikimedia',
        link: links.wikimedia_commons,
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
  'openrailwaymap_signals-signals_signal_boxes': {
    labelProperty: 'name',
    featureLinks: featureLinks.openstreetmap,
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
      position: {
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
    featureProperty: 'railway',
    featureLinks: featureLinks.openstreetmap,
    features: {
      signal: {
        name: 'Signal',
      },
      buffer_stop: {
        name: 'Buffer stop',
      },
      derail: {
        name: 'Derailer',
      },
      vacancy_detection: {
        name: 'Vacancy detection',
      },
    },
    properties: {
      feature: {
        name: 'Signal',
        format: {
          lookup: 'electrification_signals',
        },
      },
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
      ...Object.fromEntries(all_signals.tags.map(tag => [tag.tag, { name: tag.title, description: tag.description, format: tag.format }])),
      position: {
        name: 'Position',
      },
      wikidata: {
        name: 'Wikidata',
        link: links.wikidata,
      },
      wikimedia_commons: {
        name: 'Wikimedia',
        link: links.wikimedia_commons,
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
  'openrailwaymap_electrification-electrification_railway_symbols': poiFeatures('electrification'),
  'openrailwaymap_electrification-catenary': {
    featureProperty: 'feature',
    featureLinks: featureLinks.openstreetmap,
    features: {
      mast: {
        name: 'Catenary mast',
      },
      portal: {
        name: 'Catenary portal',
      },
    },
    properties: {
      ref: {
        name: 'Reference',
      },
      position: {
        name: 'Position',
      },
      transition: {
        name: 'Transition point',
      },
      structure: {
        name: 'Structure',
      },
      supporting: {
        name: 'Supporting',
      },
      attachment: {
        name: 'Attachment',
      },
      tensioning: {
        name: 'Tensioning',
      },
      insulator: {
        name: 'Insulator',
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
  'openrailwaymap_operator-operator_railway_symbols': poiFeatures('operator'),

  // Search results

  search: {
    labelProperty: 'label',
    featureLinks: featureLinks.openstreetmap,
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
  speed_railway_signals: {
    features: generateSignalFeatures(speed_railway_signals, signal_types.filter(type => type.layer === 'speed')),
  },
  signals_railway_signals: {
    features: generateSignalFeatures(signals_railway_signals, signal_types.filter(type => type.layer === 'signals')),
  },
  electrification_signals: {
    features: generateSignalFeatures(electrification_signals, signal_types.filter(type => type.layer === 'electrification')),
  },

  boolean: {
    features: {
      0: {
        name: 'no',
      },
      1: {
        name: 'yes',
      },
    },
  },
};

if (import.meta.url.endsWith(process.argv[1])) {
  console.log(JSON.stringify(features))
}
