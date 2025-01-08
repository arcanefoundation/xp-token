// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

// solhint-disable-next-line no-console
import {console} from 'forge-std/console.sol';
import {Test} from 'forge-std/Test.sol';
import {Script} from 'forge-std/Script.sol';

import {XERC20} from '../contracts/XERC20.sol';
import {XERC20Lockbox} from '../contracts/XERC20Lockbox.sol';
import {XERC20Factory, IXERC20Factory} from '../contracts/XERC20Factory.sol';
import {ScriptingLibrary} from './ScriptingLibrary/ScriptingLibrary.sol';

abstract contract XERC20Deploy is Script, ScriptingLibrary {
  uint256 public deployer = vm.envUint('PRIVATE_KEY');

  function getFactory() public virtual returns (XERC20Factory);
  function getName() public virtual returns (string memory);
  function getSymbol() public virtual returns (string memory);

  function run() public {
    uint8 decimals = 18;

    address governor = vm.addr(deployer);

    vm.createSelectFork(vm.rpcUrl(vm.envString('RPC_URL')));
    vm.startBroadcast(deployer);
    // If this chain does not have a factory we will revert

    XERC20Factory factory = getFactory();

    require(
      keccak256(address(factory).code) != keccak256(address(0).code), 'There is no factory deployed on this chain'
    );

    // deploy xerc20
    address _xerc20 = factory.deployXERC20(
      getName(), getSymbol(), decimals, new uint256[](0), new uint256[](0), new address[](0), 0, address(0), governor
    );

    // transfer xerc20 ownership to the governor
    XERC20(_xerc20).transferOwnership(governor);

    vm.stopBroadcast();

    // solhint-disable-next-line no-console
    console.log('Deployment to chain with RPC name: ', vm.envString('RPC_URL'));
    // solhint-disable-next-line no-console
    console.log('xERC20 token deployed: ', _xerc20);
  }
}
