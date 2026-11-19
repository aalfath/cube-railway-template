# Cube API and Cube Refresh Worker (same image; the worker sets CUBEJS_REFRESH_WORKER=true).
# Upstream image, pinned by version and digest. Bump both in a PR and add a CHANGELOG entry.
FROM cubejs/cube:v1.8.29@sha256:3cd19ef06226b35b92fbf0578e0d9861557a0def7d38fd07e1556f55aa97a636

# Fixed settings (variables on the service override them).
ENV CUBEJS_DEV_MODE=false \
    CUBEJS_TELEMETRY=false \
    CUBEJS_LOG_LEVEL=info \
    CUBEJS_CACHE_AND_QUEUE_DRIVER=cubestore \
    CUBEJS_CUBESTORE_PORT=3030 \
    CUBEJS_DB_TYPE=postgres \
    PORT=4000

# The data model. Edit the files in cube/model/ in your own copy of this repo.
COPY model /cube/conf/model
COPY railway /cube/railway

EXPOSE 4000
CMD ["sh", "/cube/railway/start.sh"]
