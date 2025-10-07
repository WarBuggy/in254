const DEFAULT_PUBLIC_DIR = 'public';
const DEFAULT_PORT = 7798;

const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const xml2js = require('xml2js');

const app = express();

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// Detect if running inside pkg
const isPkg = typeof process.pkg !== 'undefined';
const basePath = isPkg ? path.dirname(process.execPath) : __dirname;

// Config file path
const CONFIG_FILE = path.join(basePath, 'serverConfig.xml');

// Load config function
function loadConfig() {
    try {
        const xmlData = fs.readFileSync(CONFIG_FILE, 'utf8');
        const config = {};
        xml2js.parseString(xmlData, (err, result) => {
            if (err) throw err;
            const serverCfg = result.config.server[0];
            config.port = parseInt(serverCfg.port[0], 10) || DEFAULT_PORT;
            config.publicDir = serverCfg.publicDir[0] || DEFAULT_PUBLIC_DIR;
        });
        return config;
    } catch (error) {
        console.error(`Failed to read ${CONFIG_FILE}, using defaults.`);
        return { port: DEFAULT_PORT, publicDir: DEFAULT_PUBLIC_DIR };
    }
}

// Load configuration
const { port, publicDir } = loadConfig();

// Serve folders with URL prefix
app.use('/public', express.static(path.join(basePath, publicDir)));
app.use('/mod', express.static(path.join(basePath, 'mod')));

// Add more folders if needed
// app.use('/assets', express.static(path.join(basePath, 'assets')));

// Start server
app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
    console.log(`Serving /public from: ${path.join(basePath, publicDir)}`);
    console.log(`Serving /mod from: ${path.join(basePath, 'mod')}`);
});
