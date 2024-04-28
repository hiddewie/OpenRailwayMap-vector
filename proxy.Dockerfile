FROM ghcr.io/hiddewie/template:v0.4.1 as build-ui

WORKDIR /build

RUN --mount=type=bind,source=proxy/js/ui.js,target=ui.js.tmpl \
  --mount=type=bind,source=features/train_protection.yaml,target=train_protection.yaml \
  --mount=type=bind,source=features/speed_railway_signals.yaml,target=speed_railway_signals.yaml \
  cat train_protection.yaml speed_railway_signals.yaml \
    | template --configuration - --format yaml --template ui.js.tmpl \
    > /build/ui.js

FROM nginx:1-alpine

COPY proxy/proxy.conf.template /etc/nginx/templates/proxy.conf.template
COPY proxy/index.html /etc/nginx/public/index.html
COPY proxy/js /etc/nginx/public/js
COPY proxy/css /etc/nginx/public/css
COPY proxy/image /etc/nginx/public/image

COPY --from=build-ui \
  /build/ui.js /etc/nginx/public/js/ui.js
