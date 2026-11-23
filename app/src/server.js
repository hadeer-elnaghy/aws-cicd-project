const express = require("express");
const path = require("node:path");

const app = express();
const port = process.env.PORT || 3001;
const appVersion = process.env.APP_VERSION || "local-dev";

app.use(express.static(path.join(__dirname, "../public")));

app.get("/health", (req, res) => {
    res.status(200).json({ status: "ok" });
});

app.get("/api/info", (req, res) => {
    res.status(200).json({
        service: "eks-cicd-demo",
        version: appVersion,
        message: "Live on Amazon EKS!"
    });
});

let server;
if (require.main === module) {
    server = app.listen(port, () => {
        console.log(`Server listening on port ${port}`);
    });
}

module.exports = { app, server };