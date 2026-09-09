-- | Site chrome — DaisyUI drawer, navbar, theme dropdown, and footer,
-- | rendered entirely through App.Datastar's typed constructors (ADR-000,
-- | ADR-011). The production replacement for the Alpine-based SiteShell this
-- | module superseded on 2026-09-09 — see .scratch/datastar-streaming-transport
-- | for the spike that measured the transport swap before this became the
-- | production chrome.
module App.DatastarShell
  ( dsSitePage
  , dsSiteErrorPage
  , renderDsDocument
  , dsActiveNavClass
  , dsDropdownItemClass
  , dsDropdownItemClasses
  , dsDropdownPanelClass
  , siteDrawerId
  ) where

import Prelude

import App.Layout.Head (renderHead)
import App.Layout.Scripts (HeadScript(..), renderHeadScript)
import App.Datastar
  ( DsFlag(..)
  , contentTarget
  , dataPageLangAttr
  , dataPageTitleAttr
  , dsClassWhenFlag
  , dsClassWhenTheme
  , dsLangLink
  , dsNavLinkRecord
  , dsOnClickOutside
  , dsOnKeydownEscape
  , dsSetFlag
  , dsSetTheme
  , dsShowFlag
  , dsShowTheme
  , dsSignalsInit
  , dsToggleFlag
  )
import App.Form (FormStatus(..), formStatusQuery, statusText)
import App.Html (Attr, Html, ariaLabel, attr, class_, doctype, el, for_, href, id_, rel_, render, src, target_, text, type_)
import App.Theme (ThemeMode(..))
import App.Ui.Alert (AlertVariant(..), alert)
import App.Ui.Container as Container
import App.Ui.Templates.Contract as Contract
import Data.Content (bookingUrl, issuesUrl)
import Data.I18n (Lang(..), dict, langTag)
import Data.Maybe (Maybe(..), maybe)
import Data.Route (Route(..), routeTitle)
import Data.String.Common (toUpper)

siteDrawerId :: String
siteDrawerId = "site-drawer"

type ShellLabels =
  { siteTitle :: String
  , menuLabel :: String
  , homeLabel :: String
  , langEn :: String
  , langFr :: String
  , langPt :: String
  , langToggleLabel :: String
  , themeLight :: String
  , themeDark :: String
  , themeSystem :: String
  , themeLabel :: String
  , copyright :: String
  , closeSidebarLabel :: String
  , closeMenuLabel :: String
  , closeLabel :: String
  , aboutLabel :: String
  , guaranteesLabel :: String
  , docsLabel :: String
  , githubLabel :: String
  , issuesLabel :: String
  , footerExploreTitle :: String
  , footerResourcesTitle :: String
  }

shellLabels :: Lang -> ShellLabels
shellLabels lang =
  let
    d = dict lang
  in
    { siteTitle: d.common.siteTitle
    , menuLabel: d.common.menuLabel
    , homeLabel: d.nav.home
    , langEn: "English"
    , langFr: "Français"
    , langPt: "Português"
    , langToggleLabel: d.common.langToggleLabel
    , themeLight: d.common.themeLight
    , themeDark: d.common.themeDark
    , themeSystem: d.common.themeSystem
    , themeLabel: d.common.themeLabel
    , copyright: d.footer.copyright
    , closeSidebarLabel: d.common.closeSidebarLabel
    , closeMenuLabel: d.common.closeMenuLabel
    , closeLabel: d.common.closeLabel
    , aboutLabel: d.nav.about
    , guaranteesLabel: d.nav.guarantees
    , docsLabel: d.nav.docs
    , githubLabel: d.footer.github
    , issuesLabel: d.footer.issues
    , footerExploreTitle: d.footer.explore
    , footerResourcesTitle: d.footer.resources
    }

-- | Centralized so shell edits cannot forget them — same rationale
-- | App.Alpine's dropdownTriggerClass/dropdownPanelClass/dropdownItemClass
-- | carried, one recipe both dropdowns share.
dsDropdownTriggerClass :: String
dsDropdownTriggerClass = "btn btn-ghost btn-sm"

dsDropdownPanelClass :: String
dsDropdownPanelClass = "menu menu-sm dropdown-content rounded-box z-50 mt-3 w-52 bg-base-100 p-2 shadow"

