# Claude CLI Implementation Checklist

Use this checklist when adding Claude CLI to any development container.

## Pre-Implementation Checklist

- [ ] ✅ Container has Node.js installed
- [ ] ✅ Container has npm installed
- [ ] ✅ You have the Dockerfile or can modify the container setup
- [ ] ✅ You understand the container's user structure (root vs non-root)

## Implementation Steps

### 1. Choose Installation Method
- [ ] **System-wide only** (root user containers)
- [ ] **User-specific only** (single user containers)
- [ ] **Both system and user** (multi-user containers) ✅ Recommended

### 2. Dockerfile Modifications

#### Basic Installation (choose one):
- [ ] Add basic npm install: `npm install -g @anthropic-ai/claude-code`
- [ ] Add enhanced install with symlink:
  ```dockerfile
  npm install -g @anthropic-ai/claude-code && \
  ln -sf $(npm root -g)/@anthropic-ai/claude-code/bin/claude /usr/local/bin/claude
  ```

#### Multi-User Installation:
- [ ] Add system installation in root context
- [ ] Add user installation after user creation:
  ```dockerfile
  USER ${YOUR_USER}
  RUN npm install -g @anthropic-ai/claude-code
  USER root
  ```

### 3. Shell Configuration
- [ ] Update .bashrc/.zshrc with PATH configuration
- [ ] Add Claude CLI detection message
- [ ] Add useful aliases (optional)

### 4. Verification Steps
- [ ] Add verification commands to Dockerfile:
  ```dockerfile
  RUN claude --version && echo "✅ Claude CLI working"
  ```
- [ ] Test in running container: `claude --version`
- [ ] Verify for all users (if multi-user setup)

## Post-Implementation Testing

### Basic Functionality Tests
- [ ] `claude --version` returns version number
- [ ] `claude --help` shows help information
- [ ] `which claude` shows correct path
- [ ] `npm list -g @anthropic-ai/claude-code` shows package

### Multi-User Testing (if applicable)
- [ ] Test as root user: `claude --version`
- [ ] Test as regular user: `sudo -u ${USER} claude --version`
- [ ] Verify PATH includes npm directories for all users

### Container Restart Testing
- [ ] Stop and restart container
- [ ] Verify Claude CLI still available after restart
- [ ] Check if shell configuration loads correctly

## Common Issues & Solutions

### ❌ "claude: command not found"
**Check:**
- [ ] NPM global installation: `npm list -g @anthropic-ai/claude-code`
- [ ] PATH includes npm bin: `echo $PATH | grep npm`
- [ ] Symlink exists: `ls -la /usr/local/bin/claude`

**Fix:**
- [ ] Reinstall: `npm install -g @anthropic-ai/claude-code`
- [ ] Add to PATH: `export PATH="$PATH:$(npm config get prefix)/bin"`
- [ ] Create symlink: `ln -sf $(npm root -g)/@anthropic-ai/claude-code/bin/claude /usr/local/bin/claude`

### ❌ "Permission denied" during installation
**Fix:**
- [ ] Use sudo: `sudo npm install -g @anthropic-ai/claude-code`
- [ ] Fix npm permissions: `sudo chown -R $(whoami) $(npm config get prefix)/{lib/node_modules,bin,share}`
- [ ] Use user-local installation: `npm config set prefix ~/.local`

### ❌ Works during build but not at runtime
**Check:**
- [ ] Different user context (build vs runtime)
- [ ] nvm overriding system npm
- [ ] Shell configuration not loading

**Fix:**
- [ ] Install for both contexts
- [ ] Add proper shell configuration
- [ ] Use absolute paths in verification

### ❌ Multiple npm installations conflict
**Fix:**
- [ ] Install in all npm contexts
- [ ] Update PATH to include all locations
- [ ] Use system-wide symlinks

## Quick Start Commands

### For existing containers (manual install):
```bash
# Quick user installation
npm install -g @anthropic-ai/claude-code

# Quick system installation
sudo npm install -g @anthropic-ai/claude-code
sudo ln -sf $(npm root -g)/@anthropic-ai/claude-code/bin/claude /usr/local/bin/claude

# Verify
claude --version
```

### For new Dockerfiles:
```dockerfile
# Add to your Dockerfile after nodejs/npm installation
RUN npm install -g @anthropic-ai/claude-code && \
    claude --version
```

## Success Criteria

✅ **Installation Complete When:**
- [ ] `claude --version` returns "1.0.9 (Claude Code)" or newer
- [ ] Command works for all intended users
- [ ] Command persists after container restart
- [ ] No error messages in container logs
- [ ] Installation method is documented for team

## Files Created/Modified

- [ ] `Dockerfile` - Updated with Claude CLI installation
- [ ] `.bashrc/.zshrc` - Updated with PATH and configuration
- [ ] `docker-compose.yml` - Updated if needed for environment
- [ ] Documentation - Updated with Claude CLI usage instructions

---

**Remember:** The correct command is `claude` (not `claude-code`), and it's installed via `npm install -g @anthropic-ai/claude-code`.
