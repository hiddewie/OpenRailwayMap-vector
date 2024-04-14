const searchBackdrop = document.getElementById('search-backdrop');
const search = document.getElementById('search');
const searchResults = document.getElementById('search-results');
const searchIcon = document.getElementById('search-icon');
const cancelIcon = document.getElementById('cancel-icon');
const legend = document.getElementById('legend')
const legendMapContainer = document.getElementById('legend-map')
function searchFor(term) {
  if (!term || term.length < 3) {
    hideSearchResults();
  } else {
    // or ref=...
    fetch(`https://api.openrailwaymap.org/v2/facility?name=${term}`)
      .then(result => result.json())
      .then(result => {
        console.info('result', result, result.body)
        showSearchResults(result)
      })
      .catch(error => {
        hideSearchResults();
        hideSearch();
        console.error(error);
      });
  }
}
function showSearchResults(results) {
  let content = '';
  if (results.length === 0) {
    content += `<div class="result"><i>No results</i></div>`
  } else {
    results.forEach(result => {
      content += `<div class="result" onclick="hideSearchResults(); map.easeTo({center: [${result.latitude}, ${result.longitude}], zoom: 15}); hideSearch()">${result.name}</div>`
    })
  }
  searchResults.innerHTML = content;
  searchResults.style.display = 'block';
  cancelIcon.style.display = 'block';
  searchIcon.style.display = 'none';
}
function hideSearchResults() {
  searchResults.style.display = 'none';
  cancelIcon.style.display = 'none';
  searchIcon.style.display = 'block';
}
function showSearch() {
  searchBackdrop.style.display = 'block';
  search.focus();
  search.select();
}
function hideSearch() {
  searchBackdrop.style.display = 'none';
}
function toggleLegend() {
  if (legend.style.display === 'block') {
    legend.style.display = 'none';
  } else {
    legend.style.display = 'block';
  }
}

search.addEventListener('keydown', event => {
  if (event.key === 'Enter') {
    searchFor(event.target.value);
  }
});
searchBackdrop.onclick = event => {
  if (event.target === event.currentTarget) {
    hideSearch();
  }
};

function createDomElement(tagName, className, container) {
  const el = window.document.createElement(tagName);
  if (className !== undefined) el.className = className;
  if (container) container.appendChild(el);
  return el;
}

function removeDomElement(node) {
  if (node.parentNode) {
    node.parentNode.removeChild(node);
  }
}

const globalMinZoom = 1;
const glodalMaxZoom= 18;

const knownStyles = {
  standard: 'Infrastructure',
  speed: 'Speed',
  signals: 'Train protection',
  electrification: 'Electrification',
  gauge: 'Gauge',
};
function hashToObject(hash) {
  if (!hash) {
    return {};
  } else {
    const strippedHash = hash.replace('#', '');
    const hashEntries = strippedHash
      .split('&')
      .map(item => item.split('=', 2))
    return Object.fromEntries(hashEntries);
  }
}
function determineStyleFromHash(hash) {
  const defaultStyle = Object.keys(knownStyles)[0];
  const hashObject = hashToObject(hash);
  if (hashObject.style && hashObject.style in knownStyles) {
    return hashObject.style
  } else {
    return defaultStyle;
  }
}
function putStyleInHash(hash, style) {
  const hashObject = hashToObject(hash);
  hashObject.style = style;
  return `#${Object.entries(hashObject).map(([key, value]) => `${key}=${value}`).join('&')}`;
}
const selectedStyle = determineStyleFromHash(window.location.hash)

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
      ['any',
        ['all', ['==', ['get', 'usage'], 'main'], ['==', ['get', 'service'], null]],
        ['all', ['==', ['get', 'usage'], 'branch'], ['==', ['get', 'service'], null]],
        ['all', ['==', ['get', 'usage'], 'industrial'], ['==', ['get', 'service'], null]],
      ]
    ],
    ['case',
      ['all', ['==', ['get', 'usage'], 'industrial'], ['==', ['get', 'service'], null]], 2,
      3.5,
    ],
    ['all',
      ['==', ['get', 'feature'], 'narrow_gauge'],
      ['==', ['get', 'service'], null],
    ],
    ['case',
      ['any', ['==', ['get', 'usage'], 'industrial'], ['==', ['get', 'service'], null]], 2,
      3,
    ],
    ['any',
      ['all',
        ['==', ['get', 'railway'], 'construction'],
        ['==', ['get', 'railway'], 'rail'],
        ['any', ['==', ['get', 'usage'], 'main'], ['==', ['get', 'usage'], 'branch']],
        ['==', ['get', 'service'], null],
      ],
      ['all',
        ['==', ['get', 'feature'], 'construction'],
        ['any',
          ['==', ['get', 'railway'], 'subway'],
          ['==', ['get', 'railway'], 'light_rail'],
          ['==', ['get', 'railway'], 'monorail'],
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
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'siding']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'crossover']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'spur']],
      ]
    ],
    ['case',
      ['any',
        ['all', ['==', ['get', 'usage'], 'industrial'], ['==', ['get', 'service'], null]],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'siding']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'crossover']],
      ], 2,
      ['any',
        ['all', ['==', ['get', 'usage'], 'industrial'], ['!=', ['get', 'service'], null]],
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
      ['any', ['==', ['get', 'usage'], 'industrial'], ['==', ['get', 'service'], null]], 2,
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
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'siding']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'crossover']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'spur']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'yard']],
      ]
    ],
    ['case',
      ['any',
        ['all', ['==', ['get', 'usage'], 'industrial'], ['==', ['get', 'service'], null]],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'siding']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'crossover']],
      ], 2,
      ['any',
        ['all', ['==', ['get', 'usage'], 'industrial'], ['!=', ['get', 'service'], null]],
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
      ['any', ['==', ['get', 'usage'], 'industrial'], ['==', ['get', 'service'], null]], 2,
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
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'siding']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'crossover']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'spur']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'yard']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], null]],
      ]
    ],
    ['case',
      ['any',
        ['all', ['==', ['get', 'usage'], 'industrial'], ['==', ['get', 'service'], null]],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'siding']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'crossover']],
        ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], null]],
      ], 2,
      ['any',
        ['all', ['==', ['get', 'usage'], 'industrial'], ['!=', ['get', 'service'], null]],
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
      ['any', ['==', ['get', 'usage'], 'industrial'], ['==', ['get', 'service'], null]], 2,
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
  'line-color': ['match', ['get', 'train_protection'],
    'zsi127', '#884400',
    'ptc', '#cc0033',
    'construction_etcs', '#87CEFA',
    'etcs', 'blue',
    'tvm', '#009966',
    'kvb', '#66cc33',
    'asfa', '#ff9092',
    'scmt', '#dd11ff',
    'atc', '#6600cc',
    'atb', '#ff8c00',
    'lzb', 'red',
    'pzb', '#ffb900',
    'other', 'black',
    'grey',
  ],
  'line-width': railwayLineWidth,
  'line-dasharray': dashArray,
});

