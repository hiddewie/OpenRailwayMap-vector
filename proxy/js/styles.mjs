import fs from 'fs'
import yaml from 'yaml'

const signals_railway_line = yaml.parse(fs.readFileSync('features/train_protection.yaml', 'utf8'))
const all_signals = yaml.parse(fs.readFileSync('features/signals_railway_signals.yaml', 'utf8'))
const loading_gauges = yaml.parse(fs.readFileSync('features/loading_gauge.yaml', 'utf8'))
const track_classes = yaml.parse(fs.readFileSync('features/track_class.yaml', 'utf8'))
const poi = yaml.parse(fs.readFileSync('features/poi.yaml', 'utf8'))
const stations = yaml.parse(fs.readFileSync('features/stations.yaml', 'utf8'))

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
const glodalMaxZoom = 20;

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
        tunnelCover: 'rgba(255, 255, 255, 40%)',
        turntable: {
          fill: '#ababab',
          casing: '#808080',
        },
        stationsText: 'blue',
        yardText: '#87491D',
        tramStopText: '#D877B8',
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
        tramStopText: '#D877B8',
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

const railwayLineWidth =
  // ['step', ['zoom'],
  // 1.5,
  // 5,
  // 1.5,
  // 7,
  // ['case',
  //   ['==', ['get', 'usage'], 'main'], 2.5,
  //   2,
  // ],
  // 8,
  // ['case',
  //   ['all',
  //     ['==', ['get', 'feature'], 'rail'],
  //     ['any',
  //       ['all', ['==', ['get', 'usage'], 'main'], ['==', ['get', 'service'], null]],
  //       ['all', ['==', ['get', 'usage'], 'branch'], ['==', ['get', 'service'], null]],
  //     ]
  //   ], 3.5,
  //   ['all',
  //     ['==', ['get', 'state'], 'construction'],
  //     ['==', ['get', 'feature'], 'rail'],
  //     ['any', ['==', ['get', 'usage'], 'main'], ['==', ['get', 'usage'], 'branch']],
  //     ['==', ['get', 'service'], null],
  //   ],
  //   ['case',
  //     ['!=', ['get', 'service'], null], 1.5,
  //     3,
  //   ],
  //   0,
  // ],
  // 9,
  // ['case',
  //   ['all',
  //     ['==', ['get', 'feature'], 'rail'],
  //     ['==', ['get', 'service'], null],
  //     ['any',
  //       ['==', ['get', 'usage'], 'main'],
  //       ['==', ['get', 'usage'], 'branch'],
  //       ['==', ['get', 'usage'], 'industrial'],
  //       ['==', ['get', 'usage'], 'tourism'],
  //     ]
  //   ],
  //   ['case',
  //     ['all',
  //       ['any',
  //         ['==', ['get', 'usage'], 'industrial'],
  //         ['==', ['get', 'usage'], 'tourism'],
  //       ],
  //       ['==', ['get', 'service'], null],
  //     ], 2,
  //     3.5,
  //   ],
  //   ['all',
  //     ['==', ['get', 'feature'], 'narrow_gauge'],
  //     ['==', ['get', 'service'], null],
  //   ],
  //   ['case',
  //     ['all',
  //       ['any',
  //         ['==', ['get', 'usage'], 'industrial'],
  //         ['==', ['get', 'usage'], 'tourism'],
  //       ],
  //       ['==', ['get', 'service'], null],
  //     ], 2,
  //     3,
  //   ],
  //   ['any',
  //     ['all',
  //       ['==', ['get', 'state'], 'construction'],
  //       ['==', ['get', 'feature'], 'rail'],
  //       ['any', ['==', ['get', 'usage'], 'main'], ['==', ['get', 'usage'], 'branch']],
  //       ['==', ['get', 'service'], null],
  //     ],
  //     ['all',
  //       ['==', ['get', 'state'], 'construction'],
  //       ['any',
  //         ['==', ['get', 'feature'], 'subway'],
  //         ['==', ['get', 'feature'], 'light_rail'],
  //         ['==', ['get', 'feature'], 'monorail'],
  //       ],
  //       ['==', ['get', 'service'], null],
  //     ],
  //     ['all',
  //       ['any',
  //         ['==', ['get', 'feature'], 'subway'],
  //         ['==', ['get', 'feature'], 'light_rail'],
  //         ['==', ['get', 'feature'], 'monorail'],
  //       ],
  //       ['==', ['get', 'service'], null],
  //     ],
  //   ],
  //   ['case',
  //     ['!=', ['get', 'service'], null], 1.5,
  //     3,
  //   ],
  //   0,
  // ],
  // 10,
  // ['case',
  //   ['all',
  //     ['==', ['get', 'feature'], 'rail'],
  //     ['any',
  //       ['all', ['==', ['get', 'usage'], 'main'], ['==', ['get', 'service'], null]],
  //       ['all', ['==', ['get', 'usage'], 'branch'], ['==', ['get', 'service'], null]],
  //       ['==', ['get', 'usage'], 'industrial'],
  //       ['==', ['get', 'usage'], 'tourism'],
  //       ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'siding']],
  //       ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'crossover']],
  //       ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'spur']],
  //     ]
  //   ],
  //   ['case',
  //     ['any',
  //       ['all',
  //         ['any',
  //           ['==', ['get', 'usage'], 'industrial'],
  //           ['==', ['get', 'usage'], 'tourism'],
  //         ],
  //         ['==', ['get', 'service'], null],
  //       ],
  //       ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'siding']],
  //       ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'crossover']],
  //     ], 2,
  //     ['any',
  //       ['all',
  //         ['any',
  //           ['==', ['get', 'usage'], 'industrial'],
  //           ['==', ['get', 'usage'], 'tourism'],
  //         ],
  //         ['!=', ['get', 'service'], null],
  //       ],
  //       ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'spur']],
  //     ], 1.5,
  //     3.5,
  //   ],
  //   ['all',
  //     ['==', ['get', 'feature'], 'narrow_gauge'],
  //     ['any',
  //       ['==', ['get', 'service'], null],
  //       ['==', ['get', 'service'], 'spur'],
  //       ['==', ['get', 'service'], 'siding'],
  //       ['==', ['get', 'service'], 'crossover'],
  //     ],
  //   ],
  //   ['case',
  //     ['all',
  //       ['any',
  //         ['==', ['get', 'usage'], 'industrial'],
  //         ['==', ['get', 'usage'], 'tourism'],
  //       ],
  //       ['==', ['get', 'service'], null],
  //     ], 2,
  //     3,
  //   ],
  //   ['any',
  //     ['all',
  //       ['==', ['get', 'state'], 'construction'],
  //       ['==', ['get', 'feature'], 'rail'],
  //       ['any', ['==', ['get', 'usage'], 'main'], ['==', ['get', 'usage'], 'branch']],
  //       ['==', ['get', 'service'], null],
  //     ],
  //     ['all',
  //       ['==', ['get', 'state'], 'construction'],
  //       ['any',
  //         ['==', ['get', 'feature'], 'subway'],
  //         ['==', ['get', 'feature'], 'light_rail'],
  //         ['==', ['get', 'feature'], 'tram'],
  //         ['==', ['get', 'feature'], 'monorail'],
  //         ['==', ['get', 'feature'], 'miniature'],
  //       ],
  //       ['==', ['get', 'service'], null],
  //     ],
  //     ['all',
  //       ['any',
  //         ['==', ['get', 'feature'], 'subway'],
  //         ['==', ['get', 'feature'], 'light_rail'],
  //         ['==', ['get', 'feature'], 'tram'],
  //         ['==', ['get', 'feature'], 'monorail'],
  //         ['==', ['get', 'feature'], 'miniature'],
  //       ],
  //       ['==', ['get', 'service'], null],
  //     ],
  //   ],
  //   ['case',
  //     ['!=', ['get', 'service'], null], 1.5,
  //     3,
  //   ],
  //   0,
  // ],
  // 11,
  // ['case',
  //   ['all',
  //     ['==', ['get', 'feature'], 'rail'],
  //     ['any',
  //       ['all', ['==', ['get', 'usage'], 'main'], ['==', ['get', 'service'], null]],
  //       ['all', ['==', ['get', 'usage'], 'branch'], ['==', ['get', 'service'], null]],
  //       ['==', ['get', 'usage'], 'industrial'],
  //       ['==', ['get', 'usage'], 'tourism'],
  //       ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'siding']],
  //       ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'crossover']],
  //       ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'spur']],
  //       ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'yard']],
  //     ]
  //   ],
  //   ['case',
  //     ['any',
  //       ['all',
  //         ['any',
  //           ['==', ['get', 'usage'], 'industrial'],
  //           ['==', ['get', 'usage'], 'tourism'],
  //         ],
  //         ['==', ['get', 'service'], null],
  //       ],
  //       ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'siding']],
  //       ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'crossover']],
  //     ], 2,
  //     ['any',
  //       ['all',
  //         ['any',
  //           ['==', ['get', 'usage'], 'industrial'],
  //           ['==', ['get', 'usage'], 'tourism'],
  //         ],
  //         ['!=', ['get', 'service'], null],
  //       ],
  //       ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'spur']],
  //       ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'yard']],
  //     ], 1.5,
  //     3.5,
  //   ],
  //   ['all',
  //     ['==', ['get', 'feature'], 'narrow_gauge'],
  //     ['any',
  //       ['==', ['get', 'service'], null],
  //       ['==', ['get', 'service'], 'spur'],
  //       ['==', ['get', 'service'], 'siding'],
  //       ['==', ['get', 'service'], 'crossover'],
  //       ['==', ['get', 'service'], 'yard'],
  //     ],
  //   ],
  //   ['case',
  //     ['all',
  //       ['any',
  //         ['==', ['get', 'usage'], 'industrial'],
  //         ['==', ['get', 'usage'], 'tourism'],
  //       ],
  //       ['==', ['get', 'service'], null],
  //     ], 2,
  //     3,
  //   ],
  //   ['any',
  //     ['all',
  //       ['==', ['get', 'state'], 'construction'],
  //       ['==', ['get', 'feature'], 'rail'],
  //       ['any', ['==', ['get', 'usage'], 'main'], ['==', ['get', 'usage'], 'branch']],
  //       ['==', ['get', 'service'], null],
  //     ],
  //     ['all',
  //       ['==', ['get', 'state'], 'construction'],
  //       ['any',
  //         ['==', ['get', 'feature'], 'subway'],
  //         ['==', ['get', 'feature'], 'light_rail'],
  //         ['==', ['get', 'feature'], 'tram'],
  //         ['==', ['get', 'feature'], 'monorail'],
  //         ['==', ['get', 'feature'], 'miniature'],
  //       ],
  //       ['==', ['get', 'service'], null],
  //     ],
  //     ['all',
  //       ['any',
  //         ['==', ['get', 'feature'], 'subway'],
  //         ['==', ['get', 'feature'], 'light_rail'],
  //         ['==', ['get', 'feature'], 'tram'],
  //         ['==', ['get', 'feature'], 'monorail'],
  //         ['==', ['get', 'feature'], 'miniature'],
  //       ],
  //       ['==', ['get', 'service'], null],
  //     ],
  //   ],
  //   ['case',
  //     ['!=', ['get', 'service'], null], 1.5,
  //     3,
  //   ],
  //   0,
  // ],
  // 12,


  ['case',
    ['any',
      ['==', ['get', 'state'], 'proposed'],
      ['==', ['get', 'state'], 'razed'],
    ], 1.5,
    ['any',
      ['==', ['get', 'state'], 'disused'],
      ['==', ['get', 'state'], 'abandoned'],
    ], 2,
    ['all',
      ['==', ['get', 'service'], null],
      ['==', ['get', 'usage'], 'main'],
    ], 3.5,
    ['all',
      ['==', ['get', 'service'], null],
      ['any',
        ['==', ['get', 'usage'], 'branch'],
        ['==', ['get', 'feature'], 'tram'],
        ['==', ['get', 'feature'], 'subway'],
        ['==', ['get', 'feature'], 'light_rail'],
      ],
    ], 3,
    ['==', ['get', 'service'], null], 2.5,
    2,

    // ['any',
    //   ['all',
    //     ['any',
    //       ['==', ['get', 'usage'], 'main'],
    //       ['==', ['get', 'usage'], 'branch'],
    //     ],
    //   ],
    //   ['all',
    //     ['==', ['get', 'service'], null],
    //     ['any',
    //       ['==', ['get', 'usage'], 'industrial'],
    //       ['==', ['get', 'tourism'], 'industrial'],
    //       ['==', ['get', 'military'], 'industrial'],
    //       ['==', ['get', 'test'], 'industrial'],
    //     ],
    //   ],
    // ], 2,



    // ['all',
    //   ['==', ['get', 'feature'], 'rail'],
    //   ['any',
    //     ['all', ['==', ['get', 'usage'], 'main'], ['==', ['get', 'service'], null]],
    //     ['all', ['==', ['get', 'usage'], 'branch'], ['==', ['get', 'service'], null]],
    //     ['==', ['get', 'usage'], 'industrial'],
    //     ['==', ['get', 'usage'], 'tourism'],
    //     ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'siding']],
    //     ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'crossover']],
    //     ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'spur']],
    //     ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'yard']],
    //     ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], null]],
    //   ]
    // ],
    // ['case',
    //   ['any',
    //     ['all',
    //       ['any',
    //         ['==', ['get', 'usage'], 'industrial'],
    //         ['==', ['get', 'usage'], 'tourism'],
    //       ],
    //       ['==', ['get', 'service'], null],
    //     ],
    //     ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'siding']],
    //     ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'crossover']],
    //     ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], null]],
    //   ], 2,
    //   ['any',
    //     ['all',
    //       ['any',
    //         ['==', ['get', 'usage'], 'industrial'],
    //         ['==', ['get', 'usage'], 'tourism'],
    //       ],
    //       ['!=', ['get', 'service'], null],
    //     ],
    //     ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'spur']],
    //     ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'yard']],
    //   ], 1.5,
    //   3.5,
    // ],
    // ['all',
    //   ['==', ['get', 'feature'], 'narrow_gauge'],
    //   ['any',
    //     ['==', ['get', 'service'], null],
    //     ['==', ['get', 'service'], 'spur'],
    //     ['==', ['get', 'service'], 'siding'],
    //     ['==', ['get', 'service'], 'crossover'],
    //     ['==', ['get', 'service'], 'yard'],
    //   ],
    // ],
    // ['case',
    //   ['all',
    //     ['any',
    //       ['==', ['get', 'usage'], 'industrial'],
    //       ['==', ['get', 'usage'], 'tourism'],
    //     ],
    //     ['==', ['get', 'service'], null],
    //   ], 2,
    //   3,
    // ],
    // ['any',
    //   ['all',
    //     ['==', ['get', 'state'], 'construction'],
    //     ['==', ['get', 'feature'], 'rail'],
    //     ['any', ['==', ['get', 'usage'], 'main'], ['==', ['get', 'usage'], 'branch']],
    //     ['==', ['get', 'service'], null],
    //   ],
    //   ['all',
    //     ['==', ['get', 'state'], 'construction'],
    //     ['any',
    //       ['==', ['get', 'feature'], 'subway'],
    //       ['==', ['get', 'feature'], 'light_rail'],
    //       ['==', ['get', 'feature'], 'tram'],
    //       ['==', ['get', 'feature'], 'narrow_gauge'],
    //       ['==', ['get', 'feature'], 'monorail'],
    //       ['==', ['get', 'feature'], 'miniature'],
    //     ],
    //     ['==', ['get', 'service'], null],
    //   ],
    //   ['any',
    //     ['==', ['get', 'feature'], 'subway'],
    //     ['==', ['get', 'feature'], 'light_rail'],
    //     ['==', ['get', 'feature'], 'tram'],
    //     ['==', ['get', 'feature'], 'monorail'],
    //     ['==', ['get', 'feature'], 'miniature'],
    //   ],
    // ],
    // ['case',
    //   ['!=', ['get', 'service'], null], 1.5,
    //   3,
    // ],
    // 1.5, // 1.5,
  // ],
];
const trainProtectionCasingPaint = (theme, dashArray) => ({
  'line-color': colors[theme].casing,
  'line-width': railwayLineWidth,
  'line-gap-width': 1,
  'line-dasharray': dashArray,
});
const trainProtectionLayout = {
  'line-sort-key': ['get', 'train_protection_rank'],
  'line-join': 'round',
  'line-cap': 'round',
};
const trainProtectionColor = theme => ['case',
  ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.main,
  ...signals_railway_line.train_protections.flatMap(train_protection =>
    [['==', ['get', 'train_protection'], train_protection.train_protection], train_protection.color]),
  'grey',
];
const trainProtectionFillPaint = (theme, dashArray) => ({
  'line-color': trainProtectionColor(theme),
  'line-width': railwayLineWidth,
  'line-dasharray': dashArray,
});

