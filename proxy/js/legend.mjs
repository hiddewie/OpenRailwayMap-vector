import fs from 'fs'
import yaml from 'yaml'

const signals_railway_line = yaml.parse(fs.readFileSync('features/train_protection.yaml', 'utf8'))
const all_signals = yaml.parse(fs.readFileSync('features/signals_railway_signals.yaml', 'utf8'))
const loading_gauges = yaml.parse(fs.readFileSync('features/loading_gauge.yaml', 'utf8'))
const track_classes = yaml.parse(fs.readFileSync('features/track_class.yaml', 'utf8'))
const poi = yaml.parse(fs.readFileSync('features/poi.yaml', 'utf8'))
const stations = yaml.parse(fs.readFileSync('features/stations.yaml', 'utf8'))
const operators = yaml.parse(fs.readFileSync('features/operators.yaml', 'utf8'))

const signal_types = all_signals.types;

const speed_railway_signals = all_signals.features.filter(feature => feature.tags.find(tag => tag.tag === 'railway:signal:speed_limit' || tag.tag === 'railway:signal:speed_limit_distant'))
const signals_railway_signals = all_signals.features.filter(feature => !feature.tags.find(tag => tag.tag === 'railway:signal:speed_limit' || tag.tag === 'railway:signal:speed_limit_distant' || tag.tag === 'railway:signal:electricity'))
const electrification_signals = all_signals.features.filter(feature => feature.tags.find(tag => tag.tag === 'railway:signal:electricity'))

const speedLegends = [
  10,
  20,
  30,
  40,
  50,
  60,
  70,
  80,
  90,
  100,
  120,
  140,
  160,
  180,
  200,
  220,
  240,
  260,
  280,
  300,
  320,
  340,
  360
];

const electrificationLegends = {
  voltageFrequency: [
    { legend: '> 25 kV ~', voltage: 25000, frequency: 60, electrification_label: '26kV 60Hz' },
    { legend: '25 kV 60 Hz ~', voltage: 25000, frequency: 60, electrification_label: '25kV 60Hz' },
    { legend: '25 kV 50 Hz ~', voltage: 25000, frequency: 50, electrification_label: '25kV 50Hz' },
    { legend: '20 kV 60 Hz ~', voltage: 20000, frequency: 60, electrification_label: '20kV 60Hz' },
    { legend: '20 kV 50 Hz ~', voltage: 20000, frequency: 50, electrification_label: '20kV 50Hz' },
    { legend: '15 kV - 25 kV ~', voltage: 15001, frequency: 60, electrification_label: '16kV 60Hz' },
    { legend: '15 kV 16.7 Hz ~', voltage: 15000, frequency: 16.7, electrification_label: '15kV 16.7Hz' },
    { legend: '15 kV 16.67 Hz ~', voltage: 15000, frequency: 16.67, electrification_label: '15kV 16.67Hz' },
    { legend: '12.5 kV - 15 kV ~', voltage: 12501, frequency: 60, electrification_label: '13kV 60Hz' },
    { legend: '12.5 kV 60 Hz ~', voltage: 12500, frequency: 60, electrification_label: '12.5kV 60Hz' },
    { legend: '12.5 kV 25 Hz ~', voltage: 12500, frequency: 25, electrification_label: '12.5kV 25Hz' },
    { legend: '< 12.5 kV ~', voltage: 12499, frequency: 60, electrification_label: '11kV 60Hz' },
    { legend: '> 3 kV =', voltage: 3001, frequency: 0, electrification_label: '4kV =' },
    { legend: '3 kV =', voltage: 3000, frequency: 0, electrification_label: '3kV =' },
    { legend: '1.5 kV - 3 kV =', voltage: 1501, frequency: 0, electrification_label: '2kV =' },
    { legend: '1.5 kV =', voltage: 1500, frequency: 0, electrification_label: '1.5kV =' },
    { legend: '1 kV - 1.5 kV =', voltage: 1001, frequency: 0, electrification_label: '1.2kV =' },
    { legend: '1 kV =', voltage: 1000, frequency: 0, electrification_label: '1kV =' },
    { legend: '750 V - 1 kV =', voltage: 751, frequency: 0, electrification_label: '800V =' },
    { legend: '750 V =', voltage: 750, frequency: 0, electrification_label: '750V =' },
    { legend: '< 750 V =', voltage: 749, frequency: 0, electrification_label: '700V =' },
  ],
  maximumCurrent: [
    { maximumCurrent: 500 },
    { maximumCurrent: 600 },
    { maximumCurrent: 1500 },
    { maximumCurrent: 1600 },
    { maximumCurrent: 1800 },
    { maximumCurrent: 2000 },
    { maximumCurrent: 2400 },
    { maximumCurrent: 2600 },
    { maximumCurrent: 3200 },
    { maximumCurrent: 4000 },
  ],
  power: [
    { legend: '2 MW', voltage: 750, maximumCurrent: 2600 },
    { legend: '4.8 MW', voltage: 3000, maximumCurrent: 1600 },
    { legend: '6 MW', voltage: 3000, maximumCurrent: 2000 },
    { legend: '7.2 MW', voltage: 3000, maximumCurrent: 2400 },
    { legend: '9 MW', voltage: 15000, maximumCurrent: 600 },
    { legend: '12 MW', voltage: 3000, maximumCurrent: 4000 },
    { legend: '37.5 MW', voltage: 25000, maximumCurrent: 1500 },
  ],
};

const gaugeLegends = [
  {min: 63, legend: '63 - 88 mm'},
  {min: 88, legend: '88 - 127 mm'},
  {min: 127, legend: '127 - 184 mm'},
  {min: 184, legend: '184 - 190 mm'},
  {min: 190, legend: '190 - 260 mm'},
  {min: 260, legend: '260 - 380 mm'},
  {min: 380, legend: '380 - 500 mm'},
  {min: 500, legend: '500 - 597 mm'},
  {min: 597, legend: '597 - 600 mm'},
  {min: 600, legend: '600 - 609 mm'},
  {min: 609, legend: '609 - 700 mm'},
  {min: 700, legend: '700 - 750 mm'},
  {min: 750, legend: '750 - 760 mm'},
  {min: 760, legend: '760 - 762 mm'},
  {min: 762, legend: '762 - 785 mm'},
  {min: 785, legend: '785 - 800 mm'},
  {min: 800, legend: '800 - 891 mm'},
  {min: 891, legend: '891 - 900 mm'},
  {min: 900, legend: '900 - 914 mm'},
  {min: 914, legend: '914 - 950 mm'},
  {min: 950, legend: '950 - 1000 mm'},
  {min: 1000, legend: '1000 - 1009 mm'},
  {min: 1009, legend: '1009 - 1050 mm'},
  {min: 1050, legend: '1050 - 1066 mm'},
  {min: 1066, legend: '1066 - 1100 mm'},
  {min: 1100, legend: '1100 - 1200 mm'},
  {min: 1200, legend: '1200 - 1372 mm'},
  {min: 1372, legend: '1372 - 1422 mm'},
  {min: 1422, legend: '1422 - 1432 mm'},
  {min: 1432, legend: '1432 - 1435 mm'},
  {min: 1435, legend: '1435 - 1440 mm'},
  {min: 1440, legend: '1440 - 1445 mm'},
  {min: 1445, legend: '1445 - 1450 mm'},
  {min: 1450, legend: '1450 - 1458 mm'},
  {min: 1458, legend: '1458 - 1495 mm'},
  {min: 1495, legend: '1495 - 1520 mm'},
  {min: 1520, legend: '1520 - 1522 mm'},
  {min: 1522, legend: '1522 - 1524 mm'},
  {min: 1524, legend: '1524 - 1581 mm'},
  {min: 1581, legend: '1581 - 1588 mm'},
  {min: 1588, legend: '1588 - 1600 mm'},
  {min: 1600, legend: '1600 - 1668 mm'},
  {min: 1668, legend: '1668 - 1672 mm'},
  {min: 1672, legend: '1672 - 1700 mm'},
  {min: 1700, legend: '1700 - 1800 mm'},
  {min: 1800, legend: '1800 - 1880 mm'},
  {min: 1880, legend: '1880 - 2000 mm'},
  {min: 2000, legend: '2000 - 3000 mm'},
];

