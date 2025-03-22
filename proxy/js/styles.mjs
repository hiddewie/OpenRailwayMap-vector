import fs from 'fs'
import yaml from 'yaml'

const signals_railway_line = yaml.parse(fs.readFileSync('features/train_protection.yaml', 'utf8'))
const all_signals = yaml.parse(fs.readFileSync('features/signals_railway_signals.yaml', 'utf8'))
const loading_gauges = yaml.parse(fs.readFileSync('features/loading_gauge.yaml', 'utf8'))
const track_classes = yaml.parse(fs.readFileSync('features/track_class.yaml', 'utf8'))
const poi = yaml.parse(fs.readFileSync('features/poi.yaml', 'utf8'))
const stations = yaml.parse(fs.readFileSync('features/stations.yaml', 'utf8'))

const signal_types = all_signals.types;

const speed_railway_signals = all_signals.features.filter(feature => feature.tags.find(tag => tag.tag === 'railway:signal:speed_limit' || tag.tag === 'railway:signal:speed_limit_distant'))
const signals_railway_signals = all_signals.features.filter(feature => !feature.tags.find(tag => tag.tag === 'railway:signal:speed_limit' || tag.tag === 'railway:signal:speed_limit_distant' || tag.tag === 'railway:signal:electricity'))
const electrification_signals = all_signals.features.filter(feature => feature.tags.find(tag => tag.tag === 'railway:signal:electricity'))

const origin = `${process.env.PUBLIC_PROTOCOL}://${process.env.PUBLIC_HOST}`

const knownStyles = [
  'standard',
  'speed',
  'signals',
  'electrification',
  'gauge',
  'loading_gauge',
  'track_class',
];
const knownThemes = [
  'light',
  'dark',
];

const globalMinZoom = 1;
const globalMaxZoom = 20;

const colors = {
  light: {
    text: {
      main: 'black',
      halo: 'white',
    },
    halo: 'white',
    casing: 'white',
    hover: {
      main: '#ff0000',
      // High speed lines and 25kV are the hover color by default
      alternative: '#ffc107',
      textHalo: 'yellow',
    },
    railwayLine: {
      text: '#585858',
    },
    styles: {
      standard: {
        main: '#ff8100',
        highspeed: '#ff0c00',
        branch: '#c4b600',
        narrowGauge: '#c0da00',
        no_usage: '#000000',
        disused: '#70584d',
        tourism: '#5b4d70',
        military: '#764765',
        test: '#3d634e',
        abandoned: '#7f6a62',
        razed: '#94847e',
        tram: '#d877b8',
        subway: '#0300c3',
        light_rail: '#00bd14',
        monorail: '#00bd8b',
        miniature: '#7d7094',
        siding: '#000000',
        crossover: '#000000',
        yard: '#000000',
        spur: '#87491d',
        industrial: '#87491d',
        unknown: '#000000',
        casing: {
          railway: '#ffffff',
          bridge: '#000000',
        },
        tunnelCover: 'rgba(255, 255, 255, 50%)',
        turntable: {
          fill: '#ababab',
          casing: '#808080',
        },
        stationsText: 'blue',
        yardText: '#87491D',
        tramStopText: '#D877B8',
        lightRailText: '#0e5414',
        monorailText: '#00674d',
        miniatureText: '#503285',
        defaultText: '#616161',
        signalBox: {
          text: '#404040',
          halo: '#bfffb3',
        },
        track: {
          text: 'white',
          halo: 'blue',
          hover: 'yellow',
        },
        switch: {
          text: 'black',
          halo: 'white',
          localOperated: 'yellow',
          hover: '#ff9361',
        },
      },
    },
    km: {
      text: 'hsl(268, 100%, 40%)'
    },
    signals: {
      direction: '#a8d8bcff'
    },
  },
  dark: {
    text: {
      main: 'white',
      halo: 'black',
    },
    halo: '#333',
    casing: '#666',
    hover: {
      main: '#ff0000',
      // High speed lines and 25kV are the hover color by default
      alternative: '#ffc107',
      textHalo: '#362800',
    },
    railwayLine: {
      text: '#ccc',
    },
    styles: {
      standard: {
        main: '#ff8100',
        highspeed: '#ff0c00',
        branch: '#c4b600',
        narrowGauge: '#c0da00',
        no_usage: '#000000',
        disused: '#70584d',
        tourism: '#5b4d70',
        military: '#764765',
        test: '#3d634e',
        abandoned: '#7f6a62',
        razed: '#94847e',
        tram: '#d877b8',
        subway: '#0300c3',
        light_rail: '#00bd14',
        monorail: '#00bd8b',
        miniature: '#7d7094',
        siding: '#000000',
        crossover: '#000000',
        yard: '#000000',
        spur: '#87491d',
        industrial: '#87491d',
        unknown: '#000000',
        casing: {
          railway: '#ffffff',
          bridge: '#ddd',
        },
        tunnelCover: 'rgba(0, 0, 0, 25%)',
        turntable: {
          fill: '#ababab',
          casing: '#808080',
        },
        trackHalo: '#00298d',
        stationsText: '#bdcfff',
        yardText: '#ffa35f',
        tramStopText: '#f3b4de',
        lightRailText: '#83ea8f',
        monorailText: '#5fffd7',
        miniatureText: '#503285',
        defaultText: '#d2d2d2',
        signalBox: {
          text: '#bfffb3',
          halo: '#404040',
        },
        track: {
          text: 'white',
          halo: '#00298d',
          hover: 'yellow',
        },
        switch: {
          text: 'black',
          halo: 'white',
          localOperated: 'yellow',
          hover: '#ff9361',
        },
      },
    },
    km: {
      text: 'hsl(268, 5%, 86%)',
    },
    signals: {
      direction: '#a8d8bcff'
    },
  },
};

const turntable_casing_width = 2;

const electrificationLegends = [
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
];

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
  110,
  120,
  130,
  140,
  150,
  160,
  170,
  180,
  190,
  200,
  210,
  220,
  230,
  240,
  250,
  260,
  270,
  280,
  290,
  300,
  320,
  340,
  360,
  380
];

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

const trainProtectionColor = theme => ['case',
  ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.main,
  ...signals_railway_line.train_protections.flatMap(train_protection =>
    [['==', ['get', 'train_protection'], train_protection.train_protection], train_protection.color]),
  'grey',
];

const railway_casing_add = 1;
const bridge_casing_add = 3;

// TODO move to variable
const present_dasharray = [1];
const abandoned_dasharray = [2.5, 2.5];
const disused_dasharray = [2.5, 2.5];
const razed_dasharray = [1.5, 3.5];
const construction_dasharray = [4.5, 4.5];
const proposed_dasharray = [1, 4];

const minSpeed = 10
const maxSpeed = 380
const startHue = 248
const endHue = 284;

const speedColor = ['case',
  ['==', ['get', 'maxspeed'], null], 'gray',
  // Reverse hue order
  ['concat', 'hsl(', ['%', ['+', ['-', startHue, ['*', startHue + (360 - endHue), ['/', ['-', ['max', minSpeed, ['min', ['get', 'maxspeed'], maxSpeed]], minSpeed], maxSpeed - minSpeed]]], 360], 360], ', 100%, 40%)'],
]
const speedHoverColor = theme => ['case',
  ['all', ['!=', ['get', 'maxspeed'], null],  ['>=', ['get', 'maxspeed'], 260], ['<=', ['get', 'maxspeed'], 300]], colors[theme].hover.alternative,
  colors[theme].hover.main,
]

const electrification_construction_dashes = [2.5, 2.5];
const electrification_proposed_dashes = [2, 4];

const color_no = 'black';
const color_delectrified = '#70584D';
const color_lt750v_dc = '#FF79B8';
const color_750v_dc = '#F930FF';
const color_gt750v_lt1kv_dc = '#D033FF';
const color_1kv_dc = '#5C1CCB';
const color_gt1kv_lt1500v_dc = '#007ACB';
const color_1500v_dc = '#0098CB';
const color_gt1500v_lt3kv_dc = '#00B7CB';
const color_3kv_dc = '#0000FF';
const color_gt3kv_dc = '#1969FF';
const color_lt15kv_ac = '#97FF2F';
const color_gte15kv_lt25kv_ac = '#F1F100';
const color_gte25kv_ac = '#FF9F19';
const color_15kv_16_67hz = '#00FF00';
const color_15kv_16_7hz = '#00CB66';
const color_25kv_50hz = '#FF0000';
const color_25kv_60hz = '#C00000';
const color_12kv_25hz = '#CCCC00';
const color_12_5kv_60hz = '#999900';
const color_20kv_50hz = '#FFCC66';
const color_20kv_60hz = '#FF9966';

const electrificationColor = (theme, voltageProperty, frequencyProperty) => ['case',
  ['boolean', ['feature-state', 'hover'], false], ['case',
    ['==', ['get', voltageProperty], 25000], colors[theme].hover.alternative,
    colors[theme].hover.main,
  ],
  ['all', ['==', ['get', frequencyProperty], 60], ['==', ['get', voltageProperty], 25000]], color_25kv_60hz,
  ['all', ['==', ['get', frequencyProperty], 50], ['==', ['get', voltageProperty], 25000]], color_25kv_50hz,
  ['all', ['==', ['get', frequencyProperty], 60], ['==', ['get', voltageProperty], 20000]], color_20kv_60hz,
  ['all', ['==', ['get', frequencyProperty], 50], ['==', ['get', voltageProperty], 20000]], color_20kv_50hz,
  ['all', ['!=', ['get', frequencyProperty], null], ['<', 16.665, ['get', frequencyProperty]], ['<', ['get', frequencyProperty], 16.675], ['==', ['get', voltageProperty], 15000]], color_15kv_16_67hz,
  ['all', ['!=', ['get', frequencyProperty], null], ['<', 16.65, ['get', frequencyProperty]], ['<', ['get', frequencyProperty], 16.75], ['==', ['get', voltageProperty], 15000]], color_15kv_16_7hz,
  ['all', ['==', ['get', frequencyProperty], 60], ['==', ['get', voltageProperty], 12500]], color_12_5kv_60hz,
  ['all', ['==', ['get', frequencyProperty], 25], ['==', ['get', voltageProperty], 12000]], color_12kv_25hz,
  ['all', ['==', ['get', frequencyProperty], 0], ['!=', ['get', voltageProperty], null], ['>', ['get', voltageProperty], 3000]], color_gt3kv_dc,
  ['all', ['==', ['get', frequencyProperty], 0], ['==', ['get', voltageProperty], 3000]], color_3kv_dc,
  ['all', ['==', ['get', frequencyProperty], 0], ['!=', ['get', voltageProperty], null], ['>', 3000, ['get', voltageProperty]], ['>', ['get', voltageProperty], 1500]], color_gt1500v_lt3kv_dc,
  ['all', ['==', ['get', frequencyProperty], 0], ['==', ['get', voltageProperty], 1500]], color_1500v_dc,
  ['all', ['==', ['get', frequencyProperty], 0], ['!=', ['get', voltageProperty], null], ['>', 1500, ['get', voltageProperty]], ['>', ['get', voltageProperty], 1000]], color_gt1kv_lt1500v_dc,
  ['all', ['==', ['get', frequencyProperty], 0], ['==', ['get', voltageProperty], 1000]], color_1kv_dc,
  ['all', ['==', ['get', frequencyProperty], 0], ['!=', ['get', voltageProperty], null], ['>', 1000, ['get', voltageProperty]], ['>', ['get', voltageProperty], 750]], color_gt750v_lt1kv_dc,
  ['all', ['==', ['get', frequencyProperty], 0], ['==', ['get', voltageProperty], 750]], color_750v_dc,
  ['all', ['==', ['get', frequencyProperty], 0], ['!=', ['get', voltageProperty], null], ['>', 750, ['get', voltageProperty]]], color_lt750v_dc,
  ['all',
    ['!=', ['get', frequencyProperty], 0],
    ['!=', ['get', voltageProperty], null],
    ['any',
      ['>', ['get', voltageProperty], 25000],
      ['all', ['!=', ['get', frequencyProperty], 50], ['!=', ['get', frequencyProperty], 60], ['>', ['get', voltageProperty], 25000]],
    ],
  ], color_gte25kv_ac,
  ['all',
    ['!=', ['get', frequencyProperty], 0],
    ['!=', ['get', voltageProperty], null],
    ['all', ['>', 25000, ['get', voltageProperty]], ['>', ['get', voltageProperty], 15000]]
  ], color_gte15kv_lt25kv_ac,
  ['all',
    ['!=', ['get', frequencyProperty], 0],
    ['!=', ['get', voltageProperty], null],
    ['>', 15000, ['get', voltageProperty]],
  ], color_lt15kv_ac,
  ['any',
    ['==', ['get', 'electrification_state'], 'deelectrified'],
    ['==', ['get', 'electrification_state'], 'abandoned'],
  ], color_delectrified,
  ['any',
    ['==', ['get', 'electrification_state'], 'no'],
    ['==', ['get', 'electrification_state'], 'construction'],
    ['==', ['get', 'electrification_state'], 'proposed'],
  ], color_no,
  'gray',
];

