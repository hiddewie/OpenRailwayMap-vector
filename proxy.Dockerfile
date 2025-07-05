FROM nginx:1-alpine
COPY proxy/proxy.conf.template /etc/nginx/templates/proxy.conf.template
<<<<<<< Updated upstream
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

COPY --from=build-preset \
  /build/preset.zip /etc/nginx/public/preset.zip

COPY --from=build-features \
  /build/features.json /etc/nginx/public/features.json

ENTRYPOINT ["/with-news-hash.sh"]
CMD ["nginx", "-g", "daemon off;"]
=======
>>>>>>> Stashed changes
