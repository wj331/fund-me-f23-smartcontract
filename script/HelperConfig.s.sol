//SPDX-License-Identifier: MIT

//1. Deploy mocks when we are on a local anvil chain
//2. Keep track of contract address across different chains
//Sepolia
//mainnet

pragma solidity ^0.8.18;
import {Script} from "../lib/forge-std/src/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script{
    // if we are on a local anvil, we deploy mocks
    //otherwise, grab the existing address from live network

    //variable
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed;
    }

    //how we can choose the chain we want to deploy our smart contract to :
    constructor() {
        if (block.chainid == 11155111) {
            //matches sepolia chain id so assign var to sepolia one
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEtConfig();
        }  else {
            activeNetworkConfig = getAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure  returns (NetworkConfig memory) {
        //price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getAnvilEthConfig() public returns (NetworkConfig memory) {
        //price feed address
        if (activeNetworkConfig.priceFeed != address(0) ){
            //already set so just return
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();
        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return anvilConfig;
    }

    function getMainnetEtConfig() public pure  returns (NetworkConfig memory) {
        //price feed address
        NetworkConfig memory MainnetConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return MainnetConfig;
    }

}