const gauge_construction_dashes = [3, 3];
const dual_construction_dashes = [1.5, 4.5];
const multi_construction_dashes = [0, 1, 1, 4];
const gauge_dual_gauge_dashes = [4.5, 4.5];
const gauge_multi_gauge_dashes = [0, 3, 3, 3];

const color_gauge_0064 = '#006060';
const color_gauge_0089 = '#008080';
const color_gauge_0127 = '#00A0A0';
const color_gauge_0184 = '#00C0C0';
const color_gauge_0190 = '#00E0E0';
const color_gauge_0260 = '#00FFFF';
const color_gauge_0381 = '#80FFFF';
const color_gauge_0500 = '#A0FFFF';
const color_gauge_0597 = '#C0FFFF';
const color_gauge_0600 = '#E0FFFF';
const color_gauge_0610 = '#FFE0FF';
const color_gauge_0700 = '#FFC0FF';
const color_gauge_0750 = '#FFA0FF';
const color_gauge_0760 = '#FF80FF';
const color_gauge_0762 = '#FF60FF';
const color_gauge_0785 = '#FF40FF';
const color_gauge_0800 = '#FF00FF';
const color_gauge_0891 = '#E000FF';
const color_gauge_0900 = '#C000FF';
const color_gauge_0914 = '#A000FF';
const color_gauge_0950 = '#8000FF';
const color_gauge_1000 = '#6000FF';
const color_gauge_1009 = '#4000FF';
const color_gauge_1050 = '#0000FF';
const color_gauge_1067 = '#0000E0';
const color_gauge_1100 = '#0000C0';
const color_gauge_1200 = '#0000A0';
const color_gauge_1372 = '#000080';
const color_gauge_1422 = '#000060';
const color_gauge_1432 = '#000040';
const color_gauge_1435 = '#000000';
const color_gauge_1440 = '#400000';
const color_gauge_1445 = '#600000';
const color_gauge_1450 = '#700000';
const color_gauge_1458 = '#800000';
const color_gauge_1495 = '#A00000';
const color_gauge_1520 = '#C00000';
const color_gauge_1522 = '#E00000';
const color_gauge_1524 = '#FF0000';
const color_gauge_1581 = '#FF6000';
const color_gauge_1588 = '#FF8000';
const color_gauge_1600 = '#FFA000';
const color_gauge_1668 = '#FFC000';
const color_gauge_1676 = '#FFE000';
const color_gauge_1700 = '#FFFF00';
const color_gauge_1800 = '#E0FF00';
const color_gauge_1880 = '#C0FF00';
const color_gauge_2000 = '#A0FF00';
const color_gauge_miniature = '#80C0C0';
const color_gauge_monorail = '#C0C080';
const color_gauge_broad = '#FFC0C0';
const color_gauge_narrow = '#C0C0FF';
const color_gauge_standard = '#808080';
const color_gauge_unknown = '#C0C0C0';

const gaugeColor = (theme, gaugeProperty, gaugeIntProperty) => ['case',
  ['boolean', ['feature-state', 'hover'], false], ['case',
    ['all', ['!=', ['get', gaugeIntProperty], null], ['>=', 1450, ['get', gaugeIntProperty]], ['<=', ['get', gaugeIntProperty], 1524]], colors[theme].hover.alternative,
    colors[theme].hover.main,
  ],
  // monorails or tracks with monorail gauge value
  ['any',
    ['==', ['get', 'feature'], 'monorail'],
    ['all',
      ['==', ['get', gaugeProperty], 'monorail'],
      ['any',
        ['==', ['get', 'feature'], 'rail'],
        ['==', ['get', 'feature'], 'light_rail'],
        ['==', ['get', 'feature'], 'subway'],
        ['==', ['get', 'feature'], 'tram'],
      ],
    ],
  ], color_gauge_monorail,
  // other tracks with inaccurate gauge value
  ['all',
    ['==', ['get', gaugeProperty], 'standard'],
    ['any',
      ['==', ['get', 'feature'], 'rail'],
      ['==', ['get', 'feature'], 'light_rail'],
      ['==', ['get', 'feature'], 'subway'],
      ['==', ['get', 'feature'], 'tram'],
    ],
  ], color_gauge_standard,
  ['all',
    ['==', ['get', gaugeProperty], 'broad'],
    ['any',
      ['==', ['get', 'feature'], 'rail'],
      ['==', ['get', 'feature'], 'light_rail'],
      ['==', ['get', 'feature'], 'subway'],
      ['==', ['get', 'feature'], 'tram'],
    ],
  ], color_gauge_broad,
  ['any',
    ['all',
      ['==', ['get', gaugeProperty], 'narrow'],
      ['any',
        ['==', ['get', 'feature'], 'rail'],
        ['==', ['get', 'feature'], 'light_rail'],
        ['==', ['get', 'feature'], 'subway'],
        ['==', ['get', 'feature'], 'tram'],
      ],
    ],
    ['all',
      ['==', ['get', 'feature'], 'narrow_gauge'],
      ['any',
        ['==', ['get', gaugeProperty], 'narrow'],
        ['==', ['get', gaugeProperty], 'broad'],
        ['==', ['get', gaugeProperty], 'standard'],
        ['==', ['get', gaugeProperty], 'unknown'],
        ['==', ['get', gaugeProperty], null],
      ],
    ],
  ], color_gauge_narrow,
  // miniature tracks with inaccurate gauge value
  ['all',
    ['==', ['get', 'feature'], 'miniature'],
    ['any',
      ['==', ['get', gaugeProperty], 'narrow'],
      ['==', ['get', gaugeProperty], 'broad'],
      ['==', ['get', gaugeProperty], 'standard'],
      ['==', ['get', gaugeProperty], 'unknown'],
      ['==', ['get', gaugeProperty], null],
    ],
  ], color_gauge_miniature,
  // unknown high numeric gauge values
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>=', ['get', gaugeIntProperty], 3000]], color_gauge_unknown,
  // colors for numeric gauge values
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 88, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 63]], color_gauge_0064,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 127, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 88]], color_gauge_0089,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 184, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 127]], color_gauge_0127,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 190, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 184]], color_gauge_0184,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 260, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 190]], color_gauge_0190,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 380, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 260]], color_gauge_0260,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 500, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 380]], color_gauge_0381,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 597, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 500]], color_gauge_0500,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 600, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 597]], color_gauge_0597,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 609, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 600]], color_gauge_0600,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 700, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 609]], color_gauge_0610,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 750, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 700]], color_gauge_0700,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 760, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 750]], color_gauge_0750,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 762, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 760]], color_gauge_0760,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 785, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 762]], color_gauge_0762,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 800, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 785]], color_gauge_0785,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 891, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 800]], color_gauge_0800,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 900, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 891]], color_gauge_0891,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 914, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 900]], color_gauge_0900,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 950, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 914]], color_gauge_0914,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1000, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 950]], color_gauge_0950,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1009, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1000]], color_gauge_1000,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1050, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1009]], color_gauge_1009,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1066, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1050]], color_gauge_1050,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1100, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1066]], color_gauge_1067,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1200, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1100]], color_gauge_1100,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1372, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1200]], color_gauge_1200,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1422, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1372]], color_gauge_1372,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1432, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1422]], color_gauge_1422,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1435, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1432]], color_gauge_1432,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1440, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1435]], color_gauge_1435,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1445, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1440]], color_gauge_1440,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1450, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1445]], color_gauge_1445,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1458, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1450]], color_gauge_1450,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1495, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1458]], color_gauge_1458,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1520, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1495]], color_gauge_1495,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1522, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1520]], color_gauge_1520,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1524, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1522]], color_gauge_1522,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1581, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1524]], color_gauge_1524,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1588, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1581]], color_gauge_1581,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1600, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1588]], color_gauge_1588,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1668, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1600]], color_gauge_1600,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1672, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1668]], color_gauge_1668,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1700, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1672]], color_gauge_1676,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1800, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1700]], color_gauge_1700,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 1880, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1800]], color_gauge_1800,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 2000, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 1880]], color_gauge_1880,
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 3000, ['get', gaugeIntProperty]], ['>=', ['get', gaugeIntProperty], 2000]], color_gauge_2000,
  // color for unknown low numeric gauge values
  ['all', ['!=', ['get', gaugeIntProperty], null], ['>', 63, ['get', gaugeIntProperty]], ['>', ['get', gaugeIntProperty], 0]], color_gauge_unknown,
  'gray',
];

const loadingGaugeFillColor = ['match', ['get', 'loading_gauge'],
  ...loading_gauges.loading_gauges.flatMap(loading_gauge =>
    [loading_gauge.value, loading_gauge.color]
  ),
  'gray',
];
const trackClassFillColor = ['match', ['get', 'track_class'],
  ...track_classes.track_classes.flatMap(track_class =>
    [track_class.value, track_class.color]
  ),
  'gray',
];

const attribution = '<a href="https://github.com/hiddewie/OpenRailwayMap-vector" target="_blank">&copy; OpenRailwayMap contributors</a> | <a href="https://www.openstreetmap.org/about" target="_blank">&copy; OpenStreetMap contributors</a>';

const sources = {
  search: {
    type: 'geojson',
    data: {
      type: 'FeatureCollection',
      features: [],
    },
  },
  openrailwaymap_low: {
    type: 'vector',
    url: `${origin}/railway_line_high`,
    attribution,
    promoteId: 'id',
  },
  standard_railway_text_stations_low: {
    type: 'vector',
    url: `${origin}/standard_railway_text_stations_low`,
    attribution,
    promoteId: 'id',
  },
  standard_railway_text_stations_med: {
    type: 'vector',
    url: `${origin}/standard_railway_text_stations_med`,
    attribution,
    promoteId: 'id',
  },
  high: {
    type: 'vector',
    url: `${origin}/high`,
    attribution,
    promoteId: 'id',
  },
  openrailwaymap_standard: {
    type: 'vector',
    url: `${origin}/standard`,
    attribution,
    promoteId: 'id',
  },
  openrailwaymap_speed: {
    type: 'vector',
    url: `${origin}/speed`,
    attribution,
    promoteId: 'id',
  },
  openrailwaymap_signals: {
    type: 'vector',
    url: `${origin}/signals`,
    attribution,
    promoteId: 'id',
  },
  openrailwaymap_electrification: {
    type: 'vector',
    url: `${origin}/electrification`,
    attribution,
    promoteId: 'id',
  }
};

const searchResults = {
  id: 'search',
  type: 'circle',
  source: 'search',
  paint: {
    'circle-radius': 8,
    'circle-color': 'rgba(183, 255, 0, 0.7)',
    'circle-stroke-width': 2,
    'circle-stroke-color': 'black',
  },
};

