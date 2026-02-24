# Claudeception

A customized fork of [blader/Claudeception](https://github.com/blader/Claudeception) — a continuous learning system that extracts reusable knowledge from work sessions and codifies it into Claude Code skills.

Every time you use an AI coding agent, it starts from zero. You spend an hour debugging some obscure error, the agent figures it out, session ends. Next time you hit the same issue? Another hour. This skill fixes that by persisting discoveries as reusable skills.

## Changes from Upstream

This fork customizes the original Claudeception with:

1. **Skill-authoring integration** — delegates skill creation to the [skill-authoring](https://github.com/abhattacherjee/skill-authoring) skill for consistent structure, frontmatter conventions, and quality checks
2. **Existing skills check (Step 1)** — before creating a new skill, searches project and user-level skill directories to decide: create new, update existing, or add cross-references
3. **Project artifact updates (Step 5)** — after saving a skill, updates CHANGELOG.md and uses appropriate commit prefixes (`docs(skills):` or `fix(skills):`)
4. **Streamlined frontmatter** — uses `metadata.version` instead of top-level `version`, removes `author`, `date`, `tags`, and `allowed-tools` fields per Anthropic best practices
5. **Concise research section** — replaced verbose search instructions with a one-liner strategy
6. **See Also cross-references** — links to `skill-authoring` and Anthropic's official docs

The original's core concepts (trigger conditions, quality gates, automatic/explicit modes, retrospective) are preserved unchanged.

## Installation

### Individual repo (recommended)

**User-level** (available in all projects):

```bash
# macOS / Linux
git clone https://github.com/abhattacherjee/claudeception.git ~/.claude/skills/claudeception

# Windows
git clone https://github.com/abhattacherjee/claudeception.git %USERPROFILE%\.claude\skills\claudeception
```

**Project-level** (available only in one project):

```bash
git clone https://github.com/abhattacherjee/claudeception.git .claude/skills/claudeception
```

### Via monorepo (all skills)

```bash
git clone https://github.com/abhattacherjee/claude-code-skills.git /tmp/claude-code-skills
cp -r /tmp/claude-code-skills/claudeception ~/.claude/skills/claudeception
rm -rf /tmp/claude-code-skills
```

### Set up the activation hook (recommended)

The skill activates via semantic matching, but a hook ensures it evaluates every session for extractable knowledge.

1. Copy the activator script:

```bash
mkdir -p ~/.claude/hooks
cp ~/.claude/skills/claudeception/scripts/claudeception-activator.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/claudeception-activator.sh
```

2. Add the hook to your Claude settings (`~/.claude/settings.json`):

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/claudeception-activator.sh"
          }
        ]
      }
    ]
  }
}
```

## Updating

```bash
git -C ~/.claude/skills/claudeception pull
```

## Uninstall

```bash
rm -rf ~/.claude/skills/claudeception
```

## Usage

### Automatic Mode

The skill activates automatically when Claude Code:
- Completed debugging with a non-obvious solution
- Found a workaround through investigation or trial-and-error
- Resolved an error where the root cause wasn't immediately apparent
- Learned project-specific patterns through investigation

### Explicit Mode

```
/claudeception
```

Or: `Save what we just learned as a skill`

### What Gets Extracted

Not every task produces a skill. It only extracts knowledge that required actual discovery (not just reading docs), will help with future tasks, has clear trigger conditions, and has been verified to work.

## Research

The idea comes from academic work on skill libraries for AI agents.

[Voyager](https://arxiv.org/abs/2305.16291) (Wang et al., 2023) showed that game-playing agents can build up libraries of reusable skills over time. [CASCADE](https://arxiv.org/abs/2512.23880) (2024) introduced "meta-skills" (skills for acquiring skills), which is what this is. [SEAgent](https://arxiv.org/abs/2508.04700) (2025) showed agents can learn new software environments through trial and error. [Reflexion](https://arxiv.org/abs/2303.11366) (Shinn et al., 2023) showed that self-reflection helps.

More on the skills architecture [here](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills).

## Compatibility

This skill follows the **Agent Skills** standard — a `SKILL.md` file at the repo root with YAML frontmatter. This format is recognized by:

- [Claude Code](https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview) (Anthropic)
- [Cursor](https://www.cursor.com/)
- [Codex CLI](https://github.com/openai/codex) (OpenAI)
- [Gemini CLI](https://github.com/google-gemini/gemini-cli) (Google)

## Examples

See `examples/` for sample skills:

- `nextjs-server-side-error-debugging/`: errors that don't show in browser console
- `prisma-connection-pool-exhaustion/`: the "too many connections" serverless problem
- `typescript-circular-dependency/`: detecting and fixing import cycles

## License

[MIT](LICENSE)

## Acknowledgments

Original concept and implementation by [blader](https://github.com/blader/Claudeception).
