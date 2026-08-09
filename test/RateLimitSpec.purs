-- | Rate limiting tests — pure seams only, no clock or Ref I/O.
-- | `shouldAllow` takes one record (swappable same-typed params would be a
-- | silent footgun); `pruneExpired` bounds the in-memory map size.
module Test.RateLimitSpec where

import Prelude

import App.RateLimit (RateDecision(..), Window(..), pruneExpired, remainingMs, shouldAllow)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)

base :: { limit :: Int, windowMs :: Number, nowMs :: Number }
base = { limit: 3, windowMs: 60000.0, nowMs: 2000.0 }

spec :: Spec Unit
spec = do
  describe "App.RateLimit shouldAllow" do
    it "allows the first request and starts a window" do
      shouldAllow { limit: 20, windowMs: 60000.0, nowMs: 1000.0 } Nothing
        `shouldEqual` Allow (Window { count: 1, startedAt: 1000.0 })

    it "allows up to the limit and increments the count" do
      shouldAllow base (Just (Window { count: 2, startedAt: 1000.0 }))
        `shouldEqual` Allow (Window { count: 3, startedAt: 1000.0 })

    it "denies the request that would exceed the limit" do
      shouldAllow base (Just (Window { count: 3, startedAt: 1000.0 }))
        `shouldEqual` Deny (Window { count: 3, startedAt: 1000.0 })

    it "denied requests do not increment the count" do
      let
        decision = shouldAllow { limit: 2, windowMs: 60000.0, nowMs: 2000.0 } (Just (Window { count: 2, startedAt: 1000.0 }))
      case decision of
        Deny w1 -> shouldAllow { limit: 2, windowMs: 60000.0, nowMs: 3000.0 } (Just w1)
          `shouldEqual` Deny (Window { count: 2, startedAt: 1000.0 })
        Allow _ -> pure unit

    it "resets the window when it has expired" do
      shouldAllow { limit: 3, windowMs: 60000.0, nowMs: 62000.0 } (Just (Window { count: 3, startedAt: 1000.0 }))
        `shouldEqual` Allow (Window { count: 1, startedAt: 62000.0 })

    it "resets exactly at the expiry boundary (>=)" do
      shouldAllow { limit: 1, windowMs: 60000.0, nowMs: 61000.0 } (Just (Window { count: 1, startedAt: 1000.0 }))
        `shouldEqual` Allow (Window { count: 1, startedAt: 61000.0 })

    it "does not reset just before the boundary" do
      shouldAllow { limit: 1, windowMs: 60000.0, nowMs: 60999.0 } (Just (Window { count: 1, startedAt: 1000.0 }))
        `shouldEqual` Deny (Window { count: 1, startedAt: 1000.0 })

    it "consecutive calls thread their returned window" do
      let
        decision1 = shouldAllow { limit: 2, windowMs: 60000.0, nowMs: 0.0 } Nothing
      case decision1 of
        Allow w1 ->
          let
            decision2 = shouldAllow { limit: 2, windowMs: 60000.0, nowMs: 1.0 } (Just w1)
          in
            case decision2 of
              Allow w2 ->
                let
                  decision3 = shouldAllow { limit: 2, windowMs: 60000.0, nowMs: 2.0 } (Just w2)
                in
                  case decision3 of
                    Deny _ -> pure unit
                    Allow _ -> flip (shouldEqual) (Deny (Window { count: 2, startedAt: 0.0 })) decision3
              Deny _ -> pure unit
        Deny _ -> pure unit

  describe "App.RateLimit pruneExpired" do
    it "drops windows whose lifetime has elapsed" do
      let
        m = Map.insert "old" (Window { count: 5, startedAt: 1000.0 }) Map.empty
      pruneExpired 60000.0 70000.0 m `shouldEqual` Map.empty

    it "keeps windows still within their lifetime" do
      let
        w = Window { count: 5, startedAt: 1000.0 }
        m = Map.insert "fresh" w Map.empty
      pruneExpired 60000.0 60999.0 m `shouldEqual` m

    it "prunes per-key, not globally" do
      let
        stale = Window { count: 9, startedAt: 0.0 }
        fresh = Window { count: 1, startedAt: 50000.0 }
        m = Map.insert "stale" stale (Map.insert "fresh" fresh Map.empty)
        pruned = pruneExpired 60000.0 61000.0 m
      Map.lookup "stale" pruned `shouldEqual` Nothing
      Map.lookup "fresh" pruned `shouldEqual` Just fresh

  describe "App.RateLimit remainingMs" do
    it "reports window time left" do
      remainingMs 60000.0 20000.0 (Window { count: 3, startedAt: 0.0 })
        `shouldEqual` 40000.0

    it "reports the last second of a window, not a fresh full window" do
      remainingMs 60000.0 59900.0 (Window { count: 5, startedAt: 0.0 })
        `shouldEqual` 100.0

    it "clamps to zero on clock jitter" do
      remainingMs 60000.0 70000.0 (Window { count: 1, startedAt: 0.0 })
        `shouldEqual` 0.0
