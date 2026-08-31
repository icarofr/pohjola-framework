# ==================================================================================== #
# POHJOLA FRAMEWORK — PureScript + Alpine.js + Tailwind CSS
# ==================================================================================== #

# Paths
#   dist/        — PUBLIC static root ONLY (css, assets, images, favicon).
#                  The server bundle must never live here or it gets served.
#   dist-server/ — bundled server.js (private, never under the static root)
DIST_DIR ?= dist
SERVER_BUNDLE_DIR ?= dist-server
IMAGE_NAME ?= localhost/pohjola-framework:latest

# Local-dev origin. The Origin gate (App.Main.sameOriginOk) requires POSTs
# to match BASE_URL exactly — without this, forms 404 against the prod
# default https://example.com. Production overrides via compose env.
export BASE_URL ?= http://localhost:3000

# spago bundle shells out to esbuild (devDependency, installed locally)
export PATH := $(CURDIR)/node_modules/.bin:$(PATH)

SPAGO := bun x spago

.PHONY: all help deps assets assets-check dev watch css css-watch bundle build sync-static run test test/integration test/integration/down test/e2e check deploy image up down clean gate generator-policy design-policy fast local full ci-equivalent format format-check gen-sql new-feature evals eval

# ==================================================================================== #
# HELPERS
# ==================================================================================== #

## all: build + test — the full local check
.PHONY: all
all: check

## help: print this help message
.PHONY: help
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'

# Paths
.PHONY: format
format:
	bun x purs-tidy format-in-place 'src/**/*.purs' 'test/**/*.purs'

## format-check: verify formatting (runs in make check + CI)
.PHONY: format-check
format-check:
	bun x purs-tidy check 'src/**/*.purs' 'test/**/*.purs'

## gate: structural policy checks (policy/manifest.json)
.PHONY: gate
gate:
	@bun scripts/verify-policy.js

## generator-policy: validate the canonical generator and App.Ui boundary
.PHONY: generator-policy design-policy
generator-policy:
	@bun scripts/verify-generator-fixture.js

design-policy: generator-policy
	@bun scripts/verify-theme.js

# ==================================================================================== #
# DEPENDENCIES
# ==================================================================================== #

## deps: install PureScript dependencies + Bun packages + Alpine JS assets + vendor submodules
.PHONY: deps
deps:
	git submodule update --init --depth 1 vendor/daisyui
	bun install
	$(SPAGO) install
	$(MAKE) assets

# ==================================================================================== #
# ALPINE.JS ASSETS — pinned, self-hosted
# ==================================================================================== #

ALPINE_VERSION := 3.15.12
ALPINE_AJAX_VERSION := 0.12.7
ASSETS_DIR := static/assets/js

## assets: download pinned Alpine.js + Alpine AJAX into static/assets/js/
.PHONY: assets
assets:
	mkdir -p $(ASSETS_DIR)
	curl -fsSL "https://cdn.jsdelivr.net/npm/alpinejs@$(ALPINE_VERSION)/dist/cdn.min.js" -o $(ASSETS_DIR)/alpinejs.min.js
	curl -fsSL "https://cdn.jsdelivr.net/npm/@imacrayon/alpine-ajax@$(ALPINE_AJAX_VERSION)/dist/cdn.min.js" -o $(ASSETS_DIR)/alpine-ajax.min.js
	@echo "Alpine.js $(ALPINE_VERSION) + Alpine AJAX $(ALPINE_AJAX_VERSION) downloaded to $(ASSETS_DIR)/"

## assets-check: verify assets against SHA256SUMS (no download)
.PHONY: assets-check
assets-check:
	@echo "Verifying Alpine.js assets..."
	@shasum -a 256 static/assets/js/alpinejs.min.js static/assets/js/alpine-ajax.min.js | diff -u static/assets/SHA256SUMS -
	@echo "Asset verification OK"

# ==================================================================================== #
# DEVELOPMENT
# ==================================================================================== #

