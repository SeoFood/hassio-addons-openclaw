ARG BUILD_FROM
FROM node:22-slim

ARG BUILD_VERSION=1.0.0
ENV BUILD_VERSION=${BUILD_VERSION}

# Install system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    sudo \
    jq \
    bash \
    chromium \
    ca-certificates \
    cmake \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Create openclaw user
RUN useradd -m -s /bin/bash -u 1001 openclaw \
    && echo "openclaw ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install openclaw and Claude CLI globally
RUN npm install -g openclaw@latest @anthropic-ai/claude-code

# Remove build tools to reduce image size
RUN apt-get purge -y cmake make g++ && apt-get autoremove -y

# Create data directories
RUN mkdir -p /share/openclaw \
    && chown -R openclaw:openclaw /share/openclaw

# Set Puppeteer to use system Chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Copy startup script
COPY run.sh /run.sh
RUN chmod +x /run.sh

WORKDIR /share/openclaw

EXPOSE 18789

CMD ["/run.sh"]
