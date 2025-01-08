// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {XERC20Deploy} from './XERC20Deploy.sol';
import {XERC20Factory} from '../contracts/XERC20Factory.sol';

contract XERC20DeployTestnet is XERC20Deploy {
  function getFactory() public pure override returns (XERC20Factory) {
    return XERC20Factory(0x8CA221f9b791c9a2c097BfD580Fb17c3B74D5397); // deployed previously
  }

  function getName() public pure override returns (string memory) {
    return 'TESTXERC20';
  }

  function getSymbol() public pure override returns (string memory) {
    return 'TESTXERC20';
  }
}
