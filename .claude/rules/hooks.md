# Hooks System — Guardrail Configuration

> **Platform Support**: Hooks scripts work on **Claude Code**, **Antigravity**, and via **git hooks** for Cursor.

## Hook Types

| Type            | Timing                | Purpose                                                             |
| --------------- | --------------------- | ------------------------------------------------------------------- |
| **PreToolUse**  | Before tool execution | Block dangerous commands, inject context, validate layer boundaries |
| **PostToolUse** | After tool execution  | Auto-format, lint, type-check, security scan, console.log warning   |
| **Stop**        | When session ends     | Audit summary, changelog reminder, learning extraction              |

## Available Hook Scripts

All hooks are in `.claude/hooks/` (mirrored in `.claude/hooks/`):

### PreToolUse Hooks

| Script                           | Matcher       | Action                                                       |
| -------------------------------- | ------------- | ------------------------------------------------------------ |
| `pre-dangerous-command-guard.sh` | `Bash`        | **BLOCKS** `rm -rf`, `git push --force`, `npm publish`, etc. |
| `pre-context-loader.sh`          | `Write\|Edit` | Reminds required reading based on DDD layer being edited     |
| `pre-layer-boundary-check.sh`    | `Write\|Edit` | Detects forbidden cross-layer imports (Domain→Infra, etc.)   |

### PostToolUse Hooks

| Script                     | Matcher       | Action                                                           |
| -------------------------- | ------------- | ---------------------------------------------------------------- |
| `post-prettier-format.sh`  | `Edit\|Write` | Auto-format with Prettier (.ts, .js, .json, .css, .md)           |
| `post-eslint-check.sh`     | `Edit\|Write` | Report ESLint issues (non-blocking)                              |
| `post-typescript-check.sh` | `Edit\|Write` | Report TypeScript type errors (non-blocking)                     |
| `post-security-scan.sh`    | `Edit\|Write` | Scan for hardcoded secrets, XSS, eval() — **BLOCKS on critical** |
| `post-console-log-warn.sh` | `Edit\|Write` | Warn about `console.log` in production code                      |

### Stop Hooks

| Script                       | Matcher | Action                                                          |
| ---------------------------- | ------- | --------------------------------------------------------------- |
| `stop-audit-summary.sh`      | `*`     | Summary of all file changes, layer analysis, test coverage gaps |
| `stop-changelog-reminder.sh` | `*`     | Remind to update CHANGELOG if code changed                      |

### Git Hooks

| Script              | Purpose                                                                    |
| ------------------- | -------------------------------------------------------------------------- |
| `git-pre-commit.sh` | Install as `.git/hooks/pre-commit` — format + lint + security + type check + mirror audit |

## Configuration (Claude Code)

Copy hooks configuration into `~/.claude/settings.json`:

```json
{
    "hooks": {
        "PreToolUse": [
            {
                "matcher": "Bash",
                "hooks": [
                    { "type": "command", "command": ".claude/hooks/pre-dangerous-command-guard.sh" }
                ]
            },
            {
                "matcher": "Write|Edit",
                "hooks": [{ "type": "command", "command": ".claude/hooks/pre-context-loader.sh" }]
            }
        ],
        "PostToolUse": [
            {
                "matcher": "Edit|Write",
                "hooks": [{ "type": "command", "command": ".claude/hooks/post-prettier-format.sh" }]
            },
            {
                "matcher": "Edit|Write",
                "hooks": [{ "type": "command", "command": ".claude/hooks/post-eslint-check.sh" }]
            },
            {
                "matcher": "Edit|Write",
                "hooks": [{ "type": "command", "command": ".claude/hooks/post-security-scan.sh" }]
            },
            {
                "matcher": "Edit|Write",
                "hooks": [
                    { "type": "command", "command": ".claude/hooks/post-console-log-warn.sh" }
                ]
            }
        ],
        "Stop": [
            {
                "matcher": "*",
                "hooks": [{ "type": "command", "command": ".claude/hooks/stop-audit-summary.sh" }]
            },
            {
                "matcher": "*",
                "hooks": [
                    { "type": "command", "command": ".claude/hooks/stop-changelog-reminder.sh" }
                ]
            }
        ]
    }
}
```

See `.claude/hooks/settings-hooks.json` for the full config with schema.

## Cursor / Antigravity Alternative

Since Cursor doesn't support Claude hooks, use:

1. **Git hooks**: Copy `.claude/hooks/git-pre-commit.sh` → `.git/hooks/pre-commit`
2. **Manual checks**: Run `pnpm format && pnpm lint && pnpm test` before committing
3. **Use prompts**: `@.claude/prompts/code-review.md` for manual review

When staged changes touch the mirror trees, `tools/agents-claude-mirror*`, or `package.json`, the pre-commit hook also runs `pnpm run agents:claude:audit` and blocks the commit if the shared mirror is out of sync.

## Exit Codes

| Code | Meaning                                                             |
| ---- | ------------------------------------------------------------------- |
| `0`  | Passed — continue normally                                          |
| `1`  | Failed — **BLOCK** action (PreToolUse) or **WARNING** (PostToolUse) |
| `2`  | Skipped — hook not applicable for this file/command                 |

## Auto-Accept Permissions (Claude Code)

Use with caution:

- Enable for trusted, well-defined plans
- Disable for exploratory work
- Never use `dangerously-skip-permissions` flag
- Configure `allowedTools` in settings instead

## TodoWrite Best Practices

Use TodoWrite tool to:

- Track progress on multi-step tasks
- Verify understanding of instructions
- Enable real-time steering
- Show granular implementation steps
