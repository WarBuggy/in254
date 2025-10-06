const DEFAULT_PUBLIC_DIR = './public/';
const DEFAULT_PORT = 7798;

const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const xml2js = require('xml2js');

const app = express();

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb', }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

const CONFIG_FILE = 'configServer.xml';

// Function to load config.xml
function loadConfig() {
    try {
        const xmlData = fs.readFileSync(CONFIG_FILE, 'utf8');
        const config = {};
        xml2js.parseString(xmlData, (err, result) => {
            if (err) throw err;
            const serverCfg = result.config.server[0];
            config.port = parseInt(serverCfg.port[0], 10) || config.port;
            config.publicDir = serverCfg.publicDir[0] || config.publicDir;
        });
        return config;
    } catch (error) {
        console.error(`Failed to read ${CONFIG_FILE}, using defaults.`);
        return { port: DEFAULT_PORT, publicDir: DEFAULT_PUBLIC_DIR, };
    }
};

// Load config
const { port, publicDir, } = loadConfig();
// Serve static files
app.use(express.static(__dirname));

// Start server
app.listen(port, async () => {
    console.log(`Server running at http://localhost:${port}`);
    const absolutePublicPath = path.resolve(__filename);
    console.log(`Serving static files from: ${absolutePublicPath}`);
    // Open index.html in default browser
    const indexPath = `http://localhost:${port}/${publicDir}index.html`;
    try {
        const open = (await import('open')).default;
        await open(indexPath);
        console.log(`Opened ${indexPath} in browser`);
    } catch (err) {
        console.error('Could not open browser: ', err);
    }
});