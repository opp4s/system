# syntax=docker/dockerfile:1
ARG CHATWOOT_VERSION=v4.14.0

# ── Stage 1: Clone & patch Chatwoot source ──────────────────────────────────
FROM node:20-slim AS builder

ARG CHATWOOT_VERSION
RUN apt-get update && apt-get install -y git python3 && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN git clone --depth 1 --branch ${CHATWOOT_VERSION} https://github.com/chatwoot/chatwoot .

# Copy plugin files
COPY chatwoot/ /plugin/

# Apply patch
RUN CHATWOOT_SRC=/build bash /plugin/patches/apply.sh

# Install dependencies and build frontend assets
RUN yarn install --frozen-lockfile
RUN yarn build

# ── Stage 2: Final image based on official Chatwoot ─────────────────────────
FROM chatwoot/chatwoot:${CHATWOOT_VERSION}

# Replace compiled assets with our patched version
COPY --from=builder /build/public/packs /app/public/packs
COPY --from=builder /build/public/dashboard/images/integrations/whatsapp_lite.png \
     /app/public/dashboard/images/integrations/whatsapp_lite.png
COPY --from=builder /build/public/dashboard/images/integrations/whatsapp_lite-dark.png \
     /app/public/dashboard/images/integrations/whatsapp_lite-dark.png

# Replace config files (no recompilation needed for YAML/Ruby)
COPY --from=builder /build/config/integration/apps.yml /app/config/integration/apps.yml
COPY --from=builder /build/config/locales/en.yml /app/config/locales/en.yml

LABEL org.opencontainers.image.title="Chatwoot + WhatsApp Lite"
LABEL org.opencontainers.image.source="https://github.com/opp4s/system"
