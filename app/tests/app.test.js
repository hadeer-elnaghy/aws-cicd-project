const test = require("node:test");
const assert = require("node:assert/strict");
const http = require("node:http");
const { app } = require("../src/server.js");

function request(port, method, path, body = null) {
    return new Promise((resolve, reject) => {
        const payload = body ? JSON.stringify(body) : null;
        const req = http.request(
            {
                hostname: "127.0.0.1",
                port,
                path,
                method,
                headers: payload
                    ? {
                        "Content-Type": "application/json",
                        "Content-Length": Buffer.byteLength(payload),
                    }
                    : {},
            },
            (res) => {
                let raw = "";
                res.on("data", (chunk) => {
                    raw += chunk;
                });
                res.on("end", () => {
                    let json = null;
                    try {
                        json = JSON.parse(raw);
                    } catch {
                        json = raw;
                    }
                    resolve({ statusCode: res.statusCode, body: json });
                });
            }
        );

        req.on("error", reject);
        if (payload) {
            req.write(payload);
        }
        req.end();
    });
}

test("GET /health returns 200 ok", async (t) => {
    const server = app.listen(0);
    await new Promise((resolve) => server.once("listening", resolve));
    t.after(() => server.close());

    const { port } = server.address();
    const res = await request(port, "GET", "/health");

    assert.equal(res.statusCode, 200);
    assert.deepEqual(res.body, { status: "ok" });
});

test("GET /api/info returns service metadata", async (t) => {
    const server = app.listen(0);
    await new Promise((resolve) => server.once("listening", resolve));
    t.after(() => server.close());

    const { port } = server.address();
    const res = await request(port, "GET", "/api/info");

    assert.equal(res.statusCode, 200);
    assert.equal(res.body.service, "eks-cicd-demo");
});

test("GET /health/db returns 503 when DB is not configured", async (t) => {
    const server = app.listen(0);
    await new Promise((resolve) => server.once("listening", resolve));
    t.after(() => server.close());

    const { port } = server.address();
    const res = await request(port, "GET", "/health/db");

    assert.equal(res.statusCode, 503);
    assert.equal(res.body.db, "not configured");
});

test("POST /api/releases validates required fields or reports unconfigured DB", async (t) => {
    const server = app.listen(0);
    await new Promise((resolve) => server.once("listening", resolve));
    t.after(() => server.close());

    const { port } = server.address();
    const res = await request(port, "POST", "/api/releases", {});

    assert.ok([400, 503].includes(res.statusCode));
});