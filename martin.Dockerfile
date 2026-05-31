FROM ghcr.io/maplibre/martin:1.10.1@sha256:808afb520272ebf37ea582b0191bd7a2d87c3cf89a552000883bfbdbced9688c

COPY martin /config
COPY symbols /symbols

CMD ["--config", "/config/configuration.yml", "--sprite", "/symbols"]