const railway_casing_add = 1;

/* additional width of the casing of dashed lines */
const railway_tunnel_casing_add = 1;
const bridge_casing_add = 4;

// TODO move to variable
const present_dasharray = [1];
const abandoned_dasharray = [2.5, 2.5];
const disused_dasharray = [2.5, 2.5];
const razed_dasharray = [1.5, 3.5];
const construction_dasharray = [4.5, 4.5];
const proposed_dasharray = [1, 4];

const standardLowFillPaint = theme => ({
  'line-color': ['case',
    ['boolean', ['feature-state', 'hover'], false], ['case',
      ['get', 'highspeed'], colors[theme].hover.alternative,
      colors[theme].hover.main,
    ],
    ['==', ['get', 'usage'], 'branch'], colors[theme].styles.standard.branch,
    ['get', 'highspeed'], colors[theme].styles.standard.highspeed,
    colors[theme].styles.standard.main,
  ],
  'line-width': railwayLineWidth,
});
const standardMediumFillPaint = theme => ({
  'line-color': ['case',
    ['boolean', ['feature-state', 'hover'], false], ['case',
      ['get', 'highspeed'], colors[theme].hover.alternative,
      colors[theme].hover.main,
    ],
    ['==', ['get', 'usage'], 'branch'], colors[theme].styles.standard.branch,
    ['get', 'highspeed'], colors[theme].styles.standard.highspeed,
    colors[theme].styles.standard.main,
  ],
  'line-width': railwayLineWidth,
});
const standardColor = theme => ['case',
  ['boolean', ['feature-state', 'hover'], false], ['case',
    ['all', ['==', ['get', 'usage'], 'main'], ['get', 'highspeed']], colors[theme].hover.alternative,
    colors[theme].hover.main,
  ],
  ['==', ['get', 'state'], 'disused'], colors[theme].styles.standard.disused,
  ['==', ['get', 'state'], 'abandoned'], colors[theme].styles.standard.abandoned,
  ['==', ['get', 'state'], 'razed'], colors[theme].styles.standard.razed,
  ['==', ['get', 'state'], 'preserved'], colors[theme].styles.standard.tourism,
  ['==', ['get', 'feature'], 'rail'],
  ['case',
    ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'spur']], colors[theme].styles.standard.spur,
    ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'yard']], colors[theme].styles.standard.yard,
    ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'crossover']], colors[theme].styles.standard.siding,
    ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'siding']], colors[theme].styles.standard.siding,
    ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], null]], colors[theme].styles.standard.no_usage,
    ['==', ['get', 'usage'], 'industrial'], colors[theme].styles.standard.industrial,
    ['==', ['get', 'usage'], 'tourism'], colors[theme].styles.standard.tourism,
    ['==', ['get', 'usage'], 'branch'], colors[theme].styles.standard.branch,
    ['all', ['==', ['get', 'usage'], 'main'], ['get', 'highspeed']], colors[theme].styles.standard.highspeed,
    ['==', ['get', 'usage'], 'main'], colors[theme].styles.standard.main,
    colors[theme].styles.standard.unknown,
  ],
  ['==', ['get', 'feature'], 'narrow_gauge'],
  ['case',
    ['all', ['==', ['get', 'usage'], 'industrial'], ['==', ['get', 'service'], 'spur']], colors[theme].styles.standard.industrial,
    colors[theme].styles.standard.narrowGauge,
  ],
  ['==', ['get', 'feature'], 'subway'], colors[theme].styles.standard.subway,
  ['==', ['get', 'feature'], 'light_rail'], colors[theme].styles.standard.light_rail,
  ['==', ['get', 'feature'], 'tram'], colors[theme].styles.standard.tram,
  colors[theme].styles.standard.unknown,
]
const standardFillPaint = (theme, dashArray) => ({
  'line-color': standardColor(theme),
  'line-width': railwayLineWidth,
  'line-dasharray': dashArray,
});
const speedCasingPaint = theme => ({
  'line-color': colors[theme].casing,
  'line-width': railwayLineWidth,
  'line-gap-width': 1,
});
const speedLayout = {
  'line-join': 'round',
  'line-cap': 'round',
};