## dev: run Tailwind watcher, Spago watcher, and Bun server with hot reload
.PHONY: dev
dev: css sync-static
	@$(SPAGO) build --strict
	@echo "Starting hot-reload dev environment (Tailwind + Spago + Bun)..."
	@trap 'kill 0' INT TERM EXIT; \
	bun x @tailwindcss/cli -i css/input.css -o $(DIST_DIR)/css/styles.css --watch & \
	bun -e "const { spawn } = require('child_process'), fs = require('fs'); let t; fs.watch('src', { recursive: true }, (e, f) => { if (f && f.endsWith('.purs')) { clearTimeout(t); t = setTimeout(() => spawn('bun', ['spago', 'build', '--pure', '--strict'], { stdio: 'inherit' }), 100); } });" & \
	bun --watch --eval "import('./output/App.Main/index.js').then(m => m.main())"

## watch: PureScript hot rebuild
.PHONY: watch
watch:
	@bun -e "const { spawn } = require('child_process'), fs = require('fs'); let t; console.log('[watch] Watching src/ for changes...'); fs.watch('src', { recursive: true }, (e, f) => { if (f && f.endsWith('.purs')) { clearTimeout(t); t = setTimeout(() => spawn('bun', ['spago', 'build', '--pure', '--strict'], { stdio: 'inherit' }), 100); } });"

## css: compile Tailwind CSS (minified) and embed into PureScript
.PHONY: css
css:
	mkdir -p $(DIST_DIR)/css
	bun x @tailwindcss/cli -i css/input.css -o $(DIST_DIR)/css/styles.css --minify
	bun scripts/embed-css.js

## css-watch: Tailwind CSS hot reload
.PHONY: css-watch
css-watch:
	mkdir -p $(DIST_DIR)/css
	bun x @tailwindcss/cli -i css/input.css -o $(DIST_DIR)/css/styles.css --watch

# ==================================================================================== #
# BUILD
# ==================================================================================== #

## bundle: bundle PureScript server to dist-server/ (NEVER into dist/ —
## dist is the public static root; a bundle there would be served by /server.js)
.PHONY: bundle
bundle:
	mkdir -p $(SERVER_BUNDLE_DIR) $(DIST_DIR)/css $(DIST_DIR)/images
	$(SPAGO) bundle --module App.Main --outfile $(SERVER_BUNDLE_DIR)/server.js --bundle-type app --platform node --pure --strict

## build: production build (bundle JS + Tailwind + static assets)
.PHONY: build
build: css bundle
	# Copy static assets to dist directory
	cp -r static/assets static/images $(DIST_DIR)/ 2>/dev/null || true
	# Ensure favicon is copied 
	cp static/favicon.svg $(DIST_DIR)/ 2>/dev/null || true

## sync-static: sync static assets to dist (for development)
.PHONY: sync-static
sync-static:
	cp -r static/assets static/images $(DIST_DIR)/ 2>/dev/null || true
	cp static/favicon.svg $(DIST_DIR)/ 2>/dev/null || true

# ==================================================================================== #
# RUN
# ==================================================================================== #

## run: full build + run server locally with Bun (assets included —
## bundle alone produces an asset-less server)
.PHONY: run
run: build
	bun $(SERVER_BUNDLE_DIR)/server.js

