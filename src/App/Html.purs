-- | Html ADT — a plain rose-tree representation of HTML with a String renderer.
-- |
-- | Book-aligned: a sum type with an exhaustive pattern-matching interpreter.
-- | Text is escaped by construction. The only unescaped output paths are
-- | `<script>` and `<style>` content (unescaped text elements per the HTML
-- | spec), which is correct — escaping JS or CSS breaks it.
-- |
-- | This is intentionally NOT a framework — no component model, no virtual DOM,
-- | no event system. It produces a String. Interactivity is handled by Alpine.js
-- | in the browser.
module App.Html
  ( Html
  , Tag
  , Attr
  , doctype
  , el
  , text
  , empty
  , attr
  , flag
  , class_
  , href
  , src
  , alt
  , type_
  , id_
  , name_
  , value_
  , placeholder_
  , action_
  , method_
  , rel_
  , target_
  , content_
  , property_
  , style_
  , ariaLabel
  , ariaControls
  , for_
  , rows_
  , width_
  , height_
  , loading_
  , decoding_
  , render
  , escape
  ) where

import Prelude

import App.Bun (escapeHTMLImpl)
import Data.Array (elem)
import Data.Foldable (foldMap)
import Data.Maybe (Maybe(..))

-- ============================================================================
-- Types
-- ============================================================================

-- | HTML node — a rose tree.
data Html
  = Doctype
  | Element Tag (Array Attr) (Array Html)
  | Text String -- escaped on render (except inside script/style)
  | Fragment (Array Html) -- transparent wrapper for concatenation
  | Empty

-- | Tag name, e.g. "div", "a", "img"
type Tag = String

-- | Attribute — value is Nothing for boolean attributes (required, defer)
type Attr = { key :: String, value :: Maybe String }

-- ============================================================================
-- Semigroup / Monoid — enables foldMap for concatenating Html fragments
-- ============================================================================

instance semigroupHtml :: Semigroup Html where
  append a b = Fragment [ a, b ]

instance monoidHtml :: Monoid Html where
  mempty = Empty

-- ============================================================================
-- Constructors
-- ============================================================================

-- | Document type declaration — `<!DOCTYPE html>`. Takes no arguments;
-- | cannot carry user data.
doctype :: Html
doctype = Doctype

-- | Create an element with attributes and children.
el :: Tag -> Array Attr -> Array Html -> Html
el = Element

-- | Escaped text node.
text :: String -> Html
text = Text

-- | Empty node — renders to "".
empty :: Html
empty = Empty

-- ============================================================================
-- Attribute constructors
-- ============================================================================

-- | Key-value attribute: attr "href" "/fr"
attr :: String -> String -> Attr
attr key value = { key, value: Just value }

-- | Boolean attribute: flag "required" renders as just "required"
flag :: String -> Attr
flag key = { key, value: Nothing }

-- Common shortcuts
class_ :: String -> Attr
class_ = attr "class"

href :: String -> Attr
href = attr "href"

src :: String -> Attr
src = attr "src"

alt :: String -> Attr
alt = attr "alt"

type_ :: String -> Attr
type_ = attr "type"

id_ :: String -> Attr
id_ = attr "id"

name_ :: String -> Attr
name_ = attr "name"

value_ :: String -> Attr
value_ = attr "value"

placeholder_ :: String -> Attr
placeholder_ = attr "placeholder"

action_ :: String -> Attr
action_ = attr "action"

method_ :: String -> Attr
method_ = attr "method"

rel_ :: String -> Attr
rel_ = attr "rel"

target_ :: String -> Attr
target_ = attr "target"

content_ :: String -> Attr
content_ = attr "content"

property_ :: String -> Attr
property_ = attr "property"

style_ :: String -> Attr
style_ = attr "style"

ariaLabel :: String -> Attr
ariaLabel = attr "aria-label"

ariaControls :: String -> Attr
ariaControls = attr "aria-controls"

for_ :: String -> Attr
for_ = attr "for"

rows_ :: Int -> Attr
rows_ = attr "rows" <<< show

width_ :: Int -> Attr
width_ = attr "width" <<< show

height_ :: Int -> Attr
height_ = attr "height" <<< show

loading_ :: String -> Attr
loading_ = attr "loading"

decoding_ :: String -> Attr
decoding_ = attr "decoding"

-- ============================================================================
-- Escaping
-- ============================================================================

-- | Escape HTML special characters via Bun's SIMD-accelerated escapeHTML.
-- | Escapes & < > " ' — same set as the previous pure PS implementation.
-- | Note: Bun emits &#x27; for single quotes (was &#39; in the pure version);
-- | both are valid HTML5 entities.
escape :: String -> String
escape = escapeHTMLImpl

-- ============================================================================
-- Rendering — the single interpreter (exhaustive pattern match)
-- ============================================================================

-- | Render Html to a String.
render :: Html -> String
render = case _ of
  Doctype -> "<!DOCTYPE html>"
  Element tag attrs children ->
    if isVoid tag then
      "<" <> tag <> renderAttrs attrs <> " />"
    else if isScriptOrStyle tag then
      "<" <> tag <> renderAttrs attrs <> ">" <> foldMap renderUnescaped children <> "</" <> tag <> ">"
    else
      "<" <> tag <> renderAttrs attrs <> ">" <> foldMap render children <> "</" <> tag <> ">"
  Text s -> escape s
  Fragment children -> foldMap render children
  Empty -> ""

-- | Render children without escaping — for <script> and <style> content.
-- | These are unescaped text elements in the HTML spec: their content is
-- | not parsed as HTML, so escaping would break the JS/CSS.
renderUnescaped :: Html -> String
renderUnescaped = case _ of
  Text s -> s
  Fragment children -> foldMap renderUnescaped children
  Empty -> ""
  Element tag attrs children -> render (Element tag attrs children)
  Doctype -> "<!DOCTYPE html>"

renderAttrs :: Array Attr -> String
renderAttrs = foldMap renderAttr

renderAttr :: Attr -> String
renderAttr { key, value } = case value of
  Nothing -> " " <> key
  Just v -> " " <> key <> "=\"" <> escape v <> "\""

-- ============================================================================
-- Void elements — self-closing tags (no children, no closing tag)
-- ============================================================================

voidElements :: Array Tag
voidElements = [ "area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source", "track", "wbr" ]

isVoid :: Tag -> Boolean
isVoid tag = elem tag voidElements

-- ============================================================================
-- Unescaped text elements — content is not HTML-escaped (HTML spec)
-- ============================================================================

isScriptOrStyle :: Tag -> Boolean
isScriptOrStyle tag = tag == "script" || tag == "style"
