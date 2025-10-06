#!/usr/bin/env sh

exec \
  env \
    "NEWS_HASH=$(sha1sum /etc/nginx/public/news.html | awk '{print $1}')" \
    "NGINX_RESOLVER=$(grep 'nameserver' /etc/resolv.conf | sed 's/^nameserver //')" \
    /docker-entrypoint.sh "$@"