## migrate: run pending database migrations (requires DATABASE_URL)
## Bundles with MIGRATE_ONLY=1 so the server exits after migrating.
.PHONY: migrate
migrate: bundle
	DATABASE_URL=$${DATABASE_URL:-postgres://postgres:postgres@localhost:5432/app} \
	MIGRATE_ONLY=1 bun $(SERVER_BUNDLE_DIR)/server.js

## migrate-create: create a new empty migration file (usage: make migrate-create NAME=create_users)
.PHONY: migrate-create
migrate-create:
	@test -n "$(NAME)" || { echo "Usage: make migrate-create NAME=create_users"; exit 1; }
	@next=$$(ls migrations/*.sql 2>/dev/null | wc -l | tr -d ' ') && \
		num=$$(printf '%03d' $$((next + 1))) && \
		file="migrations/$${num}_$(NAME).sql" && \
		printf '-- Migration: %s\n-- Add your SQL here (multi-statement OK, no parameters)\n\n' "$$NAME" > $$file && \
		echo "Created $$file"

# ==================================================================================== #
# TESTING
# ==================================================================================== #

## test: run PureScript unit + property tests under Bun (production runtime)
.PHONY: test
test:
	$(SPAGO) build --pure
	bun -e "import { main } from './output/Test.Main/index.js'; main()"

## test/integration: run Venom HTTP tests via Docker Compose
.PHONY: test/integration
test/integration:
	docker compose -f docker-compose.test.yml up --build --abort-on-container-exit --exit-code-from venom

## test/integration/down: tear down integration test containers
.PHONY: test/integration/down
test/integration/down:
	docker compose -f docker-compose.test.yml down -v

## test/e2e: run Playwright browser tests (requires server running)
.PHONY: test/e2e
test/e2e:
	bun x playwright test

## check: full pre-push validation (build + test — mirrors CI)
.PHONY: check
check: full
	@echo "All checks passed."

## fast: cheap local policy and formatting checks
fast: gate format-check

## local: fast checks plus the normal local build
local: fast build

## full: complete local validation (build, tests, assets, formatting)
full: gate design-policy build test assets-check format-check

## ci-equivalent: canonical CI validation target (excluding integration/e2e jobs)
ci-equivalent: full

# ==================================================================================== #
# SCAFFOLDING
# ==================================================================================== #

## new-feature: scaffold a feature (usage: make new-feature NAME=Team [TYPE=data] [SLUG_FR=equipe])
.PHONY: new-feature
new-feature:
	@bun scripts/auto-scaffold.js --name=$(NAME) $(if $(TYPE),--type=$(TYPE),) $(if $(SLUG_EN),--slug-en=$(SLUG_EN),) $(if $(SLUG_FR),--slug-fr=$(SLUG_FR),) $(if $(WIRE),--wire,)

## gen-sql: generate PureScript types & codecs from SQL migrations (usage: make gen-sql [FILE=migrations/001.sql] [TABLE=comments] [OUT=path])
.PHONY: gen-sql
gen-sql:
	@$(SPAGO) build --quiet && bun --eval "import('./output/App.Cli.GenSql/index.js').then(m => m.main())" -- $${FILE:+"--file=$(FILE)"} $${TABLE:+"--table=$(TABLE)"} $${OUT:+"--out=$(OUT)"}

# ==================================================================================== #
# AGENT EVALS
# ==================================================================================== #

## evals: list available agent evals
.PHONY: evals
evals:
	@bun evals/run-eval.js

## eval: run an agent eval (usage: make eval EVAL=01-add-page --check)
.PHONY: eval
eval:
	@bun evals/run-eval.js $(EVAL) $(ARGS)

# ==================================================================================== #
# DOCKER
# ==================================================================================== #

## image: build Docker image
.PHONY: image
image: build
	docker build -t $(IMAGE_NAME) .

## up: start production stack via Docker Compose
.PHONY: up
up:
	docker compose up -d --build

## down: stop production stack
.PHONY: down
down:
	docker compose down

# ==================================================================================== #
# DEPLOY (homelab quadlet)
# ==================================================================================== #
#
# Auto-deploy on push: homelab poll timer runs rebuild-if-changed every 2 min.
# Manual deploy: make deploy (rebuild image + restart container + reload Caddy).
#
# Prerequisites (one-time):
#   1. ~/projects/homelab cloned alongside this repo
#   2. cd ~/projects/homelab && ./podman/scripts/install.sh

SERVICE := pohjola-framework

## deploy: check + rebuild image + restart container + reload Caddy + verify
.PHONY: deploy
deploy: check
	@echo "==> Rebuilding image via quadlet build unit..."
	systemctl --user restart $(SERVICE)-build.service
	@echo "==> Restarting container..."
	systemctl --user restart $(SERVICE).service
	@echo "==> Reloading Caddy..."
	systemctl --user restart caddy.service
	@echo "==> Verifying..."
	@sleep 3
	@curl -sf -o /dev/null -w "  healthz:  %{http_code}\n" http://127.0.0.1:3003/healthz \
		|| (echo "  healthz: FAILED" && exit 1)
	@curl -sf -o /dev/null -w "  public:  %{http_code}\n" https://pohjola.icaro.fr/healthz \
		|| (echo "  public:  FAILED (may need a few seconds for Caddy)" && exit 1)
	@echo ""
	@echo "Deployed. Status: systemctl --user status $(SERVICE).service"

# ==================================================================================== #
# CLEAN
# ==================================================================================== #

## clean: remove build artifacts
.PHONY: clean
clean:
	rm -rf $(DIST_DIR) $(SERVER_BUNDLE_DIR) output output-es .spago
