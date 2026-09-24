@AGENTS.md

## Claude Code

- For any behavior, extension or event sheet task, use the `gdevents`
  skill (`.claude/skills/gdevents/SKILL.md`): it walks through writing,
  translating and checking the file.
- In cloud sessions `.claude/hooks/session-start.sh` installs Godot 4.7.1
  as `godot` and imports the project, so the check and the tests run
  right away.
