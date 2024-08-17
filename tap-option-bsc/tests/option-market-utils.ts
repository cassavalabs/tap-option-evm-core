import { newMockEvent } from "matchstick-as"
import { ethereum, Bytes, BigInt, Address } from "@graphprotocol/graph-ts"
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
} from "../generated/OptionMarket/OptionMarket"

export function createAdjustMarketExpiryEvent(
  id: Bytes,
  minExpiry: BigInt,
  maxExpiry: BigInt
): AdjustMarketExpiry {
  let adjustMarketExpiryEvent = changetype<AdjustMarketExpiry>(newMockEvent())

  adjustMarketExpiryEvent.parameters = new Array()

  adjustMarketExpiryEvent.parameters.push(
    new ethereum.EventParam("id", ethereum.Value.fromFixedBytes(id))
  )
  adjustMarketExpiryEvent.parameters.push(
    new ethereum.EventParam(
      "minExpiry",
      ethereum.Value.fromUnsignedBigInt(minExpiry)
    )
  )
  adjustMarketExpiryEvent.parameters.push(
    new ethereum.EventParam(
      "maxExpiry",
      ethereum.Value.fromUnsignedBigInt(maxExpiry)
    )
  )

  return adjustMarketExpiryEvent
}

export function createAdjustMarketRewardEvent(
  id: Bytes,
  reward: i32
): AdjustMarketReward {
  let adjustMarketRewardEvent = changetype<AdjustMarketReward>(newMockEvent())

  adjustMarketRewardEvent.parameters = new Array()

  adjustMarketRewardEvent.parameters.push(
    new ethereum.EventParam("id", ethereum.Value.fromFixedBytes(id))
  )
  adjustMarketRewardEvent.parameters.push(
    new ethereum.EventParam(
      "reward",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(reward))
    )
  )

  return adjustMarketRewardEvent
}

export function createBearishEvent(
  id: Bytes,
  tournamentId: BigInt,
  account: Address,
  positionId: Bytes,
  expiry: BigInt,
  stake: BigInt,
  price: BigInt
): Bearish {
  let bearishEvent = changetype<Bearish>(newMockEvent())

  bearishEvent.parameters = new Array()

  bearishEvent.parameters.push(
    new ethereum.EventParam("id", ethereum.Value.fromFixedBytes(id))
  )
  bearishEvent.parameters.push(
    new ethereum.EventParam(
      "tournamentId",
      ethereum.Value.fromUnsignedBigInt(tournamentId)
    )
  )
  bearishEvent.parameters.push(
    new ethereum.EventParam("account", ethereum.Value.fromAddress(account))
  )
  bearishEvent.parameters.push(
    new ethereum.EventParam(
      "positionId",
      ethereum.Value.fromFixedBytes(positionId)
    )
  )
  bearishEvent.parameters.push(
    new ethereum.EventParam("expiry", ethereum.Value.fromUnsignedBigInt(expiry))
  )
  bearishEvent.parameters.push(
    new ethereum.EventParam("stake", ethereum.Value.fromUnsignedBigInt(stake))
  )
  bearishEvent.parameters.push(
    new ethereum.EventParam("price", ethereum.Value.fromSignedBigInt(price))
  )

  return bearishEvent
}

export function createBullishEvent(
  id: Bytes,
  tournamentId: BigInt,
  account: Address,
  positionId: Bytes,
  expiry: BigInt,
  stake: BigInt,
  price: BigInt
): Bullish {
  let bullishEvent = changetype<Bullish>(newMockEvent())

  bullishEvent.parameters = new Array()

  bullishEvent.parameters.push(
    new ethereum.EventParam("id", ethereum.Value.fromFixedBytes(id))
  )
  bullishEvent.parameters.push(
    new ethereum.EventParam(
      "tournamentId",
      ethereum.Value.fromUnsignedBigInt(tournamentId)
    )
  )
  bullishEvent.parameters.push(
    new ethereum.EventParam("account", ethereum.Value.fromAddress(account))
  )
  bullishEvent.parameters.push(
    new ethereum.EventParam(
      "positionId",
      ethereum.Value.fromFixedBytes(positionId)
    )
  )
  bullishEvent.parameters.push(
    new ethereum.EventParam("expiry", ethereum.Value.fromUnsignedBigInt(expiry))
  )
  bullishEvent.parameters.push(
    new ethereum.EventParam("stake", ethereum.Value.fromUnsignedBigInt(stake))
  )
  bullishEvent.parameters.push(
    new ethereum.EventParam("price", ethereum.Value.fromSignedBigInt(price))
  )

  return bullishEvent
}

