#!/bin/sh
set -e

WEBROOT=/var/www/html
CONF_PERSIST=/data/ost-config.php
CONF_LINK=$WEBROOT/include/ost-config.php

mkdir -p /data

# First run: seed the persistent config from the sample (installer expects the placeholders)
if [ ! -f "$CONF_PERSIST" ]; then
    cp "$WEBROOT/include/ost-sampleconfig.php" "$CONF_PERSIST"
fi

chown www-data:www-data "$CONF_PERSIST" /data

rm -f "$CONF_LINK"
ln -s "$CONF_PERSIST" "$CONF_LINK"

if grep -q '%CONFIG-DBHOST' "$CONF_PERSIST"; then
    # Not installed yet: installer must be able to write the file
    chmod 0666 "$CONF_PERSIST"
else
    # Installed: lock the config down and remove the installer
    chmod 0644 "$CONF_PERSIST"
    rm -rf "$WEBROOT/setup"
fi

exec "$@"
