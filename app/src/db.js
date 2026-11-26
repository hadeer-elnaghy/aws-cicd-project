const { Pool } = require('pg');

const hasRequiredDbEnv = Boolean(
    process.env.DB_HOST &&
    process.env.DB_USER &&
    process.env.DB_PASSWORD &&
    process.env.DB_NAME
);

const pool = hasRequiredDbEnv
    ? new Pool({
        host: process.env.DB_HOST,
        port: Number(process.env.DB_PORT || 5432),
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_NAME,
        max: 10,
        ssl: { rejectUnauthorized: false }, // RDS Postgres usually requires SSL
    })
    : null;

module.exports = pool;