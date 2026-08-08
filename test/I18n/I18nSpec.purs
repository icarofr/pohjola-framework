-- | i18n tests — dictionary completeness, non-empty strings
module Test.I18n.I18nSpec where

import Prelude

import Data.Array (length)
import Data.Content (ServiceId(..))
import Data.I18n (Lang(..), dict)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual, shouldNotEqual)

spec :: Spec Unit
spec = do
  describe "I18n" do
    describe "dictionary access" do
      it "returns English dictionary for En" do
        (dict En).common.siteTitle `shouldEqual` "PS Alpine Starter"
      it "returns French dictionary for Fr" do
        (dict Fr).common.siteTitle `shouldEqual` "PS Alpine Starter"
      it "both languages have same site title" do
        (dict En).common.siteTitle `shouldEqual` (dict Fr).common.siteTitle

    describe "nav labels" do
      it "English has About" do
        (dict En).nav.about `shouldEqual` "About"
      it "French has À propos" do
        (dict Fr).nav.about `shouldEqual` "À propos"
      it "English has Contact" do
        (dict En).nav.contact `shouldEqual` "Contact"
      it "French has Contact" do
        (dict Fr).nav.contact `shouldEqual` "Contact"

    describe "hero content" do
      it "English has headline" do
        (dict En).hero.headline `shouldEqual` "Your headline here"
      it "French has headline" do
        (dict Fr).hero.headline `shouldEqual` "Votre titre ici"

    describe "services" do
      let svc1 = ServiceId "service-1"
      it "English has copy for service-1" do
        ((dict En).services.serviceCopy svc1).title `shouldNotEqual` ""
      it "French has copy for service-1" do
        ((dict Fr).services.serviceCopy svc1).description `shouldNotEqual` ""
      it "copy localizes between languages" do
        ((dict En).services.serviceCopy svc1).description
          `shouldNotEqual` ((dict Fr).services.serviceCopy svc1).description

    describe "legal sections" do
      it "English has 3 legal sections" do
        length (dict En).legal.sections `shouldEqual` 3
      it "French has 3 legal sections" do
        length (dict Fr).legal.sections `shouldEqual` 3
