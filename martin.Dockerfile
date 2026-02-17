FROM ghcr.io/maplibre/martin:main@sha256:5668210f16293b1769f72671ea5aed9dee16cf7bfdb039798f7cd88415704749

COPY martin /config
COPY symbols /symbols

CMD ["--config", "/config/configuration.yml", "--sprite", "/symbols", "--font", "/config/fonts"]
