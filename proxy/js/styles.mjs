import fs from 'fs'
import yaml from 'yaml'

const signals_railway_line = yaml.parse(fs.readFileSync('train_protection.yaml', 'utf8')).signals_railway_line
const speed_railway_signals = yaml.parse(fs.readFileSync('speed_railway_signals.yaml', 'utf8')).speed_railway_signals
const signals_railway_signals = yaml.parse(fs.readFileSync('signals_railway_signals.yaml', 'utf8')).signals_railway_signals
const electrification_signals = yaml.parse(fs.readFileSync('electrification_signals.yaml', 'utf8')).electrification_signals

const origin = `${process.env.PUBLIC_PROTOCOL}://${process.env.PUBLIC_HOST}`

const knownStyles = [
  'standard',
  'speed',
  'signals',
  'electrification',
  'gauge',
];

const globalMinZoom = 1;
const glodalMaxZoom= 18;

const colors = {
  hover: {
    main: '#ff0000',
    // High speed lines and 25kV are the hover color by default
    alternative: '#ffc107',
    textHalo: 'yellow',
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
      abandoned: '#7f6a62',
      razed: '#94847e',
      tram: '#d877b8',
      subway: '#0300c3',
      light_rail: '#00bd14',
      siding: '#000000',
      yard: '#000000',
      spur: '#87491d',
      industrial: '#87491d',
      casing: {
        railway: '#ffffff',
        bridge: '#000000',
      },
      turntable: {
        fill: '#ababab',
        casing: '#808080',
      },
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

const railwayLineWidth = ['step', ['zoom'],
  1.5,
  5,
  1.5,
  7,
  ['case',
    ['==', ['get', 'usage'], 'main'], 2.5,
    2,
  ],
  8,
  ['case',
    ['all',
      ['==', ['get', 'feature'], 'rail'],
      ['any',
        ['all', ['==', ['get', 'usage'], 'main'], ['==', ['get', 'service'], null]],
        ['all', ['==', ['get', 'usage'], 'branch'], ['==', ['get', 'service'], null]],
      ]
    ], 3.5,
    ['all',
      ['==', ['get', 'railway'], 'construction'],
      ['==', ['get', 'feature'], 'rail'],
      ['any', ['==', ['get', 'usage'], 'main'], ['==', ['get', 'usage'], 'branch']],
      ['==', ['get', 'service'], null],
    ],
    ['case',
      ['!=', ['get', 'service'], null], 1.5,
      3,
    ],
    0,
  ],
  9,
  ['case',
    ['all',
      ['==', ['get', 'feature'], 'rail'],
      ['==', ['get', 'service'], null],
      ['any',
        ['==', ['get', 'usage'], 'main'],
        ['==', ['get', 'usage'], 'branch'],
        ['==', ['get', 'usage'], 'industrial'],
        ['==', ['get', 'usage'], 'tourism'],
      ]
    ],
    ['case',
      ['all',
        ['any',
          ['==', ['get', 'usage'], 'industrial'],
          ['==', ['get', 'usage'], 'tourism'],
        ],
        ['==', ['get', 'service'], null],
      ], 2,
      3.5,
    ],
    ['all',
      ['==', ['get', 'feature'], 'narrow_gauge'],
      ['==', ['get', 'service'], null],
    ],
    ['case',
      ['all',
        ['any',
          ['==', ['get', 'usage'], 'industrial'],
          ['==', ['get', 'usage'], 'tourism'],
        ],
        ['==', ['get', 'service'], null],
      ], 2,
      3,
    ],
    ['any',
      ['all',
        ['==', ['get', 'railway'], 'construction'],
        ['==', ['get', 'feature'], 'rail'],
        ['any', ['==', ['get', 'usage'], 'main'], ['==', ['get', 'usage'], 'branch']],
        ['==', ['get', 'service'], null],
      ],
      ['all',
        ['==', ['get', 'railway'], 'construction'],
        ['any',
          ['==', ['get', 'feature'], 'subway'],
          ['==', ['get', 'feature'], 'light_rail'],
          ['==', ['get', 'feature'], 'monorail'],
        ],
        ['==', ['get', 'service'], null],
      ],
      ['all',
        ['any',
          ['==', ['get', 'feature'], 'subway'],
          ['==', ['get', 'feature'], 'light_rail'],
          ['==', ['get', 'feature'], 'monorail'],
        ],
        ['==', ['get', 'service'], null],
      ],
    ],
    ['case',
      ['!=', ['get', 'service'], null], 1.5,
      3,
    ],
    0,
  ],
  10,
  ['case',
    ['all',
      ['==', ['get', 'feature'], 'rail'],
      ['any',
        ['all', ['==', ['get', 'usage'], 'main'], ['==', ['get', 'service'], null]],
        ['all', ['==', ['get', 'usage'], 'branch'], ['==', ['get', 'service'], null]],
        ['==', ['get', 'usage'], 'industrial'],
        ['==', ['get', 'usage'], 'tourism'],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'siding']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'crossover']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'spur']],
      ]
    ],
    ['case',
      ['any',
        ['all',
          ['any',
            ['==', ['get', 'usage'], 'industrial'],
            ['==', ['get', 'usage'], 'tourism'],
          ],
          ['==', ['get', 'service'], null],
        ],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'siding']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'crossover']],
      ], 2,
      ['any',
        ['all',
          ['any',
            ['==', ['get', 'usage'], 'industrial'],
            ['==', ['get', 'usage'], 'tourism'],
          ],
          ['!=', ['get', 'service'], null],
        ],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'spur']],
      ], 1.5,
      3.5,
    ],
    ['all',
      ['==', ['get', 'feature'], 'narrow_gauge'],
      ['any',
        ['==', ['get', 'service'], null],
        ['==', ['get', 'service'], 'spur'],
        ['==', ['get', 'service'], 'siding'],
        ['==', ['get', 'service'], 'crossover'],
      ],
    ],
    ['case',
      ['all',
        ['any',
          ['==', ['get', 'usage'], 'industrial'],
          ['==', ['get', 'usage'], 'tourism'],
        ],
        ['==', ['get', 'service'], null],
      ], 2,
      3,
    ],
    ['any',
      ['all',
        ['==', ['get', 'railway'], 'construction'],
        ['==', ['get', 'feature'], 'rail'],
        ['any', ['==', ['get', 'usage'], 'main'], ['==', ['get', 'usage'], 'branch']],
        ['==', ['get', 'service'], null],
      ],
      ['all',
        ['==', ['get', 'railway'], 'construction'],
        ['any',
          ['==', ['get', 'feature'], 'subway'],
          ['==', ['get', 'feature'], 'light_rail'],
          ['==', ['get', 'feature'], 'tram'],
          ['==', ['get', 'feature'], 'monorail'],
          ['==', ['get', 'feature'], 'miniature'],
        ],
        ['==', ['get', 'service'], null],
      ],
      ['all',
        ['any',
          ['==', ['get', 'feature'], 'subway'],
          ['==', ['get', 'feature'], 'light_rail'],
          ['==', ['get', 'feature'], 'tram'],
          ['==', ['get', 'feature'], 'monorail'],
          ['==', ['get', 'feature'], 'miniature'],
        ],
        ['==', ['get', 'service'], null],
      ],
    ],
    ['case',
      ['!=', ['get', 'service'], null], 1.5,
      3,
    ],
    0,
  ],
  11,
  ['case',
    ['all',
      ['==', ['get', 'feature'], 'rail'],
      ['any',
        ['all', ['==', ['get', 'usage'], 'main'], ['==', ['get', 'service'], null]],
        ['all', ['==', ['get', 'usage'], 'branch'], ['==', ['get', 'service'], null]],
        ['==', ['get', 'usage'], 'industrial'],
        ['==', ['get', 'usage'], 'tourism'],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'siding']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'crossover']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'spur']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'yard']],
      ]
    ],
    ['case',
      ['any',
        ['all',
          ['any',
            ['==', ['get', 'usage'], 'industrial'],
            ['==', ['get', 'usage'], 'tourism'],
          ],
          ['==', ['get', 'service'], null],
        ],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'siding']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'crossover']],
      ], 2,
      ['any',
        ['all',
          ['any',
            ['==', ['get', 'usage'], 'industrial'],
            ['==', ['get', 'usage'], 'tourism'],
          ],
          ['!=', ['get', 'service'], null],
        ],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'spur']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'yard']],
      ], 1.5,
      3.5,
    ],
    ['all',
      ['==', ['get', 'feature'], 'narrow_gauge'],
      ['any',
        ['==', ['get', 'service'], null],
        ['==', ['get', 'service'], 'spur'],
        ['==', ['get', 'service'], 'siding'],
        ['==', ['get', 'service'], 'crossover'],
        ['==', ['get', 'service'], 'yard'],
      ],
    ],
    ['case',
      ['all',
        ['any',
          ['==', ['get', 'usage'], 'industrial'],
          ['==', ['get', 'usage'], 'tourism'],
        ],
        ['==', ['get', 'service'], null],
      ], 2,
      3,
    ],
    ['any',
      ['all',
        ['==', ['get', 'railway'], 'construction'],
        ['==', ['get', 'feature'], 'rail'],
        ['any', ['==', ['get', 'usage'], 'main'], ['==', ['get', 'usage'], 'branch']],
        ['==', ['get', 'service'], null],
      ],
      ['all',
        ['==', ['get', 'railway'], 'construction'],
        ['any',
          ['==', ['get', 'feature'], 'subway'],
          ['==', ['get', 'feature'], 'light_rail'],
          ['==', ['get', 'feature'], 'tram'],
          ['==', ['get', 'feature'], 'monorail'],
          ['==', ['get', 'feature'], 'miniature'],
        ],
        ['==', ['get', 'service'], null],
      ],
      ['all',
        ['any',
          ['==', ['get', 'feature'], 'subway'],
          ['==', ['get', 'feature'], 'light_rail'],
          ['==', ['get', 'feature'], 'tram'],
          ['==', ['get', 'feature'], 'monorail'],
          ['==', ['get', 'feature'], 'miniature'],
        ],
        ['==', ['get', 'service'], null],
      ],
    ],
    ['case',
      ['!=', ['get', 'service'], null], 1.5,
      3,
    ],
    0,
  ],
  12,
  ['case',
    ['all',
      ['==', ['get', 'feature'], 'rail'],
      ['any',
        ['all', ['==', ['get', 'usage'], 'main'], ['==', ['get', 'service'], null]],
        ['all', ['==', ['get', 'usage'], 'branch'], ['==', ['get', 'service'], null]],
        ['==', ['get', 'usage'], 'industrial'],
        ['==', ['get', 'usage'], 'tourism'],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'siding']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'crossover']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'spur']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'yard']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], null]],
      ]
    ],
    ['case',
      ['any',
        ['all',
          ['any',
            ['==', ['get', 'usage'], 'industrial'],
            ['==', ['get', 'usage'], 'tourism'],
          ],
          ['==', ['get', 'service'], null],
        ],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'siding']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'crossover']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], null]],
      ], 2,
      ['any',
        ['all',
          ['any',
            ['==', ['get', 'usage'], 'industrial'],
            ['==', ['get', 'usage'], 'tourism'],
          ],
          ['!=', ['get', 'service'], null],
        ],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'spur']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'yard']],
      ], 1.5,
      3.5,
    ],
    ['all',
      ['==', ['get', 'feature'], 'narrow_gauge'],
      ['any',
        ['==', ['get', 'service'], null],
        ['==', ['get', 'service'], 'spur'],
        ['==', ['get', 'service'], 'siding'],
        ['==', ['get', 'service'], 'crossover'],
        ['==', ['get', 'service'], 'yard'],
      ],
    ],
    ['case',
      ['all',
        ['any',
          ['==', ['get', 'usage'], 'industrial'],
          ['==', ['get', 'usage'], 'tourism'],
        ],
        ['==', ['get', 'service'], null],
      ], 2,
      3,
    ],
    ['any',
      ['all',
        ['==', ['get', 'railway'], 'construction'],
        ['==', ['get', 'feature'], 'rail'],
        ['any', ['==', ['get', 'usage'], 'main'], ['==', ['get', 'usage'], 'branch']],
        ['==', ['get', 'service'], null],
      ],
      ['all',
        ['==', ['get', 'railway'], 'construction'],
        ['any',
          ['==', ['get', 'feature'], 'subway'],
          ['==', ['get', 'feature'], 'light_rail'],
          ['==', ['get', 'feature'], 'tram'],
          ['==', ['get', 'feature'], 'narrow_gauge'],
          ['==', ['get', 'feature'], 'monorail'],
          ['==', ['get', 'feature'], 'miniature'],
        ],
        ['==', ['get', 'service'], null],
      ],
      ['any',
        ['==', ['get', 'feature'], 'subway'],
        ['==', ['get', 'feature'], 'light_rail'],
        ['==', ['get', 'feature'], 'tram'],
        ['==', ['get', 'feature'], 'monorail'],
        ['==', ['get', 'feature'], 'miniature'],
      ],
    ],
    ['case',
      ['!=', ['get', 'service'], null], 1.5,
      3,
    ],
    0,
  ],
];
const trainProtectionCasingPaint = dashArray => ({
  'line-color': 'white',
  'line-width': railwayLineWidth,
  'line-gap-width': 1,
  'line-dasharray': dashArray,
});
const trainProtectionLayout = {
  'line-sort-key': ['get', 'train_protection_rank'],
  'line-join': 'round',
  'line-cap': 'round',
};
const trainProtectionFillPaint = dashArray => ({
  'line-color': ['case',
    ['boolean', ['feature-state', 'hover'], false], colors.hover.main,
    ...signals_railway_line.train_protections.flatMap(train_protection =>
      [['==', ['get', 'train_protection'], train_protection.train_protection], train_protection.color]),
    'grey',
  ],
  'line-width': railwayLineWidth,
  'line-dasharray': dashArray,
});

