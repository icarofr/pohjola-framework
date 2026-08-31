-- | Language detection tests
module Test.LangDetectSpec where

import Prelude

import App.Main (detectLang)
import Data.I18n (Lang(..), defaultLang)
import Test.Spec (describe, it, Spec)
import Test.Spec.Assertions (shouldEqual)

spec :: Spec Unit
spec = do
  describe "Language detection" do
    it "detects French from fr-FR,fr;q=0.9" do
      detectLang "fr-FR,fr;q=0.9" `shouldEqual` Fr

    it "detects English from en-US,en;q=0.9" do
      detectLang "en-US,en;q=0.9" `shouldEqual` En

    it "detects French when first token is fr" do
      detectLang "fr;q=0.9,en;q=0.8" `shouldEqual` Fr

    it "detects English when first token is en" do
      detectLang "en;q=0.9,fr;q=0.8" `shouldEqual` En

    it "detects Portuguese from pt-BR,pt;q=0.9" do
      detectLang "pt-BR,pt;q=0.9" `shouldEqual` Pt

    it "returns default for empty input" do
      detectLang "" `shouldEqual` defaultLang

    it "returns default for unsupported languages" do
      detectLang "de" `shouldEqual` defaultLang