---
name: continuous-learning
description: Claude Code only skill - moved to .claude/skills/continuous-learning/
platform: claude-code-only
---

# Continuous Learning Skill

> **MOVED**: This skill has been moved to `.claude/skills/continuous-learning/`
> 
> This skill requires Claude Code's hook system and is **not available in Cursor**.

## Why Moved?

This skill requires:
- **Stop hook**: Runs when session ends (Claude Code only)
- **Session transcript access**: `CLAUDE_TRANSCRIPT_PATH` environment variable
- **Background script execution**: Shell scripts run automatically

None of these features are available in Cursor IDE.

## For Claude Code Users

See `.claude/skills/continuous-learning/SKILL.md` for:
- Full documentation
- Configuration options
- Hook setup instructions

## For Cursor Users

Since Cursor doesn't support hooks, you can:

1. **Manual pattern extraction**: Document learned patterns yourself
2. **Use existing skills**: Reference `.claude/skills/` for guides
3. **Create custom prompts**: Add to `.claude/prompts/` for common tasks

## Quick Reference

| Feature | Cursor | Claude Code |
|---------|--------|-------------|
| Continuous Learning | Manual | Automatic (Stop hook) |
| Session Evaluation | N/A | Automatic |
| Pattern Extraction | Manual notes | Auto-extracted |
| Learned Skills | Manual creation | Auto-saved |