const railway_casing_add = 1;

/* additional width of the casing of dashed lines */
const railway_tunnel_casing_add = 1;
const bridge_casing_add = 4;

const abandoned_dasharray = [2.5, 2.5];
const razed_dasharray = [1.5, 3.5];
const construction_dasharray = [4.5, 4.5];
const proposed_dasharray = [1, 4];

const standardLowFillPaint = {
  'line-color': ['case',
    ['boolean', ['feature-state', 'hover'], false], ['case',
      ['get', 'highspeed'], colors.hover.alternative,
      colors.hover.main,
    ],
    ['get', 'highspeed'], colors.styles.standard.highspeed,
    colors.styles.standard.main,
  ],
  'line-width': railwayLineWidth,
};
const standardMediumFillPaint = {
  'line-color': ['case',
    ['boolean', ['feature-state', 'hover'], false], ['case',
      ['get', 'highspeed'], colors.hover.alternative,
      colors.hover.main,
    ],
    ['==', ['get', 'usage'], 'branch'], colors.styles.standard.branch,
    ['get', 'highspeed'], colors.styles.standard.highspeed,
    colors.styles.standard.main,
  ],
  'line-width': railwayLineWidth,
};
const standardFillPaint = dashArray => ({
  'line-color': ['case',
    ['boolean', ['feature-state', 'hover'], false], ['case',
      ['all', ['==', ['get', 'usage'], 'main'], ['get', 'highspeed']], colors.hover.alternative,
      colors.hover.main,
    ],
    ['==', ['get', 'railway'], 'disused'], colors.styles.standard.disused,
    ['==', ['get', 'railway'], 'abandoned'], colors.styles.standard.abandoned,
    ['==', ['get', 'railway'], 'razed'], colors.styles.standard.razed,
    ['==', ['get', 'feature'], 'rail'],
    ['case',
      ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'spur']], colors.styles.standard.spur,
      ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'yard']], colors.styles.standard.yard,
      ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'crossover']], colors.styles.standard.siding,
      ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'siding']], colors.styles.standard.siding,
      ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], null]], colors.styles.standard.no_usage,
      ['==', ['get', 'usage'], 'industrial'], colors.styles.standard.industrial,
      ['==', ['get', 'usage'], 'tourism'], colors.styles.standard.tourism,
      ['==', ['get', 'usage'], 'branch'], colors.styles.standard.branch,
      ['all', ['==', ['get', 'usage'], 'main'], ['get', 'highspeed']], colors.styles.standard.highspeed,
      ['==', ['get', 'usage'], 'main'], colors.styles.standard.main,
      'rgba(255, 255, 255, 1.0)',
    ],
    ['==', ['get', 'feature'], 'narrow_gauge'],
    ['case',
      ['all', ['==', ['get', 'usage'], 'industrial'], ['==', ['get', 'service'], 'spur']], colors.styles.standard.industrial,
      colors.styles.standard.narrowGauge,
    ],
    ['==', ['get', 'feature'], 'subway'], colors.styles.standard.subway,
    ['==', ['get', 'feature'], 'light_rail'], colors.styles.standard.light_rail,
    ['==', ['get', 'feature'], 'tram'], colors.styles.standard.tram,
    'rgba(255, 255, 255, 1.0)',
  ],
  'line-width': railwayLineWidth,
  'line-dasharray': dashArray,
});
const speedCasingPaint = {
  'line-color': 'white',
  'line-width': railwayLineWidth,
  'line-gap-width': 1,
};
const speedLayout = {
  'line-join': 'round',
  'line-cap': 'round',
};

const minSpeed = 10
const maxSpeed = 380
const startHue = 248
const endHue = 284;

const speedFillPaint = {
  'line-color': ['case',
    ['boolean', ['feature-state', 'hover'], false], ['case',
      ['all', ['>=', ['get', 'maxspeed'], 260], ['<=', ['get', 'maxspeed'], 300]], colors.hover.alternative,
      colors.hover.main,
    ],
    ['==', ['get', 'maxspeed'], null], 'gray',
    // Reverse hue order
    ['concat', 'hsl(', ['%', ['+', ['-', startHue, ['*', startHue + (360 - endHue), ['/', ['-', ['max', minSpeed, ['min', ['get', 'maxspeed'], maxSpeed]], minSpeed], maxSpeed - minSpeed]]], 360], 360], ', 100%, 40%)'],
  ],
  'line-width': railwayLineWidth,
};

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

