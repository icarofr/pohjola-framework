# 04: Local UI port — theme dropdown, language dropdown, mobile drawer

**What to build:** The theme dropdown (Light/Dark/System), the language
dropdown, and the mobile drawer (hamburger open, close button, Escape-to-close)
on `Home` and `About` are reimplemented on `App.Datastar` signals instead of
Alpine core's `x-data`/`x-show`/`@click.outside`, with identical behavior:
open/close, close-on-outside-click, close-on-Escape, and active-item
highlighting (the current `text-primary font-semibold` treatment for the
active nav link and theme/lang selection state). The DaisyUI visual classes
(`dropdownTriggerClass`, `dropdownPanelClass`, `dropdownItemClass(es)`) are
unchanged — only the reactivity attributes swap, not the CSS.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Theme dropdown opens/closes, closes on outside click, closes on Escape, and correctly highlights the active theme, on the Datastar-powered pages
- [ ] Language dropdown has the same behavior and correctly highlights the current language
- [ ] Mobile drawer opens/closes, closes on Escape, matching current behavior
- [ ] All three widgets render with the same DaisyUI classes as the Alpine versions — no visual difference
- [ ] A spike-local raw-playwright-core script verifies all of the above against both the Datastar version and the current Alpine version of the same two pages, side by side
- [ ] `make gate && make test` pass on the branch (existing Alpine-based `ContractSpec`/`ShellSpec` assertions remain green and unmodified)

## Comments

From `.scratch/datastar-streaming-transport/spec.md`, broken down via `/to-tickets`. Runs after 02; independent of 03 (shell-nav port) and can proceed in parallel with it. Both 03 and 04 block 05 (measure and report).
