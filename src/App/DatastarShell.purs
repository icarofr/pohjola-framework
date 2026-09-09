-- | Spike-only (datastar-shell-nav-port branch): a Datastar-powered parallel
-- | to App.Ui.Templates.SiteShell, covering only what tickets 03/04 need
-- | (nav links, theme dropdown, language dropdown, mobile drawer) for Home
-- | and About specifically. Deliberately NOT a modification of SiteShell.purs
-- | itself — the spec requires the Alpine-based pages to keep working
-- | unmodified as the side-by-side comparison baseline. Reuses
-- | SiteShell.shellLabels/ShellLabels (pure data, no Alpine attributes) and
-- | App.Ui.Container (pure DaisyUI width classes) directly; everything
-- | reactivity-shaped goes through App.Datastar's constructors, never an
-- | unescaped attribute string here.
module App.DatastarShell (dsSitePage, renderDsDocument) where

import Prelude

import App.Layout.Scripts (HeadScript(..), renderHeadScript)
import App.Layout.Styles (stylesCss)
import App.Datastar
  ( DsFlag(..)
  , dataPageLangAttr
  , dataPageTitleAttr
  , dsClassWhenEq
  , dsNavGet
  , dsOnClickOutside
  , dsOnKeydownEscape
  , dsSetFlag
  , dsSetTheme
  , dsShowFlag
  , dsSignalsInit
  , dsToggleFlag
  )
import App.Html (Html, ariaLabel, attr, class_, doctype, el, for_, href, id_, rel_, render, src, target_, text, type_)
import App.Ui.Container as Container
import App.Ui.Templates.Contract as Contract
import App.Ui.Templates.SiteShell (ShellLabels, shellLabels)
import Data.Content (bookingUrl)
import Data.I18n (Lang(..), dict, langTag)
import Data.Route (Route(..), routeUrl)
import Data.String.Common (toUpper)

siteDrawerId :: String
siteDrawerId = "ds-site-drawer"

-- | Same #content/data-page-* contract App.Alpine's fragment path uses --
-- | App.Layout.Scripts' dsShellRouterScript reads these exact fields.
-- | No status-banner param: form status isn't in ticket 03/04's scope
-- | (Home/About carry no forms today, on either transport).
dsSitePage :: Lang -> Route -> String -> Html -> Html
dsSitePage lang route title content =
  let
    labels = shellLabels lang
  in
    el "div"
      ( [ class_ "drawer drawer-end min-h-dvh bg-base-100 text-base-content"
        , id_ "content"
        , attr dataPageTitleAttr title
        , attr dataPageLangAttr (langTag lang)
        , dsSignalsInit
        , dsOnKeydownEscape DsDrawerOpen
        ]
      )
      [ el "input" [ type_ "checkbox", class_ "drawer-toggle", id_ siteDrawerId ] []
      , el "div" [ class_ "drawer-content flex min-h-full flex-col" ]
          [ renderHeader lang route labels
          , el "main" [ class_ "flex-1" ] [ content ]
          , renderFooterPlain lang route labels
          ]
      , renderDrawerSide lang route labels
      ]

renderHeader :: Lang -> Route -> ShellLabels -> Html
renderHeader lang route labels =
  el "header"
    [ class_ "sticky top-0 z-50 border-b border-base-300 bg-secondary text-secondary-content"
    , attr "data-theme" "pohjola-dark"
    , attr Contract.marker Contract.siteHeader
    ]
    [ Container.container Container.ContainerW6xl "px-4 sm:px-6"
        [ el "div" [ class_ "navbar min-h-16 px-0" ]
            [ el "div" [ class_ "navbar-start" ]
                [ el "a" [ href (routeUrl lang Home), dsNavGet lang Home, class_ "btn btn-ghost text-lg font-semibold" ]
                    [ text labels.siteTitle ]
                ]
            , el "nav"
                [ class_ "navbar-center hidden gap-1 md:flex"
                , ariaLabel (dict lang).common.navAriaLabel
                ]
                [ dsNavLink lang route Home labels.homeLabel
                , dsNavLink lang route About labels.aboutLabel
                , dsNavLink lang route Guarantees labels.guaranteesLabel
                , dsNavLink lang route Docs labels.docsLabel
                ]
            , el "div" [ class_ "navbar-end hidden gap-1 md:flex" ]
                [ el "a"
                    [ href bookingUrl, target_ "_blank", rel_ "noopener noreferrer", class_ "btn btn-ghost btn-sm" ]
                    [ text "GH" ]
                , renderThemeDropdown labels
                , renderLangDropdown lang route labels
                ]
            , el "div" [ class_ "navbar-end md:hidden" ]
                [ el "label"
                    [ for_ siteDrawerId, class_ "btn btn-square btn-ghost drawer-button", ariaLabel labels.menuLabel ]
                    [ text "≡" ]
                ]
            ]
        ]
    ]

