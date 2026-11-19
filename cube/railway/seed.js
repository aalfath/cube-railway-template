// Creates the sample table cube_demo.orders (1,000 rows) in the bundled Postgres
// when it doesn't exist yet. Leaves existing data alone. Waits up to 3 minutes for Postgres.
const { Client } = require('pg');

const log = (m) => console.log(`seed: ${m}`);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const SQL = `
CREATE SCHEMA IF NOT EXISTS cube_demo;
CREATE TABLE IF NOT EXISTS cube_demo.orders (
  id integer PRIMARY KEY,
  created_at timestamp NOT NULL,
  status text NOT NULL,
  category text NOT NULL,
  city text NOT NULL,
  amount numeric(10,2) NOT NULL
);
INSERT INTO cube_demo.orders
SELECT g,
  timestamp '2025-01-01' + make_interval(days => (g * 37) % 365, hours => (g * 7) % 24),
  (ARRAY['completed','completed','completed','shipped','shipped','processing','cancelled'])[g % 7 + 1],
  (ARRAY['Electronics','Books','Home','Toys','Sports'])[(g / 10) % 5 + 1],
  (ARRAY['Berlin','London','New York','Paris','Tokyo','Toronto'])[g % 6 + 1],
  5 + ((g * 7919) % 50000) / 100.0
FROM generate_series(1, 1000) AS g
WHERE NOT EXISTS (SELECT 1 FROM cube_demo.orders);
`;

async function main() {
  const end = Date.now() + 3 * 60 * 1000;
  for (;;) {
    const c = new Client({
      host: process.env.CUBEJS_DB_HOST,
      port: Number(process.env.CUBEJS_DB_PORT || 5432),
      database: process.env.CUBEJS_DB_NAME,
      user: process.env.CUBEJS_DB_USER,
      password: process.env.CUBEJS_DB_PASS,
      ssl: process.env.CUBEJS_DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
    });
    try {
      await c.connect();
      await c.query(SQL);
      const n = (await c.query('SELECT count(*)::int AS n FROM cube_demo.orders')).rows[0].n;
      log(`cube_demo.orders has ${n} rows`);
      await c.end();
      return;
    } catch (e) {
      try { await c.end(); } catch (_) {}
      if (Date.now() > end) throw e;
      log(`waiting for Postgres: ${e.message}`);
      await sleep(5000);
    }
  }
}

main().catch((e) => { log(`failed: ${e.message}`); process.exit(1); });
