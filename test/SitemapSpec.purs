-- | Sitemap tests
module Test.SitemapSpec where

import Prelude

import App.Sitemap (renderSitemap, renderRobots)
import Test.Spec (describe, it, Spec)
import Test.Spec.Assertions.String as StrAssert

spec :: Spec Unit
spec = do
  describe "Sitemap rendering" do
    let sitemap = renderSitemap "https://example.com"

    it "contains xmlns:xhtml declaration" do
      sitemap `StrAssert.shouldContain` "xmlns:xhtml=\"http://www.w3.org/1999/xhtml\""

    it "contains xml declaration" do
      sitemap `StrAssert.shouldContain` "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"

    -- `Route` is temporarily zero-constructor (clean-sheet rebuild, see
    -- .scratch/clean-sheet-homepage/), so `allRoutes` is empty and the
    -- sitemap correctly emits no <url> entries at all — asserted directly
    -- rather than deleted, since "no routes in, no entries out" is itself
    -- real, checkable behavior. Restore the populated-sitemap assertions
    -- once real routes exist again (ticket 02+).
    it "contains no loc URLs while there are no routes" do
      sitemap `StrAssert.shouldNotContain` "<loc>"

    it "contains no hreflang alternates while there are no routes" do
      sitemap `StrAssert.shouldNotContain` "hreflang="

  describe "Robots.txt rendering" do
    let robots = renderRobots "https://example.com"

    it "allows all crawling with empty Disallow" do
      robots `StrAssert.shouldContain` "Disallow:\n"

    it "includes sitemap URL" do
      robots `StrAssert.shouldContain` "Sitemap: https://example.com/sitemap.xml\n"
