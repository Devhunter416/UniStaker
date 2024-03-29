// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {V3FactoryOwner} from "src/V3FactoryOwner.sol";
import {INotifiableRewardReceiver} from "src/interfaces/INotifiableRewardReceiver.sol";
import {IUniswapV3PoolOwnerActions} from "src/interfaces/IUniswapV3PoolOwnerActions.sol";
import {IUniswapV3FactoryOwnerActions} from "src/interfaces/IUniswapV3FactoryOwnerActions.sol";
import {ERC20Fake} from "test/fakes/ERC20Fake.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IERC20Errors} from "openzeppelin/interfaces/draft-IERC6093.sol";
import {MockRewardReceiver} from "test/mocks/MockRewardReceiver.sol";
import {MockUniswapV3Pool} from "test/mocks/MockUniswapV3Pool.sol";
import {MockUniswapV3Factory} from "test/mocks/MockUniswapV3Factory.sol";

contract V3FactoryOwnerTest is Test {
  V3FactoryOwner factoryOwner;
  address admin = makeAddr("Admin");
  ERC20Fake payoutToken;
  MockRewardReceiver rewardReceiver;
  MockUniswapV3Pool pool;
  MockUniswapV3Factory factory;

  function setUp() public {
    vm.label(admin, "Admin");

    payoutToken = new ERC20Fake();
    vm.label(address(payoutToken), "Payout Token");

    rewardReceiver = new MockRewardReceiver();
    vm.label(address(rewardReceiver), "Reward Receiver");

    pool = new MockUniswapV3Pool();
    vm.label(address(pool), "Pool");

    factory = new MockUniswapV3Factory();
    vm.label(address(factory), "Factory");
  }

  // In order to fuzz over the payout amount, we require each test to call this method to deploy
  // the factory owner before doing anything else.
  function _deployFactoryOwnerWithPayoutAmount(uint256 _payoutAmount) public {
    vm.assume(_payoutAmount != 0);
    factoryOwner = new V3FactoryOwner(admin, factory, payoutToken, _payoutAmount, rewardReceiver);
    vm.label(address(factoryOwner), "Factory Owner");
  }
}

