-- | Semantic text foreground tones — single source for base-content opacity.
-- | Literal `text-base-content/N` class strings are forbidden outside this module (ADR-008).
module App.Ui.TextTone where

import Prelude

-- | Named foreground tones on DaisyUI `base-content`. Three roles only;
-- | agents must use these instead of opacity arithmetic.
data TextTone = Ink | Copy | Meta

toneClass :: TextTone -> String
toneClass = case _ of
  Ink -> "text-base-content"
  Copy -> "text-base-content/80"
  Meta -> "text-base-content/60"

-- | Toolbar and icon controls: copy tone with full contrast on hover.
interactiveSoftClass :: String
interactiveSoftClass = toneClass Copy <> " hover:text-base-content"
