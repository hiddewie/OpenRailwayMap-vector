# SPDX-License-Identifier: GPL-2.0-or-later
from openrailwaymap_api.abstract_api import AbstractAPI


class StatusAPI(AbstractAPI):
    async def __call__(self, args):
        return 'OK'
