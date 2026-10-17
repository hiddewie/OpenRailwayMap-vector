// GeoJSON overlays drawn by a map style's own layers, and their base64 form.
//
// Unlike the other modules here, which Node runs at build time, this one is
// loaded by the browser.

export const sourceId = 'overlay';

const layerIdPrefix = `${sourceId}-`;

/**
 * The overlay's data, if it has the shape the overlay needs; throws an error saying what is wrong
 * otherwise
 */
function validate(data) {
  if (data === null || typeof data !== 'object' || Array.isArray(data)) {
    throw new Error('not a GeoJSON object');
  }
  if (!Array.isArray(data.features)) {
    throw new Error('not a GeoJSON FeatureCollection, it has no `features` list');
  }
  const invalidFeature = data.features.findIndex(feature => feature === null || typeof feature !== 'object' || Array.isArray(feature));
  if (invalidFeature !== -1) {
    throw new Error(`feature ${invalidFeature} is not a GeoJSON object`);
  }
  if (data.hides !== undefined) {
    if (data.hides === null || typeof data.hides !== 'object' || Array.isArray(data.hides)) {
      throw new Error('`hides` is not an object of tile layers');
    }
    for (const [layer, ids] of Object.entries(data.hides)) {
      const numbers = Array.isArray(ids) && ids.every(id => Number.isInteger(id) && id >= 0);
      const strings = Array.isArray(ids) && ids.every(id => typeof id === 'string' && id !== '');
      if (!numbers && !strings) {
        throw new Error(`\`hides.${layer}\` is not a list of feature ids, all numbers or all strings`);
      }
    }
  }
  return data;
}

/**
 * Base64 of the gzip of the overlay's JSON text
 */
export async function encodeBase64(data) {
  const gzipped = new Blob([new TextEncoder().encode(JSON.stringify(data))]).stream().pipeThrough(new CompressionStream('gzip'));
  const bytes = new Uint8Array(await new Response(gzipped).arrayBuffer());
  return btoa(Array.from(bytes, byte => String.fromCharCode(byte)).join(''));
}

/**
 * The validated overlay in base64 of its JSON text or of its gzip
 */
async function decodeBase64(base64) {
  const bytes = Uint8Array.from(atob(base64), character => character.charCodeAt(0));
  const gzipped = bytes.length > 2 && bytes[0] === 0x1f && bytes[1] === 0x8b;
  const text = gzipped
    ? await new Response(new Blob([bytes]).stream().pipeThrough(new DecompressionStream('gzip'))).text()
    : new TextDecoder().decode(bytes);
  return validate(JSON.parse(text));
}

let styleSpec = null;

/**
 * Loads the MapLibre style spec, which addToStyle needs.
 *
 * This is done this way, rather than as a static import, so only pages with an overlay load it.
 *
 * TODO: `maplibre-gl` itself always loads this, but has its own bundled version. If we redid the
 * bundling, we and `maplibre-gl` could share the same `maplibre-gl-style-spec`, and then there
 * would be no reason to do this sort of manual lazy loading.
 */
async function ready() {
  styleSpec ??= await import('@maplibre/maplibre-gl-style-spec');
}

/**
 * decodeBase64 after ready, but null without an overlay or when it cannot be decoded (which is
 * logged)
 */
export async function load(base64) {
  if (!base64) {
    return null;
  }
  try {
    await ready();
    const data = await decodeBase64(base64);
    console.info('Loaded overlay');
    return data;
  } catch (error) {
    console.error('Error during loading of overlay', error);
    return null;
  }
}

/**
 * The validated overlay in its JSON text, after ready; throws an error saying what is wrong
 * otherwise
 */
export async function parse(text) {
  const data = validate(JSON.parse(text));
  await ready();
  return data;
}

// The style spec's description of layer filters, which it does not export
const filterSpec = {
  type: 'boolean',
  default: false,
  transition: false,
  'property-type': 'data-driven',
  expression: {
    interpolated: false,
    parameters: ['zoom', 'feature'],
  },
};

const unknown = Symbol('unknown');

/**
 * Whether a feature (in the style spec's form, as `featureFilter` takes it) passes a layer filter
 * whatever the map's zoom and global state are: true if it passes under all of them, false if under
 * none, null if that depends on them, so that layers for other map styles are kept. Parts of the
 * filter that depend on neither are evaluated by the style spec; `all`, `any`, `!`, `case`, `match`,
 * `coalesce` and type assertions combine what is known of their arguments, and anything else that
 * depends on them, or fails to evaluate, is unknown. Needs ready.
 *
 * TODO: replace with `featureFilter(filter).mayMatch` once
 * https://github.com/maplibre/maplibre-style-spec/pull/1910 lands.
 */
