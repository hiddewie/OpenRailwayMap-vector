#!/usr/bin/env sh

exec \
  env \
    "NEWS_HASH=$(sha1sum /etc/nginx/public/news.html | awk '{print $1}')" \
    /docker-entrypoint.sh "$@"
