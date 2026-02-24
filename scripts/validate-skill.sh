#!/usr/bin/env bash
# validate-skill.sh — Validate a Claude Code skill directory against quality rules
# Exit codes: 0 = pass, 1 = fail, 2 = usage error
set -eu

# --- Usage ---
usage() {
  cat <<'EOF'
Usage: validate-skill.sh [options] <skill-directory>

Validates a Claude Code skill directory against quality rules:
  - SKILL.md exists with valid YAML frontmatter
  - name: lowercase + hyphens, ≤64 characters
  - description: ≤1024 characters, third person, "Use when:" present
  - metadata.version: present and valid semver
  - No non-standard frontmatter fields (author, date, tags are disallowed)
  - Body: ≤500 lines
  - Scripts: executable, #!/usr/bin/env bash shebang, --help support

Options:
  -h, --help    Show this help

Examples:
  validate-skill.sh ~/.claude/skills/my-skill    # Individual skill
  validate-skill.sh .                            # Current directory as skill
  validate-skill.sh changelog-keeper/            # Monorepo subdirectory

Exit codes:
  0  All checks passed
  1  One or more checks failed
  2  Usage error (missing argument, directory not found)
EOF
  exit 0
}

# --- Parse arguments ---
SKILL_DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage ;;
    -*)        echo "Error: Unknown option: $1" >&2; exit 2 ;;
    *)         SKILL_DIR="$1"; shift ;;
  esac
done

if [[ -z "$SKILL_DIR" ]]; then
  echo "Error: skill directory is required" >&2
  echo "Usage: validate-skill.sh [options] <skill-directory>" >&2
  exit 2
fi

# Resolve to absolute path
if [[ -d "$SKILL_DIR" ]]; then
  SKILL_DIR="$(cd "$SKILL_DIR" && pwd)"
else
  echo "Error: directory not found: $SKILL_DIR" >&2
  exit 2
fi

SKILL_MD="$SKILL_DIR/SKILL.md"
ERRORS=0
WARNINGS=0

pass() { echo "  PASS  $1"; }
fail() { echo "  FAIL  $1"; ERRORS=$((ERRORS + 1)); }
warn() { echo "  WARN  $1"; WARNINGS=$((WARNINGS + 1)); }

echo "Validating: $SKILL_DIR"
echo ""

# ============================================================
# 1. SKILL.md exists
# ============================================================
echo "--- SKILL.md ---"

if [[ ! -f "$SKILL_MD" ]]; then
  fail "SKILL.md not found"
  echo ""
  echo "Result: FAIL ($ERRORS error(s), $WARNINGS warning(s))"
  exit 1
fi
pass "SKILL.md exists"

# ============================================================
# 2. Frontmatter extraction helpers
# ============================================================
# Extract ONLY the first frontmatter block (between first pair of --- delimiters)
# This avoids matching example frontmatter in the body of skills like skill-authoring
get_frontmatter() {
  awk '/^---$/{n++; if(n==2) exit; next} n==1{print}' "$SKILL_MD"
}

extract_field() {
  local field="$1"
  get_frontmatter | grep "^${field}:" | head -1 | sed "s/^${field}:[[:space:]]*//; s/^[\"']//; s/[\"']$//"
}

extract_version() {
  get_frontmatter | grep "version:" | head -1 | sed 's/.*version:[[:space:]]*//; s/^[\"'"'"']//; s/[\"'"'"']$//'
}

# Check frontmatter delimiters exist
FRONTMATTER_START=$(grep -n '^---$' "$SKILL_MD" | head -1 | cut -d: -f1)
FRONTMATTER_END=$(grep -n '^---$' "$SKILL_MD" | sed -n '2p' | cut -d: -f1)

if [[ -z "$FRONTMATTER_START" ]] || [[ -z "$FRONTMATTER_END" ]]; then
  fail "YAML frontmatter not found (missing --- delimiters)"
  echo ""
  echo "Result: FAIL ($ERRORS error(s), $WARNINGS warning(s))"
  exit 1
fi
pass "YAML frontmatter delimiters present"

# ============================================================
# 3. name field
# ============================================================
echo ""
echo "--- name ---"

NAME=$(extract_field "name")

if [[ -z "$NAME" ]]; then
  fail "name: field missing or empty"
