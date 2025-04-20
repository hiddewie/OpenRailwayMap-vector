import re

from yaml import CLoader as Loader
from yaml import load
from yattag import Doc, indent

all_signals = load(open('features/signals_railway_signals.yaml', 'r'), Loader=Loader)
train_protections = load(open('features/train_protection.yaml', 'r'), Loader=Loader)
loading_gauges = load(open('features/loading_gauge.yaml', 'r'), Loader=Loader)
poi = load(open('features/poi.yaml', 'r'), Loader=Loader)
stations = load(open('features/stations.yaml', 'r'), Loader=Loader)
railway_lines = load(open('features/railway_line.yaml', 'r'), Loader=Loader)
track_classes = load(open('features/track_class.yaml', 'r'), Loader=Loader)

doc, tag, text = Doc().tagtext()
doc.asis('<?xml version="1.0" encoding="UTF-8"?>')

signal_type_pattern = re.compile('^railway:signal:(?P<type>[^:]+)$')


def chunk_common_references():
  with tag('chunk',
           id='common_references',
           ):
    with tag('preset_link',
             preset_name='Description',
             ):
      pass
    with tag('preset_link',
             preset_name='Note',
             ):
      pass
    with tag('preset_link',
             preset_name='Media',
             ):
      pass


def chunk_train_protection():
  # TODO this does not work yet: needs unique tag keys
  # Also see https://wiki.openstreetmap.org/wiki/Proposal:Railway:train_protection
  with tag('chunk',
           id='train_protection',
           ):
    with tag('combo',
             text='Train protection',
             key='railway:train_protection',
             values_searchable='true',
             values_sort='false',
             ):
      for train_protection in train_protections['train_protections']:
        if train_protection['train_protection'] != 'other':
          with tag('list_entry',
                   value=train_protection['train_protection'],
                   short_description=train_protection['legend'],
                   ):
            pass

    with tag('combo',
             text='Train protection (under construction)',
             key='construction:railway:train_protection',
             values_searchable='true',
             values_sort='false',
             ):
      for train_protection in train_protections['train_protections']:
        if train_protection['train_protection'] != 'other':
          with tag('list_entry',
                   value=train_protection['train_protection'],
                   short_description=train_protection['legend'],
                   ):
            pass


def chunk_loading_gauge():
  with tag('chunk',
           id='loading_gauge',
           ):
    with tag('combo',
             text='Loading gauge',
             key='loading_gauge',
             values=','.join(loading_gauge['value'] for loading_gauge in loading_gauges['loading_gauges']),
             values_sort='false',
             values_searchable='true',
             use_last_as_default='true',
             ):
      pass


def chunk_track_class():
  with tag('chunk',
           id='track_class',
           ):
    with tag('combo',
             text='Track class',
             key='railway:track_class',
             values=','.join(track_class['value'] for track_class in track_classes['track_classes']),
             values_searchable='true',
             values_sort='false',
             use_last_as_default='true',
             ):
      pass


def preset_items_media():
  with(tag('item',
           type='node,way,relation',
           name='Media',
           preset_name_label='true',
           )):
    with tag('text',
             text='Wikipedia',
             key='wikipedia',
             ): pass

    with tag('text',
             text='Wikidata',
             key='wikidata',
             ): pass

    with tag('text',
             text='Wikimedia Commons',
             key='wikimedia_commons',
             ): pass

    with tag('text',
             text='Image',
             key='image',
             ): pass

    with tag('text',
             text='Mapillary',
             key='mapillary',
             ): pass


