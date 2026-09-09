-- | Behavioral policy — reference-page archetypes (structural scans: Test.Gate).
-- |
-- | Trimmed for the clean-sheet rebuild (see .scratch/clean-sheet-homepage/):
-- | Contact and Posts no longer exist. Home and About do, and cover the same
-- | two template shapes (Landing, Editorial) the deleted pages did — the
-- | "about" check now asserts a structural marker (the mission slot) rather
-- | than pinned prose, since this rebuild already proved that prose isn't
-- | stable across a rewrite the way the template shape is.
module Test.PolicySpec (spec) where

import Prelude

import App.Features.About.View as About
import App.Features.Home.View as Home
import App.Html (render)
import App.Ui.Templates.Contract as Contract
import Data.I18n (Lang(..))
import Data.Maybe (Maybe(..))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions.String as StrAssert

spec :: Spec Unit
spec =
  describe "PolicySpec" do
    describe "reference pages (page templates)" do
      it "home renders landing hero markers" do
        let html = render (Home.renderHome En Nothing)
        html `StrAssert.shouldContain` "https://github.com/icarofr/pohjola-framework"

      it "about renders mission and values grid" do
        let html = render (About.renderAbout En Nothing)
        html `StrAssert.shouldContain` Contract.slot Contract.editorialMission
        html `StrAssert.shouldContain` Contract.slot Contract.editorialValues