const railwayLine = (theme, text, layers) => [

  // Tunnels

  ...layers.flatMap(({id, minzoom, maxzoom, source, filter, width, states, sort}) =>
    Object.entries(states).map(([state, dash]) => ({
      id: `${id}_tunnel_casing_${state}`,
      type: 'line',
      minzoom,
      maxzoom,
      source,
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['==', ['get', 'state'], state],
        ['get', 'tunnel'],
        filter ?? true,
      ],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
        'line-sort-key': sort,
      },
      paint: {
        'line-color': colors[theme].casing,
        'line-width': width,
        'line-gap-width': railway_casing_add,
        'line-dasharray': dash,
      },
    }))
  ),
  ...layers.flatMap(({id, minzoom, maxzoom, source, filter, width, color, hoverColor, states, sort}) => [
    ...Object.entries(states).map(([state, dash]) => ({
      id: `${id}_tunnel_fill_${state}`,
      type: 'line',
      minzoom,
      maxzoom,
      source,
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['==', ['get', 'state'], state],
        ['get', 'tunnel'],
        filter ?? true,
      ],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
        'line-sort-key': sort,
      },
      paint: {
        'line-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], hoverColor || colors[theme].hover.main,
          color,
        ],
        'line-width': width,
        'line-dasharray': dash,
      },
    })),
  ]),
  ...layers.flatMap(({id, minzoom, maxzoom, source, filter, width, states, sort}) => ({
    id: `${id}_tunnel_cover`,
    type: 'line',
    minzoom: Math.max(minzoom, 8),
    maxzoom,
    source,
    'source-layer': 'railway_line_high',
    filter: ['all',
      ['any', ...Object.keys(states).map(state => ['==', ['get', 'state'], state])],
      ['get', 'tunnel'],
      filter ?? true,
    ],
    layout: {
      'line-join': 'round',
      'line-cap': 'butt',
      'line-sort-key': sort,
    },
    paint: {
      'line-color': colors[theme].styles.standard.tunnelCover,
      'line-width': width,
    },
  })),
  ...layers.flatMap(({id, filter, color, states}) =>
    preferredDirectionLayer(theme, `${id}_tunnel_preferred_direction`,
      ['all',
        ['get', 'tunnel'],
        ['any', ...Object.keys(states).map(state => ['==', ['get', 'state'], state])],
        ['any',
          ['==', ['get', 'preferred_direction'], 'forward'],
          ['==', ['get', 'preferred_direction'], 'backward'],
          ['==', ['get', 'preferred_direction'], 'both'],
        ],
        filter ?? true,
      ],
      color,
    ),
  ),

  // Ground

  ...layers.flatMap(({id, minzoom, maxzoom, source, filter, width, states, sort}) =>
    Object.entries(states).map(([state, dash]) => ({
      id: `${id}_casing_${state}`,
      type: 'line',
      minzoom,
      maxzoom,
      source,
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['==', ['get', 'state'], state],
        ['!', ['get', 'bridge']],
        ['!', ['get', 'tunnel']],
        filter ?? true,
      ],
      layout: {
        'line-join': 'round',
        'line-cap': 'butt',
        'line-sort-key': sort,
      },
      paint: {
        'line-color': colors[theme].casing,
        'line-width': width,
        'line-gap-width': railway_casing_add,
        'line-dasharray': dash,
      },
    }))
  ),
  ...layers.flatMap(({id, minzoom, maxzoom, source, filter, width, color, hoverColor, states, sort}) => [
    ...Object.entries(states).map(([state, dash]) => ({
      id: `${id}_fill_${state}`,
      type: 'line',
      minzoom,
      maxzoom,
      source,
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['==', ['get', 'state'], state],
        ['!', ['get', 'bridge']],
        ['!', ['get', 'tunnel']],
        filter ?? true,
      ],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
        'line-sort-key': sort,
      },
      paint: {
        'line-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], hoverColor || colors[theme].hover.main,
          color,
        ],
        'line-width': width,
        'line-dasharray': dash,
      },
    })),
  ]),

  // Bridges

  ...layers
    .filter(({states}) => 'present' in states)
    .flatMap(({id, minzoom, maxzoom, source, filter, width, sort}) => [
      {
        id: `${id}_bridge_railing`,
        type: 'line',
        minzoom: Math.max(minzoom, 8),
        maxzoom,
        source,
        'source-layer': 'railway_line_high',
        filter: ['all',
          ['==', ['get', 'state'], 'present'],
          ['get', 'bridge'],
          ['>=',
            ['get', 'way_length'],
            ['interpolate', ["exponential", .5], ['zoom'],
              8, 1500,
              16, 0
            ],
          ],
          filter ?? true,
        ],
        layout: {
          'line-join': 'round',
          'line-cap': 'butt',
          'line-sort-key': sort,
        },
        paint: {
          'line-color': colors[theme].styles.standard.casing.bridge,
          'line-width': width,
          'line-gap-width': bridge_casing_add,
        }
      },
      {
        id: `${id}_bridge_casing`,
        type: 'line',
        minzoom: Math.max(minzoom, 8),
        maxzoom,
        source,
        'source-layer': 'railway_line_high',
        filter: ['all',
          ['==', ['get', 'state'], 'present'],
          ['get', 'bridge'],
          ['>=',
            ['get', 'way_length'],
            ['interpolate', ["exponential", .5], ['zoom'],
              8, 1500,
              16, 0
            ],
          ],
        ],
        layout: {
          'line-join': 'round',
          'line-cap': 'butt',
          'line-sort-key': sort,
        },
        paint: {
          'line-color': colors[theme].casing,
          'line-width': width,
          'line-gap-width': railway_casing_add,
        }
      },
    ]),

  ...layers.flatMap(({id, minzoom, maxzoom, source, filter, width, color, hoverColor, states, sort}) => [
    ...Object.entries(states).map(([state, dash]) => ({
      id: `${id}_bridge_fill_${state}`,
      type: 'line',
      minzoom,
      maxzoom,
      source,
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['==', ['get', 'state'], state],
        ['get', 'bridge'],
        filter ?? true,
      ],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
        'line-sort-key': sort,
      },
      paint: {
        'line-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], hoverColor || colors[theme].hover.main,
          color,
        ],
        'line-width': width,
        'line-dasharray': dash,
      },
    })),
  ]),

  // Preferred direction

  ...layers.flatMap(({id, filter, color, states}) =>
    preferredDirectionLayer(
      theme,
      `${id}_preferred_direction`,
      ['all',
        ['any', ...Object.keys(states).map(state => ['==', ['get', 'state'], state])],
        ['!', ['get', 'tunnel']],
        ['any',
          ['==', ['get', 'preferred_direction'], 'forward'],
          ['==', ['get', 'preferred_direction'], 'backward'],
          ['==', ['get', 'preferred_direction'], 'both'],
        ],
        filter ?? true,
      ],
      color,
    ),
  ),

  // Text layers

  railwayKmText(theme),

  ...layers.flatMap(({id, minzoom, maxzoom, source, filter, states}) => ({
    id: `${id}_text`,
    type: 'symbol',
    minzoom,
    maxzoom,
    source,
    'source-layer': 'railway_line_high',
    filter: ['all',
      ['any', ...Object.keys(states).map(state => ['==', ['get', 'state'], state])],
      filter ?? true,
    ],
    paint: {
      'text-color': colors[theme].railwayLine.text,
      'text-halo-color': ['case',
        ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
        colors[theme].halo,
      ],
      'text-halo-width': 2,
    },
    layout: {
      'symbol-z-order': 'source',
      'symbol-placement': 'line',
      'text-field': text,
      'text-font': ['Noto Sans Bold'],
      'text-size': 11,
      'text-padding': 10,
      'text-max-width': 5,
      'symbol-spacing': 200,
    },
  })),
];

const railwayKmText = theme => ({
  id: 'railway_text_km',
  type: 'symbol',
  minzoom: 10,
  source: 'high',
  'source-layer': 'railway_text_km',
  filter: ['step', ['zoom'],
    ['get', 'zero'],
    13,
    true,
  ],
  paint: {
    'text-color': colors[theme].km.text,
    'text-halo-color': ['case',
      ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
      colors[theme].halo,
    ],
    'text-halo-width': 1,
  },
  layout: {
    'symbol-z-order': 'source',
    'text-field': ['step', ['zoom'],
      ['get', 'pos_int'],
      13,
      ['get', 'pos'],
    ],
    'text-font': ['Fira Code Bold'],
    'text-size': 11,
  },
});

const preferredDirectionLayer = (theme, id, filter, color) => ({
  id,
  type: 'symbol',
  minzoom: 15,
  source: 'high',
  'source-layer': 'railway_line_high',
  filter,
  paint: {
    'icon-color': color,
    'icon-halo-color': colors[theme].halo,
    'icon-halo-width': 2.0,
  },
  layout: {
    'symbol-placement': 'line',
    'symbol-spacing': 750,
    'icon-overlap': 'always',
    'icon-image': ['match', ['get', 'preferred_direction'],
      'forward', 'sdf:general/line-direction',
      'backward', 'sdf:general/line-direction',
      'both', 'sdf:general/line-direction-both',
      '',
    ],
    'icon-rotate': ['match', ['get', 'preferred_direction'],
      'backward', 180,
      0,
    ],
  },
});

const imageLayerWithOutline = (theme, id, spriteExpression, layer) => [
  {
    id: `${id}_outline`,
    ...layer,
    paint: {
      'icon-halo-color': ['case',
        ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
        colors[theme].halo,
      ],
      'icon-halo-blur': ['case',
        ['boolean', ['feature-state', 'hover'], false], 1.0,
        0.0,
      ],
      'icon-halo-width': ['case',
        ['boolean', ['feature-state', 'hover'], false], 3.0,
        2.0,
      ],
    },
    layout: {
      ...(layer.layout || {}),
      'icon-image': ['image', ['concat', 'sdf:', spriteExpression]],
    },
  },
  {
    id: `${id}_image`,
    ...layer,
    layout: {
      ...(layer.layout || {}),
      'icon-image': ['image', spriteExpression],
    },
  },
]

/**
 * Strategy for displaying railway lines
 *
 * Variables:
 * - state
 * - feature
 * - usage
 * - service
 *
 * Display tools, configurable per zoom level
 * - show/not show
 * - line width
 * - line color
 * - line dashes
 */
