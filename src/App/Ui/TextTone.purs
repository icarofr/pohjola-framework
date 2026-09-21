-- | Sole emitter of `text-base-content/` (Policy.Contract). Prefer Daisy
-- | default ink (`text-base-content`) in components; use these for muted copy.
module App.Ui.TextTone where

import Prelude

data TextTone = Ink | Copy | Meta

toneClass :: TextTone -> String
toneClass = case _ of
  Ink -> "text-base-content"
  Copy -> "text-base-content/70"
  Meta -> "text-base-content/50"

-- | Daisy `footer-title` is 60% opacity. That mute is not a contrast token:
-- | column labels are Ink, and `opacity-100` beats the recipe.
footerTitleClass :: String
footerTitleClass = "footer-title opacity-100 " <> toneClass Ink