def preset_items_railway_lines():
  with(tag('group',
           name='Lines',
           )):

    for item in railway_lines['features']:
      type = item['type']
      description = item['description']
      for feature in [
        {'prefix': '', 'name': description},
        {'prefix': 'construction:', 'name': f'{description} (under construction)'},
        {'prefix': 'proposed:', 'name': f'{description} (proposed)'},
        {'prefix': 'abandoned:', 'name': f'{description} (abandoned)'},
        {'prefix': 'disused:', 'name': f'{description} (disused)'},
      ]:
        prefix = feature['prefix']

        with(tag('item',
                 type='way',
                 name=feature['name'],
                 preset_name_label='true',
                 )):
          with tag('link',
                   wiki=f'Tag:railway={type}',
                   ):
            pass

          with tag('space'):
            pass

          with tag('key',
                   key=f'{prefix}railway',
                   value=type,
                   ):
            pass

          with tag('combo',
                   text='Usage',
                   key=f'{prefix}usage',
                   values='main,branch,industrial,tourism,military,test,science,leisure',
                   use_last_as_default='true',
                   values_sort='false',
                   ):
            pass

          with tag('combo',
                   text='Service',
                   key=f'{prefix}service',
                   values='yard,spur,siding,crossover',
                   use_last_as_default='true',
                   values_sort='false',
                   ):
            pass

          with tag('text',
                   text='Name',
                   key=f'{prefix}name',
                   use_last_as_default='true',
                   ):
            pass

          with tag('text',
                   text='Reference',
                   key=f'ref',
                   use_last_as_default='true',
                   ):
            pass

          with tag('text',
                   text='Gauge',
                   key=f'{prefix}gauge',
                   use_last_as_default='true',
                   ):
            pass

          with tag('text',
                   text='Operator',
                   key='operator',
                   use_last_as_default='true',
                   ):
            pass

          with tag('text',
                   text='Reporting marks',
                   key='reporting_marks',
                   use_last_as_default='true',
                   ):
            pass

          with tag('check',
                   text='Highspeed',
                   key='highspeed',
                   ):
            pass

          with tag('reference',
                   ref='train_protection',
                   ):
            pass

          with tag('check',
                   text='Bridge',
                   key='bridge',
                   ):
            pass

          # TODO move to bridge/tunnel preset?
          with tag('text',
                   text='Bridge name',
                   key='bridge:name',
                   ):
            pass

          with tag('check',
                   text='Tunnel',
                   key='tunnel',
                   ):
            pass

          with tag('text',
                   text='Tunnel name',
                   key='tunnel:name',
                   ):
            pass

          with tag('text',
                   text='Layer',
                   key='layer',
                   ):
            pass

          with tag('text',
                   text='Max speed',
                   key='maxspeed',
                   ):
            pass

          with tag('text',
                   text='Max speed (forward)',
                   key='maxspeed:forward',
                   ):
            pass

          with tag('text',
                   text='Max speed (backward)',
                   key='maxspeed:backward',
                   ):
            pass

          with tag('combo',
                   text='Preferred direction',
                   key='railway:preferred_direction',
                   values='forward,backward',
                   values_sort='false',
                   ):
            pass

          with tag('multiselect',
                   text='Electrification',
                   key='electrified',
                   values='contact_line;rail;ground-level_power_supply;4th_rail;yes;no',
                   values_sort='false',
                   rows=6,
                   ):
            pass

          with tag('text',
                   text='Voltage (V)',
                   key='voltage',
                   ):
            pass

          with tag('text',
                   text='Frequency (Hz)',
                   key='frequency',
                   ):
            pass

          with tag('multiselect',
                   text='Electrification (under construction)',
                   key='construction:electrified',
                   values='contact_line;rail;ground-level_power_supply;4th_rail;yes;no',
                   values_sort='false',
                   rows=6,
                   ):
            pass

          with tag('text',
                   text='Voltage (construction) (V)',
                   key='construction:voltage',
                   ):
            pass

          with tag('text',
                   text='Frequency (construction) (Hz)',
                   key='construction:frequency',
                   ):
            pass

          with tag('text',
                   text='Track reference',
                   key='railway:track_ref',
                   ):
            pass

          with tag('reference',
                   ref='loading_gauge',
                   ):
            pass

          with tag('reference',
                   ref='track_class',
                   ):
            pass

          with tag('check',
                   text='Preserved',
                   key='railway:preserved',
                   ):
            pass

          with tag('combo',
                   text='Traffic mode',
                   key='railway:traffic_mode',
                   values='mixed,passenger,freight',
                   values_sort='false',
                   use_last_as_default='true',
                   ):
            pass

          with tag('combo',
                   text='Radio',
                   key='railway:radio',
                   values='gsm-r,analogue,trs',
                   values_sort='false',
                   use_last_as_default='true',
                   ):
            pass

          with tag('reference',
                   ref='common_references',
                   ):
            pass