const layers = Object.fromEntries(knownThemes.map(theme => [theme, {
  standard: [
    ...railwayLine(theme,
      ['step', ['zoom'],
        ['coalesce', ['get', 'ref'], ''],
        14,
        ['coalesce', ['get', 'standard_label'], ''],
      ],
      [
        {
          id: 'railway_line_main_low',
          minzoom: 0,
          maxzoom: 7,
          source: 'openrailwaymap_low',
          states: {
            present: present_dasharray,
          },
          width: ["interpolate", ["exponential", 1.2], ["zoom"],
            0, 0.5,
            7, 2,
          ],
          color: ['case',
            ['get', 'highspeed'], colors[theme].styles.standard.highspeed,
            colors[theme].styles.standard.main,
          ],
          hoverColor: ['case',
            ['get', 'highspeed'], colors[theme].hover.alternative,
            colors[theme].hover.main,
          ],
        },

        // Medium zooms
        // ensure that width interpolation matches low zooms

        {
          id: 'railway_line_main_med',
          minzoom: 7,
          maxzoom: 8,
          source: 'openrailwaymap_low',
          states: {
            present: present_dasharray,
            construction: construction_dasharray,
            proposed: proposed_dasharray,
          },
          filter: ['==', ['get', 'usage'], 'main'],
          width: 2,
          color: ['case',
            ['get', 'highspeed'], colors[theme].styles.standard.highspeed,
            colors[theme].styles.standard.main,
          ],
          hoverColor: ['case',
            ['get', 'highspeed'], colors[theme].hover.alternative,
            colors[theme].hover.main,
          ],
        },
        {
          id: 'railway_line_branch_med',
          minzoom: 7,
          maxzoom: 8,
          source: 'openrailwaymap_low',
          states: {
            present: present_dasharray,
            construction: construction_dasharray,
            proposed: proposed_dasharray,
          },
          filter: ['==', ['get', 'usage'], 'branch'],
          width: 2,
          color: colors[theme].styles.standard.branch,
        },

        // High zooms
        // ensure that width interpolation matches medium zooms

        {
          id: 'railway_line_miniature',
          minzoom: 12,
          source: 'high',
          states: {
            present: present_dasharray,
            construction: construction_dasharray,
            proposed: proposed_dasharray,
          },
          filter: ['==', ['get', 'feature'], 'miniature'],
          width: 2,
          color: colors[theme].styles.standard.miniature,
        },
        {
          id: 'railway_line_razed',
          minzoom: 11,
          source: 'high',
          states: {
            razed: razed_dasharray,
          },
          width: 1.5,
          color: colors[theme].styles.standard.razed,
        },
        {
          id: 'railway_line_disused',
          minzoom: 11,
          source: 'high',
          states: {
            disused: disused_dasharray,
          },
          width: 1.5,
          color: colors[theme].styles.standard.disused,
        },
        {
          id: 'railway_line_abandoned',
          minzoom: 11,
          source: 'high',
          states: {
            abandoned: abandoned_dasharray,
          },
          width: 1.5,
          color: colors[theme].styles.standard.abandoned,
        },
        {
          id: 'railway_line_narrow_gauge',
          minzoom: 10,
          source: 'high',
          states: {
            present: present_dasharray,
            construction: construction_dasharray,
            proposed: proposed_dasharray,
          },
          filter: ['all',
            ['==', ['get', 'feature'], 'narrow_gauge'],
            ['!',
              // Covered by industrial case
              ['==', ['get', 'usage'], 'industrial'],
            ],
          ],
          width: 2,
          color: colors[theme].styles.standard.narrowGauge,
        },
        {
          id: 'railway_line_service',
          minzoom: 10,
          source: 'high',
          states: {
            present: present_dasharray,
            construction: construction_dasharray,
            proposed: proposed_dasharray,
          },
          filter: ['all',
            ['==', ['get', 'feature'], 'rail'],
            ['==', ['get', 'usage'], null],
          ],
          width: ["interpolate", ["exponential", 1.2], ["zoom"],
            8, ['match', ['get', 'service'],
              'yard', 1,
              1.5,
            ],
            15, ['match', ['get', 'service'],
              'yard', 1,
              1.5,
            ],
            16, 2,
          ],
          color: ['match', ['get', 'service'],
            'spur', colors[theme].styles.standard.spur,
            'siding', colors[theme].styles.standard.siding,
            'yard', colors[theme].styles.standard.yard,
            'crossover', colors[theme].styles.standard.crossover,
            colors[theme].styles.standard.unknown,
          ],
        },
        {
          id: 'railway_line_light_rail',
          minzoom: 9,
          source: 'high',
          states: {
            present: present_dasharray,
            construction: construction_dasharray,
            proposed: proposed_dasharray,
          },
          filter: ['all',
            ['any',
              ['==', ['get', 'feature'], 'subway'],
              ['==', ['get', 'feature'], 'tram'],
              ['==', ['get', 'feature'], 'light_rail'],
              ['==', ['get', 'feature'], 'monorail'],
            ],
          ],
          width: 2,
          color: ['match', ['get', 'feature'],
            'light_rail', colors[theme].styles.standard.light_rail,
            'monorail', colors[theme].styles.standard.monorail,
            'subway', colors[theme].styles.standard.subway,
            'tram', colors[theme].styles.standard.tram,
            colors[theme].styles.standard.unknown,
          ],
        },
        {
          id: 'railway_line_test_military',
          minzoom: 10,
          source: 'high',
          states: {
            present: present_dasharray,
            construction: construction_dasharray,
            proposed: proposed_dasharray,
          },
          filter: ['all',
            ['==', ['get', 'feature'], 'rail'],
            ['any',
              ['==', ['get', 'usage'], 'test'],
              ['==', ['get', 'usage'], 'military'],
            ],
          ],
          width: ["interpolate", ["exponential", 1.2], ["zoom"],
            8, 1.5,
            14, 1.5,
            16, 2,
          ],
          color: ['match', ['get', 'usage'],
            'test', colors[theme].styles.standard.test,
            'military', colors[theme].styles.standard.military,
            colors[theme].styles.standard.unknown,
          ],
        },
        {
          id: 'railway_line_tourism',
          minzoom: 9,
          source: 'high',
          states: {
            present: present_dasharray,
            preserved: present_dasharray,
            construction: construction_dasharray,
            proposed: proposed_dasharray,
          },
          filter: ['any',
            ['all',
              ['==', ['get', 'feature'], 'rail'],
              ['==', ['get', 'usage'], 'tourism'],
            ],
            ['==', ['get', 'state'], 'preserved'],
          ],
          width: 2,
          color: colors[theme].styles.standard.tourism,
        },
        {
          id: 'railway_line_industrial',
          minzoom: 9,
          source: 'high',
          states: {
            present: present_dasharray,
            construction: construction_dasharray,
            proposed: proposed_dasharray,
          },
          filter: ['all',
            ['==', ['get', 'usage'], 'industrial'],
            ['any',
              ['==', ['get', 'feature'], 'rail'],
              ['==', ['get', 'feature'], 'narrow_gauge'],
            ],
          ],
          width: ["interpolate", ["exponential", 1.2], ["zoom"],
            8, 1.5,
            14, 1.5,
            16, 2,
          ],
          color: colors[theme].styles.standard.industrial,
        },
        {
          id: 'railway_line_branch_high',
          minzoom: 8,
          source: 'high',
          states: {
            present: present_dasharray,
            construction: construction_dasharray,
            proposed: proposed_dasharray,
          },
          filter: ['all',
            ['==', ['get', 'feature'], 'rail'],
            ['==', ['get', 'usage'], 'branch'],
          ],
          width: ["interpolate", ["exponential", 1.2], ["zoom"],
            8, 2,
            14, 2,
            16, 3,
          ],
          color: colors[theme].styles.standard.branch,
        },
        {
          id: 'railway_line_main_high',
          minzoom: 8,
          source: 'high',
          states: {
            present: present_dasharray,
            construction: construction_dasharray,
            proposed: proposed_dasharray,
          },
          filter: ['all',
            ['==', ['get', 'feature'], 'rail'],
            ['==', ['get', 'usage'], 'main'],
          ],
          width: ["interpolate", ["exponential", 1.2], ["zoom"],
            8, 2,
            14, 2,
            16, 3,
          ],
          color: ['case',
            ['get', 'highspeed'], colors[theme].styles.standard.highspeed,
            colors[theme].styles.standard.main,
          ],
          hoverColor: ['case',
            ['get', 'highspeed'], colors[theme].hover.alternative,
            colors[theme].hover.main,
          ],
        },
      ],
    ),
    {
      id: 'railway_text_stations_low1',
      type: 'symbol',
      minzoom: 4,
      maxzoom: 5,
      source: 'standard_railway_text_stations_low',
      'source-layer': 'standard_railway_text_stations_low',
      paint: {
        'icon-color': colors[theme].styles.standard.stationsText,
        'icon-halo-width': 1,
        'icon-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
          colors[theme].halo,
        ],
      },
      layout: {
        'symbol-z-order': 'source',
        'icon-image': 'sdf:general/station-small',
        'icon-overlap': 'always',
      },
    },
    {
      id: 'railway_text_stations_low2',
      type: 'symbol',
      minzoom: 5,
      maxzoom: 7,
      source: 'standard_railway_text_stations_low',
      'source-layer': 'standard_railway_text_stations_low',
      paint: {
        'text-color': colors[theme].styles.standard.stationsText,
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
          colors[theme].halo,
        ],
        'text-halo-width': 1.5,
        'icon-color': colors[theme].styles.standard.stationsText,
        'icon-halo-width': 1,
        'icon-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
          colors[theme].halo,
        ],
      },
      layout: {
        'symbol-z-order': 'source',
        'icon-image': ['image', ['concat', 'sdf:general/station-', ['get', 'station_size']]],
        'icon-overlap': 'always',
        'text-field': '{label}',
        'text-font': ['Noto Sans Bold'],
        'text-size': 11,
        'text-padding': 10,
        'text-max-width': 5,
        'text-optional': true,
        'text-variable-anchor': ['top', 'bottom', 'left', 'right'],
      },
    },
    {
      id: 'railway_text_stations_med',
      type: 'symbol',
      minzoom: 7,
      maxzoom: 8,
      source: 'standard_railway_text_stations_med',
      'source-layer': 'standard_railway_text_stations_med',
      paint: {
        'text-color': colors[theme].styles.standard.stationsText,
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
          colors[theme].halo,
        ],
        'text-halo-width': 1.5,
        'icon-color': colors[theme].styles.standard.stationsText,
        'icon-halo-width': 1,
        'icon-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
          colors[theme].halo,
        ],
      },
      layout: {
        'symbol-z-order': 'source',
        'icon-image': ['image', ['concat', 'sdf:general/station-', ['get', 'station_size']]],
        'icon-overlap': 'always',
        'text-field': '{label}',
        'text-font': ['Noto Sans Bold'],
        'text-size': 11,
        'text-padding': 10,
        'text-max-width': 5,
        'text-optional': true,
        'text-variable-anchor': ['top', 'bottom', 'left', 'right'],
      },
    },
    {
      id: 'railway_grouped_stations',
      type: 'fill',
      minzoom: 13,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_grouped_stations',
      paint: {
        'fill-color': ['case',
          ['==', ['get', 'railway'], 'tram_stop'], colors[theme].styles.standard.tram,
          ['==', ['get', 'station'], 'light_rail'], colors[theme].styles.standard.light_rail,
          ['==', ['get', 'station'], 'subway'], colors[theme].styles.standard.subway,
          ['==', ['get', 'station'], 'monorail'], colors[theme].styles.standard.monorail,
          ['==', ['get', 'station'], 'miniature'], colors[theme].styles.standard.miniature,
          colors[theme].styles.standard.main,
        ],
        'fill-opacity': ['case',
          ['boolean', ['feature-state', 'hover'], false], 0.3,
          0.2,
        ],
      },
    },
    {
      id: 'railway_turntables_fill',
      type: 'fill',
      minzoom: 10,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_turntables',
      paint: {
        'fill-color': colors[theme].styles.standard.turntable.fill,
      }
    },
    {
      id: 'railway_turntables_casing',
      type: 'line',
      minzoom: 15,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_turntables',
      paint: {
        'line-color': colors[theme].styles.standard.turntable.casing,
        'line-width': turntable_casing_width,
      }
    },
    ...imageLayerWithOutline(
      theme,
      'railway_symbols_minzoom_10',
      ['get', 'feature'],
      {
        type: 'symbol',
        minzoom: 10,
        source: 'openrailwaymap_standard',
        'source-layer': 'standard_railway_symbols',
        filter: ['==', ['get', 'feature'], 'general/border'],
        layout: {
          'icon-overlap': 'cooperative',
        },
      },
    ),
    ...imageLayerWithOutline(
      theme,
      'railway_symbols_minzoom_13',
      ['get', 'feature'],
      {
        type: 'symbol',
        minzoom: 13,
        source: 'openrailwaymap_standard',
        'source-layer': 'standard_railway_symbols',
        filter: ['any',
          ['==', ['get', 'feature'], 'general/lubricator'],
          ['==', ['get', 'feature'], 'general/fuel'],
          ['==', ['get', 'feature'], 'general/sand_store'],
          ['==', ['get', 'feature'], 'general/aei'],
          ['==', ['get', 'feature'], 'general/defect_detector'],
          ['==', ['get', 'feature'], 'general/hump_yard'],
          ['==', ['get', 'feature'], 'general/loading_gauge'],
          ['==', ['get', 'feature'], 'general/preheating'],
          ['==', ['get', 'feature'], 'general/compressed_air_supply'],
          ['==', ['get', 'feature'], 'general/waste_disposal'],
          ['==', ['get', 'feature'], 'general/coaling_facility'],
          ['==', ['get', 'feature'], 'general/wash'],
          ['==', ['get', 'feature'], 'general/water_tower'],
          ['==', ['get', 'feature'], 'general/water_crane'],
          ['==', ['get', 'feature'], 'general/vacancy-detection-insulated-rail-joint'],
          ['==', ['get', 'feature'], 'general/vacancy-detection-axle-counter'],
          ['==', ['get', 'feature'], 'general/workshop'],
          ['==', ['get', 'feature'], 'general/engine_shed'],
          ['==', ['get', 'feature'], 'general/museum'],
          ['==', ['get', 'feature'], 'general/power_supply'],
          ['==', ['get', 'feature'], 'general/rolling_highway'],
        ],
        layout: {
          'symbol-z-order': 'source',
          'icon-overlap': 'always',
        },
      },
    ),
    ...imageLayerWithOutline(
      theme,
      'railway_symbols_minzoom_14',
      ['get', 'feature'],
      {
        type: 'symbol',
        minzoom: 14,
        source: 'openrailwaymap_standard',
        'source-layer': 'standard_railway_symbols',
        filter: ['any',
          ['==', ['get', 'feature'], 'general/crossing'],
          ['==', ['get', 'feature'], 'general/level-crossing'],
          ['==', ['get', 'feature'], 'general/level-crossing-light'],
          ['==', ['get', 'feature'], 'general/level-crossing-barrier'],
          ['==', ['get', 'feature'], 'general/level-crossing-light-barrier'],
          ['==', ['get', 'feature'], 'general/buffer_stop'],
          ['==', ['get', 'feature'], 'general/derail'],
        ],
        layout: {
          'symbol-z-order': 'source',
          'icon-overlap': 'always',
        },
      },
    ),
    ...imageLayerWithOutline(
      theme,
      'railway_symbols_minzoom_12',
      ['get', 'feature'],
      {
        type: 'symbol',
        minzoom: 12,
        source: 'openrailwaymap_standard',
        'source-layer': 'standard_railway_symbols',
        filter: ['any',
          ['==', ['get', 'feature'], 'general/owner-change'],
          ['==', ['get', 'feature'], 'general/radio-mast'],
          ['==', ['get', 'feature'], 'general/radio-antenna'],
        ],
        layout: {
          'symbol-z-order': 'source',
          'icon-overlap': 'always',
        },
      },
    ),
    ...imageLayerWithOutline(
      theme,
      'railway_symbols_minzoom_16',
      ['get', 'feature'],
      {
        type: 'symbol',
        minzoom: 16,
        source: 'openrailwaymap_standard',
        'source-layer': 'standard_railway_symbols',
        filter: ['any',
          ['==', ['get', 'feature'], 'general/crossing'],
          ['==', ['get', 'feature'], 'general/level-crossing'],
          ['==', ['get', 'feature'], 'general/level-crossing-light'],
          ['==', ['get', 'feature'], 'general/level-crossing-barrier'],
          ['==', ['get', 'feature'], 'general/level-crossing-light-barrier'],
          ['==', ['get', 'feature'], 'general/phone'],
          ['==', ['get', 'feature'], 'general/subway-entrance'],
          ['==', ['get', 'feature'], 'general/buffer_stop'],
        ],
        layout: {
          'symbol-z-order': 'source',
          'icon-overlap': 'always',
        },
      },
    ),
    {
      id: 'railway_text_track_numbers',
      type: 'symbol',
      minzoom: 16,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['!=', ['get', 'track_ref'], null],
      paint: {
        'text-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].styles.standard.track.hover,
          colors[theme].styles.standard.track.text,
        ],
        'text-halo-color': colors[theme].styles.standard.track.halo,
        'text-halo-width': 4,
        'text-halo-blur': 2,
      },
      layout: {
        'symbol-z-order': 'source',
        'symbol-placement': 'line',
        'text-field': '{track_ref}',
        'text-font': ['Noto Sans Bold'],
        'text-size': 10,
        'text-padding': 10,
      },
    },
    {
      id: 'railway_switch_ref',
      type: 'symbol',
      minzoom: 15,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_switch_ref',
      paint: {
        'text-color': colors[theme].styles.standard.switch.text,
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].styles.standard.switch.hover,
          ['get', 'railway_local_operated'], colors[theme].styles.standard.switch.localOperated,
          colors[theme].styles.standard.switch.halo
        ],
        'text-halo-width': 2,
      },
      layout: {
        'symbol-z-order': 'source',
        'text-field': '{ref}',
        'text-font': ['Noto Sans Medium'],
        'text-size': 11,
        'text-padding': 20,
      },
    },
    {
      id: 'railway_text_stations',
      type: 'symbol',
      minzoom: 8,
      maxzoom: 13,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_text_stations',
      filter: ['step', ['zoom'],
        ['all',
          ['==', ['get', 'railway'], 'station'],
          ['!=', ['get', 'station'], 'light_rail'],
          ['!=', ['get', 'station'], 'subway'],
          ['!=', ['get', 'station'], 'monorail'],
          ['!=', ['get', 'station'], 'funicular'],
        ],
        9,
        ['all',
          ['any',
            ['==', ['get', 'railway'], 'station'],
            ['==', ['get', 'railway'], 'halt'],
          ],
          ['!=', ['get', 'station'], 'light_rail'],
          ['!=', ['get', 'railway'], 'tram_stop'],
          ['!=', ['get', 'station'], 'subway'],
          ['!=', ['get', 'station'], 'monorail'],
          ['!=', ['get', 'station'], 'funicular'],
        ],
        10,
        ['all',
          ['!=', ['get', 'railway'], 'tram_stop'],
          ['!=', ['get', 'station'], 'funicular'],
          ['!=', ['get', 'station'], 'miniature'],
        ],
        11,
        ['all',
          ['!=', ['get', 'station'], 'funicular'],
          ['!=', ['get', 'station'], 'miniature'],
        ],
      ],
      paint: {
        'text-color': ['case',
          ['==', ['get', 'railway'], 'yard'], colors[theme].styles.standard.yardText,
          ['==', ['get', 'railway'], 'tram_stop'], colors[theme].styles.standard.tramStopText,
          ['==', ['get', 'railway'], 'station'], ['case',
            ['==', ['get', 'station'], 'light_rail'], colors[theme].styles.standard.lightRailText,
            ['==', ['get', 'station'], 'monorail'], colors[theme].styles.standard.monorailText,
            colors[theme].styles.standard.stationsText,
          ],
          ['==', ['get', 'railway'], 'halt'], ['case',
            ['==', ['get', 'station'], 'monorail'], colors[theme].styles.standard.monorailText,
            colors[theme].styles.standard.stationsText,
          ],
          colors[theme].styles.standard.defaultText,
        ],
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
          colors[theme].halo,
        ],
        'text-halo-width': 1.5,
        'icon-color': ['case',
          ['==', ['get', 'railway'], 'yard'], colors[theme].styles.standard.yardText,
          ['==', ['get', 'railway'], 'tram_stop'], colors[theme].styles.standard.tramStopText,
          ['==', ['get', 'railway'], 'station'], ['case',
            ['==', ['get', 'station'], 'light_rail'], colors[theme].styles.standard.lightRailText,
            ['==', ['get', 'station'], 'monorail'], colors[theme].styles.standard.monorailText,
            colors[theme].styles.standard.stationsText,
          ],
          ['==', ['get', 'railway'], 'halt'], ['case',
            ['==', ['get', 'station'], 'monorail'], colors[theme].styles.standard.monorailText,
            colors[theme].styles.standard.stationsText,
          ],
          colors[theme].styles.standard.defaultText,
        ],
        'icon-halo-width': 1,
        'icon-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
          colors[theme].halo,
        ],
      },
      layout: {
        'symbol-z-order': 'source',
        'icon-image': ['image', ['concat', 'sdf:general/station-', ['get', 'station_size']]],
        'icon-overlap': 'always',
        'text-field': ['step', ['zoom'],
          ['get', 'label'],
          10,
          ['get', 'name'],
        ],
        'text-font': ['Noto Sans Bold'],
        'text-size': 11,
        'text-padding': 10,
        'text-max-width': 5,
        'text-optional': true,
        'text-variable-anchor': ['top', 'bottom', 'left', 'right'],
      },
    },
    {
      id: 'railway_text_stations_high',
      type: 'symbol',
      minzoom: 13,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_text_stations',
      filter: ['all',
        ['!=', ['get', 'station'], 'funicular'],
      ],
      paint: {
        'text-color': ['case',
          ['==', ['get', 'railway'], 'yard'], colors[theme].styles.standard.yardText,
          ['==', ['get', 'railway'], 'tram_stop'], colors[theme].styles.standard.tramStopText,
          ['==', ['get', 'railway'], 'station'], ['case',
            ['==', ['get', 'station'], 'light_rail'], colors[theme].styles.standard.lightRailText,
            ['==', ['get', 'station'], 'monorail'], colors[theme].styles.standard.monorailText,
            colors[theme].styles.standard.stationsText,
          ],
          ['==', ['get', 'railway'], 'halt'], ['case',
            ['==', ['get', 'station'], 'monorail'], colors[theme].styles.standard.monorailText,
            ['==', ['get', 'station'], 'miniature'], colors[theme].styles.standard.miniatureText,
            colors[theme].styles.standard.stationsText,
          ],
          colors[theme].styles.standard.defaultText,
        ],
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
          colors[theme].halo,
        ],
        'text-halo-width': 1.5,
      },
      layout: {
        'symbol-z-order': 'source',
        'text-field': ['step', ['zoom'],
          ['get', 'name'],
          15,
          ['case',
            ['>', ['coalesce', ['get', 'count'], 0], 1], ['concat', ['get', 'name'], ' (', ['get', 'count'], ')'],
            ['get', 'name'],
          ],
        ],
        'text-font': ['Noto Sans Bold'],
        'text-variable-anchor': ['center', 'top', 'bottom', 'left', 'right'],
        'text-size': 11,
        'text-padding': 10,
        'text-max-width': 5,
      },
    },
    searchResults,
  ],

  speed: [
    ...railwayLine(theme,
      ['coalesce', ['get', 'speed_label'], ''],
      [
        {
          id: 'speed_low',
          minzoom: 0,
          maxzoom: 7,
          source: 'openrailwaymap_low',
          states: {
            present: present_dasharray,
          },
          width: ["interpolate", ["exponential", 1.2], ["zoom"],
            0, 0.5,
            7, 2,
          ],
          color: speedColor,
          hoverColor: speedHoverColor(theme),
        },
        {
          id: 'speed_med',
          minzoom: 7,
          maxzoom: 8,
          source: 'openrailwaymap_low',
          states: {
            present: present_dasharray,
            construction: construction_dasharray,
            proposed: proposed_dasharray,
          },
          width: 2,
          color: speedColor,
          hoverColor: speedHoverColor(theme),
        },
        {
          id: 'speed_high',
          minzoom: 8,
          source: 'high',
          states: {
            present: present_dasharray,
            construction: construction_dasharray,
            proposed: proposed_dasharray,
          },
          width: ["interpolate", ["exponential", 1.2], ["zoom"],
            14, 2,
            16, 3,
          ],
          color: speedColor,
          hoverColor: speedHoverColor(theme),
        },
      ],
    ),
    {
      id: 'speed_railway_signal_direction',
      type: 'symbol',
      minzoom: 13,
      source: 'openrailwaymap_speed',
      'source-layer': 'speed_railway_signals',
      filter: ['step', ['zoom'],
        ['all',
          ['!=', ['get', 'feature0'], null],
          ['!=', ['get', 'azimuth'], null],
          ['==', ['get', 'type'], 'line'],
        ],
        14,
        ['all',
          ['!=', ['get', 'feature0'], null],
          ['!=', ['get', 'azimuth'], null],
          ['any',
            ['==', ['get', 'type'], 'line'],
            ['==', ['get', 'type'], 'tram'],
          ]
        ],
        16,
        ['all',
          ['!=', ['get', 'feature0'], null],
          ['!=', ['get', 'azimuth'], null],
        ],
      ],
      paint: {
        'icon-color': colors[theme].signals.direction,
        'icon-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
          colors[theme].halo,
        ],
        'icon-halo-width': 2.0,
        'icon-halo-blur': 2.0,
      },
      layout: {
        'icon-overlap': 'always',
        'icon-image': ['case',
          ['coalesce', ['get', 'direction_both'], false], 'sdf:general/signal-direction-both',
          'sdf:general/signal-direction',
        ],
        'icon-anchor': ['case',
          ['coalesce', ['get', 'direction_both'], false], 'center',
          'top',
        ],
        'icon-rotate': ['get', 'azimuth'],
        'icon-keep-upright': true,
        'icon-rotation-alignment': 'map',
      },
    },
    ...[0, 1].flatMap(featureIndex =>
      imageLayerWithOutline(
        theme,
        `speed_railway_signals_${featureIndex}`,
        ['get', `feature${featureIndex}`],
        {
          type: 'symbol',
          minzoom: 13,
          source: 'openrailwaymap_speed',
          'source-layer': 'speed_railway_signals',
          filter: ['step', ['zoom'],
            ['all',
              ['!=', ['get', `feature${featureIndex}`], null],
              ['==', ['get', 'type'], 'line'],
            ],
            14,
            ['all',
              ['!=', ['get', `feature${featureIndex}`], null],
              ['any',
                ['==', ['get', 'type'], 'line'],
                ['==', ['get', 'type'], 'tram'],
              ]
            ],
            16,
            ['!=', ['get', `feature${featureIndex}`], null],
          ],
          layout: {
            'symbol-z-order': 'source',
            'icon-overlap': 'always',
            'icon-offset': [0, -20 * featureIndex],
          },
        },
      )
    ),
    {
      id: 'speed_railway_signals_deactivated',
      type: 'symbol',
      minzoom: 13,
      source: 'openrailwaymap_speed',
      'source-layer': 'speed_railway_signals',
      filter: ['get', 'deactivated'],
      layout: {
        'symbol-z-order': 'source',
        'icon-overlap': 'always',
        'icon-image': 'general/signal-deactivated',
      }
    },
    {
      id: `speed_railway_signals_text`,
      type: 'symbol',
      minzoom: 16,
      source: 'openrailwaymap_speed',
      'source-layer': 'speed_railway_signals',
      filter: ['any',
        ['!=', ['get', 'ref'], null],
        ['!=', ['get', 'caption'], null],
      ],
      paint: {
        'text-color': colors[theme].text.main,
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
          colors[theme].halo
        ],
        'text-halo-width': 1.5,
        'text-halo-blur': 1,
      },
      layout: {
        'text-field': ['format',
          ['get', 'ref'], {},
          ['case', ['all', ['!=', ['get', 'ref'], null], ['!=', ['get', 'caption'], null]], '\n', ''], {},
          ['case', ['==', ['get', 'caption'], null], '', ['get', 'caption']], {'text-font': ['literal', ['Noto Sans Italic']]},
        ],
        'text-font': ['Noto Sans Medium'],
        'text-size': 9,
        'text-anchor': 'top',
        'text-offset': [0, 1.5],
      },
    },
    searchResults,
  ],

  signals: [
    ...railwayLine(theme,
      '',
      [
        {
          id: 'railway_line_low',
          minzoom: 0,
          maxzoom: 7,
          source: 'openrailwaymap_low',
          states: {
            present: present_dasharray,
          },
          sort: ['get', 'train_protection_rank'],
          width: ["interpolate", ["exponential", 1.2], ["zoom"],
            0, 0.5,
            7, 2,
          ],
          color: trainProtectionColor(theme),
        },
        {
          id: 'railway_line_med',
          minzoom: 7,
          maxzoom: 8,
          source: 'openrailwaymap_low',
          states: {
            present: present_dasharray,
            construction: construction_dasharray,
            proposed: proposed_dasharray,
          },
          sort: ['get', 'train_protection_rank'],
          width: 2,
          color: trainProtectionColor(theme),
        },
        {
          id: 'railway_line_high',
          minzoom: 8,
          source: 'high',
          states: {
            present: present_dasharray,
            construction: construction_dasharray,
            proposed: proposed_dasharray,
          },
          sort: ['get', 'train_protection_rank'],
          width: ["interpolate", ["exponential", 1.2], ["zoom"],
            14, 2,
            16, 3,
          ],
          color: trainProtectionColor(theme),
        },
      ],
    ),
    {
      id: 'signal_boxes_point',
      type: 'circle',
      minzoom: 10,
      source: 'openrailwaymap_signals',
      'source-layer': 'signals_signal_boxes',
      filter: ['==', ["geometry-type"], 'Point'],
      paint: {
        'circle-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.main,
          '#008206',
        ],
        'circle-radius': 4,
        'circle-stroke-color': 'white',
        'circle-stroke-width': 1,
      },
    },
    {
      id: 'signal_boxes_polygon',
      type: 'fill',
      minzoom: 14,
      source: 'openrailwaymap_signals',
      'source-layer': 'signals_signal_boxes',
      filter: ['any',
        ['==', ["geometry-type"], 'Polygon'],
        ['==', ["geometry-type"], 'MultiPolygon'],
      ],
      paint: {
        'fill-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.main,
          '#008206',
        ],
        'fill-outline-color': 'white',
      },
    },
    {
      id: 'signal_boxes_polygon_outline',
      type: 'line',
      minzoom: 14,
      source: 'openrailwaymap_signals',
      'source-layer': 'signals_signal_boxes',
      filter: ['any',
        ['==', ["geometry-type"], 'Polygon'],
        ['==', ["geometry-type"], 'MultiPolygon'],
      ],
      paint: {
        'line-color': 'white',
        'line-width': 1,
      },
    },
    {
      id: 'railway_signals_direction',
      type: 'symbol',
      minzoom: 13,
      source: 'openrailwaymap_signals',
      'source-layer': 'signals_railway_signals',
      filter: ['all',
        ['!=', ['get', 'azimuth'], null],
        ['!=', ['get', 'feature0'], ''],
      ],
      paint: {
        'icon-color': colors[theme].signals.direction,
        'icon-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
          colors[theme].halo,
        ],
        'icon-halo-width': 2.0,
        'icon-halo-blur': 2.0,
      },
      layout: {
        'icon-overlap': 'always',
        'icon-image': ['case',
          ['coalesce', ['get', 'direction_both'], false], 'sdf:general/signal-direction-both',
          'sdf:general/signal-direction',
        ],
        'icon-anchor': ['case',
          ['coalesce', ['get', 'direction_both'], false], 'center',
          'top',
        ],
        'icon-rotate': ['get', 'azimuth'],
        'icon-keep-upright': true,
        'icon-rotation-alignment': 'map',
      },
    },
    // Show at most 2 combined features
    ...[0, 1].flatMap(featureIndex =>
      imageLayerWithOutline(
        theme,
        `railway_signals_medium_${featureIndex}`,
        ['case',
          ['==', ['slice', ['get', `feature${featureIndex}`], 0, 20], 'de/blockkennzeichen-'], 'de/blockkennzeichen',
          ['get', `feature${featureIndex}`],
        ],
        {
          type: 'symbol',
          minzoom: 13,
          maxzoom: 16,
          source: 'openrailwaymap_signals',
          'source-layer': 'signals_railway_signals',
          filter: ['!=', ['get', `feature${featureIndex}`], null],
          layout: {
            'symbol-z-order': 'source',
            'icon-overlap': 'always',
            'icon-offset': [0, -20 * featureIndex],
          },
        },
      )
    ),
    ...[0, 1, 2, 3, 4, 5].flatMap(featureIndex =>
      imageLayerWithOutline(
        theme,
        `railway_signals_high_${featureIndex}`,
        ['get', `feature${featureIndex}`],
        {
          type: 'symbol',
          minzoom: 16,
          source: 'openrailwaymap_signals',
          'source-layer': 'signals_railway_signals',
          filter: ['!=', ['get', `feature${featureIndex}`], null],
          layout: {
            'symbol-z-order': 'source',
            'icon-overlap': 'always',
            'icon-offset': [0, -20 * featureIndex],
          },
        },
      )
    ),
    {
      id:`railway_signals_high_text`,
      type: 'symbol',
      minzoom: 16,
      source: 'openrailwaymap_signals',
      'source-layer': 'signals_railway_signals',
      filter: ['all',
        ['any',
          ['!=', ['get', 'ref'], null],
          ['!=', ['get', 'caption'], null],
        ],
        ['!=', ['get', 'feature0'], null],
      ],
      paint: {
        'text-color': colors[theme].text.main,
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
          colors[theme].halo
        ],
        'text-halo-width': ['case',
          ['==', ['slice', ['get', 'feature0'], 0, 20], 'de/blockkennzeichen-'], 2.0,
          1.5,
        ],
        'text-halo-blur': 1,
      },
      layout: {
        'symbol-z-order': 'source',
        'text-field': ['format',
          ['case',
            ['==', ['slice', ['get', 'feature0'], 0, 20], 'de/blockkennzeichen-'], ['get', 'ref_multiline'],
            ['get', 'ref'],
          ], {},
          ['case', ['all', ['!=', ['get', 'ref'], null], ['!=', ['get', 'caption'], null]], '\n', ''], {},
          ['case', ['==', ['get', 'caption'], null], '', ['get', 'caption']], {'text-font': ['literal', ['Noto Sans Italic']]},
        ],
        'text-font': ['Noto Sans Medium'],
        'text-size': 9,
        'text-anchor': ['case',
          ['==', ['slice', ['get', 'feature0'], 0, 20], 'de/blockkennzeichen-'], 'center',
          'top',
        ],
        'text-offset': ['case',
          ['==', ['slice', ['get', 'feature0'], 0, 20], 'de/blockkennzeichen-'], ['literal', [0, 0]],
          ['literal', [0, 1.5]],
        ],
      },
    },
    {
      id: 'railway_signals_deactivated',
      type: 'symbol',
      minzoom: 13,
      source: 'openrailwaymap_signals',
      'source-layer': 'signals_railway_signals',
      filter: ['get', 'deactivated'],
      layout: {
        'symbol-z-order': 'source',
        'icon-overlap': 'always',
        'icon-image': 'general/signal-deactivated',
      }
    },
    {
      id: 'signal_boxes_text_medium',
      type: 'symbol',
      minzoom: 12,
      maxzoom: 15,
      source: 'openrailwaymap_signals',
      'source-layer': 'signals_signal_boxes',
      filter: ['!=', ['get', 'ref'], null],
      paint: {
        'text-color': colors[theme].styles.standard.signalBox.text,
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
          colors[theme].styles.standard.signalBox.halo,
        ],
        'text-halo-width': 1.5,
      },
      layout: {
        'text-field': '{ref}',
        'text-font': ['Noto Sans Bold'],
        'text-size': 11,
        'text-offset': ['literal', [0, 1]],
      }
    },
    {
      id: 'signal_boxes_text_high',
      type: 'symbol',
      minzoom: 15,
      source: 'openrailwaymap_signals',
      'source-layer': 'signals_signal_boxes',
      filter: ['!=', ['get', 'name'], null],
      paint: {
        'text-color': colors[theme].styles.standard.signalBox.text,
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
          colors[theme].styles.standard.signalBox.halo,
        ],
        'text-halo-width': 1.5,
      },
      layout: {
        'text-field': '{name}',
        'text-font': ['Noto Sans Bold'],
        'text-size': 11,
      }
    },
    searchResults,
  ],

  electrification: [
    ...railwayLine(theme,
      ['coalesce', ['get', 'electrification_label'], ''],
      [
        {
          id: 'railway_line_low',
          minzoom: 0,
          maxzoom: 7,
          source: 'openrailwaymap_low',
          states: {
            present: present_dasharray,
          },
          width: ["interpolate", ["exponential", 1.2], ["zoom"],
            0, 0.5,
            7, 2,
          ],
          color: electrificationColor(theme, 'voltage', 'frequency'),
        },
        {
          id: 'railway_line_med',
          minzoom: 7,
          maxzoom: 8,
          source: 'openrailwaymap_low',
          states: {
            present: present_dasharray,
          },
          width: 2,
          color: electrificationColor(theme, 'voltage', 'frequency'),
        },
        {
          id: 'railway_line_high',
          minzoom: 8,
          source: 'high',
          states: {
            present: present_dasharray,
            construction: present_dasharray,
            proposed: present_dasharray,
            disused: present_dasharray,
            abandoned: present_dasharray,
            preserved: present_dasharray,
          },
          width: ["interpolate", ["exponential", 1.2], ["zoom"],
            14, ['match', ['get', 'state'],
              'present', 2,
              1.5,
            ],
            16, ['match', ['get', 'state'],
              'present', 3,
              2,
            ],
          ],
          color: electrificationColor(theme, 'voltage', 'frequency'),
        },
        {
          id: 'railway_line_high_proposed',
          minzoom: 8,
          source: 'high',
          states: {
            present: electrification_proposed_dashes,
            construction: electrification_proposed_dashes,
            proposed: electrification_proposed_dashes,
            disused: electrification_proposed_dashes,
            abandoned: electrification_proposed_dashes,
            preserved: electrification_proposed_dashes,
          },
          filter: ['==', ['get', 'electrification_state'], 'proposed'],
          width: ["interpolate", ["exponential", 1.2], ["zoom"],
            14, ['match', ['get', 'state'],
              'present', 2,
              1.5,
            ],
            16, ['match', ['get', 'state'],
              'present', 3,
              2,
            ],
          ],
          color: electrificationColor(theme, 'future_voltage', 'future_frequency'),
        },
        {
          id: 'railway_line_high_construction',
          minzoom: 8,
          source: 'high',
          states: {
            present: electrification_construction_dashes,
            construction: electrification_construction_dashes,
            proposed: electrification_construction_dashes,
            disused: electrification_construction_dashes,
            abandoned: electrification_construction_dashes,
            preserved: electrification_construction_dashes,
          },
          filter: ['==', ['get', 'electrification_state'], 'construction'],
          width: ["interpolate", ["exponential", 1.2], ["zoom"],
            14, 2,
            16, 3,
          ],
          color: electrificationColor(theme, 'future_voltage', 'future_frequency'),
        },
      ],
    ),
    {
      id: 'electrification_signals_direction',
      type: 'symbol',
      minzoom: 13,
      source: 'openrailwaymap_electrification',
      'source-layer': 'electrification_signals',
      filter: ['all',
        ['!=', ['get', 'azimuth'], null],
        ['!=', ['get', 'feature'], ''],
      ],
      paint: {
        'icon-color': colors[theme].signals.direction,
        'icon-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
          colors[theme].halo,
        ],
        'icon-halo-width': 2.0,
        'icon-halo-blur': 2.0,
      },
      layout: {
        'icon-overlap': 'always',
        'icon-image': ['case',
          ['coalesce', ['get', 'direction_both'], false], 'sdf:general/signal-direction-both',
          'sdf:general/signal-direction',
        ],
        'icon-anchor': ['case',
          ['coalesce', ['get', 'direction_both'], false], 'center',
          'top',
        ],
        'icon-rotate': ['get', 'azimuth'],
        'icon-keep-upright': true,
        'icon-rotation-alignment': 'map',
      },
    },
    ...imageLayerWithOutline(
      theme,
      'electrification_signals',
      ['get', 'feature'],
      {
        type: 'symbol',
        minzoom: 13,
        source: 'openrailwaymap_electrification',
        'source-layer': 'electrification_signals',
        paint: {
          'text-color': colors[theme].text.main,
          'text-halo-color': ['case',
            ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
            colors[theme].halo
          ],
          'text-halo-width': 1.5,
          'text-halo-blur': 1,
        },
        layout: {
          'symbol-z-order': 'source',
          'icon-overlap': 'always',
          'text-field': '{ref}',
          'text-font': ['Noto Sans Medium'],
          'text-size': 9,
          'text-optional': true,
          'text-anchor': 'top',
          'text-offset': ['literal', [0, 1.5]],
        },
      },
    ),
    {
      id: 'electrification_signals_deactivated',
      type: 'symbol',
      minzoom: 15,
      source: 'openrailwaymap_electrification',
      'source-layer': 'electrification_signals',
      filter: ['get', 'deactivated'],
      layout: {
        'symbol-z-order': 'source',
        'icon-overlap': 'always',
        'icon-image': 'general/signal-deactivated',
      }
    },
    {
      id: `electrification_signals_text`,
      type: 'symbol',
      minzoom: 16,
      source: 'openrailwaymap_electrification',
      'source-layer': 'electrification_signals',
      filter: ['any',
        ['!=', ['get', 'ref'], null],
        ['!=', ['get', 'caption'], null],
      ],
      paint: {
        'text-color': colors[theme].text.main,
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
          colors[theme].halo
        ],
        'text-halo-width': 1.5,
        'text-halo-blur': 1,
      },
      layout: {
        'text-field': ['format',
          ['get', 'ref'], {},
          ['case', ['all', ['!=', ['get', 'ref'], null], ['!=', ['get', 'caption'], null]], '\n', ''], {},
          ['case', ['==', ['get', 'caption'], null], '', ['get', 'caption']], {'text-font': ['literal', ['Noto Sans Italic']]},
        ],
        'text-font': ['Noto Sans Medium'],
        'text-size': 9,
        'text-anchor': 'top',
        'text-offset': [0, 1.5],
      },
    },
    searchResults,
  ],

  gauge: [
    ...railwayLine(theme,
      ['coalesce', ['get', 'gauge_label'], ''],
      [
        {
          id: 'railway_line_low',
          minzoom: 0,
          maxzoom: 7,
          source: 'openrailwaymap_low',
          states: {
            present: present_dasharray,
          },
          width: ["interpolate", ["exponential", 1.2], ["zoom"],
            0, 0.5,
            7, 2,
          ],
          color: gaugeColor(theme, 'gauge0', 'gaugeint0'),
        },
        {
          id: 'railway_line_med',
          minzoom: 7,
          maxzoom: 8,
          source: 'openrailwaymap_low',
          states: {
            present: present_dasharray,
          },
          width: 2,
          color: gaugeColor(theme, 'gauge0', 'gaugeint0'),
        },
        {
          id: 'railway_line_high',
          minzoom: 8,
          source: 'high',
          states: {
            present: present_dasharray,
            construction: gauge_construction_dashes,
          },
          width: ["interpolate", ["exponential", 1.2], ["zoom"],
            14, 2,
            16, 3,
          ],
          color: gaugeColor(theme, 'gauge0', 'gaugeint0'),
        },
        {
          id: 'railway_line_high_dual',
          minzoom: 8,
          source: 'high',
          states: {
            present: gauge_dual_gauge_dashes,
            construction: dual_construction_dashes,
          },
          filter: ['!=', ['get', 'gauge1'], null],
          width: ["interpolate", ["exponential", 1.2], ["zoom"],
            14, 2,
            16, 3,
          ],
          color: gaugeColor(theme, 'gauge1', 'gaugeint1'),
        },
        {
          id: 'railway_line_high_multi',
          minzoom: 8,
          source: 'high',
          states: {
            present: gauge_multi_gauge_dashes,
            construction: multi_construction_dashes,
          },
          filter: ['!=', ['get', 'gauge2'], null],
          width: ["interpolate", ["exponential", 1.2], ["zoom"],
            14, 2,
            16, 3,
          ],
          color: gaugeColor(theme, 'gauge2', 'gaugeint2'),
        },
      ],
    ),
    searchResults,
  ],

  loading_gauge: [
    ...railwayLine(theme,
      ['coalesce', ['get', 'loading_gauge'], ''],
      [
        {
          id: 'railway_line_low',
          minzoom: 0,
          maxzoom: 7,
          source: 'openrailwaymap_low',
          states: {
            present: present_dasharray,
          },
          width: ["interpolate", ["exponential", 1.2], ["zoom"],
            0, 0.5,
            7, 2,
          ],
          color: loadingGaugeFillColor,
        },
        {
          id: 'railway_line_med',
          minzoom: 7,
          maxzoom: 8,
          source: 'openrailwaymap_low',
          states: {
            present: present_dasharray,
          },
          width: 2,
          color: loadingGaugeFillColor,
        },
        {
          id: 'railway_line_high',
          minzoom: 8,
          source: 'high',
          states: {
            present: present_dasharray,
            construction: construction_dasharray,
            proposed: proposed_dasharray,
          },
          width: ["interpolate", ["exponential", 1.2], ["zoom"],
            14, 2,
            16, 3,
          ],
          color: loadingGaugeFillColor,
        },
      ],
    ),
    searchResults,
  ],

  track_class: [
    ...railwayLine(theme,
      ['coalesce', ['get', 'track_class'], ''],
      [
        {
          id: 'railway_line_low',
          minzoom: 0,
          maxzoom: 7,
          source: 'openrailwaymap_low',
          states: {
            present: present_dasharray,
          },
          width: ["interpolate", ["exponential", 1.2], ["zoom"],
            0, 0.5,
            7, 2,
          ],
          color: trackClassFillColor,
        },
        {
          id: 'railway_line_med',
          minzoom: 7,
          maxzoom: 8,
          source: 'openrailwaymap_low',
          states: {
            present: present_dasharray,
          },
          width: 2,
          color: trackClassFillColor,
        },
        {
          id: 'railway_line_high',
          minzoom: 8,
          source: 'high',
          states: {
            present: present_dasharray,
            construction: construction_dasharray,
            proposed: proposed_dasharray,
          },
          width: ["interpolate", ["exponential", 1.2], ["zoom"],
            14, 2,
            16, 3,
          ],
          color: trackClassFillColor,
        },
      ],
    ),
    searchResults,
  ],
}]));

