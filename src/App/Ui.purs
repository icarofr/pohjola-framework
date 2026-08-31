-- | UI primitives barrel. Feature views compose pages via App.Ui.Templates only.
module App.Ui
  ( module App.Ui.Button
  , module App.Ui.Badge
  , module App.Ui.Alert
  , module App.Ui.Stat
  , module App.Ui.EmptyState
  , module App.Ui.Avatar
  , module App.Ui.Prose
  , module App.Ui.TextTone
  , module App.Ui.Templates.Types
  ) where

import App.Ui.Alert (AlertVariant(..), alert)
import App.Ui.Avatar (AvatarSize(..), avatarPlaceholder)
import App.Ui.Badge (BadgeVariant(..), badge)
import App.Ui.Button (ButtonVariant(..), Size(..), buttonLink, buttonLinkExternal)
import App.Ui.EmptyState (EmptyStateProps, emptyState)
import App.Ui.Prose (prose, proseLg)
import App.Ui.Stat (StatItem, statCard, statGrid)
import App.Ui.Templates.Types (ActionTarget(..))
import App.Ui.TextTone
