# =============================================================================
# Pohjola — SSR server (PureScript + Bun.serve + Bun)
# MPA architecture: Html ADT renders to String, Alpine.js for interactivity
# =============================================================================

# ---------------------------------------------------------------------------
# Build stage — Bun + PureScript toolchain
# ---------------------------------------------------------------------------
FROM oven/bun:debian AS build

ARG PURS_VERSION=0.15.16

RUN apt-get update && \
    apt-get install -y --no-install-recommends git ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app/pohjola-framework

COPY package.json bun.lock ./
COPY patches ./patches

# Install JS deps without lifecycle scripts, then hydrate native binaries
# explicitly. purescript's postinstall downloads from GitHub and falls back
# to stack when that fails — stack is not in this image and must not be.
RUN bun install --frozen-lockfile --ignore-scripts

# Official PureScript release binary (matches package.json devDependency).
# TARGETARCH is set automatically by BuildKit (amd64 → linux64, arm64 → linux-arm64).
ARG TARGETARCH
RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) PURS_ARCH=linux64 ;; \
      arm64) PURS_ARCH=linux-arm64 ;; \
      *) echo "unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/purescript/purescript/releases/download/v${PURS_VERSION}/${PURS_ARCH}.tar.gz" \
      | tar -xzf - -C /tmp; \
    install -m 0755 "/tmp/purescript/purs" "node_modules/purescript/purs.bin"; \
    node_modules/purescript/purs.bin --version

RUN node node_modules/esbuild/install.js

ENV PATH="/app/pohjola-framework/node_modules/.bin:${PATH}"

# Copy project source
COPY . .

# Build Tailwind CSS and embed into PureScript
RUN bun x @tailwindcss/cli -i css/input.css -o dist/css/styles.css --minify
RUN bun scripts/embed-css.js

# Bundle server to a PRIVATE dir — dist/ is the public static root and a
# bundle inside it would be downloadable at /server.js.
# --pure: use the committed spago.lock without network (avoids flaky registry)
RUN bun x spago install --pure
RUN bun x spago build --pure
RUN bun x spago bundle --module App.Main --outfile dist-server/server.js \
    --bundle-type app --platform node --pure

# Copy static assets into dist
RUN cp -r static/* dist/ 2>/dev/null || true

# ---------------------------------------------------------------------------
# Runner stage — distroless, minimal attack surface
# ---------------------------------------------------------------------------
FROM gcr.io/distroless/cc-debian13@sha256:ed7c407fd64eb0af9dddb9456b94cee188a40a7f53cf38c9836e1e9ae14fca02 AS runner

ARG BASE_URL="https://example.com"
ENV BASE_URL=$BASE_URL
ENV STATIC_ROOT=/app/dist

WORKDIR /app

# Bun runtime (latest stable — Bun.serve routes; see ADR-007)
COPY --from=oven/bun:debian /usr/local/bin/bun /usr/local/bin/bun

# Bundled app: private server.js + public static assets under dist/
# (FFI routes use relative paths ./dist/assets, ./dist/css, etc.)
COPY --from=build /app/pohjola-framework/dist-server/server.js /app/server.js
COPY --from=build /app/pohjola-framework/dist /app/dist

USER 1000:1000
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s CMD ["/usr/local/bin/bun","-e","fetch('http://127.0.0.1:'+(process.env.PORT||3000)+'/healthz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"]

ENTRYPOINT ["/usr/local/bin/bun","/app/server.js"]
