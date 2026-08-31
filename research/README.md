# Local research (optional)

This directory is for **optional local clones** of libraries you are evaluating.
It is gitignored except this README — nothing here ships with the app.

## daisyUI

Use the tracked submodule instead:

```bash
git submodule update --init --depth 1 vendor/daisyui
```

See `vendor/README.md`. Component skill files:
`vendor/daisyui/skills/daisyui/components/*.md`.

## Other clones

You may keep ad-hoc clones here (`htmx/`, `shadcn/`, etc.) for comparison.
They are not build inputs and are not required for `make check`.
