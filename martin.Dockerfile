FROM ghcr.io/maplibre/martin:1.2.0@sha256:e53c0bb7e478617c603ee06f37f2e9ecee952d999d952a5173cad5dca281c442

COPY martin /config
COPY symbols /symbols

CMD ["--config", "/config/configuration.yml", "--sprite", "/symbols", "--font", "/config/fonts"]