contract Constructor is V3FactoryOwnerTest {
  function testFuzz_SetsTheAdminPayoutTokenAndPayoutAmount(uint256 _payoutAmount) public {
    _deployFactoryOwnerWithPayoutAmount(_payoutAmount);

    assertEq(factoryOwner.admin(), admin);
    assertEq(address(factoryOwner.FACTORY()), address(factory));
    assertEq(address(factoryOwner.PAYOUT_TOKEN()), address(payoutToken));
    assertEq(factoryOwner.payoutAmount(), _payoutAmount);
    assertEq(address(factoryOwner.REWARD_RECEIVER()), address(rewardReceiver));
  }

  function testFuzz_SetsAllParametersToArbitraryValues(
    address _admin,
    address _factory,
    address _payoutToken,
    uint256 _payoutAmount,
    address _rewardReceiver
  ) public {
    vm.assume(_admin != address(0) && _payoutAmount != 0);
    V3FactoryOwner _factoryOwner = new V3FactoryOwner(
      _admin,
      IUniswapV3FactoryOwnerActions(_factory),
      IERC20(_payoutToken),
      _payoutAmount,
      INotifiableRewardReceiver(_rewardReceiver)
    );
    assertEq(_factoryOwner.admin(), _admin);
    assertEq(address(_factoryOwner.FACTORY()), address(_factory));
    assertEq(address(_factoryOwner.PAYOUT_TOKEN()), address(_payoutToken));
    assertEq(_factoryOwner.payoutAmount(), _payoutAmount);
    assertEq(address(_factoryOwner.REWARD_RECEIVER()), _rewardReceiver);
  }

  function testFuzz_EmitsAdminSetEvent(
    address _admin,
    address _factory,
    address _payoutToken,
    uint256 _payoutAmount,
    address _rewardReceiver
  ) public {
    vm.assume(_admin != address(0) && _payoutAmount != 0);

    vm.expectEmit();
    emit V3FactoryOwner.AdminSet(address(0), _admin);
    new V3FactoryOwner(
      _admin,
      IUniswapV3FactoryOwnerActions(_factory),
      IERC20(_payoutToken),
      _payoutAmount,
      INotifiableRewardReceiver(_rewardReceiver)
    );
  }

  function testFuzz_EmitsPayoutSetEvent(
    address _admin,
    address _factory,
    address _payoutToken,
    uint256 _payoutAmount,
    address _rewardReceiver
  ) public {
    vm.assume(_admin != address(0) && _payoutAmount != 0);

    vm.expectEmit();
    emit V3FactoryOwner.PayoutAmountSet(0, _payoutAmount);
    new V3FactoryOwner(
      _admin,
      IUniswapV3FactoryOwnerActions(_factory),
      IERC20(_payoutToken),
      _payoutAmount,
      INotifiableRewardReceiver(_rewardReceiver)
    );
  }

  function testFuzz_RevertIf_TheAdminIsAddressZero(
    address _factory,
    address _payoutToken,
    uint256 _payoutAmount,
    address _rewardReceiver
  ) public {
    vm.assume(_payoutAmount != 0);
    vm.expectRevert(V3FactoryOwner.V3FactoryOwner__InvalidAddress.selector);
    new V3FactoryOwner(
      address(0),
      IUniswapV3FactoryOwnerActions(_factory),
      IERC20(_payoutToken),
      _payoutAmount,
      INotifiableRewardReceiver(_rewardReceiver)
    );
  }

  function testFuzz_RevertIf_ThePayoutAmountIsZero(
    address _admin,
    address _factory,
    address _payoutToken,
    address _rewardReceiver
  ) public {
    vm.assume(_admin != address(0));

    vm.expectRevert(V3FactoryOwner.V3FactoryOwner__InvalidPayoutAmount.selector);
    new V3FactoryOwner(
      _admin,
      IUniswapV3FactoryOwnerActions(_factory),
      IERC20(_payoutToken),
      0,
      INotifiableRewardReceiver(_rewardReceiver)
    );
  }
}

contract SetAdmin is V3FactoryOwnerTest {
  function testFuzz_UpdatesTheAdminWhenCalledByTheCurrentAdmin(address _newAdmin) public {
    vm.assume(_newAdmin != address(0));
    _deployFactoryOwnerWithPayoutAmount(1);

    vm.prank(admin);
    factoryOwner.setAdmin(_newAdmin);

    assertEq(factoryOwner.admin(), _newAdmin);
  }

  function testFuzz_EmitsAnEventWhenUpdatingTheAdmin(address _newAdmin) public {
    vm.assume(_newAdmin != address(0));
    _deployFactoryOwnerWithPayoutAmount(1);

    vm.expectEmit();
    vm.prank(admin);
    emit V3FactoryOwner.AdminSet(admin, _newAdmin);
    factoryOwner.setAdmin(_newAdmin);
  }

  function testFuzz_RevertIf_TheCallerIsNotTheCurrentAdmin(address _notAdmin, address _newAdmin)
    public
  {
    _deployFactoryOwnerWithPayoutAmount(1);

    vm.assume(_notAdmin != admin);

    vm.expectRevert(V3FactoryOwner.V3FactoryOwner__Unauthorized.selector);
    vm.prank(_notAdmin);
    factoryOwner.setAdmin(_newAdmin);
  }

  function test_RevertIf_TheNewAdminIsAddressZero() public {
    _deployFactoryOwnerWithPayoutAmount(1);

    vm.expectRevert(V3FactoryOwner.V3FactoryOwner__InvalidAddress.selector);
    vm.prank(admin);
    factoryOwner.setAdmin(address(0));
  }
}

