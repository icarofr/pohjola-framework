module App.Cache where

import Prelude

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
type StaticCache = Ref (Map (Tuple Route Lang) String)

mkStaticCache :: Effect StaticCache
mkStaticCache = Ref.new Map.empty

lookupStatic :: StaticCache -> Route -> Lang -> Effect (Maybe String)
lookupStatic cache route lang = do
  m <- Ref.read cache
  pure (Map.lookup (Tuple route lang) m)

insertStatic :: StaticCache -> Route -> Lang -> String -> Effect Unit
insertStatic cache route lang body =
  Ref.modify_ (Map.insert (Tuple route lang) body) cache

-- | TTL cache for dynamic pages (PostDetail).
type CacheEntry = { body :: String, expires :: Number }
type DynamicCache = Ref (Map String CacheEntry)

maxEntries :: Int
maxEntries = 10000

pruneExpired :: Number -> Map String CacheEntry -> Map String CacheEntry
pruneExpired nowMs = Map.filter (\entry -> entry.expires > nowMs)

mkDynamicCache :: Effect DynamicCache
mkDynamicCache = Ref.new Map.empty

-- | TTL in milliseconds. Default 30 seconds.
defaultTtlMs :: Number
defaultTtlMs = 30000.0

lookupDynamic :: DynamicCache -> String -> Effect (Maybe String)
lookupDynamic cache key = do
  m <- Ref.read cache
  case Map.lookup key m of
    Nothing -> pure Nothing
    Just entry -> do
      t <- now
      let nowMs = getTime t
      if nowMs < entry.expires then pure (Just entry.body)
      else do
        Ref.modify_ (Map.delete key) cache
        pure Nothing

insertDynamic :: DynamicCache -> String -> String -> Number -> Effect Unit
insertDynamic cache key body ttlMs = do
  t <- now
  let nowMs = getTime t
  Ref.modify_
    ( \m ->
        let
          m' = if Map.size m >= maxEntries then pruneExpired nowMs m else m
        in
          Map.insert key { body, expires: nowMs + ttlMs } m'
    )
    cache

type PageCache = { static :: StaticCache, dynamic :: DynamicCache }

mkPageCache :: Effect PageCache
mkPageCache = do
  s <- mkStaticCache
  d <- mkDynamicCache
  pure { static: s, dynamic: d }
