FROM postgis/postgis:16-3.4-alpine

RUN apk add --no-cache \
    libspatialite \
    python3 \
    py3-pip \
    py3-werkzeug \
    py3-psycopg2

RUN python3 -m pip install spatialite
#    werkzeug \
#    psycopg2
#    python3-werkzeug \
#    python3-psycopg2
RUN #apt update \
#    && apt install -y \
#        python3 \
#        python3-werkzeug \
#        python3-psycopg2

#RUN pip3 install \
#    werkzeug \
#    psycopg2-binary

WORKDIR /app
COPY openrailwaymap_api openrailwaymap_api
COPY api.py api.py

#USER postgres

CMD ["python3", "-m", "api"]
#CMD ["sh", "-c", "/docker-entrypoint.sh postgres && "]
