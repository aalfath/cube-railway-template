# Cube Store router and worker (same image; the worker sets CUBESTORE_ROLE=worker).
# Upstream image, pinned by version and digest. Keep it on the same version as cube/Dockerfile.
FROM cubejs/cubestore:v1.8.29@sha256:b64111ae4d7d8081e38c514389f259b2ac30ec04a3eebd8047df4ca14d75bbfe

ENV CUBESTORE_TELEMETRY=false \
    CUBESTORE_LOG_LEVEL=info \
    CUBESTORE_DATA_DIR=/cube/data/local \
    CUBESTORE_MINIO_SUB_PATH=cubestore

COPY start.sh /cube/railway-start.sh
CMD ["sh", "/cube/railway-start.sh"]