function createMayMatch(filter, rootKey) {
  if (filter === null || filter === undefined) {
    return () => true;
  }
  const {CompoundExpression, EvaluationContext, convertFilter, createExpression, expressions, typeOf} = styleSpec;
  const compiled = createExpression(
    styleSpec.expression.isExpressionFilter(filter) ? filter : convertFilter(filter),
    rootKey,
    filterSpec,
  );
  if (compiled.result === 'error') {
    console.warn(`${rootKey}: ${compiled.value.map(error => error.message).join(', ')}`);
    return () => null;
  }
  const root = compiled.value.expression;

  // the subexpressions that depend on the zoom or on global state
  const dependent = new Set();
  const findDependent = expression => {
    let depends = expression instanceof expressions['global-state']
      || (expression instanceof CompoundExpression && expression.name === 'zoom');
    expression.eachChild(child => {
      if (findDependent(child)) depends = true;
    });
    if (depends) dependent.add(expression);
    return depends;
  };
  findDependent(root);

  const ctx = new EvaluationContext();
  const evaluate = expression => {
    if (!dependent.has(expression)) {
      try {
        return expression.evaluate(ctx);
      } catch {
        return unknown;
      }
    }
    if (expression instanceof CompoundExpression) {
      switch (expression.name) {
        case 'all': {
          let result = true;
          for (const arg of expression.args) {
            const value = evaluate(arg);
            if (value === unknown) result = unknown;
            else if (!value) return false;
          }
          return result;
        }
        case 'any': {
          let result = false;
          for (const arg of expression.args) {
            const value = evaluate(arg);
            if (value === unknown) result = unknown;
            else if (value) return true;
          }
          return result;
        }
        case '!': {
          const value = evaluate(expression.args[0]);
          return value === unknown ? unknown : !value;
        }
      }
      return unknown;
    }
    if (expression instanceof expressions.boolean) {
      // type assertions (`boolean`, `number`, `string`, ...): the first argument of the type
      for (const arg of expression.args) {
        const value = evaluate(arg);
        if (value === unknown) return unknown;
        if (typeOf(value).kind === expression.type.kind) return value;
      }
      return unknown;
    }
    if (expression instanceof expressions.case) {
      for (const [test, output] of expression.branches) {
        const value = evaluate(test);
        if (value === unknown) return unknown;
        if (value) return evaluate(output);
      }
      return evaluate(expression.otherwise);
    }
    if (expression instanceof expressions.match) {
      const input = evaluate(expression.input);
      if (input === unknown) return unknown;
      const output = (typeOf(input) === expression.inputType && expression.outputs[expression.cases[input]])
        || expression.otherwise;
      return evaluate(output);
    }
    if (expression instanceof expressions.coalesce) {
      for (const arg of expression.args) {
        const value = evaluate(arg);
        if (value === unknown) return unknown;
        if (value !== null) return value;
      }
      return null;
    }
    return unknown;
  };

  return feature => {
    ctx.globals = {};
    ctx.feature = feature;
    ctx.featureState = null;
    // a filter independent of them fails on errors, as `featureFilter` does
    if (!dependent.has(root)) {
      try {
        return root.evaluate(ctx) === true;
      } catch {
        return false;
      }
    }
    const value = evaluate(root);
    return value === unknown ? null : value === true;
  };
}

// vector tile geometry types, which `geometry-type` reports
const geometryTypes = {
  Point: 1,
  MultiPoint: 1,
  LineString: 2,
  MultiLineString: 2,
  Polygon: 3,
  MultiPolygon: 3,
};

/**
 * Puts the overlay (validated data) into a style object; needs ready.
 *
 * Each feature names in its `layer` property the tile layer (`source-layer`) it is drawn as, and
 * carries the properties that layer's features have: the style layers drawing that tile layer get
 * copies, each right after its original, that draw the overlay's features instead, so they look like
 * the tiled data. The feature ids the overlay's top-level `hides` lists for a tile layer are filtered
 * out of the style layers drawing it, for overlays that replace existing features.
 *
 * `featureId(sourceLayer)` is the expression giving a tile feature's id as `hides` lists it; by
 * default its vector tile feature id, `['id']` (in filters, `promoteId` does not apply). An
 * expression that fails to evaluate makes the filter false, hiding every feature, so it should
 * not fail.
 */
export function addToStyle(style, data, {featureId = () => ['id']} = {}) {
  style.sources[sourceId] = {
    type: 'geojson',
    data,
    generateId: true,
  };

  // the features in the form layer filters are evaluated on, by the tile layer they name
  const featuresByLayer = new Map();
  data.features.forEach(feature => {
    const layer = feature.properties?.layer;
    if (layer) {
      featuresByLayer.set(layer, [...(featuresByLayer.get(layer) ?? []), {
        type: geometryTypes[feature.geometry?.type] ?? 0,
        properties: feature.properties,
        id: feature.id,
      }]);
    }
  });


  style.layers = style.layers.flatMap(layer => {
    const sourceLayer = layer['source-layer'];
    if (!sourceLayer) {
      return [layer];
    }
    const layers = [layer];
    // a copy of every style layer drawing a wanted tile layer that some feature can pass the
    // filter of (every layer costs rendering time, so the many that cannot are left out), right
    // after its original
    const features = featuresByLayer.get(sourceLayer);
    const mayMatch = features && createMayMatch(layer.filter, `layers.${layer.id}.filter`);
    if (features && features.some(feature => mayMatch(feature) !== false)) {
      const copy = JSON.parse(JSON.stringify(layer));
      copy.id = `${layerIdPrefix}${layer.id}`;
      copy.source = sourceId;
      delete copy['source-layer'];
      copy.filter = ['all', ['==', ['get', 'layer'], sourceLayer], layer.filter ?? true];
      layers.push(copy);
    }
    // `match` looks the id up rather than scanning the list
    const hidden = [...new Set(data.hides?.[sourceLayer] ?? [])];
    if (hidden.length > 0) {
      layer.filter = ['all', layer.filter ?? true, ['match', featureId(sourceLayer), hidden, false, true]];
    }
    return layers;
  });
}

/**
 * The id of the style layer a layer drawing the overlay is a copy of
 */
export function originalLayerId(layerId) {
  return layerId.startsWith(layerIdPrefix) ? layerId.slice(layerIdPrefix.length) : null;
}
