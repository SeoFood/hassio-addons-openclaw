ARG BUILD_FROM
FROM node:22-slim

ARG BUILD_VERSION=2.0.1
ENV BUILD_VERSION=${BUILD_VERSION}

# Install system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    jq \
    bash \
    chromium \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create openclaw user
RUN useradd -m -s /bin/bash -u 1001 openclaw

# Install OpenClaw
RUN npm install -g openclaw@latest

# Patch current OpenClaw dist to preserve operator scopes when
# allowInsecureAuth is used by the Control UI over HTTP.
COPY scripts/patch-openclaw-control-ui-scopes.mjs /tmp/patch-openclaw-control-ui-scopes.mjs
RUN node /tmp/patch-openclaw-control-ui-scopes.mjs && rm -f /tmp/patch-openclaw-control-ui-scopes.mjs

# Create data directories
RUN mkdir -p /share/openclaw /opt/ha-skill \
    && chown -R openclaw:openclaw /share/openclaw

# Set Puppeteer to use system Chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Copy bundled Home Assistant skill
COPY ha-skill /opt/ha-skill

# Copy startup script
COPY run.sh /run.sh
RUN chmod +x /run.sh

WORKDIR /share/openclaw

EXPOSE 18789

CMD ["/run.sh"]
