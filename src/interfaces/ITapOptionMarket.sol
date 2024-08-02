// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

type MarketId is bytes32;

interface ITapOptionMarket {
    /**
     * @dev Emitted when a user takes a bearish position on a market
     */
    event Bearish(
        MarketId indexed id,
        uint256 indexed tournamentId,
        address indexed account,
        bytes32 positionId,
        uint256 expiry,
        uint256 stake,
        int64 price
    );

    /**
     * @dev Emitted when a user takes a bullish position on a market
     */
    event Bullish(
        MarketId indexed id,
        uint256 indexed tournamentId,
        address indexed account,
        bytes32 positionId,
        uint256 expiry,
        uint256 stake,
        int64 price
    );

    /**
     * @notice Emitted whenever an option is excersised
     */
    event Settle(
        MarketId indexed id,
        uint256 indexed tournamentId,
        address indexed account,
        bytes32 positionId,
        uint256 reward,
        int64 closingPrice
    );

    /**
     * @notice Emitted whenever a new user signs up for tournament
     */
    event SignUp(uint256 indexed tournamentId, address indexed account, uint256 amount);

    /**
     * @notice Emitted whenever an account refills it's tournament balance
     */
    event Refill(uint256 indexed tournamentId, address indexed account, uint256 amount);

    /**
     * @notice Emitted whenever an account claims tournament reward
     */
    event Claim(uint256 indexed tournamentId, address indexed account, uint256 amount);

    /**
     * @dev Called to open a bearish position on a market
     *
     * @param id the identifier of market to open position in
     * @param tournamentId the participating tournament identifier
     * @param investment the amount to invest
     * @param expiry the option expiry in seconds after openning
     * @param priceUpdate the pyth network price update data
     */
    function bearish(
        MarketId id,
        uint64 tournamentId,
        uint64 investment,
        uint32 expiry,
        bytes calldata priceUpdate
    ) external payable;

    /**
     * @dev Called to open a bullish position on a market
     *
     * @param id the identifier of market to open position in
     * @param tournamentId the participating tournament identifier
     * @param investment the amount to invest
     * @param expiry the option expiry in seconds after openning
     * @param priceUpdate the pyth network price update data
     */
    function bullish(
        MarketId id,
        uint64 tournamentId,
        uint64 investment,
        uint32 expiry,
        bytes calldata priceUpdate
    ) external payable;

    /**
     * @dev Allow anyone to excercise the option at expiration
     *
     * @param id the market identifier
     * @param tournamentId tournament identifier
     * @param account the position owner address
     * @param priceUpdate the pyth network price update data
     */
    function settle(MarketId id, uint64 tournamentId, address account, bytes calldata priceUpdate) external payable;

    /**
     * @dev Allow anyone to signup as entrants to tournament
     *
     * @param tournamentId the tournament identifier
     */
    function signup(uint256 tournamentId) external payable;

    /**
     * @dev Caller can refill their depleted tournament balance, if they are
     * eligible and the tournaments permits
     *
     * @param tournamentId the tournament identifier
     */
    function refill(uint256 tournamentId) external payable;

    /**
     * @dev Allow anyone to claim pending reward for the reward account
     *
     * @param tournamentId the tournament identifier
     * @param proof the merkle leaf sibling hashes
     * @param index the leaf index
     * @param account the account addresss reward is accrued to
     * @param amount the amount to claim
     */
    function claim(
        uint256 tournamentId,
        bytes32[] memory proof,
        uint256 index,
        address account,
        uint256 amount
    ) external;
}
