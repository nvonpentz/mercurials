const readline = require('readline');
const fetch = require('node-fetch');

const confirm = async () => {
  return new Promise((resolve, reject) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });
  
    rl.question('Please enter "deploy" to deploy: ', (answer) => {
      if (answer === 'deploy') {
        console.log('Proceeding...');
        resolve(true);
      } else {
        console.log('Aborting.');
        resolve(false);
      }
      rl.close();
    });
  });
};

// Check that the local Ethereum node is
// running on localhost:8545
const getChainId = async (rpcUrl) => {
  const response = await fetch(rpcUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
          jsonrpc: '2.0',
          method: 'eth_chainId',
          params: [],
          id: 1
      })
  })
  const data = await response.json();
  const chainId = parseInt(data.result, 16);
  return chainId;
}

const getChainIdOrExit = async (rpcUrl) => {
  try {
    return await getChainId(rpcUrl);
  } catch (e) {
    console.error('Could not connect to local Ethereum node. Please make sure that your local Ethereum node is running on localhost:8545.');
    process.exit(1);
  }
}

module.exports = {
  confirm, getChainId, getChainIdOrExit
};
