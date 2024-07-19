const searchBackdrop = document.getElementById('search-backdrop');
const search = document.getElementById('search');
const searchFacilitiesTab = document.getElementById('search-facilities-tab');
const searchMilestonesTab = document.getElementById('search-milestones-tab');
const facilitySearchForm = document.getElementById('facility-search-form');
const searchResults = document.getElementById('search-results');
const configurationBackdrop = document.getElementById('configuration-backdrop');
const backgroundSaturationControl = document.getElementById('backgroundSaturation');
const backgroundOpacityControl = document.getElementById('backgroundOpacity');
const backgroundRasterUrlControl = document.getElementById('backgroundRasterUrl');
const legend = document.getElementById('legend')
const legendMapContainer = document.getElementById('legend-map')

function searchQuery(type, term) {
  const encoded = encodeURIComponent(term)

  switch (type) {
    case 'name':
      return `name=${encoded}`;
    case 'ref':
      return `ref=${encoded}`;
    case 'uic_ref':
      return `uic_ref=${encoded}`;
    case 'all':
    default:
      return `q=${encoded}`;
  }
}

function searchFor(type, term) {
  if (!term || term.length < 2) {
    hideSearchResults();
  } else {
    const queryString = searchQuery(type, term)
    fetch(`${location.origin}/api/facility?${queryString}`)
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
    content += `<div class="list-group-item no-results"><i>No results</i></div>`
  } else {
    results.forEach(result => {
      content += `<a class="list-group-item list-group-item-action" href="javascript:hideSearchResults(); map.easeTo({center: [${result.latitude}, ${result.longitude}], zoom: 15}); hideSearch()">${result.name}</a>`
    })
  }
  searchResults.innerHTML = content;
  searchResults.style.display = 'block';
}

function hideSearchResults() {
  searchResults.style.display = 'none';
}

function showSearch() {
  searchBackdrop.style.display = 'block';
  search.focus();
  search.select();
}

function hideSearch() {
  searchBackdrop.style.display = 'none';
}

function searchFacilities() {
  searchFacilitiesTab.classList.add('active')
  searchMilestonesTab.classList.remove('active')
}

function searchMilestones() {
  searchFacilitiesTab.classList.remove('active')
  searchMilestonesTab.classList.add('active')
}

function showConfiguration() {
  backgroundSaturationControl.value = configuration.backgroundSaturation ?? defaultConfiguration.backgroundSaturation;
  backgroundOpacityControl.value = configuration.backgroundOpacity ?? defaultConfiguration.backgroundOpacity;
  backgroundRasterUrlControl.value = configuration.backgroundRasterUrl ?? defaultConfiguration.backgroundRasterUrl;
  configurationBackdrop.style.display = 'block';
}

function hideConfiguration() {
  configurationBackdrop.style.display = 'none';
}

function toggleLegend() {
  if (legend.style.display === 'block') {
    legend.style.display = 'none';
  } else {
    legend.style.display = 'block';
  }
}

