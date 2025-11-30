import contextlib
import os
from typing import Annotated

import asyncpg
from fastapi import FastAPI
from fastapi import Query

import httpx

from openrailwaymap_api.facility_api import FacilityAPI
from openrailwaymap_api.milestone_api import MilestoneAPI
from openrailwaymap_api.status_api import StatusAPI
from openrailwaymap_api.replication_api import ReplicationAPI
from openrailwaymap_api.wikidata_api import WikidataAPI


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

        async with httpx.AsyncClient(timeout=3.0) as http_client:
            print('Created HTTP client')
            app.state.http_client = http_client

            yield

            app.state.http_client = None

            print('Closed HTTP client')

        app.state.database = None

    print('Disconnected from database')


app = FastAPI(
    title="OpenRailwayMap API",
    lifespan=lifespan,
)

DEFAULT_FACILITY_LIMIT = 20
DEFAULT_MILESTONE_LIMIT = 2
MIN_LIMIT = 1
MAX_LIMIT = 200


@app.get("/api/status")
async def status():
    api = StatusAPI()
    return await api()


@app.get("/api/replication_timestamp")
async def replication_timestamp():
    api = ReplicationAPI(app.state.database)
    return await api()


@app.get("/api/facility")
async def facility(
        q: Annotated[str | None, Query()] = None,
        name: Annotated[str | None, Query()] = None,
        ref: Annotated[str | None, Query()] = None,
        uic_ref: Annotated[str | None, Query()] = None,
        lang: Annotated[str | None, Query()] = None,
        limit: Annotated[int, Query(ge=MIN_LIMIT, le=MAX_LIMIT)] = DEFAULT_FACILITY_LIMIT,
):
    api = FacilityAPI(app.state.database)
    return await api(q=q, name=name, ref=ref, uic_ref=uic_ref, limit=limit, language=lang)


@app.get("/api/milestone")
async def milestone(
        ref: Annotated[str, Query()],
        position: Annotated[float, Query()],
        limit: Annotated[int | None, Query(ge=MIN_LIMIT, le=MAX_LIMIT)] = DEFAULT_MILESTONE_LIMIT,
):
    api = MilestoneAPI(app.state.database)
    return await api(ref=ref, position=position, limit=limit)


@app.get("/api/wikidata/{id}")
async def wikidata(
        id: str
):
    api = WikidataAPI(app.state.http_client)
    return await api(id=id)
