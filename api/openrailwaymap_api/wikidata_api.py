import hashlib

from fastapi import Response
from fastapi.responses import RedirectResponse
from urllib.parse import quote


class WikidataAPI:
    def __init__(self, http_client):
        self.http_client = http_client

    async def wikidata_image(self, *, id):
        file_name, error = await self.wikidata_image_file(id)
        if error:
            return Response(content=error, status_code=404, media_type='text/plain')
        return await self.wikimedia_commons_image(file_name=file_name, base_view_url=f'https://www.wikidata.org/wiki/{id}')

    async def wikimedia_commons_file(self, *, file_name):
        return await self.wikimedia_commons_image(file_name=file_name, base_view_url=f'https://commons.wikimedia.org/wiki/File:{quote(file_name)}')

    async def wikimedia_commons_image(self, *, file_name, base_view_url):
        sanitized_name = file_name.replace(' ', '_')
        name_hash = hashlib.md5(sanitized_name.encode()).hexdigest()

        thumbnail_url = f"https://upload.wikimedia.org/wikipedia/commons/thumb/{name_hash[0:1]}/{name_hash[0:2]}/{sanitized_name}/330px-{sanitized_name}"

        view_url = f"{base_view_url}#/media/File:{sanitized_name}"
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

        image_statements = self.dig(data, ['P18', 0])
        if not image_statements:
            return None, 'Image statements (P18) not found in Wikidata response'

        for statement in data['P18']:
            statement_rank = self.dig(statement, ['rank'])
            statement_content = self.dig(statement, ['value', 'content'])

            if not statement_rank or not statement_content:
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
            return None, None, None, None
        if response.status_code != 200:
            return None, None, None, None

        data = response.json()

        metadata = self.dig(data, ['query', 'pages', '-1', 'imageinfo', 0, 'extmetadata'])
        if not metadata:
            return None, None, None, None

        return \
            self.dig(metadata, ['Attribution', 'value']), \
                self.dig(metadata, ['LicenseShortName', 'value']), \
                self.dig(metadata, ['LicenseUrl', 'value']), \
                self.dig(metadata, ['ImageDescription', 'value'])

    def dig(self, item, path):
        if not item:
            return None
        if len(path) == 0:
            return item
        if type(item) == dict:
            if path[0] in item:
                return self.dig(item[path[0]], path[1:])
            else:
                return None
        if type(item) == list and type(path[0]) == int:
            if len(item) > path[0]:
                return self.dig(item[path[0]], path[1:])
            else:
                return None
        else:
            return None
