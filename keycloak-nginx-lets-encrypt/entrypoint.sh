#!/bin/sh

function stripStartAndEndQuotes {
    cmd="temp=\${$1%\\\"}"
    eval echo $cmd > /dev/null 2>&1
    temp="${temp#\"}"
    eval echo "$1=$temp" > /dev/null 2>&1
}

# Var checks
if [ -n "$KEYCLOAK_HOST" ] && \
    [ -n "$KEYCLOAK_PORT" ] && \
    [ -n "$KEYCLOAK_DOMAIN" ] && \
    [ -n "$LE_EMAIL" ]; then
    # Inject variables
    sed -i s/__KEYCLOAK_HOST__/$KEYCLOAK_HOST/g /etc/nginx/conf.d/keycloak.conf
    sed -i s/__KEYCLOAK_PORT__/$KEYCLOAK_PORT/g /etc/nginx/conf.d/keycloak.conf
    sed -i s/__KEYCLOAK_DOMAIN__/$KEYCLOAK_DOMAIN/g /etc/nginx/conf.d/keycloak.conf

    # https://github.com/docker/compose/issues/2854 :(
    # See https://stackoverflow.com/questions/9733338/shell-script-remove-first-and-last-quote-from-a-variable for code
    stripStartAndEndQuotes "LE_OPTIONS"
    stripStartAndEndQuotes "LE_RENEW_OPTIONS"

    certbot certonly -n "${LE_OPTIONS}" \
        --agree-tos --email "${LE_EMAIL}" \
        --webroot -w /usr/share/nginx/html -d $KEYCLOAK_DOMAIN

    # Start nginx
    nginx -g "daemon off;"

    # Install certificate renewing crontab
    touch crontab.tmp \
        && echo "37 2 * * * certbot renew ${LE_RENEW_OPTIONS}" > crontab.tmp \
        && crontab crontab.tmp \
        && rm -rf crontab.tmp
else
    echo "ERROR: please provide KEYCLOAK_HOST, KEYCLOAK_PORT, KEYCLOAK_DOMAIN, LE_EMAIL"
fi