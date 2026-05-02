FROM ghcr.io/maplibre/martin:1.8.2@sha256:7137cad2facf21ef4af6cbef051ce0553b717e8289fde57b50b50c5ac93275b7

COPY martin /config
COPY symbols /symbols

CMD ["--config", "/config/configuration.yml", "--sprite", "/symbols"]