const signalFeatures = (feature) =>
  // Generate signal features for each icon variant. For an icon variant, use the default (or last) variant of the other icon cases.
  feature.icon.map((icon, i) => ({
    legend: icon.default ? icon.description : icon.cases[0].description,
    icon: feature.icon
      .map((otherIcon, j) => i === j
        ? `${icon.default ?? icon.cases[0].example ?? icon.cases[0].value}${icon.position ? `@${icon.position}` : ''}`
        : `${otherIcon.default ?? otherIcon.cases[otherIcon.cases.length - 1].example ?? otherIcon.cases[otherIcon.cases.length - 1].value}${otherIcon.position ? `@${otherIcon.position}` : ''}`
      )
      .join('|'),
    variants: (icon.cases ?? []).slice(icon.default ? 0 : 1).map(item => ({
      legend: item.description,
      icon: feature.icon
        .map((otherIcon, j) => i === j
          ? `${item.example ?? item.value}${icon.position ? `@${icon.position}` : ''}`
          : `${otherIcon.default ?? otherIcon.cases[otherIcon.cases.length - 1].example ?? otherIcon.cases[otherIcon.cases.length - 1].value}${otherIcon.position ? `@${otherIcon.position}` : ''}`
        )
        .join('|'),
    })),
  }));

// TODO move source layers to own property
const legendData = {
  standard: {
    countries: [],

    "standard_railway_line_low-standard_railway_line_low": {
      key: [
        'highspeed',
        'feature',
        'state',
        'usage',
        'service',
      ],
      features: [
        {
          legend: 'Highspeed main line',
          type: 'line',
          properties: {
            highspeed: true,
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            tunnel: false,
            bridge: false,
            ref: 'H1',
            standard_label: 'H1 Name',
            track_ref: '8b',
            way_length: 1.0,
          },
        },
        {
          legend: 'Main line',
          type: 'line',
          properties: {
            highspeed: false,
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            tunnel: false,
            bridge: false,
            ref: 'L1',
            standard_label: 'L1 Name',
            track_ref: '8b',
            way_length: 1.0,
          },
        },
        {
          legend: 'Ferry',
          type: 'line',
          properties: {
            highspeed: false,
            feature: 'ferry',
            state: 'present',
            usage: 'main',
            service: null,
            tunnel: false,
            bridge: false,
            ref: 'F1',
            standard_label: 'F1 Ship',
            track_ref: null,
            way_length: 1.0,
          }
        },
      ],
    },
    "openrailwaymap_low-railway_line_high": {
      key: [
        'highspeed',
        'feature',
        'state',
        'usage',
        'service',
      ],
      features: [
        {
          legend: 'Highspeed main line',
          type: 'line',
          properties: {
            highspeed: true,
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            tunnel: false,
            bridge: false,
            ref: 'H1',
            standard_label: 'H1 Name',
            track_ref: '8b',
            way_length: 1.0,
          },
        },
        {
          legend: 'Main line',
          type: 'line',
          properties: {
            highspeed: false,
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            tunnel: false,
            bridge: false,
            ref: 'L1',
            standard_label: 'L1 Name',
            track_ref: '8b',
            way_length: 1.0,
          },
        },
        {
          legend: 'Branch line',
          type: 'line',
          properties: {
            highspeed: false,
            feature: 'rail',
            state: 'present',
            usage: 'branch',
            service: null,
            tunnel: false,
            bridge: false,
            ref: 'B1',
            standard_label: 'B1 Name',
            track_ref: '8b',
            way_length: 1.0,
          }
        },
        {
          legend: 'Ferry',
          type: 'line',
          properties: {
            highspeed: false,
            feature: 'ferry',
            state: 'present',
            usage: 'main',
            service: null,
            tunnel: false,
            bridge: false,
            ref: 'F1',
            standard_label: 'F1 Ship',
            track_ref: null,
            way_length: 1.0,
          }
        },
      ],
    },
    "high-railway_line_high": {
      key: [
        'highspeed',
        'feature',
        'state',
        'usage',
        'service',
      ],
      features: [
        {
          legend: 'Highspeed main line',
          type: 'line',
          properties: {
            highspeed: true,
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            tunnel: false,
            bridge: false,
            ref: 'H1',
            standard_label: 'H1 Name',
            track_ref: '8b',
            way_length: 1.0,
          },
        },
        {
          legend: 'Main line',
          type: 'line',
          properties: {
            highspeed: false,
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            tunnel: false,
            bridge: false,
            ref: 'L1',
            standard_label: 'L1 Name',
            track_ref: '8b',
            way_length: 1.0,
          },
          variants: [
            {
              legend: 'bridge',
              properties: {
                bridge: true,
                standard_label: null,
                ref: null,
                track_ref: null,
                way_length: 100000,
              },
            },
            {
              legend: 'tunnel',
              properties: {
                tunnel: true,
                standard_label: null,
                ref: null,
                track_ref: null,
                way_length: 1.0,
              },
            },
          ],
        },
        {
          legend: 'Branch line',
          type: 'line',
          properties: {
            highspeed: false,
            feature: 'rail',
            state: 'present',
            usage: 'branch',
            service: null,
            tunnel: false,
            bridge: false,
            ref: 'B1',
            standard_label: 'B1 Name',
            track_ref: '9b',
            way_length: 1.0,
          }
        },
        {
          legend: 'Industrial line',
          type: 'line',
          minzoom: 9,
          properties: {
            highspeed: false,
            feature: 'rail',
            state: 'present',
            usage: 'industrial',
            service: null,
            tunnel: false,
            bridge: false,
            ref: 'I1',
            standard_label: 'I1 Name',
            track_ref: null,
            way_length: 1.0,
          }
        },
        {
          legend: 'Narrow gauge line',
          type: 'line',
          minzoom: 10,
          properties: {
            highspeed: false,
            feature: 'narrow_gauge',
            state: 'present',
            usage: null,
            service: null,
            tunnel: false,
            bridge: false,
            ref: 'N1',
            standard_label: 'N1 Name',
            track_ref: null,
            way_length: 1.0,
          }
        },
        {
          legend: 'Subway',
          type: 'line',
          minzoom: 9,
          properties: {
            highspeed: false,
            feature: 'subway',
            state: 'present',
            usage: null,
            service: null,
            tunnel: false,
            bridge: false,
            ref: 'S1',
            standard_label: 'S1 Name',
            track_ref: null,
            way_length: 1.0,
          }
        },
        {
          legend: 'Light rail',
          type: 'line',
          minzoom: 9,
          properties: {
            highspeed: false,
            feature: 'light_rail',
            state: 'present',
            usage: null,
            service: null,
            tunnel: false,
            bridge: false,
            ref: 'L1',
            standard_label: 'L1 Name',
            track_ref: null,
            way_length: 1.0,
          }
        },
        {
          legend: 'Tram',
          type: 'line',
          minzoom: 9,
          properties: {
            highspeed: false,
            feature: 'tram',
            state: 'present',
            usage: null,
            service: null,
            tunnel: false,
            bridge: false,
            ref: 'T1',
            standard_label: 'T1 Name',
            track_ref: null,
            way_length: 1.0,
          }
        },
        {
          legend: 'Monorail',
          type: 'line',
          minzoom: 9,
          properties: {
            highspeed: false,
            feature: 'monorail',
            state: 'present',
            usage: null,
            service: null,
            tunnel: false,
            bridge: false,
            ref: 'M1',
            standard_label: 'M1 Name',
            track_ref: null,
            way_length: 1.0,
          }
        },
        {
          legend: 'Test railway',
          type: 'line',
          minzoom: 9,
          properties: {
            highspeed: false,
            feature: 'rail',
            state: 'present',
            usage: 'test',
            service: null,
            tunnel: false,
            bridge: false,
            ref: 'T1',
            standard_label: 'T1 Name',
            track_ref: null,
            way_length: 1.0,
          }
        },
        {
          legend: 'Military railway',
          type: 'line',
          minzoom: 9,
          properties: {
            highspeed: false,
            feature: 'rail',
            state: 'present',
            usage: 'military',
            service: null,
            tunnel: false,
            bridge: false,
            ref: 'M1',
            standard_label: 'M1 Name',
            track_ref: null,
            way_length: 1.0,
          }
        },
        {
          legend: 'Miniature railway',
          type: 'line',
          minzoom: 12,
          properties: {
            highspeed: false,
            feature: 'miniature',
            state: 'present',
            usage: null,
            service: null,
            tunnel: false,
            bridge: false,
            ref: 'M3',
            standard_label: 'M3 Name',
            track_ref: null,
            way_length: 1.0,
          }
        },
        {
          legend: 'Yard',
          type: 'line',
          minzoom: 10,
          properties: {
            highspeed: false,
            feature: 'rail',
            state: 'present',
            usage: null,
            service: 'yard',
            tunnel: false,
            bridge: false,
            ref: null,
            standard_label: null,
            track_ref: null,
            way_length: 1.0,
          }
        },
        {
          legend: 'Spur',
          type: 'line',
          minzoom: 10,
          properties: {
            highspeed: false,
            feature: 'rail',
            state: 'present',
            usage: null,
            service: 'spur',
            tunnel: false,
            bridge: false,
            ref: null,
            standard_label: null,
            track_ref: null,
            way_length: 1.0,
          }
        },
        {
          legend: 'Siding',
          type: 'line',
          minzoom: 10,
          properties: {
            highspeed: false,
            feature: 'rail',
            state: 'present',
            usage: null,
            service: 'siding',
            tunnel: false,
            bridge: false,
            ref: null,
            standard_label: null,
            track_ref: null,
            way_length: 1.0,
          }
        },
        {
          legend: 'Crossover',
          type: 'line',
          minzoom: 10,
          properties: {
            highspeed: false,
            feature: 'rail',
            state: 'present',
            usage: null,
            service: 'crossover',
            tunnel: false,
            bridge: false,
            ref: null,
            standard_label: null,
            track_ref: null,
            way_length: 1.0,
          }
        },
        {
          legend: 'Tourism (preserved)',
          type: 'line',
          minzoom: 9,
          properties: {
            highspeed: false,
            feature: 'rail',
            state: 'preserved',
            usage: 'tourism',
            service: null,
            tunnel: false,
            bridge: false,
            ref: 'T1',
            standard_label: 'T1 Name',
            track_ref: '8b',
            way_length: 1.0,
          }
        },
        {
          legend: 'Ferry',
          type: 'line',
          properties: {
            highspeed: false,
            feature: 'ferry',
            state: 'present',
            usage: 'main',
            service: null,
            tunnel: false,
            bridge: false,
            ref: 'F1',
            standard_label: 'F1 Ship',
            track_ref: null,
            way_length: 1.0,
          }
        },
        {
          legend: 'Under construction',
          type: 'line',
          minzoom: 10,
          properties: {
            highspeed: false,
            state: 'construction',
            feature: 'rail',
            usage: 'main',
            service: null,
            tunnel: false,
            bridge: false,
            ref: null,
            standard_label: null,
            track_ref: null,
            way_length: 1.0,
          },
          mapState: {
            showConstructionInfrastructure: true,
          },
        },
        {
          legend: 'Proposed railway',
          type: 'line',
          minzoom: 10,
          properties: {
            highspeed: false,
            state: 'proposed',
            feature: 'rail',
            usage: 'main',
            service: null,
            tunnel: false,
            bridge: false,
            ref: null,
            standard_label: null,
            track_ref: null,
            way_length: 1.0,
          },
          mapState: {
            showProposedInfrastructure: true,
          },
        },
        {
          legend: 'Disused railway',
          type: 'line',
          minzoom: 11,
          properties: {
            highspeed: false,
            state: 'disused',
            feature: 'rail',
            usage: 'main',
            service: null,
            tunnel: false,
            bridge: false,
            ref: null,
            standard_label: null,
            track_ref: null,
            way_length: 1.0,
          },
        },
        {
          legend: 'Abandoned railway',
          type: 'line',
          minzoom: 12,
          properties: {
            highspeed: false,
            state: 'abandoned',
            feature: 'rail',
            usage: 'main',
            service: null,
            tunnel: false,
            bridge: false,
            ref: null,
            standard_label: null,
            track_ref: null,
            way_length: 1.0,
          },
          mapState: {
            showAbandonedInfrastructure: true,
          },
        },
        {
          legend: 'Razed railway',
          type: 'line',
          minzoom: 12,
          properties: {
            highspeed: false,
            state: 'razed',
            feature: 'rail',
            usage: 'main',
            service: null,
            tunnel: false,
            bridge: false,
            ref: null,
            standard_label: null,
            track_ref: null,
            way_length: 1.0,
          },
          mapState: {
            showRazedInfrastructure: true,
          },
        },
      ],
    },
    'openhistoricalmap-transport_lines': {
      key: [
        'highspeed',
        'type',
        'state',
        'usage',
        'service',
      ],
      features: [
        {
          legend: 'Highspeed main line (historical)',
          type: 'line',
          minzoom: 5,
          properties: {
            type: 'rail',
            highspeed: 'yes',
            usage: 'main',
            service: null,
            tunnel: 0,
            bridge: 0,
            ref: 'H1',
            name: 'H1 Name',
          },
        },
        {
          legend: 'Main line (historical)',
          type: 'line',
          minzoom: 5,
          properties: {
            type: 'rail',
            highspeed: 'no',
            usage: 'main',
            service: null,
            tunnel: 0,
            bridge: 0,
            ref: 'M1',
            name: 'M1 Name',
          },
          variants: [
            {
              legend: 'bridge',
              properties: {
                bridge: 1,
                ref: null,
                name: null,
              },
            },
            {
              legend: 'tunnel',
              properties: {
                tunnel: 1,
                ref: null,
                name: null,
              },
            },
          ],
        },
        {
          legend: 'Branch line (historical)',
          type: 'line',
          minzoom: 7,
          properties: {
            type: 'rail',
            highspeed: 'no',
            usage: 'branch',
            service: null,
            tunnel: 0,
            bridge: 0,
            ref: 'B1',
            name: 'B1 Name',
          }
        },
        {
          legend: 'Industrial line (historical)',
          type: 'line',
          minzoom: 9,
          properties: {
            type: 'rail',
            highspeed: 'no',
            usage: 'industrial',
            service: null,
            tunnel: 0,
            bridge: 0,
            ref: 'I1',
            name: 'I1 Name',
          }
        },
        {
          legend: 'Narrow gauge line (historical)',
          type: 'line',
          minzoom: 10,
          properties: {
            type: 'narrow_gauge',
            highspeed: 'no',
            usage: null,
            service: null,
            tunnel: 0,
            bridge: 0,
            ref: 'N1',
            name: 'N1 Name',
          }
        },
        {
          legend: 'Subway (historical)',
          type: 'line',
          minzoom: 9,
          properties: {
            type: 'subway',
            highspeed: 'no',
            usage: null,
            service: null,
            tunnel: 0,
            bridge: 0,
            ref: 'S1',
            name: 'S1 Name',
          }
        },
        {
          legend: 'Light rail (historical)',
          type: 'line',
          minzoom: 9,
          properties: {
            type: 'light_rail',
            highspeed: 'no',
            usage: null,
            service: null,
            tunnel: 0,
            bridge: 0,
            ref: 'L1',
            name: 'L1 Name',
          }
        },
        {
          legend: 'Tram (historical)',
          type: 'line',
          minzoom: 9,
          properties: {
            type: 'tram',
            highspeed: 'no',
            usage: null,
            service: null,
            tunnel: 0,
            bridge: 0,
            ref: 'T1',
            name: 'T1 Name',
          }
        },
        {
          legend: 'Monorail (historical)',
          type: 'line',
          minzoom: 9,
          properties: {
            type: 'monorail',
            highspeed: 'no',
            usage: null,
            service: null,
            tunnel: 0,
            bridge: 0,
            ref: 'M1',
            name: 'M1 Name',
          }
        },
        {
          legend: 'Miniature railway (historical)',
          type: 'line',
          minzoom: 12,
          properties: {
            type: 'miniature',
            highspeed: 'no',
            usage: null,
            service: null,
            tunnel: 0,
            bridge: 0,
            ref: 'M3',
            name: 'N3 Name',
          }
        },
        {
          legend: 'Yard (historical)',
          type: 'line',
          minzoom: 10,
          properties: {
            type: 'rail',
            highspeed: 'no',
            usage: null,
            service: 'yard',
            tunnel: 0,
            bridge: 0,
            ref: null,
            name: null,
          }
        },
        {
          legend: 'Spur (historical)',
          type: 'line',
          minzoom: 10,
          properties: {
            type: 'rail',
            highspeed: 'no',
            usage: null,
            service: 'spur',
            tunnel: 0,
            bridge: 0,
            ref: null,
            name: null,
          }
        },
        {
          legend: 'Siding (historical)',
          type: 'line',
          minzoom: 10,
          properties: {
            type: 'rail',
            highspeed: 'no',
            usage: null,
            service: 'siding',
            tunnel: 0,
            bridge: 0,
            ref: null,
            name: null,
          }
        },
        {
          legend: 'Crossover (historical)',
          type: 'line',
          minzoom: 10,
          properties: {
            type: 'rail',
            highspeed: 'no',
            usage: null,
            service: 'crossover',
            tunnel: 0,
            bridge: 0,
            ref: null,
            name: null,
          }
        },
        {
          legend: 'Tourism (preserved) (historical)',
          type: 'line',
          minzoom: 9,
          properties: {
            type: 'preserved',
            highspeed: 'no',
            usage: null,
            service: null,
            tunnel: 0,
            bridge: 0,
            ref: 'P1',
            name: 'P1 Name',
          }
        },
        {
          legend: 'Test railway (historical)',
          type: 'line',
          minzoom: 9,
          properties: {
            type: 'rail',
            highspeed: 'no',
            usage: 'test',
            service: null,
            tunnel: 0,
            bridge: 0,
            ref: 'T1',
            name: 'T1 Name',
          }
        },
        {
          legend: 'Military railway (historical)',
          type: 'line',
          minzoom: 9,
          properties: {
            type: 'rail',
            highspeed: 'no',
            usage: 'military',
            service: null,
            tunnel: 0,
            bridge: 0,
            ref: 'M2',
            name: 'M2 Name',
          }
        },
        {
          legend: 'Under construction (historical)',
          type: 'line',
          minzoom: 10,
          properties: {
            type: 'construction',
            highspeed: 'no',
            usage: null,
            service: null,
            tunnel: 0,
            bridge: 0,
            ref: 'C1',
            name: 'C1 Name',
          }
        },
        {
          legend: 'Proposed railway (historical)',
          type: 'line',
          minzoom: 10,
          properties: {
            type: 'proposed',
            highspeed: 'no',
            usage: null,
            service: null,
            tunnel: 0,
            bridge: 0,
            ref: 'P1',
            name: 'P1 Name',
          }
        },
        {
          legend: 'Disused railway (historical)',
          type: 'line',
          minzoom: 11,
          properties: {
            type: 'disused',
            highspeed: 'no',
            usage: null,
            service: null,
            tunnel: 0,
            bridge: 0,
            ref: 'D1',
            name: 'D1 Name',
          }
        },
        {
          legend: 'Abandoned railway (historical)',
          type: 'line',
          minzoom: 11,
          properties: {
            type: 'abandoned',
            highspeed: 'no',
            usage: null,
            service: null,
            tunnel: 0,
            bridge: 0,
            ref: 'A1',
            name: 'A1 Name',
          }
        },
      ],
    },
    'standard_railway_text_stations_low-standard_railway_text_stations_low': {
      key: [
        'railway',
        'state',
      ],
      features: stations.features
        .filter(feature => feature.feature === 'station')
        .map(feature => ({
          legend: feature.description,
          type: 'point',
          minzoom: feature.minzoom,
          properties: {
            ...feature.example,
            railway: feature.feature,
          },
          variants: (feature.variants || []).map(variant => ({
            legend: variant.description,
            properties: variant.example,
            mapState: variant.mapState,
          })),
          mapState: feature.mapState,
        })),
    },
    "standard_railway_text_stations_med-standard_railway_text_stations_med": {
      key: [
        'railway',
        'state',
      ],
      features: stations.features
        .filter(feature => feature.feature === 'station')
        .map(feature => ({
          legend: feature.description,
          type: 'point',
          minzoom: feature.minzoom,
          properties: {
            ...feature.example,
            railway: feature.feature,
          },
          variants: (feature.variants || []).map(variant => ({
            legend: variant.description,
            properties: variant.example,
            mapState: variant.mapState,
          })),
          mapState: feature.mapState,
        })),
    },
    "openrailwaymap_standard-standard_railway_text_stations": {
      key: [
        'railway',
        'state',
      ],
      features: stations.features.flatMap(feature => [
        {
          legend: feature.description,
          type: 'point',
          minzoom: feature.minzoom,
          properties: {
            ...feature.example,
            railway: feature.feature,
          },
          mapState: feature.mapState,
        },
        ...(feature.variants || []).map(variant => ({
          legend: `${feature.description}: ${variant.description}`,
          type: 'point',
          minzoom: variant.minzoom ?? feature.minzoom,
          properties: {
            ...feature.example,
            ...variant.example,
          },
          mapState: variant.mapState,
        })),
      ]),
    },
    'openhistoricalmap-transport_points_centroids': {
      key: [
        'type',
      ],
      features: [
        {
          legend: 'Station (historical)',
          properties: {
            class: 'railway',
            type: 'station',
          },
        },
      ],
    },
    'openhistoricalmap-landuse_areas': {
      key: [
        'type',
      ],
      features: [
        {
          legend: 'Railway landuse',
          type: 'polygon',
          properties: {
            class: 'landuse',
            type: 'railway',
          },
        },
      ],
    },
    "openrailwaymap_standard-standard_railway_grouped_stations": {
      key: [],
      features: [],
    },
    "openrailwaymap_standard-standard_railway_grouped_station_areas": {
      key: [],
      features: [],
    },
    "openrailwaymap_standard-standard_railway_turntables": {
      key: [
        'feature',
      ],
      features: [
        {
          legend: 'Turntable',
          type: 'polygon',
          properties: {
            feature: 'turntable'
          },
          variants: [
            {
              legend: 'Transfer table',
              properties: {
                feature: 'traverser',
              }
            }
          ]
        },
      ],
    },
    "openrailwaymap_standard-standard_station_entrances": {
      key: [],
      features: [
        {
          legend: 'Subway entrance',
          type: 'point',
        },
      ],
    },
    "openrailwaymap_standard-standard_railway_platforms": {
      key: [],
      features: [
        {
          legend: 'Platform',
          type: 'polygon',
          properties: {
            ref: 1,
          },
        },
      ],
    },
    "openrailwaymap_standard-standard_railway_platform_edges": {
      key: [],
      features: [
        {
          legend: 'Platform edge',
          type: 'line',
          properties: {
            ref: 3,
          },
        },
      ],
    },
    "openrailwaymap_standard-standard_railway_stop_positions": {
      key: [
        'type',
      ],
      features: [
        {
          legend: 'Stop position',
          type: 'point',
          properties: {
            type: 'train',
          },
          variants: [
            {
              legend: 'light rail',
              properties: {
                type: 'light_rail',
              },
            },
            {
              legend: 'Tram',
              properties: {
                type: 'tram',
              },
            },
            {
              legend: 'Subway',
              properties: {
                type: 'Subway',
              },
            },
            {
              legend: 'funicular',
              properties: {
                type: 'funicular',
              },
            },
            {
              legend: 'monorail',
              properties: {
                type: 'monorail',
              },
            },
            {
              legend: 'miniature',
              properties: {
                type: 'miniature',
              },
            },
          ]
        },
      ],
    },
    "openrailwaymap_standard-standard_railway_symbols": {
      key: [
        'feature',
      ],
      features: poi.features
        .filter(feature => feature.layer === 'standard')
        .map(feature => ({
          legend: feature.description,
          type: 'point',
          minzoom: feature.minzoom,
          properties: {
            feature: feature.feature,
          },
          variants: feature.variants ? feature.variants.map(variant => ({
            legend: variant.description,
            properties: {
              feature: variant.feature,
            },
          })) : undefined,
        })),
    },
    "high-railway_text_km": {
      key: [],
      features: [
        {
          legend: 'Milestone',
          type: 'point',
          properties: {
            zero: true,
            pos_int: '47',
            pos: '47.0',
            pos_exact: '47.012',
            type: 'km',
          },
        },
      ],
    },
    "openrailwaymap_standard-standard_railway_switch_ref": {
      key: [
        'railway',
        'type',
      ],
      features: [
        {
          legend: 'Switch',
          type: 'point',
          properties: {
            railway: 'switch',
            ref: '3A',
            type: 'default',
            turnout_side: null,
            local_operated: false,
            resetting: false,
          },
          variants: [
            {
              legend: '(locally operated)',
              type: 'point',
              properties: {
                ref: null,
                local_operated: true,
              },
            },
            {
              legend: '(left sided)',
              type: 'point',
              properties: {
                ref: null,
                turnout_side: 'left',
              },
            },
            {
              legend: '(right sided)',
              type: 'point',
              properties: {
                ref: null,
                turnout_side: 'right',
              },
            },
          ],
        },
        {
          legend: 'Wye switch',
          type: 'point',
          properties: {
            railway: 'switch',
            ref: null,
            type: 'wye',
            turnout_side: null,
            local_operated: false,
            resetting: false,
          },
          variants: [
            {
              legend: '(locally operated)',
              type: 'point',
              properties: {
                local_operated: true,
              },
            },
          ],
        },
        {
          legend: 'Three-way switch',
          type: 'point',
          properties: {
            railway: 'switch',
            ref: null,
            type: 'three_way',
            turnout_side: null,
            local_operated: false,
            resetting: false,
          },
          variants: [
            {
              legend: '(locally operated)',
              type: 'point',
              properties: {
                local_operated: true,
              },
            },
          ],
        },
        {
          legend: 'Four-way switch',
          type: 'point',
          properties: {
            railway: 'switch',
            ref: null,
            type: 'four_way',
            turnout_side: null,
            local_operated: false,
            resetting: false,
          },
          variants: [
            {
              legend: '(locally operated)',
              type: 'point',
              properties: {
                local_operated: true,
              },
            },
          ],
        },
        {
          legend: 'Abt switch',
          type: 'point',
          properties: {
            railway: 'switch',
            ref: null,
            type: 'abt',
            turnout_side: null,
            local_operated: false,
            resetting: false,
          },
          variants: [
            {
              legend: '(locally operated)',
              type: 'point',
              properties: {
                local_operated: true,
              },
            },
          ],
        },
        {
          legend: 'Single slip switch',
          type: 'point',
          properties: {
            railway: 'switch',
            ref: null,
            type: 'single_slip',
            turnout_side: null,
            local_operated: false,
            resetting: false,
          },
          variants: [
            {
              legend: '(locally operated)',
              type: 'point',
              properties: {
                local_operated: true,
              },
            },
          ],
        },
        {
          legend: 'Double slip switch',
          type: 'point',
          properties: {
            railway: 'switch',
            ref: null,
            type: 'double_slip',
            turnout_side: null,
            local_operated: false,
            resetting: false,
          },
          variants: [
            {
              legend: '(locally operated)',
              type: 'point',
              properties: {
                local_operated: true,
              },
            },
          ],
        },
        {
          legend: 'Railway crossing',
          type: 'point',
          properties: {
            railway: 'railway_crossing',
            ref: null,
            type: null,
            turnout_side: null,
            local_operated: false,
            resetting: false,
          },
        },
      ],
    },
  },

  speed: {
    countries: [...new Set(speed_railway_signals.map(feature => feature.country).filter(it => it))].toSorted(),

    'speed_railway_line_low-speed_railway_line_low': {
      key: [],
      features: [
        ...speedLegends.map(speed => ({
          legend: `${speed} km/h`,
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            tunnel: false,
            bridge: false,
            maxspeed: speed,
          },
        })),
        {
          legend: '(unknown)',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            tunnel: false,
            bridge: false,
            maxspeed: null,
          },
        },
      ],
    },
    'openrailwaymap_low-railway_line_high': {
      key: [],
      features: [
        ...speedLegends.map(speed => ({
          legend: `${speed} km/h`,
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            tunnel: false,
            bridge: false,
            maxspeed: speed,
          },
        })),
        {
          legend: '(unknown)',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            tunnel: false,
            bridge: false,
            maxspeed: null,
          },
        },
      ],
    },
    'high-railway_line_high': {
      key: [],
      features: [
        ...speedLegends.map(speed => ({
          legend: `${speed} km/h`,
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            maxspeed: speed,
            tunnel: false,
            bridge: false,
            speed_label: `${speed}`,
          },
        })),
        {
          legend: '(unknown)',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            maxspeed: null,
            tunnel: false,
            bridge: false,
            speed_label: '',
          },
        },
      ],
    },
    "high-railway_text_km": {
      key: [],
      features: [
        {
          legend: 'Milestone',
          type: 'point',
          properties: {
            zero: true,
            pos_int: '47',
            pos: '47.0',
            pos_exact: '47.012',
            type: 'km',
          },
        },
      ],
    },
    'openrailwaymap_speed-speed_railway_signals': {
      key: [
        'feature0',
      ],
      matchKeys: [
        [
          'railway',
          'feature1',
        ],
      ],
      features: [
        ...speed_railway_signals.flatMap(feature =>
          signalFeatures(feature).map(iconFeature => ({
            legend: `${feature.description}${iconFeature.legend ? ` ${iconFeature.legend}` : ''}`,
            type: 'point',
            country: feature.country,
            properties: {
              feature0: iconFeature.icon,
              type: 'line',
              azimuth: null,
              deactivated0: false,
              direction_both: false,
            },
            variants: iconFeature.variants.map(variant => ({
              legend: variant.legend,
              properties: {
                feature0: variant.icon,
              },
            })),
          }))),
        {
          legend: 'signal direction',
          type: 'point',
          properties: {
            feature0: 'does-not-exist',
            type: 'line',
            azimuth: 135.5,
            deactivated0: false,
            direction_both: false,
          },
          variants: [
            {
              legend: '(both)',
              properties: {
                direction_both: true,
              },
            },
          ],
        },
        {
          legend: '(deactivated)',
          type: 'point',
          properties: {
            feature0: 'pl/w21-{40}',
            type: 'line',
            azimuth: null,
            deactivated0: true,
            direction_both: false,
          },
        },
        ...signal_types.filter(type => type.layer === 'speed').map(type => ({
          legend: `unknown signal (${type.type})`,
          type: 'point',
          properties: {
            feature0: `general/signal-unknown-${type.type}`,
            type: 'line',
            azimuth: null,
            deactivated0: false,
            direction_both: false,
          },
        })),
      ],
    },
  },

  signals: {
    countries: [...new Set(signals_railway_signals.map(feature => feature.country).filter(it => it))].toSorted(),

    'signals_railway_line_low-signals_railway_line_low': {
      key: [
        'feature',
        'state',
        'train_protection',
        'train_protection_construction',
      ],
      features: [
        ...signals_railway_line.train_protections.map(train_protection => ({
          legend: train_protection.legend,
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            train_protection: train_protection.train_protection,
            train_protection_rank: 1,
            train_protection_construction: null,
            train_protection_construction_rank: 0,
          },
          variants: [
            {
              properties: {
                train_protection: null,
                train_protection_rank: 0,
                train_protection_construction: train_protection.train_protection,
                train_protection_construction_rank: 1,
              }
            }
          ],
        })),
        {
          legend: '(unknown)',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            train_protection: null,
            train_protection_rank: 0,
            train_protection_construction: null,
            train_protection_construction_rank: 0,
          },
        },
      ]
    },
    'openrailwaymap_low-railway_line_high': {
      key: [
        'feature',
        'state',
        'train_protection',
        'train_protection_construction',
      ],
      features: [
        ...signals_railway_line.train_protections.map(train_protection => ({
          legend: train_protection.legend,
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            train_protection: train_protection.train_protection,
            train_protection_rank: 1,
            train_protection_construction: null,
            train_protection_construction_rank: 0,
          },
          variants: [
            {
              properties: {
                train_protection: null,
                train_protection_rank: 0,
                train_protection_construction: train_protection.train_protection,
                train_protection_construction_rank: 1,
              }
            }
          ],
        })),
        {
          legend: '(unknown)',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            train_protection: null,
            train_protection_rank: 0,
            train_protection_construction: null,
            train_protection_construction_rank: 0,
          },
        },
      ],
    },
    'high-railway_line_high': {
      key: [
        'feature',
        'state',
        'train_protection',
        'train_protection_construction',
      ],
      features: [
        ...signals_railway_line.train_protections.map(train_protection => ({
          legend: train_protection.legend,
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            train_protection: train_protection.train_protection,
            train_protection_rank: 1,
            train_protection_construction: null,
            train_protection_construction_rank: 0,
          },
          variants: [
            {
              properties: {
                train_protection: null,
                train_protection_rank: 0,
                train_protection_construction: train_protection.train_protection,
                train_protection_construction_rank: 1,
              }
            }
          ],
        })),
        {
          legend: '(unknown)',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            train_protection: null,
            train_protection_rank: 0,
            train_protection_construction: null,
            train_protection_construction_rank: 0,
          },
        },
        {
          legend: 'Under construction',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'construction',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            train_protection: 'etcs',
            train_protection_rank: 1,
            train_protection_construction: null,
            train_protection_construction_rank: 0,
          },
        },
        {
          legend: 'Proposed',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'proposed',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            train_protection: 'etcs',
            train_protection_rank: 1,
            train_protection_construction: null,
            train_protection_construction_rank: 0,
          },
        },
      ],
    },
    'openrailwaymap_signals-signals_signal_boxes': {
      key: [
        'feature',
      ],
      features: [
        {
          legend: 'Signal box',
          type: 'point',
          properties: {
            ref: 'Rtd',
            name: 'Rotterdam',
            feature: 'signal_box',
          },
          variants: [
            {
              legend: 'crossing box',
              properties: {
                ref: 'Crs',
                name: 'Cross',
                feature: 'crossing_box',
              },
            },
            {
              legend: 'block post',
              properties: {
                ref: 'Blk',
                name: 'KM 47',
                feature: 'blockpost',
              },
            },
          ],
        },
      ],
    },
    "high-railway_text_km": {
      key: [],
      features: [
        {
          legend: 'Milestone',
          type: 'point',
          properties: {
            zero: true,
            pos_int: '47',
            pos: '47.0',
            pos_exact: '47.012',
            type: 'km',
          },
        },
      ],
    },
    'openrailwaymap_signals-signals_railway_signals': {
      key: [
        'railway',
        'feature0',
      ],
      matchKeys: [
        [
          'railway',
          'feature1',
        ],
        [
          'railway',
          'feature2',
        ],
        [
          'railway',
          'feature3',
        ],
        [
          'railway',
          'feature4',
        ],
      ],
      features: [
        ...signals_railway_signals.flatMap(feature =>
          signalFeatures(feature).map(iconFeature => ({
            legend: `${feature.description}${iconFeature.legend ? ` ${iconFeature.legend}` : ''}`,
            type: 'point',
            country: feature.country,
            properties: {
              feature0: iconFeature.icon,
              railway: 'signal',
              type: 'line',
              azimuth: null,
              deactivated0: false,
              direction_both: false,
            },
            variants: iconFeature.variants.map(variant => ({
              legend: variant.legend,
              properties: {
                feature0: variant.icon,
              },
            })),
          }))),
        {
          legend: 'signal direction',
          type: 'point',
          properties: {
            feature0: 'does-not-exist',
            railway: 'signal',
            type: 'line',
            azimuth: 135.5,
            deactivated0: false,
            direction_both: false,
          },
          variants: [
            {
              legend: '(both)',
              properties: {
                direction_both: true,
              },
            },
          ],
        },
        {
          legend: '(deactivated)',
          type: 'point',
          properties: {
            feature0: 'de/ks-combined',
            railway: 'signal',
            type: 'line',
            azimuth: null,
            deactivated0: true,
            direction_both: false,
          },
        },
        ...signal_types.filter(type => type.layer === 'signals').map(type => ({
          legend: `unknown signal (${type.type})`,
          type: 'point',
          properties: {
            feature0: `general/signal-unknown-${type.type}`,
            railway: 'signal',
            type: 'line',
            azimuth: null,
            deactivated0: false,
            direction_both: false,
          },
        })),
      ],
    },
  },

  electrification: {
    countries: [...new Set(electrification_signals.map(feature => feature.country).filter(it => it))].toSorted(),

    'electrification_railway_line_low-electrification_railway_line_low': {
      key: [],
      features: [
        ...electrificationLegends.voltageFrequency.map(({legend, voltage, frequency}) => ({
          legend,
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            electrification_state: 'present',
            voltage,
            frequency,
          },
          mapState: {
            electrificationRailwayLine: 'voltageFrequency',
          },
        })),
        ...electrificationLegends.maximumCurrent.map(({maximumCurrent}) => ({
          legend: `${maximumCurrent} A`,
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            electrification_state: 'present',
            maximum_current: maximumCurrent,
          },
          mapState: {
            electrificationRailwayLine: 'maximumCurrent',
          },
        })),
        ...electrificationLegends.power.map(({legend, maximumCurrent, voltage}) => ({
          legend,
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            electrification_state: 'present',
            voltage: voltage,
            maximum_current: maximumCurrent,
          },
          mapState: {
            electrificationRailwayLine: 'power',
          },
        })),
        {
          legend: 'Not electrified',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            electrification_state: 'no',
            voltage: null,
            frequency: null,
          },
        },
        {
          legend: 'De-electrified / abandoned railway',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            electrification_state: 'abandoned',
            voltage: null,
            frequency: null,
          },
        },
        {
          legend: '(unknown)',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            electrification_state: null,
            voltage: null,
            frequency: null,
          },
        },
      ],
    },
    'openrailwaymap_low-railway_line_high': {
      key: [],
      features: [
        ...electrificationLegends.voltageFrequency.map(({legend, voltage, frequency}) => ({
          legend,
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            electrification_state: 'present',
            voltage,
            frequency,
          },
          mapState: {
            electrificationRailwayLine: 'voltageFrequency',
          },
        })),
        ...electrificationLegends.maximumCurrent.map(({maximumCurrent}) => ({
          legend: `${maximumCurrent} A`,
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            electrification_state: 'present',
            maximum_current: maximumCurrent,
          },
          mapState: {
            electrificationRailwayLine: 'maximumCurrent',
          },
        })),
        ...electrificationLegends.power.map(({legend, maximumCurrent, voltage}) => ({
          legend,
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            electrification_state: 'present',
            voltage: voltage,
            maximum_current: maximumCurrent,
          },
          mapState: {
            electrificationRailwayLine: 'power',
          },
        })),
        {
          legend: 'Not electrified',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            electrification_state: 'no',
            voltage: null,
            frequency: null,
          },
        },
        {
          legend: 'De-electrified / abandoned railway',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            electrification_state: 'abandoned',
            voltage: null,
            frequency: null,
          },
        },
        {
          legend: '(unknown)',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            electrification_state: null,
            voltage: null,
            frequency: null,
          },
        },
      ],
    },
    'high-railway_line_high': {
      key: [],
      features: [
        ...electrificationLegends.voltageFrequency.map(({legend, voltage, frequency}) => ({
          legend,
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            electrification_state: 'present',
            voltage,
            frequency,
          },
          mapState: {
            electrificationRailwayLine: 'voltageFrequency',
          },
        })),
        ...electrificationLegends.maximumCurrent.map(({maximumCurrent}) => ({
          legend: `${maximumCurrent} A`,
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            electrification_state: 'present',
            maximum_current: maximumCurrent,
          },
          mapState: {
            electrificationRailwayLine: 'maximumCurrent',
          },
        })),
        ...electrificationLegends.power.map(({legend, maximumCurrent, voltage}) => ({
          legend,
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            electrification_state: 'present',
            voltage: voltage,
            maximum_current: maximumCurrent,
          },
          mapState: {
            electrificationRailwayLine: 'power',
          },
        })),
        {
          legend: 'Proposed electrification',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            electrification_state: 'proposed',
            voltage: null,
            frequency: null,
            future_voltage: 1500,
            future_frequency: 0,
            future_maximum_current: 1600,
            electrification_label: '',
          },
        },
        {
          legend: 'Electrification under construction',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            electrification_state: 'construction',
            voltage: null,
            frequency: null,
            future_voltage: 1500,
            future_frequency: 0,
            future_maximum_current: 1600,
            electrification_label: '',
          },
        },
        {
          legend: 'Not electrified',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            electrification_state: 'no',
            voltage: null,
            frequency: null,
            electrification_label: '',
          },
        },
        {
          legend: 'De-electrified / abandoned railway',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            electrification_state: 'abandoned',
            voltage: null,
            frequency: null,
            electrification_label: '',
          },
        },
        {
          legend: '(unknown)',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            electrification_state: null,
            voltage: null,
            frequency: null,
            electrification_label: '',
          },
        },
      ]
    },
    "high-railway_text_km": {
      key: [],
      features: [
        {
          legend: 'Milestone',
          type: 'point',
          properties: {
            zero: true,
            pos_int: '47',
            pos: '47.0',
            pos_exact: '47.012',
            type: 'km',
          },
        },
      ],
    },
    'openrailwaymap_electrification-electrification_signals': {
      key: [
        'feature',
      ],
      features: [
        ...electrification_signals.flatMap(feature =>
          signalFeatures(feature).map(iconFeature => ({
            legend: `${feature.description}${iconFeature.legend ? ` ${iconFeature.legend}` : ''}`,
            type: 'point',
            country: feature.country,
            properties: {
              feature: iconFeature.icon,
              type: 'line',
              azimuth: null,
              deactivated: false,
              direction_both: false,
            },
            variants: iconFeature.variants.map(variant => ({
              legend: variant.legend,
              properties: {
                feature: variant.icon,
              },
            })),
          }))),
        {
          legend: 'signal direction',
          type: 'point',
          properties: {
            feature: 'does-not-exist',
            type: 'line',
            azimuth: 135.5,
            deactivated: false,
            direction_both: false,
          },
          variants: [
            {
              legend: '(both)',
              properties: {
                direction_both: true,
              },
            },
          ],
        },
        {
          legend: '(deactivated)',
          type: 'point',
          properties: {
            feature: 'de/el6',
            type: 'line',
            azimuth: null,
            deactivated: true,
            direction_both: false,
          },
        },
        ...signal_types.filter(type => type.layer === 'electrification').map(type => ({
          legend: `unknown signal (${type.type})`,
          type: 'point',
          properties: {
            feature: `general/signal-unknown-${type.type}`,
            type: 'line',
            azimuth: null,
            deactivated: false,
            direction_both: false,
          },
        })),
      ],
    },
    "openrailwaymap_electrification-electrification_railway_symbols": {
      key: [
        'feature',
      ],
      features: poi.features
        .filter(feature => feature.layer === 'electrification')
        .map(feature => ({
          legend: feature.description,
          type: 'point',
          minzoom: feature.minzoom,
          properties: {
            feature: feature.feature,
          },
          variants: feature.variants ? feature.variants.map(variant => ({
            legend: variant.description,
            properties: {
              feature: variant.feature,
            },
          })) : undefined,
        })),
    },
    "openrailwaymap_electrification-electrification_catenary": {
      key: [
        'feature',
      ],
      features: [
        {
          legend: 'Catenary mast',
          type: 'point',
          properties: {
            feature: 'mast',
            transition: false,
          },
          variants: [
            {
              legend: '(transition)',
              properties: {
                transition: true,
              }
            }
          ]
        },
        {
          legend: 'Catenary portal',
          type: 'line',
          properties: {
            feature: 'portal',
          },
        },
      ],
    },
    "openrailwaymap_electrification-electrification_substation": {
      key: [
        'feature',
      ],
      features: [
        {
          legend: 'Traction substation',
          type: 'polygon',
          properties: {
            feature: 'traction',
          }
        }
      ],
    },
  },

  track: {
    countries: [],

    'track_railway_line_low-track_railway_line_low': {
      key: [],
      features: [
        ...gaugeLegends.map(({min, legend}) => ({
          legend,
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            gauge0: `${min}`,
            gaugeint0: min,
            label: `${min}`,
          },
          mapState: {
            trackRailwayLine: 'gauge',
          },
        })),
        {
          legend: 'Monorail',
          type: 'line',
          properties: {
            feature: 'monorail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            gauge0: 'monorail',
            gaugeint0: null,
          },
          mapState: {
            trackRailwayLine: 'gauge',
          },
        },
        {
          legend: 'Narrow',
          type: 'line',
          properties: {
            feature: 'narrow_gauge',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            gauge0: 'standard',
            gaugeint0: null,
          },
          variants: [
            {
              type: 'line',
              properties: {
                feature: 'rail',
                gauge0: 'narrow',
              },
            },
          ],
          mapState: {
            trackRailwayLine: 'gauge',
          },
        },
        {
          legend: 'Broad',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            gauge0: 'broad',
            gaugeint0: null,
          },
          mapState: {
            trackRailwayLine: 'gauge',
          },
        },
        {
          legend: 'Standard',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            gauge0: 'standard',
            gaugeint0: null,
          },
          mapState: {
            trackRailwayLine: 'gauge',
          },
        },
        ...loading_gauges.loading_gauges.map(loading_gauge => ({
          legend: loading_gauge.legend,
          type: 'line',
          properties: {
            loading_gauge: loading_gauge.value,
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
          },
          mapState: {
            trackRailwayLine: 'loadingGauge',
          },
        })),
        ...track_classes.track_classes.map(track_class => ({
          legend: track_class.value,
          type: 'line',
          properties: {
            track_class: track_class.value,
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
          },
          mapState: {
            trackRailwayLine: 'trackClass',
          },
        })),
        {
          legend: '(unknown)',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            gauge0: '3500',
            gaugeint0: 3500,
            label: '3500',
            loading_gauge: null,
            track_class: null,
          },
        },
      ],
    },
    'openrailwaymap_low-railway_line_high': {
      key: [],
      features: [
        ...gaugeLegends.map(({min, legend}) => ({
          legend,
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            gauge0: `${min}`,
            gaugeint0: min,
            label: `${min}`,
          },
          mapState: {
            trackRailwayLine: 'gauge',
          },
        })),
        {
          legend: 'Monorail',
          type: 'line',
          properties: {
            feature: 'monorail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            gauge0: 'monorail',
            gaugeint0: null,
          },
          mapState: {
            trackRailwayLine: 'gauge',
          },
        },
        {
          legend: 'Narrow',
          type: 'line',
          properties: {
            feature: 'narrow_gauge',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            gauge0: 'standard',
            gaugeint0: null,
          },
          variants: [
            {
              type: 'line',
              properties: {
                feature: 'rail',
                gauge0: 'narrow',
              },
            },
          ],
          mapState: {
            trackRailwayLine: 'gauge',
          },
        },
        {
          legend: 'Broad',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            gauge0: 'broad',
            gaugeint0: null,
          },
          mapState: {
            trackRailwayLine: 'gauge',
          },
        },
        {
          legend: 'Standard',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            gauge0: 'standard',
            gaugeint0: null,
          },
          mapState: {
            trackRailwayLine: 'gauge',
          },
        },
        ...loading_gauges.loading_gauges.map(loading_gauge => ({
          legend: loading_gauge.legend,
          type: 'line',
          properties: {
            loading_gauge: loading_gauge.value,
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
          },
          mapState: {
            trackRailwayLine: 'loadingGauge',
          },
        })),
        ...track_classes.track_classes.map(track_class => ({
          legend: track_class.value,
          type: 'line',
          properties: {
            track_class: track_class.value,
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
          },
          mapState: {
            trackRailwayLine: 'trackClass',
          },
        })),
        {
          legend: '(unknown)',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            gauge0: '3500',
            gaugeint0: 3500,
            label: '3500',
            loading_gauge: null,
            track_class: null,
          },
        },
      ],
    },
    'high-railway_line_high': {
      key: [],
      features: [
        ...gaugeLegends.map(({min, legend}) => ({
          legend,
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            gauge0: `${min}`,
            gaugeint0: min,
            gauge_label: `${min}`,
          },
          mapState: {
            trackRailwayLine: 'gauge',
          },
        })),
        {
          legend: 'Monorail',
          type: 'line',
          properties: {
            feature: 'monorail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            gauge0: 'monorail',
            gaugeint0: null,
          },
          mapState: {
            trackRailwayLine: 'gauge',
          },
        },
        {
          legend: 'Narrow',
          type: 'line',
          properties: {
            feature: 'narrow_gauge',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            gauge0: 'standard',
            gaugeint0: null,
          },
          variants: [
            {
              type: 'line',
              properties: {
                feature: 'rail',
                gauge0: 'narrow',
              },
            },
          ],
          mapState: {
            trackRailwayLine: 'gauge',
          },
        },
        {
          legend: 'Broad',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            gauge0: 'broad',
            gaugeint0: null,
          },
          mapState: {
            trackRailwayLine: 'gauge',
          },
        },
        {
          legend: 'Miniature',
          type: 'line',
          properties: {
            feature: 'miniature',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            gauge0: 'standard',
            gaugeint0: null,
          },
          mapState: {
            trackRailwayLine: 'gauge',
          },
        },
        {
          legend: 'Standard',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            gauge0: 'standard',
            gaugeint0: null,
          },
          mapState: {
            trackRailwayLine: 'gauge',
          },
        },
        {
          legend: 'Dual gauge',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            gauge0: '1435',
            gaugeint0: 1435,
            gauge1: '1520',
            gaugeint1: 1520,
            gauge_label: '',
          },
          mapState: {
            trackRailwayLine: 'gauge',
          },
        },
        {
          legend: 'Multi gauge',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            gauge0: '1435',
            gaugeint0: 1435,
            gauge1: '1520',
            gaugeint1: 1520,
            gauge2: '1600',
            gaugeint2: 1600,
            gauge_label: '',
          },
          mapState: {
            trackRailwayLine: 'gauge',
          },
        },
        {
          legend: 'Under construction',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'construction',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            gauge0: '1435',
            gaugeint0: 1435,
            gauge_label: '',
          },
          mapState: {
            trackRailwayLine: 'gauge',
          },
        },
        {
          legend: 'Dual gauge under construction',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'construction',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            gauge0: '1435',
            gaugeint0: 1435,
            gauge1: '1520',
            gaugeint1: 1520,
            gauge_label: '',
          },
          mapState: {
            trackRailwayLine: 'gauge',
          },
        },
        {
          legend: 'Multi gauge under construction',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'construction',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            gauge0: '1435',
            gaugeint0: 1435,
            gauge1: '1520',
            gaugeint1: 1520,
            gauge2: '1600',
            gaugeint2: 1600,
            gauge_label: '',
          },
          mapState: {
            trackRailwayLine: 'gauge',
          },
        },
        ...loading_gauges.loading_gauges.map(loading_gauge => ({
          legend: loading_gauge.legend,
          type: 'line',
          properties: {
            loading_gauge: loading_gauge.value,
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
          },
          mapState: {
            trackRailwayLine: 'loadingGauge',
          },
        })),
        ...track_classes.track_classes.map(track_class => ({
          legend: track_class.value,
          type: 'line',
          properties: {
            track_class: track_class.value,
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
          },
          mapState: {
            trackRailwayLine: 'trackClass',
          },
        })),
        {
          legend: '(unknown)',
          type: 'line',
          properties: {
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
            gauge0: '3500',
            gaugeint0: 3500,
            gauge_label: '3500',
            loading_gauge: null,
            track_class: null,
          },
        },
      ],
    },
    "high-railway_text_km": {
      key: [],
      features: [
        {
          legend: 'Milestone',
          type: 'point',
          properties: {
            zero: true,
            pos_int: '47',
            pos: '47.0',
            pos_exact: '47.012',
            type: 'km',
          },
        },
      ],
    },
  },

  operator: {
    countries: [...new Set(operators.operators.map(operator => operator.country).filter(it => it))].toSorted(),

    'operator_railway_line_low-operator_railway_line_low': {
      key: [
        'operator',
      ],
      features: [
        ...operators.operators.map(operator => ({
          legend: operator.names.join(', '),
          type: 'line',
          country: operator.country,
          properties: {
            operator: operator.names[0],
            primary_operator: operator.names[0],
            operator_color: operator.color,
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
          },
        })),
        {
          legend: '(unknown)',
          type: 'line',
          properties: {
            operator: null,
            primary_operator: null,
            operator_color: null,
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
          },
        },
      ],
    },
    'openrailwaymap_low-railway_line_high': {
      key: [
        'operator',
      ],
      features: [
        ...operators.operators.map(operator => ({
          legend: operator.names.join(', '),
          type: 'line',
          country: operator.country,
          properties: {
            operator: operator.names[0],
            primary_operator: operator.names[0],
            operator_color: operator.color,
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
          },
        })),
        {
          legend: '(unknown)',
          type: 'line',
          properties: {
            operator: null,
            primary_operator: null,
            operator_color: null,
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
          },
        },
      ],
    },
    'high-railway_line_high': {
      key: [
        'operator',
      ],
      features: [
        ...operators.operators.map(operator => ({
          legend: operator.names.join(', '),
          type: 'line',
          country: operator.country,
          properties: {
            operator: operator.names[0],
            primary_operator: operator.names[0],
            operator_color: operator.color,
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
          },
        })),
        {
          legend: '(unknown)',
          type: 'line',
          properties: {
            operator: null,
            primary_operator: null,
            operator_color: null,
            feature: 'rail',
            state: 'present',
            usage: 'main',
            service: null,
            bridge: false,
            tunnel: false,
          },
        },
      ],
    },
    "high-railway_text_km": {
      key: [],
      features: [
        {
          legend: 'Milestone',
          type: 'point',
          properties: {
            zero: true,
            pos_int: '47',
            pos: '47.0',
            pos_exact: '47.012',
            type: 'km',
          },
        },
      ],
    },
    "openrailwaymap_operator-operator_railway_symbols": {
      key: [
        'feature',
      ],
      features: poi.features
        .filter(feature => feature.layer === 'operator')
        .map(feature => ({
          legend: feature.description,
          type: 'point',
          minzoom: feature.minzoom,
          properties: {
            feature: feature.feature,
          },
          variants: feature.variants ? feature.variants.map(variant => ({
            legend: variant.description,
            properties: {
              feature: variant.feature,
            },
          })) : undefined,
        })),
    },
  },

  route: {
    countries: [],
  },
}

// Generate legend keys
const legendDataWithKeys = Object.fromEntries(
  Object.entries(legendData)
    .map(([style, {countries, ...rest}]) => [style, {
      countries,
      ...Object.fromEntries(
        Object.entries(rest)
          .map(([sourceLayer, {key, features}]) => [sourceLayer, {
            key,
            features: features.map(item => {
              const itemFeatures = [item, ...(item.variants ?? []).map(subItem => ({...item, ...subItem, properties: {...item.properties, ...subItem.properties}}))]
              const itemFeatureKeys = itemFeatures.map(itemFeature => key.map(keyPart => String(itemFeature.properties[keyPart] ?? '').replace(/\{[^}]+}/, '{}').replace(/@([^|]+|$)/g, '')).join('\u001e'));
              return {
                ...item,
                keys: itemFeatureKeys.toSorted(),
              }
            }),
          }])
      ),
    }])
)

console.log(JSON.stringify(legendDataWithKeys));
