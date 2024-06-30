# SPDX-License-Identifier: GPL-2.0-or-later
from openrailwaymap_api.abstract_api import AbstractAPI

class StatusAPI(AbstractAPI):
    def __init__(self, db_conn):
        self.data = []
        self.status_code = 200

    def __call__(self, args):
        return self.build_response()
