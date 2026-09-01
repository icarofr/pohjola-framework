-- | Typed architectural contract — single source of truth for policy scans.
-- |
-- | Enforced by `make gate` (Test.Gate) and `Test.PolicySpec`. No JSON manifest.
-- | Extend this module when the closed surface grows; agents cannot bypass by
-- | editing a config file.
module Policy.Contract
  ( bannedSubstrings
  , contentFirewallGlobPatterns
  , contentFirewallPattern
  , envReadAllowlist
  , featureViewGlobPatterns
  , forbiddenCallsInFeatureViews
  , forbiddenImportsInFeatureViews
  , forbiddenInAppUi
  , forbiddenInFeatureViews
  , forbiddenThemeLiterals
  , ffiAllowlist
  , policyScanExclusions
  , scriptAllowlist
  , textToneAllowlist
  , textTonePattern
  , uiPrimitiveModules
  , uiTemplateModules
  ) where

-- | Modules that quote policy literals — excluded from content scans.
policyScanExclusions :: Array String
policyScanExclusions =
  [ "src/Policy/Contract.purs" ]

-- | Foreign import is allowed only in these modules (ADR-003).
ffiAllowlist :: Array String
ffiAllowlist =
  [ "src/App/ServerBun.purs"
  , "src/App/FetchBun.purs"
  , "src/App/Bun.purs"
  , "src/App/Data/SQL.purs"
  ]

scriptAllowlist :: Array String
scriptAllowlist =
  [ "src/App/Layout/Scripts.purs"
  , "src/App/Layout/Page.purs"
  ]

envReadAllowlist :: Array String
envReadAllowlist =
  [ "src/App/Env.purs"
  ]

bannedSubstrings :: Array String
bannedSubstrings =
  [ "unsafeCoerce"
  , "unsafePerformEffect"
  , "unsafePartial"
  , "unsafeCompare"
  , "unsafeIndex"
  , "Data.Maybe.Unsafe"
  , "Data.Array.Unsafe"
  , "Data.String.CodePoint.Unsafe"
  , "Data.String.Unsafe"
  , "Data.Unsafe"
  , "fromJust"
  , "throwException"
  , "catchException"
  , "Effect.Unsafe"
  , "Partial"
  ]

featureViewGlobPatterns :: Array String
featureViewGlobPatterns =
  [ "src/App/Features/*/Page.purs"
  , "src/App/Features/*/View.purs"
  , "src/App/Features/*/Components/*.purs"
  ]

contentFirewallGlobPatterns :: Array String
contentFirewallGlobPatterns =
  [ "src/App/Features/*/Page.purs"
  , "src/App/Features/*/View.purs"
  ]

-- | Feature views fill template slots only — no styling or primitive soup (ADR-012).
forbiddenInFeatureViews :: Array String
forbiddenInFeatureViews =
  [ "class_"
  , "mx-auto max-w-"
  , "text-base-content/"
  ]

forbiddenImportsInFeatureViews :: Array String
forbiddenImportsInFeatureViews =
  [ "App.Ui.Card"
  , "App.Ui.Container"
  , "App.Ui.Hero"
  , "App.Ui.Prose"
  , "App.Ui.Alert"
  , "App.Ui.Badge"
  , "App.Ui.Form"
  , "App.Ui.Divider"
  , "App.Ui.EmptyState"
  , "App.Ui.Avatar"
  , "App.Ui.Button"
  , "App.Ui.Breadcrumbs"
  , "App.Ui.Stat"
  ]

forbiddenCallsInFeatureViews :: Array String
forbiddenCallsInFeatureViews =
  [ "Ui.page"
  , "Ui.hero"
  , "Ui.container"
  , "Ui.stack"
  , "Ui.sectionTitle"
  , "Ui.prose"
  , "Ui.proseLg"
  , "Ui.alert"
  , "Ui.badge"
  , "Ui.card"
  , "cardBody"
  , "cardTitle"
  , "cardText"
  , "cardActions"
  , "pageLayout"
  , "pageHeader"
  , "pageSection"
  , "conversionSection"
  , "sectionHeader"
  , "innerPageHeader"
  ]

forbiddenInAppUi :: Array String
forbiddenInAppUi = []

contentFirewallPattern :: String
contentFirewallPattern = "text \"[A-Za-z0-9]"

textTonePattern :: String
textTonePattern = "text-base-content/"

textToneAllowlist :: Array String
textToneAllowlist =
  [ "src/App/Ui/TextTone.purs"
  ]

forbiddenThemeLiterals :: Array String
forbiddenThemeLiterals =
  [ "setAttribute('data-theme', 'light')"
  , "setAttribute('data-theme', 'dark')"
  ]

-- | Closed set — new page templates require extending Policy.Contract + ADR.
uiTemplateModules :: Array String
uiTemplateModules =
  [ "src/App/Ui/Templates/ActionLink.purs"
  , "src/App/Ui/Templates/Article.purs"
  , "src/App/Ui/Templates/Contract.purs"
  , "src/App/Ui/Templates/Editorial.purs"
  , "src/App/Ui/Templates/Feed.purs"
  , "src/App/Ui/Templates/Hub.purs"
  , "src/App/Ui/Templates/Landing.purs"
  , "src/App/Ui/Templates/PageHeader.purs"
  , "src/App/Ui/Templates/Render.purs"
  , "src/App/Ui/Templates/Schedule.purs"
  , "src/App/Ui/Templates/SiteShell.purs"
  , "src/App/Ui/Templates/Types.purs"
  ]

-- | DaisyUI primitives — styling lives here, not in new ad-hoc Ui modules.
uiPrimitiveModules :: Array String
uiPrimitiveModules =
  [ "src/App/Ui/Alert.purs"
  , "src/App/Ui/Avatar.purs"
  , "src/App/Ui/Badge.purs"
  , "src/App/Ui/Breadcrumbs.purs"
  , "src/App/Ui/Button.purs"
  , "src/App/Ui/Card.purs"
  , "src/App/Ui/Container.purs"
  , "src/App/Ui/Divider.purs"
  , "src/App/Ui/EmptyState.purs"
  , "src/App/Ui/Form.purs"
  , "src/App/Ui/Prose.purs"
  , "src/App/Ui/Stat.purs"
  , "src/App/Ui/TextTone.purs"
  ]
