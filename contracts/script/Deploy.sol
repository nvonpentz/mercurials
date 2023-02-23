// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/Mercurial.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

contract Deploy is Script {
    using Strings for uint256;

    // Deployable contract
    Mercurial public mercurial;

    function run() public {
        // Start deployment
        vm.startBroadcast();

        // Deploy Mercurial contract
        mercurial = new Mercurial();
        console.log('address', address(mercurial));

        // Fetch ABI output from /out, and write to /deploys folder
        string memory compilerOutput = vm.readFile("out/Mercurial.sol/Mercurial.json");
        vm.writeFile(string.concat("deploys/mercurial.", block.chainid.toString(), ".compilerOutput.json"), compilerOutput);

        // Write address JSON to /deploys folder
        string memory addressJson = string.concat(
            '{"address": "',
            vm.toString(address(mercurial)),
            '", "blockNumber": ',
            vm.toString(block.number),
            "}"
        );

        vm.writeFile(string.concat("deploys/mercurial.", block.chainid.toString(), ".address.json"), addressJson);

        // Finish deployment
        vm.stopBroadcast();
        console.log('Deploy done...');
    }
}
