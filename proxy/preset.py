import re

from yaml import CLoader as Loader
from yaml import load
from yattag import Doc, indent

all_signals = load(open('features/signals_railway_signals.yaml', 'r'), Loader=Loader)

doc, tag, text = Doc().tagtext()
doc.asis('<?xml version="1.0" encoding="UTF-8"?>')

signal_type_pattern = re.compile('^railway:signal:(?P<type>[^:]+)$')


def common_tags():
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

  with tag('text',
           text='Note',
           key='note',
           ): pass

  with tag('text',
           text='Description',
           key='description',
           ): pass


def signals():
  with(tag('group',
           name='Railway signals',
           )):

    for feature in all_signals['features']:

      types = []
      for ftag in feature['tags']:
        matches = signal_type_pattern.match(ftag['tag'])
        if matches:
          types.append(matches.group('type'))

      with(tag('item',
               type='node',
               name=f'{'country' in feature and f'{feature['country']}: ' or ''}{feature['description']}',  # TODO group by country?
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
          pass

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

        # TODO make link to other presets instead
        with tag('reference',
                 ref='common_tags',
                 ):
          pass


def presets_xml():
  with tag('presets',
           author='Hidde Wieringa',
           version='1.0',
           shortdescription='OpenRailwayMap preset',
           description='Preset to tag railway infrastructure such as railway lines, signals and railway places of interest',
           ):
    with tag('chunk',
             id='common_tags',
             ):
      common_tags()

    signals()


if __name__ == "__main__":
  presets_xml()
  print(indent(doc.getvalue()))
