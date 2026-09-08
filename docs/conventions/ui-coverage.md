# UI coverage map (generated)

Regenerate: `make ui-coverage`

Maps `App.Ui` primitives to DaisyUI vendor docs. Feature views must not import these — use `App.Ui.Templates` slots (`docs/conventions/component-checklist.md`).

## App.Ui primitives

| Module | DaisyUI doc | Source |
|---|---|---|
| `App.Ui.Alert` | [alert](vendor/daisyui/skills/daisyui/components/alert.md) | `/home/irocha/projects/pohjola/src/App/Ui/Alert.purs` |
| `App.Ui.Avatar` | [avatar](vendor/daisyui/skills/daisyui/components/avatar.md) | `/home/irocha/projects/pohjola/src/App/Ui/Avatar.purs` |
| `App.Ui.Badge` | — | `/home/irocha/projects/pohjola/src/App/Ui/Badge.purs` |
| `App.Ui.Breadcrumbs` | [breadcrumbs](vendor/daisyui/skills/daisyui/components/breadcrumbs.md) | `/home/irocha/projects/pohjola/src/App/Ui/Breadcrumbs.purs` |
| `App.Ui.Button` | [button](vendor/daisyui/skills/daisyui/components/button.md) | `/home/irocha/projects/pohjola/src/App/Ui/Button.purs` |
| `App.Ui.Card` | [card](vendor/daisyui/skills/daisyui/components/card.md) | `/home/irocha/projects/pohjola/src/App/Ui/Card.purs` |
| `App.Ui.Container` | — | `/home/irocha/projects/pohjola/src/App/Ui/Container.purs` |
| `App.Ui.Divider` | — | `/home/irocha/projects/pohjola/src/App/Ui/Divider.purs` |
| `App.Ui.EmptyState` | — | `/home/irocha/projects/pohjola/src/App/Ui/EmptyState.purs` |
| `App.Ui.Form` | [fieldset](vendor/daisyui/skills/daisyui/components/fieldset.md) | `/home/irocha/projects/pohjola/src/App/Ui/Form.purs` |
| `App.Ui.Prose` | — | `/home/irocha/projects/pohjola/src/App/Ui/Prose.purs` |
| `App.Ui.Stat` | [stat](vendor/daisyui/skills/daisyui/components/stat.md) | `/home/irocha/projects/pohjola/src/App/Ui/Stat.purs` |
| `App.Ui.TextTone` | — | `/home/irocha/projects/pohjola/src/App/Ui/TextTone.purs` |

## Page templates

| Module | Role |
|---|---|
| `App.Ui.Templates.SiteShell` | Site chrome (drawer, navbar, footer, theme) |
| `App.Ui.Templates.Landing` | Marketing landing |
| `App.Ui.Templates.Hub` | Card hub + optional breadcrumbs |
| `App.Ui.Templates.Editorial` | Long-form static |
| `App.Ui.Templates.Feed` | Post/list grid |
| `App.Ui.Templates.Article` | Article detail |
| `App.Ui.Templates.Schedule` | Fixture/match list |
| `App.Ui.Templates.Form` | Form page (fieldset + submit) |

## Chrome-only (SiteShell, not App.Ui primitives)



## Vendor docs without App.Ui wrapper yet

_All vendor components are either wrapped or chrome-only._
