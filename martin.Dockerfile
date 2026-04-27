FROM ghcr.io/maplibre/martin:latest@sha256:077329dbde8d791f030b9eab63f4681772480be2f6ceebab0108cb79cebb4aa3

COPY martin /config
COPY symbols /symbols

CMD ["--config", "/config/configuration.yml", "--sprite", "/symbols", "--font", "/config/fonts"]
