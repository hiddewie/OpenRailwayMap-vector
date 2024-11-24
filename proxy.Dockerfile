FROM node:22-alpine as build-styles

ARG PUBLIC_PROTOCOL
ARG PUBLIC_HOST

WORKDIR /build

RUN npm install yaml

RUN --mount=type=bind,source=proxy/js/styles.mjs,target=styles.mjs \
  --mount=type=bind,source=features/train_protection.yaml,target=train_protection.yaml \
  --mount=type=bind,source=features/speed_railway_signals.yaml,target=speed_railway_signals.yaml \
  --mount=type=bind,source=features/electrification_signals.yaml,target=electrification_signals.yaml \
  --mount=type=bind,source=features/signals_railway_signals.yaml,target=signals_railway_signals.yaml \
  --mount=type=bind,source=features/loading_gauge.yaml,target=loading_gauge.yaml \
  --mount=type=bind,source=features/track_class.yaml,target=track_class.yaml \
  node /build/styles.mjs

FROM node:22-alpine as build-features

WORKDIR /build

RUN npm install yaml

RUN --mount=type=bind,source=proxy/js/features.mjs,target=features.mjs \
  --mount=type=bind,source=features/train_protection.yaml,target=train_protection.yaml \
  --mount=type=bind,source=features/speed_railway_signals.yaml,target=speed_railway_signals.yaml \
  --mount=type=bind,source=features/electrification_signals.yaml,target=electrification_signals.yaml \
  --mount=type=bind,source=features/signals_railway_signals.yaml,target=signals_railway_signals.yaml \
  --mount=type=bind,source=features/loading_gauge.yaml,target=loading_gauge.yaml \
  node /build/features.mjs \
    > /build/features.json

FROM nginx:1-alpine

COPY proxy/proxy.conf.template /etc/nginx/templates/proxy.conf.template
COPY proxy/manifest.json /etc/nginx/public/manifest.json
COPY proxy/index.html /etc/nginx/public/index.html
COPY proxy/api /etc/nginx/public/api
COPY proxy/js /etc/nginx/public/js
COPY proxy/css /etc/nginx/public/css
COPY proxy/image /etc/nginx/public/image
COPY data/import /etc/nginx/public/import

COPY --from=build-styles \
  /build /etc/nginx/public/style

COPY --from=build-features \
  /build/features.json /etc/nginx/public/features.json
