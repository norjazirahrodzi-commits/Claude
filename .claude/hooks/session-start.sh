#!/bin/bash
set -euo pipefail

# Only run dependency installs in Claude Code on the web (remote) sessions.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

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

exit 0
