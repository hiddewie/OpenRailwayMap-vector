#!/usr/bin/env sh

exec \
  env \
    "NEWS_HASH=$(grep '<h5>' /etc/nginx/public/news.html | sha1sum - | awk '{print $1}')" \
    "NGINX_RESOLVER=$(grep 'nameserver' /etc/resolv.conf | sed 's/^nameserver //')" \
    /docker-entrypoint.sh "$@"
