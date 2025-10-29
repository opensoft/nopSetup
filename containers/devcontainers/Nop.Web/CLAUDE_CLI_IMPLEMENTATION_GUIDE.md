# Claude CLI Implementation Guide for Dev Containers

This guide provides step-by-step instructions for implementing Claude CLI in any development container.

## Overview

Claude CLI is installed via npm as `@anthropic-ai/claude-code` and provides the `claude` command (not `claude-code`). This guide covers both system-level and user-level installation methods.

## Prerequisites

- Container with Node.js and npm installed
- Root access for system-level installation
- Understanding of Dockerfile modifications

## 1. Dockerfile Implementation

### Basic Installation (System-level)

Add the following to your Dockerfile after installing Node.js and npm:

```dockerfile
# Install Node.js and npm (if not already installed)
RUN apt-get update && \
    apt-get install -y nodejs npm && \
    rm -rf /var/lib/apt/lists/* && \
    # Install Claude CLI globally
    npm install -g @anthropic-ai/claude-code && \
    # Verify installation
    echo "✓ Claude CLI installed: $(claude --version 2>/dev/null || echo 'installed')"
```

### Enhanced Installation with Verification

For better debugging and verification:

```dockerfile
# Install development tools including Claude CLI
RUN apt-get update && \
    apt-get install -y \
        nodejs \
        npm \
        curl \
        git \
        # ... other tools ... \
    && rm -rf /var/lib/apt/lists/* && \
    # Install Claude CLI globally via npm
    npm install -g @anthropic-ai/claude-code && \
    # Verify all installations
    echo "✓ Development tools installed successfully:" && \
    echo "  - node: $(node --version)" && \
    echo "  - npm: $(npm --version)" && \
    echo "  - claude: $(claude --version 2>/dev/null || echo 'installed')" && \
    # Create symlink for system-wide access
    ln -sf $(npm root -g)/@anthropic-ai/claude-code/bin/claude /usr/local/bin/claude || true
```

### User-specific Installation (for non-root users)

If your container creates a non-root user, add Claude CLI installation for that user:

```dockerfile
# After creating your user (replace ${IDE_USER} with your username variable)
USER ${IDE_USER}
RUN npm install -g @anthropic-ai/claude-code && \
    echo "Claude CLI installed for user ${IDE_USER}: $(claude --version 2>/dev/null || echo 'installed')"

# Switch back to root if needed for other operations
USER root
```

## 2. Docker Compose Integration

If using docker-compose, ensure proper environment setup:

```yaml
version: '3.8'
services:
  your-service:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        - IDE_USER=${IDE_USER:-developer}
        - IDE_UID=${IDE_UID:-1000}
        - IDE_GID=${IDE_GID:-1000}
    environment:
      - NODE_ENV=development
    # ... other configuration
```

## 3. Shell Configuration

### Add Claude CLI to .bashrc or .zshrc

Create or update shell configuration files:

```bash
# Add to .bashrc or .zshrc
# Claude CLI detection and PATH setup
if command -v claude >/dev/null 2>&1; then
    echo "✓ Claude CLI is available: $(claude --version)"
else
    echo "⚠ Claude CLI not found - you may need to install it with: npm install -g @anthropic-ai/claude-code"
fi

# Ensure npm global binaries are in PATH
export PATH="$PATH:$(npm config get prefix)/bin"
```

### For containers with multiple npm installations

If your container uses nvm or multiple npm versions:

```bash
# Add to shell configuration
# Handle multiple npm installations
if [ -d "$HOME/.nvm" ]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# Ensure both system and user npm paths are available
export PATH="/usr/local/bin:$PATH:$(npm config get prefix)/bin"

# Claude CLI aliases for convenience
alias claude-version='claude --version'
alias claude-help='claude --help'
```

## 4. Verification Steps

### During Build (Dockerfile)

Add verification steps to your Dockerfile:

```dockerfile
# Verification step
RUN echo "=== Claude CLI Verification ===" && \
    which claude && \
    claude --version && \
    echo "✓ Claude CLI is working correctly"
```

### After Container Startup

Test Claude CLI functionality:

```bash
# Basic verification
claude --version

# Check installation path
which claude

# List global npm packages
npm list -g --depth=0 | grep claude

# Test basic functionality
claude --help
```

## 5. Common Issues and Troubleshooting

### Issue: "claude command not found"

**Solutions:**
1. Check if installed globally: `npm list -g @anthropic-ai/claude-code`
2. Verify PATH includes npm global bin: `echo $PATH | grep -o $(npm config get prefix)/bin`
3. Create manual symlink: `ln -sf $(npm root -g)/@anthropic-ai/claude-code/bin/claude /usr/local/bin/claude`
4. Reinstall: `npm install -g @anthropic-ai/claude-code`

