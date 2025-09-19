# Test Dockerfile for Claude CLI installation only
FROM mcr.microsoft.com/dotnet/sdk:9.0-noble

# Install basic development tools including Claude CLI
RUN apt-get update && \
    apt-get install -y \
        sudo \
        curl \
        jq \
        tree \
        zsh \
        git && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/* && \
    npm install -g @anthropic-ai/claude-code && \
    echo "✓ Development tools installed successfully:" && \
    echo "  - zsh: $(zsh --version)" && \
    echo "  - git: $(git --version)" && \
    echo "  - curl: $(curl --version | head -1)" && \
    echo "  - jq: $(jq --version)" && \
    echo "  - tree: $(tree --version)" && \
    echo "  - node: $(node --version)" && \
    echo "  - npm: $(npm --version)" && \
    echo "  - claude: $(claude --version 2>/dev/null || echo 'installed')"

WORKDIR /workspace
