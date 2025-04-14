FROM node:22-alpine AS build-yaml

WORKDIR /build

RUN npm install yaml

FROM build-yaml AS build-styles

ARG PUBLIC_PROTOCOL
ARG PUBLIC_HOST

RUN --mount=type=bind,source=proxy/js/styles.mjs,target=styles.mjs \
  --mount=type=bind,source=features,target=features \
  node /build/styles.mjs

FROM build-yaml AS build-features

RUN --mount=type=bind,source=proxy/js/features.mjs,target=features.mjs \
  --mount=type=bind,source=features,target=features \
  node /build/features.mjs \
    > /build/features.json

FROM nginx:1-alpine

COPY proxy/proxy.conf.template /etc/nginx/templates/proxy.conf.template
COPY proxy/manifest.json /etc/nginx/public/manifest.json
COPY proxy/index.html /etc/nginx/public/index.html
COPY proxy/news.html /etc/nginx/public/news.html
COPY proxy/api /etc/nginx/public/api
COPY proxy/js /etc/nginx/public/js
COPY proxy/css /etc/nginx/public/css
COPY proxy/image /etc/nginx/public/image
COPY data/import /etc/nginx/public/import

COPY --from=build-styles \
  /build /etc/nginx/public/style

COPY --from=build-features \
  /build/features.json /etc/nginx/public/features.json
