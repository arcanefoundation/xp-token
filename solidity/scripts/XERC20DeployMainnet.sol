// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {XERC20Deploy} from './XERC20Deploy.sol';
import {XERC20Factory} from '../contracts/XERC20Factory.sol';

contract XERC20DeployMainnet is XERC20Deploy {
  function getFactory() public pure override returns (XERC20Factory) {
    return XERC20Factory(0xc36974Add85de6DB42D9ceC1b4BBA88FA26967f3); // deployed previously
  }

  function getName() public pure override returns (string memory) {
    return 'XP';
  }

  function getSymbol() public pure override returns (string memory) {
    return 'XP';
  }
}
