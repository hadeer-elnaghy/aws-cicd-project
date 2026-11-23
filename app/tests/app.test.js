const test = require("node:test");
const assert = require("node:assert/strict");
const http = require("node:http");
const { app } = require("../src/server.js");

test("GET /health returns 200 ok", async (t) => {
    const server = app.listen(0); // 0 picks a free port automatically
    await new Promise((resolve) => server.once("listening", resolve));

    t.after(() => server.close());

    const { port } = server.address();
    const res = await new Promise((resolve, reject) => {
        http.get(`http://127.0.0.1:${port}/health`, resolve).on("error", reject);
    });

    assert.equal(res.statusCode, 200);
});