dsNavLink :: Lang -> Route -> Route -> String -> Html
dsNavLink lang current target label =
  el "a"
    [ href (routeUrl lang target)
    , dsNavGet lang target
    , class_ ("btn btn-ghost btn-sm" <> if target == current then " text-primary font-semibold" else "")
    ]
    [ text label ]

renderThemeDropdown :: ShellLabels -> Html
renderThemeDropdown labels =
  el "div"
    [ class_ "dropdown dropdown-end"
    , dsOnClickOutside DsThemeMenuOpen
    , dsOnKeydownEscape DsThemeMenuOpen
    ]
    [ el "button"
        [ attr "type" "button"
        , class_ "btn btn-ghost btn-sm"
        , ariaLabel labels.themeLabel
        , attr "aria-haspopup" "menu"
        , dsToggleFlag DsThemeMenuOpen
        ]
        [ text "◐" ]
    , el "ul"
        [ dsShowFlag DsThemeMenuOpen
        , class_ "menu menu-sm dropdown-content rounded-box z-50 mt-3 w-52 bg-base-100 p-2 shadow"
        ]
        [ themeMenuItem "light" labels.themeLight
        , themeMenuItem "dark" labels.themeDark
        , themeMenuItem "system" labels.themeSystem
        ]
    ]

themeMenuItem :: String -> String -> Html
themeMenuItem value label =
  el "li" []
    [ el "button"
        [ class_ "btn btn-ghost btn-sm w-full justify-start"
        , dsClassWhenEq "btn-active" "theme" value
        , attr "type" "button"
        , dsSetTheme value
        ]
        [ text label ]
    ]

renderLangDropdown :: Lang -> Route -> ShellLabels -> Html
renderLangDropdown currentLang route labels =
  el "div"
    [ class_ "dropdown dropdown-end"
    , dsOnClickOutside DsLangMenuOpen
    , dsOnKeydownEscape DsLangMenuOpen
    ]
    [ el "button"
        [ attr "type" "button"
        , class_ "btn btn-ghost btn-sm gap-1"
        , ariaLabel labels.langToggleLabel
        , attr "aria-haspopup" "menu"
        , dsToggleFlag DsLangMenuOpen
        ]
        [ text (toUpper (langTag currentLang)) ]
    , el "ul"
        [ dsShowFlag DsLangMenuOpen
        , class_ "menu menu-sm dropdown-content rounded-box z-50 mt-3 w-52 bg-base-100 p-2 shadow"
        ]
        [ langMenuItem En currentLang labels.langEn
        , langMenuItem Fr currentLang labels.langFr
        , langMenuItem Pt currentLang labels.langPt
        ]
    ]
  where
  -- Which language is "current" is fixed at render time (a real navigation,
  -- not a client signal) -- a static class, same as SiteShell's own
  -- dropdownItemClasses (targetLang == currentLang), not a dsClassWhen*.
  langMenuItem targetLang current label =
    el "li" []
      [ el "a"
          [ href (routeUrl targetLang route)
          , dsNavGet targetLang route
          , class_ ("btn btn-ghost btn-sm w-full justify-start" <> if targetLang == current then " btn-active" else "")
          , dsSetFlag DsLangMenuOpen false
          ]
          [ text label ]
      ]

