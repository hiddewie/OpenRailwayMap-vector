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

const coordinateFactor = legendZoom => Math.pow(2, 5 - legendZoom);

const legendPointToMapPoint = (zoom, [x, y]) =>
  [x * coordinateFactor(zoom), y * coordinateFactor(zoom)]

const mapStyles = Object.fromEntries(
  Object.keys(knownStyles)
    .map(style => [style, `http://localhost:8000/style/${style}.json`])
);

const legendStyles = Object.fromEntries(
  Object.keys(knownStyles)
    .map(style => [style, `http://localhost:8000/style/legend-${style}.json`])
);

const legendMap = new maplibregl.Map({
  container: 'legend-map',
  style: legendStyles[selectedStyle],
  zoom: 5,
  center: [0, 0],
  attributionControl: false,
  interactive: false,
  // See https://github.com/maplibre/maplibre-gl-js/issues/3503
  maxCanvasSize: [Infinity, Infinity],
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
  onStyleChange: changedStyle => {
    selectedStyle = changedStyle;

    // Change styles
    map.setStyle(mapStyles[changedStyle], {validate: false});
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
}));
map.addControl(new maplibregl.NavigationControl({
  showCompass: false,
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

// Listen to the first stylesheet change
// Followup stylesheet changes are handled by the style change callback
legendMap.once('styledata', e => onStylesheetChange(e.style.stylesheet));
