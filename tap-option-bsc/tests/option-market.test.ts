import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { Bytes, BigInt, Address } from "@graphprotocol/graph-ts"
import { AdjustMarketExpiry } from "../generated/schema"
import { AdjustMarketExpiry as AdjustMarketExpiryEvent } from "../generated/OptionMarket/OptionMarket"
import { handleAdjustMarketExpiry } from "../src/option-market"
import { createAdjustMarketExpiryEvent } from "./option-market-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let id = Bytes.fromI32(1234567890)
    let minExpiry = BigInt.fromI32(234)
    let maxExpiry = BigInt.fromI32(234)
    let newAdjustMarketExpiryEvent = createAdjustMarketExpiryEvent(
      id,
      minExpiry,
      maxExpiry
    )
    handleAdjustMarketExpiry(newAdjustMarketExpiryEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("AdjustMarketExpiry created and stored", () => {
    assert.entityCount("AdjustMarketExpiry", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "AdjustMarketExpiry",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "minExpiry",
      "234"
    )
    assert.fieldEquals(
      "AdjustMarketExpiry",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "maxExpiry",
      "234"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
