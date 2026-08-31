-- | Sole emitter of `text-base-content/` (Policy.Contract). Prefer Daisy
-- | default ink (`text-base-content`) in components; use these for muted copy.
module App.Ui.TextTone where

data TextTone = Ink | Copy | Meta

toneClass :: TextTone -> String
toneClass = case _ of
  Ink -> "text-base-content"
  Copy -> "text-base-content/70"
  Meta -> "text-base-content/50"
