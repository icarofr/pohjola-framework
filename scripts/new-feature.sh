#!/usr/bin/env bash
# Scaffold a new feature — generates templated files and prints manual edits.
#
# Usage:
#   make new-feature NAME=Team                    # static page (default)
#   make new-feature NAME=Products TYPE=data      # data-backed page
#   make new-feature NAME=Team SLUG_FR=equipe     # custom FR slug
#
# Creates src/App/Features/<Name>/ with the right file split.
# Prints a patch for Route.purs, Main.purs, and I18n/Dictionary.purs
# that you apply manually — the compiler guides you to every site.
set -euo pipefail

# --- Args -------------------------------------------------------------------
NAME="${NAME:?NAME is required (PascalCase, e.g. Team)}"
TYPE="${TYPE:-static}"
SLUG_EN="${SLUG_EN:-$(echo "$NAME" | tr '[:upper:]' '[:lower:]')}"
SLUG_FR="${SLUG_FR:-$SLUG_EN}"

if [[ "$TYPE" != "static" && "$TYPE" != "data" ]]; then
  echo "TYPE must be 'static' or 'data' (got: $TYPE)"
  exit 1
fi

# --- Paths ------------------------------------------------------------------
FEATURE_DIR="src/App/Features/$NAME"

if [[ -d "$FEATURE_DIR" ]]; then
  echo "Feature already exists: $FEATURE_DIR"
  exit 1
fi

# --- Helpers ----------------------------------------------------------------
lower=$(echo "$NAME" | tr '[:upper:]' '[:lower:]')

mkdir -p "$FEATURE_DIR"

# --- Generate files ---------------------------------------------------------

# Page.purs (both types)
cat > "$FEATURE_DIR/Page.purs" <<EOF
-- | $NAME page — entry point
module App.Features.$NAME.Page where

import App.Features.$NAME.View (render$NAME)
import App.Html (Html)
import App.Layout.Page (staticPage)
import Data.I18n (Lang)
import Effect.Aff (Aff)
import App.Error (AppError)
import Data.Either (Either)

render :: Lang -> Aff (Either AppError Html)
render lang = staticPage (render$NAME lang)
EOF

# View.purs (both types)
cat > "$FEATURE_DIR/View.purs" <<EOF
-- | $NAME page — page-level rendering, orchestrates Components/
module App.Features.$NAME.View where

import App.Alpine (xAutofocus)
import App.Html (Html, attr, class_, el, text)
import App.Ui.Container (container)
import Data.I18n (Lang, dict)

render$NAME :: Lang -> Html
render$NAME lang =
  let
    d = (dict lang).$lower
  in
    container "max-w-3xl" "py-16"
      [ el "h1" [ class_ "font-display text-4xl font-bold text-slate-900 dark:text-white", xAutofocus, attr "tabindex" "-1" ]
          [ text d.heading ]
      , el "p" [ class_ "mt-6 text-lg leading-8 text-slate-600 dark:text-slate-300" ]
          [ text d.body ]
      ]
EOF

if [[ "$TYPE" == "data" ]]; then
  cat > "$FEATURE_DIR/Types.purs" <<EOF
-- | $NAME domain type + JSON decoding.
module App.Features.$NAME.Types where

import Prelude

import Data.Argonaut.Decode (class DecodeJson, decodeJson, (.:))
import Data.Argonaut.Decode.Error (JsonDecodeError(..))
import Data.Argonaut.Parser (jsonParser)
import Data.Either (Either(..))
import Data.Newtype (class Newtype)
import App.Error (AppError(..))

newtype $NAME = $NAME
  { id :: Int
  , title :: String
  , body :: String
  }

derive instance newtype$NAME :: Newtype $NAME _
derive newtype instance show$NAME :: Show $NAME
derive newtype instance eq$NAME :: Eq $NAME

instance decodeJson$NAME :: DecodeJson $NAME where
  decodeJson json = do
    obj <- decodeJson json
    id <- obj .: "id"
    title <- obj .: "title"
    body <- obj .: "body"
    pure $ $NAME { id, title, body }

decode${NAME}s :: String -> Either AppError (Array $NAME)
decode${NAME}s body = case jsonParser body of
  Left _ -> Left (DecodeError (TypeMismatch "Failed to parse ${lower} JSON"))
  Right json -> case decodeJson json of
    Left _ -> Left (DecodeError (TypeMismatch "Failed to parse ${lower} JSON"))
    Right items -> Right items
EOF

  cat > "$FEATURE_DIR/Service.purs" <<EOF
-- | Data service — fetches $lower from an external API via Bun native fetch.
module App.Features.$NAME.Service where

import Prelude
import App.Config (Config)
import App.Data.Fetch (fetchJson)
import App.Error (AppError)
import App.Features.$NAME.Types ($NAME)
import Data.Either (Either)
import Effect.Aff (Aff)

fetch${NAME}s :: Config -> Aff (Either AppError (Array $NAME))
fetch${NAME}s cfg =
  fetchJson (cfg.postsApiBase <> "/${lower}")
EOF

  # Overwrite Page.purs for data-backed
  cat > "$FEATURE_DIR/Page.purs" <<EOF
-- | $NAME page — entry point with async data fetching.
module App.Features.$NAME.Page where

import Prelude

import App.Config (Config)
import App.Error (AppError)
import App.Features.$NAME.Service (fetch${NAME}s)
import App.Features.$NAME.View (render${NAME}List, render${NAME}Error)
import App.Html (Html)
import Data.Either (Either(..))
import Data.I18n (Lang)
import Effect.Aff (Aff)

