-- | Test runner — purescript-spec
-- |
-- | Trimmed for the clean-sheet rebuild (see .scratch/clean-sheet-homepage/):
-- | PostsSpec, PolicySpec, TemplateContractSpec, and ShellSpec were 100%
-- | feature-literal (no route/module survived the purge) and were deleted
-- | outright rather than trimmed. Restore their coverage once real routes
-- | and features exist again (tickets 02+).
module Test.Main where

import Prelude

import Effect (Effect)
import Test.AuthSpec as AuthSpec
import Test.ContractSpec as ContractSpec
import Test.FormSpec as FormSpec
import Test.Html.HtmlSpec as HtmlSpec
import Test.I18n.I18nSpec as I18nSpec
import Test.RateLimitSpec as RateLimitSpec
import Test.Route.RouteSpec as RouteSpec
import Test.SitemapSpec as SitemapSpec
import Test.LangDetectSpec as LangDetectSpec
import Test.LoggerSpec as LoggerSpec
import Test.ServerSpec as ServerSpec
import Test.UsersSpec as UsersSpec
import Test.Spec.Reporter (consoleReporter)
import Test.Spec.Runner.Node (runSpecAndExitProcess)

main :: Effect Unit
main = runSpecAndExitProcess [ consoleReporter ] do
  AuthSpec.spec
  ContractSpec.spec
  FormSpec.spec
  HtmlSpec.spec
  RouteSpec.spec
  I18nSpec.spec
  SitemapSpec.spec
  LangDetectSpec.spec
  LoggerSpec.spec
  RateLimitSpec.spec
  ServerSpec.spec
  UsersSpec.spec