const makeStyle = (selectedStyle, theme) => ({
  center: [12.55, 51.14], // default
  zoom: 3.75, // default
  glyphs: `${origin}/font/{fontstack}/{range}`,
  metadata: {},
  name: `OpenRailwayMap ${selectedStyle}`,
  sources,
  sprite: [
    {
      id: 'sdf',
      url: `${origin}/sdf_sprite/symbols`
    },
    {
      id: 'default',
      url: `${origin}/sprite/symbols`
    }
  ],
  version: 8,
  layers: layers[theme][selectedStyle],
});

const legendData = {
  standard: {
    "openrailwaymap_low-railway_line_high": [
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
    ],
    "high-railway_line_high": [
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
              way_length: 1.0,
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
          ref: 'M2',
          standard_label: 'M2 Name',
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
        legend: 'Under construction',
        type: 'line',
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
        }
      },
      {
        legend: 'Proposed railway',
        type: 'line',
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
        }
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
        }
      },
      {
        legend: 'Abandoned railway',
        type: 'line',
        minzoom: 11,
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
        }
      },
      {
        legend: 'Razed railway',
        type: 'line',
        minzoom: 11,
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
        }
      },
    ],
    'standard_railway_text_stations_low-standard_railway_text_stations_low':
      stations.features
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
            legend: variant.legend,
            properties: variant.example,
          })),
        })),
    "standard_railway_text_stations_med-standard_railway_text_stations_med":
      stations.features
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
            legend: variant.legend,
            properties: variant.example,
          })),
        })),
    "openrailwaymap_standard-standard_railway_text_stations":
      stations.features.map(feature => ({
        legend: feature.description,
        type: 'point',
        minzoom: feature.minzoom,
        properties: {
          ...feature.example,
          railway: feature.feature,
        },
        variants: (feature.variants || []).map(variant => ({
          legend: variant.legend,
          properties: variant.example,
        })),
      })),
    "openrailwaymap_standard-standard_railway_grouped_stations": [],
    "openrailwaymap_standard-standard_railway_turntables": [
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
    "openrailwaymap_standard-standard_railway_symbols": [
      ...poi.features.map(feature => ({
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
      }))
    ],
    "high-railway_text_km": [
      {
        legend: 'Milestone',
        type: 'point',
        properties: {
          zero: true,
          pos_int: '47',
          pos: '47.0',
        },
      },
    ],
    "openrailwaymap_standard-standard_railway_switch_ref": [
      {
        legend: 'Switch',
        type: 'point',
        properties: {
          railway: 'switch',
          ref: '123a',
          railway_local_operated: false,
        },
        variants: [
          {
            legend: '(locally operated)',
            type: 'point',
            properties: {
              railway_local_operated: true,
            },
          },
        ]
      },
    ],
  },
  speed: {
    'openrailwaymap_low-railway_line_high': [
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
    'high-railway_line_high': [
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
    "high-railway_text_km": [
      {
        legend: 'Milestone',
        type: 'point',
        properties: {
          zero: true,
          pos_int: '47',
          pos: '47.0',
        },
      },
    ],
    'openrailwaymap_speed-speed_railway_signals': [
      // TODO filter per country polygon
      ...speed_railway_signals.map(feature => ({
        legend: `(${feature.country}) ${feature.description}`,
        type: 'point',
        properties: {
          feature0: feature.icon.default,
          type: 'line',
          azimuth: null,
          deactivated: false,
          direction_both: false,
        },
        variants: (feature.icon.cases ?? []).map(item => ({
          legend: item.description,
          properties: {
            feature0: item.example ?? item.value,
          },
        })),
      })),
      {
        legend: 'signal direction',
        type: 'point',
        properties: {
          feature0: 'does-not-exist',
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
          feature0: 'pl/w21-{40}',
          type: 'line',
          azimuth: null,
          deactivated: true,
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
          deactivated: false,
          direction_both: false,
        },
      })),
    ],
  },
  signals: {
    'openrailwaymap_low-railway_line_high': [
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
          train_protection: null,
          train_protection_rank: 0,
        },
      },
    ],
    'high-railway_line_high': [
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
          train_protection: null,
          train_protection_rank: 0,
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
        },
      },
    ],
    'openrailwaymap_signals-signals_signal_boxes': [
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
    "high-railway_text_km": [
      {
        legend: 'Milestone',
        type: 'point',
        properties: {
          zero: true,
          pos_int: '47',
          pos: '47.0',
        },
      },
    ],
    'openrailwaymap_signals-signals_railway_signals': [
      ...signals_railway_signals.map(feature => ({
        legend: `${feature.country ? `(${feature.country}) ` : ''}${feature.description}`,
        type: 'point',
        properties: {
          feature0: feature.icon.default,
          type: 'line',
          azimuth: null,
          deactivated: false,
          direction_both: false,
        },
        variants: (feature.icon.cases ?? []).map(item => ({
          legend: item.description,
          properties: {
            feature0: item.example ?? item.value,
          },
        })),
      })),
      {
        legend: 'signal direction',
        type: 'point',
        properties: {
          feature0: 'does-not-exist',
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
      // TODO country specific railway signals
      {
        legend: '(deactivated)',
        type: 'point',
        properties: {
          feature0: 'de/ks-combined',
          type: 'line',
          azimuth: null,
          deactivated: true,
          direction_both: false,
        },
      },
      ...signal_types.filter(type => !['speed', 'electrification'].includes(type.layer)).map(type => ({
        legend: `unknown signal (${type.type})`,
        type: 'point',
        properties: {
          feature0: `general/signal-unknown-${type.type}`,
          type: 'line',
          azimuth: null,
          deactivated: false,
          direction_both: false,
        },
      })),
    ],
  },
  electrification: {
    'openrailwaymap_low-railway_line_high': [
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
      ...electrificationLegends.map(({legend, voltage, frequency}) => ({
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
          electrification_state: null,
          voltage: null,
          frequency: null,
        },
      },
    ],
    'high-railway_line_high': [
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
      ...electrificationLegends.map(({legend, voltage, frequency, electrification_label}) => ({
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
          electrification_label,
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
          electrification_state: null,
          voltage: null,
          frequency: null,
          electrification_label: '',
        },
      },
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
          future_voltage: 25000,
          future_frequency: 60,
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
          future_voltage: 25000,
          future_frequency: 60,
          electrification_label: '',
        },
      },
    ],
    "high-railway_text_km": [
      {
        legend: 'Milestone',
        type: 'point',
        properties: {
          zero: true,
          pos_int: '47',
          pos: '47.0',
        },
      },
    ],
    'openrailwaymap_electrification-electrification_signals': [
      ...electrification_signals.map(feature => ({
        legend: `(${feature.country}) ${feature.description}`,
        type: 'point',
        properties: {
          feature: feature.icon.default,
          type: 'line',
          azimuth: null,
          deactivated: false,
          direction_both: false,
        },
        variants: (feature.icon.cases ?? []).map(item => ({
          legend: item.description,
          properties: {
            feature: item.example ?? item.value,
          },
        })),
      })),
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
  gauge: {
    'openrailwaymap_low-railway_line_high': [
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
          gauge0: '3500',
          gaugeint0: 3500,
          label: '3500'
        },
      },
    ],
    'high-railway_line_high': [
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
          gauge0: '3500',
          gaugeint0: 3500,
          gauge_label: '3500'
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
      },
    ],
    "high-railway_text_km": [
      {
        legend: 'Milestone',
        type: 'point',
        properties: {
          zero: true,
          pos_int: '47',
          pos: '47.0',
        },
      },
    ],
  },
  loading_gauge: {
    'openrailwaymap_low-railway_line_high': [
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
      })),
      {
        legend: '(unknown)',
        type: 'line',
        properties: {
          loading_gauge: null,
          feature: 'rail',
          state: 'present',
          usage: 'main',
          service: null,
          bridge: false,
          tunnel: false,
        },
      },
    ],
    'high-railway_line_high': [
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
      })),
      {
        legend: '(unknown)',
        type: 'line',
        properties: {
          loading_gauge: null,
          feature: 'rail',
          state: 'present',
          usage: 'main',
          service: null,
          bridge: false,
          tunnel: false,
        },
      },
    ],
    "high-railway_text_km": [
      {
        legend: 'Milestone',
        type: 'point',
        properties: {
          zero: true,
          pos_int: '47',
          pos: '47.0',
        },
      },
    ],
  },
  track_class: {
    'openrailwaymap_low-railway_line_high': [
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
      })),
      {
        legend: '(unknown)',
        type: 'line',
        properties: {
          track_class: null,
          feature: 'rail',
          state: 'present',
          usage: 'main',
          service: null,
          bridge: false,
          tunnel: false,
        },
      },
    ],
    'high-railway_line_high': [
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
      })),
      {
        legend: '(unknown)',
        type: 'line',
        properties: {
          track_class: null,
          feature: 'rail',
          state: 'present',
          usage: 'main',
          service: null,
          bridge: false,
          tunnel: false,
        },
      },
    ],
    "high-railway_text_km": [
      {
        legend: 'Milestone',
        type: 'point',
        properties: {
          zero: true,
          pos_int: '47',
          pos: '47.0',
        },
      },
    ],
  },
}

