# syntax=docker/dockerfile:1
# Builds Chatwoot with the WhatsApp Lite plugin applied.
# Mirrors the official chatwoot/chatwoot build process exactly,
# then overlays patched assets on top of the official final image.

ARG CHATWOOT_VERSION=v4.14.0

# ── Stage 0: Node binary ────────────────────────────────────────────────────
FROM node:24-alpine AS node

# ── Stage 1: Build Chatwoot + WhatsApp Lite plugin ──────────────────────────
FROM ruby:3.4.4-alpine3.21 AS builder

ARG CHATWOOT_VERSION
ARG NODE_VERSION="24.13.0"
ARG PNPM_VERSION="10.2.0"
ARG BUNDLE_WITHOUT="development:test"
ARG RAILS_ENV=production
ARG NODE_OPTIONS="--max-old-space-size=4096 --openssl-legacy-provider"

ENV BUNDLE_WITHOUT=${BUNDLE_WITHOUT}
ENV BUNDLER_VERSION=2.5.16
ENV BUNDLE_PATH="/gems"
ENV BUNDLE_FORCE_RUBY_PLATFORM=1
ENV RAILS_ENV=${RAILS_ENV}
ENV RAILS_SERVE_STATIC_FILES=true
ENV NODE_OPTIONS=${NODE_OPTIONS}
ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN apk update && apk add --no-cache \
      openssl tar build-base tzdata postgresql-dev postgresql-client \
      git curl xz musl ruby-full ruby-dev gcc make musl-dev \
      openssl-dev g++ linux-headers vips \
    && gem install bundler -v "$BUNDLER_VERSION"

# Reuse the exact same Node binary Chatwoot uses
COPY --from=node /usr/local/bin/node /usr/local/bin/
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
 && ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
 && npm install -g pnpm@${PNPM_VERSION}

# Clone Chatwoot source at the pinned version
RUN git clone --depth 1 --branch ${CHATWOOT_VERSION} \
      https://github.com/chatwoot/chatwoot /build

WORKDIR /build

# Copy plugin overlay
COPY chatwoot/ /plugin/
COPY assets/   /assets/

# Apply patches before installing deps (routes.js, apps.yml, en.yml, Vue files)
RUN sh /plugin/patches/apply.sh

# Install Ruby gems (same flags as official Dockerfile)
RUN bundle config set force_ruby_platform true \
 && bundle config set without 'development test' \
 && bundle install -j 4 -r 3

# Install JS deps
RUN pnpm install --frozen-lockfile

# Compile frontend + Rails assets (identical to official build command)
RUN SECRET_KEY_BASE=precompile_placeholder \
    RAILS_LOG_TO_STDOUT=enabled \
    bundle exec rake assets:precompile

# ── Stage 2: Final image — overlay compiled assets on official image ─────────
FROM chatwoot/chatwoot:${CHATWOOT_VERSION}

# Swap compiled packs (includes manifest so Rails finds all new pack files)
COPY --from=builder /build/public/packs   /app/public/packs
COPY --from=builder /build/public/assets  /app/public/assets

# Logo
COPY --from=builder \
     /build/public/dashboard/images/integrations/whatsapp_lite.png \
     /app/public/dashboard/images/integrations/whatsapp_lite.png
COPY --from=builder \
     /build/public/dashboard/images/integrations/whatsapp_lite-dark.png \
     /app/public/dashboard/images/integrations/whatsapp_lite-dark.png

# Patched config files (no recompilation needed for YAML)
COPY --from=builder /build/config/integration/apps.yml /app/config/integration/apps.yml
COPY --from=builder /build/config/locales/en.yml       /app/config/locales/en.yml

LABEL org.opencontainers.image.title="Chatwoot + WhatsApp Lite" \
      org.opencontainers.image.source="https://github.com/opp4s/system" \
      org.opencontainers.image.version=${CHATWOOT_VERSION}
