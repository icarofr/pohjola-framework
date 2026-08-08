-- | Test runner — purescript-spec
module Test.Main where

import Prelude

import Effect (Effect)
import Test.ContractSpec as ContractSpec
import Test.FormSpec as FormSpec
import Test.Html.HtmlSpec as HtmlSpec
import Test.I18n.I18nSpec as I18nSpec
import Test.PostsSpec as PostsSpec
import Test.RateLimitSpec as RateLimitSpec
import Test.Route.RouteSpec as RouteSpec
import Test.SitemapSpec as SitemapSpec
import Test.LangDetectSpec as LangDetectSpec
import Test.LoggerSpec as LoggerSpec
import Test.ServerSpec as ServerSpec
import Test.Spec.Reporter (consoleReporter)
import Test.Spec.Runner.Node (runSpecAndExitProcess)

main :: Effect Unit
main = runSpecAndExitProcess [ consoleReporter ] do
  ContractSpec.spec
  FormSpec.spec
  HtmlSpec.spec
  RouteSpec.spec
  I18nSpec.spec
  PostsSpec.spec
  SitemapSpec.spec
  LangDetectSpec.spec
  LoggerSpec.spec
  RateLimitSpec.spec
  ServerSpec.spec