dsDropdownItemClass :: String
dsDropdownItemClass = "btn btn-ghost btn-sm w-full justify-start"

dsDropdownItemClasses :: Boolean -> String
dsDropdownItemClasses isActive = dsDropdownItemClass <> if isActive then " btn-active" else ""

-- | Desktop/mobile nav active-item treatment (text-primary, not a filled
-- | pill). Footer links use a fixed class regardless of active state
-- | instead — see footerLink.
dsActiveNavClass :: String -> Boolean -> String
dsActiveNavClass base isActive = base <> if isActive then " text-primary font-semibold" else ""

maybeStatusBanner :: Lang -> Maybe FormStatus -> Html
maybeStatusBanner lang = maybe (text "") \status ->
  let
    variant = case status of
      FormSuccess -> AlertSuccess
      FormError -> AlertError
      FormSubscribed -> AlertSuccess
  in
    el "div" [ attr "data-form-status" (formStatusQuery status) ]
      [ alert variant (statusText lang status) ]

-- | Same #content/data-page-* contract App.Layout.Scripts' dsShellRouterScript
-- | reads. Title is computed from the route; dsSitePageTitled below exists
-- | only for the error page, which needs a title with no Route of its own.
dsSitePage :: Lang -> Route -> Maybe FormStatus -> Html -> Html
dsSitePage lang route status content =
  dsSitePageTitled lang route (routeTitle lang route) status content

dsSitePageTitled :: Lang -> Route -> String -> Maybe FormStatus -> Html -> Html
dsSitePageTitled lang route title status content =
  let
    labels = shellLabels lang
  in
    el "div"
      [ class_ "drawer drawer-end min-h-dvh bg-base-100 text-base-content"
      , id_ contentTarget
      , attr dataPageTitleAttr title
      , attr dataPageLangAttr (langTag lang)
      , dsSignalsInit
      , dsOnKeydownEscape DsDrawerOpen
      ]
      [ el "input" [ type_ "checkbox", class_ "drawer-toggle", id_ siteDrawerId ] []
      , el "div" [ class_ "drawer-content flex min-h-full flex-col" ]
          [ renderHeader lang route labels
          , maybeStatusBanner lang status
          , el "main" [ class_ "flex-1" ] [ content ]
          , renderFooter lang route labels
          ]
      , renderDrawerSide lang route labels
      ]

dsSiteErrorPage :: Lang -> Int -> Html
dsSiteErrorPage lang statusCode =
  let
    labels = shellLabels lang
    title = show statusCode <> " - " <> labels.siteTitle
    body =
      el "div" [ class_ "mx-auto max-w-3xl px-6 py-24 text-center" ]
        [ el "h1" [ class_ "text-5xl font-semibold tracking-tight" ] [ text (show statusCode) ]
        , el "p" [ class_ "mt-6 text-lg opacity-70" ] [ text (errorMessage lang statusCode) ]
        ]
  in
    -- Home stands in for the current route: an error page has none of its
    -- own, and Home is guaranteed to exist (it's the one route every build
    -- of this framework always has).
    dsSitePageTitled lang Home title Nothing body

errorMessage :: Lang -> Int -> String
errorMessage lang status =
  let
    d = dict lang
  in
    if status == 404 then d.common.error404 else d.common.error500

-- | DESIGN.md's Elevation & Depth "Level 2 (Dock / Terminal)" — see
-- | App.Ui.Templates.SiteShell's original doc comment for the full
-- | rationale (this shell's header/footer inherit it unchanged).
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
                [ dsNavLinkRecord { lang, current: route, target: Home }
                    [ class_ "btn btn-ghost text-lg font-semibold" ]
                    [ text labels.siteTitle ]
                ]
            , el "nav"
                [ class_ "navbar-center hidden gap-1 md:flex"
                , ariaLabel (dict lang).common.navAriaLabel
                ]
                [ desktopNavLink lang route Home labels.homeLabel
                , desktopNavLink lang route About labels.aboutLabel
                , desktopNavLink lang route Guarantees labels.guaranteesLabel
                , desktopNavLink lang route Docs labels.docsLabel
                ]
            , el "div" [ class_ "navbar-end hidden gap-1 md:flex" ]
                [ githubLink labels
                , renderThemeDropdown labels
                , renderLangDropdown lang route labels
                ]
            , el "div" [ class_ "navbar-end md:hidden" ]
                [ el "label"
                    [ for_ siteDrawerId, class_ "btn btn-square btn-ghost drawer-button", ariaLabel labels.menuLabel ]
                    [ hamburgerIcon ]
                ]
            ]
        ]
    ]

