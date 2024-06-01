FROM python:3-slim

RUN pip3 install \
    werkzeug \
    psycopg2-binary

COPY openrailwaymap_api openrailwaymap_api
COPY api.py api.py

CMD ["python3", "-m", "api"]