const electrificationCasingPaint = {
  'line-color': 'white',
  'line-width': railwayLineWidth,
  'line-gap-width': 0.75,
};
const electrificationFillPaint = (dashArray, voltageProperty, frequencyProperty) => ({
  'line-color': ['case',
    ['boolean', ['feature-state', 'hover'], false], ['case',
      ['==', ['get', voltageProperty], 25000], colors.hover.alternative,
      colors.hover.main,
    ],
    ['all', ['==', ['get', frequencyProperty], 60], ['==', ['get', voltageProperty], 25000]], color_25kv_60hz,
    ['all', ['==', ['get', frequencyProperty], 50], ['==', ['get', voltageProperty], 25000]], color_25kv_50hz,
    ['all', ['==', ['get', frequencyProperty], 60], ['==', ['get', voltageProperty], 20000]], color_20kv_60hz,
    ['all', ['==', ['get', frequencyProperty], 50], ['==', ['get', voltageProperty], 20000]], color_20kv_50hz,
    ['all', ['<', 16.665, ['get', frequencyProperty]], ['<', ['get', frequencyProperty], 16.675], ['==', ['get', voltageProperty], 15000]], color_15kv_16_67hz,
    ['all', ['<', 16.65, ['get', frequencyProperty]], ['<', ['get', frequencyProperty], 16.75], ['==', ['get', voltageProperty], 15000]], color_15kv_16_7hz,
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
    ['all', ['==', ['get', frequencyProperty], 0], ['!=', ['get', voltageProperty], null], ['<', 750, ['get', voltageProperty]]], color_lt750v_dc,
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
  ],
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

const gaugeCasingPaint = {
  'line-color': 'white',
  'line-width': railwayLineWidth,
  'line-gap-width': 0.75,
};

const gaugeFillPaint = (gaugeProperty, gaugeIntProperty, dashArray) => ({
  'line-color': ['case',
    ['boolean', ['feature-state', 'hover'], false], ['case',
      ['all', ['!=', ['get', gaugeIntProperty], null], ['>=', 1450, ['get', gaugeIntProperty]], ['<=', ['get', gaugeIntProperty], 1524]], colors.hover.alternative,
      colors.hover.main,
    ],
    // monorails or tracks with monorail gauge value
    ['any',
      ['==', ['get', 'railway'], 'monorail'],
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
  ],
  'line-width': railwayLineWidth,
  'line-dasharray': dashArray,
});
const gaugeLayout = {
  'line-join': 'round',
  'line-cap': 'round',
};

const attribution = '<a href="https://github.com/hiddewie/OpenRailwayMap-vector" target="_blank">&copy; OpenRailwayMap contributors</a>';

const sources = {
  background_map: {
    type: 'vector',
    url: 'https://api.maptiler.com/tiles/contours/tiles.json?key=get_your_own_OpIi9ZULNHzrESv6T2vL',
    // url: 'https://tile.ourmap.us/data/v3.json',
    // url: 'https://www.openhistoricalmap.org/map-styles/main/main.json',
    // tiles: [
    //   'https://vtiles.openhistoricalmap.org/maps/osm/{z}/{x}/{y}.pbf',
    //   'https://tile.openstreetmap.org/.png',
    // ],
    // tileSize: 256,
    // attribution: '<a href="https://www.openstreetmap.org/about" target="_blank">&copy; OpenStreetMap contributors</a>'
  },
  search: {
    type: 'geojson',
    data: {
      type: 'FeatureCollection',
      features: [],
    },
  },
  openrailwaymap_low: {
    type: 'vector',
    url: `${origin}/railway_line_low`,
    attribution,
    promoteId: 'id',
  },
  standard_railway_text_stations_low: {
    type: 'vector',
    url: `${origin}/standard_railway_text_stations_low`,
    attribution,
    promoteId: 'id',
  },
  openrailwaymap_med: {
    type: 'vector',
    url: `${origin}/railway_line_med`,
    attribution,
    promoteId: 'id',
  },
  standard_railway_text_stations_med: {
    type: 'vector',
    url: `${origin}/standard_railway_text_stations_med`,
    attribution,
    promoteId: 'id',
  },
  railway_line_high: {
    type: 'vector',
    url: `${origin}/railway_line_high`,
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

const backgroundColor = {
  id: 'background',
  type: 'background',
  paint: {
    'background-color': 'rgb(242, 243, 240)'
  }
};

const backgroundMap = {
  id: "background-map",
  'type': 'line',
  'source-layer': 'contour',
  'layout': {
    'line-join': 'round',
    'line-cap': 'round'
  },
  'paint': {
    'line-color': '#ff69b4',
    'line-width': 1
  },
  source: "background_map",
  // paint: {
  //   'raster-saturation': -1.0, // or 0.0 for colorful
  //   'raster-opacity': 1.0, // or 0.0 for transparent
  // }
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

// TODO remove all [switch, [zoom]] to ensure legend displays only visible features
const layers = {
  standard: [
    // backgroundColor,
    // backgroundMap,
    {
      id: 'railway_line_low_casing',
      type: 'line',
      maxzoom: 7,
      source: 'openrailwaymap_low',
      'source-layer': 'railway_line_low',
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: {
        'line-color': colors.styles.standard.casing.railway,
        'line-width': railwayLineWidth,
        'line-gap-width': railway_casing_add,
      }
    },
    {
      id: 'railway_line_low_fill',
      type: 'line',
      maxzoom: 7,
      source: 'openrailwaymap_low',
      'source-layer': 'railway_line_low',
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: standardLowFillPaint,
    },
    {
      id: 'railway_text_stations_low',
      type: 'symbol',
      minzoom: 5,
      maxzoom: 7,
      source: 'standard_railway_text_stations_low',
      'source-layer': 'standard_railway_text_stations_low',
      paint: {
        'text-color': 'blue',
        'text-halo-color': 'white',
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
      id: 'railway_line_med_casing',
      type: 'line',
      minzoom: 7,
      maxzoom: 8,
      source: 'openrailwaymap_med',
      'source-layer': 'railway_line_med',
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: {
        'line-color': colors.styles.standard.casing.railway,
        'line-width': railwayLineWidth,
        'line-gap-width': railway_casing_add,
      }
    },
    {
      id: 'railway_line_med_fill',
      type: 'line',
      minzoom: 7,
      maxzoom: 8,
      source: 'openrailwaymap_med',
      'source-layer': 'railway_line_med',
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: standardMediumFillPaint,
    },
    {
      id: 'railway_text_stations_med',
      type: 'symbol',
      minzoom: 7,
      maxzoom: 8,
      source: 'standard_railway_text_stations_med',
      'source-layer': 'standard_railway_text_stations_med',
      paint: {
        'text-color': 'blue',
        'text-halo-color': 'white',
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
      id: 'railway_tunnel_casing',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['get', 'tunnel'],
        ['!=', ['get', 'railway'], 'construction'],
        ['!=', ['get', 'railway'], 'proposed'],
        ['!=', ['get', 'railway'], 'abandoned'],
        ['!=', ['get', 'railway'], 'razed'],
      ],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: {
        'line-color': colors.styles.standard.casing.railway,
        'line-width': railwayLineWidth,
        'line-gap-width': railway_tunnel_casing_add,
      }
    },
    {
      id: 'railway_tunnel_fill',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['get', 'tunnel'],
        ['!=', ['get', 'railway'], 'construction'],
        ['!=', ['get', 'railway'], 'proposed'],
        ['!=', ['get', 'railway'], 'abandoned'],
        ['!=', ['get', 'railway'], 'razed'],
      ],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: standardFillPaint([1]),
    },
    {
      id: 'railway_tunnel_bright',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['get', 'tunnel'],
        ['!=', ['get', 'railway'], 'construction'],
        ['!=', ['get', 'railway'], 'proposed'],
        ['!=', ['get', 'railway'], 'abandoned'],
        ['!=', ['get', 'railway'], 'razed'],
      ],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: {
        ...standardFillPaint([1]),
        'line-color': 'rgba(255, 255, 255, 50%)',
      }
    },
    {
      id: 'railway_line_casing',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['!', ['get', 'bridge']],
        ['!', ['get', 'tunnel']],
        ['!=', ['get', 'railway'], 'construction'],
        ['!=', ['get', 'railway'], 'proposed'],
        ['!=', ['get', 'railway'], 'abandoned'],
        ['!=', ['get', 'railway'], 'razed'],
      ],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: {
        'line-color': colors.styles.standard.casing.railway,
        'line-width': railwayLineWidth,
        'line-gap-width': railway_casing_add,
      }
    },
    {
      id: 'railway_line_construction_casing',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['==', ['get', 'railway'], 'construction'],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: {
        'line-color': colors.styles.standard.casing.railway,
        'line-width': railwayLineWidth,
        'line-gap-width': railway_casing_add,
        'line-dasharray': construction_dasharray,
      }
    },
    {
      id: 'railway_line_proposed_casing',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['==', ['get', 'railway'], 'proposed'],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: {
        'line-color': colors.styles.standard.casing.railway,
        'line-width': railwayLineWidth,
        'line-gap-width': railway_casing_add,
        'line-dasharray': proposed_dasharray,
      }
    },
    {
      id: 'railway_line_abandoned_casing',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['==', ['get', 'railway'], 'abandoned'],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: {
        'line-color': colors.styles.standard.casing.railway,
        'line-width': railwayLineWidth,
        'line-gap-width': railway_casing_add,
        'line-dasharray': abandoned_dasharray,
      }
    },
    {
      id: 'railway_line_razed_casing',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['==', ['get', 'railway'], 'razed'],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: {
        'line-color': colors.styles.standard.casing.railway,
        'line-width': railwayLineWidth,
        'line-gap-width': railway_casing_add,
        'line-dasharray': razed_dasharray,
      }
    },
    {
      id: 'railway_construction_fill',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['==', ['get', 'railway'], 'construction'],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: standardFillPaint(construction_dasharray),
    },
    {
      id: 'railway_proposed_fill',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['==', ['get', 'railway'], 'proposed'],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: standardFillPaint(proposed_dasharray),
    },
    {
      id: 'railway_abandoned_fill',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['==', ['get', 'railway'], 'abandoned'],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: standardFillPaint(abandoned_dasharray),
    },
    {
      id: 'railway_razed_fill',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['==', ['get', 'railway'], 'razed'],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: standardFillPaint(razed_dasharray),
    },
    {
      id: 'railway_line_fill',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['!', ['get', 'bridge']],
        ['!', ['get', 'tunnel']],
        ['!=', ['get', 'railway'], 'construction'],
        ['!=', ['get', 'railway'], 'proposed'],
        ['!=', ['get', 'railway'], 'abandoned'],
        ['!=', ['get', 'railway'], 'razed'],
      ],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: standardFillPaint([1]),
    },
    {
      id: 'railway_bridge_railing',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['get', 'bridge'],
        ['!=', ['get', 'railway'], 'construction'],
        ['!=', ['get', 'railway'], 'proposed'],
        ['!=', ['get', 'railway'], 'abandoned'],
        ['!=', ['get', 'railway'], 'razed'],
      ],
      paint: {
        'line-color': colors.styles.standard.casing.bridge,
        'line-width': railwayLineWidth,
        'line-gap-width': bridge_casing_add,
      }
    },
    {
      id: 'railway_bridge_casing',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['get', 'bridge'],
        ['!=', ['get', 'railway'], 'construction'],
        ['!=', ['get', 'railway'], 'proposed'],
        ['!=', ['get', 'railway'], 'abandoned'],
        ['!=', ['get', 'railway'], 'razed'],
      ],
      paint: {
        'line-color': colors.styles.standard.casing.railway,
        'line-width': railwayLineWidth,
        'line-gap-width': railway_casing_add,
      }
    },
    {
      id: 'railway_bridge_fill',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['get', 'bridge'],
        ['!=', ['get', 'railway'], 'construction'],
        ['!=', ['get', 'railway'], 'proposed'],
        ['!=', ['get', 'railway'], 'abandoned'],
        ['!=', ['get', 'railway'], 'razed'],
      ],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: standardFillPaint([1]),
    },
    {
      id: 'railway_turntables_fill',
      type: 'fill',
      minzoom: 10,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_turntables',
      paint: {
        'fill-color': colors.styles.standard.turntable.fill,
      }
    },
    {
      id: 'railway_turntables_casing',
      type: 'line',
      minzoom: 15,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_turntables',
      paint: {
        'line-color': colors.styles.standard.turntable.casing,
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
    {
      id: 'railway_symbols_low',
      type: 'symbol',
      minzoom: 10,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_symbols',
      filter: ['==', ['get', 'feature'], 'general/border'],
      layout: {
        'icon-image': ['image', ['get', 'feature']],
      }
    },
    {
      id: 'railway_symbols_med_high',
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
        'icon-image': ['image', ['get', 'feature']],
      }
    },
    {
      id: 'railway_symbols_med',
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
        'icon-image': ['image', ['get', 'feature']],
      },
    },
    {
      id: 'railway_symbols_high',
      type: 'symbol',
      minzoom: 16,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_symbols',
      filter: ['==', ['get', 'feature'], 'general/phone'],
      layout: {
        'symbol-z-order': 'source',
        'icon-image': ['image', ['get', 'feature']],
      }
    },
    {
      id: 'railway_text_km',
      type: 'symbol',
      minzoom: 10,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_text_km',
      filter: ['step', ['zoom'],
        ['get', 'zero'],
        13,
        true,
      ],
      paint: {
        'text-color': 'black',
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors.hover.textHalo,
          'white',
        ],
        'text-halo-width': 1,
      },
      layout: {
        'symbol-z-order': 'source',
        'text-field': '{pos}',
        'text-font': ['Noto Sans Bold'],
        'text-size': 11,
      },
    },
    {
      id: 'railway_text_track_numbers',
      type: 'symbol',
      minzoom: 16,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['!=', ['get', 'track_ref'], null],
      paint: {
        'text-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors.hover.textHalo,
          'white',
        ],
        'text-halo-color': 'blue',
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
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['step', ['zoom'],
        ['all',
          ['!=', ['get', 'ref'], null],
          ['any',
            ['all',
              ['==', ['get', 'railway'], 'rail'],
              ['any',
                ['==', ['get', 'usage'], 'main'],
                ['==', ['get', 'usage'], 'branch'],
              ],
              ['==', ['get', 'service'], null],
            ],
            ['all',
              ['any',
                ['==', ['get', 'railway'], 'disused'],
                ['==', ['get', 'railway'], 'abandoned'],
              ],
              ['==', ['get', 'feature'], 'rail'],
              ['==', ['get', 'service'], null],
            ],
            ['all',
              ['any',
                ['==', ['get', 'railway'], 'construction'],
                ['==', ['get', 'railway'], 'proposed'],
              ],
              ['==', ['get', 'feature'], 'rail'],
              ['any',
                ['==', ['get', 'usage'], 'main'],
                ['==', ['get', 'usage'], 'branch'],
              ],
              ['==', ['get', 'service'], null],
            ],
          ],
        ],
        9,
        ['all',
          ['!=', ['get', 'ref'], null],
          ['any',
            ['all',
              ['==', ['get', 'railway'], 'rail'],
              ['any',
                ['==', ['get', 'usage'], 'main'],
                ['==', ['get', 'usage'], 'branch'],
                ['==', ['get', 'usage'], 'industrial'],
              ],
              ['==', ['get', 'service'], null],
            ],
            ['all',
              ['any',
                ['==', ['get', 'railway'], 'narrow_gauge'],
                ['==', ['get', 'railway'], 'subway'],
                ['==', ['get', 'railway'], 'light_rail'],
              ],
              ['==', ['get', 'service'], null],
            ],
            ['all',
              ['any',
                ['==', ['get', 'railway'], 'disused'],
                ['==', ['get', 'railway'], 'abandoned'],
                ['==', ['get', 'railway'], 'razed'],
              ],
              ['==', ['get', 'feature'], 'rail'],
              ['==', ['get', 'service'], null],
            ],
            ['all',
              ['any',
                ['==', ['get', 'railway'], 'construction'],
                ['==', ['get', 'railway'], 'proposed'],
              ],
              ['any',
                ['==', ['get', 'feature'], 'rail'],
                ['==', ['get', 'feature'], 'subway'],
                ['==', ['get', 'feature'], 'light_rail'],
              ],
              ['any',
                ['==', ['get', 'usage'], 'main'],
                ['==', ['get', 'usage'], 'branch'],
              ],
              ['==', ['get', 'service'], null],
            ],
          ],
        ],
        10,
        ['all',
          ['!=', ['get', 'ref'], null],
          ['any',
            ['all',
              ['==', ['get', 'railway'], 'rail'],
              ['any',
                ['==', ['get', 'usage'], 'main'],
                ['==', ['get', 'usage'], 'branch'],
              ],
              ['==', ['get', 'service'], null],
            ],
            ['all',
              ['==', ['get', 'railway'], 'rail'],
              ['==', ['get', 'usage'], 'industrial'],
            ],
            ['all',
              ['==', ['get', 'railway'], 'rail'],
              ['==', ['get', 'usage'], null],
              ['any',
                ['==', ['get', 'service'], 'siding'],
                ['==', ['get', 'service'], 'crossover'],
                ['==', ['get', 'service'], 'spur'],
              ],
            ],
            ['all',
              ['any',
                ['==', ['get', 'railway'], 'narrow_gauge'],
                ['==', ['get', 'railway'], 'subway'],
                ['==', ['get', 'railway'], 'light_rail'],
              ],
              ['any',
                ['==', ['get', 'service'], null],
                ['==', ['get', 'service'], 'siding'],
                ['==', ['get', 'service'], 'crossover'],
                ['==', ['get', 'service'], 'spur'],
              ],
            ],
            ['all',
              ['any',
                ['==', ['get', 'railway'], 'disused'],
                ['==', ['get', 'railway'], 'abandoned'],
                ['==', ['get', 'railway'], 'razed'],
              ],
              ['any',
                ['==', ['get', 'feature'], 'rail'],
                ['==', ['get', 'feature'], 'subway'],
                ['==', ['get', 'feature'], 'light_rail'],
              ],
              ['==', ['get', 'service'], null],
            ],
            ['all',
              ['any',
                ['==', ['get', 'railway'], 'construction'],
                ['==', ['get', 'railway'], 'proposed'],
              ],
              ['any',
                ['==', ['get', 'feature'], 'rail'],
                ['==', ['get', 'feature'], 'subway'],
                ['==', ['get', 'feature'], 'light_rail'],
                ['==', ['get', 'feature'], 'tram'],
              ],
              ['any',
                ['==', ['get', 'usage'], 'main'],
                ['==', ['get', 'usage'], 'branch'],
              ],
              ['==', ['get', 'service'], null],
            ],
            ['all',
              ['==', ['get', 'railway'], 'tram'],
              ['==', ['get', 'service'], null],
            ],
          ],
        ],
        11,
        ['all',
          ['!=', ['get', 'ref'], null],
          ['any',
            ['all',
              ['==', ['get', 'railway'], 'rail'],
              ['any',
                ['==', ['get', 'usage'], 'main'],
                ['==', ['get', 'usage'], 'branch'],
              ],
              ['==', ['get', 'service'], null],
            ],
            ['all',
              ['==', ['get', 'railway'], 'rail'],
              ['==', ['get', 'usage'], 'industrial'],
            ],
            ['all',
              ['==', ['get', 'railway'], 'rail'],
              ['==', ['get', 'usage'], null],
              ['any',
                ['==', ['get', 'service'], 'siding'],
                ['==', ['get', 'service'], 'crossover'],
                ['==', ['get', 'service'], 'spur'],
                ['==', ['get', 'service'], 'yard'],
              ],
            ],
            ['all',
              ['any',
                ['==', ['get', 'railway'], 'narrow_gauge'],
                ['==', ['get', 'railway'], 'subway'],
                ['==', ['get', 'railway'], 'light_rail'],
              ],
              ['any',
                ['==', ['get', 'service'], null],
                ['==', ['get', 'service'], 'siding'],
                ['==', ['get', 'service'], 'crossover'],
                ['==', ['get', 'service'], 'spur'],
                ['==', ['get', 'service'], 'yard'],
              ],
            ],
            ['all',
              ['any',
                ['==', ['get', 'railway'], 'disused'],
                ['==', ['get', 'railway'], 'abandoned'],
                ['==', ['get', 'railway'], 'razed'],
              ],
              ['any',
                ['==', ['get', 'feature'], 'rail'],
                ['==', ['get', 'feature'], 'subway'],
                ['==', ['get', 'feature'], 'light_rail'],
                ['==', ['get', 'feature'], 'tram'],
              ],
              ['==', ['get', 'service'], null],
            ],
            ['all',
              ['any',
                ['==', ['get', 'railway'], 'construction'],
                ['==', ['get', 'railway'], 'proposed'],
              ],
              ['any',
                ['==', ['get', 'feature'], 'rail'],
                ['==', ['get', 'feature'], 'subway'],
                ['==', ['get', 'feature'], 'light_rail'],
                ['==', ['get', 'feature'], 'tram'],
              ],
              ['any',
                ['==', ['get', 'usage'], 'main'],
                ['==', ['get', 'usage'], 'branch'],
              ],
              ['==', ['get', 'service'], null],
            ],
            ['all',
              ['==', ['get', 'railway'], 'tram'],
              ['==', ['get', 'service'], null],
            ],
          ],
        ],
        12,
        ['!=', ['get', 'ref'], null],
        14,
        ['!=', ['get', 'standard_label'], null],
      ],
      paint: {
        'text-color': '#585858',
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors.hover.textHalo,
          'white',
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
        'text-halo-color': ['case',
          // Invert coloring on hover
          ['boolean', ['feature-state', 'hover'], false], ['case',
            ['get', 'railway_local_operated'], 'white',
            colors.hover.textHalo,
          ],
          ['get', 'railway_local_operated'], 'yellow',
          'white'
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
          ['!=', ['get', 'station'], 'funicular'],
        ],
        10,
        ['all',
          ['!=', ['get', 'railway'], 'tram_stop'],
          ['!=', ['get', 'station'], 'funicular'],
        ],
        13,
        ['!=', ['get', 'station'], 'funicular'],
      ],
      paint: {
        'text-color': ['case',
          ['==', ['get', 'railway'], 'yard'], '#87491D',
          ['==', ['get', 'railway'], 'tram_stop'], '#D877B8',
          ['==', ['get', 'railway'], 'station'], 'blue',
          ['==', ['get', 'railway'], 'halt'], 'blue',
          '#616161',
        ],
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors.hover.textHalo,
          ['==', ['get', 'railway'], 'yard'], '#F1F1F1',
          ['==', ['get', 'railway'], 'tram_stop'], 'white',
          ['==', ['get', 'railway'], 'station'], 'white',
          ['==', ['get', 'railway'], 'halt'], 'white',
          '#F1F1F1',
        ],
        'text-halo-width': 1.5,
      },
      layout: {
        'symbol-z-order': 'source',
        'text-field': ['step', ['zoom'],
          ['get', 'label'],
          10,
          ['get', 'name'],
        ],
        // TODO light rail / subway oblique font
        'text-font': ['Noto Sans Bold'],
        // TODO text-variable-anchor-offset
        'text-size': 11,
        'text-padding': 10,
        'text-max-width': 5,
        'text-offset': ['case',
          ['==', ['get', 'railway'], 'tram_stop'], ['literal', [0, 1]],
          ['literal', [0, 0]]
        ],
      },
    },
    searchResults,
  ],

  speed: [
    backgroundColor,
    backgroundMap,
    {
      id: 'speed_railway_line_low_casing',
      type: 'line',
      source: 'openrailwaymap_low',
      maxzoom: 7,
      'source-layer': 'railway_line_low',
      paint: speedCasingPaint,
      layout: speedLayout,
    },
    {
      id: 'speed_railway_line_low_fill',
      type: 'line',
      source: 'openrailwaymap_low',
      maxzoom: 7,
      'source-layer': 'railway_line_low',
      paint: speedFillPaint,
      layout: speedLayout,
    },
    {
      id: 'speed_railway_line_med_casing',
      type: 'line',
      source: 'openrailwaymap_med',
      minzoom: 7,
      maxzoom: 8,
      'source-layer': 'railway_line_med',
      paint: speedCasingPaint,
      layout: speedLayout,
    },
    {
      id: 'speed_railway_line_med_fill',
      type: 'line',
      source: 'openrailwaymap_med',
      minzoom: 7,
      maxzoom: 8,
      'source-layer': 'railway_line_med',
      paint: speedFillPaint,
      layout: speedLayout,
    },
    {
      id: 'speed_railway_line_casing',
      type: 'line',
      source: 'railway_line_high',
      minzoom: 8,
      'source-layer': 'railway_line_high',
      paint: speedCasingPaint,
      layout: speedLayout,
    },
    {
      id: 'speed_railway_line_fill',
      type: 'line',
      source: 'railway_line_high',
      minzoom: 8,
      'source-layer': 'railway_line_high',
      paint: speedFillPaint,
      layout: speedLayout,
    },
    {
      id: 'speed_railway_signal_direction',
      type: 'symbol',
      minzoom: 13,
      source: 'openrailwaymap_speed',
      'source-layer': 'speed_railway_signals',
      filter: ['step', ['zoom'],
        ['all',
          ['!=', ['get', 'feature'], null],
          ['!=', ['get', 'azimuth'], null],
          ['==', ['get', 'type'], 'line'],
        ],
        14,
        ['all',
          ['!=', ['get', 'feature'], null],
          ['!=', ['get', 'azimuth'], null],
          ['any',
            ['==', ['get', 'type'], 'line'],
            ['==', ['get', 'type'], 'tram'],
          ]
        ],
        16,
        ['all',
          ['!=', ['get', 'feature'], null],
          ['!=', ['get', 'azimuth'], null],
        ],
      ],
      layout: {
        'icon-overlap': 'always',
        'icon-image': ['case',
          ['get', 'direction_both'], 'general/signal-direction-both',
          'general/signal-direction',
        ],
        'icon-anchor': ['case',
          ['get', 'direction_both'], 'center',
          'top',
        ],
        'icon-rotate': ['get', 'azimuth'],
      }
    },
    {
      id: 'speed_railway_signals',
      type: 'symbol',
      source: 'openrailwaymap_speed',
      minzoom: 13,
      'source-layer': 'speed_railway_signals',
      filter: ['step', ['zoom'],
        ['all',
          ['!=', ['get', 'feature'], null],
          ['==', ['get', 'type'], 'line'],
        ],
        14,
        ['all',
          ['!=', ['get', 'feature'], null],
          ['any',
            ['==', ['get', 'type'], 'line'],
            ['==', ['get', 'type'], 'tram'],
          ]
        ],
        16,
        ['!=', ['get', 'feature'], null],
      ],
      paint: {
        // TODO https://github.com/maplibre/martin/issues/1075
        // 'icon-halo-color': 'rgba(255, 255, 255, 1)',
        // 'icon-halo-blur': 0,
        // 'icon-halo-width': 2.0,
      },
      layout: {
        'symbol-z-order': 'source',
        'icon-overlap': 'always',
        'icon-image': ['image', ['get', 'feature']],
      }
    },
    {
      id: 'speed_railway_line_text',
      type: 'symbol',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      // TODO zoom filters do not match line zoom levels
      filter: ['step', ['zoom'],
        ['==', ['get', 'feature'], 'rail'],
        10,
        ['any',
          ['==', ['get', 'feature'], 'rail'],
          ['==', ['get', 'feature'], 'narrow_gauge'],
        ],
        11,
        ['any',
          ['==', ['get', 'feature'], 'rail'],
          ['==', ['get', 'feature'], 'narrow_gauge'],
          ['==', ['get', 'feature'], 'light_rail'],
          ['==', ['get', 'feature'], 'subway'],
        ],
        12,
        true,
      ],
      paint: {
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors.hover.textHalo,
          'white'
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
        'symbol-spacing': 100,
      },
    },
    searchResults,
  ],

  signals: [
    backgroundColor,
    backgroundMap,
    {
      id: 'railway_line_low_casing',
      type: 'line',
      source: 'openrailwaymap_low',
      maxzoom: 7,
      'source-layer': 'railway_line_low',
      paint: trainProtectionCasingPaint([1]),
      layout: trainProtectionLayout,
    },
    {
      id: 'railway_line_low_fill',
      type: 'line',
      source: 'openrailwaymap_low',
      maxzoom: 7,
      'source-layer': 'railway_line_low',
      paint: trainProtectionFillPaint([1]),
      layout: trainProtectionLayout,
    },
    {
      id: 'railway_line_med_casing',
      type: 'line',
      minzoom: 7,
      maxzoom: 8,
      source: 'openrailwaymap_med',
      'source-layer': 'railway_line_med',
      paint: trainProtectionCasingPaint([1]),
      layout: trainProtectionLayout,
    },
    {
      id: 'railway_line_med_fill',
      type: 'line',
      minzoom: 7,
      maxzoom: 8,
      source: 'openrailwaymap_med',
      'source-layer': 'railway_line_med',
      paint: trainProtectionFillPaint([1]),
      layout: trainProtectionLayout,
    },
    {
      id: 'railway_line_casing_construction',
      type: 'line',
      source: 'railway_line_high',
      minzoom: 8,
      'source-layer': 'railway_line_high',
      filter: ['==', ['get', 'railway'], 'construction'],
      paint: trainProtectionCasingPaint([2, 2]),
      layout: trainProtectionLayout,
    },
    {
      id: 'railway_line_casing',
      type: 'line',
      source: 'railway_line_high',
      minzoom: 8,
      'source-layer': 'railway_line_high',
      filter: ['!=', ['get', 'railway'], 'construction'],
      paint: trainProtectionCasingPaint([1]),
      layout: trainProtectionLayout,
    },
    {
      id: 'railway_line_fill_construction',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['==', ['get', 'railway'], 'construction'],
      paint: trainProtectionFillPaint([2, 2]),
      layout: trainProtectionLayout,
    },
    {
      id: 'railway_line_fill',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['!=', ['get', 'railway'], 'construction'],
      paint: trainProtectionFillPaint([1]),
      layout: trainProtectionLayout,
    },
    {
      id: 'signal_boxes_point',
      type: 'circle',
      minzoom: 10,
      source: 'openrailwaymap_signals',
      'source-layer': 'signals_signal_boxes',
      filter: ['==', ["geometry-type"], 'Point'],
      paint: {
        'circle-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors.hover.main,
          '#008206',
        ],
        'circle-radius': 6,
        'circle-stroke-color': 'white',
        'circle-stroke-width': 1,
      },
    },
    {
      id: 'signal_boxes_polygon',
      type: 'fill',
      minzoom: 12,
      source: 'openrailwaymap_signals',
      'source-layer': 'signals_signal_boxes',
      filter: ['any',
        ['==', ["geometry-type"], 'Polygon'],
        ['==', ["geometry-type"], 'MultiPolygon'],
      ],
      paint: {
        'fill-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors.hover.main,
          '#008206',
        ],
        'fill-outline-color': 'white',
      },
    },
    {
      id: 'signal_boxes_polygon_outline',
      type: 'line',
      minzoom: 12,
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
        ['!=', ['get', 'feature'], ''],
      ],
      layout: {
        'icon-overlap': 'always',
        'icon-image': ['case',
          ['get', 'direction_both'], 'general/signal-direction-both',
          'general/signal-direction',
        ],
        'icon-anchor': ['case',
          ['get', 'direction_both'], 'center',
          'top',
        ],
        'icon-rotate': ['get', 'azimuth'],
      }
    },
    {
      id: 'railway_signals',
      type: 'symbol',
      minzoom: 13,
      source: 'openrailwaymap_signals',
      'source-layer': 'signals_railway_signals',
      paint: {
        // TODO https://github.com/maplibre/martin/issues/1075
        // 'icon-halo-color': 'rgba(255, 255, 255, 1)',
        // 'icon-halo-blur': 0,
        // 'icon-halo-width': 2.0,
      },
      layout: {
        'symbol-z-order': 'source',
        'icon-overlap': 'always',
        'icon-image': ['step', ['zoom'],
          ['case',
            ['==', ['slice', ['get', 'feature'], 0, 20], 'de/blockkennzeichen-'], 'de/blockkennzeichen',
            ['image', ['get', 'feature']],
          ],
          16,
          ['image', ['get', 'feature']],
        ],
      }
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
      paint: {
        'text-color': '#404040',
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors.hover.textHalo,
          '#bfffb3',
        ],
        'text-halo-width': 1.5,
      },
      layout: {
        'text-field': '{ref}',
        'text-font': ['Noto Sans Bold'],
        'text-size': 11,
      }
    },
    {
      id: 'signal_boxes_text_high',
      type: 'symbol',
      minzoom: 15,
      source: 'openrailwaymap_signals',
      'source-layer': 'signals_signal_boxes',
      paint: {
        'text-color': '#404040',
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors.hover.textHalo,
          '#bfffb3',
        ],
        'text-halo-width': 1.5,
      },
      layout: {
        'text-field': '{name}',
        'text-font': ['Noto Sans Bold'],
        'text-size': 11,
      }
    },
    {
      id: 'railway_signals_blockkennzeichen_text',
      type: 'symbol',
      minzoom: 16,
      source: 'openrailwaymap_signals',
      'source-layer': 'signals_railway_signals',
      filter: ['all',
        ['!=', ['get', 'ref_multiline'], null],
        ['==', ['slice', ['get', 'feature'], 0, 20], 'de/blockkennzeichen-'],
      ],
      paint: {
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors.hover.textHalo,
          'white'
        ],
        'text-halo-width': 2,
      },
      layout: {
        'text-field': '{ref_multiline}',
        'text-font': ['Noto Sans Bold'],
        'text-size': 9,
        'text-anchor': 'center',
        'text-overlap': 'always',
      },
    },
    {
      id: 'railway_signals_text',
      type: 'symbol',
      minzoom: 13,
      source: 'openrailwaymap_signals',
      'source-layer': 'signals_railway_signals',
      filter: ['step', ['zoom'],
        ['all',
          ['!=', ['get', 'ref'], null],
          ['!=', ['get', 'feature'], ''],
        ],
        16,
        ['all',
          ['!=', ['get', 'ref'], null],
          ['!=', ['get', 'feature'], ''],
          ['!=', ['slice', ['get', 'feature'], 0, 20], 'de/blockkennzeichen-'],
        ],
      ],
      paint: {
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors.hover.textHalo,
          'white'
        ],
        'text-halo-width': 1.5,
        'text-halo-blur': 1,
      },
      layout: {
        'text-field': '{ref}',
        'text-font': ['Noto Sans Medium'],
        'text-size': 9,
        'text-anchor': 'top',
        'text-offset': ['case',
          ['==', ['get', 'main_height'], 'dwarf'], ['literal', [0, 1]],
          ['any',
            ['all',
              ['==', ['get', 'main_form'], 'light'],
              ['==', ['get', 'speed_limit_form'], 'light'],
            ],
            ['all',
              ['==', ['get', 'distant_form'], 'light'],
              ['==', ['get', 'speed_limit_form'], 'light'],
            ],
          ], ['literal', [0, 2]],
          ['literal', [0, 1.5]],
        ],
      }
    },
    searchResults,
  ],

  electrification: [
    backgroundColor,
    backgroundMap,
    {
      id: 'electrification_railway_line_low_casing',
      type: 'line',
      maxzoom: 7,
      source: 'openrailwaymap_low',
      'source-layer': 'railway_line_low',
      paint: electrificationCasingPaint,
      layout: electrificationLayout,
    },
    {
      id: 'electrification_railway_line_low_fill',
      type: 'line',
      maxzoom: 7,
      source: 'openrailwaymap_low',
      'source-layer': 'railway_line_low',
      paint: electrificationFillPaint([1], 'voltage', 'frequency'),
      layout: electrificationLayout,
    },
    {
      id: 'electrification_railway_line_med_casing',
      type: 'line',
      minzoom: 7,
      maxzoom: 8,
      source: 'openrailwaymap_med',
      'source-layer': 'railway_line_med',
      paint: electrificationCasingPaint,
      layout: electrificationLayout,
    },
    {
      id: 'electrification_railway_line_med_fill',
      type: 'line',
      minzoom: 7,
      maxzoom: 8,
      source: 'openrailwaymap_med',
      'source-layer': 'railway_line_med',
      paint: electrificationFillPaint([1], 'voltage', 'frequency'),
      layout: electrificationLayout,
    },
    {
      id: 'electrification_railway_line_casing',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      paint: electrificationCasingPaint,
      layout: electrificationLayout,
    },
    {
      id: 'electrification_railway_line_fill',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      paint: electrificationFillPaint([1], 'voltage', 'frequency'),
      layout: electrificationLayout,
    },
    {
      id: 'electrification_future_proposed',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['==', ['get', 'electrification_state'], 'proposed'],
      paint: electrificationFillPaint(electrification_proposed_dashes, 'future_voltage', 'future_frequency'),
      layout: electrificationLayout,
    },
    {
      id: 'electrification_future_construction',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['==', ['get', 'electrification_state'], 'construction'],
      paint: electrificationFillPaint(electrification_construction_dashes, 'future_voltage', 'future_frequency'),
      layout: electrificationLayout,
    },
    {
      id: 'electrification_signals_direction',
      type: 'symbol',
      minzoom: 16,
      source: 'openrailwaymap_electrification',
      'source-layer': 'electrification_signals',
      filter: ['all',
        ['!=', ['get', 'azimuth'], null],
        ['!=', ['get', 'feature'], ''],
      ],
      layout: {
        'icon-overlap': 'always',
        'icon-image': ['case',
          ['get', 'direction_both'], 'general/signal-direction-both',
          'general/signal-direction',
        ],
        'icon-anchor': ['case',
          ['get', 'direction_both'], 'center',
          'top',
        ],
        'icon-rotate': ['get', 'azimuth'],
      }
    },
    {
      id: 'electrification_signals',
      type: 'symbol',
      minzoom: 16,
      source: 'openrailwaymap_electrification',
      'source-layer': 'electrification_signals',
      paint: {
        // TODO https://github.com/maplibre/martin/issues/1075
        // 'icon-halo-color': 'rgba(255, 255, 255, 1)',
        // 'icon-halo-blur': 0,
        // 'icon-halo-width': 2.0,
      },
      layout: {
        'icon-overlap': 'always',
        'icon-image': ['image', ['get', 'feature']],
      }
    },
    {
      id: 'electrification_railway_text_high',
      type: 'symbol',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['step', ['zoom'],
        ['all',
          ['==', ['get', 'railway'], 'rail'],
          ['any',
            ['==', ['get', 'usage'], 'main'],
            ['==', ['get', 'usage'], 'branch'],
          ],
          ['==', ['get', 'service'], null],
        ],
        9,
        ['all',
          ['==', ['get', 'railway'], 'rail'],
          ['any',
            ['==', ['get', 'usage'], 'main'],
            ['==', ['get', 'usage'], 'branch'],
            ['==', ['get', 'usage'], 'industrial'],
          ],
          ['==', ['get', 'service'], null],
        ],
        10,
        ['any',
          ['all',
            ['==', ['get', 'railway'], 'rail'],
            ['any',
              ['==', ['get', 'usage'], 'main'],
              ['==', ['get', 'usage'], 'branch'],
            ],
            ['==', ['get', 'service'], null],
          ],
          ['all',
            ['==', ['get', 'railway'], 'rail'],
            ['==', ['get', 'usage'], 'industrial'],
          ],
          ['all',
            ['==', ['get', 'railway'], 'rail'],
            ['==', ['get', 'usage'], null],
            ['any',
              ['==', ['get', 'service'], 'siding'],
              ['==', ['get', 'service'], 'crossover'],
              ['==', ['get', 'service'], 'spur'],
            ],
          ],
          ['all',
            ['==', ['get', 'railway'], 'narrow_gauge'],
            ['any',
              ['==', ['get', 'service'], null],
              ['==', ['get', 'service'], 'siding'],
              ['==', ['get', 'service'], 'crossover'],
              ['==', ['get', 'service'], 'spur'],
            ],
          ],
          ['all',
            ['==', ['get', 'railway'], 'construction'],
            ['==', ['get', 'feature'], 'rail'],
            ['any',
              ['==', ['get', 'usage'], 'main'],
              ['==', ['get', 'usage'], 'branch'],
            ],
            ['==', ['get', 'service'], null],
          ],
        ],
        11,
        ['any',
          ['all',
            ['==', ['get', 'railway'], 'rail'],
            ['any',
              ['==', ['get', 'usage'], 'main'],
              ['==', ['get', 'usage'], 'branch'],
            ],
            ['==', ['get', 'service'], null],
          ],
          ['all',
            ['==', ['get', 'railway'], 'rail'],
            ['==', ['get', 'usage'], 'industrial'],
          ],
          ['all',
            ['==', ['get', 'railway'], 'rail'],
            ['==', ['get', 'usage'], null],
            ['any',
              ['==', ['get', 'service'], 'siding'],
              ['==', ['get', 'service'], 'crossover'],
              ['==', ['get', 'service'], 'spur'],
              ['==', ['get', 'service'], 'yard'],
            ],
          ],
          ['all',
            ['==', ['get', 'railway'], 'narrow_gauge'],
            ['any',
              ['==', ['get', 'service'], null],
              ['==', ['get', 'service'], 'siding'],
              ['==', ['get', 'service'], 'crossover'],
              ['==', ['get', 'service'], 'spur'],
              ['==', ['get', 'service'], 'yard'],
            ],
          ],
          ['all',
            ['==', ['get', 'railway'], 'construction'],
            ['==', ['get', 'feature'], 'rail'],
            ['any',
              ['==', ['get', 'usage'], 'main'],
              ['==', ['get', 'usage'], 'branch'],
              ['==', ['get', 'usage'], 'subway'],
              ['==', ['get', 'usage'], 'light_rail'],
            ],
            ['==', ['get', 'service'], null],
          ],
          ['all',
            ['any',
              ['==', ['get', 'railway'], 'subway'],
              ['==', ['get', 'railway'], 'light_rail'],
            ],
            ['==', ['get', 'service'], null],
          ],
        ],
        12,
        true,
      ],
      paint: {
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors.hover.textHalo,
          'white'
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
        'symbol-spacing': 100,
      },
    },
    searchResults,
  ],

  gauge: [
    backgroundColor,
    backgroundMap,
    {
      id: 'gauge_railway_line_low_casing',
      type: 'line',
      maxzoom: 7,
      source: 'openrailwaymap_low',
      'source-layer': 'railway_line_low',
      paint: gaugeCasingPaint,
      layout: gaugeLayout,
    },
    {
      id: 'gauge_railway_line_low_fill',
      type: 'line',
      maxzoom: 7,
      source: 'openrailwaymap_low',
      'source-layer': 'railway_line_low',
      paint: gaugeFillPaint('gauge0', 'gaugeint0', [1]),
      layout: gaugeLayout,
    },
    {
      id: 'gauge_railway_line_med_casing',
      type: 'line',
      minzoom: 7,
      maxzoom: 8,
      source: 'openrailwaymap_med',
      'source-layer': 'railway_line_med',
      paint: gaugeCasingPaint,
      layout: gaugeLayout,
    },
    {
      id: 'gauge_railway_line_med_fill',
      type: 'line',
      minzoom: 7,
      maxzoom: 8,
      source: 'openrailwaymap_med',
      'source-layer': 'railway_line_med',
      paint: gaugeFillPaint('gauge0', 'gaugeint0', [1]),
      layout: gaugeLayout,
    },
    {
      id: 'gauge_railway_line_casing',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['!=', ['get', 'railway'], 'construction'],
      paint: gaugeCasingPaint,
      layout: gaugeLayout,
    },
    {
      id: 'gauge_railway_line_casing_construction',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['==', ['get', 'railway'], 'construction'],
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
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['!=', ['get', 'railway'], 'construction'],
      paint: gaugeFillPaint('gauge0', 'gaugeint0', [1]),
      layout: gaugeLayout,
    },
    {
      id: 'gauge_railway_line_fill_construction',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['==', ['get', 'railway'], 'construction'],
      paint: gaugeFillPaint('gauge0', 'gaugeint0', gauge_construction_dashes),
      layout: gaugeLayout,
    },
    {
      id: 'gauge_railway_dual_gauge_line',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['!=', ['get', 'gauge1'], null],
        ['!=', ['get', 'railway'], 'construction'],
      ],
      paint: gaugeFillPaint('gauge1', 'gaugeint1', gauge_dual_gauge_dashes),
      layout: gaugeLayout,
    },
    {
      id: 'gauge_railway_dual_gauge_line_construction',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['!=', ['get', 'gauge1'], null],
        ['==', ['get', 'railway'], 'construction'],
      ],
      paint: gaugeFillPaint('gauge1', 'gaugeint1', dual_construction_dashes),
      layout: gaugeLayout,
    },
    {
      id: 'gauge_railway_multi_gauge_line',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['!=', ['get', 'gauge2'], null],
        ['!=', ['get', 'railway'], 'construction'],
      ],
      paint: gaugeFillPaint('gauge2', 'gaugeint2', gauge_multi_gauge_dashes),
      layout: gaugeLayout,
    },
    {
      id: 'gauge_railway_multi_gauge_line_construction',
      type: 'line',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['all',
        ['!=', ['get', 'gauge2'], null],
        ['==', ['get', 'railway'], 'construction'],
      ],
      paint: gaugeFillPaint('gauge2', 'gaugeint2', multi_construction_dashes),
      layout: gaugeLayout,
    },
    {
      id: 'gauge_railway_text_high',
      type: 'symbol',
      minzoom: 8,
      source: 'railway_line_high',
      'source-layer': 'railway_line_high',
      filter: ['step', ['zoom'],
        ['all',
          ['==', ['get', 'feature'], 'rail'],
          ['any',
            ['==', ['get', 'usage'], 'main'],
            ['==', ['get', 'usage'], 'branch'],
          ],
          ['==', ['get', 'service'], null],
        ],
        9,
        ['all',
          ['==', ['get', 'feature'], 'rail'],
          ['any',
            ['==', ['get', 'usage'], 'main'],
            ['==', ['get', 'usage'], 'branch'],
            ['==', ['get', 'usage'], 'industrial'],
          ],
          ['==', ['get', 'service'], null],
        ],
        10,
        ['any',
          ['all',
            ['==', ['get', 'feature'], 'rail'],
            ['any',
              ['==', ['get', 'usage'], 'main'],
              ['==', ['get', 'usage'], 'branch'],
            ],
            ['==', ['get', 'service'], null],
          ],
          ['all',
            ['==', ['get', 'feature'], 'rail'],
            ['==', ['get', 'usage'], 'industrial'],
          ],
          ['all',
            ['==', ['get', 'feature'], 'rail'],
            ['==', ['get', 'usage'], null],
            ['any',
              ['==', ['get', 'service'], 'siding'],
              ['==', ['get', 'service'], 'crossover'],
              ['==', ['get', 'service'], 'spur'],
            ],
          ],
          ['all',
            ['==', ['get', 'feature'], 'narrow_gauge'],
            ['any',
              ['==', ['get', 'service'], null],
              ['==', ['get', 'service'], 'siding'],
              ['==', ['get', 'service'], 'crossover'],
              ['==', ['get', 'service'], 'spur'],
            ],
          ],
          ['all',
            ['==', ['get', 'railway'], 'construction'],
            ['==', ['get', 'feature'], 'rail'],
            ['any',
              ['==', ['get', 'usage'], 'main'],
              ['==', ['get', 'usage'], 'branch'],
            ],
            ['==', ['get', 'service'], null],
          ],
        ],
        11,
        ['any',
          ['all',
            ['==', ['get', 'feature'], 'rail'],
            ['any',
              ['==', ['get', 'usage'], 'main'],
              ['==', ['get', 'usage'], 'branch'],
            ],
            ['==', ['get', 'service'], null],
          ],
          ['all',
            ['==', ['get', 'railway'], 'rail'],
            ['==', ['get', 'usage'], 'industrial'],
          ],
          ['all',
            ['==', ['get', 'feature'], 'rail'],
            ['==', ['get', 'usage'], null],
            ['any',
              ['==', ['get', 'service'], 'siding'],
              ['==', ['get', 'service'], 'crossover'],
              ['==', ['get', 'service'], 'spur'],
              ['==', ['get', 'service'], 'yard'],
            ],
          ],
          ['all',
            ['==', ['get', 'feature'], 'narrow_gauge'],
            ['any',
              ['==', ['get', 'service'], null],
              ['==', ['get', 'service'], 'siding'],
              ['==', ['get', 'service'], 'crossover'],
              ['==', ['get', 'service'], 'spur'],
              ['==', ['get', 'service'], 'yard'],
            ],
          ],
          ['all',
            ['==', ['get', 'railway'], 'construction'],
            ['==', ['get', 'feature'], 'rail'],
            ['any',
              ['==', ['get', 'usage'], 'main'],
              ['==', ['get', 'usage'], 'branch'],
              ['==', ['get', 'usage'], 'subway'],
              ['==', ['get', 'usage'], 'light_rail'],
            ],
            ['==', ['get', 'service'], null],
          ],
          ['all',
            ['any',
              ['==', ['get', 'feature'], 'subway'],
              ['==', ['get', 'feature'], 'light_rail'],
            ],
            ['==', ['get', 'service'], null],
          ],
        ],
        12,
        true,
      ],
      paint: {
        'text-halo-color': ['case',
          ['boolean', ['feature-state', 'hover'], false], colors.hover.textHalo,
          'white'
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
        'symbol-spacing': 100,
      },
    },
    searchResults,
  ],
};

