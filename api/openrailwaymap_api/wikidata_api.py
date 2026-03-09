from fastapi import Response
from fastapi.responses import RedirectResponse
import hashlib

class WikidataAPI:
    def __init__(self, http_client):
        self.http_client = http_client

    async def __call__(self, *, id):
        url = "https://www.wikidata.org/w/rest.php/wikibase/v1/entities/items/" + id + "/statements"
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
            or not data['P18'][0] \
            or not data['P18'][0]['value'] \
            or not data['P18'][0]['value']['content']:
            return Response(content='Image statements (P18) not found in Wikidata response', status_code=404, media_type='text/plain')

        name = data['P18'][0]['value']['content']
        sanitized_name = name.replace(' ', '_')
        name_hash = hashlib.md5(sanitized_name.encode()).hexdigest()

        resource_url = f"https://upload.wikimedia.org/wikipedia/commons/thumb/{name_hash[0:1]}/{name_hash[0:2]}/{sanitized_name}/330px-{sanitized_name}"
        return RedirectResponse(resource_url)
