from fastapi import Response
from fastapi.responses import RedirectResponse
import hashlib

class WikidataAPI:
    def __init__(self, http_client):
        self.http_client = http_client

    async def __call__(self, *, id):
        url = f"https://www.wikidata.org/w/rest.php/wikibase/v1/entities/items/{id}/statements"
        params = {
          'property': 'P18',
        }
        headers = {
          'accept': 'application/json',
        }
        response = await self.http_client.get(url, params=params, headers=headers)
        if not response:
            return Response(content='No response from Wikidata API', status_code=404, media_type='text/plain')
        if response.status_code != 200:
            return Response(content=f"Response from Wikidata API had status {response.status_code}", status_code=404, media_type='text/plain')

        data = response.json()
        if not data:
            return Response(content='No response body from Wikidata API', status_code=404, media_type='text/plain')

        if not data['P18'] \
            or not data['P18'][0]:
            return Response(content='Image statements (P18) not found in Wikidata response', status_code=404, media_type='text/plain')

        for statement in data['P18']:
            if not statement \
                or not statement['rank'] \
                or not statement['value'] \
                or not statement['value']['content']:
                return Response(content='Invalid image statement (P18) in Wikidata response', status_code=404, media_type='text/plain')

        # 'preferred' > 'normal' > 'deprecated' both as strings and as ranks
        best_statement = max(data['P18'], key=lambda statement: statement['rank'])

        file_name = best_statement['value']['content']
        sanitized_name = file_name.replace(' ', '_')
        name_hash = hashlib.md5(sanitized_name.encode()).hexdigest()

        thumbnail_url = f"https://upload.wikimedia.org/wikipedia/commons/thumb/{name_hash[0:1]}/{name_hash[0:2]}/{sanitized_name}/330px-{sanitized_name}"
        view_url = f"https://www.wikidata.org/wiki/{id}#/media/File:{sanitized_name}"
        file_attribution = await self.wikimedia_file_attribution(file_name)
        return {
            'file_name': sanitized_name,
            'view_url': view_url,
            'thumbnail_url': thumbnail_url,
            'file_attribution': file_attribution,
        }

    async def wikimedia_file_attribution(self, file_name):
        url = "https://www.wikidata.org/w/api.php"
        params = {
            'action': 'query',
            'prop': 'imageinfo',
            'iiprop': 'extmetadata',
            'titles': f'File:{file_name}',
            'format': 'json',
        }

        response = await self.http_client.get(url, params=params)
        if not response:
            return None
        if response.status_code != 200:
            return None

        data = response.json()
        if not data:
            return None

        if not data['query'] \
            or not data['query']['pages'] \
            or not data['query']['pages']['-1'] \
            or not data['query']['pages']['-1']['imageinfo'] \
            or len(data['query']['pages']['-1']['imageinfo']) == 0 \
            or not data['query']['pages']['-1']['imageinfo'][0]['extmetadata']:
            return None

        metadata = data['query']['pages']['-1']['imageinfo'][0]['extmetadata']

        attribution = metadata['Attribution'] and metadata['Attribution']['value'] or None
        license = metadata['LicenseShortName'] and metadata['LicenseShortName']['value'] or None
        license_url = metadata['LicenseUrl'] and metadata['LicenseUrl']['value'] or None

        return {
            'attribution': attribution,
            'license': license,
            'license_url': license_url,
        }
