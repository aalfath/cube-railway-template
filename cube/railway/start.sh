#!/bin/sh
# Start script for the Cube API and the Cube Refresh Worker on Railway.
set -e

if [ -z "$CUBEJS_API_SECRET" ]; then
  echo "start: CUBEJS_API_SECRET is empty; refusing to start" >&2
  exit 1
fi
case "$CUBEJS_CUBESTORE_HOST" in
  ""|.*|:*) echo "start: CUBEJS_CUBESTORE_HOST is not set yet; retrying" >&2; sleep 10; exit 1 ;;
esac

# The SQL API (Postgres wire protocol) runs on the API service only, and only with a password.
if [ "$CUBEJS_REFRESH_WORKER" = "true" ] || [ -z "$CUBEJS_SQL_PASSWORD" ]; then
  unset CUBEJS_PG_SQL_PORT
else
  export CUBEJS_PG_SQL_PORT="${CUBEJS_PG_SQL_PORT:-15432}"
  export CUBEJS_SQL_USER="${CUBEJS_SQL_USER:-cube}"
fi

# Sample data for the bundled model (API service only, idempotent, never blocks the start).
if [ "$CUBEJS_REFRESH_WORKER" != "true" ] && [ "${CUBE_SAMPLE_DATA:-true}" = "true" ] && [ "$CUBEJS_DB_TYPE" = "postgres" ]; then
  node /cube/railway/seed.js || echo "start: sample data skipped (see above)" >&2
fi

exec cubejs server