desktopNavLink :: Lang -> Route -> Route -> String -> Html
desktopNavLink lang current target label =
  dsNavLinkRecord { lang, current, target }
    [ class_ (dsActiveNavClass "btn btn-ghost btn-sm" (target == current)) ]
    [ text label ]

-- | Same URL as Home's hero CTA (Data.Content.bookingUrl) — the one GitHub
-- | link every page shares. Icon-only, same as the theme toggle beside it.
githubLink :: ShellLabels -> Html
githubLink labels =
  el "a"
    [ href bookingUrl
    , target_ "_blank"
    , rel_ "noopener noreferrer"
    , class_ dsDropdownTriggerClass
    , ariaLabel labels.githubLabel
    ]
    [ githubIcon ]

renderThemeDropdown :: ShellLabels -> Html
renderThemeDropdown labels =
  el "div"
    [ class_ "dropdown dropdown-end"
    , dsClassWhenFlag "dropdown-open" DsThemeMenuOpen
    , dsOnClickOutside DsThemeMenuOpen
    , dsOnKeydownEscape DsThemeMenuOpen
    ]
    [ el "button"
        [ attrTypeButton
        , class_ dsDropdownTriggerClass
        , ariaLabel labels.themeLabel
        , attr "aria-haspopup" "menu"
        , dsToggleFlag DsThemeMenuOpen
        ]
        [ sunIcon, moonIcon, systemIcon ]
    , el "ul"
        [ dsShowFlag DsThemeMenuOpen
        , class_ dsDropdownPanelClass
        ]
        [ themeMenuItem ThemeLight labels.themeLight
        , themeMenuItem ThemeDark labels.themeDark
        , themeMenuItem ThemeSystem labels.themeSystem
        ]
    ]

themeMenuItem :: ThemeMode -> String -> Html
themeMenuItem mode label =
  el "li" []
    [ el "button"
        [ class_ dsDropdownItemClass
        , dsClassWhenTheme "btn-active" mode
        , attrTypeButton
        , dsSetTheme mode
        ]
        [ text label ]
    ]

renderLangDropdown :: Lang -> Route -> ShellLabels -> Html
renderLangDropdown currentLang route labels =
  el "div"
    [ class_ "dropdown dropdown-end"
    , dsClassWhenFlag "dropdown-open" DsLangMenuOpen
    , dsOnClickOutside DsLangMenuOpen
    , dsOnKeydownEscape DsLangMenuOpen
    ]
    [ el "button"
        [ attrTypeButton
        , class_ (dsDropdownTriggerClass <> " gap-1")
        , ariaLabel labels.langToggleLabel
        , attr "aria-haspopup" "menu"
        , dsToggleFlag DsLangMenuOpen
        ]
        [ globeIcon, text (toUpper (langTag currentLang)) ]
    , el "ul"
        [ dsShowFlag DsLangMenuOpen
        , class_ dsDropdownPanelClass
        ]
        [ langMenuItem En currentLang route labels.langEn
        , langMenuItem Fr currentLang route labels.langFr
        , langMenuItem Pt currentLang route labels.langPt
        ]
    ]

-- | Which language is "current" is fixed at render time (a real navigation,
-- | not a client signal) — a static class, matching dropdownItemClasses.
langMenuItem :: Lang -> Lang -> Route -> String -> Html
langMenuItem targetLang currentLang route label =
  el "li" []
    [ dsLangLink { targetLang, currentLang, route }
        [ class_ (dsDropdownItemClasses (targetLang == currentLang))
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
            , el "li" [] [ githubLink labels ]
            , el "li" [ class_ "menu-title mt-4" ] [ text labels.themeLabel ]
            , themeMenuItem ThemeLight labels.themeLight
            , themeMenuItem ThemeDark labels.themeDark
            , themeMenuItem ThemeSystem labels.themeSystem
            , el "li" [ class_ "menu-title mt-4" ] [ text labels.langToggleLabel ]
            , langMenuItem En lang route labels.langEn
            , langMenuItem Fr lang route labels.langFr
            , langMenuItem Pt lang route labels.langPt
            ]
        ]
    ]

