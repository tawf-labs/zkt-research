import { spawn } from "child_process";
import http from "http";
import { fileURLToPath } from "url";
import path from "path";
import fs from "fs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SERVER_SCRIPT = path.join(__dirname, "..", "index.js");
const PORT = process.env.PORT || 3099;
const BASE_URL = `http://localhost:${PORT}`;
const DATA_DIR = path.join(__dirname, "..", "..", "data");

process.env.PORT = PORT.toString();
process.env.PRIVATE_KEY = "0x0000000000000000000000000000000000000000000000000000000000000001";
process.env.RPC_URL = "http://localhost:8545";
process.env.DAO_CONTRACT_ADDRESS = "0x0000000000000000000000000000000000000000";

// Clean up persisted data from previous runs
if (fs.existsSync(DATA_DIR)) {
    fs.rmSync(DATA_DIR, { recursive: true, force: true });
}

function fetchJSON(url, options = {}) {
    return new Promise((resolve, reject) => {
        const urlObj = new URL(url);
        const req = http.request(
            {
                hostname: urlObj.hostname,
                port: urlObj.port,
                path: urlObj.pathname,
                method: options.method || "GET",
                headers: { "Content-Type": "application/json", ...options.headers },
            },
            (res) => {
                let data = "";
                res.on("data", (chunk) => (data += chunk));
                res.on("end", () => {
                    try {
                        resolve({ status: res.statusCode, body: JSON.parse(data) });
                    } catch {
                        resolve({ status: res.statusCode, body: data });
                    }
                });
            }
        );
        req.on("error", reject);
        if (options.body) req.write(JSON.stringify(options.body));
        req.end();
    });
}

async function waitForServer(url, retries = 20, delay = 500) {
    for (let i = 0; i < retries; i++) {
        try {
            const res = await fetchJSON(url);
            if (res.status === 200) return true;
        } catch {}
        await new Promise((r) => setTimeout(r, delay));
    }
    return false;
}

let serverProcess;

async function startServer() {
    return new Promise((resolve, reject) => {
        serverProcess = spawn("node", [SERVER_SCRIPT], {
            env: { ...process.env, PORT: PORT.toString(), NODE_ENV: "test" },
            stdio: ["ignore", "pipe", "pipe"],
        });
        serverProcess.stderr.on("data", (d) => process.stderr.write(d));
        serverProcess.stdout.on("data", (d) => process.stdout.write(d));
        serverProcess.on("error", reject);
        setTimeout(() => resolve(), 2000);
    });
}

function stopServer() {
    if (serverProcess) serverProcess.kill("SIGTERM");
}

const CHECK = "\u2713";
const CROSS = "\u2717";

async function test(name, fn) {
    try {
        await fn();
        console.log(`  ${CHECK} ${name}`);
        return true;
    } catch (err) {
        console.log(`  ${CROSS} ${name}: ${err.message}`);
        return false;
    }
}

