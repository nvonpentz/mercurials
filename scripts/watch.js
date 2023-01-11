const fs = require('fs');
const { exec } = require('child_process');

// Note: This script assumes it's run from within the contracts/ directory
const directoriesToWatch = ['src', 'script'];

directoriesToWatch.forEach(directoryToWatch => {
    fs.watch(directoryToWatch, (eventType, filename) => {
        if (eventType === 'change') {
            exec('forge script script/Deploy.sol --rpc-url http://localhost:8545', (error, stdout, stderr) => {
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