mobileNavLink :: Lang -> Route -> Route -> String -> Html
mobileNavLink lang current target label =
  el "li" []
    [ dsNavLinkRecord { lang, current, target }
        [ class_ (dsActiveNavClass "btn btn-ghost justify-start" (target == current)) ]
        [ text label ]
    ]

-- | Two real nav sections: `explore` (all four pages) plus `resources`
-- | (GitHub source + issues) — matching App.Ui.Templates.SiteShell's footer
-- | exactly, all four routes now that every route is ported.
renderFooter :: Lang -> Route -> ShellLabels -> Html
renderFooter lang route labels =
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
                ( [ el "h6" [ class_ "footer-title" ] [ text labels.footerExploreTitle ] ]
                    <>
                      [ footerLink lang route Home labels.homeLabel
                      , footerLink lang route About labels.aboutLabel
                      , footerLink lang route Guarantees labels.guaranteesLabel
                      , footerLink lang route Docs labels.docsLabel
                      ]
                )
            , el "nav" []
                [ el "h6" [ class_ "footer-title" ] [ text labels.footerResourcesTitle ]
                , footerExternalLink bookingUrl labels.githubLabel
                , footerExternalLink issuesUrl labels.issuesLabel
                ]
            ]
        ]
    ]

-- | Footer links always carry this one class regardless of active state
-- | (matching App.Alpine's navLinkClasses NavFooter, which ignored isActive
-- | entirely) — aria-current/prefetch-skip still come from dsNavLinkRecord.
footerLink :: Lang -> Route -> Route -> String -> Html
footerLink lang current target label =
  dsNavLinkRecord { lang, current, target }
    [ class_ "link link-hover hover:text-primary" ]
    [ text label ]

footerExternalLink :: String -> String -> Html
footerExternalLink url label =
  el "a"
    [ href url, target_ "_blank", rel_ "noopener noreferrer", class_ "link link-hover hover:text-primary" ]
    [ text label ]

attrTypeButton :: Attr
attrTypeButton = attr "type" "button"

hamburgerIcon :: Html
hamburgerIcon =
  el "svg"
    [ attr "xmlns" "http://www.w3.org/2000/svg"
    , class_ "h-5 w-5"
    , attr "fill" "none"
    , attr "viewBox" "0 0 24 24"
    , attr "stroke" "currentColor"
    ]
    [ el "path"
        [ attr "stroke-linecap" "round"
        , attr "stroke-linejoin" "round"
        , attr "stroke-width" "2"
        , attr "d" "M4 6h16M4 12h16M4 18h16"
        ]
        []
    ]

-- | Trigger icon reflects the *selected* preference, not the resolved
-- | color scheme — all three sit in the DOM and toggle via dsShowTheme
-- | against the same `theme` signal dsClassWhenTheme reads for the active
-- | menu item, so the icon and the checked entry always agree.
sunIcon :: Html
sunIcon =
  el "svg"
    [ attr "xmlns" "http://www.w3.org/2000/svg"
    , class_ "h-5 w-5"
    , attr "fill" "none"
    , attr "viewBox" "0 0 24 24"
    , attr "stroke" "currentColor"
    , attr "stroke-width" "2"
    , attr "stroke-linecap" "round"
    , attr "stroke-linejoin" "round"
    , dsShowTheme ThemeLight
    ]
    [ el "circle" [ attr "cx" "12", attr "cy" "12", attr "r" "5" ] []
    , el "path"
        [ attr "d"
            "M12 1v2M12 21v2M4.2 4.2l1.4 1.4M18.4 18.4l1.4 1.4M1 12h2M21 12h2M4.2 19.8l1.4-1.4M18.4 5.6l1.4-1.4"
        ]
        []
    ]

