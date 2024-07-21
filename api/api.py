#! /usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
import contextlib
import os

import asyncpg
from fastapi import FastAPI


# import psycopg2
# import psycopg2.extras
# import json
# import sys
# import os
# from werkzeug.exceptions import HTTPException, NotFound, InternalServerError
# from werkzeug.routing import Map, Rule
# from werkzeug.wrappers import Request, Response
# from openrailwaymap_api.facility_api import FacilityAPI
# from openrailwaymap_api.milestone_api import MilestoneAPI
# from openrailwaymap_api.status_api import StatusAPI


@contextlib.asynccontextmanager
async def lifespan(app):
    async with asyncpg.create_pool(
            user=os.environ['POSTGRES_USER'],
            host=os.environ['POSTGRES_HOST'],
            database=os.environ['POSTGRES_DB'],
            command_timeout=10,
            min_size=1,
            max_size=20,
    ) as pool:
        print('Connected to database')
        app.state.database = pool

        async with pool.acquire() as connection:
            result = await connection.fetchval("SELECT COUNT(*) FROM openrailwaymap_milestones")
            print(f'{result} milestones')

        yield

        app.state.database = None

    print('Disconnected from database')


app = FastAPI(
    title="OpenRailwayMap API",
    lifespan=lifespan,
)


@app.get("/api/status")
async def root():
    return 'OK'

#
# def connect_db():
#     conn = psycopg2.connect(dbname=os.environ['POSTGRES_DB'], user=os.environ['POSTGRES_USER'], host=os.environ['POSTGRES_HOST'])
#     return conn
#
# class OpenRailwayMapAPI:
#
#     db_conn = connect_db()
#
#     def __init__(self):
#         self.url_map = Map([
#             Rule('/api/facility', endpoint=FacilityAPI, methods=('GET',)),
#             Rule('/api/milestone', endpoint=MilestoneAPI, methods=('GET',)),
#             Rule('/api/status', endpoint=StatusAPI, methods=('GET',)),
#         ])
#
#     def ensure_db_connection_alive(self):
#         if self.db_conn.closed != 0:
#             self.db_conn = connect_db()
#
#     def dispatch_request(self, environ, start_response):
#         request = Request(environ)
#         urls = self.url_map.bind_to_environ(environ)
#         response = None
#         try:
#             endpoint, args = urls.match()
#             self.ensure_db_connection_alive()
#             response = endpoint(self.db_conn)(request.args)
#         except HTTPException as e:
#             return e
#         except Exception as e:
#             print('Error during request:', e, file=sys.stderr)
#             return InternalServerError()
#         finally:
#             if not response:
#                 self.db_conn.close()
#                 self.db_conn = connect_db()
#         return response
#
#     def wsgi_app(self, environ, start_response):
#         request = Request(environ)
#         response = self.dispatch_request(request)
#         return response(environ, start_response)
#
#
# def application(environ, start_response):
#     openrailwaymap_api = OpenRailwayMapAPI()
#     response = openrailwaymap_api.dispatch_request(environ, start_response)
#     return response(environ, start_response)
#
#
# if __name__ == '__main__':
#     openrailwaymap_api = OpenRailwayMapAPI()
#     from werkzeug.serving import run_simple
#     run_simple('::', int(os.environ['PORT']), application, use_debugger=True, use_reloader=True)
