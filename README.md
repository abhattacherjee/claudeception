# claudeception

Extracts reusable knowledge from work sessions and codifies it into Claude Code skills.

## Installation

### Individual repo (recommended)

Clone into your Claude Code skills directory:

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

## Updating

```bash
git -C ~/.claude/skills/claudeception pull
```

## Uninstall

```bash
rm -rf ~/.claude/skills/claudeception
```

## What It Does

Extracts reusable knowledge from work sessions and codifies it into Claude Code skills.

## Compatibility

This skill follows the **Agent Skills** standard — a `SKILL.md` file at the repo root with YAML frontmatter. This format is recognized by:

- [Claude Code](https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview) (Anthropic)
- [Cursor](https://www.cursor.com/)
- [Codex CLI](https://github.com/openai/codex) (OpenAI)
- [Gemini CLI](https://github.com/google-gemini/gemini-cli) (Google)

## Directory Structure

```
claudeception/
├── .github/
    ├── PULL_REQUEST_TEMPLATE.md
    ├── workflows/
        ├── validate-skill.yml
├── .gitignore
├── CHANGELOG.md
├── CONTRIBUTING.md
├── examples/
    ├── nextjs-server-side-error-debugging/
        ├── SKILL.md
    ├── prisma-connection-pool-exhaustion/
        ├── SKILL.md
    ├── typescript-circular-dependency/
        ├── SKILL.md
├── LICENSE
├── README.md
├── resources/
    ├── research-references.md
    ├── skill-template.md
├── scripts/
    ├── claudeception-activator.sh
    ├── validate-skill.sh
├── SKILL.md
├── WARP.md
```

## License

[MIT](LICENSE)
