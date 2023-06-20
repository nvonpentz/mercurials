// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/Mercurials.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

contract Deploy is Script {
    using Strings for uint256;

    // Deployable contract
    Mercurials public mercurials;

    function run() public {
        // Start deployment
        vm.startBroadcast();

        // Deploy Mercurials contract
        mercurials = new Mercurials();
        console.log("address", address(mercurials));

        // Fetch ABI output from /out, and write to /deploys folder
        string memory compilerOutput = vm.readFile(
            "out/Mercurials.sol/Mercurials.json"
        );
        vm.writeFile(
            string.concat(
                "deploys/mercurials.",
                block.chainid.toString(),
                ".compilerOutput.json"
            ),
            compilerOutput
        );

        // Write address JSON to /deploys folder
        string memory addressJson = string.concat(
            '{"address": "',
            vm.toString(address(mercurials)),
            '", "blockNumber": ',
            vm.toString(block.number),
            "}"
        );

        vm.writeFile(
            string.concat(
                "deploys/mercurials.",
                block.chainid.toString(),
                ".address.json"
            ),
            addressJson
        );

        // Finish deployment
        vm.stopBroadcast();
        console.log("Deploy done...");
    }
}