const main_color = '#ff8100';
const highspeed_color = '#ff0c00';
const branch_color = '#c4b600';
const narrow_gauge_color = '#c0da00';
const no_usage_color = '#000000';
const disused_color = '#70584d';
const abandoned_color = '#7f6a62';
const razed_color = '#94847e';
const tram_color = '#d877b8';
const subway_color = '#0300c3';
const light_rail_color = '#00bd14';
const siding_color = '#000000';
const yard_color = '#000000';
const spur_color = '#87491d';
const industrial_color = '#87491d';

const railway_casing_color = '#ffffff';
const bridge_casing_color = '#000000';

const turntable_fill = '#ababab';
const turntable_casing = '#808080';
const turntable_casing_width = 2;

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
    ['get', 'highspeed'], highspeed_color,
    main_color,
  ],
  'line-width': railwayLineWidth,
};
const standardMediumFillPaint = {
  'line-color': ['case',
    ['==', ['get', 'usage'], 'branch'], branch_color,
    ['get', 'highspeed'], highspeed_color,
    main_color,
  ],
  'line-width': railwayLineWidth,
};
const standardFillPaint = dashArray => ({
  'line-color': ['case',
    ['==', ['get', 'feature'], 'rail'],
    ['case',
      ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'spur']], spur_color,
      ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'yard']], yard_color,
      ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'crossover']], siding_color,
      ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], 'siding']], siding_color,
      ['all', ['==', ['get', 'usage'], null], ['==', ['get', 'service'], null]], no_usage_color,
      ['==', ['get', 'usage'], 'industrial'], industrial_color,
      ['==', ['get', 'usage'], 'branch'], branch_color,
      ['all', ['==', ['get', 'usage'], 'main'], ['get', 'highspeed']], highspeed_color,
      ['==', ['get', 'usage'], 'main'], main_color,
      'rgba(255, 255, 255, 1.0)',
    ],
    ['==', ['get', 'feature'], 'narrow_gauge'],
    ['case',
      ['all', ['==', ['get', 'usage'], 'industrial'], ['==', ['get', 'service'], 'spur']], industrial_color,
      narrow_gauge_color,
    ],
    ['==', ['get', 'railway'], 'disused'], disused_color,
    ['==', ['get', 'railway'], 'abandoned'], abandoned_color,
    ['==', ['get', 'railway'], 'razed'], razed_color,
    ['==', ['get', 'feature'], 'subway'], subway_color,
    ['==', ['get', 'feature'], 'light_rail'], light_rail_color,
    ['==', ['get', 'feature'], 'tram'], tram_color,
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
const maxspeed_fill_color_10 = '#0100CB';
const maxspeed_fill_color_20 = '#001ECB';
const maxspeed_fill_color_30 = '#003DCB';
const maxspeed_fill_color_40 = '#005BCB';
const maxspeed_fill_color_50 = '#007ACB';
const maxspeed_fill_color_60 = '#0098CB';
const maxspeed_fill_color_70 = '#00B7CB';
const maxspeed_fill_color_80 = '#00CBC1';
const maxspeed_fill_color_90 = '#00CBA2';
const maxspeed_fill_color_100 = '#00CB84';
const maxspeed_fill_color_110 = '#00CB66';
const maxspeed_fill_color_120 = '#00CB47';
const maxspeed_fill_color_130 = '#00CB29';
const maxspeed_fill_color_140 = '#00CB0A';
const maxspeed_fill_color_150 = '#14CB00';
const maxspeed_fill_color_160 = '#33CB00';
const maxspeed_fill_color_170 = '#51CB00';
const maxspeed_fill_color_180 = '#70CB00';
const maxspeed_fill_color_190 = '#8ECB00';
const maxspeed_fill_color_200 = '#ADCB00';
const maxspeed_fill_color_210 = '#CBCB00';
const maxspeed_fill_color_220 = '#CBAD00';
const maxspeed_fill_color_230 = '#CB8E00';
const maxspeed_fill_color_240 = '#CB7000';
const maxspeed_fill_color_250 = '#CB5100';
const maxspeed_fill_color_260 = '#CB3300';
const maxspeed_fill_color_270 = '#CB1400';
const maxspeed_fill_color_280 = '#CB0007';
const maxspeed_fill_color_290 = '#CB0025';
const maxspeed_fill_color_300 = '#CB0044';
const maxspeed_fill_color_320 = '#CB0062';
const maxspeed_fill_color_340 = '#CB0081';
const maxspeed_fill_color_360 = '#CB009F';
const maxspeed_fill_color_380 = '#CB00BD';