const minSpeed = 10
const maxSpeed = 380
const startHue = 248
const endHue = 284;

const speedColor = theme => ['case',
  ['boolean', ['feature-state', 'hover'], false], ['case',
    ['all', ['!=', ['get', 'maxspeed'], null],  ['>=', ['get', 'maxspeed'], 260], ['<=', ['get', 'maxspeed'], 300]], colors[theme].hover.alternative,
    colors[theme].hover.main,
  ],
  ['==', ['get', 'maxspeed'], null], 'gray',
  // Reverse hue order
  ['concat', 'hsl(', ['%', ['+', ['-', startHue, ['*', startHue + (360 - endHue), ['/', ['-', ['max', minSpeed, ['min', ['get', 'maxspeed'], maxSpeed]], minSpeed], maxSpeed - minSpeed]]], 360], 360], ', 100%, 40%)'],
]

const speedFillPaint = theme => ({
  'line-color': speedColor(theme),
  'line-width': railwayLineWidth,
});

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

const electrificationCasingPaint = theme => ({
  'line-color': colors[theme].casing,
  'line-width': railwayLineWidth,
  'line-gap-width': 0.75,
});
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
  ['==', ['get', 'electrification_state'], 'no'], color_no,
  'gray',
];
const electrificationFillPaint = (theme, dashArray, voltageProperty, frequencyProperty) => ({
  'line-color': electrificationColor(theme, voltageProperty, frequencyProperty),
  'line-width': railwayLineWidth,
  'line-dasharray': dashArray,
});
const electrificationLayout = {
  'line-join': 'round',
  'line-cap': 'round',
};

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

const gaugeCasingPaint = theme => ({
  'line-color': colors[theme].casing,
  'line-width': railwayLineWidth,
  'line-gap-width': 0.75,
});

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
const gaugeFillPaint = (theme, gaugeProperty, gaugeIntProperty, dashArray) => ({
  'line-color': gaugeColor(theme, gaugeProperty, gaugeIntProperty),
  'line-width': railwayLineWidth,
  'line-dasharray': dashArray,
});
const gaugeLayout = {
  'line-join': 'round',
  'line-cap': 'round',
};

const loadingGaugeCasingPaint = theme => ({
  'line-color': colors[theme].casing,
  'line-width': railwayLineWidth,
  'line-gap-width': 0.75,
});
const loadingGaugeFillColor = ['match', ['get', 'loading_gauge'],
  ...loading_gauges.loading_gauges.flatMap(loading_gauge =>
    [loading_gauge.value, loading_gauge.color]
  ),
  'gray',
];
const loadingGaugeFillPaint = (theme, dashArray) => ({
  'line-color': loadingGaugeFillColor,
  'line-width': railwayLineWidth,
  'line-dasharray': dashArray,
});
const loadingGaugeLayout = {
  'line-join': 'round',
  'line-cap': 'round',
};

const trackClassCasingPaint = theme => ({
  'line-color': colors[theme].casing,
  'line-width': railwayLineWidth,
  'line-gap-width': 0.75,
});
const trackClassFillColor = ['match', ['get', 'track_class'],
  ...track_classes.track_classes.flatMap(track_class =>
    [track_class.value, track_class.color]
  ),
  'gray',
];
const trackClassFillPaint = (theme, dashArray) => ({
  'line-color': trackClassFillColor,
  'line-width': railwayLineWidth,
  'line-dasharray': dashArray,
});
const trackClassLayout = {
  'line-join': 'round',
  'line-cap': 'round',
};

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
  // TODO merge with low
  openrailwaymap_med: {
    type: 'vector',
    url: `${origin}/railway_line_high`,
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
  }
};

