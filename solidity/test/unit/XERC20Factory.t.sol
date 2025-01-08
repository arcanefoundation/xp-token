// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {Test} from 'forge-std/Test.sol';
import {XERC20} from '../../contracts/XERC20.sol';
import {XERC20Factory} from '../../contracts/XERC20Factory.sol';
import {XERC20Lockbox} from '../../contracts/XERC20Lockbox.sol';
import {IXERC20Factory} from '../../interfaces/IXERC20Factory.sol';
import {CREATE3} from 'isolmate/utils/CREATE3.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract XERC20FactoryForTest is XERC20Factory {
  function getDeployed(
    bytes32 _salt
  ) public view returns (address _precomputedAddress) {
    _precomputedAddress = CREATE3.getDeployed(_salt);
  }
}

abstract contract Base is Test {
  address internal _owner = vm.addr(1);
  address internal _user = vm.addr(2);
  address internal _erc20 = vm.addr(3);
  address internal _receiver = vm.addr(4);
  address internal _xerc20 = vm.addr(4);

  XERC20FactoryForTest internal _xerc20Factory;

  event XERC20Deployed(address _xerc20);
  event LockboxDeployed(address payable _lockbox);

  function setUp() public virtual {
    _xerc20Factory = new XERC20FactoryForTest();
  }
}