export function createClaimEvent(
  tournamentId: BigInt,
  account: Address,
  amount: BigInt
): Claim {
  let claimEvent = changetype<Claim>(newMockEvent())

  claimEvent.parameters = new Array()

  claimEvent.parameters.push(
    new ethereum.EventParam(
      "tournamentId",
      ethereum.Value.fromUnsignedBigInt(tournamentId)
    )
  )
  claimEvent.parameters.push(
    new ethereum.EventParam("account", ethereum.Value.fromAddress(account))
  )
  claimEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return claimEvent
}

export function createCollectFeesEvent(
  collector: Address,
  recipient: Address,
  token: Address,
  amount: BigInt
): CollectFees {
  let collectFeesEvent = changetype<CollectFees>(newMockEvent())

  collectFeesEvent.parameters = new Array()

  collectFeesEvent.parameters.push(
    new ethereum.EventParam("collector", ethereum.Value.fromAddress(collector))
  )
  collectFeesEvent.parameters.push(
    new ethereum.EventParam("recipient", ethereum.Value.fromAddress(recipient))
  )
  collectFeesEvent.parameters.push(
    new ethereum.EventParam("token", ethereum.Value.fromAddress(token))
  )
  collectFeesEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return collectFeesEvent
}

export function createCreateMarketEvent(
  id: Bytes,
  creator: Address,
  reward: i32,
  minInterval: BigInt,
  maxInterval: BigInt
): CreateMarket {
  let createMarketEvent = changetype<CreateMarket>(newMockEvent())

  createMarketEvent.parameters = new Array()

  createMarketEvent.parameters.push(
    new ethereum.EventParam("id", ethereum.Value.fromFixedBytes(id))
  )
  createMarketEvent.parameters.push(
    new ethereum.EventParam("creator", ethereum.Value.fromAddress(creator))
  )
  createMarketEvent.parameters.push(
    new ethereum.EventParam(
      "reward",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(reward))
    )
  )
  createMarketEvent.parameters.push(
    new ethereum.EventParam(
      "minInterval",
      ethereum.Value.fromUnsignedBigInt(minInterval)
    )
  )
  createMarketEvent.parameters.push(
    new ethereum.EventParam(
      "maxInterval",
      ethereum.Value.fromUnsignedBigInt(maxInterval)
    )
  )

  return createMarketEvent
}

export function createExtendTournamentEvent(
  tournamentId: BigInt,
  endTime: BigInt
): ExtendTournament {
  let extendTournamentEvent = changetype<ExtendTournament>(newMockEvent())

  extendTournamentEvent.parameters = new Array()

  extendTournamentEvent.parameters.push(
    new ethereum.EventParam(
      "tournamentId",
      ethereum.Value.fromUnsignedBigInt(tournamentId)
    )
  )
  extendTournamentEvent.parameters.push(
    new ethereum.EventParam(
      "endTime",
      ethereum.Value.fromUnsignedBigInt(endTime)
    )
  )

  return extendTournamentEvent
}

export function createGrantOperatorRoleEvent(
  account: Address
): GrantOperatorRole {
  let grantOperatorRoleEvent = changetype<GrantOperatorRole>(newMockEvent())

  grantOperatorRoleEvent.parameters = new Array()

  grantOperatorRoleEvent.parameters.push(
    new ethereum.EventParam("account", ethereum.Value.fromAddress(account))
  )

  return grantOperatorRoleEvent
}

