#!/bin/bash
set -euo pipefail

# Only run dependency installs in Claude Code on the web (remote) sessions.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

echo '{"async": true, "asyncTimeout": 300000}'

cd "$CLAUDE_PROJECT_DIR"

# Node.js
if [ -f package.json ]; then
  echo "Installing npm dependencies..."
  npm install
fi

# Python (pip / requirements.txt)
if [ -f requirements.txt ]; then
  echo "Installing pip dependencies..."
  pip install -r requirements.txt
fi

# Python (Poetry)
if [ -f pyproject.toml ] && command -v poetry >/dev/null 2>&1; then
  echo "Installing poetry dependencies..."
  poetry install
fi

# Rust
if [ -f Cargo.toml ]; then
  echo "Fetching cargo dependencies..."
  cargo fetch
fi

# Go
if [ -f go.mod ]; then
  echo "Downloading go modules..."
  go mod download
fi

# Ruby
if [ -f Gemfile ]; then
  echo "Installing bundler dependencies..."
  bundle install
fi

# claude-mem: local-only cross-session memory plugin for Claude Code.
# Since this container is ephemeral, re-run the (idempotent) installer each
# session so hooks/worker are set up. Cloud sync is off; memory lives in
# ~/.claude-mem on the container and does NOT persist between sessions
# unless you sign in interactively to enable cloud sync (see README.md).
if command -v npx >/dev/null 2>&1; then
  echo "Ensuring claude-mem is installed..."
  CLAUDE_MEM_ONLINE_OPTIN=false npx --yes claude-mem@latest install --provider claude --ide claude-code || true
fi

exit 0