const makeStyle = selectedStyle => ({
  center: [12.55, 51.14], // default
  zoom: 3.75, // default
  glyphs: `${origin}/font/{fontstack}/{range}`,
  metadata: {},
  name: `OpenRailwayMap ${selectedStyle}`,
  sources,
  sprite: [
    {
      id: 'default',
      url: `${origin}/sprite/symbols`,
    }
  ],
  version: 8,
  layers: layers[selectedStyle],
});

const legendData = {
  standard: {
    'openrailwaymap_low-railway_line_low': [
      {
        legend: 'Highspeed main line',
        type: 'line',
        properties: {
          highspeed: true,
        },
      },
      {
        legend: 'Main line',
        type: 'line',
        properties: {
          highspeed: false,
        }
      },
    ],
    "openrailwaymap_med-railway_line_med": [
      {
        legend: 'Highspeed main line',
        type: 'line',
        properties: {
          highspeed: true,
          usage: 'main',
        },
      },
      {
        legend: 'Main line',
        type: 'line',
        properties: {
          highspeed: false,
          usage: 'main',
        }
      },
      {
        legend: 'Branch line',
        type: 'line',
        properties: {
          highspeed: false,
          usage: 'branch',
        }
      },
    ],
    "railway_line_high-railway_line_high": [
      {
        legend: 'Highspeed main line',
        type: 'line',
        properties: {
          highspeed: true,
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          service: null,
          tunnel: false,
          bridge: false,
          ref: 'L1',
          standard_label: 'Name',
          track_ref: '8b',
        },
      },
      {
        legend: 'Main line',
        type: 'line',
        properties: {
          highspeed: false,
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          service: null,
          tunnel: false,
          bridge: false,
          ref: 'L1',
          standard_label: 'Name',
          track_ref: '8b',
        },
        variants: [
          {
            legend: 'bridge',
            properties: {
              bridge: true,
              standard_label: null,
              ref: null,
              track_ref: null,
            },
          },
          {
            legend: 'tunnel',
            properties: {
              tunnel: true,
              standard_label: null,
              ref: null,
              track_ref: null,
            },
          },
        ],
      },
      {
        legend: 'Branch line',
        type: 'line',
        properties: {
          highspeed: false,
          railway: 'rail',
          feature: 'rail',
          usage: 'branch',
          service: null,
          tunnel: false,
          bridge: false,
          ref: 'L1',
          standard_label: 'Name',
          track_ref: '8b',
        }
      },
      {
        legend: 'Industrial line',
        type: 'line',
        properties: {
          highspeed: false,
          railway: 'rail',
          feature: 'rail',
          usage: 'industrial',
          service: null,
          tunnel: false,
          bridge: false,
          ref: 'L1',
          standard_label: 'Name',
          track_ref: '8b',
        }
      },
      {
        legend: 'Narrow gauge line',
        type: 'line',
        properties: {
          highspeed: false,
          railway: 'narrow_gauge',
          feature: 'narrow_gauge',
          usage: null,
          service: null,
          tunnel: false,
          bridge: false,
          ref: 'L1',
          standard_label: 'Name',
          track_ref: '8b',
        }
      },
      {
        legend: 'Tourism line',
        type: 'line',
        properties: {
          highspeed: false,
          railway: 'preserved',
          feature: 'rail',
          usage: 'tourism',
          service: null,
          tunnel: false,
          bridge: false,
          ref: 'L1',
          standard_label: 'Name',
          track_ref: '8b',
        }
      },
      {
        legend: 'Subway',
        type: 'line',
        properties: {
          highspeed: false,
          railway: 'subway',
          feature: 'subway',
          usage: null,
          service: null,
          tunnel: false,
          bridge: false,
          ref: 'L1',
          standard_label: 'Name',
          track_ref: '8b',
        }
      },
      {
        legend: 'Light rail',
        type: 'line',
        properties: {
          highspeed: false,
          railway: 'light_rail',
          feature: 'light_rail',
          usage: null,
          service: null,
          tunnel: false,
          bridge: false,
          ref: 'L1',
          standard_label: null,
          track_ref: '8b',
        }
      },
      {
        legend: 'Tram',
        type: 'line',
        properties: {
          highspeed: false,
          railway: 'tram',
          feature: 'tram',
          usage: null,
          service: null,
          tunnel: false,
          bridge: false,
          ref: 'L1',
          standard_label: 'Name',
          track_ref: '8b',
        }
      },
      {
        legend: 'Under construction',
        type: 'line',
        properties: {
          highspeed: false,
          railway: 'construction',
          feature: 'rail',
          usage: 'main',
          service: null,
          tunnel: false,
          bridge: false,
          ref: null,
          standard_label: null,
          track_ref: null,
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
    "openrailwaymap_standard-standard_railway_text_stations": [
      {
        legend: 'Railway station / halt',
        type: 'point',
        properties: {
          railway: 'station',
          station: null,
          label: 'Gd',
          name: 'Gouda',
        },
      },
      {
        legend: 'Tram station',
        type: 'point',
        properties: {
          railway: 'tram_stop',
          station: null,
          label: null,
          name: 'Llacuna',
        },
      },
      {
        legend: 'Railway yard',
        type: 'point',
        properties: {
          railway: 'yard',
          station: null,
          label: null,
          name: 'Kijfhoek',
        },
      },
    ],
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
      {
        legend: 'Tram stop',
        type: 'point',
        properties: {
          feature: 'general/tram-stop',
        },
      },
      {
        legend: 'Border crossing',
        type: 'point',
        properties: {
          feature: 'general/border',
        },
        variants: [
          {
            legend: 'owner change',
            properties: {
              feature: 'general/owner-change',
            },
          },
        ],
      },
      {
        legend: 'Radio mast',
        type: 'point',
        properties: {
          feature: 'general/radio-mast',
        },
        variants: [
          {
            legend: 'antenna',
            properties: {
              feature: 'general/radio-antenna',
            }
          }
        ]
      },
      {
        legend: 'Crossing',
        type: 'point',
        properties: {
          feature: 'general/crossing',
        },
        variants: [
          {
            legend: 'level crossing',
            properties: {
              feature: 'general/level-crossing',
            }
          },
          {
            legend: 'lights',
            properties: {
              feature: 'general/level-crossing-light',
            }
          },
          {
            legend: 'barrier',
            properties: {
              feature: 'general/level-crossing-barrier',
            }
          }
        ]
      },
      {
        legend: 'Phone',
        type: 'point',
        properties: {
          feature: 'general/phone',
        },
      },
      {
        legend: 'Lubricator',
        type: 'point',
        properties: {
          feature: 'general/lubricator',
        },
      },
      {
        legend: 'Fuel',
        type: 'point',
        properties: {
          feature: 'general/fuel',
        },
      },
      {
        legend: 'Sand store',
        type: 'point',
        properties: {
          feature: 'general/sand_store',
        },
      },
      {
        legend: 'Defect detector',
        type: 'point',
        properties: {
          feature: 'general/defect_detector',
        },
      },
      {
        legend: 'Automatic equipment identification',
        type: 'point',
        properties: {
          feature: 'general/aei',
        },
      },
      {
        legend: 'Buffer stop',
        type: 'point',
        properties: {
          feature: 'general/buffer_stop',
        },
        variants: [
          {
            legend: 'Derailer',
            properties: {
              feature: 'general/derail',
            }
          }
        ]
      },
      {
        legend: 'Hump yard',
        type: 'point',
        properties: {
          feature: 'general/hump_yard',
        },
      },
      {
        legend: 'Loading gauge',
        type: 'point',
        properties: {
          feature: 'general/loading_gauge',
        },
      },
      {
        legend: 'Preheating',
        type: 'point',
        properties: {
          feature: 'general/preheating',
        },
      },
      {
        legend: 'Compressed air supply',
        type: 'point',
        properties: {
          feature: 'general/compressed_air_supply',
        },
      },
      {
        legend: 'Waste disposal',
        type: 'point',
        properties: {
          feature: 'general/waste_disposal',
        },
      },
      {
        legend: 'Coaling facility',
        type: 'point',
        properties: {
          feature: 'general/coaling_facility',
        },
      },
      {
        legend: 'Wash',
        type: 'point',
        properties: {
          feature: 'general/wash',
        },
      },
      {
        legend: 'Water tower',
        type: 'point',
        properties: {
          feature: 'general/water_tower',
        },
        variants: [
          {
            legend: 'crane',
            properties: {
              feature: 'general/water_crane',
            },
          },
        ]
      },
      {
        legend: 'Axle counter',
        type: 'point',
        properties: {
          feature: 'general/vacancy-detection-axle-counter',
        },
        variants: [
          {
            legend: 'insulated rail joint',
            properties: {
              feature: 'general/vacancy-detection-insulated-rail-joint',
            }
          },
        ]
      },
    ],
    "openrailwaymap_standard-standard_railway_text_km": [
      {
        legend: 'Milestone',
        type: 'point',
        properties: {
          zero: true,
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
    'openrailwaymap_low-railway_line_low': [
      ...speedLegends.map(speed => ({
        legend: `${speed} km/h`,
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          maxspeed: speed,
        },
      })),
      {
        legend: '(unknown)',
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          maxspeed: null,
        },
      },
    ],
    'openrailwaymap_med-railway_line_med': [
      ...speedLegends.map(speed => ({
        legend: `${speed} km/h`,
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          maxspeed: speed,
        },
      })),
      {
        legend: '(unknown)',
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          maxspeed: null,
        },
      },
    ],
    'railway_line_high-railway_line_high': [
      ...speedLegends.map(speed => ({
        legend: `${speed} km/h`,
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          maxspeed: speed,
          speed_label: `${speed}`,
        },
      })),
      {
        legend: '(unknown)',
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          maxspeed: null,
          speed_label: '',
        },
      },
    ],
    'openrailwaymap_speed-speed_railway_signals': [
      // TODO filter per country polygon
      ...speed_railway_signals.features.map(feature => ({
        legend: `(${feature.country}) ${feature.description}`,
        type: 'point',
        properties: {
          feature: feature.icon.default,
          type: 'line',
          azimuth: null,
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
    ],
  },
  signals: {
    'openrailwaymap_low-railway_line_low': [
      ...signals_railway_line.train_protections.map(train_protection => ({
        legend: train_protection.legend,
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
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
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          service: null,
          train_protection: null,
          train_protection_rank: 0,
        },
      },
    ],
    'openrailwaymap_med-railway_line_med': [
      ...signals_railway_line.train_protections.map(train_protection => ({
        legend: train_protection.legend,
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
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
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          service: null,
          train_protection: null,
          train_protection_rank: 0,
        },
      },
    ],
    'railway_line_high-railway_line_high': [
      ...signals_railway_line.train_protections.map(train_protection => ({
        legend: train_protection.legend,
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
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
          railway: 'rail',
          feature: 'rail',
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
          railway: 'construction',
          feature: 'rail',
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
    'openrailwaymap_signals-signals_railway_signals': [
      ...signals_railway_signals.features.map(feature => ({
        legend: `${feature.country ? `(${feature.country}) ` : ''}${feature.description}`,
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
      // TODO country specific railway signals
      {
        legend: '(deactivated)',
        type: 'point',
        properties: {
          feature: 'de/ks-combined',
          type: 'line',
          azimuth: null,
          deactivated: true,
          direction_both: false,
        },
      },
    ],
  },
  electrification: {
    'openrailwaymap_low-railway_line_low': [
      {
        legend: 'Not electrified',
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
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
          railway: 'rail',
          feature: 'rail',
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
          railway: 'rail',
          feature: 'rail',
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
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          service: null,
          electrification_state: null,
          voltage: null,
          frequency: null,
        },
      },
    ],
    'openrailwaymap_med-railway_line_med': [
      {
        legend: 'Not electrified',
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
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
          railway: 'rail',
          feature: 'rail',
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
          railway: 'rail',
          feature: 'rail',
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
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          service: null,
          electrification_state: null,
          voltage: null,
          frequency: null,
        },
      },
    ],
    'railway_line_high-railway_line_high': [
      {
        legend: 'Not electrified',
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
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
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          service: null,
          electrification_state: 'abandoned',
          voltage: null,
          frequency: null,
          electrification_label: '',
        },
      },
      ...electrificationLegends.map(({legend, voltage, frequency, electrification_label }) => ({
        legend,
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
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
          railway: 'rail',
          feature: 'rail',
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
          railway: 'rail',
          feature: 'rail',
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
          railway: 'rail',
          feature: 'rail',
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
    'openrailwaymap_electrification-electrification_signals': [
      ...electrification_signals.features.map(feature => ({
        legend: `(${feature.country}) ${feature.description}`,
        type: 'point',
        properties: {
          feature: feature.icon.default,
          type: 'line',
          azimuth: null,
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
    ],
  },
  gauge: {
    'openrailwaymap_low-railway_line_low': [
      ...gaugeLegends.map(({min, legend}) => ({
        legend,
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
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
          railway: 'monorail',
          feature: 'monorail',
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
          railway: 'na',
          feature: 'monorail',
          usage: 'main',
          service: null,
          gauge0: 'standard',
          gaugeint0: null,
        },
      },
      {
        legend: 'Broad',
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
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
          railway: 'rail',
          feature: 'rail',
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
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          service: null,
          gauge0: '3500',
          gaugeint0: 3500,
          label: '3500'
        },
      },
    ],
    'openrailwaymap_med-railway_line_med': [
      ...gaugeLegends.map(({min, legend}) => ({
        legend,
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
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
          railway: 'monorail',
          feature: 'monorail',
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
          railway: 'na',
          feature: 'monorail',
          usage: 'main',
          service: null,
          gauge0: 'standard',
          gaugeint0: null,
        },
      },
      {
        legend: 'Broad',
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
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
          railway: 'rail',
          feature: 'rail',
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
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          service: null,
          gauge0: '3500',
          gaugeint0: 3500,
          label: '3500'
        },
      },
    ],
    'railway_line_high-railway_line_high': [
      ...gaugeLegends.map(({min, legend}) => ({
        legend,
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
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
          railway: 'monorail',
          feature: 'monorail',
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
          railway: 'na',
          feature: 'monorail',
          usage: 'main',
          service: null,
          gauge0: 'standard',
          gaugeint0: null,
        },
      },
      {
        legend: 'Broad',
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
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
          railway: 'miniature',
          feature: 'miniature',
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
          railway: 'rail',
          feature: 'rail',
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
          railway: 'rail',
          feature: 'rail',
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
          railway: 'rail',
          feature: 'rail',
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
          railway: 'rail',
          feature: 'rail',
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
          railway: 'construction',
          feature: 'rail',
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
          railway: 'construction',
          feature: 'rail',
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
          railway: 'construction',
          feature: 'rail',
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
  },
}

const coordinateFactor = legendZoom => Math.pow(2, 5 - legendZoom);

const layerVisibleAtZoom = (zoom) =>
  layer =>
    ((layer.minzoom ?? globalMinZoom) <= zoom) && (zoom < (layer.maxzoom ?? (glodalMaxZoom + 1)));

const legendPointToMapPoint = (zoom, [x, y]) =>
  [x * coordinateFactor(zoom), y * coordinateFactor(zoom)]

function makeLegendStyle(style) {
  const sourceStyle = makeStyle(style);
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
      paint: {},
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
          entry ++;
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
    fs.writeFileSync(`${style}.json`, JSON.stringify(makeStyle(style)));
    fs.writeFileSync(`legend-${style}.json`, JSON.stringify(makeLegendStyle(style)));
});
