import { BigDecimal, BigInt } from "@graphprotocol/graph-ts";
import {
  AdjustMarketExpiry as AdjustMarketExpiryEvent,
  AdjustMarketReward as AdjustMarketRewardEvent,
  Bearish as BearishEvent,
  Bullish as BullishEvent,
  Claim as ClaimEvent,
  CreateMarket as CreateMarketEvent,
  ExtendTournament as ExtendTournamentEvent,
  Pause as PauseEvent,
  Purge as PurgeEvent,
  Refill as RefillEvent,
  Settle as SettleEvent,
  SettleTournament as SettleTournamentEvent,
  SignUp as SignUpEvent,
  StartTournament as StartTournamentEvent,
  UnPause as UnPauseEvent,
} from "../generated/OptionMarket/OptionMarket";
import { Account, LeaderBoard, Market, Position, Tournament } from "../generated/schema";

let ONE_BI = BigInt.fromI32(1);
let ZERO_BI = BigInt.fromI32(0);
let ZERO_BD = BigDecimal.fromString("0");
let LOT_AMOUNT_BD = BigDecimal.fromString("100");

export function handleAdjustMarketExpiry(event: AdjustMarketExpiryEvent): void {
  let market = Market.load(event.params.id.toHexString());

  if (market) {
    market.minExpiry = event.params.minExpiry;
    market.maxExpiry = event.params.maxExpiry;

    market.save();
  }
}

export function handleAdjustMarketReward(event: AdjustMarketRewardEvent): void {
  let market = Market.load(event.params.id.toHexString());

  if (market) {
    market.reward = BigInt.fromU64(event.params.reward);
    market.save();
  }
}

export function handleBearish(event: BearishEvent): void {
  let positionId = event.params.positionId.toHexString();
  let position = Position.load(positionId);

  if (!position) {
    position = new Position(positionId);
    position.account = event.params.account.toHexString();
    position.closingPrice = ZERO_BI;
    position.createdAt = event.block.timestamp;
    position.expiryTime = event.params.expiry;
    position.investment = event.params.stake.toBigDecimal();
    position.isExcersized = false;
    position.market = event.params.id.toHexString();
    position.option = "LOW";
    position.profit = ZERO_BD;
    position.strikePrice = event.params.price;
    position.tournament = event.params.tournamentId.toHexString();

    position.save();
  }

  let leaderboard = LeaderBoard.load(
    event.params.tournamentId.toHexString().concat("#").concat(event.params.account.toHexString()),
  );

  if (leaderboard) {
    leaderboard.openPositions = leaderboard.openPositions.plus(ONE_BI);
    leaderboard.totalPositions = leaderboard.totalPositions.plus(ONE_BI);
    leaderboard.save();
  }
}

export function handleBullish(event: BullishEvent): void {
  let positionId = event.params.positionId.toHexString();
  let position = Position.load(positionId);

  if (!position) {
    position = new Position(positionId);
    position.account = event.params.account.toHexString();
    position.closingPrice = ZERO_BI;
    position.createdAt = event.block.timestamp;
    position.expiryTime = event.params.expiry;
    position.investment = event.params.stake.toBigDecimal();
    position.isExcersized = false;
    position.market = event.params.id.toHexString();
    position.option = "HIGH";
    position.profit = ZERO_BD;
    position.strikePrice = event.params.price;
    position.tournament = event.params.tournamentId.toHexString();

    position.save();
  }

  let leaderboard = LeaderBoard.load(
    event.params.tournamentId.toHexString().concat("#").concat(event.params.account.toHexString()),
  );

  if (leaderboard) {
    leaderboard.openPositions = leaderboard.openPositions.plus(ONE_BI);
    leaderboard.totalPositions = leaderboard.totalPositions.plus(ONE_BI);
    leaderboard.save();
  }
}

export function handleClaim(event: ClaimEvent): void {
  let leaderboardId = event.params.tournamentId.toHexString().concat("#").concat(event.params.account.toHexString());
  let leaderboard = LeaderBoard.load(leaderboardId);

  if (leaderboard) {
    leaderboard.rewardAmountClaimed = event.params.amount.toBigDecimal();
    leaderboard.save();
  }
}

export function handleCreateMarket(event: CreateMarketEvent): void {
  let market = Market.load(event.params.id.toHexString());

  if (!market) {
    market = new Market(event.params.id.toHexString());
    market.createdAt = event.block.timestamp;
    market.createdAtBlockNumber = event.block.number;
    market.maxExpiry = event.params.maxInterval;
    market.minExpiry = event.params.minInterval;
    market.paused = false;
    market.reward = BigInt.fromI32(event.params.reward);

    market.save();
  }
}

