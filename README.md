# Claude

## Claude Code on the web setup

This repository is configured with a Claude Code [`SessionStart` hook](https://code.claude.com/docs/en/claude-code-on-the-web)
so that Claude Code on the web can automatically install project dependencies
at the start of a session.

### How it works

- **`.claude/settings.json`** registers `.claude/hooks/session-start.sh` to
  run on the `SessionStart` event.
- **`.claude/hooks/session-start.sh`** only runs in remote (Claude Code on
  the web) sessions, checked via `$CLAUDE_CODE_REMOTE`. It looks for common
  dependency manifests in the repo root and runs the matching install
  command:

  | Manifest            | Command             |
  | -------------------- | -------------------- |
  | `package.json`        | `npm install`         |
  | `requirements.txt`    | `pip install -r requirements.txt` |
  | `pyproject.toml` (Poetry) | `poetry install`  |
  | `Cargo.toml`           | `cargo fetch`          |
  | `go.mod`               | `go mod download`     |
  | `Gemfile`              | `bundle install`      |

  Since the repo currently has no dependency manifests, the hook is a no-op
  today — it will automatically start installing dependencies as soon as any
  of the files above are added, with no changes needed to the hook itself.

- The hook runs in **async mode** (`{"async": true, "asyncTimeout": 300000}`),
  so a Claude Code on the web session starts immediately while dependency
  installation happens in the background (up to a 5-minute timeout). The
  trade-off is a small race-condition risk: Claude could try to run tests or
  linters before installs finish. If you'd rather have the session wait
  until installs are complete, switch the hook to synchronous mode by
  removing that line.

### Updating the hook

As the project grows, extend `.claude/hooks/session-start.sh` with any
additional setup steps needed (env vars via `$CLAUDE_ENV_FILE`, database
migrations, build steps, etc.). Keep it idempotent and non-interactive, since
it may run on every session start.
