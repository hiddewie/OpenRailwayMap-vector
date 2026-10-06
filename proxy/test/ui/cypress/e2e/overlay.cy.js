/**
 * GeoJSON overlays (proxy/js/overlay.mjs). The module and the style spec are imported in the page,
 * as ui.js gets them, so the import map and the served files are tested too.
 */

const view = '9.88/52.5134/13.4024'

// a module of the page, imported there
const pageImport = specifier => cy.window().then(win => win.eval(`import('${specifier}')`))
const overlayModule = () => pageImport('/js/overlay.mjs')

// ui.js's map once its style has loaded (ui.js's `map` is a global binding, not a window property)
const loadedMap = (check = 'true') => cy.window({timeout: 30000})
  .should(win => {
    expect(win.eval(`typeof map.getStyle === 'function' && !!map.getStyle()?.layers?.length && (${check})`)).to.equal(true)
  })
  .then(win => win.eval('map'))

// a small style: tile layers drawn by several style layers, as the map's style does
const style = () => ({
  version: 8,
  sources: {tiles: {type: 'vector', url: 'https://example.com/tiles.json', promoteId: 'id'}},
  layers: [
    {id: 'background', type: 'background'},
    {id: 'track', type: 'line', source: 'tiles', 'source-layer': 'tracks', filter: ['==', ['get', 'state'], 'present']},
    {id: 'track_tunnel', type: 'line', source: 'tiles', 'source-layer': 'tracks', filter: ['all', ['==', ['get', 'state'], 'present'], ['==', ['get', 'tunnel'], true]]},
    {id: 'track_proposed', type: 'line', source: 'tiles', 'source-layer': 'tracks', filter: ['==', ['get', 'state'], 'proposed']},
    {id: 'track_toggled', type: 'line', source: 'tiles', 'source-layer': 'tracks', filter: ['all', ['==', ['get', 'state'], 'present'], ['boolean', ['global-state', 'showTracks']]]},
    {id: 'track_zoomed', type: 'line', source: 'tiles', 'source-layer': 'tracks', filter: ['all', ['>=', ['zoom'], 10], ['==', ['get', 'usage'], 'main']]},
    {id: 'track_line_only', type: 'line', source: 'tiles', 'source-layer': 'tracks', filter: ['==', ['geometry-type'], 'LineString']},
    {id: 'platform', type: 'fill', source: 'tiles', 'source-layer': 'platforms'},
    {id: 'station', type: 'symbol', source: 'tiles', 'source-layer': 'stations'},
  ],
})

const track = (properties, type = 'LineString') => ({
  type: 'Feature',
  properties: {layer: 'tracks', state: 'present', usage: 'main', ...properties},
  geometry: {type, coordinates: type === 'LineString' ? [[13.40, 52.51], [13.41, 52.52]] : [[[13.40, 52.51], [13.41, 52.52]]]},
})
const platform = {type: 'Feature', properties: {layer: 'platforms'}, geometry: {type: 'Polygon', coordinates: [[[13.40, 52.51], [13.41, 52.51], [13.41, 52.52], [13.40, 52.51]]]}}

// a style with the overlay in it
const withOverlay = (overlay, data, options) => overlay.parse(JSON.stringify(data)).then(parsed => {
  const result = style()
  overlay.addToStyle(result, parsed, options)
  return result
})

// whether a tile feature passes a style layer's filter, as MapLibre evaluates it
const passes = (styleSpec, layer, id, properties = {}) =>
  styleSpec.featureFilter(layer.filter, layer.id).filter({zoom: 12}, {type: 2, id, properties})