const railwayLine = (theme, layers) => [
  ...layers.flatMap(({id, minzoom, maxzoom, source, filter, width, states}) =>
    Object.entries(states).map(([state, dash]) => ({
      id: `${id}_casing_${state}`,
      type: 'line',
      minzoom,
      maxzoom,
      source,
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['==', ['get', 'state'], state],
        filter ?? true,
      ],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: {
        'line-color': colors[theme].casing,
        'line-width': width,
        'line-gap-width': railway_casing_add,
        'line-dasharray': dash,
      }
    }))
  ),
  ...layers.flatMap(( {id, minzoom, maxzoom, source, filter, width, color, hoverColor, states}) => [
    ...Object.entries(states).map(([state, dash]) => ({
      id: `${id}_fill_${state}`,
      type: 'line',
      minzoom,
      maxzoom,
      source,
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['==', ['get', 'state'], state],
        filter ?? true,
      ],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: {
        'line-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], hoverColor || colors[theme].hover.main,
          color,
        ],
        'line-width': width,
        'line-dasharray': dash,
      }
    })),
    preferredDirectionLayer(theme, `${id}_preferred_direction`,
      ['all',
        ['!', ['get', 'bridge']],
        ['!', ['get', 'tunnel']],
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
  ]),
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
    ...railwayLine(theme, [
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
        source: 'openrailwaymap_med',
        states: {
          present: present_dasharray,
          construction: construction_dasharray,
          proposed: proposed_dasharray,
        },
        filter:  ['==', ['get', 'usage'], 'main'],
        width: ["interpolate", ["exponential", 1.2], ["zoom"],
          7, 2,
          8, 2,
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
      {
        id: 'railway_line_branch_med',
        minzoom: 7,
        maxzoom: 8,
        source: 'openrailwaymap_med',
        states: {
          present: present_dasharray,
          construction: construction_dasharray,
          proposed: proposed_dasharray,
        },
        filter:  ['==', ['get', 'usage'], 'branch'],
        width: ["interpolate", ["exponential", 1.2], ["zoom"],
          7, 2,
          8, 2,
        ],
        color: colors[theme].styles.standard.branch,
      },

      // High zooms
      // ensure that width interpolation matches medium zooms

      // TODO split service null/non-null

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
          8, ['case',
            ['==', ['get', 'service'], null], 2,
            0,
          ],
          10, 2,
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
        ],
        color: colors[theme].styles.standard.branch,
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
            ['all',
              ['==', ['get', 'feature'], 'rail'],
            ],
            ['all',
              ['==', ['get', 'feature'], 'narrow_gauge'],
              ['==', ['get', 'service'], 'spur'],
            ],
          ],
        ],
        width: ["interpolate", ["exponential", 1.2], ["zoom"],
          8, 1.5,
        ],
        color: colors[theme].styles.standard.industrial,
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
        width: ["interpolate", ["exponential", 1.2], ["zoom"],
          8, 2,
        ],
        color: colors[theme].styles.standard.tourism,
      },
      {
        id: 'railway_line_military',
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
        ],
        color: ['match', ['get', 'usage'],
          'test', colors[theme].styles.standard.test,
          'military', colors[theme].styles.standard.military,
          colors[theme].styles.standard.unknown,
        ],
      },
      {
        id: 'railway_line_subway',
        minzoom: 9,
        source: 'high',
        states: {
          present: present_dasharray,
          construction: construction_dasharray,
          proposed: proposed_dasharray,
        },
        filter: ['all',
          ['==', ['get', 'feature'], 'subway'],
        ],
        width: ["interpolate", ["exponential", 1.2], ["zoom"],
          8, 2,
        ],
        color: colors[theme].styles.standard.subway,
      },
      {
        id: 'railway_line_light_mono_rail',
        minzoom: 9,
        source: 'high',
        states: {
          present: present_dasharray,
          construction: construction_dasharray,
          proposed: proposed_dasharray,
        },
        filter: ['all',
          ['any',
            ['==', ['get', 'feature'], 'light_rail'],
            ['==', ['get', 'feature'], 'monorail'],
          ],
        ],
        width: ["interpolate", ["exponential", 1.2], ["zoom"],
          8, 2,
        ],
        color: ['match', ['get', 'feature'],
          'light_rail', colors[theme].styles.standard.light_rail,
          'monorail', colors[theme].styles.standard.monorail,
          colors[theme].styles.standard.unknown,
        ],
      },
      {
        id: 'railway_line_tram',
        minzoom: 10,
        source: 'high',
        states: {
          present: present_dasharray,
          construction: construction_dasharray,
          proposed: proposed_dasharray,
        },
        filter: ['all',
          ['==', ['get', 'feature'], 'tram'],
        ],
        width: ["interpolate", ["exponential", 1.2], ["zoom"],
          8, 2,
        ],
        color: colors[theme].styles.standard.tram,
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
          8, 2,
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
            ['all',
              ['==', ['get', 'usage'], 'industrial'],
              ['==', ['get', 'service'], 'spur'],
            ],
          ],
        ],
        width: ["interpolate", ["exponential", 1.2], ["zoom"],
          8, 2,
        ],
        color: colors[theme].styles.standard.narrowGauge,
      },
      {
        id: 'railway_line_disused',
        minzoom: 11,
        source: 'high',
        states: {
          disused: disused_dasharray,
        },
        width: ["interpolate", ["exponential", 1.2], ["zoom"],
          8, 1.5,
        ],
        color: colors[theme].styles.standard.disused,
      },
      {
        id: 'railway_line_abandoned',
        minzoom: 11,
        source: 'high',
        states: {
          abandoned: abandoned_dasharray,
        },
        width: ["interpolate", ["exponential", 1.2], ["zoom"],
          8, 1.5,
        ],
        color: colors[theme].styles.standard.abandoned,
      },
      {
        id: 'railway_line_razed',
        minzoom: 11,
        source: 'high',
        states: {
          razed: razed_dasharray,
        },
        width: ["interpolate", ["exponential", 1.2], ["zoom"],
          8, 1.5,
        ],
        color: colors[theme].styles.standard.razed,
      },
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
        width: ["interpolate", ["exponential", 1.2], ["zoom"],
          8, 2,
        ],
        color: colors[theme].styles.standard.miniature,
      },
    ]),
    {
      id: 'railway_text_stations_low',
      type: 'symbol',
      minzoom: 5,
      maxzoom: 7,
      source: 'standard_railway_text_stations_low',
      'source-layer': 'standard_railway_text_stations_low',
      paint: {
        'text-color': colors[theme].styles.standard.stationsText,
        'text-halo-color': colors[theme].halo,
        'text-halo-width': 1.5,
      },
      layout: {
        'symbol-z-order': 'source',
        'text-field': '{label}',
        'text-font': ['Noto Sans Bold'],
        'text-size': 11,
        'text-padding': 30,
        'text-max-width': 5,
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
        'text-halo-color': colors[theme].halo,
        'text-halo-width': 1.5,
      },
      layout: {
        'symbol-z-order': 'source',
        'text-field': '{label}',
        'text-font': ['Noto Sans Bold'],
        'text-size': 11,
        'text-padding': 10,
        'text-max-width': 5,
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
          colors[theme].styles.standard.main,
        ],
        'fill-opacity': ['case',
          ['boolean', ['feature-state', 'hover'], false], 0.3,
          0.2,
        ],
      },
    },
    // TODO tunnels
    {
      id: 'railway_tunnel_casing',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['get', 'tunnel'],
        ['!=', ['get', 'state'], 'construction'],
        ['!=', ['get', 'state'], 'proposed'],
        ['!=', ['get', 'state'], 'abandoned'],
        ['!=', ['get', 'state'], 'razed'],
      ],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: {
        'line-color': colors[theme].casing,
        'line-width': railwayLineWidth,
        'line-gap-width': railway_tunnel_casing_add,
      }
    },
    // {
    //   id: 'railway_line_casing',
    //   type: 'line',
    //   minzoom: 8,
    //   source: 'high',
    //   'source-layer': 'railway_line_high',
    //   filter: ['all',
    //     ['!', ['get', 'bridge']],
    //     ['!', ['get', 'tunnel']],
    //     ['!=', ['get', 'state'], 'construction'],
    //     ['!=', ['get', 'state'], 'proposed'],
    //     ['!=', ['get', 'state'], 'abandoned'],
    //     ['!=', ['get', 'state'], 'razed'],
    //   ],
    //   layout: {
    //     'line-join': 'round',
    //     'line-cap': 'round',
    //   },
    //   paint: {
    //     'line-color': colors[theme].casing,
    //     'line-width': railwayLineWidth,
    //     'line-gap-width': railway_casing_add,
    //   }
    // },
    // {
    //   id: 'railway_line_construction_casing',
    //   type: 'line',
    //   minzoom: 8,
    //   source: 'high',
    //   'source-layer': 'railway_line_high',
    //   filter: ['==', ['get', 'state'], 'construction'],
    //   layout: {
    //     'line-join': 'round',
    //     'line-cap': 'round',
    //   },
    //   paint: {
    //     'line-color': colors[theme].casing,
    //     'line-width': railwayLineWidth,
    //     'line-gap-width': railway_casing_add,
    //     'line-dasharray': construction_dasharray,
    //   }
    // },
    // {
    //   id: 'railway_line_proposed_casing',
    //   type: 'line',
    //   minzoom: 8,
    //   source: 'high',
    //   'source-layer': 'railway_line_high',
    //   filter: ['==', ['get', 'state'], 'proposed'],
    //   layout: {
    //     'line-join': 'round',
    //     'line-cap': 'round',
    //   },
    //   paint: {
    //     'line-color': colors[theme].casing,
    //     'line-width': railwayLineWidth,
    //     'line-gap-width': railway_casing_add,
    //     'line-dasharray': proposed_dasharray,
    //   }
    // },
    // {
    //   id: 'railway_line_abandoned_casing',
    //   type: 'line',
    //   minzoom: 8,
    //   source: 'high',
    //   'source-layer': 'railway_line_high',
    //   filter: ['==', ['get', 'state'], 'abandoned'],
    //   layout: {
    //     'line-join': 'round',
    //     'line-cap': 'round',
    //   },
    //   paint: {
    //     'line-color': colors[theme].casing,
    //     'line-width': railwayLineWidth,
    //     'line-gap-width': railway_casing_add,
    //     'line-dasharray': abandoned_dasharray,
    //   }
    // },
    // {
    //   id: 'railway_line_razed_casing',
    //   type: 'line',
    //   minzoom: 8,
    //   source: 'high',
    //   'source-layer': 'railway_line_high',
    //   filter: ['==', ['get', 'state'], 'razed'],
    //   layout: {
    //     'line-join': 'round',
    //     'line-cap': 'round',
    //   },
    //   paint: {
    //     'line-color': colors[theme].casing,
    //     'line-width': railwayLineWidth,
    //     'line-gap-width': railway_casing_add,
    //     'line-dasharray': razed_dasharray,
    //   }
    // },
    {
      id: 'railway_tunnel_fill',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['get', 'tunnel'],
        ['!=', ['get', 'state'], 'construction'],
        ['!=', ['get', 'state'], 'proposed'],
        ['!=', ['get', 'state'], 'abandoned'],
        ['!=', ['get', 'state'], 'razed'],
      ],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: standardFillPaint(theme, [1]),
    },
    {
      id: 'railway_tunnel_cover',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['get', 'tunnel'],
        ['!=', ['get', 'state'], 'construction'],
        ['!=', ['get', 'state'], 'proposed'],
        ['!=', ['get', 'state'], 'abandoned'],
        ['!=', ['get', 'state'], 'razed'],
      ],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: {
        ...standardFillPaint(theme, [1]),
        'line-color': colors[theme].styles.standard.tunnelCover,
      }
    },
    preferredDirectionLayer(theme, 'railway_tunnel_preferred_direction',
      ['all',
        ['get', 'tunnel'],
        ['any',
          ['==', ['get', 'preferred_direction'], 'forward'],
          ['==', ['get', 'preferred_direction'], 'backward'],
          ['==', ['get', 'preferred_direction'], 'both'],
        ],
      ],
      standardColor(theme),
    ),
    // {
    //   id: 'railway_construction_fill',
    //   type: 'line',
    //   minzoom: 8,
    //   source: 'high',
    //   'source-layer': 'railway_line_high',
    //   filter: ['==', ['get', 'state'], 'construction'],
    //   layout: {
    //     'line-join': 'round',
    //     'line-cap': 'round',
    //   },
    //   paint: standardFillPaint(theme, construction_dasharray),
    // },
    // {
    //   id: 'railway_proposed_fill',
    //   type: 'line',
    //   minzoom: 8,
    //   source: 'high',
    //   'source-layer': 'railway_line_high',
    //   filter: ['==', ['get', 'state'], 'proposed'],
    //   layout: {
    //     'line-join': 'round',
    //     'line-cap': 'round',
    //   },
    //   paint: standardFillPaint(theme, proposed_dasharray),
    // },
    // {
    //   id: 'railway_abandoned_fill',
    //   type: 'line',
    //   minzoom: 8,
    //   source: 'high',
    //   'source-layer': 'railway_line_high',
    //   filter: ['==', ['get', 'state'], 'abandoned'],
    //   layout: {
    //     'line-join': 'round',
    //     'line-cap': 'round',
    //   },
    //   paint: standardFillPaint(theme, abandoned_dasharray),
    // },
    // {
    //   id: 'railway_razed_fill',
    //   type: 'line',
    //   minzoom: 8,
    //   source: 'high',
    //   'source-layer': 'railway_line_high',
    //   filter: ['==', ['get', 'state'], 'razed'],
    //   layout: {
    //     'line-join': 'round',
    //     'line-cap': 'round',
    //   },
    //   paint: standardFillPaint(theme, razed_dasharray),
    // },
    // {
    //   id: 'railway_line_fill',
    //   type: 'line',
    //   minzoom: 8,
    //   source: 'high',
    //   'source-layer': 'railway_line_high',
    //   filter: ['all',
    //     ['!', ['get', 'bridge']],
    //     ['!', ['get', 'tunnel']],
    //     ['!=', ['get', 'state'], 'construction'],
    //     ['!=', ['get', 'state'], 'proposed'],
    //     ['!=', ['get', 'state'], 'abandoned'],
    //     ['!=', ['get', 'state'], 'razed'],
    //   ],
    //   layout: {
    //     'line-join': 'round',
    //     'line-cap': 'round',
    //   },
    //   paint: standardFillPaint(theme, [1]),
    // },
    preferredDirectionLayer(theme, 'railway_preferred_direction',
      ['all',
        ['!', ['get', 'bridge']],
        ['!', ['get', 'tunnel']],
        ['any',
          ['==', ['get', 'preferred_direction'], 'forward'],
          ['==', ['get', 'preferred_direction'], 'backward'],
          ['==', ['get', 'preferred_direction'], 'both'],
        ]
      ],
      standardColor(theme),
    ),
    {
      id: 'railway_bridge_railing',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['get', 'bridge'],
        ['>=', ['get', 'way_length'],
          ['interpolate', ["exponential", .5], ['zoom'],
            8, 0.008,
            16, 0
          ],
        ],
        ['!=', ['get', 'state'], 'construction'],
        ['!=', ['get', 'state'], 'proposed'],
        ['!=', ['get', 'state'], 'abandoned'],
        ['!=', ['get', 'state'], 'razed'],
      ],
      paint: {
        'line-color': colors[theme].styles.standard.casing.bridge,
        'line-width': railwayLineWidth,
        'line-gap-width': bridge_casing_add,
      }
    },
    {
      id: 'railway_bridge_casing',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['get', 'bridge'],
        ['>=', ['get', 'way_length'],
          ['interpolate', ["exponential", .5], ['zoom'],
            8, 0.008,
            16, 0
          ],
        ],
        ['!=', ['get', 'state'], 'construction'],
        ['!=', ['get', 'state'], 'proposed'],
        ['!=', ['get', 'state'], 'abandoned'],
        ['!=', ['get', 'state'], 'razed'],
      ],
      paint: {
        'line-color': colors[theme].casing,
        'line-width': railwayLineWidth,
        'line-gap-width': railway_casing_add,
      }
    },
    {
      id: 'railway_bridge_fill',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['get', 'bridge'],
        ['!=', ['get', 'state'], 'construction'],
        ['!=', ['get', 'state'], 'proposed'],
        ['!=', ['get', 'state'], 'abandoned'],
        ['!=', ['get', 'state'], 'razed'],
      ],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: standardFillPaint(theme, [1]),
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
    {
      id: 'railway_symbols_tram_stop',
      type: 'symbol',
      minzoom: 12,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_symbols',
      filter: ['==', ['get', 'feature'], 'general/tram-stop'],
      layout: {
        'icon-overlap': 'always',
        'icon-image': 'general/tram-stop',
      }
    },
    ...imageLayerWithOutline(
      theme,
      'railway_symbols_low',
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
      'railway_symbols_med_high',
      ['get', 'feature'],
      {
        type: 'symbol',
        minzoom: 13,
        source: 'openrailwaymap_standard',
        'source-layer': 'standard_railway_symbols',
        filter: ['any',
          ['==', ['get', 'feature'], 'general/crossing'],
          ['==', ['get', 'feature'], 'general/level-crossing'],
          ['==', ['get', 'feature'], 'general/level-crossing-light'],
          ['==', ['get', 'feature'], 'general/level-crossing-barrier'],
          ['==', ['get', 'feature'], 'general/lubricator'],
          ['==', ['get', 'feature'], 'general/fuel'],
          ['==', ['get', 'feature'], 'general/sand_store'],
          ['==', ['get', 'feature'], 'general/aei'],
          ['==', ['get', 'feature'], 'general/buffer_stop'],
          ['==', ['get', 'feature'], 'general/derail'],
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
        ],
        layout: {
          'symbol-z-order': 'source',
          'icon-overlap': 'always',
        },
      },
    ),
    ...imageLayerWithOutline(
      theme,
      'railway_symbols_med',
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
      'railway_symbols_high',
      ['get', 'feature'],
      {
        type: 'symbol',
        minzoom: 16,
        source: 'openrailwaymap_standard',
        'source-layer': 'standard_railway_symbols',
        filter: ['==', ['get', 'feature'], 'general/phone'],
        layout: {
          'symbol-z-order': 'source',
          'icon-overlap': 'always',
        },
      },
    ),
    railwayKmText(theme),
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
      id: 'railway_text',
      type: 'symbol',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['!=', ['get', 'standard_label'], null],
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
        'text-field': ['step', ['zoom'],
          ['get', 'ref'],
          14,
          ['get', 'standard_label'],
        ],
        'text-font': ['Noto Sans Bold'],
        'text-size': 11,
        'text-padding': 10,
        'text-max-width': 5,
        'symbol-spacing': 200,
      },
    },
    {
      id: 'railway_switch_ref',
      type: 'symbol',
      minzoom: 15,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_switch_ref',
      paint: {
        'text-color': colors[theme].text.main,
        'text-halo-color': ['case',
          // Invert coloring on hover
          ['boolean', ['feature-state', 'hover'], false], ['case',
            ['get', 'railway_local_operated'], 'white',
            colors[theme].hover.textHalo,
          ],
          ['get', 'railway_local_operated'], 'yellow',
          colors[theme].halo
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
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_text_stations',
      filter: ['step', ['zoom'],
        ['all',
          ['==', ['get', 'railway'], 'station'],
          ['!=', ['get', 'station'], 'light_rail'],
          ['!=', ['get', 'station'], 'subway'],
          ['!=', ['get', 'station'], 'funicular'],
        ],
        9,
        ['all',
          ['any',
            ['==', ['get', 'railway'], 'station'],
            ['==', ['get', 'railway'], 'halt'],
          ],
          ['!=', ['get', 'railway'], 'tram_stop'],
          ['!=', ['get', 'station'], 'funicular'],
        ],
        10,
        ['all',
          ['!=', ['get', 'railway'], 'tram_stop'],
          ['!=', ['get', 'station'], 'funicular'],
        ],
      ],
      paint: {
        'text-color': ['case',
          ['==', ['get', 'railway'], 'yard'], colors[theme].styles.standard.yardText,
          ['==', ['get', 'railway'], 'station'], colors[theme].styles.standard.stationsText,
          ['==', ['get', 'railway'], 'halt'], colors[theme].styles.standard.stationsText,
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
          ['get', 'label'],
          10,
          ['get', 'name'],
          15,
          ['case',
            ['>', ['coalesce', ['get', 'count'], 0], 1], ['concat', ['get', 'name'], ' (', ['get', 'count'], ')'],
            ['get', 'name'],
          ],
        ],
        // TODO light rail / subway oblique font
        'text-font': ['Noto Sans Bold'],
        'text-variable-anchor': ['center', 'top', 'bottom', 'left', 'right'],
        'text-size': 11,
        'text-padding': 10,
        'text-max-width': 5,
      },
    },
    {
      id: 'railway_tram_stations',
      type: 'symbol',
      minzoom: 13,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_text_stations',
      filter: ['==', ['get', 'railway'], 'tram_stop'],
      paint: {
        'text-color': colors[theme].styles.standard.tramStopText,
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
        // TODO light rail / subway oblique font
        'text-font': ['Noto Sans Bold'],
        'text-size': 11,
        'text-padding': 10,
        'text-max-width': 5,
        'text-variable-anchor': ['top', 'bottom'],
      },
    },
    searchResults,
  ],

  speed: [
    {
      id: 'speed_railway_line_low_casing',
      type: 'line',
      source: 'openrailwaymap_low',
      maxzoom: 7,
      'source-layer': 'railway_line_high',
      paint: speedCasingPaint(theme),
      layout: speedLayout,
    },
    {
      id: 'speed_railway_line_low_fill',
      type: 'line',
      source: 'openrailwaymap_low',
      maxzoom: 7,
      'source-layer': 'railway_line_high',
      paint: speedFillPaint(theme),
      layout: speedLayout,
    },
    {
      id: 'speed_railway_line_med_casing',
      type: 'line',
      source: 'openrailwaymap_med',
      minzoom: 7,
      maxzoom: 8,
      'source-layer': 'railway_line_high',
      paint: speedCasingPaint(theme),
      layout: speedLayout,
    },
    {
      id: 'speed_railway_line_med_fill',
      type: 'line',
      source: 'openrailwaymap_med',
      minzoom: 7,
      maxzoom: 8,
      'source-layer': 'railway_line_high',
      paint: speedFillPaint(theme),
      layout: speedLayout,
    },
    {
      id: 'speed_railway_line_casing',
      type: 'line',
      source: 'high',
      minzoom: 8,
      'source-layer': 'railway_line_high',
      paint: speedCasingPaint(theme),
      layout: speedLayout,
    },
    {
      id: 'speed_railway_line_fill',
      type: 'line',
      source: 'high',
      minzoom: 8,
      'source-layer': 'railway_line_high',
      paint: speedFillPaint(theme),
      layout: speedLayout,
    },
    preferredDirectionLayer(theme, 'railway_preferred_direction',
      ['any',
        ['==', ['get', 'preferred_direction'], 'forward'],
        ['==', ['get', 'preferred_direction'], 'backward'],
        ['==', ['get', 'preferred_direction'], 'both'],
      ],
      speedColor(theme),
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
      filter: ['!=', ['get', `ref`], null],
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
        'text-field': '{ref}',
        'text-font': ['Noto Sans Medium'],
        'text-size': 9,
        'text-anchor': 'top',
        'text-offset': [0, 1.5],
      },
    },
    railwayKmText(theme),
    {
      id: 'speed_railway_line_text',
      type: 'symbol',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['!=', ['get', 'speed_label'], null],
      paint: {
        'text-color': colors[theme].text.main,
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
          colors[theme].halo,
        ],
        'text-halo-width': 1.5,
      },
      layout: {
        'symbol-z-order': 'source',
        'symbol-placement': 'line',
        'text-field': '{speed_label}',
        'text-font': ['Noto Sans Bold'],
        'text-size': 11,
        'text-padding': 30,
        'symbol-spacing': 200,
      },
    },
    searchResults,
  ],

  signals: [
    {
      id: 'railway_line_low_casing',
      type: 'line',
      source: 'openrailwaymap_low',
      maxzoom: 7,
      'source-layer': 'railway_line_high',
      paint: trainProtectionCasingPaint(theme, [1]),
      layout: trainProtectionLayout,
    },
    {
      id: 'railway_line_low_fill',
      type: 'line',
      source: 'openrailwaymap_low',
      maxzoom: 7,
      'source-layer': 'railway_line_high',
      paint: trainProtectionFillPaint(theme, [1]),
      layout: trainProtectionLayout,
    },
    {
      id: 'railway_line_med_casing',
      type: 'line',
      minzoom: 7,
      maxzoom: 8,
      source: 'openrailwaymap_med',
      'source-layer': 'railway_line_high',
      paint: trainProtectionCasingPaint(theme, [1]),
      layout: trainProtectionLayout,
    },
    {
      id: 'railway_line_med_fill',
      type: 'line',
      minzoom: 7,
      maxzoom: 8,
      source: 'openrailwaymap_med',
      'source-layer': 'railway_line_high',
      paint: trainProtectionFillPaint(theme, [1]),
      layout: trainProtectionLayout,
    },
    {
      id: 'railway_line_casing_construction',
      type: 'line',
      source: 'high',
      minzoom: 8,
      'source-layer': 'railway_line_high',
      filter: ['==', ['get', 'state'], 'construction'],
      paint: trainProtectionCasingPaint(theme, [2, 2]),
      layout: trainProtectionLayout,
    },
    {
      id: 'railway_line_casing',
      type: 'line',
      source: 'high',
      minzoom: 8,
      'source-layer': 'railway_line_high',
      filter: ['!=', ['get', 'state'], 'construction'],
      paint: trainProtectionCasingPaint(theme, [1]),
      layout: trainProtectionLayout,
    },
    {
      id: 'railway_line_fill_construction',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['==', ['get', 'state'], 'construction'],
      paint: trainProtectionFillPaint(theme, [2, 2]),
      layout: trainProtectionLayout,
    },
    {
      id: 'railway_line_fill',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['!=', ['get', 'state'], 'construction'],
      paint: trainProtectionFillPaint(theme, [1]),
      layout: trainProtectionLayout,
    },
    preferredDirectionLayer(theme, 'railway_preferred_direction',
      ['any',
        ['==', ['get', 'preferred_direction'], 'forward'],
        ['==', ['get', 'preferred_direction'], 'backward'],
        ['==', ['get', 'preferred_direction'], 'both'],
      ],
      trainProtectionColor(theme),
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
        ['!=', ['get', `ref`], null],
        ['!=', ['get', `feature0`], null],
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
        'text-field': ['case',
          ['==', ['slice', ['get', 'feature0'], 0, 20], 'de/blockkennzeichen-'], ['get', 'ref_multiline'],
          ['get', 'ref'],
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
    railwayKmText(theme),
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
    {
      id: 'electrification_railway_line_low_casing',
      type: 'line',
      maxzoom: 7,
      source: 'openrailwaymap_low',
      'source-layer': 'railway_line_high',
      paint: electrificationCasingPaint(theme),
      layout: electrificationLayout,
    },
    {
      id: 'electrification_railway_line_low_fill',
      type: 'line',
      maxzoom: 7,
      source: 'openrailwaymap_low',
      'source-layer': 'railway_line_high',
      paint: electrificationFillPaint(theme, [1], 'voltage', 'frequency'),
      layout: electrificationLayout,
    },
    {
      id: 'electrification_railway_line_med_casing',
      type: 'line',
      minzoom: 7,
      maxzoom: 8,
      source: 'openrailwaymap_med',
      'source-layer': 'railway_line_high',
      paint: electrificationCasingPaint(theme),
      layout: electrificationLayout,
    },
    {
      id: 'electrification_railway_line_med_fill',
      type: 'line',
      minzoom: 7,
      maxzoom: 8,
      source: 'openrailwaymap_med',
      'source-layer': 'railway_line_high',
      paint: electrificationFillPaint(theme, [1], 'voltage', 'frequency'),
      layout: electrificationLayout,
    },
    {
      id: 'electrification_railway_line_casing',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      paint: electrificationCasingPaint(theme),
      layout: electrificationLayout,
    },
    {
      id: 'electrification_railway_line_fill',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      paint: electrificationFillPaint(theme, [1], 'voltage', 'frequency'),
      layout: electrificationLayout,
    },
    {
      id: 'electrification_future_proposed',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['==', ['get', 'electrification_state'], 'proposed'],
      paint: electrificationFillPaint(theme, electrification_proposed_dashes, 'future_voltage', 'future_frequency'),
      layout: electrificationLayout,
    },
    {
      id: 'electrification_future_construction',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['==', ['get', 'electrification_state'], 'construction'],
      paint: electrificationFillPaint(theme, electrification_construction_dashes, 'future_voltage', 'future_frequency'),
      layout: electrificationLayout,
    },
    preferredDirectionLayer(theme, 'railway_preferred_direction',
      ['any',
        ['==', ['get', 'preferred_direction'], 'forward'],
        ['==', ['get', 'preferred_direction'], 'backward'],
        ['==', ['get', 'preferred_direction'], 'both'],
      ],
      electrificationColor(theme, 'voltage', 'frequency'),
    ),
    {
      id: 'electrification_signals_direction',
      type: 'symbol',
      minzoom: 15,
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
      },
    },
    ...imageLayerWithOutline(
      theme,
      'electrification_signals',
      ['get', 'feature'],
      {
        type: 'symbol',
        minzoom: 15,
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
    railwayKmText(theme),
    {
      id: 'electrification_railway_text_high',
      type: 'symbol',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['!=', ['get', 'electrification_label'], null],
      paint: {
        'text-color': colors[theme].text.main,
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
          colors[theme].halo
        ],
        'text-halo-width': 1.5,
      },
      layout: {
        'symbol-z-order': 'source',
        'symbol-placement': 'line',
        'text-field': '{electrification_label}',
        // TODO not present: oblique font
        'text-font': ['Noto Sans Bold'],
        'text-size': 11,
        'text-padding': 30,
        'symbol-spacing': 250,
      },
    },
    searchResults,
  ],

  gauge: [
    {
      id: 'gauge_railway_line_low_casing',
      type: 'line',
      maxzoom: 7,
      source: 'openrailwaymap_low',
      'source-layer': 'railway_line_high',
      paint: gaugeCasingPaint(theme),
      layout: gaugeLayout,
    },
    {
      id: 'gauge_railway_line_low_fill',
      type: 'line',
      maxzoom: 7,
      source: 'openrailwaymap_low',
      'source-layer': 'railway_line_high',
      paint: gaugeFillPaint(theme, 'gauge0', 'gaugeint0', [1]),
      layout: gaugeLayout,
    },
    {
      id: 'gauge_railway_line_med_casing',
      type: 'line',
      minzoom: 7,
      maxzoom: 8,
      source: 'openrailwaymap_med',
      'source-layer': 'railway_line_high',
      paint: gaugeCasingPaint(theme),
      layout: gaugeLayout,
    },
    {
      id: 'gauge_railway_line_med_fill',
      type: 'line',
      minzoom: 7,
      maxzoom: 8,
      source: 'openrailwaymap_med',
      'source-layer': 'railway_line_high',
      paint: gaugeFillPaint(theme, 'gauge0', 'gaugeint0', [1]),
      layout: gaugeLayout,
    },
    {
      id: 'gauge_railway_line_casing',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['!=', ['get', 'state'], 'construction'],
      paint: gaugeCasingPaint(theme),
      layout: gaugeLayout,
    },
    {
      id: 'gauge_railway_line_casing_construction',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['==', ['get', 'state'], 'construction'],
      paint: {
        'line-color': 'white',
        'line-width': railwayLineWidth,
        'line-gap-width': 0.75,
        'line-dasharray': gauge_construction_dashes,
      },
    },
    {
      id: 'gauge_railway_line_fill',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['!=', ['get', 'state'], 'construction'],
      paint: gaugeFillPaint(theme, 'gauge0', 'gaugeint0', [1]),
      layout: gaugeLayout,
    },
    {
      id: 'gauge_railway_line_fill_construction',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['==', ['get', 'state'], 'construction'],
      paint: gaugeFillPaint(theme, 'gauge0', 'gaugeint0', gauge_construction_dashes),
      layout: gaugeLayout,
    },
    {
      id: 'gauge_railway_dual_gauge_line',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['!=', ['get', 'gauge1'], null],
        ['!=', ['get', 'state'], 'construction'],
      ],
      paint: gaugeFillPaint(theme, 'gauge1', 'gaugeint1', gauge_dual_gauge_dashes),
      layout: gaugeLayout,
    },
    {
      id: 'gauge_railway_dual_gauge_line_construction',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['!=', ['get', 'gauge1'], null],
        ['==', ['get', 'state'], 'construction'],
      ],
      paint: gaugeFillPaint(theme, 'gauge1', 'gaugeint1', dual_construction_dashes),
      layout: gaugeLayout,
    },
    {
      id: 'gauge_railway_multi_gauge_line',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['!=', ['get', 'gauge2'], null],
        ['!=', ['get', 'state'], 'construction'],
      ],
      paint: gaugeFillPaint(theme, 'gauge2', 'gaugeint2', gauge_multi_gauge_dashes),
      layout: gaugeLayout,
    },
    {
      id: 'gauge_railway_multi_gauge_line_construction',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['!=', ['get', 'gauge2'], null],
        ['==', ['get', 'state'], 'construction'],
      ],
      paint: gaugeFillPaint(theme, 'gauge2', 'gaugeint2', multi_construction_dashes),
      layout: gaugeLayout,
    },
    preferredDirectionLayer(theme, 'railway_preferred_direction',
      ['any',
        ['==', ['get', 'preferred_direction'], 'forward'],
        ['==', ['get', 'preferred_direction'], 'backward'],
        ['==', ['get', 'preferred_direction'], 'both'],
      ],
      gaugeColor(theme, 'gauge0', 'gaugeint0'),
    ),
    railwayKmText(theme),
    {
      id: 'gauge_railway_text_high',
      type: 'symbol',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['!=', ['get', 'gauge_label'], null],
      paint: {
        'text-color': colors[theme].text.main,
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
          colors[theme].halo
        ],
        'text-halo-width': 1.5,
      },
      layout: {
        'symbol-z-order': 'source',
        'symbol-placement': 'line',
        'text-field': '{gauge_label}',
        // TODO not present: oblique font
        'text-font': ['Noto Sans Bold'],
        'text-size': 11,
        'text-padding': 30,
        'symbol-spacing': 250,
      },
    },
    searchResults,
  ],

  loading_gauge: [
    {
      id: 'loading_gauge_railway_line_low_casing',
      type: 'line',
      maxzoom: 7,
      source: 'openrailwaymap_low',
      'source-layer': 'railway_line_high',
      paint: loadingGaugeCasingPaint(theme),
      layout: loadingGaugeLayout,
    },
    {
      id: 'loading_gauge_railway_line_low_fill',
      type: 'line',
      maxzoom: 7,
      source: 'openrailwaymap_low',
      'source-layer': 'railway_line_high',
      paint: loadingGaugeFillPaint(theme, [1]),
      layout: loadingGaugeLayout,
    },
    {
      id: 'loading_gauge_railway_line_med_casing',
      type: 'line',
      minzoom: 7,
      maxzoom: 8,
      source: 'openrailwaymap_med',
      'source-layer': 'railway_line_high',
      paint: loadingGaugeCasingPaint(theme),
      layout: loadingGaugeLayout,
    },
    {
      id: 'loading_gauge_railway_line_med_fill',
      type: 'line',
      minzoom: 7,
      maxzoom: 8,
      source: 'openrailwaymap_med',
      'source-layer': 'railway_line_high',
      paint: loadingGaugeFillPaint(theme, [1]),
      layout: loadingGaugeLayout,
    },
    {
      id: 'loading_gauge_railway_line_casing',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['!=', ['get', 'state'], 'construction'],
      paint: loadingGaugeCasingPaint(theme),
      layout: loadingGaugeLayout,
    },
    {
      id: 'loading_gauge_railway_line_casing_construction',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['==', ['get', 'state'], 'construction'],
      paint: {
        'line-color': 'white',
        'line-width': railwayLineWidth,
        'line-gap-width': 0.75,
        'line-dasharray': gauge_construction_dashes,
      },
    },
    {
      id: 'loading_gauge_railway_line_fill',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['!=', ['get', 'state'], 'construction'],
      paint: loadingGaugeFillPaint(theme, [1]),
      layout: loadingGaugeLayout,
    },
    {
      id: 'loading_gauge_railway_line_fill_construction',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['==', ['get', 'state'], 'construction'],
      paint: loadingGaugeFillPaint(theme, gauge_construction_dashes),
      layout: loadingGaugeLayout,
    },
    preferredDirectionLayer(theme, 'railway_preferred_direction',
      ['any',
        ['==', ['get', 'preferred_direction'], 'forward'],
        ['==', ['get', 'preferred_direction'], 'backward'],
        ['==', ['get', 'preferred_direction'], 'both'],
      ],
      loadingGaugeFillColor,
    ),
    railwayKmText(theme),
    {
      id: 'loading_gauge_railway_text_high',
      type: 'symbol',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['!=', ['get', 'loading_gauge'], null],
      paint: {
        'text-color': colors[theme].text.main,
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
          colors[theme].halo
        ],
        'text-halo-width': 1.5,
      },
      layout: {
        'symbol-z-order': 'source',
        'symbol-placement': 'line',
        'text-field': '{loading_gauge}',
        // TODO not present: oblique font
        'text-font': ['Noto Sans Bold'],
        'text-size': 11,
        'text-padding': 30,
        'symbol-spacing': 250,
      },
    },
    searchResults,
  ],

  track_class: [
    {
      id: 'track_class_railway_line_low_casing',
      type: 'line',
      maxzoom: 7,
      source: 'openrailwaymap_low',
      'source-layer': 'railway_line_high',
      paint: trackClassCasingPaint,
      layout: trackClassLayout,
    },
    {
      id: 'track_class_railway_line_low_fill',
      type: 'line',
      maxzoom: 7,
      source: 'openrailwaymap_low',
      'source-layer': 'railway_line_high',
      paint: trackClassFillPaint(theme, [1]),
      layout: trackClassLayout,
    },
    {
      id: 'track_class_railway_line_med_casing',
      type: 'line',
      minzoom: 7,
      maxzoom: 8,
      source: 'openrailwaymap_med',
      'source-layer': 'railway_line_high',
      paint: trackClassCasingPaint,
      layout: trackClassLayout,
    },
    {
      id: 'track_class_railway_line_med_fill',
      type: 'line',
      minzoom: 7,
      maxzoom: 8,
      source: 'openrailwaymap_med',
      'source-layer': 'railway_line_high',
      paint: trackClassFillPaint(theme, [1]),
      layout: trackClassLayout,
    },
    {
      id: 'track_class_railway_line_casing',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['!=', ['get', 'state'], 'construction'],
      paint: trackClassCasingPaint,
      layout: trackClassLayout,
    },
    {
      id: 'track_class_railway_line_casing_construction',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['==', ['get', 'state'], 'construction'],
      paint: {
        'line-color': 'white',
        'line-width': railwayLineWidth,
        'line-gap-width': 0.75,
        'line-dasharray': gauge_construction_dashes,
      },
    },
    {
      id: 'track_class_railway_line_fill',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['!=', ['get', 'state'], 'construction'],
      paint: trackClassFillPaint(theme, [1]),
      layout: trackClassLayout,
    },
    {
      id: 'track_class_railway_line_fill_construction',
      type: 'line',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['==', ['get', 'state'], 'construction'],
      paint: trackClassFillPaint(theme, gauge_construction_dashes),
      layout: loadingGaugeLayout,
    },
    preferredDirectionLayer(theme, 'railway_preferred_direction',
      ['any',
        ['==', ['get', 'preferred_direction'], 'forward'],
        ['==', ['get', 'preferred_direction'], 'backward'],
        ['==', ['get', 'preferred_direction'], 'both'],
      ],
      trackClassFillColor,
    ),
    railwayKmText(theme),
    {
      id: 'track_class_railway_text_high',
      type: 'symbol',
      minzoom: 8,
      source: 'high',
      'source-layer': 'railway_line_high',
      filter: ['!=', ['get', 'track_class'], null],
      paint: {
        'text-color': colors[theme].text.main,
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors[theme].hover.textHalo,
          colors[theme].halo
        ],
        'text-halo-width': 1.5,
      },
      layout: {
        'symbol-z-order': 'source',
        'symbol-placement': 'line',
        'text-field': '{track_class}',
        // TODO not present: oblique font
        'text-font': ['Noto Sans Bold'],
        'text-size': 11,
        'text-padding': 30,
        'symbol-spacing': 250,
      },
    },
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
    'openrailwaymap_low-railway_line_high': [
      {
        legend: 'Highspeed main line',
        type: 'line',
        properties: {
          state: 'present',
          highspeed: true,
          usage: 'main',
          service: null,
        },
      },
      {
        legend: 'Main line',
        type: 'line',
        properties: {
          state: 'present',
          highspeed: false,
          usage: 'main',
          service: null,
        }
      },
    ],
    "openrailwaymap_med-railway_line_high": [
      {
        legend: 'Highspeed main line',
        type: 'line',
        properties: {
          state: 'present',
          highspeed: true,
          usage: 'main',
          service: null,
        },
      },
      {
        legend: 'Main line',
        type: 'line',
        properties: {
          state: 'present',
          highspeed: false,
          usage: 'main',
          service: null,
        }
      },
      {
        legend: 'Branch line',
        type: 'line',
        properties: {
          state: 'present',
          highspeed: false,
          usage: 'branch',
          service: null,
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
          ref: 'L1',
          standard_label: 'Name',
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
          standard_label: 'Name',
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
          ref: 'L1',
          standard_label: 'Name',
          track_ref: '8b',
          way_length: 1.0,
        }
      },
      {
        legend: 'Industrial line',
        type: 'line',
        properties: {
          highspeed: false,
          feature: 'rail',
          state: 'present',
          usage: 'industrial',
          service: null,
          tunnel: false,
          bridge: false,
          ref: 'L1',
          standard_label: 'Name',
          track_ref: '8b',
          way_length: 1.0,
        }
      },
      {
        legend: 'Narrow gauge line',
        type: 'line',
        properties: {
          highspeed: false,
          feature: 'narrow_gauge',
          state: 'present',
          usage: null,
          service: null,
          tunnel: false,
          bridge: false,
          ref: 'L1',
          standard_label: 'Name',
          track_ref: '8b',
          way_length: 1.0,
        }
      },
      {
        legend: 'Subway',
        type: 'line',
        properties: {
          highspeed: false,
          feature: 'subway',
          state: 'present',
          usage: null,
          service: null,
          tunnel: false,
          bridge: false,
          ref: 'L1',
          standard_label: 'Name',
          track_ref: '8b',
          way_length: 1.0,
        }
      },
      {
        legend: 'Light rail',
        type: 'line',
        properties: {
          highspeed: false,
          feature: 'light_rail',
          state: 'present',
          usage: null,
          service: null,
          tunnel: false,
          bridge: false,
          ref: 'L1',
          standard_label: null,
          track_ref: '8b',
          way_length: 1.0,
        }
      },
      {
        legend: 'Tram',
        type: 'line',
        properties: {
          highspeed: false,
          feature: 'tram',
          state: 'present',
          usage: null,
          service: null,
          tunnel: false,
          bridge: false,
          ref: 'L1',
          standard_label: 'Name',
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
        legend: 'Tourism (preserved)',
        type: 'line',
        properties: {
          highspeed: false,
          feature: 'rail',
          state: 'preserved',
          usage: 'tourism',
          service: null,
          tunnel: false,
          bridge: false,
          ref: 'L1',
          standard_label: 'Name',
          track_ref: '8b',
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
    'standard_railway_text_stations_low-standard_railway_text_stations_low': [
      {
        legend: 'Station',
        type: 'point',
        properties: {
          label: 'BSA',
        },
      },
    ],
    "standard_railway_text_stations_med-standard_railway_text_stations_med": [
      {
        legend: 'Station',
        type: 'point',
        properties: {
          label: 'BSA',
        },
      },
    ],
    "openrailwaymap_standard-standard_railway_text_stations":
      stations.features.map(feature => ({
        legend: feature.description,
        type: 'point',
        properties: {
          ...feature.example,
          railway: feature.feature,
        },
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
          maxspeed: null,
        },
      },
    ],
    'openrailwaymap_med-railway_line_high': [
      ...speedLegends.map(speed => ({
        legend: `${speed} km/h`,
        type: 'line',
        properties: {
          feature: 'rail',
          state: 'present',
          usage: 'main',
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
          feature0: 'pl/w21-40',
          type: 'line',
          azimuth: null,
          deactivated: true,
          direction_both: false,
        },
      },
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
          train_protection: null,
          train_protection_rank: 0,
        },
      },
    ],
    'openrailwaymap_med-railway_line_high': [
      ...signals_railway_line.train_protections.map(train_protection => ({
        legend: train_protection.legend,
        type: 'line',
        properties: {
          feature: 'rail',
          state: 'present',
          usage: 'main',
          service: null,
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
          electrification_state: null,
          voltage: null,
          frequency: null,
        },
      },
    ],
    'openrailwaymap_med-railway_line_high': [
      {
        legend: 'Not electrified',
        type: 'line',
        properties: {
          feature: 'rail',
          state: 'present',
          usage: 'main',
          service: null,
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
          gauge0: '3500',
          gaugeint0: 3500,
          label: '3500'
        },
      },
    ],
    'openrailwaymap_med-railway_line_high': [
      ...gaugeLegends.map(({min, legend}) => ({
        legend,
        type: 'line',
        properties: {
          feature: 'rail',
          state: 'present',
          usage: 'main',
          service: null,
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
        },
      },
    ],
    'openrailwaymap_med-railway_line_high': [
      ...loading_gauges.loading_gauges.map(loading_gauge => ({
        legend: loading_gauge.legend,
        type: 'line',
        properties: {
          loading_gauge: loading_gauge.value,
          feature: 'rail',
          state: 'present',
          usage: 'main',
          service: null,
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
        },
      },
    ],
    'openrailwaymap_med-railway_line_high': [
      ...track_classes.track_classes.map(track_class => ({
        legend: track_class.value,
        type: 'line',
        properties: {
          track_class: track_class.value,
          feature: 'rail',
          state: 'present',
          usage: 'main',
          service: null,
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
    ((layer.minzoom ?? globalMinZoom) <= zoom) && (zoom < (layer.maxzoom ?? (glodalMaxZoom + 1)));

const legendPointToMapPoint = (zoom, [x, y]) =>
  [x * coordinateFactor(zoom), y * coordinateFactor(zoom)]

function makeLegendStyle(style, theme) {
  const sourceStyle = makeStyle(style, theme);
  const sourceLayers = sourceStyle.layers.filter(layer => layer.type !== 'raster' && layer.type !== 'background');
  const legendZoomLevels = [...Array(glodalMaxZoom - globalMinZoom + 1).keys()].map(zoom => globalMinZoom + zoom);

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
      let entry = 0;
      let done = new Set();

      const featureSourceLayers = sourceLayers.flatMap(layer => {
        const legendLayerName = `${layer.source}-${layer['source-layer']}`;
        const sourceName = `${legendLayerName}-z${legendZoom}`
        if (done.has(sourceName) || !usedLegendSources[legendZoom] || !usedLegendSources[legendZoom].has(sourceName)) {
          return [];
        }

        const applicable = layerVisibleAtZoom(legendZoom)(layer);
        const data = applicable ? (legendData[style][legendLayerName] ?? []) : [];
        const features = data.flatMap(item => {
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
        if (done.has(sourceName)) {
          return [];
        }

        const applicable = layerVisibleAtZoom(legendZoom)(layer);
        const data = applicable ? (legendData[style][legendLayerName] ?? []) : [];
        const features = data.map(item => {
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