const coordinateFactor = legendZoom => Math.pow(2, 5 - legendZoom);

const layerVisibleAtZoom = (zoom) =>
  layer =>
    ((layer.minzoom ?? globalMinZoom) <= zoom) && (zoom < (layer.maxzoom ?? (globalMaxZoom + 1)));

const legendPointToMapPoint = (zoom, [x, y]) =>
  [x * coordinateFactor(zoom), y * coordinateFactor(zoom)]

function makeLegendStyle(style, theme) {
  const sourceStyle = makeStyle(style, theme);
  const sourceLayers = sourceStyle.layers;
  const legendZoomLevels = [...Array(globalMaxZoom - globalMinZoom + 1).keys()].map(zoom => globalMinZoom + zoom);

  const legendLayers = legendZoomLevels.flatMap(legendZoom => {
    const styleZoomLayers = sourceLayers
      .filter(layerVisibleAtZoom(legendZoom))
      .map(layer => ({...layer, layout: layer.layout ?? {}, paint: layer.paint ?? {}}))
      .map(({
              ['source-layer']: sourceLayer,
              source,
              layout: {['text-padding']: textPadding, ['text-offset']: textOffset, ['symbol-spacing']: symbolSpacing, ['symbol-placement']: symbolPlacement, ['icon-offset']: iconOffset, ...layoutRest},
              ...rest
            }) => {
        const resultLayout = {...layoutRest};
        if (symbolPlacement === 'line') {
          resultLayout['symbol-placement'] = 'line-center';
        }

        return {
          ...rest,
          id: `${rest.id}-z${legendZoom}`,
          source: `${source}-${sourceLayer}-z${legendZoom}`,
          minzoom: legendZoom,
          maxzoom: legendZoom + 1,
          layout: resultLayout,
        };
      })

    const legendZoomLayer = {
      type: 'symbol',
      id: `legend-z${legendZoom}`,
      source: `legend-z${legendZoom}`,
      metadata: {
        ['legend:zoom']: legendZoom,
      },
      minzoom: legendZoom,
      maxzoom: legendZoom + 1,
      paint: {
        'text-color': colors[theme].text.main,
        'text-halo-color': colors[theme].halo,
        'text-halo-width': 1,
      },
      layout: {
        'text-field': '{legend}',
        'text-font': ['Noto Sans Medium'],
        'text-size': 11,
        'text-anchor': 'left',
        'text-max-width': 14,
        'text-overlap': 'always',
      },
    };

    return [...styleZoomLayers, legendZoomLayer];
  });

  const usedLegendSources = {};
  legendLayers.forEach(layer => {
    if (!usedLegendSources[layer.minzoom]) {
      usedLegendSources[layer.minzoom] = new Set();
    }
    usedLegendSources[layer.minzoom].add(layer.source)
  })

  const legendSources = Object.fromEntries(
    legendZoomLevels.flatMap(legendZoom => {
      const zoomFilter = layerVisibleAtZoom(legendZoom);

      let entry = 0;
      let done = new Set();

      const featureSourceLayers = sourceLayers.flatMap(layer => {
        const legendLayerName = `${layer.source}-${layer['source-layer']}`;
        const sourceName = `${legendLayerName}-z${legendZoom}`
        const applicable = zoomFilter(layer);
        if (done.has(sourceName) || !usedLegendSources[legendZoom] || !usedLegendSources[legendZoom].has(sourceName) || !applicable) {
          return [];
        }

        const data = applicable ? (legendData[style][legendLayerName] ?? []) : [];
        const features = data
          .filter(zoomFilter)
          .flatMap(item => {
            const itemFeatures = [item, ...(item.variants ?? []).map(subItem => ({...item, ...subItem, properties: {...item.properties, ...subItem.properties}}))].flatMap((subItem, index, subItems) => ({
              type: 'Feature',
              geometry: {
                type: subItem.type === 'line' || subItem.type === 'polygon'
                  ? 'LineString'
                  : 'Point',
                coordinates:
                  subItem.type === 'line' ? [
                    legendPointToMapPoint(legendZoom, [index / subItems.length * 1.5 - 1.5, -entry * 0.6]),
                    legendPointToMapPoint(legendZoom, [(index + 1) / subItems.length * 1.5 - 1.5, -entry * 0.6]),
                  ] :
                  subItem.type === 'polygon' ? Array.from({length: 20 + 1}, (_, i) => i * Math.PI * 2 / 20).map(phi =>
                      legendPointToMapPoint(legendZoom, [Math.cos(phi) * 0.1 + (index + 0.5) / subItems.length * 1.5 - 1.5, Math.sin(phi) * 0.1 - entry * 0.6]))
                    : legendPointToMapPoint(legendZoom, [(index + 0.5) / subItems.length * 1.5 - 1.5, -entry * 0.6]),
              },
              properties: subItem.properties,
            }));
            entry ++;
            return itemFeatures;
          });
        done.add(sourceName);

        return [[sourceName, {
          type: 'geojson',
          data: {
            type: 'FeatureCollection',
            features,
          },
        }]];
      });

      entry = 0;
      done = new Set();

      const legendFeatures = sourceLayers.flatMap(layer => {
        const legendLayerName = `${layer.source}-${layer['source-layer']}`;
        const sourceName = `${legendLayerName}-z${legendZoom}`
        const applicable = layerVisibleAtZoom(legendZoom)(layer);
        if (done.has(sourceName) || !applicable) {
          return [];
        }

        const data = applicable ? (legendData[style][legendLayerName] ?? []) : [];
        const features = data
          .filter(zoomFilter)
          .map(item => {
            const legend = [item.legend, ...(item.variants ?? [])
              .filter(variant => variant.legend)
              .map(variant => variant.legend)]
              .join(', ');

            const feature = {
              type: 'Feature',
              geometry: {
                type: "Point",
                coordinates: legendPointToMapPoint(legendZoom, [0.5, -entry * 0.6]),
              },
              properties: {
                legend,
              },
            };
            entry++;
            return feature;
          });
        done.add(sourceName);

        return features;
      })

      const legendSourceLayer = [`legend-z${legendZoom}`, {
        type: 'geojson',
        data: {
          type: 'FeatureCollection',
          features: legendFeatures,
        },
      }]

      return [...featureSourceLayers, legendSourceLayer];
    })
  );

  legendZoomLevels.forEach(legendZoom => {
    const legendLayer = legendLayers.find(layer => layer.id === `legend-z${legendZoom}`);
    const legendSource = legendSources[`legend-z${legendZoom}`];

    legendLayer.metadata['legend:count'] = legendSource.data.features.length;
  });

  return {
    ...sourceStyle,
    name: `${sourceStyle.name} legend`,
    layers: legendLayers,
    sources: legendSources,
    metadata: {
      name: style,
    }
  };
}

knownStyles.forEach(style => {
  knownThemes.forEach(theme => {
    fs.writeFileSync(`${style}-${theme}.json`, JSON.stringify(makeStyle(style, theme)));
    fs.writeFileSync(`legend-${style}-${theme}.json`, JSON.stringify(makeLegendStyle(style, theme)));
  });
});
