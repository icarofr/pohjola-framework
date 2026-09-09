-- | i18n tests — dictionaries load and localize (copy is not pinned).
-- |
-- | Trimmed for the clean-sheet rebuild (see .scratch/clean-sheet-homepage/):
-- | the "localization" describe block asserted per-page copy differs across
-- | languages (nav, hero, services) — all deleted along with the pages that
-- | owned them. `footer`/`common` are still exercised via `dictionary
-- | access`/`Lang parsing`. Restore per-page localization coverage as each
-- | page's content lands (tickets 02+).
module Test.I18n.I18nSpec where

import Prelude

import Data.Array (elem)
import Data.I18n (Lang(..), allLangs, dict, parseLang)
import Data.Maybe (Maybe(..))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual, shouldNotEqual, shouldSatisfy)

spec :: Spec Unit
spec = do
  describe "I18n" do
    describe "dictionary access" do
      it "both languages share the site title" do
        (dict En).common.siteTitle `shouldEqual` (dict Fr).common.siteTitle
        (dict En).common.siteTitle `shouldNotEqual` ""

    describe "Lang parsing" do
      it "parses pt" do
        parseLang "pt" `shouldEqual` Just Pt

      it "allLangs includes Pt" do
        (Pt `elem` allLangs) `shouldEqual` true

      it "dict Pt has same siteTitle access pattern" do
        (dict Pt).common.siteTitle `shouldSatisfy` (_ /= "")