describe('overlay module', () => {
  beforeEach(() => {
    cy.visit(`/#view=${view}`)
    loadedMap()
  })

  it('the overlay survives its base64 form, gzipped or plain', () => {
    const data = {type: 'FeatureCollection', hides: {tracks: [1]}, features: [track({})]}
    overlayModule().then(async overlay => {
      expect(await overlay.load(await overlay.encodeBase64(data))).to.deep.equal(data)
      expect(await overlay.load(btoa(JSON.stringify(data)))).to.deep.equal(data)
    })
  })

  it('load gives null without an overlay or for a broken one', () => {
    overlayModule().then(async overlay => {
      expect(await overlay.load(null)).to.equal(null)
      expect(await overlay.load('not base64!')).to.equal(null)
      expect(await overlay.load(btoa('{"features": {}}'))).to.equal(null)
    })
  })

  it('parse rejects what the overlay cannot use', () => {
    overlayModule().then(async overlay => {
      for (const bad of [
        'not json',
        '[]',
        '{"type": "FeatureCollection"}',
        '{"type": "FeatureCollection", "features": [null]}',
        '{"type": "FeatureCollection", "features": [], "hides": [1, 2]}',
        '{"type": "FeatureCollection", "features": [], "hides": {"tracks": [1, "2"]}}',
        '{"type": "FeatureCollection", "features": [], "hides": {"tracks": [-1]}}',
        '{"type": "FeatureCollection", "features": [], "hides": {"tracks": 1}}',
      ]) {
        const rejected = await overlay.parse(bad).then(() => false, () => true)
        expect(rejected, bad).to.equal(true)
      }
    })
  })

  it('the style layers that can draw a feature are copied, right after their originals', () => {
    overlayModule().then(overlay => withOverlay(overlay, {type: 'FeatureCollection', features: [track({}), platform]}).then(result => {
      expect(result.layers.map(layer => layer.id)).to.deep.equal([
        'background',
        'track', 'overlay-track',
        // a tunnel layer cannot draw a track that is not in a tunnel
        'track_tunnel',
        // nor one for proposed tracks a present one
        'track_proposed',
        // global state and zoom are unknown, so these may draw it
        'track_toggled', 'overlay-track_toggled',
        'track_zoomed', 'overlay-track_zoomed',
        'track_line_only', 'overlay-track_line_only',
        'platform', 'overlay-platform',
        // no feature names this tile layer
        'station',
      ])
      const copy = result.layers.find(layer => layer.id === 'overlay-track')
      expect(copy.source).to.equal(overlay.sourceId)
      expect(copy).not.to.have.property('source-layer')
      expect(copy.filter).to.deep.equal(['all', ['==', ['get', 'layer'], 'tracks'], ['==', ['get', 'state'], 'present']])
      expect(overlay.originalLayerId(copy.id)).to.equal('track')
      expect(overlay.originalLayerId('track')).to.equal(null)
      expect(result.sources[overlay.sourceId].type).to.equal('geojson')
    }))
  })

  it('a multi-geometry counts as its single kind, as in vector tiles', () => {
    overlayModule().then(overlay => withOverlay(overlay, {type: 'FeatureCollection', features: [track({}, 'MultiLineString')]}).then(result => {
      expect(result.layers.map(layer => layer.id)).to.include('overlay-track_line_only')
    }))
  })

  it('hides filters the listed features out of the tile layer they are listed for', () => {
    pageImport('@maplibre/maplibre-gl-style-spec').then(styleSpec =>
      overlayModule().then(overlay => withOverlay(overlay, {type: 'FeatureCollection', features: [], hides: {platforms: [7, 7]}}).then(result => {
        const platformLayer = result.layers.find(layer => layer.id === 'platform')
        expect(passes(styleSpec, platformLayer, 7)).to.equal(false)
        expect(passes(styleSpec, platformLayer, 8)).to.equal(true)
        expect(passes(styleSpec, platformLayer, undefined)).to.equal(true)
        // other tile layers are left alone
        expect(result.layers.find(layer => layer.id === 'track').filter).to.deep.equal(style().layers[1].filter)
      })))
  })

  it('hides can name features by another id than the feature id', () => {
    const featureId = sourceLayer => sourceLayer === 'tracks' ? ['to-number', ['get', 'way']] : ['id']
    pageImport('@maplibre/maplibre-gl-style-spec').then(styleSpec =>
      overlayModule().then(overlay => withOverlay(overlay, {type: 'FeatureCollection', features: [track({})], hides: {tracks: [123]}}, {featureId}).then(result => {
        const trackLayer = result.layers.find(layer => layer.id === 'track')
        expect(passes(styleSpec, trackLayer, 'a', {state: 'present', way: 123})).to.equal(false)
        expect(passes(styleSpec, trackLayer, 'b', {state: 'present', way: 124})).to.equal(true)
        // the copies drawing the overlay are not filtered
        expect(result.layers.find(layer => layer.id === 'overlay-track').filter[2]).to.deep.equal(trackLayer.filter[1])
      })))
  })
})

describe('overlay on the map', () => {
  const data = {
    type: 'FeatureCollection',
    hides: {railway_line_high: [123456]},
    features: [{
      type: 'Feature',
      properties: {layer: 'railway_line_high', feature: 'rail', state: 'present', usage: 'main', name: 'New line'},
      geometry: {type: 'LineString', coordinates: [[13.40, 52.51], [13.41, 52.52]]},
    }],
  }

  const expectOverlayIn = map => {
    const layers = map.getStyle().layers
    expect(layers.some(layer => layer.id.startsWith('overlay-') && layer.source === 'overlay')).to.equal(true)
    // the hidden way is filtered out of the tracks
    const tracks = layers.filter(layer => layer['source-layer'] === 'railway_line_high')
    expect(tracks.length).to.be.greaterThan(0)
    tracks.forEach(layer => expect(JSON.stringify(layer.filter)).to.include('[123456],false,true'))
  }

  it('an overlay in the link is drawn', () => {
    cy.visit(`/#view=${view}`)
    loadedMap()
    overlayModule().then(overlay => overlay.encodeBase64(data)).then(base64 => {
      cy.visit(`/#view=${view}&overlay-base64=${encodeURIComponent(base64)}`)
      cy.reload()
      loadedMap('!!map.getStyle().sources.overlay').then(expectOverlayIn)
    })
  })

  it('an overlay pasted into the configuration is drawn and put in the link', () => {
    cy.visit(`/#view=${view}`)
    loadedMap()

    cy.get('.maplibregl-ctrl-configuration').click()
    cy.contains('Map configuration').should('be.visible')

    cy.get('#overlayJson').invoke('val', '{"type": "FeatureCollection"').trigger('change')
    cy.get('#overlayJson').should(field => expect(field[0].validationMessage).to.include('cannot be loaded'))
    cy.url().should('not.include', 'overlay-base64=')

    cy.get('#overlayJson').invoke('val', JSON.stringify(data)).trigger('change')
    cy.get('#overlayJson').should(field => expect(field[0].validationMessage).to.equal(''))
    cy.url().should('include', 'overlay-base64=')
    loadedMap('!!map.getStyle().sources.overlay').then(expectOverlayIn)

    cy.get('#overlayJson').invoke('val', '').trigger('change')
    cy.url().should('not.include', 'overlay-base64=')
  })
})