renderDrawerSide :: Lang -> Route -> ShellLabels -> Html
renderDrawerSide lang route labels =
  el "div" [ class_ "drawer-side z-50 md:hidden" ]
    [ el "label" [ for_ siteDrawerId, class_ "drawer-overlay", ariaLabel labels.closeSidebarLabel ] []
    , el "div"
        [ class_ "flex min-h-full w-80 flex-col bg-base-200 p-4 text-base-content" ]
        [ el "div" [ class_ "flex items-center justify-between" ]
            [ el "span" [ class_ "text-lg font-semibold" ] [ text labels.siteTitle ]
            , el "label" [ for_ siteDrawerId, class_ "btn btn-ghost btn-sm", ariaLabel labels.closeMenuLabel ]
                [ text labels.closeLabel ]
            ]
        , el "nav" [ class_ "menu mt-6 w-full rounded-box bg-base-100 p-2" ]
            [ mobileNavLink lang route Home labels.homeLabel
            , mobileNavLink lang route About labels.aboutLabel
            , mobileNavLink lang route Guarantees labels.guaranteesLabel
            , mobileNavLink lang route Docs labels.docsLabel
            ]
        ]
    ]

mobileNavLink :: Lang -> Route -> Route -> String -> Html
mobileNavLink lang current target label =
  el "li" []
    [ el "a"
        [ href (routeUrl lang target)
        , dsNavGet lang target
        , class_ ("btn btn-ghost justify-start" <> if target == current then " text-primary font-semibold" else "")
        ]
        [ text label ]
    ]

-- | Footer isn't in ticket 04's scope (no reactivity there today) -- plain
-- | links, same markup shape as SiteShell's, no Datastar attributes needed.
renderFooterPlain :: Lang -> Route -> ShellLabels -> Html
renderFooterPlain lang route labels =
  el "footer"
    [ class_ "border-t border-base-300 bg-secondary text-secondary-content"
    , attr "data-theme" "pohjola-dark"
    , attr Contract.marker Contract.siteFooter
    ]
    [ Container.container Container.ContainerW6xl "px-4 py-10 sm:px-6"
        [ el "div" [ class_ "footer sm:footer-horizontal" ]
            [ el "aside" []
                [ el "p" [ class_ "font-semibold" ] [ text labels.siteTitle ]
                , el "p" [ class_ "text-sm opacity-70" ] [ text labels.copyright ]
                ]
            , el "nav" []
                [ el "h6" [ class_ "footer-title" ] [ text labels.footerExploreTitle ]
                , footerLink lang route Home labels.homeLabel
                , footerLink lang route About labels.aboutLabel
                ]
            ]
        ]
    ]

footerLink :: Lang -> Route -> Route -> String -> Html
footerLink lang _ target label =
  el "a" [ href (routeUrl lang target), class_ "link link-hover" ] [ text label ]

-- | Full document wrapper for the Datastar-transport version of a page --
-- | deliberately NOT App.Layout.Page.renderDocument (that stays untouched,
-- | hardcoded to the two Alpine scripts, so the Alpine baseline keeps
-- | working unmodified). Minimal head: this is a comparison spike, not a
-- | production page -- no prefetch links, no full SEO meta, just enough to
-- | render and function correctly. CSP is enforced server-side via
-- | headers regardless of body content, so the nonce here only needs to
-- | match what the response's CSP header already pins.
renderDsDocument :: String -> Lang -> Html -> String
renderDsDocument nonce lang content =
  render $
    doctype
      <> el "html" [ attr "lang" (langTag lang) ]
        [ el "head" []
            [ el "meta" [ attr "charset" "UTF-8" ] []
            , el "meta" [ attr "name" "viewport", attr "content" "width=device-width, initial-scale=1.0" ] []
            , el "title" [] [ text "Pohjola (Datastar spike)" ]
            , el "style" [] [ text stylesCss ]
            ]
        , el "body" []
            [ content
            , el "script" [ type_ "module", src "/assets/js/datastar.js", attr "nonce" nonce ] []
            , renderHeadScript nonce DsShellRouter
            ]
        ]
