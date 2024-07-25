const searchBackdrop = document.getElementById('search-backdrop');
const searchFacilitiesTab = document.getElementById('search-facilities-tab');
const searchMilestonesTab = document.getElementById('search-milestones-tab');
const searchFacilitiesForm = document.getElementById('search-facilities-form');
const searchMilestonesForm = document.getElementById('search-milestones-form');
const searchFacilityTermField = document.getElementById('facility-term');
const searchMilestoneRefField = document.getElementById('milestone-ref');
const searchResults = document.getElementById('search-results');
const configurationBackdrop = document.getElementById('configuration-backdrop');
const backgroundSaturationControl = document.getElementById('backgroundSaturation');
const backgroundOpacityControl = document.getElementById('backgroundOpacity');
const backgroundRasterUrlControl = document.getElementById('backgroundRasterUrl');
const legend = document.getElementById('legend')
const legendMapContainer = document.getElementById('legend-map')

function registerLastSearchResults(results) {
  const data = {
    type: 'FeatureCollection',
    features: results.map(result => ({
      type: 'Feature',
      properties: result,
      geometry: {
        type: 'Point',
        coordinates: [result.latitude, result.longitude],
      },
    })),
  };
  map.getSource('search').setData(data);
}

function facilitySearchQuery(type, term) {
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

function searchForFacilities(type, term) {
  if (!term || term.length < 2) {
    hideSearchResults();
  } else {
    const queryString = facilitySearchQuery(type, term)
    fetch(`${location.origin}/api/facility?${queryString}`)
      .then(result => result.json())
      .then(result => {
        console.info('facility search result', result)
        showSearchResults(result, item => item.name)
      })
      .catch(error => {
        hideSearchResults();
        hideSearch();
        console.error(error);
      });
  }
}

function searchForMilestones(ref, position) {
  if (!ref || !position) {
    hideSearchResults();
  } else {
    fetch(`${location.origin}/api/milestone?ref=${encodeURIComponent(ref)}&position=${encodeURIComponent(position)}`)
      .then(result => result.json())
      .then(result => {
        console.info('milestone search result', result)
        showSearchResults(result, item => `Ref: ${item.ref}, KM: ${item.position}`)
      })
      .catch(error => {
        hideSearchResults();
        hideSearch();
        console.error(error);
      });
  }
}

function showSearchResults(results, renderItem) {
  registerLastSearchResults(results);

  const bounds = results.length > 0
    ? JSON.stringify(results.reduce(
      (bounds, result) =>
        bounds.extend({lat: result.longitude, lon: result.latitude}),
      new maplibregl.LngLatBounds({lat: results[0].longitude, lon: results[0].latitude})
    ).toArray())
    : null;

  searchResults.innerHTML = results.length === 0
    ? `
      <div class="mb-1 d-flex align-items-center">
        <span class="flex-grow-1">
          <span class="badge badge-light">0 results</span>
        </span>
      </div>
    `
    : `
      <div class="mb-1 d-flex align-items-center">
        <span class="flex-grow-1">
          <span class="badge badge-light">${results.length} results</span>
        </span>
        <button class="btn btn-sm btn-primary" type="button" style="vertical-align: text-bottom" onclick="viewSearchResultsOnMap(${bounds})">
          <svg width="auto" height="16" viewBox="-4 0 36 36" xmlns="http://www.w3.org/2000/svg"><g fill="none" fill-rule="evenodd"><path d="M14 0c7.732 0 14 5.641 14 12.6C28 23.963 14 36 14 36S0 24.064 0 12.6C0 5.641 6.268 0 14 0Z" fill="white"/><circle fill="var(--primary)" fill-rule="nonzero" cx="14" cy="14" r="7"/></g></svg>
          Show on map
        </button>
      </div>
      <div class="list-group">
        ${results.map(result =>
          `<a class="list-group-item list-group-item-action" href="javascript:hideSearchResults(); map.easeTo({center: [${result.latitude}, ${result.longitude}], zoom: 15}); hideSearch()">
            ${renderItem(result)}
          </a>`
        ).join('')}
      </div>
    `;
  searchResults.style.display = 'block';
}

function hideSearchResults() {
  searchResults.style.display = 'none';
  registerLastSearchResults([]);
}

function showSearch() {
  searchBackdrop.style.display = 'block';
  if (searchFacilitiesForm.style.display !== 'none') {
    searchFacilityTermField.focus();
    searchFacilityTermField.select();
  } else if (searchMilestonesForm.style.display !== 'none') {
    searchMilestoneRefField.focus();
    searchMilestoneRefField.select();
  }
}

function hideSearch() {
  searchBackdrop.style.display = 'none';
}

function searchFacilities() {
  searchFacilitiesTab.classList.add('active')
  searchMilestonesTab.classList.remove('active')
  searchFacilitiesForm.style.display = 'block';
  searchMilestonesForm.style.display = 'none';
  searchFacilityTermField.focus();
  searchFacilityTermField.select();
  hideSearchResults();
}

function searchMilestones() {
  searchFacilitiesTab.classList.remove('active')
  searchMilestonesTab.classList.add('active')
  searchFacilitiesForm.style.display = 'none';
  searchMilestonesForm.style.display = 'block';
  searchMilestoneRefField.focus();
  searchMilestoneRefField.select();
  hideSearchResults();
}

function viewSearchResultsOnMap(bounds) {
  hideSearch();
  map.fitBounds(bounds, {
    padding: 40,
  });
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

searchFacilitiesForm.addEventListener('submit', event => {
  event.preventDefault();
  const formData = new FormData(event.target);
  const data = Object.fromEntries(formData);
  searchForFacilities(data.type, data.term)
})
searchMilestonesForm.addEventListener('submit', event => {
  event.preventDefault();
  const formData = new FormData(event.target);
  const data = Object.fromEntries(formData);
  searchForMilestones(data.ref, data.position)
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
const globalMaxZoom = 18;
const globalMaxBounds = [[-10.0, 35.7], [39.0, 70.0]];

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
  maxZoom: globalMaxZoom,
  minPitch: 0,
  maxPitch: 0,
  maxBounds: globalMaxBounds,
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

// When a click event occurs on a feature in the places layer, open a popup at the
// location of the feature, with description HTML from its properties.
map.on('click', 'search', (e) => {
  const feature = e.features[0];
  const coordinates = feature.geometry.coordinates.slice();
  const properties = feature.properties;
  const content = `
    <h6><span title="${properties.railway}">(i)</span> <a href="https://www.openstreetmap.org/node/${properties.osm_id}" target="_blank">${properties.name}</a> <a href="https://www.openstreetmap.org/edit/node=${properties.osm_id}" target="_blank">${properties.name}</a>(e)</a></h6>
    <h6>
      ${properties.railway_ref ? `<span class="badge badge-pill badge-light">reference: <span class="text-monospace">${properties.railway_ref}</span></span>` : ''} 
      ${properties.ref ? `<span class="badge badge-pill badge-light">reference: <span class="text-monospace">${properties.ref}</span></span>` : ''} 
      ${properties.uic_ref ? `<span class="badge badge-pill badge-light">UIC reference: <span class="text-monospace">${properties.uic_ref}</span></span>` : ''}
      ${properties.position ? `<span class="badge badge-pill badge-light">position: ${properties.position}</span>` : ''}
      ${properties.operator ? `<span class="badge badge-pill badge-light">operator: ${properties.operator}</span>` : ''}
    </h6>
  `;

  new maplibregl.Popup()
    .setLngLat(coordinates)
    .setHTML(content)
    .addTo(map);
});

// Change the cursor to a pointer when the mouse is over the places layer.
map.on('mouseenter', 'search', () => {
  map.getCanvas().style.cursor = 'pointer';
});

// Change it back to a pointer when it leaves.
map.on('mouseleave', 'search', () => {
  map.getCanvas().style.cursor = '';
});