else
  pass "name: present ($NAME)"

  # Lowercase + hyphens only
  if echo "$NAME" | grep -qE '^[a-z][a-z0-9-]*$'; then
    pass "name: valid format (lowercase + hyphens)"
  else
    fail "name: must be lowercase letters, digits, and hyphens only (got: $NAME)"
  fi

  # ≤64 characters
  NAME_LEN=${#NAME}
  if [[ $NAME_LEN -le 64 ]]; then
    pass "name: length OK ($NAME_LEN chars, max 64)"
  else
    fail "name: too long ($NAME_LEN chars, max 64)"
  fi
fi

# ============================================================
# 4. description field
# ============================================================
echo ""
echo "--- description ---"

DESCRIPTION=$(extract_field "description")

if [[ -z "$DESCRIPTION" ]]; then
  fail "description: field missing or empty"
else
  DESC_LEN=${#DESCRIPTION}

  # ≤1024 characters
  if [[ $DESC_LEN -le 1024 ]]; then
    pass "description: length OK ($DESC_LEN chars, max 1024)"
  else
    fail "description: too long ($DESC_LEN chars, max 1024)"
  fi

  # Third person (should NOT start with "I ", "You ", etc.)
  if echo "$DESCRIPTION" | grep -qiE '^(I |You |We )'; then
    fail "description: should be third person (starts with I/You/We)"
  else
    pass "description: third person"
  fi

  # "Use when:" present
  if echo "$DESCRIPTION" | grep -q "Use when:"; then
    pass "description: contains 'Use when:'"
  else
    fail "description: must contain 'Use when:' trigger list"
  fi
fi

# ============================================================
# 5. metadata.version
# ============================================================
echo ""
echo "--- metadata.version ---"

VERSION=$(extract_version)

if [[ -z "$VERSION" ]]; then
  fail "metadata.version: missing"
else
  pass "metadata.version: present ($VERSION)"

  # Valid semver (major.minor.patch)
  if echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    pass "metadata.version: valid semver"
  else
    fail "metadata.version: invalid semver (expected X.Y.Z, got: $VERSION)"
  fi
fi

# ============================================================
# 6. No non-standard frontmatter fields
# ============================================================
echo ""
echo "--- frontmatter fields ---"

# Extract all top-level keys from first frontmatter block only
# Standard fields: name, description, metadata (and nested version)
FRONTMATTER_KEYS=$(get_frontmatter | grep -E '^[a-zA-Z]' | sed 's/:.*//' | sort -u)
NON_STANDARD=""

for key in $FRONTMATTER_KEYS; do
  case "$key" in
    name|description|metadata|model) ;; # allowed (model is valid for sub-agent skills)
    *) NON_STANDARD="$NON_STANDARD $key" ;;
  esac
done

if [[ -z "$NON_STANDARD" ]]; then
  pass "no non-standard frontmatter fields"
else
  fail "non-standard frontmatter fields:$NON_STANDARD (allowed: name, description, metadata, model)"
fi

# ============================================================
# 7. Body length (≤500 lines)
# ============================================================
echo ""
echo "--- body ---"

TOTAL_LINES=$(wc -l < "$SKILL_MD" | tr -d ' ')
# Body starts after second ---
BODY_LINES=$((TOTAL_LINES - FRONTMATTER_END))

if [[ $BODY_LINES -le 500 ]]; then
  pass "body: $BODY_LINES lines (max 500)"
else
  fail "body: too long ($BODY_LINES lines, max 500)"
fi

# ============================================================
# 8. Scripts validation (if scripts/ directory exists)
# ============================================================
if [[ -d "$SKILL_DIR/scripts" ]]; then
  echo ""
  echo "--- scripts ---"

  SCRIPT_COUNT=0
  while IFS= read -r script; do
    SCRIPT_COUNT=$((SCRIPT_COUNT + 1))  # safe with set -e (unlike ((var++)))
    SCRIPT_NAME=$(basename "$script")

    # Executable permission
    if [[ -x "$script" ]]; then
      pass "$SCRIPT_NAME: executable"
    else
      fail "$SCRIPT_NAME: not executable (chmod +x needed)"
    fi

    # Shebang
    FIRST_LINE=$(head -1 "$script")
    if [[ "$FIRST_LINE" == "#!/usr/bin/env bash" ]]; then
      pass "$SCRIPT_NAME: correct shebang"
    elif echo "$FIRST_LINE" | grep -q '^#!'; then
      warn "$SCRIPT_NAME: non-standard shebang ($FIRST_LINE), expected #!/usr/bin/env bash"
    else
      fail "$SCRIPT_NAME: missing shebang (first line: $FIRST_LINE)"
    fi

    # --help support
    if grep -q '\-\-help' "$script" 2>/dev/null; then
      pass "$SCRIPT_NAME: --help supported"
    else
      warn "$SCRIPT_NAME: no --help flag detected"
    fi
  done < <(find "$SKILL_DIR/scripts" -name '*.sh' -type f | sort)

  if [[ $SCRIPT_COUNT -eq 0 ]]; then
    warn "scripts/ directory exists but contains no .sh files"
  fi
fi

# ============================================================
# Summary
# ============================================================
echo ""
echo "============================================================"
if [[ $ERRORS -eq 0 ]]; then
  echo "Result: PASS ($WARNINGS warning(s))"
  exit 0
else
  echo "Result: FAIL ($ERRORS error(s), $WARNINGS warning(s))"
  exit 1
fi