export function createOwnershipTransferredEvent(
  prevOwner: Address,
  newOwner: Address
): OwnershipTransferred {
  let ownershipTransferredEvent = changetype<OwnershipTransferred>(
    newMockEvent()
  )

  ownershipTransferredEvent.parameters = new Array()

  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam("prevOwner", ethereum.Value.fromAddress(prevOwner))
  )
  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam("newOwner", ethereum.Value.fromAddress(newOwner))
  )

  return ownershipTransferredEvent
}

export function createPauseEvent(id: Bytes): Pause {
  let pauseEvent = changetype<Pause>(newMockEvent())

  pauseEvent.parameters = new Array()

  pauseEvent.parameters.push(
    new ethereum.EventParam("id", ethereum.Value.fromFixedBytes(id))
  )

  return pauseEvent
}

export function createPurgeEvent(
  id: Bytes,
  tournamentId: BigInt,
  account: Address,
  positionId: Bytes
): Purge {
  let purgeEvent = changetype<Purge>(newMockEvent())

  purgeEvent.parameters = new Array()

  purgeEvent.parameters.push(
    new ethereum.EventParam("id", ethereum.Value.fromFixedBytes(id))
  )
  purgeEvent.parameters.push(
    new ethereum.EventParam(
      "tournamentId",
      ethereum.Value.fromUnsignedBigInt(tournamentId)
    )
  )
  purgeEvent.parameters.push(
    new ethereum.EventParam("account", ethereum.Value.fromAddress(account))
  )
  purgeEvent.parameters.push(
    new ethereum.EventParam(
      "positionId",
      ethereum.Value.fromFixedBytes(positionId)
    )
  )

  return purgeEvent
}

export function createRecoverTokenEvent(
  currency: Address,
  recipient: Address,
  amount: BigInt
): RecoverToken {
  let recoverTokenEvent = changetype<RecoverToken>(newMockEvent())

  recoverTokenEvent.parameters = new Array()

  recoverTokenEvent.parameters.push(
    new ethereum.EventParam("currency", ethereum.Value.fromAddress(currency))
  )
  recoverTokenEvent.parameters.push(
    new ethereum.EventParam("recipient", ethereum.Value.fromAddress(recipient))
  )
  recoverTokenEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return recoverTokenEvent
}

export function createRefillEvent(
  tournamentId: BigInt,
  account: Address
): Refill {
  let refillEvent = changetype<Refill>(newMockEvent())

  refillEvent.parameters = new Array()

  refillEvent.parameters.push(
    new ethereum.EventParam(
      "tournamentId",
      ethereum.Value.fromUnsignedBigInt(tournamentId)
    )
  )
  refillEvent.parameters.push(
    new ethereum.EventParam("account", ethereum.Value.fromAddress(account))
  )

  return refillEvent
}

export function createRevokeOperatorRoleEvent(
  account: Address
): RevokeOperatorRole {
  let revokeOperatorRoleEvent = changetype<RevokeOperatorRole>(newMockEvent())

  revokeOperatorRoleEvent.parameters = new Array()

  revokeOperatorRoleEvent.parameters.push(
    new ethereum.EventParam("account", ethereum.Value.fromAddress(account))
  )

  return revokeOperatorRoleEvent
}

export function createSettleEvent(
  id: Bytes,
  tournamentId: BigInt,
  account: Address,
  positionId: Bytes,
  reward: BigInt,
  closingPrice: BigInt
): Settle {
  let settleEvent = changetype<Settle>(newMockEvent())

  settleEvent.parameters = new Array()

  settleEvent.parameters.push(
    new ethereum.EventParam("id", ethereum.Value.fromFixedBytes(id))
  )
  settleEvent.parameters.push(
    new ethereum.EventParam(
      "tournamentId",
      ethereum.Value.fromUnsignedBigInt(tournamentId)
    )
  )
  settleEvent.parameters.push(
    new ethereum.EventParam("account", ethereum.Value.fromAddress(account))
  )
  settleEvent.parameters.push(
    new ethereum.EventParam(
      "positionId",
      ethereum.Value.fromFixedBytes(positionId)
    )
  )
  settleEvent.parameters.push(
    new ethereum.EventParam("reward", ethereum.Value.fromUnsignedBigInt(reward))
  )
  settleEvent.parameters.push(
    new ethereum.EventParam(
      "closingPrice",
      ethereum.Value.fromSignedBigInt(closingPrice)
    )
  )

  return settleEvent
}

