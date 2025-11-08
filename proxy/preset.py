import re
from os import environ

from yaml import CLoader as Loader
from yaml import load
from yattag import Doc, indent

all_signals = load(open('features/signals_railway_signals.yaml', 'r'), Loader=Loader)
train_protections = load(open('features/train_protection.yaml', 'r'), Loader=Loader)
loading_gauges = load(open('features/loading_gauge.yaml', 'r'), Loader=Loader)
pois = load(open('features/poi.yaml', 'r'), Loader=Loader)
stations = load(open('features/stations.yaml', 'r'), Loader=Loader)
railway_lines = load(open('features/railway_line.yaml', 'r'), Loader=Loader)
track_classes = load(open('features/track_class.yaml', 'r'), Loader=Loader)

doc, tag, text = Doc().tagtext()
doc.asis('<?xml version="1.0" encoding="UTF-8"?>')

signal_type_pattern = re.compile('^railway:signal:(?P<type>[^:]+)$')

tag_types = {}
tag_descriptions = {}
for t in all_signals['tags']:
  if 'type' in t:
    tag_types[t['tag']] = t['type']
  tag_descriptions[t['tag']] = t['title']


def all_states(description):
  return [
    {'prefix': '', 'name': description},
    {'prefix': 'construction:', 'name': f'{description} (under construction)'},
    {'prefix': 'proposed:', 'name': f'{description} (proposed)'},
    {'prefix': 'abandoned:', 'name': f'{description} (abandoned)'},
    {'prefix': 'disused:', 'name': f'{description} (disused)'},
  ]


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
      for feature in all_states(item['description']):
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
             icon=f'symbols/{feature['exampleIcon'] if 'exampleIcon' in feature else feature['icon'][0]['default']}.svg',
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

      if not any(ftag['tag'] == 'railway' for ftag in feature['tags']):
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

        elif 'all' in ftag:
          with tag('key',
                   key=ftag['tag'],
                   value=';'.join(ftag['all']),
                   ): pass

        elif ('any' not in ftag) and (ftag['tag'] in tag_types) and tag_types[ftag['tag']] == 'boolean':
          with tag('key',
                   key=ftag['tag'],
                   value='yes',
                   ): pass

      # TODO better support a combo or multiselect of valid values

      icon_tags = set()
      for icon in feature['icon']:
        if 'match' in icon:
          match = icon['match']
          if match in icon_tags:
            continue
          icon_tags.add(match)

          text = (tag_descriptions[match] if match in tag_descriptions else match)

          if ftag['tag'] in tag_types and tag_types[ftag['tag']] == 'boolean':
            with tag('check',
                     text=text,
                     key=match,
                     ): pass
          else:
            with tag('text',
                     text=text,
                     key=match,
                     ): pass


      for ftag in feature['tags']:
        if 'any' in ftag:
          with tag('multiselect',
                   text=tag_descriptions[ftag['tag']],
                   key=ftag['tag'],
                   values=';'.join(ftag['any']),
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


def preset_items_poi(poi):
  with(tag('item',
           type='node,way',
           name=poi['description'],
           icon=f'symbols/{poi['feature']}.svg',
           preset_name_label='true',
           )):
    for ftag in poi['tags']:
      if 'value' in ftag:
        with tag('link',
                 wiki=f'Tag:{ftag['tag']}={ftag['value']}',
                 ):
          pass

    with tag('space'):
      pass

    for ftag in poi['tags']:
      if 'value' in ftag:
        with tag('key',
                 key=ftag['tag'],
                 value=ftag['value'],
                 ): pass

    for ftag in poi['tags']:
      if 'values' in ftag:
        with tag('combo',
                 text=ftag['tag'],  # TODO generate proper label
                 key=ftag['tag'],
                 values=','.join(ftag['values']),
                 match='keyvalue!',
                 ): pass

    with tag('optional'):
      with tag('text',
               text='Reference',
               key='ref',
               ):
        pass

      with tag('reference',
               ref='common_references',
               ):
        pass


def preset_items_pois():
  for poi in pois['features']:
    preset_items_poi(poi)
    if 'variants' in poi:
      for variant in poi['variants']:
        preset_items_poi(variant)


def preset_items_turntables():
  preset_items_poi({
    'description': 'Turntable',
    'feature': 'general/turntable',
    'tags': [
      {'tag': 'railway', 'value': 'turntable'},
    ],
  })

  preset_items_poi({
    'description': 'Traverser',
    'feature': 'general/traverser',
    'tags': [
      {'tag': 'railway', 'value': 'traverser'},
    ],
  })


def preset_items_stations():
  for item in stations['features']:
    for feature in all_states(item['description']):
      prefix = feature['prefix']
      with(tag('item',
               type='node',
               name=feature['name'],
               icon=f'symbols/general/{item['feature']}.svg',
               preset_name_label='true',
               )):
        with tag('link',
                 wiki=f'Tag:{prefix}railway={item['feature']}',
                 ):
          pass

        with tag('key',
                 key=f'{prefix}railway',
                 value=item['feature'],
                 ):
          pass

        with tag('space'):
          pass

        with tag('text',
                 text='Name',
                 key='name',
                 ):
          pass

        with tag('text',
                 text='Short name',
                 key='short_name',
                 ):
          pass

        with tag('text',
                 text='Railway reference',
                 key='railway:ref',
                 ):
          pass

        if item['feature'] in ['station', 'halt']:
          with tag('multiselect',
                   text='Station type',
                   key=f'{prefix}station',
                   values='train;subway;light_rail;monorail;funicular;tram;miniature;bus',
                   values_sort='false',
                   rows=8,
                   ):
            pass

        with tag('optional'):
          with tag('text',
                   text='Reference',
                   key='ref',
                   ):
            pass

          with tag('text',
                   text='UIC reference',
                   key='uic_ref',
                   ):
            pass

          with tag('text',
                   text='UIC name',
                   key='uic_name',
                   ):
            pass

          with tag('text',
                   text='Operator',
                   key='operator',
                   ):
            pass

          with tag('text',
                   text='Network',
                   key='network',
                   ):
            pass

          with tag('reference',
                   ref='common_references',
                   ):
            pass


def preset_items_signal_boxes():
  for feature in [
    {'feature': 'signal_box', 'description': 'Signal box'},
    {'feature': 'crossing_box', 'description': 'Crossing box'},
    {'feature': 'blockpost', 'description': 'Block post'},
  ]:
    with(tag('item',
             type='node,way',
             name=feature['description'],
             # TODO icon
             # icon=f'symbols/general/{feature['feature[}.svg',
             preset_name_label='true',
             )):
      with tag('link',
               wiki=f'Tag:railway={feature['feature']}',
               ):
        pass
      with tag('key',
               key=f'railway',
               value=feature['feature'],
               ):
        pass

      with tag('key',
               key=f'building',
               value='yes',
               ):
        pass

      with tag('space'):
        pass

      if feature['feature'] == 'signal_box':
        with tag('combo',
                 text='Type',
                 key='railway:signal_box',
                 values='mechanical,electric,track_diagram,electronic,yes',
                 values_searchable='true',
                 values_sort='false',
                 ):
          pass

      with tag('text',
               text='Name',
               key='name',
               ):
        pass

      with tag('text',
               text='Railway reference',
               key='railway:ref',
               ):
        pass

      with tag('optional'):
        with tag('text',
                 text='Position',
                 key='railway:position',
                 ):
          pass

        with tag('text',
                 text='Exact position',
                 key='railway:position:exact',
                 ):
          pass

        with tag('text',
                 text='Operating times',
                 key='operating_times',
                 ):
          pass

        with tag('check',
                 text='Operated locally',
                 key='railway:local_operated',
                 ):
          pass

        with tag('text',
                 text='Date of opening',
                 key='start_date',
                 ):
          pass

        with tag('text',
                 text='Date of closing',
                 key='end_date',
                 ):
          pass

        with tag('reference',
                 ref='common_references',
                 ):
          pass


def preset_items_switches():
  with(tag('item',
           type='node',
           name='Switch',
           icon=f'symbols/general/switch-default.svg',
           preset_name_label='true',
           )):
    with tag('link',
             wiki=f'Tag:railway=switch',
             ):
      pass
    with tag('key',
             key=f'railway',
             value='switch',
             ):
      pass

    with tag('space'):
      pass

    with tag('text',
             text='Reference',
             key='ref',
             ):
      pass

    with tag('combo',
             text='Type',
             key='railway:switch',
             values='default,three_way,four_way,single_slip,double_slip,wye,abt',
             values_searchable='true',
             values_sort='false',
             ):
      pass

    with tag('optional'):
      with tag('combo',
               text='Turnout direction',
               key='railway:turnout_side',
               values='left,right',
               values_sort='false',
               ):
        pass

      with tag('check',
               text='Heated',
               key='railway:switch:heated',
               ):
        pass

      with tag('check',
               text='Operated locally',
               key='railway:local_operated',
               ):
        pass

      with tag('check',
               text='Resetting switch',
               key='railway:switch:resetting',
               ):
        pass

      with tag('check',
               text='Electric',
               key='railway:switch:electric',
               ):
        pass

      with tag('check',
               text='Movable frog',
               key='railway:switch:movable_frog',
               ):
        pass

      with tag('text',
               text='Max speed (straight)',
               key='railway:maxspeed:straight',
               ):
        pass

      with tag('text',
               text='Max speed (diverging)',
               key='railway:maxspeed:diverging',
               ):
        pass

      with tag('reference',
               ref='common_references',
               ):
        pass


def preset_items_milestones():
  with(tag('item',
           type='node',
           name='Milestone',
           # TODO icon
           # icon=f'symbols/general/milestone.svg',
           preset_name_label='true',
           )):
    with tag('link',
             wiki=f'Tag:railway=milestone',
             ):
      pass
    with tag('key',
             key=f'railway',
             value='milestone',
             ):
      pass

    with tag('space'):
      pass

    with tag('text',
             text='Position',
             key='railway:position',
             ):
      pass

    with tag('text',
             text='Exact position',
             key='railway:position:exact',
             ):
      pass

    with tag('check',
             text='On catenary mast',
             key='railway:milestone:catenary_mast',
             ):
      pass

    with tag('reference',
             ref='common_references',
             ):
      pass


def presets_xml():
  with tag('presets',
           author='Hidde Wieringa',
           version=environ.get('PRESET_VERSION', '1.0'),
           shortdescription='Railways',
           description='OpenRailwayMap preset to tag railway infrastructure such as railway lines, stations, signals, switches and railway places of interest',
           icon='symbols/general/station.svg',
           link='https://github.com/hiddewie/OpenRailwayMap-vector',
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
      preset_items_pois()
      preset_items_turntables()
      preset_items_stations()
      preset_items_signal_boxes()
      preset_items_switches()
      preset_items_milestones()


if __name__ == "__main__":
  presets_xml()
  print(indent(doc.getvalue()))
