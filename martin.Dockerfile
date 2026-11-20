FROM ghcr.io/maplibre/martin:1.16.1@sha256:59902019bf9038926ff0c71174237d6852e64c457830a6349abe7090be8818ca

COPY martin /config
COPY symbols /symbols

CMD ["--config", "/config/configuration.yml", "--sprite", "/symbols"]