contract UnitDeploy is Base {
  function testDeployment(uint256 _initialSupply, uint8 _decimals) public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.prank(_owner);
    address _xerc20 = _xerc20Factory.deployXERC20(
      'Test', 'TST', _decimals, _limits, _limits, _minters, _initialSupply, _receiver, address(0)
    );
    assertEq(XERC20(_xerc20).name(), 'Test');
    assertEq(XERC20(_xerc20).owner(), _owner);
    assertEq(XERC20(_xerc20).decimals(), _decimals);
    assertEq(XERC20(_xerc20).balanceOf(_receiver), _initialSupply);
  }

  function testDeploymentDifferentOwner(
    uint256 _initialSupply
  ) public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    address differentOwner = vm.addr(1001);
    vm.prank(_owner);
    address _xerc20 = _xerc20Factory.deployXERC20(
      'Test', 'TST', 18, _limits, _limits, _minters, _initialSupply, _receiver, differentOwner
    );
    assertEq(XERC20(_xerc20).name(), 'Test');
    assertEq(XERC20(_xerc20).owner(), differentOwner);
    assertEq(XERC20(_xerc20).balanceOf(_receiver), _initialSupply);
  }

  function testDeploymentInitialSupplyNoReceiver(
    uint256 _initialSupply
  ) public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    address differentOwner = vm.addr(1001);
    vm.prank(_owner);
    address _xerc20 = _xerc20Factory.deployXERC20(
      'Test', 'TST', 18, _limits, _limits, _minters, _initialSupply, address(0), differentOwner
    );
    assertEq(XERC20(_xerc20).name(), 'Test');
    assertEq(XERC20(_xerc20).owner(), differentOwner);
    assertEq(XERC20(_xerc20).balanceOf(_owner), _initialSupply);
  }

  function testRevertsWhenAddressIsTaken() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.prank(_owner);
    _xerc20Factory.deployXERC20('Test', 'TST', 18, _limits, _limits, _minters, 0, address(0), address(0));

    vm.prank(_owner);
    vm.expectRevert('DEPLOYMENT_FAILED');
    _xerc20Factory.deployXERC20('Test', 'TST', 18, _limits, _limits, _minters, 0, address(0), address(0));
  }

  function testComputedAddress() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.startPrank(address(_owner));
    bytes32 _salt = keccak256(abi.encodePacked('Test', 'TST', _owner));

    address _xerc20 =
      _xerc20Factory.deployXERC20('Test', 'TST', 18, _limits, _limits, _minters, 0, address(0), address(0));
    vm.stopPrank();
    address _predictedAddress = _xerc20Factory.getDeployed(_salt);

    assertEq(_predictedAddress, _xerc20);
  }

  function testLockboxPrecomputedAddress() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.mockCall(address(_erc20), abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(18));

    vm.startPrank(_owner);
    address _xerc20 =
      _xerc20Factory.deployXERC20('Test', 'TST', 18, _limits, _limits, _minters, 0, address(0), address(0));
    address payable _lockbox = payable(_xerc20Factory.deployLockbox(_xerc20, _erc20, false));
    vm.stopPrank();

    bytes32 _salt = keccak256(abi.encodePacked(_xerc20, _erc20, _owner));
    address _predictedAddress = _xerc20Factory.getDeployed(_salt);

    assertEq(_predictedAddress, _lockbox);
  }

  function testLockboxSingleDeployment() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.mockCall(address(_erc20), abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(18));

    vm.startPrank(_owner);
    address _xerc20 =
      _xerc20Factory.deployXERC20('Test', 'TST', 18, _limits, _limits, _minters, 0, address(0), address(0));

    address payable _lockbox = payable(_xerc20Factory.deployLockbox(_xerc20, _erc20, false));
    vm.stopPrank();

    assertEq(address(XERC20Lockbox(_lockbox).XERC20()), _xerc20);
    assertEq(address(XERC20Lockbox(_lockbox).ERC20()), _erc20);
  }

  function testLockboxSingleDeploymentRevertsIfNotOwner() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.startPrank(_owner);
    address _xerc20 =
      _xerc20Factory.deployXERC20('Test', 'TST', 18, _limits, _limits, _minters, 0, address(0), address(0));
    vm.stopPrank();

    vm.mockCall(address(_erc20), abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(18));

    vm.expectRevert(IXERC20Factory.IXERC20Factory_NotOwner.selector);
    _xerc20Factory.deployLockbox(_xerc20, _erc20, false);
  }

  function testLockboxDeploymentRevertsIfMaliciousXERC20Address() public {
    vm.expectRevert(IXERC20Factory.IXERC20Factory_BadTokenAddress.selector);
    _xerc20Factory.deployLockbox(address(0), _erc20, false);
  }

  function testLockboxDeploymentRevertsIfMaliciousAddress() public {
    vm.expectRevert(IXERC20Factory.IXERC20Factory_BadTokenAddress.selector);
    _xerc20Factory.deployLockbox(_xerc20, address(0), false);
  }

  function testLockboxDeploymentRevertsIncompatibleDecimals() public {
    vm.mockCall(address(_xerc20), abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(18));
    vm.mockCall(address(_erc20), abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(6));

    vm.expectRevert(IXERC20Factory.IXERC20Factory_IncompatibleDecimals.selector);
    _xerc20Factory.deployLockbox(_xerc20, _erc20, false);
  }

  function testLockboxDeploymentRevertsIncompatibleDecimalsNative() public {
    vm.mockCall(address(_xerc20), abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(6));

    vm.expectRevert(IXERC20Factory.IXERC20Factory_IncompatibleDecimals.selector);
    _xerc20Factory.deployLockbox(_xerc20, address(0), true);
  }

  function testLockboxDeploymentRevertsIfInvalidParameters() public {
    vm.mockCall(address(_xerc20), abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(18));
    vm.mockCall(address(_erc20), abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(18));

    vm.expectRevert(IXERC20Factory.IXERC20Factory_BadTokenAddress.selector);
    _xerc20Factory.deployLockbox(_erc20, _xerc20, true);
  }

  function testCantDeployLockboxTwice() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.mockCall(address(_erc20), abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(18));

    address _xerc20 =
      _xerc20Factory.deployXERC20('Test', 'TST', 18, _limits, _limits, _minters, 0, address(0), address(0));

    _xerc20Factory.deployLockbox(_xerc20, _erc20, false);

    vm.expectRevert(IXERC20Factory.IXERC20Factory_LockboxAlreadyDeployed.selector);
    _xerc20Factory.deployLockbox(_xerc20, _erc20, false);
  }

  function testNotParallelArraysRevert() public {
    uint256[] memory _minterLimits = new uint256[](1);
    uint256[] memory _burnerLimits = new uint256[](1);
    uint256[] memory _empty = new uint256[](0);
    address[] memory _minters = new address[](0);

    _minterLimits[0] = 1;
    _burnerLimits[0] = 1;

    vm.prank(_owner);
    vm.expectRevert(IXERC20Factory.IXERC20Factory_InvalidLength.selector);
    _xerc20Factory.deployXERC20('Test', 'TST', 18, _minterLimits, _empty, _minters, 0, address(0), address(0));

    vm.expectRevert(IXERC20Factory.IXERC20Factory_InvalidLength.selector);
    _xerc20Factory.deployXERC20('Test', 'TST', 18, _empty, _burnerLimits, _minters, 0, address(0), address(0));
  }

  function testDeployEmitsEvent() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    address _token = _xerc20Factory.getDeployed(keccak256(abi.encodePacked('Test', 'TST', _owner)));
    vm.expectEmit(true, true, true, true);
    emit XERC20Deployed(_token);
    vm.prank(_owner);
    _xerc20Factory.deployXERC20('Test', 'TST', 18, _limits, _limits, _minters, 0, address(0), address(0));
  }

  function testLockboxEmitsEvent() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);
    vm.prank(_owner);
    address _token =
      _xerc20Factory.deployXERC20('Test', 'TST', 18, _limits, _limits, _minters, 0, address(0), address(0));
    address payable _lockbox = payable(_xerc20Factory.getDeployed(keccak256(abi.encodePacked(_token, _erc20, _owner))));

    vm.mockCall(address(_erc20), abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(18));

    vm.expectEmit(true, true, true, true);
    emit LockboxDeployed(_lockbox);
    vm.prank(_owner);
    _xerc20Factory.deployLockbox(_token, _erc20, false);
  }

  function testDeployXERC20AndLockbox() public {
    vm.mockCall(address(_erc20), abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(6));

    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.prank(_owner);
    (address xerc20, address payable lockbox) =
      _xerc20Factory.deployXERC20AndLockbox('Test', 'TST', _erc20, false, _limits, _limits, _minters, address(0));
    assertEq(XERC20(xerc20).name(), 'Test');
    assertEq(XERC20(xerc20).owner(), _owner);
    assertEq(XERC20(xerc20).decimals(), 6);
    assertEq(XERC20(xerc20).totalSupply(), 0);

    assertEq(address(XERC20Lockbox(lockbox).XERC20()), xerc20);
    assertEq(address(XERC20Lockbox(lockbox).ERC20()), _erc20);
  }

  function testDeployXERC20AndLockboxNative() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.prank(_owner);
    (address xerc20, address payable lockbox) =
      _xerc20Factory.deployXERC20AndLockbox('Test', 'TST', address(0), true, _limits, _limits, _minters, address(0));
    assertEq(XERC20(xerc20).name(), 'Test');
    assertEq(XERC20(xerc20).owner(), _owner);
    assertEq(XERC20(xerc20).decimals(), 18);
    assertEq(XERC20(xerc20).totalSupply(), 0);

    assertEq(address(XERC20Lockbox(lockbox).XERC20()), xerc20);
    assertEq(address(XERC20Lockbox(lockbox).ERC20()), address(0));
    assertEq(XERC20Lockbox(lockbox).IS_NATIVE(), true);
  }
}
