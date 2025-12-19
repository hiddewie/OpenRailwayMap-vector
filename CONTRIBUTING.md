# Contributing

Contributions to the OpenRailwayMap are appreciated!

For a number of specific types of contributions, there are detailed instructions below. In other cases, feel free to open an issue or pull request!

Use the instructions in [the local development setup documentation](SETUP.md) to run the project locally. This can help to get a visual feedback on your changes.

## I want to visualize a new train protection system on the map

Edit the file [`features/train_protection.yaml`](https://github.com/hiddewie/OpenRailwayMap-vector/edit/master/features/train_protection.yaml).

The file contains a list of train protection systems, each with a code, a legend and a color.

At the top of the file, add an entry for the legend, For example:
```yaml
train_protections:
  - { train_protection: 'new', legend: 'Description about this new train protection system', color: '#abc123' }
```

In the body of the file, add a new entry at a certain place in the list. The `rank` should match the ordering of the entries. The value of `train_protection` should match the value in the legend entries. For example:
```yaml
features:
  - train_protection: new
    tags:
      - { tag: 'railway:new', value: 'yes' }
```

Open a pull request where you provide details about the new train protection system. Ensure the pull request contains references to documentation and places on the map where the train protection system exists.

## I want to visualize a new railway signal

Railway signals are present on three layers. The features are defined in a YAML file [`features/signals_railway_signals.yaml`](https://github.com/hiddewie/OpenRailwayMap-vector/edit/master/features/signals_railway_signals.yaml).

The file contains a list of signal tags, a list of signal types and all known signal features.

In the body of the file, add a new entry for the new railway signal. The signals are grouped by country. Every signal has a description, a set of tags and an icon. The icon can optionally have a `match` clause to match tag values to render the feature differently based on the matched tag value.

For example, to match railway signals with tags `railway:signal:shunting=AT-V2:verschubhalttafel` and `railway:signal:shunting:form=sign` with icon `at/verschubhalttafel`:
```yaml
features:
  - description: Verschubhalttafel
    country: AT
    icon: [ default: 'at/verschubhalttafel' ]
    tags:
      - { tag: 'railway:signal:shunting', value: 'AT-V2:verschubhalttafel' }
      - { tag: 'railway:signal:shunting:form', value: 'sign' }
```

A more complicated example matches a tag to show a different icon and legend for different values of the same feature. Matching is always performed from top to bottom. For example the signal `railway:signal:train_protection=BE:PRA` has a different icon for each of the signal positions: `railway:signal:position` can be `left`, `overhead` or `right` (the default value). Every variant can have its own description which will be used in the legend:
```yaml
features:
  - description: train protection block markers
    country: BE
    icon:
      - match: 'railway:signal:position'
        cases:
          - exact: 'left'
            value: 'be/PRA-arrow-right'
            description: 'left'
          - exact: 'overhead'
            value: 'be/PRA-arrow-down'
            description: 'overhead'
        default: 'be/PRA-arrow-left'
    tags:
      - { tag: 'railway:signal:train_protection', value: 'BE:PRA' }
      - { tag: 'railway:signal:train_protection:form', value: 'sign' }
```

The type of the matched tag matters. You can find the type of every tag at the top of the file. Any tag without a type is a string tag, so matching is always performed on the full tag value.

Matching a tag with a `boolean` type (`yes`/`no`) does not need to match a value. For example `railway:signal:main_repeated:magnet` is a boolean tag:
```yaml
features:
  - description: Signalnachahmer
    country: AT
    icon:
      - match: 'railway:signal:main_repeated:magnet'
        cases:
          - { value: 'at/signalnachahmer-magnet', description: '1000Hz magnet' }
        default: 'at/signalnachahmer'
    tags:
      - { tag: 'railway:signal:main_repeated', value: 'AT-V2:signalnachahmer' }
      - { tag: 'railway:signal:main_repeated:form', value: 'light' }
```

Matching a tag with an `array` type (`;`-separated values) can happen in multiple ways:
- `exact` match: the given match value must equal at least one of the tag values
- `regex` match: the given match value must match with the at least one of the tag values
- `any` match: at least one element in the given match array must be in the tag values
- `all` match: all elements in the given match array must be in the tag values

Matching an `exact` and `any` value. For example a node with `railway:signal:distant:states=AT-V2:hauptsignal_frei_mit_60;AT-V2:hauptsignal_frei_mit_40` will match the first case, and a node with `railway:signal:distant:states=AT-V2:hauptsignal_frei_mit_20;AT-V2:hauptsignal_frei` will match the second case:
```yaml
features:
- description: distant (light)
  country: AT
  icon:
    - match: 'railway:signal:distant:states'
      cases:
        - { exact: 'AT-V2:hauptsignal_frei_mit_60', value: 'at/vorsignal-frei-mit-60', description: '60 km/h' }
        - { any: ['AT-V2:hauptsignal_frei_mit_40', 'AT-V2:hauptsignal_frei_mit_20'], value: 'at/vorsignal-frei-mit-40', description: '20/40 km/h' }
        - { exact: 'AT-V2:hauptsignal_frei', value: 'at/vorsignal-frei', description: 'clear' }
      default: 'at/vorsignal-vorsicht'
  tags:
    - { tag: 'railway:signal:distant', value: 'AT-V2:vorsignal' }
    - { tag: 'railway:signal:distant:form', value: 'light' }
```

Matching with `exact` and `all`. For example a node with `railway:signal:main:states=PL-PKP:sr1;PL-PKP:sr2` will match the second case:
```yaml
features:
  - description: Semafor kształtowy
    country: PL
    icon:
      - match: 'railway:signal:main:states'
        cases:
          - { exact: 'PL-PKP:sr3', value: 'pl/sr3' }
          - { all: ['PL-PKP:sr1', 'PL-PKP:sr2'], value: 'pl/sr2' }
        default: 'pl/sr1'
    tags:
      - { tag: 'railway:signal:main', value: 'PL-PKP:sr' }
      - { tag: 'railway:signal:main:form', value: 'semaphore' }
```

Matching an array (speed limit) tag with `regex`. The match result is substituted into the icon. For array `regex` matches, the longest, and then the highest result is taken. For example a speed limit signal matches speed limits that have a valid icon, based on the `railway:signal:speed_limit:speed` or `railway:signal:speed_limit_distant:speed` tag. The speed tags have an array type. For example a signal with `railway:signal:speed_limit_distant:speed=60;80;off` would match the regular expression, and the resulting icon would be `at/geschwindigkeitsvoranzeiger-light-{80}`:
```yaml
features:
  - description: Geschwindigkeitsvoranzeiger (light)
    country: AT
    icon:
      - match: 'railway:signal:speed_limit_distant:speed'
        cases:
          - { regex: '^(1[0-4]|[2-9])0$', value: 'at/geschwindigkeitsvoranzeiger-light-{}', example: 'at/geschwindigkeitsvoranzeiger-light-{140}' }
        default: 'at/geschwindigkeitsvoranzeiger-empty-light'
    tags:
      - { tag: 'railway:signal:speed_limit_distant', value: 'AT-V2:geschwindigkeitsvoranzeiger' }
      - { tag: 'railway:signal:speed_limit_distant:form', value: 'light' }
```
Note that the icon files will also contain the `{` and `}` characters, the filename will be for example `at/geschwindigkeitsvoranzeiger-light-{80}.svg`.

Signal features can use multiple icons by specifying more than one item for `icon`:
```yaml
features:
  - description: 1ª categoria (1 light)
    country: IT
    icon:
      - match: 'railway:signal:main:shape'
        cases:
          - { exact: 'square', value: 'it/main-s-1v', description: 'quadro' }
        default: 'it/main-1v'
      - match: 'railway:signal:main:states'
        cases:
          - { any: [ '(Y)', 'Y' ], value: "it/1v-Y" }
          - { exact: 'G', value: "it/1v-G" }
        default: "it/1v-R"
      - match: 'railway:signal:main:substitute_signal'
        cases:
          - { all: ['IT:AVA', 'IT:AVV'], value: 'it/AVV-AVA', description: 'Avvio & Avanzamento' }
          - { exact: 'IT:AVA', value: 'it/AVA', description: 'Avanzamento' }
          - { exact: 'IT:AVV', value: 'it/AVV', description: 'Avvio' }
        position: 'bottom'
    tags:
      - { tag: 'railway:signal:main', value: 'IT:1V' }
      - { tag: 'railway:signal:main:form', value: 'light' }
```
In this example the shape, the states, and the substitute signal each define an (optional) icon to use. The icons are composed together, starting with the first one and layering every following icon on top. The (optional) `default` icon is used if the `match` cases do not match. 

The icons can have an `position` with a value of `center` (default), `bottom`, `top`, `left` or `right` to determine where the icon will be placed in relation to the previously placed icons. When an icon is placed below, above, left or right of the other icons, the icon is centered along the other axis.

For complex signals, an additional property `exampleIcon` can be specified to designate an icon used for the feature as a whole, for example in the JOSM preset or TagInfo.
```yaml
features:
  - description: Geschwindigkeitsvoranzeiger
    country: AT
    icon:
      - match: ...
      - match: ...
      - match: ...
    exampleIcon: 'at/geschwindigkeitsvoranzeiger-example'
    tags:
      - ...
      - ...
```

If the railway signal uses tags that are not in the list at the top of the file, ensure the tag is added there. For example:
```yaml
tags:
  # ...
  - { tag: 'railway:signal:combined:form', title: 'Combined form' }
  # ...
```
If the tag has a `yes`/`no` value, add `type: boolean`. If the tag has a semicolon (`;`) separated value, add `type: array`. If the value of the tag should be displayed formatted or with a unit, add `format: { template: ... }` where the value is a template like `%.2d Hz` or `%s V` to format the tag value into a string for display in the popup.

Next, ensure the icon exists in the [symbols directory](https://github.com/hiddewie/OpenRailwayMap-vector/tree/master/symbols). The icon must be an SVG file, minified and of the correct dimensions (most icons are between 10 and 24 pixels wide / high). Icons with an even number of pixels in the width and height give the best visual results.

The icon must not contain text. Using an SVG tool, convert the text to the shape of the text. In Inkscape, use the menu item *Path* > *Object to Path*.

The SVG of the icon must be compressed. For example using the `rsvg-convert` tool, execute the command:
```shell
rsvg-convert icon.svg --width 16 --keep-aspect-ratio --format svg > icon-compressed.svg
```

Open a pull request where you provide details about the new railway signals. Ensure the pull request contains references to documentation and places on the map where these signals exist.

## I want to visualize a new track gauge on the map

*To be documented...*

## I want to visualize a new loading gauge on the map

Edit the file [`features/loading_gauge.yaml`](https://github.com/hiddewie/OpenRailwayMap-vector/edit/master/features/loading_gauge.yaml).

The file contains a list of loading gauges, each with a value (the value of the `loading_gauge` tag), a legend and a color.

Add a new entry at a certain place in the list. The value is the `loading_gauge` tag value. The `legend` will be used as a description in the legend. For example:
```yaml
loading_gauges:
  - { value: 'TSI_GA', legend: 'GA', color: 'blue' }
    # ...
```

Open a pull request where you provide details about the new loading gauge. Ensure the pull request contains references to documentation and places on the map where the loading gauge exists.

## I want to visualize a new track class on the map

Edit the file [`features/track_class.yaml`](https://github.com/hiddewie/OpenRailwayMap-vector/edit/master/features/track_class.yaml).

The file contains a list of track classes, each with a value (the value of the `railway:track_class` tag) and a color.

Add a new entry at a certain place in the list. The value is the `railway:track_class` tag value. For example:
```yaml
track_classes:
  - { value: 'Z', color: 'blue' }
    # ...
```

Open a pull request where you provide details about the new track class. Ensure the pull request contains references to documentation and places on the map where the track class exists.

## I want to add an operator

Edit the file [`features/operators.yaml`](https://github.com/hiddewie/OpenRailwayMap-vector/edit/master/features/operators.yaml).

The file contains a list of operators. A single operator can have multiple names, for example when it operates across multiple countries.

An operator has a color associated with it, used to display the operator on the map. Colors can use the form `#2d00e3`, `rgb(45, 0, 227)` or `hsl(252, 100%, 44.5%)`. Use the [colorpicker.dev](https://colorpicker.dev/#2d00e3) tool to assist in conversion of color formats.

Add a new entry at a certain place in the list. The value is the `operator` tag value. For example:
```yaml
operators:
  - names:
      - 'GVB'
      - 'Gemeentelijk Vervoerbedrijf'
    color: '#0863b5'

  # ...
```

Open a pull request where you provide details about the new operator. Ensure the pull request contains references to documentation and places on the map where the operator exists.

## I want to improve the user interface

The HTML, Javascript and CSS of the user interface are located in the [proxy](https://github.com/hiddewie/OpenRailwayMap-vector/tree/master/proxy) directory.

Open a pull request where you provide details about the new train protection system. Make sure the pull request contains screenshots showing the user visible changes.

## I want to provide translations for a new language 

At this moment the user interface and legend are solely available in English. This might change in the future.