### Issue: Different npm installations (nvm vs system)

**Solutions:**
1. Install in both environments:
   ```bash
   # System npm
   sudo npm install -g @anthropic-ai/claude-code

   # User npm (if using nvm)
   npm install -g @anthropic-ai/claude-code
   ```

2. Update PATH to include both:
   ```bash
   export PATH="/usr/local/bin:$PATH:$(npm config get prefix)/bin"
   ```

### Issue: Permission errors during installation

**Solutions:**
1. Use sudo for system installation: `sudo npm install -g @anthropic-ai/claude-code`
2. Fix npm permissions: `sudo chown -R $(whoami) $(npm config get prefix)/{lib/node_modules,bin,share}`
3. Use user-local installation: `npm config set prefix ~/.local && npm install -g @anthropic-ai/claude-code`

### Issue: Container built successfully but claude not available at runtime

**Causes:**
- Different user context at runtime vs build
- nvm overriding system npm
- PATH not properly configured

**Solutions:**
1. Install for both root and user during build
2. Add proper PATH configuration to shell files
3. Create system-wide symlinks

## 6. Complete Example: Multi-Stage Dockerfile

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:9.0-noble AS build

# Install system dependencies and Claude CLI
RUN apt-get update && \
    apt-get install -y \
        sudo \
        nodejs \
        npm \
        curl \
        git \
        zsh && \
    rm -rf /var/lib/apt/lists/* && \
    # Install Claude CLI globally
    npm install -g @anthropic-ai/claude-code && \
    # Create system-wide symlink
    ln -sf $(npm root -g)/@anthropic-ai/claude-code/bin/claude /usr/local/bin/claude && \
    # Verify installation
    claude --version

# Accept build arguments for user creation
ARG IDE_USER=developer
ARG IDE_UID=1000
ARG IDE_GID=1000

# Create user
RUN groupadd --gid ${IDE_GID} ${IDE_USER} && \
    useradd --uid ${IDE_UID} --gid ${IDE_GID} -m ${IDE_USER} && \
    echo "${IDE_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install Claude CLI for user
USER ${IDE_USER}
RUN npm install -g @anthropic-ai/claude-code
USER root

# Copy shell configuration
COPY .zshrc /home/${IDE_USER}/.zshrc
RUN chown ${IDE_USER}:${IDE_USER} /home/${IDE_USER}/.zshrc

# Set working directory and permissions
WORKDIR /workspace
RUN chown -R ${IDE_USER}:${IDE_USER} /workspace

# Final verification
RUN echo "=== Final Claude CLI Verification ===" && \
    claude --version && \
    sudo -u ${IDE_USER} claude --version && \
    echo "✓ Claude CLI available for both root and ${IDE_USER}"

USER ${IDE_USER}
```

## 7. Testing Your Implementation

Create a simple test script to verify Claude CLI:

```bash
#!/bin/bash
# test-claude.sh

echo "=== Claude CLI Test ==="
echo "1. Checking if claude command exists..."
if command -v claude >/dev/null 2>&1; then
    echo "✓ claude command found"
else
    echo "✗ claude command not found"
    exit 1
fi

echo "2. Checking Claude CLI version..."
CLAUDE_VERSION=$(claude --version 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "✓ Claude CLI version: $CLAUDE_VERSION"
else
    echo "✗ Failed to get Claude CLI version"
    exit 1
fi

echo "3. Checking npm installation..."
NPM_CLAUDE=$(npm list -g @anthropic-ai/claude-code 2>/dev/null | grep claude-code)
if [ $? -eq 0 ]; then
    echo "✓ Claude CLI found in npm global packages"
else
    echo "⚠ Claude CLI not found in npm global packages (may be installed differently)"
fi

echo "4. Checking PATH..."
CLAUDE_PATH=$(which claude)
echo "✓ Claude CLI location: $CLAUDE_PATH"

echo "5. Testing basic functionality..."
claude --help >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ Claude CLI help command works"
else
    echo "✗ Claude CLI help command failed"
    exit 1
fi

echo "=== All tests passed! Claude CLI is properly installed. ==="
```

## 8. Summary

**Key Points:**
- Install via npm: `npm install -g @anthropic-ai/claude-code`
- Command name is `claude` (not `claude-code`)
- Install for both system and user contexts in containers
- Verify installation with `claude --version`
- Handle PATH configuration for different npm setups
- Create symlinks for system-wide access when needed

**Best Practices:**
- Always verify installation in Dockerfile
- Add shell configuration for PATH
- Install for both root and non-root users
- Include troubleshooting steps in your documentation
- Test the installation after container startup

This guide should work for any development container setup. Adjust the specific package managers and user configurations based on your container's base image and requirements.