renderList :: Config -> Lang -> Aff (Either AppError Html)
renderList cfg lang = do
  result <- fetch${NAME}s cfg
  pure case result of
    Right items -> Right (render${NAME}List lang items)
    Left _ -> Right (render${NAME}Error lang)
EOF

  # Overwrite View.purs for data-backed
  cat > "$FEATURE_DIR/View.purs" <<EOF
-- | $NAME view — list rendering, orchestrates Components/
module App.Features.$NAME.View where

import Prelude

import App.Alpine (xAutofocus)
import App.Features.$NAME.Components.${NAME}Card (render${NAME}Card)
import App.Features.$NAME.Types ($NAME)
import App.Html (Html, attr, class_, el, text)
import App.Ui.Container (container)
import Data.Foldable (foldMap)
import Data.I18n (Lang, dict)

render${NAME}List :: Lang -> Array $NAME -> Html
render${NAME}List lang items =
  let
    d = (dict lang).$lower
  in
    container "max-w-3xl" "py-16"
      [ el "h1" [ class_ "font-display text-4xl font-bold text-slate-900 dark:text-white", xAutofocus, attr "tabindex" "-1" ]
          [ text d.heading ]
      , el "div" [ class_ "mt-8 space-y-6" ]
          [ foldMap (render${NAME}Card lang) items ]
      ]

render${NAME}Error :: Lang -> Html
render${NAME}Error lang =
  let
    d = (dict lang).$lower
  in
    container "max-w-3xl" "py-16"
      [ el "h1" [ class_ "font-display text-4xl font-bold text-slate-900 dark:text-white", xAutofocus, attr "tabindex" "-1" ]
          [ text d.heading ]
      , el "p" [ class_ "mt-4 text-lg text-red-600 dark:text-red-400" ]
          [ text "Error loading." ]
      ]
EOF

  # Components/ — feature-local presentational components
  mkdir -p "$FEATURE_DIR/Components"
  cat > "$FEATURE_DIR/Components/${NAME}Card.purs" <<EOF
-- | ${NAME} card — presentational component for a single item in a list.
module App.Features.$NAME.Components.${NAME}Card where

import App.Features.$NAME.Types ($NAME)
import App.Html (Html, class_, el, text)
import Data.I18n (Lang)

render${NAME}Card :: Lang -> $NAME -> Html
render${NAME}Card _ _ =
  el "article" [ class_ "rounded-lg border border-slate-200 dark:border-slate-800 p-6" ]
    [ el "h2" [ class_ "text-xl font-semibold text-slate-900 dark:text-white" ]
        [ text "TODO" ]
    ]
EOF
fi

# --- Print manual edits -----------------------------------------------------

cat <<INSTRUCTIONS

╭──────────────────────────────────────────────────────────────────────────╮
│  Feature scaffolded: $FEATURE_DIR ($TYPE)                                  │
│  Files created:                                                           │
INSTRUCTIONS

if [[ "$TYPE" == "data" ]]; then
  echo "│    Types.purs  Service.purs  Page.purs  View.purs  Components/            │"
else
  echo "│    Page.purs  View.purs                                                  │"
fi

cat <<INSTRUCTIONS
╰──────────────────────────────────────────────────────────────────────────╯

  Apply these edits manually — the compiler guides you to every site.

  ── 1. src/Data/Route.purs ──────────────────────────────────────────────

  Add to the Route sum type (after the last constructor):

      | $NAME

  Add to BOTH codec blocks (En and Fr):

      , "$NAME": "$SLUG_EN" / G.noArgs       ← in routeCodec En
      , "$NAME": "$SLUG_FR" / G.noArgs       ← in routeCodec Fr

  Add to routeTitle:

      $NAME -> d.nav.$lower <> " — " <> siteTitle

  Add to prefetchFor:

      $NAME -> [ Home ]

  Add to allRoutes (if it should appear in the sitemap):

      allRoutes = [ Home, About, Contact, PostList, $NAME ]

  Add to navItems (if it should appear in navigation):

      , { label: d.nav.$lower, route: $NAME }

INSTRUCTIONS

if [[ "$TYPE" == "data" ]]; then
  cat <<INSTRUCTIONS
  ── 2. src/App/Main.purs ────────────────────────────────────────────────

  Add to pageRenderer (import + case):

      import App.Features.$NAME.Page (renderList) as $NAME
      -- in the case expression:
      $NAME -> $NAME.renderList cfg lang

  ── 3. src/App/Data/I18n/Dictionary.purs ────────────────────────────────

  Add a \`$lower\` record to BOTH en and fr dictionaries:

      $lower:
        { heading: "..."
        , body: "..."
        }

  For data-backed, also add nav label and error text.

INSTRUCTIONS
else
  cat <<INSTRUCTIONS
  ── 2. src/App/Main.purs ────────────────────────────────────────────────

  Add to pageRenderer (import + case):

      import App.Features.$NAME.Page (render) as $NAME
      -- in the case expression:
      $NAME -> $NAME.render lang

  ── 3. src/App/Data/I18n/Dictionary.purs ────────────────────────────────

  Add a \`$lower\` record to BOTH en and fr dictionaries:

      $lower:
        { heading: "..."
        , body: "..."
        }

  And add a nav label to BOTH nav records:

      , $lower: "..."   ← en
      , $lower: "..."   ← fr

INSTRUCTIONS
fi

cat <<INSTRUCTIONS

  ── 4. Verify ───────────────────────────────────────────────────────────

  make gate    # ~2s — check the route codec compiles
  make check   # ~60s — full validation

  The compiler will error on every missing site until the edits are complete.
INSTRUCTIONS
