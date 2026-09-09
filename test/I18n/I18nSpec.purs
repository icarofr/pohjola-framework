-- | i18n tests — dictionaries load and localize (copy is not pinned).
module Test.I18n.I18nSpec where

import Prelude

import Data.Array (concat, elem)
import Data.Content (ServiceId(..))
import Data.Foldable (for_)
import Data.I18n (Lang(..), allLangs, dict, parseLang)
import Data.Maybe (Maybe(..))
import Data.Route (allRoutes, routeTitle)
import Data.String as String
import Data.String.Pattern (Pattern(..))
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
        -- Every nav entry, not just `home` — a per-page label that's only
        -- ever compared to itself can silently stay untranslated (this
        -- caught About/Guarantees/Docs shipping literal English nav labels
        -- in fr/pt during the clean-sheet rebuild).
        (dict En).nav.home `shouldNotEqual` (dict Fr).nav.home
        (dict En).nav.about `shouldNotEqual` (dict Fr).nav.about
        (dict En).nav.guarantees `shouldNotEqual` (dict Fr).nav.guarantees
        (dict En).nav.docs `shouldNotEqual` (dict Fr).nav.docs
        (dict En).nav.home `shouldNotEqual` (dict Pt).nav.home
        (dict En).nav.about `shouldNotEqual` (dict Pt).nav.about
        (dict En).nav.guarantees `shouldNotEqual` (dict Pt).nav.guarantees
        (dict En).nav.docs `shouldNotEqual` (dict Pt).nav.docs
        (dict En).hero.headline `shouldNotEqual` (dict Fr).hero.headline
      it "service copy localizes" do
        let svc1 = ServiceId "service-1"
        ((dict En).services.serviceCopy svc1).description
          `shouldNotEqual` ((dict Fr).services.serviceCopy svc1).description
        ((dict En).services.serviceCopy svc1).title `shouldNotEqual` ""

      it "About names Songs from the North in every language" do
        for_ allLangs \lang ->
          (dict lang).about.mission.lead
            `shouldSatisfy` String.contains (Pattern "Songs from the North")

      it "user-facing copy and page titles have no em dashes" do
        for_ allLangs \lang -> do
          for_ (visibleCopy lang) \s ->
            String.contains (Pattern "—") s `shouldEqual` false
          for_ allRoutes \route ->
            String.contains (Pattern "—") (routeTitle lang route) `shouldEqual` false

visibleCopy :: Lang -> Array String
visibleCopy lang =
  let
    d = dict lang
    svc sid =
      let
        c = d.services.serviceCopy (ServiceId sid)
      in
        [ c.title, c.description, c.actionLabel ]
    value v = [ v.title, v.description ]
    items = d.about.values.items
    cards = d.guarantees.cards
  in
    [ d.nav.home
    , d.nav.about
    , d.nav.guarantees
    , d.nav.docs
    , d.hero.eyebrow
    , d.hero.headline
    , d.hero.body
    , d.hero.ctaLabel
    , d.hero.secondaryLabel
    , d.services.sectionEyebrow
    , d.services.sectionHeadline
    , d.services.sectionIntro
    , d.cta.heading
    , d.cta.body
    , d.cta.ctaLabel
    , d.seo.homeDescription
    , d.seo.aboutDescription
    , d.seo.guaranteesDescription
    , d.seo.docsDescription
    , d.footer.explore
    , d.footer.resources
    , d.footer.github
    , d.footer.issues
    , d.footer.copyright
    , d.about.heading
    , d.about.subtitle
    , d.about.mission.heading
    , d.about.mission.lead
    , d.about.mission.body
    , d.about.values.heading
    , d.about.values.intro
    , d.guarantees.heading
    , d.guarantees.subtitle
    , d.guarantees.lead
    , d.docs.heading
    , d.docs.subtitle
    , d.docs.lead
    , d.docs.itemsHeading
    , d.docs.itemsIntro
    ]
      <> svc "service-1"
      <> svc "service-2"
      <> svc "service-3"
      <> value items.one
      <> value items.two
      <> value items.three
      <> value items.four
      <> value items.five
      <> value items.six
      <>
        [ cards.one.title
        , cards.one.description
        , cards.one.buttonLabel
        , cards.two.title
        , cards.two.description
        , cards.two.buttonLabel
        , cards.three.title
        , cards.three.description
        , cards.three.buttonLabel
        ]
      <> concat (map (\item -> [ item.title, item.description ]) d.docs.items)