async function main() {
    console.log("=== Off-Chain Coordinator Test Suite ===\n");

    // Start server
    console.log("Starting server...");
    await startServer();
    const ready = await waitForServer(`${BASE_URL}/health`);
    if (!ready) {
        console.error("Server failed to start");
        stopServer();
        process.exit(1);
    }
    console.log("Server started.\n");

    let passed = 0;
    let failed = 0;

    const results = [];

    results.push(
        await test("GET /health returns status ok", async () => {
            const res = await fetchJSON(`${BASE_URL}/health`);
            if (res.status !== 200) throw new Error(`Expected 200, got ${res.status}`);
            if (res.body.status !== "ok") throw new Error(`Expected status ok, got ${res.body.status}`);
            if (!res.body.uptime) throw new Error("Missing uptime");
            if (!res.body.memory) throw new Error("Missing memory");
            if (!res.body.tee) throw new Error("Missing TEE info");
        })
    );

    results.push(
        await test("GET /council returns council info", async () => {
            const res = await fetchJSON(`${BASE_URL}/council`);
            if (res.status !== 200) throw new Error(`Expected 200, got ${res.status}`);
            if (typeof res.body.memberCount !== "number") throw new Error("Missing memberCount");
            if (typeof res.body.root !== "string") throw new Error("Missing root");
        })
    );

    results.push(
        await test("POST /council/setup creates council", async () => {
            const members = [
                { address: "0x1111111111111111111111111111111111111111", secret: "0xabc1" },
                { address: "0x2222222222222222222222222222222222222222", secret: "0xabc2" },
                { address: "0x3333333333333333333333333333333333333333", secret: "0xabc3" },
                { address: "0x4444444444444444444444444444444444444444", secret: "0xabc4" },
                { address: "0x5555555555555555555555555555555555555555", secret: "0xabc5" },
            ];
            const res = await fetchJSON(`${BASE_URL}/council/setup`, {
                method: "POST",
                body: { members },
            });
            if (res.status !== 200) throw new Error(`Expected 200, got ${res.status}`);
            if (!res.body.success) throw new Error("Expected success");
            if (res.body.memberCount !== 5) throw new Error(`Expected 5 members, got ${res.body.memberCount}`);
            if (typeof res.body.root !== "string") throw new Error("Missing root");
        })
    );

    results.push(
        await test("POST /council/setup rejects empty members", async () => {
            const res = await fetchJSON(`${BASE_URL}/council/setup`, {
                method: "POST",
                body: { members: [] },
            });
            if (res.status !== 400) throw new Error(`Expected 400, got ${res.status}`);
        })
    );

    results.push(
        await test("POST /vote rejects non-council member", async () => {
            const res = await fetchJSON(`${BASE_URL}/vote`, {
                method: "POST",
                body: {
                    bundleId: 1,
                    proposalId: 1,
                    voterAddress: "0xDEADDEADDEADDEADDEADDEADDEADDEADDEADDEAD",
                    vote: 1,
                },
            });
            if (res.status !== 403) throw new Error(`Expected 403, got ${res.status}`);
        })
    );

    results.push(
        await test("POST /vote rejects invalid vote value", async () => {
            const res = await fetchJSON(`${BASE_URL}/vote`, {
                method: "POST",
                body: {
                    bundleId: 1,
                    proposalId: 1,
                    voterAddress: "0x1111111111111111111111111111111111111111",
                    vote: 2,
                },
            });
            if (res.status !== 400) throw new Error(`Expected 400, got ${res.status}`);
        })
    );

    results.push(
        await test("POST /vote records valid vote from council member", async () => {
            const res = await fetchJSON(`${BASE_URL}/vote`, {
                method: "POST",
                body: {
                    bundleId: 1,
                    proposalId: 1,
                    voterAddress: "0x1111111111111111111111111111111111111111",
                    vote: 1,
                },
            });
            if (res.status !== 200) throw new Error(`Expected 200, got ${res.status}`);
            if (!res.body.success) throw new Error("Expected success");
        })
    );

    results.push(
        await test("GET /votes/:bundleId/:proposalId returns counts", async () => {
            const res = await fetchJSON(`${BASE_URL}/votes/1/1`);
            if (res.status !== 200) throw new Error(`Expected 200, got ${res.status}`);
            if (res.body.approvals !== 1) throw new Error(`Expected 1 approval, got ${res.body.approvals}`);
            if (res.body.total !== 1) throw new Error(`Expected 1 total, got ${res.body.total}`);
        })
    );

    results.push(
        await test("POST /vote rejects double voting", async () => {
            const res = await fetchJSON(`${BASE_URL}/vote`, {
                method: "POST",
                body: {
                    bundleId: 1,
                    proposalId: 1,
                    voterAddress: "0x1111111111111111111111111111111111111111",
                    vote: 0,
                },
            });
            if (res.status !== 400) throw new Error(`Expected 400, got ${res.status}`);
        })
    );

    passed = results.filter((r) => r).length;
    failed = results.filter((r) => !r).length;

    console.log(`\n=== Results: ${passed} passed, ${failed} failed ===`);

    stopServer();
    process.exit(failed > 0 ? 1 : 0);
}

main().catch((err) => {
    console.error("Fatal error:", err);
    stopServer();
    process.exit(1);
});
