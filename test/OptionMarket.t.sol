// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {Errors} from "../src/libraries/Errors.sol";
import {Market} from "../src/libraries/Market.sol";
import {MarketId} from "../src/libraries/MarketId.sol";
import {OptionMarket} from "../src/OptionMarket.sol";
import {MockERC20} from "./MockERC20.sol";
import {MockPyth} from "./pyth/MockPyth.sol";

contract OptionMarketTest is Test {
    bytes32 public immutable BTC_PRICE_FEED_ID = bytes32(uint256(1));
    bytes32 public immutable ETH_PRICE_FEED_ID = bytes32(uint256(2));
    address public immutable NATIVE_GAS_TOKEN = address(0);
    uint256 public constant ONE_WEI = 0.000000000000000001 ether;
    uint32 public constant DEFAULT_LOT_AMOUNT = 100;

    MockPyth public pyth;

    uint256 public constant MAX_INT = 2 ** 256 - 1;

    MarketId public btcMarketId = MarketId.wrap(BTC_PRICE_FEED_ID);
    MarketId public ethMarketId = MarketId.wrap(ETH_PRICE_FEED_ID);

    MockERC20 public stone;
    OptionMarket public market;

    address public owner = address(1);
    address public operator = address(2);

    address public user1 = address(3);
    address public user2 = address(4);
    address public user3 = address(5);
    address public user4 = address(6);

    address public sponsor1 = address(7);

    event Bearish(
        MarketId indexed id,
        uint256 indexed tournamentId,
        address indexed account,
        bytes32 positionId,
        uint256 expiry,
        uint256 stake,
        int64 price
    );

    event Bullish(
        MarketId indexed id,
        uint256 indexed tournamentId,
        address indexed account,
        bytes32 positionId,
        uint256 expiry,
        uint256 stake,
        int64 price
    );

    event Settle(
        MarketId indexed id,
        uint256 indexed tournamentId,
        address indexed account,
        bytes32 positionId,
        uint256 reward,
        int64 closingPrice
    );

    event SignUp(uint256 indexed tournamentId, address indexed account, uint256 amount);

    event Refill(uint256 indexed tournamentId, address indexed account, uint256 amount);

    event Claim(uint256 indexed tournamentId, address indexed account, uint256 amount);

    event StartTournament(
        uint256 indexed tournamentId,
        address initiator,
        address currency,
        uint256 prizePool,
        uint256 entryFee,
        uint256 cost,
        uint64 winners,
        uint64 startTime,
        uint64 endTime,
        uint64 maxRefill,
        string title
    );

    event SettleTournament(
        uint256 indexed tournamentId,
        address indexed operator,
        bytes32 merkleRoot
    );

    event ExtendTournament(uint256 indexed tournamentId, uint64 endTime);

    event AdjustMarketReward(MarketId indexed id, uint16 reward);

    event CreateMarket(
        MarketId indexed id,
        address creator,
        uint16 reward,
        uint32 minInterval,
        uint32 maxInterval
    );

    event AdjustMarketExpiry(MarketId indexed id, uint32 minExpiry, uint32 maxExpiry);

    event Pause(MarketId indexed id);

    event UnPause(MarketId indexed id);

    event RecoverToken(
        address indexed currency,
        address indexed recipient,
        uint256 amount
    );

    error NotOwner();
    error NotOperator();
    error UnAuthorized();

    function setUp() public {
        pyth = new MockPyth(60, 1);
        stone = new MockERC20("Stone", "STONE", 18);

        vm.startPrank(owner);
        market = new OptionMarket(owner, address(pyth));
        vm.stopPrank();
    }

    function execute_startTournament_native(
        uint32 winners,
        uint32 startTime,
        uint32 duration,
        uint256 prizePool
    ) public returns (uint64 tournamentId) {
        vm.deal(sponsor1, prizePool);

        Market.StartTournamentParam memory params = Market.StartTournamentParam(
            NATIVE_GAS_TOKEN,
            winners,
            uint64(block.timestamp + startTime),
            uint64(block.timestamp + duration),
            // 15,
            prizePool,
            0.25 ether,
            0.25 ether,
            "Hello Future"
        );
        tournamentId = uint64(market.tournamentIds());
        market.startTournament{value: prizePool}(params);
    }

    function execute_startTournament_erc20(
        uint32 winners,
        uint32 startTime,
        uint32 duration,
        uint256 prizePool
    ) public returns (uint64 tournamentId) {
        vm.startPrank(sponsor1);

        stone.mint(sponsor1, prizePool);
        stone.approve(address(market), MAX_INT);

        Market.StartTournamentParam memory params = Market.StartTournamentParam(
            address(stone),
            winners,
            uint64(block.timestamp + startTime),
            uint64(block.timestamp + duration),
            prizePool,
            2e18,
            2e18,
            "Hello Future"
        );
        tournamentId = uint64(market.tournamentIds());
        market.startTournament(params);

        vm.stopPrank();
    }

    function createBTCpriceUpdate(
        int64 price,
        uint64 publishTime
    ) public view returns (bytes memory priceUpdate) {
        priceUpdate = pyth.createPriceFeedUpdateData(
            BTC_PRICE_FEED_ID,
            price,
            10 * 100000000,
            -8,
            price,
            10 * 100000000,
            publishTime
        );
    }

    function createETHpriceUpdate(
        int64 price,
        uint64 publishTime
    ) public view returns (bytes memory priceUpdate) {
        priceUpdate = pyth.createPriceFeedUpdateData(
            ETH_PRICE_FEED_ID,
            price,
            10 * 100000000,
            -8,
            price,
            10 * 100000000,
            publishTime
        );
    }

    function test_createMarket_succeeds() public {
        vm.startPrank(owner);
        vm.expectEmit();

        emit CreateMarket(btcMarketId, owner, 8500, 5, 30);
        market.createMarket(btcMarketId, 8500, 5, 30);

        vm.stopPrank();
    }

    function test_createMarket_revertsIfMarketAlreadyExist() public {
        vm.startPrank(owner);
        market.createMarket(btcMarketId, 8500, 5, 30);
        vm.expectRevert(Errors.MarketAlreadyExist.selector);

        market.createMarket(btcMarketId, 8500, 50, 300);

        vm.stopPrank();
    }

    function test_createMarket_revertsWhenCallerIsNotOwner() public {
        vm.expectRevert(NotOwner.selector);
        market.createMarket(btcMarketId, 8500, 50, 300);
    }

    function test_startTournament_with_native_asset_succeeds() public {
        vm.startPrank(user1);
        vm.deal(user1, 70 ether);

        Market.StartTournamentParam memory params = Market.StartTournamentParam(
            NATIVE_GAS_TOKEN,
            25,
            uint64(block.timestamp),
            uint64(block.timestamp + 30),
            // 15,
            65 ether,
            0.25 ether,
            0.25 ether,
            "Hello Future"
        );

        vm.expectEmit();
        emit StartTournament(
            1,
            user1,
            params.currency,
            params.prizePool,
            params.entryFee,
            params.cost,
            params.winners,
            params.startTime,
            params.closingTime,
            DEFAULT_LOT_AMOUNT,
            params.title
        );

        market.startTournament{value: params.prizePool}(params);

        vm.stopPrank();
    }

    function test_startTournament_with_erc20_succeeds() public {
        vm.startPrank(user2);
        vm.deal(user2, 1 ether);

        stone.mint(user2, 25e18);
        stone.approve(address(market), MAX_INT);

        Market.StartTournamentParam memory params = Market.StartTournamentParam(
            address(stone),
            25,
            uint64(block.timestamp),
            uint64(block.timestamp + 30),
            21e18,
            2e18,
            2e18,
            "Hello Future"
        );

        vm.expectEmit();
        emit StartTournament(
            1,
            user2,
            params.currency,
            params.prizePool,
            params.entryFee,
            params.cost,
            params.winners,
            params.startTime,
            params.closingTime,
            DEFAULT_LOT_AMOUNT,
            params.title
        );

        market.startTournament(params);

        vm.stopPrank();
    }

    function test_startTournament_with_native_asset_revertsIfNotEnoughFundProvided()
        public
    {
        vm.startPrank(user1);
        vm.deal(user1, 7 ether);

        Market.StartTournamentParam memory params = Market.StartTournamentParam(
            NATIVE_GAS_TOKEN,
            25,
            uint64(block.timestamp),
            uint64(block.timestamp + 30),
            // 15,
            65 ether,
            0.25 ether,
            0.25 ether,
            "Hello Future"
        );

        vm.expectRevert(Errors.InsufficientRewardFund.selector);

        market.startTournament{value: 2 ether}(params);

        vm.stopPrank();
    }

    function test_signup_native_succeeds() public {
        uint64 tournamentId = execute_startTournament_native(15, 0, 30, 12 ether);
        uint256 entryFee = 0.25 ether;

        vm.startPrank(user1);
        vm.deal(user1, 1 ether);

        vm.expectEmit();
        emit SignUp(tournamentId, user1, DEFAULT_LOT_AMOUNT);
        market.signup{value: entryFee}(tournamentId);
        vm.stopPrank();
    }

    function test_signup_native_revertsIfTournamentNotFound() public {
        uint64 tournamentId = 1;
        uint256 entryFee = 0.25 ether;

        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        vm.warp(200);

        vm.expectRevert(Errors.InvalidTournament.selector);
        market.signup{value: entryFee}(tournamentId);
        vm.stopPrank();
    }

    function test_signup_native_revertsIfTournamentEnded() public {
        uint64 tournamentId = execute_startTournament_native(15, 0, 30, 12 ether);
        uint256 entryFee = 0.25 ether;

        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        vm.warp(200);

        vm.expectRevert(Errors.TournamentEnded.selector);
        market.signup{value: entryFee}(tournamentId);
        vm.stopPrank();
    }

    function test_signup_native_revertsIfUserAlreadySignedUp() public {
        uint64 tournamentId = execute_startTournament_native(15, 0, 30, 12 ether);
        uint256 entryFee = 0.25 ether;

        vm.startPrank(user1);
        vm.deal(user1, 1 ether);

        market.signup{value: entryFee}(tournamentId);
        vm.expectRevert(Errors.AlreadySignedUp.selector);

        market.signup{value: entryFee}(tournamentId);
        vm.stopPrank();
    }

    function test_signup_erc20_succeeds() public {
        uint64 tournamentId = execute_startTournament_erc20(15, 0, 30, 25e18);

        vm.startPrank(user2);
        stone.mint(user2, 5e18);
        stone.approve(address(market), MAX_INT);

        vm.expectEmit();
        emit SignUp(tournamentId, user2, DEFAULT_LOT_AMOUNT);
        market.signup(tournamentId);

        vm.stopPrank();
    }

    function test_signup_erc20_revertsIfTournamentNotFound() public {
        uint64 tournamentId = 1;

        vm.startPrank(user1);
        stone.mint(user1, 25e18);
        stone.approve(address(market), MAX_INT);
        vm.warp(200);

        vm.expectRevert(Errors.InvalidTournament.selector);
        market.signup(tournamentId);
        vm.stopPrank();
    }

    function test_signup_erc20_revertsIfTournamentEnded() public {
        uint64 tournamentId = execute_startTournament_erc20(15, 0, 30, 12e18);

        vm.startPrank(user1);
        stone.mint(user1, 25e18);
        stone.approve(address(market), MAX_INT);
        vm.warp(200);

        vm.expectRevert(Errors.TournamentEnded.selector);
        market.signup(tournamentId);
        vm.stopPrank();
    }

    function test_signup_erc20_revertsIfUserAlreadySignedUp() public {
        uint64 tournamentId = execute_startTournament_erc20(15, 0, 30, 12e18);

        vm.startPrank(user1);
        stone.mint(user1, 25e18);
        stone.approve(address(market), MAX_INT);

        market.signup(tournamentId);
        vm.expectRevert(Errors.AlreadySignedUp.selector);

        market.signup(tournamentId);
        vm.stopPrank();
    }

    function test_bearish_succeeds() public {
        vm.warp(100);
        uint64 tournamentId = execute_startTournament_native(15, 0, 30, 15 ether);
        vm.prank(owner);
        market.createMarket(btcMarketId, 8500, 60, 300);

        vm.startPrank(user1);
        vm.deal(user1, 5 ether);
        market.signup{value: 0.25 ether}(tournamentId);
        bytes32 positionId = keccak256(abi.encodePacked(btcMarketId, uint256(0), user1));

        bytes memory priceUpdate = createBTCpriceUpdate(64e8, 80);

        vm.expectEmit();
        emit Bearish(
            btcMarketId,
            tournamentId,
            user1,
            positionId,
            block.timestamp + 60,
            25,
            64e8
        );
        market.bearish{value: 0.0000001 ether}(
            btcMarketId,
            tournamentId,
            25,
            60,
            priceUpdate
        );
        vm.stopPrank();
    }

    function test_bullish_succeeds() public {
        vm.warp(100);
        uint64 tournamentId = execute_startTournament_native(15, 0, 30, 15 ether);
        vm.prank(owner);
        market.createMarket(btcMarketId, 8500, 60, 300);

        vm.startPrank(user1);
        vm.deal(user1, 5 ether);
        market.signup{value: 0.25 ether}(tournamentId);
        bytes32 positionId = keccak256(abi.encodePacked(btcMarketId, uint256(0), user1));

        bytes memory priceUpdate = createBTCpriceUpdate(64e8, 80);

        vm.expectEmit();
        emit Bullish(
            btcMarketId,
            tournamentId,
            user1,
            positionId,
            block.timestamp + 60,
            25,
            64e8
        );
        market.bullish{value: 0.0000001 ether}(
            btcMarketId,
            tournamentId,
            25,
            60,
            priceUpdate
        );
        vm.stopPrank();
    }

    function test_bearish_revertsIfMarketDoesNotExist() public {
        uint64 tournamentId = execute_startTournament_native(15, 0, 30, 15 ether);

        vm.startPrank(user1);
        vm.deal(user1, 5 ether);
        market.signup{value: 0.25 ether}(tournamentId);

        bytes memory priceUpdate = createBTCpriceUpdate(64e8, 80);

        vm.expectRevert(Errors.MarketDoesNotExist.selector);
        market.bearish{value: 0.0000001 ether}(
            btcMarketId,
            tournamentId,
            25,
            60,
            priceUpdate
        );
        vm.stopPrank();
    }

    function test_bearish_revertsIfTournamentNotOpen() public {
        uint64 tournamentId = execute_startTournament_native(15, 5, 30, 15 ether);
        vm.prank(owner);
        market.createMarket(btcMarketId, 8500, 60, 300);

        vm.startPrank(user1);
        vm.deal(user1, 5 ether);
        market.signup{value: 0.25 ether}(tournamentId);

        bytes memory priceUpdate = createBTCpriceUpdate(64e8, 80);

        vm.expectRevert(Errors.EntryNotAllowed.selector);
        market.bearish{value: 0.0000001 ether}(
            btcMarketId,
            tournamentId,
            25,
            60,
            priceUpdate
        );
        vm.stopPrank();
    }

    function test_bearish_revertsIfTournamentEnded() public {
        uint64 tournamentId = execute_startTournament_native(15, 0, 30, 15 ether);
        vm.prank(owner);
        market.createMarket(btcMarketId, 8500, 60, 300);

        vm.startPrank(user1);
        vm.deal(user1, 5 ether);
        market.signup{value: 0.25 ether}(tournamentId);

        vm.warp(60);

        bytes memory priceUpdate = createBTCpriceUpdate(64e8, 80);

        vm.expectRevert(Errors.EntryNotAllowed.selector);
        market.bearish{value: 0.0000001 ether}(
            btcMarketId,
            tournamentId,
            25,
            60,
            priceUpdate
        );
        vm.stopPrank();
    }

    function test_bearish_revertsIfEntrantHaveInsufficientBalance() public {
        vm.warp(100);
        uint64 tournamentId = execute_startTournament_native(15, 0, 30, 15 ether);
        vm.prank(owner);
        market.createMarket(btcMarketId, 8500, 60, 300);
        vm.prank(owner);
        market.createMarket(ethMarketId, 8500, 60, 300);

        vm.startPrank(user1);
        vm.deal(user1, 5 ether);
        market.signup{value: 0.25 ether}(tournamentId);

        bytes memory priceUpdate = createBTCpriceUpdate(64e8, 80);
        market.bearish{value: 0.0000001 ether}(
            btcMarketId,
            tournamentId,
            DEFAULT_LOT_AMOUNT,
            60,
            priceUpdate
        );

        bytes memory priceUpdate2 = createBTCpriceUpdate(3e8, 80);
        vm.expectRevert(Errors.InsufficientBalance.selector);
        market.bearish{value: 0.0000001 ether}(
            ethMarketId,
            tournamentId,
            25,
            60,
            priceUpdate2
        );
        vm.stopPrank();
    }

    function test_bearish_revertsWhenExpiryIsOutsideMarketRange() public {
        uint64 tournamentId = execute_startTournament_native(15, 0, 30, 15 ether);
        vm.prank(owner);
        market.createMarket(btcMarketId, 8500, 60, 300);

        vm.startPrank(user1);
        vm.deal(user1, 5 ether);
        market.signup{value: 0.25 ether}(tournamentId);

        bytes memory priceUpdate = createBTCpriceUpdate(64e8, 80);

        vm.expectRevert(Errors.InvalidExpiryInterval.selector);
        market.bearish{value: 0.0000001 ether}(
            btcMarketId,
            tournamentId,
            25,
            6,
            priceUpdate
        );
        vm.stopPrank();
    }

    function test_bearish_revertsIfPositionAlreadyExist() public {
        vm.warp(100);
        uint64 tournamentId = execute_startTournament_native(15, 0, 30, 15 ether);
        vm.prank(owner);
        market.createMarket(btcMarketId, 8500, 60, 300);

        vm.startPrank(user1);
        vm.deal(user1, 5 ether);
        market.signup{value: 0.25 ether}(tournamentId);

        bytes memory priceUpdate = createBTCpriceUpdate(64e8, 80);
        market.bearish{value: 0.0000001 ether}(
            btcMarketId,
            tournamentId,
            DEFAULT_LOT_AMOUNT,
            60,
            priceUpdate
        );

        vm.expectRevert(Errors.InsufficientBalance.selector);
        market.bearish{value: 0.0000001 ether}(
            btcMarketId,
            tournamentId,
            25,
            60,
            priceUpdate
        );
        vm.stopPrank();
    }

    function test_settle_succeeds() public {
        vm.warp(100);
        uint64 tournamentId = execute_startTournament_native(15, 0, 30, 15 ether);
        vm.prank(owner);
        market.createMarket(btcMarketId, 8500, 60, 300);

        vm.startPrank(user1);
        vm.deal(user1, 5 ether);
        market.signup{value: 0.25 ether}(tournamentId);

        bytes memory priceUpdate = createBTCpriceUpdate(64e8, 80);
        market.bullish{value: 0.0000001 ether}(
            btcMarketId,
            tournamentId,
            DEFAULT_LOT_AMOUNT,
            60,
            priceUpdate
        );
        bytes32 positionId = keccak256(abi.encodePacked(btcMarketId, uint256(0), user1));
        uint256 expectedReward = ((DEFAULT_LOT_AMOUNT * 8500) / 10000) +
            DEFAULT_LOT_AMOUNT;

        vm.warp(block.timestamp + 60);
        bytes memory priceUpdate2 = createBTCpriceUpdate(65e8, uint64(block.timestamp));
        vm.expectEmit();
        emit Settle(btcMarketId, tournamentId, user1, positionId, expectedReward, 65e8);
        market.settle{value: 0.0000001 ether}(
            btcMarketId,
            tournamentId,
            user1,
            priceUpdate2
        );
        vm.stopPrank();
    }

    function test_settle_revertsIfNoPositionFound() public {
        vm.warp(100);
        uint64 tournamentId = execute_startTournament_native(15, 0, 30, 15 ether);
        vm.prank(owner);
        market.createMarket(btcMarketId, 8500, 60, 300);

        vm.startPrank(user1);
        vm.deal(user1, 5 ether);
        market.signup{value: 0.25 ether}(tournamentId);

        vm.warp(block.timestamp + 60);
        bytes memory priceUpdate = createBTCpriceUpdate(65e8, uint64(block.timestamp));
        vm.expectRevert(Errors.PositionNotFound.selector);
        market.settle{value: 0.0000001 ether}(
            btcMarketId,
            tournamentId,
            user1,
            priceUpdate
        );

        vm.stopPrank();
    }

    function test_settle_revertsIfRewardClaimed() public {
        vm.warp(100);
        uint64 tournamentId = execute_startTournament_native(15, 0, 30, 15 ether);
        vm.prank(owner);
        market.createMarket(btcMarketId, 8500, 60, 300);

        vm.startPrank(user1);
        vm.deal(user1, 5 ether);
        market.signup{value: 0.25 ether}(tournamentId);

        bytes memory priceUpdate = createBTCpriceUpdate(64e8, 80);
        market.bullish{value: 0.0000001 ether}(
            btcMarketId,
            tournamentId,
            DEFAULT_LOT_AMOUNT,
            60,
            priceUpdate
        );

        vm.warp(block.timestamp + 60);
        bytes memory priceUpdate2 = createBTCpriceUpdate(65e8, uint64(block.timestamp));
        market.settle{value: 0.0000001 ether}(
            btcMarketId,
            tournamentId,
            user1,
            priceUpdate2
        );

        vm.expectRevert(Errors.PositionNotFound.selector);
        market.settle{value: 0.0000001 ether}(
            btcMarketId,
            tournamentId,
            user1,
            priceUpdate2
        );

        vm.stopPrank();
    }

    function test_refill_native_succeeds() public {
        vm.warp(100);
        uint64 tournamentId = execute_startTournament_native(15, 0, 300, 15 ether);
        vm.prank(owner);
        market.createMarket(btcMarketId, 8500, 60, 300);

        vm.startPrank(user1);
        vm.deal(user1, 5 ether);
        market.signup{value: 0.25 ether}(tournamentId);

        bytes memory priceUpdate = createBTCpriceUpdate(64e8, 80);
        market.bearish{value: 0.0000001 ether}(
            btcMarketId,
            tournamentId,
            DEFAULT_LOT_AMOUNT,
            60,
            priceUpdate
        );

        vm.warp(block.timestamp + 60);
        bytes memory priceUpdate2 = createBTCpriceUpdate(65e8, uint64(block.timestamp));
        market.settle{value: 0.0000001 ether}(
            btcMarketId,
            tournamentId,
            user1,
            priceUpdate2
        );

        vm.expectEmit();
        emit Refill(tournamentId, user1, DEFAULT_LOT_AMOUNT);
        market.refill{value: 0.25 ether}(tournamentId);

        vm.stopPrank();
    }

    function test_refill_native_revertsWhenNotSignedUp() public {
        vm.warp(100);
        uint64 tournamentId = execute_startTournament_native(15, 0, 300, 15 ether);

        vm.startPrank(user1);
        vm.deal(user1, 5 ether);

        vm.expectRevert(Errors.NotSignedUp.selector);
        market.refill{value: 0.25 ether}(tournamentId);

        vm.stopPrank();
    }

    function test_refill_native_revertsWhenBalanceNotDepleted() public {
        vm.warp(100);
        uint64 tournamentId = execute_startTournament_native(15, 0, 300, 15 ether);

        vm.startPrank(user1);
        vm.deal(user1, 5 ether);
        market.signup{value: 0.25 ether}(tournamentId);

        vm.expectRevert(Errors.CannotRefill.selector);
        market.refill{value: 0.25 ether}(tournamentId);

        vm.stopPrank();
    }

    function test_refill_native_revertsWhenFeeNotEnough() public {
        vm.warp(100);
        uint64 tournamentId = execute_startTournament_native(15, 0, 300, 15 ether);
        vm.prank(owner);
        market.createMarket(btcMarketId, 8500, 60, 300);

        vm.startPrank(user1);
        vm.deal(user1, 5 ether);
        market.signup{value: 0.25 ether}(tournamentId);

        bytes memory priceUpdate = createBTCpriceUpdate(64e8, 80);
        market.bearish{value: 0.0000001 ether}(
            btcMarketId,
            tournamentId,
            DEFAULT_LOT_AMOUNT,
            60,
            priceUpdate
        );

        vm.warp(block.timestamp + 60);
        bytes memory priceUpdate2 = createBTCpriceUpdate(65e8, uint64(block.timestamp));
        market.settle{value: 0.0000001 ether}(
            btcMarketId,
            tournamentId,
            user1,
            priceUpdate2
        );

        vm.expectRevert(Errors.InsufficientFee.selector);
        market.refill{value: 0.15 ether}(tournamentId);

        vm.stopPrank();
    }

    //
    function test_refill_erc20_succeeds() public {
        vm.warp(100);
        uint64 tournamentId = execute_startTournament_erc20(15, 0, 300, 15e18);
        vm.prank(owner);
        market.createMarket(btcMarketId, 8500, 60, 300);

        vm.startPrank(user1);
        stone.mint(user1, 50e18);
        stone.approve(address(market), MAX_INT);
        market.signup(tournamentId);

        bytes memory priceUpdate = createBTCpriceUpdate(64e8, 80);
        market.bearish{value: 0.0000001 ether}(
            btcMarketId,
            tournamentId,
            DEFAULT_LOT_AMOUNT,
            60,
            priceUpdate
        );

        vm.warp(block.timestamp + 60);
        bytes memory priceUpdate2 = createBTCpriceUpdate(65e8, uint64(block.timestamp));
        market.settle{value: 0.0000001 ether}(
            btcMarketId,
            tournamentId,
            user1,
            priceUpdate2
        );

        vm.expectEmit();
        emit Refill(tournamentId, user1, DEFAULT_LOT_AMOUNT);
        market.refill(tournamentId);

        vm.stopPrank();
    }

    function test_refill_erc20_revertsWhenNotSignedUp() public {
        vm.warp(100);
        uint64 tournamentId = execute_startTournament_erc20(15, 0, 300, 15e18);

        vm.startPrank(user1);
        stone.mint(user1, 50e18);
        stone.approve(address(market), MAX_INT);

        vm.expectRevert(Errors.NotSignedUp.selector);
        market.refill(tournamentId);

        vm.stopPrank();
    }

    function test_refill_erc20_revertsWhenBalanceNotDepleted() public {
        vm.warp(100);
        uint64 tournamentId = execute_startTournament_erc20(15, 0, 300, 15e18);

        vm.startPrank(user1);
        stone.mint(user1, 50e18);
        stone.approve(address(market), MAX_INT);
        market.signup(tournamentId);

        vm.expectRevert(Errors.CannotRefill.selector);
        market.refill(tournamentId);

        vm.stopPrank();
    }

    function test_settleTournament_succeeds() public {
        uint64 tournamentId = execute_startTournament_native(15, 0, 300, 15 ether);
        vm.warp(310);
        vm.prank(owner);
        market.grantOperatorRole(operator);

        bytes32 merkleRoot = bytes32(uint256(1));
        vm.expectEmit();
        emit SettleTournament(tournamentId, operator, merkleRoot);
        vm.prank(operator);
        market.settleTournament(tournamentId, merkleRoot);
    }

    function test_settleTournament_revertsIfTournamentNotFound() public {
        uint64 tournamentId = 1;
        vm.warp(310);
        vm.prank(owner);
        market.grantOperatorRole(operator);

        bytes32 merkleRoot = bytes32(uint256(1));
        vm.expectRevert(Errors.InvalidTournament.selector);
        vm.prank(operator);
        market.settleTournament(tournamentId, merkleRoot);
    }

    function test_settleTournament_revertsIfCallerNotOperator() public {
        uint64 tournamentId = execute_startTournament_native(15, 0, 300, 15 ether);
        vm.warp(310);

        bytes32 merkleRoot = bytes32(uint256(1));
        vm.expectRevert(NotOperator.selector);
        market.settleTournament(tournamentId, merkleRoot);
    }

    function test_settleTournament_revertsIfTournamentOngoing() public {
        uint64 tournamentId = execute_startTournament_native(15, 0, 300, 15 ether);
        vm.prank(owner);
        market.grantOperatorRole(operator);

        bytes32 merkleRoot = bytes32(uint256(1));
        vm.expectRevert(Errors.TournamentOngoing.selector);
        vm.prank(operator);
        market.settleTournament(tournamentId, merkleRoot);
    }

    function test_extendTournament_succeeds() public {
        uint64 tournamentId = execute_startTournament_native(15, 0, 300, 15 ether);
        vm.prank(owner);
        market.grantOperatorRole(operator);

        vm.warp(301);
        vm.expectEmit();
        emit ExtendTournament(tournamentId, 500);
        vm.prank(operator);
        market.extendTournament(tournamentId, 500);
    }

    function test_extendTournament_revertsWhenTournamentNotFound() public {
        uint64 tournamentId = 1;
        vm.prank(owner);
        market.grantOperatorRole(operator);

        vm.warp(301);
        vm.expectRevert(Errors.InvalidTournament.selector);
        vm.prank(operator);
        market.extendTournament(tournamentId, 500);
    }

    function test_extendTournament_revertsIfTimeLessThanClosing() public {
        uint64 tournamentId = execute_startTournament_native(15, 0, 300, 15 ether);
        vm.prank(owner);
        market.grantOperatorRole(operator);

        vm.expectRevert(Errors.InvalidTimeConfig.selector);
        vm.prank(operator);
        market.extendTournament(tournamentId, 50);
    }

    function test_extendTournament_revertsWhenCallerNotOperator() public {
        uint64 tournamentId = execute_startTournament_native(15, 0, 300, 15 ether);

        vm.warp(301);
        vm.expectRevert(NotOperator.selector);
        market.extendTournament(tournamentId, 500);
    }

    function test_adjustMarketReward_succeeds() public {
        vm.prank(owner);
        market.createMarket(btcMarketId, 8500, 60, 300);
        vm.prank(owner);
        market.grantOperatorRole(operator);

        vm.expectEmit();
        emit AdjustMarketReward(btcMarketId, 9500);
        vm.prank(operator);
        market.adjustMarketReward(btcMarketId, 9500);
    }

    function test_adjustMarketReward_revertsIfMarketDoesNotExist() public {
        vm.prank(owner);
        market.grantOperatorRole(operator);

        vm.expectRevert(Errors.MarketDoesNotExist.selector);
        vm.prank(operator);
        market.adjustMarketReward(btcMarketId, 9500);
    }

    function test_adjustMarketReward_revertsIfRewardExceedsMax() public {
        vm.prank(owner);
        market.createMarket(btcMarketId, 8500, 60, 300);
        vm.prank(owner);
        market.grantOperatorRole(operator);

        vm.expectRevert(Errors.RewardExceedsMax.selector);
        vm.prank(operator);
        market.adjustMarketReward(btcMarketId, 16000);
    }

    function test_adjustMarketExpiry_succeeds() public {
        vm.prank(owner);
        market.createMarket(btcMarketId, 8500, 60, 300);
        vm.prank(owner);
        market.grantOperatorRole(operator);

        vm.expectEmit();
        emit AdjustMarketExpiry(btcMarketId, 120, 400);
        vm.prank(operator);
        market.adjustMarketExpiry(btcMarketId, 120, 400);
    }

    function test_adjustMarketExpiry_revertsIfMarketDoesNotExist() public {
        vm.prank(owner);
        market.grantOperatorRole(operator);

        vm.expectRevert(Errors.MarketDoesNotExist.selector);
        vm.prank(operator);
        market.adjustMarketExpiry(btcMarketId, 120, 400);
    }

    function test_adjustMarketExpiry_revertsWhenTimeIdInvalid() public {
        vm.prank(owner);
        market.createMarket(btcMarketId, 8500, 60, 300);
        vm.prank(owner);
        market.grantOperatorRole(operator);

        vm.expectRevert(Errors.InvalidTimeConfig.selector);
        vm.prank(operator);
        market.adjustMarketExpiry(btcMarketId, 20, 50);
    }

    function test_pause_succeeds_with_owner() public {
        vm.prank(owner);
        market.createMarket(btcMarketId, 8500, 60, 300);

        vm.expectEmit();
        emit Pause(btcMarketId);
        vm.prank(owner);
        market.pause(btcMarketId);
    }

    function test_pause_succeeds_with_operator() public {
        vm.prank(owner);
        market.createMarket(btcMarketId, 8500, 60, 300);
        vm.prank(owner);
        market.grantOperatorRole(operator);

        vm.expectEmit();
        emit Pause(btcMarketId);
        vm.prank(operator);
        market.pause(btcMarketId);
    }

    function test_pause_revertsIfMarketDoesNotExist() public {
        vm.expectRevert(Errors.MarketDoesNotExist.selector);
        vm.prank(owner);
        market.pause(btcMarketId);
    }

    function test_pause_revertsIfMarketPausedAlready() public {
        vm.startPrank(owner);
        market.createMarket(btcMarketId, 8500, 60, 300);
        market.pause(btcMarketId);

        vm.expectRevert(Errors.MarketPaused.selector);
        market.pause(btcMarketId);
        vm.stopPrank();
    }

    //
    function test_unpause_succeeds_with_owner() public {
        vm.startPrank(owner);
        market.createMarket(btcMarketId, 8500, 60, 300);
        market.pause(btcMarketId);

        vm.expectEmit();
        emit UnPause(btcMarketId);
        market.unpause(btcMarketId);
        vm.stopPrank();
    }

    function test_unpause_succeeds_with_operator() public {
        vm.prank(owner);
        market.createMarket(btcMarketId, 8500, 60, 300);
        vm.prank(owner);
        market.grantOperatorRole(operator);

        vm.prank(operator);
        market.pause(btcMarketId);

        vm.expectEmit();
        emit UnPause(btcMarketId);
        vm.prank(operator);
        market.unpause(btcMarketId);
    }

    function test_unpause_revertsIfMarketDoesNotExist() public {
        vm.expectRevert(Errors.MarketDoesNotExist.selector);
        vm.prank(owner);
        market.unpause(btcMarketId);
    }

    function test_unpause_revertsIfMarketNotPaused() public {
        vm.startPrank(owner);
        market.createMarket(btcMarketId, 8500, 60, 300);

        vm.expectRevert(Errors.MarketNotPaused.selector);
        market.unpause(btcMarketId);
        vm.stopPrank();
    }

    function test_unclaimedFees() public {
        uint64 tournamentId = execute_startTournament_native(15, 0, 30, 12 ether);
        uint256 entryFee = 0.25 ether;

        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        market.signup{value: entryFee}(tournamentId);
        vm.stopPrank();

        vm.startPrank(user2);
        vm.deal(user2, 1 ether);
        market.signup{value: entryFee}(tournamentId);
        vm.stopPrank();

        vm.startPrank(user3);
        vm.deal(user3, 1 ether);
        market.signup{value: entryFee}(tournamentId);
        vm.stopPrank();

        vm.startPrank(user4);
        vm.deal(user4, 1 ether);
        market.signup{value: entryFee}(tournamentId);
        vm.stopPrank();

        uint256 unclaimedFees = market.unclaimedFees(tournamentId);
        assertEq(unclaimedFees == 1 ether, true);
    }
}