def preset_items_signals_for_country(features):
  for feature in features:

    types = []
    for ftag in feature['tags']:
      matches = signal_type_pattern.match(ftag['tag'])
      if matches:
        types.append(matches.group('type'))

    with(tag('item',
             type='node',
             name=feature['description'],
             icon=f'symbols/{feature['icon']['default']}.svg',
             preset_name_label='true',
             )):

      if 'country' in feature:
        doc.attr(regions=feature['country'])

      with tag('link',
               wiki='Tag:railway=signal',
               ):
        pass

      with tag('space'):
        pass

      with tag('combo',
               text='Signal direction',
               key='railway:signal:direction',
               values='forward,backward,both',
               ):
        pass

      with tag('key',
               key='railway',
               value='signal',
               ):
        pass

      for ftag in feature['tags']:
        if 'value' in ftag:
          with tag('key',
                   key=ftag['tag'],
                   value=ftag['value'],
                   ): pass

      # TODO better support a combo or multiselect of valid values
      if 'match' in feature['icon']:
        with tag('text',
                 text=feature['icon']['match'],  # TODO generate proper label
                 key=feature['icon']['match'],
                 ): pass

      for ftag in feature['tags']:
        if 'values' in ftag:
          with tag('combo',
                   text=ftag['tag'],  # TODO generate proper label
                   key=ftag['tag'],
                   values=','.join(ftag['values']),
                   match='keyvalue!',
                   use_last_as_default='true',
                   ): pass

      with tag('optional'):
        with tag('combo',
                 text='Signal position',
                 key='railway:signal:position',
                 values='right,left,in_track,bridge,overhead,catenary_mast',
                 short_descriptions='Right,Left,In track,Bridge,Overhead,Catenary mast',
                 values_sort='false',
                 ):
          pass

        with tag('text',
                 text='Reference',
                 key='ref',
                 ):
          pass

        for type in types:
          with tag('text',
                   text='Caption' if len(types) == 1 else f'Caption ({type})',
                   key=f'railway:signal:{type}:caption',
                   ):
            pass

        for type in types:
          with tag('check',
                   text='Deactivated' if len(types) == 1 else f'Deactivated ({type})',
                   key=f'railway:signal:{type}:deactivated',
                   default='false',
                   ):
            pass

        with tag('reference',
                 ref='common_references',
                 ):
          pass


def preset_items_signals():
  all_signals_by_country = {}
  for feature in all_signals['features']:
    country = feature.get('country')
    if country not in all_signals_by_country:
      all_signals_by_country[country] = []
    all_signals_by_country[country].append(feature)

  with(tag('group',
           name='Signals',
           )):

    for country, features in all_signals_by_country.items():
      if country is None:
        preset_items_signals_for_country(features)
      else:
        with(tag('group',
                 name=country,
                 regions=country,
                 )):
          preset_items_signals_for_country(features)


def presets_xml():
  with tag('presets',
           author='Hidde Wieringa',
           version='1.0',
           shortdescription='OpenRailwayMap preset',
           description='Preset to tag railway infrastructure such as railway lines, signals and railway places of interest',
           ):
    chunk_common_references()
    chunk_train_protection()
    chunk_loading_gauge()
    chunk_track_class()

    with(tag('group',
             name='Railway',
             )):
      preset_items_media()
      preset_items_railway_lines()
      preset_items_signals()


if __name__ == "__main__":
  presets_xml()
  print(indent(doc.getvalue()))
