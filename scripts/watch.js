const fs = require('fs');
const { exec } = require('child_process');

// Note: This script assumes it's run from within the contracts/ directory
const command = 'forge script script/Deploy.sol --rpc-url http://localhost:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'
const directoriesToWatch = ['src', 'script'];
directoriesToWatch.forEach(directoryToWatch => {
    fs.watch(directoryToWatch, (eventType, filename) => {
        if (eventType === 'change') {
            exec(command, (error, stdout, stderr) => {
                if (error) {
                    console.error(`exec error: ${error}`);
                    return;
                }
                console.log(`stdout: ${stdout}`);
                console.error(`stderr: ${stderr}`);
            });
        }
    });

    console.log(`Watching ${directoryToWatch} for changes...`);
});