const speedFillPaint = {
  'line-color': ['case',
    ['==', ['get', 'maxspeed'], null], 'gray',
    ['<=', ['get', 'maxspeed'], 10], maxspeed_fill_color_10,
    ['<=', ['get', 'maxspeed'], 20], maxspeed_fill_color_20,
    ['<=', ['get', 'maxspeed'], 30], maxspeed_fill_color_30,
    ['<=', ['get', 'maxspeed'], 40], maxspeed_fill_color_40,
    ['<=', ['get', 'maxspeed'], 50], maxspeed_fill_color_50,
    ['<=', ['get', 'maxspeed'], 60], maxspeed_fill_color_60,
    ['<=', ['get', 'maxspeed'], 70], maxspeed_fill_color_70,
    ['<=', ['get', 'maxspeed'], 80], maxspeed_fill_color_80,
    ['<=', ['get', 'maxspeed'], 90], maxspeed_fill_color_90,
    ['<=', ['get', 'maxspeed'], 100], maxspeed_fill_color_100,
    ['<=', ['get', 'maxspeed'], 110], maxspeed_fill_color_110,
    ['<=', ['get', 'maxspeed'], 120], maxspeed_fill_color_120,
    ['<=', ['get', 'maxspeed'], 130], maxspeed_fill_color_130,
    ['<=', ['get', 'maxspeed'], 140], maxspeed_fill_color_140,
    ['<=', ['get', 'maxspeed'], 150], maxspeed_fill_color_150,
    ['<=', ['get', 'maxspeed'], 160], maxspeed_fill_color_160,
    ['<=', ['get', 'maxspeed'], 170], maxspeed_fill_color_170,
    ['<=', ['get', 'maxspeed'], 180], maxspeed_fill_color_180,
    ['<=', ['get', 'maxspeed'], 190], maxspeed_fill_color_190,
    ['<=', ['get', 'maxspeed'], 200], maxspeed_fill_color_200,
    ['<=', ['get', 'maxspeed'], 210], maxspeed_fill_color_210,
    ['<=', ['get', 'maxspeed'], 220], maxspeed_fill_color_220,
    ['<=', ['get', 'maxspeed'], 230], maxspeed_fill_color_230,
    ['<=', ['get', 'maxspeed'], 240], maxspeed_fill_color_240,
    ['<=', ['get', 'maxspeed'], 250], maxspeed_fill_color_250,
    ['<=', ['get', 'maxspeed'], 260], maxspeed_fill_color_260,
    ['<=', ['get', 'maxspeed'], 270], maxspeed_fill_color_270,
    ['<=', ['get', 'maxspeed'], 280], maxspeed_fill_color_280,
    ['<=', ['get', 'maxspeed'], 290], maxspeed_fill_color_290,
    ['<=', ['get', 'maxspeed'], 300], maxspeed_fill_color_300,
    ['<=', ['get', 'maxspeed'], 320], maxspeed_fill_color_320,
    ['<=', ['get', 'maxspeed'], 340], maxspeed_fill_color_340,
    ['<=', ['get', 'maxspeed'], 360], maxspeed_fill_color_360,
    ['>', ['get', 'maxspeed'], 360], maxspeed_fill_color_380,
    'gray',
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
const electrificationFillPaint = dashArray => ({
  'line-color': ['case',
    ['all', ['==', ['get', 'frequency'], 60], ['==', ['get', 'voltage'], 25000]], color_25kv_60hz,
    ['all', ['==', ['get', 'frequency'], 50], ['==', ['get', 'voltage'], 25000]], color_25kv_50hz,
    ['all', ['==', ['get', 'frequency'], 60], ['==', ['get', 'voltage'], 20000]], color_20kv_60hz,
    ['all', ['==', ['get', 'frequency'], 50], ['==', ['get', 'voltage'], 20000]], color_20kv_50hz,
    ['all', ['==', ['get', 'frequency'], 16.7], ['==', ['get', 'voltage'], 15000]], color_15kv_16_7hz,
    ['all', ['==', ['get', 'frequency'], 16.67], ['==', ['get', 'voltage'], 15000]], color_15kv_16_67hz,
    ['all', ['==', ['get', 'frequency'], 60], ['==', ['get', 'voltage'], 12500]], color_12_5kv_60hz,
    ['all', ['==', ['get', 'frequency'], 25], ['==', ['get', 'voltage'], 12000]], color_12kv_25hz,
    ['all', ['==', ['get', 'frequency'], 0], ['!=', ['get', 'voltage'], null], ['>', ['get', 'voltage'], 3000]], color_gt3kv_dc,
    ['all', ['==', ['get', 'frequency'], 0], ['==', ['get', 'voltage'], 3000]], color_3kv_dc,
    ['all', ['==', ['get', 'frequency'], 0], ['!=', ['get', 'voltage'], null], ['>', 3000, ['get', 'voltage']], ['>', ['get', 'voltage'], 1500]], color_gt1500v_lt3kv_dc,
    ['all', ['==', ['get', 'frequency'], 0], ['==', ['get', 'voltage'], 1500]], color_1500v_dc,
    ['all', ['==', ['get', 'frequency'], 0], ['!=', ['get', 'voltage'], null], ['>', 1500, ['get', 'voltage']], ['>', ['get', 'voltage'], 1000]], color_gt1kv_lt1500v_dc,
    ['all', ['==', ['get', 'frequency'], 0], ['==', ['get', 'voltage'], 1000]], color_1kv_dc,
    ['all', ['==', ['get', 'frequency'], 0], ['!=', ['get', 'voltage'], null], ['>', 1000, ['get', 'voltage']], ['>', ['get', 'voltage'], 750]], color_gt750v_lt1kv_dc,
    ['all', ['==', ['get', 'frequency'], 0], ['==', ['get', 'voltage'], 750]], color_750v_dc,
    ['all', ['==', ['get', 'frequency'], 0], ['!=', ['get', 'voltage'], null], ['<', 750, ['get', 'voltage']]], color_lt750v_dc,
    ['all',
      ['!=', ['get', 'frequency'], 0],
      ['!=', ['get', 'voltage'], null],
      ['any',
        ['>', ['get', 'voltage'], 25000],
        ['all', ['!=', ['get', 'frequency'], 50], ['!=', ['get', 'frequency'], 60], ['>', ['get', 'voltage'], 25000]],
      ],
    ], color_gte25kv_ac,
    ['all',
      ['!=', ['get', 'frequency'], 0],
      ['!=', ['get', 'voltage'], null],
      ['any',
        ['all', ['!=', ['get', 'frequency'], 16.67], ['!=', ['get', 'frequency'], '16.7'], ['==', ['get', 'voltage'], 15000]],
        ['all', ['>', 20000, ['get', 'voltage']], ['>', ['get', 'voltage'], 15000]],
        ['all', ['!=', ['get', 'frequency'], 50], ['!=', ['get', 'frequency'], '60'], ['==', ['get', 'voltage'], 20000]],
        ['all', ['>', 25000, ['get', 'voltage']], ['>', ['get', 'voltage'], 20000]],
      ],
    ], color_gte15kv_lt25kv_ac,
    ['all',
      ['!=', ['get', 'frequency'], 0],
      ['!=', ['get', 'voltage'], null],
      ['any',
        ['>', 12000, ['get', 'voltage']],
        ['all', ['!=', ['get', 'frequency'], 25], ['==', ['get', 'voltage'], 12000]],
        ['all', ['>', 12500, ['get', 'voltage']], ['>', ['get', 'voltage'], 12000]],
        ['all', ['!=', ['get', 'frequency'], 60], ['==', ['get', 'voltage'], 12500]],
        ['all', ['>', 15000, ['get', 'voltage']], ['>', ['get', 'voltage'], 12500]],
      ],
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
    // monorails or tracks with monorail gauge value
    ['any',
      ['==', ['get', 'railway'], 'monorail'],
      ['all',
        ['==', ['get', gaugeProperty], 'monorail'],
        ['any',
          ['==', ['get', 'railway'], 'rail'],
          ['==', ['get', 'railway'], 'light_rail'],
          ['==', ['get', 'railway'], 'subway'],
          ['==', ['get', 'railway'], 'tram'],
        ],
      ],
    ], color_gauge_monorail,
    // other tracks with inaccurate gauge value
    ['all',
      ['==', ['get', gaugeProperty], 'standard'],
      ['any',
        ['==', ['get', 'railway'], 'rail'],
        ['==', ['get', 'railway'], 'light_rail'],
        ['==', ['get', 'railway'], 'subway'],
        ['==', ['get', 'railway'], 'tram'],
      ],
    ], color_gauge_standard,
    ['all',
      ['==', ['get', gaugeProperty], 'broad'],
      ['any',
        ['==', ['get', 'railway'], 'rail'],
        ['==', ['get', 'railway'], 'light_rail'],
        ['==', ['get', 'railway'], 'subway'],
        ['==', ['get', 'railway'], 'tram'],
      ],
    ], color_gauge_broad,
    ['any',
      ['all',
        ['==', ['get', gaugeProperty], 'narrow'],
        ['any',
          ['==', ['get', 'railway'], 'rail'],
          ['==', ['get', 'railway'], 'light_rail'],
          ['==', ['get', 'railway'], 'subway'],
          ['==', ['get', 'railway'], 'tram'],
        ],
      ],
      ['all',
        ['==', ['get', 'railway'], 'narrow_gauge'],
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
      ['==', ['get', 'railway'], 'miniature'],
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

const openstreetmap = {
  type: 'raster',
  tiles: [
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  ],
  tileSize: 256,
  attribution: '<a href="https://www.openstreetmap.org/about" target="_blank">&copy; OpenStreetMap contributors</a>'
};
const sources = {
  openstreetmap,
  openrailwaymap_low: {
    type: 'vector',
    url: `${location.origin}/railway_line_low`,
    attribution,
  },
  standard_railway_text_stations_low: {
    type: 'vector',
    url: `${location.origin}/standard_railway_text_stations_low`,
    attribution,
  },
  openrailwaymap_med: {
    type: 'vector',
    url: `${location.origin}/railway_line_med`,
    attribution,
  },
  standard_railway_text_stations_med: {
    type: 'vector',
    url: `${location.origin}/standard_railway_text_stations_med`,
    attribution,
  },
  openrailwaymap_standard: {
    type: 'vector',
    url: `${location.origin}/standard`,
    attribution,
  },
  openrailwaymap_speed: {
    type: 'vector',
    url: `${location.origin}/speed`,
    attribution,
  },
  openrailwaymap_signals: {
    type: 'vector',
    url: `${location.origin}/signals`,
    attribution,
  },
  openrailwaymap_electrification: {
    type: 'vector',
    url: `${location.origin}/electrification`,
    attribution,
  },
  openrailwaymap_gauge: {
    type: 'vector',
    url: `${location.origin}/gauge`,
    attribution,
  },
};

const backgroundColor = {
  id: 'background',
  type: 'background',
  paint: {
    'background-color': 'rgb(242, 243, 240)'
  }
};
const backgroundMap = {
  id: "openstreetmap",
  type: "raster",
  source: "openstreetmap",
  paint: {
    'raster-saturation': -1.0, // or 0.0 for colorful
  }
};

// TODO remove all [switch, [zoom]] to ensure legend displays only visible features
const layers = {
  standard: [
    backgroundColor,
    backgroundMap,
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
        'line-color': railway_casing_color,
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
        'line-color': railway_casing_color,
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
      id: 'railway_bridge_railing',
      type: 'line',
      minzoom: 8,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_line_fill',
      filter: ['all',
        ['get', 'bridge'],
        ['!=', ['get', 'railway'], 'construction'],
        ['!=', ['get', 'railway'], 'proposed'],
        ['!=', ['get', 'railway'], 'abandoned'],
        ['!=', ['get', 'railway'], 'razed'],
      ],
      paint: {
        'line-color': bridge_casing_color,
        'line-width': railwayLineWidth,
        'line-gap-width': bridge_casing_add,
      }
    },
    {
      id: 'railway_tunnel_casing',
      type: 'line',
      minzoom: 8,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_line_fill',
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
        'line-color': railway_casing_color,
        'line-width': railwayLineWidth,
        'line-gap-width': railway_tunnel_casing_add,
      }
    },
    {
      id: 'railway_line_casing',
      type: 'line',
      minzoom: 8,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_line_fill',
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
        'line-color': railway_casing_color,
        'line-width': railwayLineWidth,
        'line-gap-width': railway_casing_add,
      }
    },
    {
      id: 'railway_line_construction_casing',
      type: 'line',
      minzoom: 8,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_line_fill',
      filter: ['==', ['get', 'railway'], 'construction'],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: {
        'line-color': railway_casing_color,
        'line-width': railwayLineWidth,
        'line-gap-width': railway_casing_add,
        'line-dasharray': construction_dasharray,
      }
    },
    {
      id: 'railway_line_proposed_casing',
      type: 'line',
      minzoom: 8,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_line_fill',
      filter: ['==', ['get', 'railway'], 'proposed'],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: {
        'line-color': railway_casing_color,
        'line-width': railwayLineWidth,
        'line-gap-width': railway_casing_add,
        'line-dasharray': proposed_dasharray,
      }
    },
    {
      id: 'railway_line_abandoned_casing',
      type: 'line',
      minzoom: 8,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_line_fill',
      filter: ['==', ['get', 'railway'], 'abandoned'],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: {
        'line-color': railway_casing_color,
        'line-width': railwayLineWidth,
        'line-gap-width': railway_casing_add,
        'line-dasharray': abandoned_dasharray,
      }
    },
    {
      id: 'railway_line_razed_casing',
      type: 'line',
      minzoom: 8,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_line_fill',
      filter: ['==', ['get', 'railway'], 'razed'],
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: {
        'line-color': railway_casing_color,
        'line-width': railwayLineWidth,
        'line-gap-width': railway_casing_add,
        'line-dasharray': razed_dasharray,
      }
    },
    {
      id: 'railway_bridge_casing',
      type: 'line',
      minzoom: 8,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_line_fill',
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
      paint: {
        'line-color': railway_casing_color,
        'line-width': railwayLineWidth,
        'line-gap-width': railway_casing_add,
      }
    },
    {
      id: 'railway_tunnel_fill',
      type: 'line',
      minzoom: 8,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_line_fill',
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
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_line_fill',
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
      id: 'railway_construction_fill',
      type: 'line',
      minzoom: 8,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_line_fill',
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
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_line_fill',
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
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_line_fill',
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
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_line_fill',
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
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_line_fill',
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
      id: 'railway_bridge_fill',
      type: 'line',
      minzoom: 8,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_line_fill',
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
        'fill-color': turntable_fill,
      }
    },
    {
      id: 'railway_turntables_casing',
      type: 'line',
      minzoom: 15,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_turntables',
      paint: {
        'line-color': turntable_casing,
        'line-width': turntable_casing_width,
      }
    },
    {
      id: 'railway_symbols_tram_stop',
      type: 'symbol',
      minzoom: 12,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_symbols',
      filter: ['==', ['get', 'railway'], 'tram_stop'],
      layout: {
        'icon-overlap': 'always',
        'icon-image': 'general/tram-stop',
      }
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
    {
      id: 'railway_symbols_low',
      type: 'symbol',
      minzoom: 10,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_symbols',
      filter: ['==', ['get', 'railway'], 'border'],
      layout: {
        'icon-image': 'general/border',
      }
    },
    {
      id: 'railway_symbols_med',
      type: 'symbol',
      minzoom: 12,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_symbols',
      filter: ['any',
        ['==', ['get', 'railway'], 'owner_change'],
        ['==', ['get', 'railway'], 'radio'],
      ],
      layout: {
        'symbol-z-order': 'source',
        'icon-image': ['case',
          ['==', ['get', 'railway'], 'owner_change'], 'general/border',
          ['==', ['get', 'railway'], 'radio'], ['case',
            ['==', ['get', 'man_made'], 'mast'], 'general/radio-mast',
            ['==', ['get', 'man_made'], 'tower'], 'general/radio-mast',
            ['==', ['get', 'man_made'], 'antenna'], 'general/radio-antenna',
            '',
          ],
          '',
        ],
      }
    },
    {
      id: 'railway_symbols_med_high',
      type: 'symbol',
      minzoom: 13,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_symbols',
      filter: ['any',
        ['==', ['get', 'railway'], 'crossing'],
        ['==', ['get', 'railway'], 'level_crossing'],
      ],
      layout: {
        'symbol-z-order': 'source',
        'icon-image': ['case',
          ['==', ['get', 'railway'], 'level_crossing'], 'general/level-crossing',
          ['==', ['get', 'railway'], 'crossing'], 'general/crossing',
          '',
        ],
      }
    },
    {
      id: 'railway_symbols_high',
      type: 'symbol',
      minzoom: 16,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_symbols',
      filter: ['==', ['get', 'railway'], 'phone'],
      layout: {
        'symbol-z-order': 'source',
        'icon-image': 'general/phone',
      }
    },
    {
      id: 'railway_text',
      type: 'symbol',
      minzoom: 8,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_line_fill',
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
        ['!=', ['get', 'label'], null],
      ],
      paint: {
        'text-color': '#585858',
        'text-halo-color': 'white',
        'text-halo-width': 2,
      },
      layout: {
        'symbol-z-order': 'source',
        'symbol-placement': 'line',
        'text-field': ['step', ['zoom'],
          ['get', 'ref'],
          14,
          ['get', 'label'],
        ],
        'text-font': ['Noto Sans Bold'],
        'text-size': 11,
        'text-padding': 10,
        'text-max-width': 5,
        'symbol-spacing': 200,
      },
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
        'text-halo-color': 'white',
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
      id: 'railway_switch_ref',
      type: 'symbol',
      minzoom: 15,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_switch_ref',
      paint: {
        'text-halo-color': ['case',
          ['==', ['get', 'railway_local_operated'], 'yes'], 'yellow',
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
      id: 'railway_text_track_numbers',
      type: 'symbol',
      minzoom: 16,
      source: 'openrailwaymap_standard',
      'source-layer': 'standard_railway_line_fill',
      filter: ['!=', ['get', 'track_ref'], null],
      paint: {
        'text-color': 'white',
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
      source: 'openrailwaymap_speed',
      minzoom: 8,
      // TODO merge with speed_railway_line_fill source
      'source-layer': 'speed_railway_line_casing',
      paint: speedCasingPaint,
      layout: speedLayout,
    },
    {
      id: 'speed_railway_line_fill',
      type: 'line',
      source: 'openrailwaymap_speed',
      minzoom: 8,
      'source-layer': 'speed_railway_line_fill',
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
        'icon-image': 'general/signal-direction',
        'icon-offset': ['literal', [0, 15]],
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
      source: 'openrailwaymap_speed',
      'source-layer': 'speed_railway_line_fill',
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
        'text-halo-color': 'white',
        'text-halo-width': 1.5,
      },
      layout: {
        'symbol-z-order': 'source',
        'symbol-placement': 'line',
        'text-field': '{label}',
        'text-font': ['Noto Sans Bold'],
        'text-size': 11,
        'text-padding': 30,
        'symbol-spacing': 100,
      },
    },
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
      source: 'openrailwaymap_signals',
      minzoom: 8,
      'source-layer': 'signals_railway_line',
      filter: ['==', ['get', 'railway'], 'construction'],
      paint: trainProtectionCasingPaint([2, 2]),
      layout: trainProtectionLayout,
    },
    {
      id: 'railway_line_casing',
      type: 'line',
      source: 'openrailwaymap_signals',
      minzoom: 8,
      'source-layer': 'signals_railway_line',
      filter: ['!=', ['get', 'railway'], 'construction'],
      paint: trainProtectionCasingPaint([1]),
      layout: trainProtectionLayout,
    },
    {
      id: 'railway_line_fill_construction',
      type: 'line',
      minzoom: 8,
      source: 'openrailwaymap_signals',
      'source-layer': 'signals_railway_line',
      filter: ['==', ['get', 'railway'], 'construction'],
      paint: trainProtectionFillPaint([2, 2]),
      layout: trainProtectionLayout,
    },
    {
      id: 'railway_line_fill',
      type: 'line',
      minzoom: 8,
      source: 'openrailwaymap_signals',
      'source-layer': 'signals_railway_line',
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
        'circle-color': '#008206',
        'circle-radius': ['interpolate', ['linear'], ['zoom'],
          10, 6,
          14, 12,
        ],
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
        'fill-color': '#008206',
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
        'symbol-z-order': 'source',
        'icon-overlap': 'always',
        'icon-image': 'general/signal-direction',
        'icon-offset': ['literal', [0, 15]],
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
        'text-halo-color': '#bfffb3',
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
        'text-halo-color': '#bfffb3',
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
        'text-halo-color': 'white',
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
        'text-halo-color': 'white',
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
      paint: electrificationFillPaint([1]),
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
      paint: electrificationFillPaint([1]),
      layout: electrificationLayout,
    },
    {
      id: 'electrification_railway_line_casing',
      type: 'line',
      minzoom: 8,
      source: 'openrailwaymap_electrification',
      'source-layer': 'electrification_railway_line',
      paint: electrificationCasingPaint,
      layout: electrificationLayout,
    },
    {
      id: 'electrification_railway_line_fill',
      type: 'line',
      minzoom: 8,
      source: 'openrailwaymap_electrification',
      'source-layer': 'electrification_railway_line',
      paint: electrificationFillPaint([1]),
      layout: electrificationLayout,
    },
    {
      id: 'electrification_future_proposed',
      type: 'line',
      minzoom: 8,
      source: 'openrailwaymap_electrification',
      'source-layer': 'electrification_future',
      filter: ['==', ['get', 'electrification_state'], 'proposed'],
      paint: electrificationFillPaint(electrification_proposed_dashes),
      layout: electrificationLayout,
    },
    {
      id: 'electrification_future_construction',
      type: 'line',
      minzoom: 8,
      source: 'openrailwaymap_electrification',
      'source-layer': 'electrification_future',
      filter: ['==', ['get', 'electrification_state'], 'construction'],
      paint: electrificationFillPaint(electrification_construction_dashes),
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
        'icon-image': 'general/signal-direction',
        'icon-offset': ['literal', [0, 15]],
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
      source: 'openrailwaymap_electrification',
      'source-layer': 'electrification_railway_line',
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
        'text-halo-color': 'white',
        'text-halo-width': 1.5,
      },
      layout: {
        'symbol-z-order': 'source',
        'symbol-placement': 'line',
        'text-field': '{label}',
        // TODO not present: oblique font
        'text-font': ['Noto Sans Bold'],
        'text-size': 11,
        'text-padding': 30,
        'symbol-spacing': 100,
      },
    },
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
      source: 'openrailwaymap_gauge',
      'source-layer': 'gauge_railway_line',
      filter: ['!=', ['get', 'railway'], 'construction'],
      paint: gaugeCasingPaint,
      layout: gaugeLayout,
    },
    {
      id: 'gauge_railway_line_casing_construction',
      type: 'line',
      minzoom: 8,
      source: 'openrailwaymap_gauge',
      'source-layer': 'gauge_railway_line',
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
      source: 'openrailwaymap_gauge',
      'source-layer': 'gauge_railway_line',
      filter: ['!=', ['get', 'railway'], 'construction'],
      paint: gaugeFillPaint('gauge0', 'gaugeint0', [1]),
      layout: gaugeLayout,
    },
    {
      id: 'gauge_railway_line_fill_construction',
      type: 'line',
      minzoom: 8,
      source: 'openrailwaymap_gauge',
      'source-layer': 'gauge_railway_line',
      filter: ['==', ['get', 'railway'], 'construction'],
      paint: gaugeFillPaint('gauge0', 'gaugeint0', gauge_construction_dashes),
      layout: gaugeLayout,
    },
    {
      id: 'gauge_railway_dual_gauge_line',
      type: 'line',
      minzoom: 8,
      source: 'openrailwaymap_gauge',
      'source-layer': 'gauge_railway_line',
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
      source: 'openrailwaymap_gauge',
      'source-layer': 'gauge_railway_line',
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
      source: 'openrailwaymap_gauge',
      'source-layer': 'gauge_railway_line',
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
      source: 'openrailwaymap_gauge',
      'source-layer': 'gauge_railway_line',
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
      source: 'openrailwaymap_gauge',
      'source-layer': 'gauge_railway_line',
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
        'text-halo-color': 'white',
        'text-halo-width': 1.5,
      },
      layout: {
        'symbol-z-order': 'source',
        'symbol-placement': 'line',
        'text-field': '{label}',
        // TODO not present: oblique font
        'text-font': ['Noto Sans Bold'],
        'text-size': 11,
        'text-padding': 30,
        'symbol-spacing': 100,
      },
    },
  ],
};

// TODO move this to build-time generation, serve JSON
const makeStyle = selectedStyle => ({
  center: [12.55, 51.14], // default
  zoom: 3.75, // default
  glyphs: `${location.origin}/font/{fontstack}/{range}`,
  metadata: {},
  name: 'OpenRailwayMap',
  sources,
  sprite: `${location.origin}/sprite/symbols`,
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
    "openrailwaymap_standard-standard_railway_line_fill": [
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
          label: 'Name',
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
          label: 'Name',
          track_ref: '8b',
        }
      },
      // TODO support variants
      {
        legend: 'Main line (tunnel)',
        type: 'line',
        properties: {
          highspeed: false,
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          service: null,
          tunnel: true,
          bridge: false,
          ref: 'L1',
          label: 'Name',
          track_ref: '8b',
        }
      },
      {
        legend: 'Main line (bridge)',
        type: 'line',
        properties: {
          highspeed: false,
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          service: null,
          tunnel: false,
          bridge: true,
          ref: 'L1',
          label: 'Name',
          track_ref: '8b',
        }
      },
      {
        legend: 'Railway under construction',
        type: 'line',
        properties: {
          highspeed: false,
          railway: 'construction',
          feature: 'rail',
          usage: 'main',
          service: null,
          tunnel: false,
          bridge: false,
          ref: 'L1',
          label: 'Name',
          track_ref: '8b',
        }
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
          label: 'Name',
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
          label: 'Name',
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
          label: 'Name',
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
          label: 'Name',
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
          label: null,
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
          label: 'Name',
          track_ref: '8b',
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
        properties: {},
      },
    ],
    "openrailwaymap_standard-standard_railway_symbols": [
      {
        legend: 'Tram stop',
        type: 'point',
        properties: {
          railway: 'tram_stop',
        },
      },
      {
        legend: 'Border crossing / owner change',
        type: 'point',
        properties: {
          railway: 'border',
        },
      },
      {
        legend: 'Radio mast',
        type: 'point',
        properties: {
          railway: 'radio',
          man_made: 'mast',
        },
      },
      {
        legend: 'Radio antenna',
        type: 'point',
        properties: {
          railway: 'radio',
          man_made: 'antenna',
        },
      },
      {
        legend: 'Crossing',
        type: 'point',
        properties: {
          railway: 'crossing',
        },
      },
      {
        legend: 'Level crossing',
        type: 'point',
        properties: {
          railway: 'level_crossing',
        },
      },
      {
        legend: 'Phone',
        type: 'point',
        properties: {
          railway: 'phone',
        },
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
          railway_local_operated: 'no',
        },
      },
      {
        legend: 'Locally operated switch',
        type: 'point',
        properties: {
          railway: 'switch',
          ref: '456z',
          railway_local_operated: 'yes',
        },
      },
    ],
  },
  speed: {
    'openrailwaymap_low-railway_line_low': [
      ...[10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200, 210, 220, 230, 240, 250, 260, 270, 280, 290, 300, 320, 340, 360, 380].map(speed => ({
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
      ...[10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200, 210, 220, 230, 240, 250, 260, 270, 280, 290, 300, 320, 340, 360, 380].map(speed => ({
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
    'openrailwaymap_speed-speed_railway_line_fill': [
      ...[10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200, 210, 220, 230, 240, 250, 260, 270, 280, 290, 300, 320, 340, 360, 380].map(speed => ({
        legend: `${speed} km/h`,
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          maxspeed: speed,
          label: `${speed}`,
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
    'openrailwaymap_speed-speed_railway_signals': [
      // TODO import from signals definition files
      // TODO filter per country polygon
      // TODO ensure direction shows
      {
        legend: 'zs3v',
        type: 'point',
        properties: {
          feature: 'de/zs3v-100-sign-down',
          type: 'line',
          azimuth: 90.0,
        },
      },
    ],
  },
  signals: {
    'openrailwaymap_low-railway_line_low': [
      // TODO source from definition file
      ...['zsi127', 'ptc', 'construction_etcs', 'etcs', 'tvm', 'kvb', 'asfa', 'scmt', 'atc', 'atb', 'lzb', 'pzb'].map(trainProtection => ({
        legend: trainProtection,
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          service: null,
          train_protection: trainProtection,
          train_protection_rank: 1,
        },
      })),
      {
        legend: '(other)',
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          service: null,
          train_protection: 'other',
          train_protection_rank: 1,
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
          train_protection: null,
          train_protection_rank: null,
        },
      },
    ],
    'openrailwaymap_med-railway_line_med': [
      // TODO source from definition file
      ...['zsi127', 'ptc', 'construction_etcs', 'etcs', 'tvm', 'kvb', 'asfa', 'scmt', 'atc', 'atb', 'lzb', 'pzb'].map(trainProtection => ({
        legend: trainProtection,
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          service: null,
          train_protection: trainProtection,
          train_protection_rank: 1,
        },
      })),
      {
        legend: '(other)',
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          service: null,
          train_protection: 'other',
          train_protection_rank: 1,
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
          train_protection: null,
          train_protection_rank: null,
        },
      },
    ],
    'openrailwaymap_signals-signals_railway_line': [
      // TODO source from definition file
      ...['zsi127', 'ptc', 'construction_etcs', 'etcs', 'tvm', 'kvb', 'asfa', 'scmt', 'atc', 'atb', 'lzb', 'pzb'].map(trainProtection => ({
        legend: trainProtection,
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          service: null,
          train_protection: trainProtection,
          train_protection_rank: 1,
        },
      })),
      {
        legend: '(other)',
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          service: null,
          train_protection: 'other',
          train_protection_rank: 1,
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
          train_protection: null,
          train_protection_rank: null,
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
          name: 'Rotterdam'
        },
      },
    ],
    'openrailwaymap_signals-signals_railway_signals': [
      // TODO railway signals from definition file
      // TODO country specific railway signals
      {
        legend: '(deactivated)',
        type: 'point',
        properties: {
          feature: 'de/ks-combined',
          type: 'line',
          azimuth: 90.0,
          deactivated: true,
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
      ...[
        { legend: '> 25 kV ~', voltage: 25000, frequency: 60 },
        { legend: '25 kV 60 Hz ~', voltage: 25000, frequency: 60 },
        { legend: '25 kV 50 Hz ~', voltage: 25000, frequency: 50 },
        { legend: '20 kV 60 Hz ~', voltage: 20000, frequency: 60 },
        { legend: '20 kV 50 Hz ~', voltage: 20000, frequency: 50 },
        { legend: '15 kV - 25 kV ~', voltage: 15001, frequency: 60 },
        { legend: '15 kV 16.7 Hz ~', voltage: 15000, frequency: 16.7 },
        { legend: '15 kV 16.67 Hz ~', voltage: 15000, frequency: 16.67 },
        { legend: '12.5 kV - 15 kV ~', voltage: 12501, frequency: 60 },
        { legend: '12.5 kV 60 Hz ~', voltage: 12500, frequency: 60 },
        { legend: '12.5 kV 12 Hz ~', voltage: 12500, frequency: 12 },
        { legend: '< 12.5 kV ~', voltage: 12499, frequency: 60 },
        { legend: '> 3 kV =', voltage: 3001, frequency: 0 },
        { legend: '3 kV =', voltage: 3000, frequency: 0 },
        { legend: '1.5 kV - 3 kV =', voltage: 1501, frequency: 0 },
        { legend: '1.5 kV =', voltage: 1500, frequency: 0 },
        { legend: '1 kV - 1.5 kV =', voltage: 1001, frequency: 0 },
        { legend: '1 kV =', voltage: 1000, frequency: 0 },
        { legend: '750 V - 1 kV =', voltage: 751, frequency: 0 },
        { legend: '750 V =', voltage: 750, frequency: 0 },
        { legend: '< 750 V =', voltage: 749, frequency: 0 },
      ].map(({legend, voltage, frequency}) => ({
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
      ...[
        { legend: '> 25 kV ~', voltage: 25000, frequency: 60 },
        { legend: '25 kV 60 Hz ~', voltage: 25000, frequency: 60 },
        { legend: '25 kV 50 Hz ~', voltage: 25000, frequency: 50 },
        { legend: '20 kV 60 Hz ~', voltage: 20000, frequency: 60 },
        { legend: '20 kV 50 Hz ~', voltage: 20000, frequency: 50 },
        { legend: '15 kV - 25 kV ~', voltage: 15001, frequency: 60 },
        { legend: '15 kV 16.7 Hz ~', voltage: 15000, frequency: 16.7 },
        { legend: '15 kV 16.67 Hz ~', voltage: 15000, frequency: 16.67 },
        { legend: '12.5 kV - 15 kV ~', voltage: 12501, frequency: 60 },
        { legend: '12.5 kV 60 Hz ~', voltage: 12500, frequency: 60 },
        { legend: '12.5 kV 12 Hz ~', voltage: 12500, frequency: 12 },
        { legend: '< 12.5 kV ~', voltage: 12499, frequency: 60 },
        { legend: '> 3 kV =', voltage: 3001, frequency: 0 },
        { legend: '3 kV =', voltage: 3000, frequency: 0 },
        { legend: '1.5 kV - 3 kV =', voltage: 1501, frequency: 0 },
        { legend: '1.5 kV =', voltage: 1500, frequency: 0 },
        { legend: '1 kV - 1.5 kV =', voltage: 1001, frequency: 0 },
        { legend: '1 kV =', voltage: 1000, frequency: 0 },
        { legend: '750 V - 1 kV =', voltage: 751, frequency: 0 },
        { legend: '750 V =', voltage: 750, frequency: 0 },
        { legend: '< 750 V =', voltage: 749, frequency: 0 },
      ].map(({legend, voltage, frequency}) => ({
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
    'openrailwaymap_electrification-electrification_railway_line': [
      // TODO 3rd rail
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
          label: '',
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
          label: '',
        },
      },
      ...[
        { legend: '> 25 kV ~', voltage: 25000, frequency: 60, label: '26kV 60Hz' },
        { legend: '25 kV 60 Hz ~', voltage: 25000, frequency: 60, label: '25kV 60Hz' },
        { legend: '25 kV 50 Hz ~', voltage: 25000, frequency: 50, label: '25kV 50Hz' },
        { legend: '20 kV 60 Hz ~', voltage: 20000, frequency: 60, label: '20kV 60Hz' },
        { legend: '20 kV 50 Hz ~', voltage: 20000, frequency: 50, label: '20kV 50Hz' },
        { legend: '15 kV - 25 kV ~', voltage: 15001, frequency: 60, label: '16kV 60Hz' },
        { legend: '15 kV 16.7 Hz ~', voltage: 15000, frequency: 16.7, label: '15kV 16.7Hz' },
        { legend: '15 kV 16.67 Hz ~', voltage: 15000, frequency: 16.67, label: '15kV 16.67Hz' },
        { legend: '12.5 kV - 15 kV ~', voltage: 12501, frequency: 60, label: '13kV 60Hz' },
        { legend: '12.5 kV 60 Hz ~', voltage: 12500, frequency: 60, label: '12.5kV 60Hz' },
        { legend: '12.5 kV 25 Hz ~', voltage: 12500, frequency: 25, label: '12.5kV 25Hz' },
        { legend: '< 12.5 kV ~', voltage: 12499, frequency: 60, label: '11kV 60Hz' },
        { legend: '> 3 kV =', voltage: 3001, frequency: 0, label: '4kV =' },
        { legend: '3 kV =', voltage: 3000, frequency: 0, label: '3kV =' },
        { legend: '1.5 kV - 3 kV =', voltage: 1501, frequency: 0, label: '2kV =' },
        { legend: '1.5 kV =', voltage: 1500, frequency: 0, label: '1.5kV =' },
        { legend: '1 kV - 1.5 kV =', voltage: 1001, frequency: 0, label: '1.2kV =' },
        { legend: '1 kV =', voltage: 1000, frequency: 0, label: '1kV =' },
        { legend: '750 V - 1 kV =', voltage: 751, frequency: 0, label: '800V =' },
        { legend: '750 V =', voltage: 750, frequency: 0, label: '750V =' },
        { legend: '< 750 V =', voltage: 749, frequency: 0, label: '700V =' },
      ].map(({legend, voltage, frequency, label }) => ({
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
          label,
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
          label: '',
        },
      },
    ],
    'openrailwaymap_electrification-electrification_future': [
      {
        legend: 'Proposed electrification',
        type: 'line',
        properties: {
          railway: 'rail',
          feature: 'rail',
          usage: 'main',
          service: null,
          electrification_state: 'proposed',
          voltage: 25000,
          frequency: 60,
          label: '',
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
          voltage: 25000,
          frequency: 60,
          label: '',
        },
      },
    ],
    'openrailwaymap_electrification-electrification_signals': [
      // TODO source from data file
      {
        legend: 'AT andkündigung stromabnehmer tief',
        type: 'point',
        properties: {
          feature: 'de/el3',
          type: 'line',
          azimuth: 90.0,
        },
      },
    ],
  },
  gauge: {
    'openrailwaymap_low-railway_line_low': [
      ...[
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
      ].map(({min, legend}) => ({
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
      ...[
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
      ].map(({min, legend}) => ({
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
    'openrailwaymap_gauge-gauge_railway_line': [
      ...[
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
      ].map(({min, legend}) => ({
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
          label: '3500'
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
          label: '',
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
          label: '',
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
          label: '',
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
          label: '',
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
          label: '',
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

  const legendSources = Object.fromEntries(
    legendZoomLevels.flatMap(legendZoom => {
      let entry = 0;
      let done = new Set();

      const featureSourceLayers = sourceLayers.flatMap(layer => {
        const legendLayerName = `${layer.source}-${layer['source-layer']}`;
        const sourceName = `${legendLayerName}-z${legendZoom}`
        if (done.has(sourceName)) {
          return [];
        }

        const applicable = layerVisibleAtZoom(legendZoom)(layer);
        const data = applicable ? (legendData[style][legendLayerName] ?? []) : [];
        const features = data.map(item => {
          const feature = {
            type: 'Feature',
            geometry: {
              type: item.type === 'line' || item.type === 'polygon'
                ? 'LineString'
                : 'Point',
              coordinates:
                item.type === 'line' ? [
                  legendPointToMapPoint(legendZoom, [-1.5, -entry * 0.6]),
                  legendPointToMapPoint(legendZoom, [-0.0, -entry * 0.6]),
                ] :
                item.type === 'polygon' ? Array.from({length: 20 + 1}, (_, i) => i * Math.PI * 2 / 20).map(phi =>
                    legendPointToMapPoint(legendZoom, [Math.cos(phi) * 0.1 - 0.5, Math.sin(phi) * 0.1 - entry * 0.6]))
                : legendPointToMapPoint(legendZoom, [-0.75, -entry * 0.6]),
            },
            properties: item.properties,
          };
          entry ++;
          return feature;
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
          const feature = {
            type: 'Feature',
            geometry: {
              type: "Point",
              coordinates: legendPointToMapPoint(legendZoom, [0.5, -entry * 0.6]),
            },
            properties: {
              legend: item.legend,
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

  return {
    ...sourceStyle,
    name: `${sourceStyle.name} legend`,
    layers: legendLayers,
    sources: legendSources,
  };
}

const mapStyles = Object.fromEntries(
  Object.keys(knownStyles)
    .map(style => [style, makeStyle(style)])
);

const legendStyles = Object.fromEntries(
  Object.keys(knownStyles)
    .map(style => [style, makeLegendStyle(style)])
);

const legendMap = new maplibregl.Map({
  container: 'legend-map',
  style: legendStyles[selectedStyle],
  zoom: 5,
  center: [0, 0],
  attributionControl: false,
  interactive: false,
});

const map = new maplibregl.Map({
  container: 'map',
  style: mapStyles[selectedStyle],
  hash: 'view',
  minZoom: globalMinZoom,
  maxZoom: glodalMaxZoom,
  minPitch: 0,
  maxPitch: 0,
});

class StyleControl {
  constructor(options) {
    this.options = options
  }

  onAdd(map) {
    this._map = map;
    this._container = createDomElement('div', 'maplibregl-ctrl maplibregl-ctrl-group maplibregl-ctrl-style');
    const form = createDomElement('form', 'form form-inline', this._container);
    const span = createDomElement('span', '', form);
    span.innerHTML = 'Style:&nbsp;'

    Object.entries(knownStyles).forEach(([name, styleLabel]) => {
      const id = `style-${name}`
      const wrapper = createDomElement('div', 'form-check form-check-inline', form);
      const button = createDomElement('input', 'form-check-input', wrapper);
      button.id = id
      button.type = 'radio'
      button.name = 'style'
      button.value = name
      button.onclick = () => this.options.onStyleChange(name)
      button.checked = (this.options.initialSelection === name)
      const label = createDomElement('label', 'form-check-label', wrapper);
      label.htmlFor = id
      label.innerText = styleLabel
    });

    return this._container;
  }

  onRemove() {
    removeDomElement(this._container);
    this._map = undefined;
  }
}

class SearchControl {
  onAdd(map) {
    this._map = map;
    this._container = createDomElement('div', 'maplibregl-ctrl maplibregl-ctrl-group');
    const button = createDomElement('button', 'maplibregl-ctrl-search', this._container);
    button.type = 'button';
    button.title = 'Search for places'
    button.onclick = _ => showSearch();
    createDomElement('span', 'maplibregl-ctrl-icon', button);

    return this._container;
  }

  onRemove() {
    removeDomElement(this._container);
    this._map = undefined;
  }
}

class EditControl {
  onAdd(map) {
    this._map = map;
    this._container = createDomElement('div', 'maplibregl-ctrl maplibregl-ctrl-group');
    const button = createDomElement('button', 'maplibregl-ctrl-edit', this._container);
    button.type = 'button';
    button.title = 'Edit map data'
    button.onclick = _ => window.open(`https://www.openstreetmap.org/edit#map=${Math.round(this._map.getZoom()) + 1}/${this._map.getCenter().lat}/${this._map.getCenter().lng}`, '_blank');
    createDomElement('span', 'maplibregl-ctrl-icon', button);

    return this._container;
  }

  onRemove() {
    removeDomElement(this._container);
    this._map = undefined;
  }
}

class LegendControl {
  constructor(options) {
    this.options = options;
  }

  onAdd(map) {
    this._map = map;
    this._container = createDomElement('div', 'maplibregl-ctrl maplibregl-ctrl-group');
    const button = createDomElement('button', 'maplibregl-ctrl-legend', this._container);
    button.type = 'button';
    button.title = 'Show/hide map legend';
    const icon = createDomElement('span', 'maplibregl-ctrl-icon', button);
    const text = createDomElement('span', '', icon);
    text.innerText = 'Legend'

    button.onclick = () => this.options.onLegendToggle()

    return this._container;
  }

  onRemove() {
    removeDomElement(this._container);
    this._map = undefined;
  }
}

map.addControl(new StyleControl({
  initialSelection: selectedStyle,
  onStyleChange: changedStyle => {
    map.setStyle(mapStyles[changedStyle]);
    legendMap.setStyle(legendStyles[changedStyle]);
    const updatedHash = putStyleInHash(window.location.hash, changedStyle);
    const location = window.location.href.replace(/(#.+)?$/, updatedHash);
    window.history.replaceState(window.history.state, null, location);
  }
}));
map.addControl(new maplibregl.NavigationControl({
  showCompass: false,
  visualizePitch: false,
}));
map.addControl(new SearchControl());
map.addControl(
  new maplibregl.GeolocateControl({
    positionOptions: {
      enableHighAccuracy: true
    },
    trackUserLocation: true,
    showAccuracyCircle: false,
    showUserLocation: true,
  })
);
map.addControl(new maplibregl.FullscreenControl());
map.addControl(new EditControl());

map.addControl(new maplibregl.ScaleControl({
  maxWidth: 150,
  unit: 'metric',
}), 'bottom-right');

map.addControl(new LegendControl({
  onLegendToggle: toggleLegend,
}), 'bottom-left');

const onMapZoom = zoom => {
  const legendZoom = Math.floor(zoom);
  const numberOfLegendEntries = legendStyles[selectedStyle]
    .sources[`legend-z${legendZoom}`]
    .data
    .features
    .length

  legendMap.jumpTo({
    zoom: legendZoom,
    center: legendPointToMapPoint(legendZoom, [1, -((numberOfLegendEntries - 2) / 2) * 0.6]),
  });
  legendMapContainer.style.height = `${numberOfLegendEntries * 30}px`;
}


map.on('load', () => onMapZoom(map.getZoom()));
map.on('zoomend', () => onMapZoom(map.getZoom()));