contract SetPayoutAmount is V3FactoryOwnerTest {
  function testFuzz_UpdatesThePayoutAmountWhenCalledByAdmin(
    uint256 _initialPayoutAmount,
    uint256 _newPayoutAmount
  ) public {
    vm.assume(_newPayoutAmount != 0);
    _deployFactoryOwnerWithPayoutAmount(_initialPayoutAmount);

    vm.prank(admin);
    factoryOwner.setPayoutAmount(_newPayoutAmount);

    assertEq(factoryOwner.payoutAmount(), _newPayoutAmount);
  }

  function testFuzz_EmitsAnEventWhenUpdatingThePayoutAmount(
    uint256 _initialPayoutAmount,
    uint256 _newPayoutAmount
  ) public {
    vm.assume(_newPayoutAmount != 0);
    _deployFactoryOwnerWithPayoutAmount(_initialPayoutAmount);

    vm.expectEmit();
    vm.prank(admin);
    emit V3FactoryOwner.PayoutAmountSet(_initialPayoutAmount, _newPayoutAmount);
    factoryOwner.setPayoutAmount(_newPayoutAmount);
  }

  function testFuzz_RevertIf_TheCallerIsNotAdmin(
    uint256 _initialPayoutAmount,
    uint256 _newPayoutAmount,
    address _notAdmin
  ) public {
    vm.assume(_notAdmin != admin && _newPayoutAmount != 0);
    _deployFactoryOwnerWithPayoutAmount(_initialPayoutAmount);

    vm.expectRevert(V3FactoryOwner.V3FactoryOwner__Unauthorized.selector);
    vm.prank(_notAdmin);
    factoryOwner.setPayoutAmount(_newPayoutAmount);
  }

  function testFuzz_RevertIf_TheNewPayoutAmountIsZero(uint256 _initialPayoutAmount) public {
    _deployFactoryOwnerWithPayoutAmount(_initialPayoutAmount);

    vm.expectRevert(V3FactoryOwner.V3FactoryOwner__InvalidPayoutAmount.selector);
    vm.prank(admin);
    factoryOwner.setPayoutAmount(0);
  }
}

contract EnableFeeAmount is V3FactoryOwnerTest {
  function testFuzz_ForwardsParametersToTheEnableFeeAmountMethodOnTheFactory(
    uint24 _fee,
    int24 _tickSpacing
  ) public {
    _deployFactoryOwnerWithPayoutAmount(1);

    vm.prank(admin);
    factoryOwner.enableFeeAmount(_fee, _tickSpacing);

    assertEq(factory.lastParam__enableFeeAmount_fee(), _fee);
    assertEq(factory.lastParam__enableFeeAmount_tickSpacing(), _tickSpacing);
  }

  function testFuzz_RevertIf_TheCallerIsNotTheAdmin(
    address _notAdmin,
    uint24 _fee,
    int24 _tickSpacing
  ) public {
    _deployFactoryOwnerWithPayoutAmount(1);
    vm.assume(_notAdmin != admin);

    vm.expectRevert(V3FactoryOwner.V3FactoryOwner__Unauthorized.selector);
    vm.prank(_notAdmin);
    factoryOwner.enableFeeAmount(_fee, _tickSpacing);
  }
}

