import hashlib

from fastapi import Response
from fastapi.responses import RedirectResponse


class WikidataAPI:
    def __init__(self, http_client):
        self.http_client = http_client

    async def wikidata_image(self, *, id):
        file_name, error = await self.wikidata_image_file(id)
        if error:
            return Response(content=error, status_code=404, media_type='text/plain')
        return await self.wikimedia_commons_image(file_name=file_name)

    async def wikimedia_commons_image(self, *, file_name):
        sanitized_name = file_name.replace(' ', '_')
        name_hash = hashlib.md5(sanitized_name.encode()).hexdigest()

        thumbnail_url = f"https://upload.wikimedia.org/wikipedia/commons/thumb/{name_hash[0:1]}/{name_hash[0:2]}/{sanitized_name}/330px-{sanitized_name}"

        view_url = f"https://www.wikidata.org/wiki/{id}#/media/File:{sanitized_name}"
        attribution, license, license_url, image_description = await self.wikimedia_file_attribution(file_name)
        return {
            'file_name': sanitized_name,
            'description': image_description,
            'view_url': view_url,
            'thumbnail_url': thumbnail_url,
            'attribution': attribution,
            'license': license,
            'license_url': license_url,
        }

    async def wikidata_image_file(self, id):
        url = f"https://www.wikidata.org/w/rest.php/wikibase/v1/entities/items/{id}/statements"
        params = {
            'property': 'P18',
        }
        headers = {
            'accept': 'application/json',
        }
        response = await self.http_client.get(url, params=params, headers=headers)
        if not response:
            return None, 'No response from Wikidata API'

        if response.status_code != 200:
            return None, f"Response from Wikidata API had status {response.status_code}"

        data = response.json()
        if not data:
            return None, 'No response body from Wikidata API'

        if not data['P18'] \
            or not data['P18'][0]:
            return None, 'Image statements (P18) not found in Wikidata response'

        for statement in data['P18']:
            if not statement \
                or not statement['rank'] \
                or not statement['value'] \
                or not statement['value']['content']:
                return None, 'Invalid image statement (P18) in Wikidata response'

        # 'preferred' > 'normal' > 'deprecated' both as strings and as ranks
        best_statement = max(data['P18'], key=lambda statement: statement['rank'])

        return best_statement['value']['content'], None

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

        attribution = metadata['Attribution']['value'] if 'Attribution' in metadata and 'value' in metadata['Attribution'] else None
        license = metadata['LicenseShortName']['value'] if 'LicenseShortName' in metadata and 'value' in metadata['LicenseShortName'] else None
        license_url = metadata['LicenseUrl']['value'] if 'LicenseUrl' in metadata and 'value' in metadata['LicenseUrl'] else None
        image_description = metadata['ImageDescription']['value'] if 'ImageDescription' in metadata and 'value' in metadata['ImageDescription'] else None

        return attribution, license, license_url, image_description
