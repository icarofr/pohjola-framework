-- | i18n tests — dictionaries load and localize (copy is not pinned).
module Test.I18n.I18nSpec where

import Prelude

import Data.Array (elem)
import Data.Content (ServiceId(..))
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

    describe "localization" do
      it "nav and hero strings differ between languages" do
        (dict En).nav.about `shouldNotEqual` (dict Fr).nav.about
        (dict En).hero.headline `shouldNotEqual` (dict Fr).hero.headline
      it "service copy localizes" do
        let svc1 = ServiceId "service-1"
        ((dict En).services.serviceCopy svc1).description
          `shouldNotEqual` ((dict Fr).services.serviceCopy svc1).description
        ((dict En).services.serviceCopy svc1).title `shouldNotEqual` ""
