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

    it "contains loc URLs for routes" do
      sitemap `StrAssert.shouldContain` "<loc>https://example.com/en</loc>"

    it "contains hreflang alternates" do
      sitemap `StrAssert.shouldContain` "hreflang=\"en\""
      sitemap `StrAssert.shouldContain` "hreflang=\"fr\""
      sitemap `StrAssert.shouldContain` "hreflang=\"x-default\""

    it "uses absolute URLs with base URL" do
      sitemap `StrAssert.shouldContain` "https://example.com/"

  describe "Robots.txt rendering" do
    let robots = renderRobots "https://example.com"

    it "blocks all crawling with Disallow: /" do
      robots `StrAssert.shouldContain` "Disallow: /\n"

    it "includes sitemap URL" do
      robots `StrAssert.shouldContain` "Sitemap: https://example.com/sitemap.xml\n"