facilitySearchForm.addEventListener('submit', event => {
  event.preventDefault();
  const formData = new FormData(event.target);
  const data = Object.fromEntries(formData);
  searchFor(data.type, data.term)
})
searchBackdrop.onclick = event => {
  if (event.target === event.currentTarget) {
    hideSearch();
  }
};
configurationBackdrop.onclick = event => {
  if (event.target === event.currentTarget) {
    hideConfiguration();
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
const glodalMaxZoom = 18;

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

let selectedStyle = determineStyleFromHash(window.location.hash)

// Configuration //

const localStorageKey = 'openrailwaymap-configuration';
function readConfiguration(localStorage) {
  const rawConfiguration = localStorage.getItem(localStorageKey);
  if (rawConfiguration) {
    try {
      const parsedConfiguration = JSON.parse(rawConfiguration);
      console.info('Found local configuration', parsedConfiguration);
      return parsedConfiguration;
    } catch (exception) {
      console.error('Error parsing local storage value. Deleting from local storage. Value:', rawConfiguration, 'Error:', exception)
      localStorage.removeItem(localStorageKey)
      return {};
    }
  } else {
    return {};
  }
}
function storeConfiguration(localStorage, configuration) {
  localStorage.setItem(localStorageKey, JSON.stringify(configuration));
}
function updateConfiguration(name, value) {
  configuration[name] = value;
  storeConfiguration(localStorage, configuration)
  onStyleChange(selectedStyle);
}

const defaultConfiguration = {
  backgroundSaturation: -1.0,
  backgroundOpacity: 1.0,
  backgroundRasterUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
}
let configuration = readConfiguration(localStorage);

const coordinateFactor = legendZoom => Math.pow(2, 5 - legendZoom);

const legendPointToMapPoint = (zoom, [x, y]) =>
  [x * coordinateFactor(zoom), y * coordinateFactor(zoom)]

const mapStyles = Object.fromEntries(
  Object.keys(knownStyles)
    .map(style => [style, `${location.origin}/style/${style}.json`])
);

const legendStyles = Object.fromEntries(
  Object.keys(knownStyles)
    .map(style => [style, `${location.origin}/style/legend-${style}.json`])
);

const transformMapStyle = (style, configuration) => {
  const backgroundMapLayer = style.layers.find(it => it.id === 'background-map');
  backgroundMapLayer.paint['raster-saturation'] = configuration.backgroundSaturation ?? defaultConfiguration.backgroundSaturation;
  backgroundMapLayer.paint['raster-opacity'] = configuration.backgroundOpacity ?? defaultConfiguration.backgroundOpacity;

  const backgroundMapSource = style.sources.background_map;
  backgroundMapSource.tiles = [configuration.backgroundRasterUrl ?? defaultConfiguration.backgroundRasterUrl];

  return style;
}

const legendMap = new maplibregl.Map({
  container: 'legend-map',
  zoom: 5,
  center: [0, 0],
  attributionControl: false,
  interactive: false,
  // See https://github.com/maplibre/maplibre-gl-js/issues/3503
  maxCanvasSize: [Infinity, Infinity],
});

const map = new maplibregl.Map({
  container: 'map',
  hash: 'view',
  minZoom: globalMinZoom,
  maxZoom: glodalMaxZoom,
  minPitch: 0,
  maxPitch: 0,
});

const onStyleChange = changedStyle => {
  selectedStyle = changedStyle;

  // Change styles
  map.setStyle(mapStyles[changedStyle], {
    validate: false,
    transformStyle: (previous, next) => {
      return transformMapStyle(next, configuration);
    },
  });
  legendMap.setStyle(legendStyles[changedStyle], {
    validate: false,
    transformStyle: (previous, next) => {
      onStylesheetChange(next);
      return next;
    },
  });

  // Update URL
  const updatedHash = putStyleInHash(window.location.hash, changedStyle);
  const location = window.location.href.replace(/(#.+)?$/, updatedHash);
  window.history.replaceState(window.history.state, null, location);
}

onStyleChange(selectedStyle);

class StyleControl {
  constructor(options) {
    this.options = options
  }

  onAdd(map) {
    this._map = map;
    this._container = createDomElement('div', 'maplibregl-ctrl maplibregl-ctrl-group maplibregl-ctrl-style');
    const buttonGroup = createDomElement('div', 'btn-group-vertical btn-group-toggle', this._container);

    Object.entries(knownStyles).forEach(([name, styleLabel]) => {
      const id = `style-${name}`
      const label = createDomElement('label', 'btn btn-light', buttonGroup);
      label.htmlFor = id
      label.innerText = styleLabel
      const radio = createDomElement('input', '', label);
      radio.id = id
      radio.type = 'radio'
      radio.name = 'style'
      radio.value = name
      radio.onclick = () => this.options.onStyleChange(name)
      radio.checked = (this.options.initialSelection === name)
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
    const icon = createDomElement('span', 'maplibregl-ctrl-icon', button);
    const text = createDomElement('span', '', icon);
    text.innerText = 'Search'

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

class ConfigurationControl {
  onAdd(map) {
    this._map = map;
    this._container = createDomElement('div', 'maplibregl-ctrl maplibregl-ctrl-group');
    const button = createDomElement('button', 'maplibregl-ctrl-configuration', this._container);
    button.type = 'button';
    button.title = 'Configure the map'
    button.onclick = _ => showConfiguration();
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

// Cache for the number of items in the legend, per style and zoom level
const legendEntriesCount = Object.fromEntries(Object.keys(knownStyles).map(key => [key, {}]));

map.addControl(new StyleControl({
  initialSelection: selectedStyle,
  onStyleChange,
}));
map.addControl(new maplibregl.NavigationControl({
  showCompass: true,
  visualizePitch: false,
}));
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
map.addControl(new ConfigurationControl());

map.addControl(new SearchControl(), 'top-left');

map.addControl(new maplibregl.ScaleControl({
  maxWidth: 150,
  unit: 'metric',
}), 'bottom-right');

map.addControl(new LegendControl({
  onLegendToggle: toggleLegend,
}), 'bottom-left');

const onMapZoom = zoom => {
  const legendZoom = Math.floor(zoom);
  const numberOfLegendEntries = legendEntriesCount[selectedStyle][legendZoom] ?? 100;

  legendMap.jumpTo({
    zoom: legendZoom,
    center: legendPointToMapPoint(legendZoom, [1, -((numberOfLegendEntries - 2) / 2) * 0.6]),
  });
  legendMapContainer.style.height = `${numberOfLegendEntries * 30}px`;
}

const onStylesheetChange = styleSheet => {
  const styleName = styleSheet.metadata.name;
  styleSheet.layers.forEach(layer => {
    if (layer.metadata && layer.metadata['legend:zoom'] && layer.metadata['legend:count']) {
      legendEntriesCount[styleName][layer.metadata['legend:zoom']] = layer.metadata['legend:count']
    }
  })
  onMapZoom(map.getZoom());
}

map.on('load', () => onMapZoom(map.getZoom()));
map.on('zoomend', () => onMapZoom(map.getZoom()));
