module App.Cache where

import Prelude

import App.Html (Html)
import Data.I18n (Lang)
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Route (Route)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Ref (Ref)
import Effect.Ref as Ref
import Data.JSDate (now, getTime)

-- | Cache for pre-rendered static pages. Keyed by (Route, Lang).
-- | Lazy: populated on first request, then immutable for the process lifetime.
type StaticCache = Ref (Map (Tuple Route Lang) Html)

mkStaticCache :: Effect StaticCache
mkStaticCache = Ref.new Map.empty

lookupStatic :: StaticCache -> Route -> Lang -> Effect (Maybe Html)
lookupStatic cache route lang = do
  m <- Ref.read cache
  pure (Map.lookup (Tuple route lang) m)

insertStatic :: StaticCache -> Route -> Lang -> Html -> Effect Unit
insertStatic cache route lang html =
  Ref.modify_ (Map.insert (Tuple route lang) html) cache

-- | TTL cache for dynamic pages (PostDetail).
-- |
-- | Keyed by `(Route, Lang)` rather than a rendered string. A string key would
-- | rest on `Show Route` being injective — a hand-written instance with nothing
-- | enforcing it, so a future edit could silently make two routes share a cache
-- | entry and serve one route's HTML for another. The tuple removes the claim
-- | instead of testing it: `Ord Route` is derived, so distinct routes are
-- | distinct keys by construction.
type CacheEntry = { html :: Html, expires :: Number }
type DynamicKey = Tuple Route Lang
type DynamicCache = Ref (Map DynamicKey CacheEntry)

maxEntries :: Int
maxEntries = 10000

pruneExpired :: Number -> Map DynamicKey CacheEntry -> Map DynamicKey CacheEntry
pruneExpired nowMs = Map.filter (\entry -> entry.expires > nowMs)

mkDynamicCache :: Effect DynamicCache
mkDynamicCache = Ref.new Map.empty

-- | TTL in milliseconds. Default 30 seconds.
defaultTtlMs :: Number
defaultTtlMs = 30000.0

lookupDynamic :: DynamicCache -> DynamicKey -> Effect (Maybe Html)
lookupDynamic cache key = do
  m <- Ref.read cache
  case Map.lookup key m of
    Nothing -> pure Nothing
    Just entry -> do
      t <- now
      let nowMs = getTime t
      if nowMs < entry.expires then pure (Just entry.html)
      else do
        Ref.modify_ (Map.delete key) cache
        pure Nothing

insertDynamic :: DynamicCache -> DynamicKey -> Html -> Number -> Effect Unit
insertDynamic cache key html ttlMs = do
  t <- now
  let nowMs = getTime t
  Ref.modify_
    ( \m ->
        let
          m' = if Map.size m >= maxEntries then pruneExpired nowMs m else m
        in
          Map.insert key { html, expires: nowMs + ttlMs } m'
    )
    cache

type PageCache = { static :: StaticCache, dynamic :: DynamicCache }

mkPageCache :: Effect PageCache
mkPageCache = do
  s <- mkStaticCache
  d <- mkDynamicCache
  pure { static: s, dynamic: d }
