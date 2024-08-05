// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

library Errors {
    /// @notice Revert when insufficient fee is provided
    error InsufficientFee();

    /// @notice Revert when trying to use amount greater than your deposited balance
    error InsufficientBalance();

    /// @notice Revert if fee exceeds maximum allowed
    error FeeExceedsMaximum();

    /// @notice Revert when trying to open position with amount less than minimum allowed
    error CannotInvestLessThan(uint64 amount);

    /// @notice Revert when trying to open a position double position in a market
    error PositionAlreadyExist();

    /// @dev Revert if the market has been created before
    error MarketAlreadyExist();

    /// @notice Revert when trying to interact with non-existing market
    error MarketDoesNotExist();

    ///@notice Revert when trying to interact with a paused market
    error MarketPaused();

    /// @notice Revert when trying to settle non existing position
    error PositionNotFound();

    /// @notice Revert if the user has claimed reward before
    error RewardClaimed();

    /// @notice Revert if the market reward is greater than 100%
    error RewardExceedsMax();

    /// @notice Revert when trying to unpause a market not paused
    error MarketNotPaused();

    /// @notice Revert if the tournament is not valid
    error InvalidTournament();

    /// @notice Revert if the tornament has ended
    error TournamentEnded();

    /// @notice Revert if the user is trying to re-register for a tournament
    error AlreadySignedUp();

    /// @notice Revert if the user has not signed up for tournament but tried to refill
    error NotSignedUp();

    /// @notice Revert if the user provided invalid merkle proof
    error InvalidMerkleProof();

    /// @notice Revert if the user cannot refill at the moment
    error CannotRefill();

    /// @notice Revert if user has reached tournament max refilling count
    error MaxRefillReached();

    /// @notice Revert if the tournament has not ended yet
    error TournamentNotFinalized();

    /// @notice Revert if trying to finalize tournament too early
    error TournamentOngoing();

    /// @notice Revert when trying to claim fee of tournament unathorized
    error OnlyCreatorCanCollectFees();

    /// @notice Revert if fee has been claimed already
    error FeeClaimed();

    /// @notice Revert if entry to tournament is yet open or closed
    error EntryNotAllowed();

    /// @notice Revert if user provides invalid expiry for option
    error InvalidExpiryInterval();

    /// @notice Revert if user does not provide enough value to cover prize pool
    error InsufficientRewardFund();

    /// @notice Revert if invalid time config is provided
    error InvalidTimeConfig();
}
