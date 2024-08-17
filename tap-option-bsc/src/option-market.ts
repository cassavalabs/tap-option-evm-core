import {
  AdjustMarketExpiry as AdjustMarketExpiryEvent,
  AdjustMarketReward as AdjustMarketRewardEvent,
  Bearish as BearishEvent,
  Bullish as BullishEvent,
  Claim as ClaimEvent,
  CollectFees as CollectFeesEvent,
  CreateMarket as CreateMarketEvent,
  ExtendTournament as ExtendTournamentEvent,
  GrantOperatorRole as GrantOperatorRoleEvent,
  OwnershipTransferred as OwnershipTransferredEvent,
  Pause as PauseEvent,
  Purge as PurgeEvent,
  RecoverToken as RecoverTokenEvent,
  Refill as RefillEvent,
  RevokeOperatorRole as RevokeOperatorRoleEvent,
  Settle as SettleEvent,
  SettleTournament as SettleTournamentEvent,
  SignUp as SignUpEvent,
  StartTournament as StartTournamentEvent,
  UnPause as UnPauseEvent
} from "../generated/OptionMarket/OptionMarket"
import {
  AdjustMarketExpiry,
  AdjustMarketReward,
  Bearish,
  Bullish,
  Claim,
  CollectFees,
  CreateMarket,
  ExtendTournament,
  GrantOperatorRole,
  OwnershipTransferred,
  Pause,
  Purge,
  RecoverToken,
  Refill,
  RevokeOperatorRole,
  Settle,
  SettleTournament,
  SignUp,
  StartTournament,
  UnPause
} from "../generated/schema"

export function handleAdjustMarketExpiry(event: AdjustMarketExpiryEvent): void {
  let entity = new AdjustMarketExpiry(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.OptionMarket_id = event.params.id
  entity.minExpiry = event.params.minExpiry
  entity.maxExpiry = event.params.maxExpiry

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleAdjustMarketReward(event: AdjustMarketRewardEvent): void {
  let entity = new AdjustMarketReward(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.OptionMarket_id = event.params.id
  entity.reward = event.params.reward

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleBearish(event: BearishEvent): void {
  let entity = new Bearish(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.OptionMarket_id = event.params.id
  entity.tournamentId = event.params.tournamentId
  entity.account = event.params.account
  entity.positionId = event.params.positionId
  entity.expiry = event.params.expiry
  entity.stake = event.params.stake
  entity.price = event.params.price

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleBullish(event: BullishEvent): void {
  let entity = new Bullish(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.OptionMarket_id = event.params.id
  entity.tournamentId = event.params.tournamentId
  entity.account = event.params.account
  entity.positionId = event.params.positionId
  entity.expiry = event.params.expiry
  entity.stake = event.params.stake
  entity.price = event.params.price

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleClaim(event: ClaimEvent): void {
  let entity = new Claim(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.tournamentId = event.params.tournamentId
  entity.account = event.params.account
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleCollectFees(event: CollectFeesEvent): void {
  let entity = new CollectFees(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.collector = event.params.collector
  entity.recipient = event.params.recipient
  entity.token = event.params.token
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleCreateMarket(event: CreateMarketEvent): void {
  let entity = new CreateMarket(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.OptionMarket_id = event.params.id
  entity.creator = event.params.creator
  entity.reward = event.params.reward
  entity.minInterval = event.params.minInterval
  entity.maxInterval = event.params.maxInterval

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleExtendTournament(event: ExtendTournamentEvent): void {
  let entity = new ExtendTournament(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.tournamentId = event.params.tournamentId
  entity.endTime = event.params.endTime

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleGrantOperatorRole(event: GrantOperatorRoleEvent): void {
  let entity = new GrantOperatorRole(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.account = event.params.account

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleOwnershipTransferred(
  event: OwnershipTransferredEvent
): void {
  let entity = new OwnershipTransferred(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.prevOwner = event.params.prevOwner
  entity.newOwner = event.params.newOwner

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handlePause(event: PauseEvent): void {
  let entity = new Pause(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.OptionMarket_id = event.params.id

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handlePurge(event: PurgeEvent): void {
  let entity = new Purge(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.OptionMarket_id = event.params.id
  entity.tournamentId = event.params.tournamentId
  entity.account = event.params.account
  entity.positionId = event.params.positionId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleRecoverToken(event: RecoverTokenEvent): void {
  let entity = new RecoverToken(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.currency = event.params.currency
  entity.recipient = event.params.recipient
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleRefill(event: RefillEvent): void {
  let entity = new Refill(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.tournamentId = event.params.tournamentId
  entity.account = event.params.account

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleRevokeOperatorRole(event: RevokeOperatorRoleEvent): void {
  let entity = new RevokeOperatorRole(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.account = event.params.account

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleSettle(event: SettleEvent): void {
  let entity = new Settle(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.OptionMarket_id = event.params.id
  entity.tournamentId = event.params.tournamentId
  entity.account = event.params.account
  entity.positionId = event.params.positionId
  entity.reward = event.params.reward
  entity.closingPrice = event.params.closingPrice

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleSettleTournament(event: SettleTournamentEvent): void {
  let entity = new SettleTournament(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.tournamentId = event.params.tournamentId
  entity.operator = event.params.operator
  entity.merkleRoot = event.params.merkleRoot

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleSignUp(event: SignUpEvent): void {
  let entity = new SignUp(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.tournamentId = event.params.tournamentId
  entity.account = event.params.account

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleStartTournament(event: StartTournamentEvent): void {
  let entity = new StartTournament(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.tournamentId = event.params.tournamentId
  entity.initiator = event.params.initiator
  entity.currency = event.params.currency
  entity.prizePool = event.params.prizePool
  entity.entryFee = event.params.entryFee
  entity.winners = event.params.winners
  entity.startTime = event.params.startTime
  entity.endTime = event.params.endTime
  entity.lot = event.params.lot
  entity.title = event.params.title

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleUnPause(event: UnPauseEvent): void {
  let entity = new UnPause(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.OptionMarket_id = event.params.id

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