export function createSettleTournamentEvent(
  tournamentId: BigInt,
  operator: Address,
  merkleRoot: Bytes
): SettleTournament {
  let settleTournamentEvent = changetype<SettleTournament>(newMockEvent())

  settleTournamentEvent.parameters = new Array()

  settleTournamentEvent.parameters.push(
    new ethereum.EventParam(
      "tournamentId",
      ethereum.Value.fromUnsignedBigInt(tournamentId)
    )
  )
  settleTournamentEvent.parameters.push(
    new ethereum.EventParam("operator", ethereum.Value.fromAddress(operator))
  )
  settleTournamentEvent.parameters.push(
    new ethereum.EventParam(
      "merkleRoot",
      ethereum.Value.fromFixedBytes(merkleRoot)
    )
  )

  return settleTournamentEvent
}

export function createSignUpEvent(
  tournamentId: BigInt,
  account: Address
): SignUp {
  let signUpEvent = changetype<SignUp>(newMockEvent())

  signUpEvent.parameters = new Array()

  signUpEvent.parameters.push(
    new ethereum.EventParam(
      "tournamentId",
      ethereum.Value.fromUnsignedBigInt(tournamentId)
    )
  )
  signUpEvent.parameters.push(
    new ethereum.EventParam("account", ethereum.Value.fromAddress(account))
  )

  return signUpEvent
}

export function createStartTournamentEvent(
  tournamentId: BigInt,
  initiator: Address,
  currency: Address,
  prizePool: BigInt,
  entryFee: BigInt,
  winners: BigInt,
  startTime: BigInt,
  endTime: BigInt,
  lot: BigInt,
  title: string
): StartTournament {
  let startTournamentEvent = changetype<StartTournament>(newMockEvent())

  startTournamentEvent.parameters = new Array()

  startTournamentEvent.parameters.push(
    new ethereum.EventParam(
      "tournamentId",
      ethereum.Value.fromUnsignedBigInt(tournamentId)
    )
  )
  startTournamentEvent.parameters.push(
    new ethereum.EventParam("initiator", ethereum.Value.fromAddress(initiator))
  )
  startTournamentEvent.parameters.push(
    new ethereum.EventParam("currency", ethereum.Value.fromAddress(currency))
  )
  startTournamentEvent.parameters.push(
    new ethereum.EventParam(
      "prizePool",
      ethereum.Value.fromUnsignedBigInt(prizePool)
    )
  )
  startTournamentEvent.parameters.push(
    new ethereum.EventParam(
      "entryFee",
      ethereum.Value.fromUnsignedBigInt(entryFee)
    )
  )
  startTournamentEvent.parameters.push(
    new ethereum.EventParam(
      "winners",
      ethereum.Value.fromUnsignedBigInt(winners)
    )
  )
  startTournamentEvent.parameters.push(
    new ethereum.EventParam(
      "startTime",
      ethereum.Value.fromUnsignedBigInt(startTime)
    )
  )
  startTournamentEvent.parameters.push(
    new ethereum.EventParam(
      "endTime",
      ethereum.Value.fromUnsignedBigInt(endTime)
    )
  )
  startTournamentEvent.parameters.push(
    new ethereum.EventParam("lot", ethereum.Value.fromUnsignedBigInt(lot))
  )
  startTournamentEvent.parameters.push(
    new ethereum.EventParam("title", ethereum.Value.fromString(title))
  )

  return startTournamentEvent
}

export function createUnPauseEvent(id: Bytes): UnPause {
  let unPauseEvent = changetype<UnPause>(newMockEvent())

  unPauseEvent.parameters = new Array()

  unPauseEvent.parameters.push(
    new ethereum.EventParam("id", ethereum.Value.fromFixedBytes(id))
  )

  return unPauseEvent
}
