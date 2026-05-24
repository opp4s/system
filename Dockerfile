# syntax=docker/dockerfile:1
# Estratégia: usa a imagem oficial do Chatwoot como base (gems Ruby já compiladas),
# adiciona Node.js apenas para recompilar os assets frontend com os patches aplicados.
# Tempo de build: ~10-15 min.

ARG CHATWOOT_VERSION=v4.14.0

# ── Stage 1 (= imagem final): Chatwoot oficial + plugin ─────────────────────
FROM chatwoot/chatwoot:${CHATWOOT_VERSION}

ARG CHATWOOT_VERSION
ARG PNPM_VERSION="10.2.0"
ENV NODE_OPTIONS="--max-old-space-size=4096 --openssl-legacy-provider"
ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# Instalar Node.js e pnpm via Alpine
RUN apk add --no-cache nodejs npm \
 && npm install -g pnpm@${PNPM_VERSION} --no-fund --no-audit

# Copiar plugin e assets
COPY chatwoot/ /plugin/
COPY assets/   /assets/

# Aplicar patches no source do Chatwoot (Vue components + integrations.routes.js)
RUN CHATWOOT_SRC=/app sh /plugin/patches/apply.sh

WORKDIR /app

# Instalar dependências JS (pnpm já instalado, node_modules pode já existir na imagem)
RUN pnpm install --frozen-lockfile || pnpm install

# Compilar assets frontend
RUN SECRET_KEY_BASE=precompile_placeholder \
    RAILS_LOG_TO_STDOUT=enabled \
    bundle exec rake assets:precompile

# Backend Ruby do plugin (copiado após o build para não afetar compilação)
RUN mkdir -p \
      /app/lib/whatsapp_lite/listeners \
      /app/app/controllers/whatsapp_lite/api \
      /app/app/jobs/whatsapp_lite \
      /app/db/migrate_plugin \
 && cp -r /plugin/lib/whatsapp_lite/. /app/lib/whatsapp_lite/ \
 && cp    /plugin/app/models/whatsapp_lite_channel.rb /app/app/models/ \
 && cp -r /plugin/app/controllers/whatsapp_lite       /app/app/controllers/ \
 && cp -r /plugin/app/jobs/whatsapp_lite              /app/app/jobs/ \
 && cp    /plugin/db/migrate/*.rb                     /app/db/migrate_plugin/ \
 && cp    /plugin/config/initializers/whatsapp_lite.rb /app/config/initializers/

# Locales do plugin
RUN mkdir -p /app/config/locales \
 && cp /plugin/config/locales/whatsapp_lite.*.yml /app/config/locales/ 2>/dev/null || true

# Logo
RUN mkdir -p /app/public/dashboard/images/integrations \
 && cp /assets/whatsapp_lite.png /app/public/dashboard/images/integrations/whatsapp_lite.png \
 && cp /assets/whatsapp_lite.png /app/public/dashboard/images/integrations/whatsapp_lite-dark.png \
 2>/dev/null || true

# Limpar deps de build
RUN rm -rf /plugin /assets \
 && npm uninstall -g pnpm 2>/dev/null || true \
 && apk del nodejs npm 2>/dev/null || true

WORKDIR /app

LABEL org.opencontainers.image.title="Chatwoot + WhatsApp Lite" \
      org.opencontainers.image.source="https://github.com/opp4s/system" \
      org.opencontainers.image.version=${CHATWOOT_VERSION}