contract SetFeeProtocol is V3FactoryOwnerTest {
  function testFuzz_ForwardsParametersToSetFeeProtocolToAPool(
    uint8 _feeProtocol0,
    uint8 _feeProtocol1
  ) public {
    _deployFactoryOwnerWithPayoutAmount(1);

    vm.prank(admin);
    factoryOwner.setFeeProtocol(pool, _feeProtocol0, _feeProtocol1);

    assertEq(pool.lastParam__setFeeProtocol_feeProtocol0(), _feeProtocol0);
    assertEq(pool.lastParam__setFeeProtocol_feeProtocol1(), _feeProtocol1);
  }

  function testFuzz_RevertIf_TheCallerIsNotTheAdmin(
    address _notAdmin,
    uint8 _feeProtocol0,
    uint8 _feeProtocol1
  ) public {
    _deployFactoryOwnerWithPayoutAmount(1);
    vm.assume(_notAdmin != admin);

    vm.expectRevert(V3FactoryOwner.V3FactoryOwner__Unauthorized.selector);
    vm.prank(_notAdmin);
    factoryOwner.setFeeProtocol(pool, _feeProtocol0, _feeProtocol1);
  }
}

contract ClaimFees is V3FactoryOwnerTest {
  function testFuzz_TransfersThePayoutFromTheCallerToTheRewardReceiver(
    uint256 _payoutAmount,
    address _caller,
    address _recipient,
    uint128 _amount0,
    uint128 _amount1
  ) public {
    _deployFactoryOwnerWithPayoutAmount(_payoutAmount);

    vm.assume(_caller != address(0) && _recipient != address(0));
    payoutToken.mint(_caller, _payoutAmount);

    vm.startPrank(_caller);
    payoutToken.approve(address(factoryOwner), _payoutAmount);
    factoryOwner.claimFees(pool, _recipient, _amount0, _amount1);
    vm.stopPrank();

    assertEq(payoutToken.balanceOf(address(rewardReceiver)), _payoutAmount);
  }

  function testFuzz_NotifiesTheRewardReceiverOfTheReward(
    uint256 _payoutAmount,
    address _caller,
    address _recipient,
    uint128 _amount0,
    uint128 _amount1
  ) public {
    _deployFactoryOwnerWithPayoutAmount(_payoutAmount);

    vm.assume(_caller != address(0) && _recipient != address(0));
    payoutToken.mint(_caller, _payoutAmount);

    vm.startPrank(_caller);
    payoutToken.approve(address(factoryOwner), _payoutAmount);
    factoryOwner.claimFees(pool, _recipient, _amount0, _amount1);
    vm.stopPrank();

    assertEq(rewardReceiver.lastParam__notifyRewardAmount_amount(), _payoutAmount);
  }

  function testFuzz_CallsPoolCollectProtocolMethodWithRecipientAndAmountsRequestedAndReturnsForwardedFeeAmountsFromPool(
    uint256 _payoutAmount,
    address _caller,
    address _recipient,
    uint128 _amount0,
    uint128 _amount1
  ) public {
    _deployFactoryOwnerWithPayoutAmount(_payoutAmount);

    vm.assume(_caller != address(0) && _recipient != address(0));
    payoutToken.mint(_caller, _payoutAmount);

    vm.startPrank(_caller);
    payoutToken.approve(address(factoryOwner), _payoutAmount);
    (uint256 _amount0Collected, uint256 _amount1Collected) =
      factoryOwner.claimFees(pool, _recipient, _amount0, _amount1);
    vm.stopPrank();

    assertEq(pool.lastParam__collectProtocol_recipient(), _recipient);
    assertEq(pool.lastParam__collectProtocol_amount0Requested(), _amount0);
    assertEq(pool.lastParam__collectProtocol_amount1Requested(), _amount1);
    assertEq(_amount0Collected, _amount0);
    assertEq(_amount1Collected, _amount1);
  }

  function testFuzz_EmitsAnEventWithFeeClaimParameters(
    uint256 _payoutAmount,
    address _caller,
    address _recipient,
    uint128 _amount0,
    uint128 _amount1
  ) public {
    _deployFactoryOwnerWithPayoutAmount(_payoutAmount);

    vm.assume(_caller != address(0) && _recipient != address(0));
    payoutToken.mint(_caller, _payoutAmount);

    vm.startPrank(_caller);
    payoutToken.approve(address(factoryOwner), _payoutAmount);
    vm.expectEmit();
    emit V3FactoryOwner.FeesClaimed(address(pool), _caller, _recipient, _amount0, _amount1);
    factoryOwner.claimFees(pool, _recipient, _amount0, _amount1);
    vm.stopPrank();
  }

  function testFuzz_RevertIf_CallerHasInsufficientBalanceOfPayoutToken(
    uint256 _payoutAmount,
    address _caller,
    address _recipient,
    uint128 _amount0,
    uint128 _amount1,
    uint256 _mintAmount
  ) public {
    _payoutAmount = bound(_payoutAmount, 1, type(uint256).max);
    _deployFactoryOwnerWithPayoutAmount(_payoutAmount);

    vm.assume(_caller != address(0) && _recipient != address(0));
    _mintAmount = bound(_mintAmount, 0, _payoutAmount - 1);
    payoutToken.mint(_caller, _mintAmount);

    vm.startPrank(_caller);
    payoutToken.approve(address(factoryOwner), _payoutAmount);

    vm.expectRevert(
      abi.encodeWithSelector(
        IERC20Errors.ERC20InsufficientBalance.selector, _caller, _mintAmount, _payoutAmount
      )
    );
    factoryOwner.claimFees(pool, _recipient, _amount0, _amount1);
    vm.stopPrank();
  }

  function testFuzz_RevertIf_CallerHasInsufficientApprovalForPayoutToken(
    uint256 _payoutAmount,
    address _caller,
    address _recipient,
    uint128 _amount0,
    uint128 _amount1,
    uint256 _approveAmount
  ) public {
    _payoutAmount = bound(_payoutAmount, 1, type(uint256).max);
    _deployFactoryOwnerWithPayoutAmount(_payoutAmount);

    vm.assume(_caller != address(0) && _recipient != address(0));
    _approveAmount = bound(_approveAmount, 0, _payoutAmount - 1);
    payoutToken.mint(_caller, _payoutAmount);

    vm.startPrank(_caller);
    payoutToken.approve(address(factoryOwner), _approveAmount);

    vm.expectRevert(
      abi.encodeWithSelector(
        IERC20Errors.ERC20InsufficientAllowance.selector,
        address(factoryOwner),
        _approveAmount,
        _payoutAmount
      )
    );
    factoryOwner.claimFees(pool, _recipient, _amount0, _amount1);
    vm.stopPrank();
  }

  function testFuzz_RevertIf_CallerExpectsMoreFeesThanPoolPaysOut(
    uint256 _payoutAmount,
    address _caller,
    address _recipient,
    uint128 _amount0Requested,
    uint128 _amount1Requested,
    uint128 _amount0Collected,
    uint128 _amount1Collected
  ) public {
    _deployFactoryOwnerWithPayoutAmount(_payoutAmount);
    vm.assume(_caller != address(0) && _recipient != address(0));
    _amount0Requested = uint128(bound(_amount0Requested, 1, type(uint128).max));
    _amount1Requested = uint128(bound(_amount1Requested, 1, type(uint128).max));

    // sometimes get less amount0, other times get less amount1
    // uses arbitrary randomness via fuzzed _payoutAmount
    if (_payoutAmount % 2 == 0) {
      _amount0Collected = uint128(bound(_amount0Collected, 0, _amount0Requested - 1));
    } else {
      _amount1Collected = uint128(bound(_amount1Collected, 0, _amount1Requested - 1));
    }
    pool.setNextReturn__collectProtocol(_amount0Collected, _amount1Collected);

    payoutToken.mint(_caller, _payoutAmount);

    vm.startPrank(_caller);
    payoutToken.approve(address(factoryOwner), _payoutAmount);

    vm.expectRevert(V3FactoryOwner.V3FactoryOwner__InsufficientFeesCollected.selector);
    factoryOwner.claimFees(pool, _recipient, _amount0Requested, _amount1Requested);
    vm.stopPrank();
  }
}
