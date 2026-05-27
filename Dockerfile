# syntax=docker/dockerfile:1
# Funnels Plugin — constrói sobre chatwoot-whatsapp-lite (que já tem WA Lite + assets compilados)
# Recompila apenas o frontend com o plugin de funis injetado.

ARG BASE_IMAGE=chatwoot-whatsapp-lite:latest
ARG PNPM_VERSION="10.2.0"

FROM ${BASE_IMAGE}

ARG PNPM_VERSION
ENV NODE_OPTIONS="--max-old-space-size=4096 --openssl-legacy-provider"
ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# Node.js + pnpm para recompilar assets
RUN apk add --no-cache nodejs npm \
 && npm install -g pnpm@${PNPM_VERSION} --no-fund --no-audit

# Copiar plugin
COPY chatwoot/ /funnels-plugin/

# Instalar vue-draggable-next (dep do Kanban)
WORKDIR /app
RUN pnpm install --frozen-lockfile || pnpm install
RUN pnpm add vue-draggable-next vue-virtual-scroller --save 2>/dev/null || true

# Aplicar patches (frontend)
RUN CHATWOOT_SRC=/app sh /funnels-plugin/patches/apply.sh

# Recompilar assets
RUN SECRET_KEY_BASE=precompile_placeholder \
    RAILS_LOG_TO_STDOUT=enabled \
    bundle exec rake assets:precompile

# Copiar backend Ruby
RUN mkdir -p \
      /app/lib/funnels \
      /app/app/controllers/funnels/api \
      /app/app/channels/funnels \
      /app/app/models/funnels \
      /app/app/jobs/funnels \
      /app/app/policies/funnels \
      /app/db/migrate_funnels \
 && cp -r /funnels-plugin/lib/funnels/.              /app/lib/funnels/ \
 && cp -r /funnels-plugin/app/controllers/funnels    /app/app/controllers/ \
 && cp -r /funnels-plugin/app/channels/funnels       /app/app/channels/ \
 && cp -r /funnels-plugin/app/models/funnels         /app/app/models/ \
 && cp -r /funnels-plugin/app/jobs/funnels            /app/app/jobs/ \
 && cp    /funnels-plugin/db/migrate/*.rb             /app/db/migrate_funnels/ \
 && cp    /funnels-plugin/config/initializers/funnels.rb /app/config/initializers/

# Locales
RUN cp /funnels-plugin/config/locales/funnels.*.yml /app/config/locales/ 2>/dev/null || true

# Limpeza
RUN rm -rf /funnels-plugin \
 && npm uninstall -g pnpm 2>/dev/null || true \
 && apk del nodejs npm 2>/dev/null || true

WORKDIR /app

LABEL org.opencontainers.image.title="Chatwoot + WA Lite + Funnels" \
      org.opencontainers.image.source="https://github.com/opp4s/system"
