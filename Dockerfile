# =============================================================================
# Pohjola — SSR server (PureScript + Bun.serve + Bun)
# MPA architecture: Html ADT renders to String, Alpine.js for interactivity
# =============================================================================

# ---------------------------------------------------------------------------
# Build stage — Bun + PureScript toolchain
# ---------------------------------------------------------------------------
FROM oven/bun:canary-debian AS build

RUN apt-get update && \
    apt-get install -y --no-install-recommends git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# PureScript compiler — npm registry (pinned), same as CI setup-toolchain action.
# Avoid curling GitHub release tarballs during docker build (504-prone, uncached).
ARG PURESCRIPT_VERSION=0.15.16
RUN bun install --global purescript@${PURESCRIPT_VERSION}

WORKDIR /app/pohjola-framework

# Install dependencies (Spago, Tailwind, esbuild) with Bun (applies patches automatically)
COPY package.json bun.lock ./
COPY patches ./patches
RUN bun install --frozen-lockfile

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

# Bun runtime (canary — required for Bun.serve routes; 1.3.x crashes)
COPY --from=oven/bun:canary-debian /usr/local/bin/bun /usr/local/bin/bun

# Bundled app: private server.js + public static assets under dist/
# (FFI routes use relative paths ./dist/assets, ./dist/css, etc.)
COPY --from=build /app/pohjola-framework/dist-server/server.js /app/server.js
COPY --from=build /app/pohjola-framework/dist /app/dist

USER 1000:1000
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s CMD ["/usr/local/bin/bun","-e","fetch('http://127.0.0.1:'+(process.env.PORT||3000)+'/healthz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"]

ENTRYPOINT ["/usr/local/bin/bun","/app/server.js"]
