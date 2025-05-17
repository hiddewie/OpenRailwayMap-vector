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
  # ...
  - { train_protection: 'new', legend: 'Description about this new train protection system', color: '#abc123' }
  # ...
```

In the body of the file, add a new entry at a certain place in the list. The `rank` should match the ordering of the entries. The value of `train_protection` should match the value in the legend entries. For example:
```yaml
features:
  # ...

  - train_protection: new
    tags:
      - { tag: 'railway:new', value: 'yes' }

  # ...
```

Open a pull request where you provide details about the new train protection system. Ensure the pull request contains references to documentation and places on the map where the train protection system exists.

## I want to visualize a new railway signal

Railway signals are present on three layers. The features are defined in a YAML file [`features/signals_railway_signals.yaml`](https://github.com/hiddewie/OpenRailwayMap-vector/edit/master/features/signals_railway_signals.yaml).

The file contains a list of signal tags, a list of signal types and all known signal features.

In the body of the file, add a new entry for the new railway signal. The signals are grouped by country. Every signal has a description, a set of tags and an icon. The icon can optionally have a `match` clause to match tag values to render the feature differently based on the matched tag value.

For example, to match railway signals with tags `railway:signal:shunting=AT-V2:verschubhalttafel` and `railway:signal:shunting:form=sign` with icon `at/verschubhalttafel`:
```yaml
features:
  # ...
  
  - description: Verschubhalttafel
    country: AT
    icon: { default: 'at/verschubhalttafel' }
    tags:
      - { tag: 'railway:signal:shunting', value: 'AT-V2:verschubhalttafel' }
      - { tag: 'railway:signal:shunting:form', value: 'sign' }

  # ...
```

A more complicated example where the different forms of features with tags `railway:signal:main=AT-V2:hauptsignal` and `railway:signal:main:form=semaphore` are rendered with different icons, based on the value of the `railway:signal:main:states` tag. Each of the cases will be matched as a [regular expression](https://www.postgresql.org/docs/current/functions-matching.html#FUNCTIONS-POSIX-REGEXP) against the tag value. These variants of the icon will also be shown in the legend, described by the `description` of each of the cases: 
```yaml
features:
  # ...

  - description: Hauptsignal (semaphore)
    country: AT
    icon:
      match: 'railway:signal:main:states'
      cases:
        - regex: '^(.*;)?AT-V2:frei_mit_(4|2)0(;.*)?$'
          value: 'at/hp2-semaphore'
          description: '20/40 km/h'
        - regex: '^(.*;)?AT-V2:frei(;.*)?$'
          value: 'at/hp1-semaphore'
          description: 'clear'
      default: 'de/hp0-semaphore'
    tags:
      - { tag: 'railway:signal:main', value: 'AT-V2:hauptsignal' }
      - { tag: 'railway:signal:main:form', value: 'semaphore' }

  # ...
```

A final example for speed signals which display an icon depending on the matched speed value. The `value` property contains `{}` as part of the icon, which is replaced automatically with the matched tag value, for example `{80}`. In particular an `example` must be given, which is used in the legend:

```yaml
features:
  # ...

  - description: Geschwindigkeitsvoranzeiger (sign)
    country: AT
    icon:
      match: 'railway:signal:speed_limit_distant:speed:max'
      cases:
        - regex: '^(1[02]|[1-9])0$'
          value: 'at/geschwindigkeitsvoranzeiger-{}-sign'
          example: 'at/geschwindigkeitsvoranzeiger-{80}-sign'
      default: 'at/geschwindigkeitsvoranzeiger-empty-sign'
    tags:
      - { tag: 'railway:signal:speed_limit_distant', value: 'AT-V2:geschwindigkeitsvoranzeiger' }
      - { tag: 'railway:signal:speed_limit_distant:form', value: 'sign' }
  
  # ...
```
Note that the icon files will also contain the `{` and `}` characters, the filename will be for example `at/geschwindigkeitsvoranzeiger-{80}-sign.svg`.

If the railway signal uses tags that are not in the list at the top of the file, ensure the tag is added there. For example:
```yaml
tags:
  # ...
  - 'railway:signal:combined:form'
  # ...
```

Next, ensure the icon exists in the [symbols directory](https://github.com/hiddewie/OpenRailwayMap-vector/tree/master/symbols). The icon must be an SVG file, minified and of the correct dimensions (most icons are between 10 and 24 pixels wide / high).

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

## I want to improve the user interface

The HTML, Javascript and CSS of the user interface are located in the [proxy](https://github.com/hiddewie/OpenRailwayMap-vector/tree/master/proxy) directory.

Open a pull request where you provide details about the new train protection system. Make sure the pull request contains screenshots showing the user visible changes.

## I want to provide translations for a new language 

At this moment the user interface and legend are solely available in English. This might change in the future.
