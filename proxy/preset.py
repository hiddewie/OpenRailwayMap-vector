from yaml import CLoader as Loader
from yaml import load
from yattag import Doc, indent

all_signals = load(open('features/signals_railway_signals.yaml', 'r'), Loader=Loader)

doc, tag, text = Doc().tagtext()
doc.asis('<?xml version="1.0" encoding="UTF-8"?>')

with tag('presets',
         author='Hidde Wieringa',
         version='1.0',
         shortdescription='OpenRailwayMap preset',
         description='Preset to tag railway infrastructure such as railway lines, signals and railway places of interest',
         ):
  with(tag('group',
           name='Railway signals')):

    for feature in all_signals['features']:
      with(tag('item',
               type='node',
               name=f'{'country' in feature and f'{feature['country']}: ' or ''}{feature['description']}',  # TODO group by country?
               icon=f'symbols/{feature['icon']['default']}.svg',
               preset_name_label='true',
               )):

        if 'country' in feature:
          doc.attr(regions=feature['country'])

        with tag('link', wiki='Tag:railway=signal'):
          pass
        with tag('space'):
          pass

        for ftag in feature['tags']:
          if 'value' in ftag:
            with tag('key',
                     key=ftag['tag'],
                     value=ftag['value']): pass

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
                     use_last_as_default='true'): pass

        with tag('optional'):
          pass

if __name__ == "__main__":
  print(indent(doc.getvalue()))
