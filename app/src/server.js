const express = require("express");
const path = require("node:path");
const pool = require("./db");

const app = express();
const port = process.env.PORT || 3001;
const appVersion = process.env.APP_VERSION || "local-dev";

app.use(express.json());
app.use(express.static(path.join(__dirname, "../public")));

app.get("/health", (req, res) => {
    res.status(200).json({ status: "ok" });
});

app.get("/health/db", async (req, res) => {
    if (!pool) {
        return res.status(503).json({ status: "error", db: "not configured" });
    }
    try {
        await pool.query("SELECT 1");
        res.status(200).json({ status: "ok", db: "connected" });
    } catch (err) {
        console.error("DB health check failed:", err);
        res.status(500).json({ status: "error", db: "disconnected" });
    }
});

app.get("/api/info", (req, res) => {
    res.status(200).json({
        service: "eks-cicd-demo",
        version: appVersion,
        message: "Live on Amazon EKS!",
    });
});

app.get("/api/releases", async (req, res) => {
    if (!pool) {
        return res.status(503).json({ error: "Database not configured" });
    }
    try {
        const [rows] = await pool.query(
            "SELECT id, version, commit_sha, stage, status, notes, created_at FROM releases ORDER BY id DESC LIMIT 10"
        );
        res.status(200).json(rows);
    } catch (err) {
        console.error("Failed to fetch releases:", err);
        res.status(500).json({ error: "Database query failed" });
    }
});

app.post("/api/releases", async (req, res) => {
    if (!pool) {
        return res.status(503).json({ error: "Database not configured" });
    }
    const { version, commit_sha, stage = "EKS Rollout", status = "PASSED", notes } = req.body || {};
    if (!version || !commit_sha || !notes) {
        return res.status(400).json({ error: "version, commit_sha, and notes are required" });
    }
    try {
        const [result] = await pool.query(
            "INSERT INTO releases (version, commit_sha, stage, status, notes) VALUES (?, ?, ?, ?, ?)",
            [String(version).trim(), String(commit_sha).trim(), String(stage).trim(), status, String(notes).trim()]
        );
        res.status(201).json({ id: result.insertId, version, commit_sha, stage, status, notes });
    } catch (err) {
        console.error("Failed to insert release:", err);
        res.status(500).json({ error: "Database insert failed" });
    }
});

let server;
if (require.main === module) {
    server = app.listen(port, () => {
        console.log(`Server listening on port ${port}`);
    });
}

module.exports = { app, server };