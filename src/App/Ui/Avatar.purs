-- | DaisyUI avatar — vendor/daisyui/skills/daisyui/components/avatar.md
module App.Ui.Avatar
  ( AvatarSize(..)
  , avatarPlaceholder
  ) where

import Prelude

import App.Html (Html, class_, el, text)

data AvatarSize = Avatar8 | Avatar12 | Avatar16 | Avatar24

sizeClass :: AvatarSize -> String
sizeClass = case _ of
  Avatar8 -> "w-8"
  Avatar12 -> "w-12"
  Avatar16 -> "w-16"
  Avatar24 -> "w-24"

-- | avatar avatar-placeholder with initials
avatarPlaceholder :: AvatarSize -> String -> Html
avatarPlaceholder size initial =
  el "div" [ class_ "avatar avatar-placeholder" ]
    [ el "div" [ class_ ("bg-neutral text-neutral-content rounded-full " <> sizeClass size) ]
        [ el "span" [] [ text initial ] ]
    ]
