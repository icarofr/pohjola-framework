-- | Behavioral policy — reference-page archetypes (structural scans: Test.Gate).
module Test.PolicySpec (spec) where

import Prelude

import App.Features.About.View as About
import App.Features.Contact.View as Contact
import App.Features.Home.View as Home
import App.Features.Posts.Types (Post(..))
import App.Features.Posts.View as Posts
import App.Html (render)
import Data.I18n (Lang(..))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions.String as StrAssert

spec :: Spec Unit
spec =
  describe "PolicySpec" do
    describe "reference pages (page templates)" do
      it "home renders landing hero markers" do
        let html = render (Home.renderHome En)
        html `StrAssert.shouldContain` "text-4xl font-bold"
        html `StrAssert.shouldContain` "bg-base-200"
        html `StrAssert.shouldContain` "https://github.com/icarofr/pohjola-framework"

      it "contact renders three-column hub cards" do
        let html = render (Contact.renderContact En)
        html `StrAssert.shouldContain` "data-template=\"hub-card\""
        html `StrAssert.shouldContain` "md:grid-cols-3"
        html `StrAssert.shouldContain` "flex-auto"

      it "about renders mission and values grid" do
        let html = render (About.renderAbout En)
        html `StrAssert.shouldContain` "Our mission"
        html `StrAssert.shouldContain` "lg:grid-cols-3"

      it "posts list renders feed card grid" do
        let
          sample =
            Post
              { id: 1
              , userId: 1
              , title: "Sample post title"
              , body: "Excerpt body for the card grid."
              }
          html = render (Posts.renderPostList En [ sample ])
        html `StrAssert.shouldContain` "data-template=\"feed-card\""
        html `StrAssert.shouldContain` "line-clamp-3"
