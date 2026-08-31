# Vendored references

## daisyUI (`vendor/daisyui`)

Git submodule — [saadeghi/daisyui](https://github.com/saadeghi/daisyui).

After clone:

```bash
git submodule update --init --depth 1 vendor/daisyui
```

**Agent use:** read component recipes under `vendor/daisyui/skills/daisyui/components/`.
Do not copy class strings into feature views — map findings to `App.Ui` primitives
or `App.Ui.Templates` slot recipes.

**Humans:** optional full clone for deeper inspection; `make deps` initializes the submodule.
