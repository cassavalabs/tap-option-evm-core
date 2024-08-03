// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.23;

interface IPyth {
    /**
     * @notice A price with a degree of uncertainty, represented as a price +- a confidence interval.
     *
     * The confidence interval roughly corresponds to the standard error of a normal distribution.
     * Both the price and confidence are stored in a fixed-point numeric representation,
     * `x * (10^expo)`, where `expo` is the exponent.
     *
     * Please refer to the documentation at https://docs.pyth.network/documentation/pythnet-price-feeds/best-practices for how
     * to how this price safely.
     */
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint256 publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }

    /**
     * @notice Update price feeds with given update messages.
     * This method requires the caller to pay a fee in wei; the required fee can be computed by calling
     * `getUpdateFee` with the length of the `updateData` array.
     * Prices will be updated if they are more recent than the current stored prices.
     * The call will succeed even if the update is not the most recent.
     * @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
     * @param updateData Array of price update data.
     */
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /**
     *
     * @notice Returns the required fee to update an array of price updates.
     * @param updateData Array of price update data.
     * @return feeAmount The required fee in Wei.
     */
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint256 feeAmount);

    /**
     * @notice Returns the price and confidence interval.
     * @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
     * @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
     * @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
     */
    function getPrice(bytes32 id) external view returns (Price memory price);

    /**
     * @notice Returns the price that is no older than `age` seconds of the current time.
     * @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
     * applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
     * recently.
     * @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
     */
    function getPriceNoOlderThan(
        bytes32 id,
        uint256 age
    ) external view returns (Price memory price);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method may store the price updates on-chain, if they
    /// are more recent than the current stored prices.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PriceFeed[] memory priceFeeds);

    /**
     * @notice Similar to `parsePriceFeedUpdates` but ensures the updates returned are
     * the first updates published in minPublishTime. That is, if there are multiple updates for a given timestamp,
     * this method will return the first update.
     *
     *
     * @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
     * no update for any of the given `priceIds` within the given time range and uniqueness condition.
     * @param updateData Array of price update data.
     * @param priceIds Array of price ids.
     * @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
     * @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
     * @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
     */
    function parsePriceFeedUpdatesUnique(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PriceFeed[] memory priceFeeds);
}
