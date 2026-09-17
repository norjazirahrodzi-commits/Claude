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

  Since the repo currently has no dependency manifests, none of these steps
  run today — they'll kick in automatically as soon as the matching file is
  added, with no changes needed to the hook itself.

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

## claude-mem (cross-session memory)

[`claude-mem`](https://github.com/thedotmack/claude-mem) is installed via the
session-start hook (`npx claude-mem@latest install --provider claude --ide
claude-code`), running non-interactively with cloud sign-in disabled
(`CLAUDE_MEM_ONLINE_OPTIN=false`). This registers claude-mem's lifecycle
hooks and MCP search tools using your own logged-in Claude account — no
separate account or API key required.

**Important limitation for Claude Code on the web:** each web session runs in
a fresh, ephemeral container. claude-mem's local database lives in
`~/.claude-mem` on the container's filesystem, which is destroyed when the
session ends — so, as installed, memory does **not** carry over between
sessions; it only builds up locally within a single running session/container.

To get real cross-session memory on the web, sign in interactively to enable
claude-mem's hosted cloud sync:

```bash
npx claude-mem@latest install
```

Follow the browser email-link sign-in flow it prompts for. This provisions a
memory key tied to your account so memory persists across containers. See the
[claude-mem docs](https://docs.claude-mem.ai/) for details on the hosted
service and its trial/plan terms.

## task-master-ai (MCP task management)

[`task-master-ai`](https://github.com/eyaltoledano/claude-task-master) is
configured as a project MCP server in [`.mcp.json`](.mcp.json), run on demand
via `npx -y task-master-ai`.

It requires an LLM API key to function. Set `ANTHROPIC_API_KEY` (or add other
provider keys — see `.mcp.json`) as an environment variable in your Claude
Code on the web environment settings; the MCP config reads it via
`${ANTHROPIC_API_KEY}` and never stores the key in the repo. No key is
configured here — the server won't have tools available until one is set.