moonIcon :: Html
moonIcon =
  el "svg"
    [ attr "xmlns" "http://www.w3.org/2000/svg"
    , class_ "h-5 w-5"
    , attr "fill" "none"
    , attr "viewBox" "0 0 24 24"
    , attr "stroke" "currentColor"
    , attr "stroke-width" "2"
    , attr "stroke-linecap" "round"
    , attr "stroke-linejoin" "round"
    , dsShowTheme ThemeDark
    ]
    [ el "path"
        [ attr "d" "M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" ]
        []
    ]

systemIcon :: Html
systemIcon =
  el "svg"
    [ attr "xmlns" "http://www.w3.org/2000/svg"
    , class_ "h-5 w-5"
    , attr "fill" "none"
    , attr "viewBox" "0 0 24 24"
    , attr "stroke" "currentColor"
    , attr "stroke-width" "2"
    , attr "stroke-linecap" "round"
    , attr "stroke-linejoin" "round"
    , dsShowTheme ThemeSystem
    ]
    [ el "rect" [ attr "x" "3", attr "y" "4", attr "width" "18", attr "height" "13", attr "rx" "2" ] []
    , el "path" [ attr "d" "M8 21h8M12 17v4" ] []
    ]

globeIcon :: Html
globeIcon =
  el "svg"
    [ attr "xmlns" "http://www.w3.org/2000/svg"
    , class_ "h-4 w-4"
    , attr "fill" "none"
    , attr "viewBox" "0 0 24 24"
    , attr "stroke" "currentColor"
    , attr "stroke-width" "2"
    , attr "stroke-linecap" "round"
    , attr "stroke-linejoin" "round"
    ]
    [ el "circle" [ attr "cx" "12", attr "cy" "12", attr "r" "9" ] []
    , el "path" [ attr "d" "M3 12h18M12 3c2.5 2.7 3.8 6 3.8 9s-1.3 6.3-3.8 9c-2.5-2.7-3.8-6-3.8-9s1.3-6.3 3.8-9z" ] []
    ]

githubIcon :: Html
githubIcon =
  el "svg"
    [ attr "xmlns" "http://www.w3.org/2000/svg"
    , class_ "h-5 w-5"
    , attr "viewBox" "0 0 24 24"
    , attr "fill" "currentColor"
    ]
    [ el "path"
        [ attr "d"
            "M12 .5C5.65.5.5 5.65.5 12c0 5.08 3.29 9.39 7.86 10.91.57.1.78-.25.78-.55 0-.27-.01-1.16-.02-2.11-3.2.7-3.87-1.36-3.87-1.36-.53-1.33-1.29-1.69-1.29-1.69-1.05-.72.08-.7.08-.7 1.17.08 1.78 1.2 1.78 1.2 1.03 1.77 2.71 1.26 3.37.96.1-.75.4-1.26.73-1.55-2.55-.29-5.24-1.28-5.24-5.69 0-1.26.45-2.29 1.19-3.09-.12-.29-.52-1.46.11-3.05 0 0 .97-.31 3.18 1.18a11 11 0 0 1 2.9-.39c.98 0 1.97.13 2.9.39 2.2-1.49 3.17-1.18 3.17-1.18.63 1.59.23 2.76.11 3.05.74.8 1.19 1.83 1.19 3.09 0 4.42-2.69 5.39-5.25 5.68.41.36.78 1.06.78 2.14 0 1.55-.01 2.79-.01 3.17 0 .3.2.66.79.55A10.52 10.52 0 0 0 23.5 12c0-6.35-5.15-11.5-11.5-11.5Z"
        ]
        []
    ]

-- | Full document wrapper — the production HTML shell. Head content
-- | (meta/SEO/OG/hreflang/JSON-LD/inlined CSS) is App.Layout.Head's
-- | existing, complete implementation, unchanged by the transport swap. No
-- | CSP nonce placeholder replacement logic lives here; the caller
-- | (App.Main) threads the same per-request nonce this response's CSP
-- | header pins.
renderDsDocument :: String -> String -> Lang -> Route -> Html -> String
renderDsDocument baseUrl nonce lang route content =
  render $
    doctype
      <> el "html" [ attr "lang" (langTag lang) ]
        [ el "head" [] [ renderHead baseUrl nonce lang route ]
        , el "body" []
            [ content
            , el "script" [ type_ "module", src "/assets/js/datastar.js", attr "nonce" nonce ] []
            , renderHeadScript nonce DsShellRouter
            ]
        ]
