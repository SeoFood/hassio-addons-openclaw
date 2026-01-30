ARG BUILD_FROM
FROM node:22-alpine

# Cache breaker - change this to force rebuild
ARG BUILD_VERSION=1.0.0
ENV BUILD_VERSION=${BUILD_VERSION}

# Install system packages (Node.js already in base image for local dev)
# For Home Assistant builds, install Node.js 22 from official binaries
RUN apk add --no-cache \
    git \
    curl \
    sudo \
    jq \
    bash \
    shadow \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ca-certificates \
    ttf-freefont \
    && if ! command -v node >/dev/null 2>&1 || [ "$(node -v | cut -d. -f1 | tr -d v)" -lt 22 ]; then \
        echo "Installing Node.js 22..." && \
        curl -fsSL https://unofficial-builds.nodejs.org/download/release/v22.12.0/node-v22.12.0-linux-x64-musl.tar.gz | tar -xz -C /usr/local --strip-components=1; \
    fi

# Create openclaw user
RUN adduser -D -s /bin/bash -u 1001 openclaw \
    && echo "openclaw ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install clawdbot and Claude CLI globally
RUN npm install -g clawdbot@latest @anthropic-ai/claude-code

# Create data directories
RUN mkdir -p /share/openclaw \
    && chown -R openclaw:openclaw /share/openclaw

# Set Puppeteer to use system Chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

# Copy startup script
COPY run.sh /run.sh
RUN chmod +x /run.sh

WORKDIR /share/openclaw

EXPOSE 18789

CMD ["/run.sh"]
