FROM ghcr.io/maplibre/martin:main

COPY martin /config
COPY symbols /symbols

HEALTHCHECK CMD wget --spider localhost:3000/catalog

CMD ["--config", "/config/configuration.yml", "--sprite", "/symbols", "--font", "/config/fonts"]
