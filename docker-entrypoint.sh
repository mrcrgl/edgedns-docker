#!/bin/bash

set -ef -o pipefail

KEYS="UPSTREAM_SERVER UPSTREAM_MAX_FAILURES CACHE_MAX_ITEMS CACHE_MIN_TTL CACHE_MAX_TTL NETWORK_UDP_PORTS NETWORK_LISTEN WEBSERVICE_ENABLED WEBSERVICE_LISTEN"

if [ -z "${UPSTREAM_SERVER}" ]; then
    UPSTREAM_SERVER="8.8.8.8:53"
fi

if [ -z "${UPSTREAM_MAX_FAILURES}" ]; then
    UPSTREAM_MAX_FAILURES=3
fi

if [ -z "${CACHE_MAX_ITEMS}" ]; then
    CACHE_MAX_ITEMS=250000
fi

if [ -z "${CACHE_MIN_TTL}" ]; then
    CACHE_MIN_TTL=60
fi

if [ -z "${CACHE_MAX_TTL}" ]; then
    CACHE_MAX_TTL=86400
fi

if [ -z "${NETWORK_UDP_PORTS}" ]; then
    NETWORK_UDP_PORTS=80
fi

if [ -z "${NETWORK_LISTEN}" ]; then
    NETWORK_LISTEN="0.0.0.0:10053"
fi

if [ -z "${WEBSERVICE_ENABLED}" ]; then
    WEBSERVICE_ENABLED="true"
fi

if [ -z "${WEBSERVICE_LISTEN}" ]; then
    WEBSERVICE_LISTEN="0.0.0.0:9090"
fi


for name in ${KEYS}
do
  eval value=\$$name
  sed -i "s|__${name}__|${value}|g" /home/dns/edgedns.toml
done

pid=0

# SIGTERM-handler
term_handler() {
  echo "[Terminate] Initiate graceful shutdown"

  # Grace period
  echo "[Terminate] Wait grace period of 5 seconds"
  sleep 5;

  if [ $pid -ne 0 ]; then
    echo "[Terminate] Terminate EdgeDNS"
    kill -SIGTERM "$pid" || :
    wait "$pid" || :
  fi

  exit 143; # 128 + 15 => SIGTERM
}

# setup handlers
# on callback, kill the last background process, which is `tail -f /dev/null` and execute the specified handler
trap 'kill ${!}; term_handler' SIGTERM
trap 'kill ${!}; term_handler' SIGINT

$@ &

pid="$!"

# wait indefinetely
while true
do
  tail -f /dev/null & wait ${!}
done
