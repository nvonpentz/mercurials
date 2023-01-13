const fs = require("fs");
const fetch = require("node-fetch");
const { exec } = require("child_process");

let commandRunning = false;

const runCommand = async (command, callback) => {
  if (commandRunning) {
    console.log("Command already running, skipping...");
    return;
  }
  commandRunning = true;

  try {
    // Check if blockchain node is running
    const response = await fetch("http://localhost:8545", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        jsonrpc: "2.0",
        id: 1,
        method: "eth_chainId",
        params: [],
      }),
    });
    const json = await response.json();
    console.log(`Chain ID: ${json.result}`);

    // Run command
    exec(command, (error, stdout, stderr) => {
      if (error) {
        console.error(`exec error: ${error}`);
        return;
      }
      console.log(`stdout: ${stdout}`);
      console.error(`stderr: ${stderr}`);
      callback(stdout);
    });
  } catch (err) {
    console.error(err);
    process.exit(1);
  } finally {
    commandRunning = false;
  }
};

const watchDirectories = async (directories, command) => {
  for (const directory of directories) {
    fs.watch(directory, async (eventType) => {
      if (eventType === "change") {
        console.log(`File change detected in ${directory}`);
        runCommand(command, (stdout) => {
          console.log(`Command finished with return value: ${stdout}`);
          console.log(`Finished running command.`);
        });
      }
    });
  }
};

const start = async (directories, command) => {
  await runCommand(command, (stdout) => {
    console.log(`Command finished with return value: ${stdout}`);
  });
  watchDirectories(directories, command);
};

start(["src", "script"],
"forge script script/Deploy.sol --rpc-url http://localhost:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
);

