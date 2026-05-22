# syntax=docker/dockerfile:1
# Estratégia: usa a imagem oficial do Chatwoot como base (gems Ruby já compiladas),
# adiciona Node.js apenas para recompilar os assets frontend com os patches aplicados.
# Tempo de build: ~10-15 min (vs ~2h compilando tudo do zero).

ARG CHATWOOT_VERSION=v4.14.0

# ── Stage 1 (= imagem final): Chatwoot oficial + plugin ─────────────────────
FROM chatwoot/chatwoot:${CHATWOOT_VERSION}

ARG CHATWOOT_VERSION
ARG PNPM_VERSION="10.2.0"
ENV NODE_OPTIONS="--max-old-space-size=4096 --openssl-legacy-provider"
ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# Instalar Node.js e pnpm via Alpine (sem conflitos com binários existentes)
RUN apk add --no-cache nodejs npm python3 \
 && npm install -g pnpm@${PNPM_VERSION} --no-fund --no-audit

# Clonar source do Chatwoot na versão exata (para recompilar assets com patches)
RUN git clone --depth 1 --branch ${CHATWOOT_VERSION} \
      https://github.com/chatwoot/chatwoot /tmp/build

# Copiar plugin e aplicar patches
COPY chatwoot/ /plugin/
COPY assets/   /assets/
RUN CHATWOOT_SRC=/tmp/build sh /plugin/patches/apply.sh

WORKDIR /tmp/build

# Usar as gems já existentes na imagem (BUNDLE_PATH=/gems já configurado)
RUN bundle config set path '/gems' \
 && bundle config set without 'development test'

# Instalar dependências JS
RUN pnpm install --frozen-lockfile

# Compilar assets frontend (reutiliza gems Ruby da imagem oficial — sem bundle install)
RUN SECRET_KEY_BASE=precompile_placeholder \
    RAILS_LOG_TO_STDOUT=enabled \
    bundle exec rake assets:precompile

# Mover assets compilados para o diretório da app (Chatwoot v4 usa Vite → public/vite/)
RUN cp -r /tmp/build/public/vite /app/public/vite

# Copiar arquivos de config patchados
RUN cp /tmp/build/config/integration/apps.yml /app/config/integration/apps.yml \
 && cp /tmp/build/config/locales/en.yml /app/config/locales/en.yml \
 && cp /tmp/build/config/locales/pt_BR.yml /app/config/locales/pt_BR.yml

# Copiar logo
RUN mkdir -p /app/public/dashboard/images/integrations \
 && cp /assets/whatsapp_lite.png /app/public/dashboard/images/integrations/whatsapp_lite.png \
 && cp /assets/whatsapp_lite.png /app/public/dashboard/images/integrations/whatsapp_lite-dark.png

# Limpar deps de build
RUN rm -rf /tmp/build /plugin /assets \
 && npm uninstall -g pnpm 2>/dev/null || true \
 && apk del python3 curl xz 2>/dev/null || true

# Restaurar workdir original da imagem oficial
WORKDIR /app

LABEL org.opencontainers.image.title="Chatwoot + WhatsApp Lite" \
      org.opencontainers.image.source="https://github.com/opp4s/system" \
      org.opencontainers.image.version=${CHATWOOT_VERSION}
