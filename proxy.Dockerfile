FROM node:24-alpine@sha256:a34ab6d7f6f4813f4d0c5469d74685604b962fbdbf5793a7bc7b4998ecb867c8 AS build-yaml

WORKDIR /build

RUN npm install yaml@2.8.1

FROM build-yaml AS build-styles

RUN --mount=type=bind,source=proxy/js/styles.mjs,target=styles.mjs \
  --mount=type=bind,source=features,target=features \
  node /build/styles.mjs \
    > /build/style.json

FROM build-yaml AS build-legend

RUN --mount=type=bind,source=proxy/js/legend.mjs,target=legend.mjs \
  --mount=type=bind,source=features,target=features \
  node /build/legend.mjs \
    > /build/legend.json

FROM build-yaml AS build-taginfo

RUN npm install chroma-js@3.1.2

RUN --mount=type=bind,source=proxy,target=proxy \
  --mount=type=bind,source=features,target=features \
  node proxy/js/taginfo.mjs \
    > /build/taginfo.json

FROM python:3-alpine@sha256:dd4d2bd5b53d9b25a51da13addf2be586beebd5387e289e798e4083d94ca837a AS build-preset

RUN apk add --no-cache zip

RUN pip install --no-cache-dir \
  pyyaml \
  yattag

WORKDIR /build

ARG PRESET_VERSION
RUN --mount=type=bind,source=proxy/preset.py,target=preset.py \
  --mount=type=bind,source=features,target=features \
  python preset.py \
    > preset.xml

RUN --mount=type=bind,source=symbols,target=symbols \
  zip -o /build/preset.zip -r -q \
    symbols \
    preset.xml

FROM nginx:1-alpine@sha256:713fc2ebfd92e8217db451477182ee91944b123d2b1ee9fd5a8c6e91ca6c3a11

COPY proxy/script/with-news-hash.sh /with-news-hash.sh
COPY proxy/proxy.conf.template /etc/nginx/templates/proxy.conf.template
COPY proxy/manifest.json /etc/nginx/public/manifest.json
COPY proxy/index.html /etc/nginx/public/index.html
COPY proxy/news.html /etc/nginx/public/news.html
COPY proxy/api /etc/nginx/public/api
COPY proxy/js /etc/nginx/public/js
COPY proxy/css /etc/nginx/public/css
COPY proxy/image /etc/nginx/public/image
COPY proxy/font /etc/nginx/public/font
COPY proxy/ssl /etc/nginx/ssl

COPY --from=build-styles \
  /build/style.json /etc/nginx/public/style.json

COPY --from=build-legend \
  /build/legend.json /etc/nginx/public/legend.json

COPY --from=build-taginfo \
  /build/taginfo.json /etc/nginx/public/taginfo.json

COPY --from=build-preset \
  /build/preset.zip /etc/nginx/public/preset.zip

ENTRYPOINT ["/with-news-hash.sh"]
CMD ["nginx", "-g", "daemon off;"]