export function handleExtendTournament(event: ExtendTournamentEvent): void {
  let tournament = Tournament.load(event.params.tournamentId.toHexString());

  if (tournament) {
    tournament.closingTime = event.params.endTime;
    tournament.save();
  }
}

export function handlePause(event: PauseEvent): void {
  let market = Market.load(event.params.id.toHexString());

  if (market) {
    market.paused = true;
    market.save();
  }
}

export function handlePurge(event: PurgeEvent): void {
  let position = Position.load(event.params.positionId.toHexString());

  if (position) {
    position.isExcersized = true;
    position.save();
  }
}

export function handleRefill(event: RefillEvent): void {
  let leaderboardId = event.params.tournamentId.toHexString().concat(event.params.account.toHexString());
  let leaderboard = LeaderBoard.load(leaderboardId);

  if (leaderboard) {
    leaderboard.balance = leaderboard.balance.plus(LOT_AMOUNT_BD);
    leaderboard.rebuyCount = leaderboard.rebuyCount.plus(ONE_BI);

    leaderboard.save();
  }
}

export function handleSettle(event: SettleEvent): void {
  let position = Position.load(event.params.positionId.toHexString());

  if (position) {
    position.closingPrice = event.params.closingPrice;
    position.isExcersized = true;
    position.profit = event.params.reward.toBigDecimal();

    position.save();
  }

  let leaderboard = LeaderBoard.load(
    event.params.tournamentId.toHexString().concat("#").concat(event.params.account.toHexString()),
  );

  if (leaderboard) {
    leaderboard.balance = leaderboard.balance.plus(event.params.reward.toBigDecimal());
    leaderboard.openPositions = leaderboard.openPositions.minus(ONE_BI);

    leaderboard.save();
  }
}

export function handleSettleTournament(event: SettleTournamentEvent): void {
  let tournament = Tournament.load(event.params.tournamentId.toHexString());

  if (tournament) {
    tournament.merkleRoot = event.params.merkleRoot.toHexString();
    tournament.isFinalized = true;
    
    tournament.save();
  }
}

export function handleSignUp(event: SignUpEvent): void {
  let tournament = Tournament.load(event.params.tournamentId.toHexString());
  let account = Account.load(event.params.account.toHexString());
  let leaderboardId = event.params.tournamentId.toHexString().concat("#").concat(event.params.account.toHexString());
  let leaderboard = LeaderBoard.load(leaderboardId);

  if (tournament) {
    tournament.entrants = tournament.entrants.plus(ONE_BI);
    tournament.save();
  }

  if (!account) {
    account = new Account(event.params.account.toHexString());
    account.createdAt = event.block.timestamp;

    account.save();
  }

  if (!leaderboard && tournament) {
    leaderboard = new LeaderBoard(leaderboardId);
    leaderboard.account = event.params.account.toHexString();
    leaderboard.createdAt = event.block.timestamp;
    leaderboard.balance = tournament.lot.toBigDecimal();
    leaderboard.openPositions = ZERO_BI;
    leaderboard.rebuyCount = ZERO_BI;
    leaderboard.rewardAmountClaimed = ZERO_BD;
    leaderboard.totalPositions = ZERO_BI;
    leaderboard.tournament = event.params.tournamentId.toHexString();

    leaderboard.save();
  }
}

export function handleStartTournament(event: StartTournamentEvent): void {
  let tournament = Tournament.load(event.params.tournamentId.toHexString());

  if (!tournament) {
    tournament = new Tournament(event.params.tournamentId.toHexString());
    tournament.blockNumber = event.block.number;
    tournament.closingTime = event.params.endTime;
    tournament.createdAt = event.block.timestamp;
    tournament.currency = event.params.currency.toHexString();
    tournament.entrants = ZERO_BI;
    tournament.entryFee = event.params.entryFee.toBigDecimal();
    tournament.initiator = event.params.initiator.toHexString();
    tournament.lot = event.params.lot;
    tournament.isFinalized = false;
    tournament.merkleRoot = "";
    tournament.prizePool = event.params.prizePool.toBigDecimal();
    tournament.rebuyCount = ZERO_BI;
    tournament.startTime = event.params.startTime;
    tournament.title = event.params.title;
    tournament.winners = event.params.winners;

    tournament.save();
  }
}

export function handleUnPause(event: UnPauseEvent): void {
  let market = Market.load(event.params.id.toHexString());

  if (market) {
    market.paused = false;
    market.save();
  }
}
