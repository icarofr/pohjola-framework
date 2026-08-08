-- | Html ADT tests — escaping, void elements, rendering, monoid laws
module Test.Html.HtmlSpec where

import Prelude

import App.Html (attr, class_, el, empty, flag, raw, render, text)
import Data.String.CodeUnits (contains) as SCU
import Data.String.Pattern (Pattern(..))
import Effect.Class (liftEffect)
import Test.QuickCheck (quickCheck)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)

spec :: Spec Unit
spec = do
  describe "Html ADT" do
    describe "text escaping" do
      it "escapes <" do
        render (text "<script>") `shouldEqual` "&lt;script&gt;"
      it "escapes &" do
        render (text "a & b") `shouldEqual` "a &amp; b"
      it "escapes quotes" do
        render (text "\"hello\"") `shouldEqual` "&quot;hello&quot;"
      it "escapes single quotes" do
        render (text "it's") `shouldEqual` "it&#x27;s"
      it "preserves plain text" do
        render (text "Hello World") `shouldEqual` "Hello World"

    describe "raw" do
      it "does not escape" do
        render (raw "<svg></svg>") `shouldEqual` "<svg></svg>"
      it "preserves HTML entities" do
        render (raw "&amp;") `shouldEqual` "&amp;"

    describe "element rendering" do
      it "renders a div with children" do
        render (el "div" [] [ text "hi" ]) `shouldEqual` "<div>hi</div>"
      it "renders attributes" do
        render (el "a" [ attr "href" "/fr" ] [ text "link" ]) `shouldEqual` "<a href=\"/fr\">link</a>"
      it "renders class attribute" do
        render (el "div" [ class_ "container" ] []) `shouldEqual` "<div class=\"container\"></div>"
      it "renders boolean attributes" do
        render (el "input" [ flag "required" ] []) `shouldEqual` "<input required />"
      it "escapes attribute values" do
        render (el "div" [ attr "title" "\"quoted\"" ] []) `shouldEqual` "<div title=\"&quot;quoted&quot;\"></div>"

    describe "void elements" do
      it "self-closes img" do
        render (el "img" [ attr "src" "/test.png" ] []) `shouldEqual` "<img src=\"/test.png\" />"
      it "self-closes br" do
        render (el "br" [] []) `shouldEqual` "<br />"
      it "self-closes input" do
        render (el "input" [] []) `shouldEqual` "<input />"
      it "self-closes meta" do
        render (el "meta" [ attr "charset" "UTF-8" ] []) `shouldEqual` "<meta charset=\"UTF-8\" />"

    describe "fragment and empty" do
      it "fragment concatenates children" do
        render (el "div" [] [ text "a", text "b" ]) `shouldEqual` "<div>ab</div>"
      it "empty renders to empty string" do
        render empty `shouldEqual` ""
      it "semigroup appends" do
        render (text "a" <> text "b") `shouldEqual` "ab"
      it "mempty renders to empty" do
        render mempty `shouldEqual` ""

    describe "property: text always escapes" do
      it "render(text(s)) never contains unescaped <"
        $ liftEffect
        $ quickCheck \s -> not (SCU.contains (Pattern "<") (render (text s)))
      it "render(text(s)) never contains unescaped >"
        $ liftEffect
        $ quickCheck \s -> not (SCU.contains (Pattern ">") (render (text s)))
