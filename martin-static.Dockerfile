FROM ghcr.io/maplibre/martin:main

COPY martin /config
COPY symbols /symbols
COPY tiles /tiles

CMD ["/tiles", "--listen-addresses", "[::]:3000", "--sprite", "/symbols", "--font", "/config/fonts"]
