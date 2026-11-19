#!/bin/sh
# Start script for the Cube Store router and worker on Railway.
# Railway's private network is IPv6, so every port binds on [::].
set -e

if [ -z "$RAILWAY_PRIVATE_DOMAIN" ]; then
  echo "start: RAILWAY_PRIVATE_DOMAIN is empty (private networking off?)" >&2
  exit 1
fi
mkdir -p "$CUBESTORE_DATA_DIR"

# Shared remote storage: a Railway Bucket through Cube Store's S3-compatible (MinIO) driver.
# Without a bucket, Cube Store falls back to the local volume (single node only).
if [ -z "$CUBESTORE_MINIO_BUCKET" ]; then
  unset CUBESTORE_MINIO_BUCKET CUBESTORE_MINIO_SERVER_ENDPOINT CUBESTORE_MINIO_ACCESS_KEY_ID CUBESTORE_MINIO_SECRET_ACCESS_KEY CUBESTORE_MINIO_REGION
  export CUBESTORE_REMOTE_DIR="${CUBESTORE_REMOTE_DIR:-/cube/data/remote}"
  echo "start: no bucket configured; using $CUBESTORE_REMOTE_DIR on the volume" >&2
fi

case "${CUBESTORE_ROLE:-router}" in
  router)
    export CUBESTORE_SERVER_NAME="${CUBESTORE_SERVER_NAME:-$RAILWAY_PRIVATE_DOMAIN:9999}"
    export CUBESTORE_META_BIND_ADDR="${CUBESTORE_META_BIND_ADDR:-[::]:9999}"
    export CUBESTORE_HTTP_BIND_ADDR="${CUBESTORE_HTTP_BIND_ADDR:-[::]:3030}"
    export CUBESTORE_BIND_ADDR="${CUBESTORE_BIND_ADDR:-[::]:3306}"
    # Health probes (/livez, /readyz) on Railway's PORT.
    export CUBESTORE_STATUS_BIND_ADDR="${CUBESTORE_STATUS_BIND_ADDR:-[::]:${PORT:-3031}}"
    # CUBESTORE_WORKERS lists the worker(s) as host:port. Empty means the router does the work itself.
    case "$CUBESTORE_WORKERS" in ""|:*|*",:"*) unset CUBESTORE_WORKERS; echo "start: no Cube Store workers set; the router runs queries itself" >&2 ;; esac
    unset CUBESTORE_META_ADDR CUBESTORE_WORKER_PORT
    ;;
  worker)
    if [ -z "$CUBESTORE_META_ADDR" ] || [ "${CUBESTORE_META_ADDR#:}" != "$CUBESTORE_META_ADDR" ]; then
      echo "start: CUBESTORE_META_ADDR is not set yet; retrying" >&2
      sleep 10
      exit 1
    fi
    export CUBESTORE_WORKER_PORT="${CUBESTORE_WORKER_PORT:-10001}"
    export CUBESTORE_SERVER_NAME="${CUBESTORE_SERVER_NAME:-$RAILWAY_PRIVATE_DOMAIN:$CUBESTORE_WORKER_PORT}"
    export CUBESTORE_WORKER_BIND_ADDR="${CUBESTORE_WORKER_BIND_ADDR:-[::]:$CUBESTORE_WORKER_PORT}"
    export CUBESTORE_WORKERS="${CUBESTORE_WORKERS:-$CUBESTORE_SERVER_NAME}"
    case ",$CUBESTORE_WORKERS," in
      *",$CUBESTORE_SERVER_NAME,"*) ;;
      *) echo "start: warning: $CUBESTORE_SERVER_NAME is not in CUBESTORE_WORKERS ($CUBESTORE_WORKERS); the router won't send it work" >&2 ;;
    esac
    unset CUBESTORE_META_PORT CUBESTORE_HTTP_BIND_ADDR CUBESTORE_STATUS_BIND_ADDR
    ;;
  *) echo "start: CUBESTORE_ROLE must be router or worker" >&2; exit 1 ;;
esac

echo "start: Cube Store $CUBESTORE_ROLE as $CUBESTORE_SERVER_NAME (workers: $CUBESTORE_WORKERS)"
exec ./cubestored
