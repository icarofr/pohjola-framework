-- | Unit tests for accessible UI primitives (Modal, Toast, Accordion, Tabs)
module Test.UiSpec (spec) where

import Prelude

import App.Html (render, text)
import App.Ui.Accordion (renderAccordion)
import App.Ui.Modal (renderModal)
import App.Ui.Tabs (renderTabs)
import App.Ui.Toast (renderToast)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions.String (shouldContain)

spec :: Spec Unit
spec = do
  describe "App.Ui" do
    describe "Modal" do
      it "renders dialog role and aria-modal" do
        let html = render (renderModal { id: "test-modal", triggerText: "Open Modal", title: "Dialog Title", content: text "Modal Content" })
        html `shouldContain` "role=\"dialog\""
        html `shouldContain` "aria-modal=\"true\""
        html `shouldContain` "aria-label=\"Dialog Title\""
        html `shouldContain` "Open Modal"
        html `shouldContain` "Modal Content"

    describe "Toast" do
      it "renders status role and message" do
        let html = render (renderToast { id: "test-toast", message: "Changes saved successfully", isSuccess: true })
        html `shouldContain` "role=\"status\""
        html `shouldContain` "Changes saved successfully"
        html `shouldContain` "bg-emerald-50"

    describe "Accordion" do
      it "renders accordion group with ARIA controls" do
        let
          items =
            [ { id: "item1", title: "Section 1", content: text "Content 1", defaultOpen: true }
            , { id: "item2", title: "Section 2", content: text "Content 2", defaultOpen: false }
            ]
        let html = render (renderAccordion items)
        html `shouldContain` "aria-controls=\"panel_item1\""
        html `shouldContain` "aria-controls=\"panel_item2\""
        html `shouldContain` "Section 1"
        html `shouldContain` "Content 1"

    describe "Tabs" do
      it "renders tablist and tabpanel roles" do
        let
          tabs =
            { tab1: { id: "tab1", label: "Tab 1", content: text "Panel 1" }
            , tab2: { id: "tab2", label: "Tab 2", content: text "Panel 2" }
            }
        let html = render (renderTabs tabs)
        html `shouldContain` "role=\"tablist\""
        html `shouldContain` "role=\"tab\""
        html `shouldContain` "role=\"tabpanel\""
        html `shouldContain` "Tab 1"
        html `shouldContain` "Panel 1"
