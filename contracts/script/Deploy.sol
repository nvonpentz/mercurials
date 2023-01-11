// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Fossil.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

contract Deploy is Script {
    using Strings for uint256;

    // Deployable contract
    Fossil public fossil;

    function run() public {
        // Start deployment
        vm.startBroadcast();

        // Deploy Fossil contract
        fossil = new Fossil();

        // Fetch ABI output from /out, and write to /deploys folder
        string memory compilerOutput = vm.readFile("out/Fossil.sol/Fossil.json");
        vm.writeFile(string.concat("deploys/fossil.", block.chainid.toString(), ".compilerOutput.json"), compilerOutput);

        // Write address JSON to /deploys folder
        string memory addressJson = string.concat(
            '{"address": "',
            vm.toString(address(fossil)),
            '", "blockNumber": ',
            vm.toString(block.number),
            "}"
        );

        vm.writeFile(string.concat("deploys/fossil.", block.chainid.toString(), ".address.json"), addressJson);

        // Finish deployment
        vm.stopBroadcast();
    }
}
