-- | Test runner — purescript-spec
-- |
-- | PostsSpec stays deleted (tested Posts.Service, which no longer exists —
-- | no seam left to trim to). PolicySpec, TemplateContractSpec, and
-- | ShellSpec were restored, trimmed to Home/About, once the clean-sheet
-- | rebuild (see .scratch/clean-sheet-homepage/) gave them real routes to
-- | exercise again — their Contact/Posts/Fixtures-specific assertions stay
-- | gone.
module Test.Main where

import Prelude

import Effect (Effect)
import Test.AuthSpec as AuthSpec
import Test.ContractSpec as ContractSpec
import Test.DatastarSpec as DatastarSpec
import Test.FormSpec as FormSpec
import Test.Html.HtmlSpec as HtmlSpec
import Test.I18n.I18nSpec as I18nSpec
import Test.PolicySpec as PolicySpec
import Test.RateLimitSpec as RateLimitSpec
import Test.Route.RouteSpec as RouteSpec
import Test.ShellSpec as ShellSpec
import Test.SitemapSpec as SitemapSpec
import Test.LangDetectSpec as LangDetectSpec
import Test.LoggerSpec as LoggerSpec
import Test.ServerSpec as ServerSpec
import Test.TemplateContractSpec as TemplateContractSpec
import Test.UsersSpec as UsersSpec
import Test.Spec.Reporter (consoleReporter)
import Test.Spec.Runner.Node (runSpecAndExitProcess)

main :: Effect Unit
main = runSpecAndExitProcess [ consoleReporter ] do
  AuthSpec.spec
  ContractSpec.spec
  DatastarSpec.spec
  FormSpec.spec
  HtmlSpec.spec
  RouteSpec.spec
  I18nSpec.spec
  PolicySpec.spec
  ShellSpec.spec
  SitemapSpec.spec
  TemplateContractSpec.spec
  LangDetectSpec.spec
  LoggerSpec.spec
  RateLimitSpec.spec
  ServerSpec.spec
  UsersSpec.spec
