[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/cube-1?utm_medium=integration&utm_source=button&utm_campaign=cube)

# Cube on Railway

A one-click [Railway](https://railway.com) template for [Cube](https://github.com/cube-js/cube) **v1.8.29**, the open-source semantic layer: define metrics once, then query them over REST, GraphQL or SQL (Postgres wire protocol) from BI tools, apps and AI agents.

It deploys the production stack from Cube's own [Docker deployment guide](https://cube.dev/docs/product/deployment/core):

| Service | Built from | What it does |
|---|---|---|
| **Cube API** (public) | `cube/` (`cubejs/cube:v1.8.29`, pinned by digest) | REST and GraphQL API at `/cubejs-api/v1` and `/cubejs-api/graphql`, SQL API on port 15432 (private network), health at `/readyz` |
| **Cube Refresh Worker** | `cube/` | Builds and refreshes pre-aggregations in the background (`CUBEJS_REFRESH_WORKER=true`) |
| **Cube Store Router** | `cubestore/` (`cubejs/cubestore:v1.8.29`, pinned by digest) | Cube Store metastore, query planning, cache and queue. Volume on `/cube/data` |
| **Cube Store Worker** | `cubestore/` | Stores pre-aggregation partitions and runs the queries on them. Volume on `/cube/data` |
| **Postgres** | Railway's PostgreSQL | Sample data source (`cube_demo.orders`, 1,000 rows, created on first start). Point Cube at your own warehouse when ready |
| **Bucket** | Railway Bucket | Cube Store's shared remote storage (S3-compatible), so router and worker see the same files |

## Variables

All variables are set by the template; nothing has to be typed in at deploy.

- `CUBEJS_API_SECRET` (Cube API): generated, 64 characters. Signs and checks the JWTs every API request needs. The refresh worker references it.
- `CUBEJS_SQL_USER` / `CUBEJS_SQL_PASSWORD` (Cube API): login for the SQL API; the password is generated.
- `CUBEJS_DB_*`: references to the bundled Postgres. Change them (and `CUBEJS_DB_TYPE`) on **both** Cube API and Cube Refresh Worker to use your own database.
- `CUBESTORE_MINIO_*`: references to the Railway Bucket.
- `CUBESTORE_WORKERS` (Cube Store Router): the workers as `host:port`, comma-separated. Default `cube-store-worker.railway.internal:10001`.

Fixed settings (dev mode off, telemetry off, Cube Store as cache and queue driver, ports) are set in the Dockerfiles and the start scripts.

## After deploy

1. Make a JWT signed with `CUBEJS_API_SECRET` (HS256), for example `node -e "console.log(require('jsonwebtoken').sign({}, process.env.CUBEJS_API_SECRET, {expiresIn: '30d'}))"`.
2. Query it: `curl -G https://YOUR-DOMAIN/cubejs-api/v1/load -H "Authorization: YOUR-JWT" --data-urlencode 'query={"measures":["orders.count"],"dimensions":["orders.city"]}'`.
3. Replace the sample model in `cube/model/` with cubes for your own tables (fork or eject the service source), and set `CUBE_SAMPLE_DATA=false` on Cube API to stop seeding the sample table.

To reach the SQL API from outside Railway, add a TCP proxy to port 15432 on Cube API.

## Updates

Both images are pinned by version and digest in `cube/Dockerfile` and `cubestore/Dockerfile`, always on the same Cube version. A new version lands here as a commit on `main`; Railway then shows an "update available" notice on your project and you choose when to apply it. Read [CHANGELOG.md](CHANGELOG.md) first: breaking changes are listed first.

## Repo layout

- `cube/`: Dockerfile, start script, sample seed and data model for Cube API and Cube Refresh Worker.
- `cubestore/`: Dockerfile and start script for the Cube Store router and worker (role picked from `CUBESTORE_META_ADDR`; ports bind on IPv6 for Railway's private network).
- `test/compose.yml`: local test of the same stack (SeaweedFS stands in for the bucket).

Cube is licensed under Apache-2.0 by Cube Dev, Inc. This repo only packages it for Railway.
