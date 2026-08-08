-- | In-memory fixed-window rate limiting, keyed by client IP.
-- |
-- | Bounds: state grows one entry per distinct IP seen, hard-capped at
-- | 10 000 entries. Expired windows are pruned first; if a same-window IP-
-- | rotation flood keeps the map full, the limiter fails open — unseen IPs
-- | are allowed without recording, so the map never exceeds the cap.
-- | Behind a reverse proxy all requests share the proxy's IP and would be
-- | limited as one — a documented limitation; trusting X-Forwarded-For
-- | unconditionally would allow spoofing.
-- |
-- | The pure `shouldAllow` is the seam under unit test; `checkRateLimit`
-- | is its Effect wrapper against wall-clock time and a shared Ref.
module App.RateLimit
  ( Window(..)
  , shouldAllow
  , RateLimitParams
  , pruneExpired
  , remainingMs
  , RateLimitVerdict
  , RateLimiter
  , maxEntries
  , mkRateLimiter
  , checkRateLimit
  ) where

import Prelude

import Data.JSDate (getTime, now)
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Ref (Ref)
import Effect.Ref as Ref

-- | Window state for one key (an IP): requests seen and window start
-- | (epoch milliseconds).
newtype Window = Window { count :: Int, startedAt :: Number }

derive instance eqWindow :: Eq Window

instance showWindow :: Show Window where
  show (Window w) = "Window { count: " <> show w.count <> ", startedAt: " <> show w.startedAt <> " }"

-- | Milliseconds until `w`'s window expires at `nowMs` — the value
-- | Retry-After should carry for a denied request. The denial branch of
-- | shouldAllow implies the window is still open (else it would have
-- | reset), so the computed offset is positive; `max 0.0` just guards
-- | against clock jitter between the decision and this computation.
remainingMs :: Number -> Number -> Window -> Number
remainingMs windowMs nowMs (Window w) = max 0.0 (w.startedAt + windowMs - nowMs)

-- | Fixed-window decision.
-- | - No prior window → allow, start a fresh window (count 1).
-- | - Window expired (nowMs - startedAt >= windowMs) → allow, fresh window.
-- | - Inside window: allow iff count < limit; count increments only when
-- |   allowed (denied requests do not grow the counter).
-- | Parameters for rate limiting decision
type RateLimitParams =
  { limit :: Int
  , windowMs :: Number
  , nowMs :: Number
  }

shouldAllow :: RateLimitParams -> Maybe Window -> Tuple Boolean Window
shouldAllow { limit, windowMs, nowMs } maybeWindow =
  case maybeWindow of
    Nothing -> Tuple true (Window { count: 1, startedAt: nowMs })
    Just (Window w)
      | nowMs - w.startedAt >= windowMs ->
          Tuple true (Window { count: 1, startedAt: nowMs })
      | otherwise ->
          let
            allowed = w.count < limit
            newCount = if allowed then w.count + 1 else w.count
          in
            Tuple allowed (Window { count: newCount, startedAt: w.startedAt })

type RateLimiter = Ref (Map String Window)

mkRateLimiter :: Effect RateLimiter
mkRateLimiter = Ref.new Map.empty

-- | Hard cap on stored keys; see the module header for the fail-open rule.
maxEntries :: Int
maxEntries = 10000

-- | Drop windows whose lifetime has fully elapsed at `nowMs`.
pruneExpired :: Number -> Number -> Map String Window -> Map String Window
pruneExpired windowMs nowMs =
  Map.filterWithKey \_ (Window w) -> nowMs - w.startedAt < windowMs

-- | Result of a limit check: the decision plus, on denial, how many
-- | milliseconds remain in the current window (for Retry-After). On allow
-- | the remaining time is not meaningful (`Nothing`) — the request was let
-- | through and needs no guidance.
type RateLimitVerdict = { allowed :: Boolean, retryAfterMs :: Maybe Number }

-- | Check the limit for `key`; always writes the updated window back.
checkRateLimit :: RateLimiter -> Int -> Number -> String -> Effect RateLimitVerdict
checkRateLimit limiter limit windowMs key = do
  nowMs <- getTime <$> now
  windows <- Ref.read limiter
  let
    bounded = if Map.size windows >= maxEntries then pruneExpired windowMs nowMs windows else windows
  if not (Map.member key bounded) && Map.size bounded >= maxEntries then
    -- Map full of live windows from an IP-rotation flood: fail open for the
    -- unseen key rather than grow past the cap. This key gets NO limiting
    -- protection this window — that is the trade-off of the hard cap.
    pure { allowed: true, retryAfterMs: Nothing }
  else do
    let
      Tuple allowed newWindow = shouldAllow { limit, windowMs, nowMs } (Map.lookup key bounded)
      updated = Map.insert key newWindow bounded
    Ref.write updated limiter
    pure
      { allowed
      , retryAfterMs: if allowed then Nothing else Just (remainingMs windowMs nowMs newWindow)
      }
