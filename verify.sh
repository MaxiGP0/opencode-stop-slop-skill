#!/usr/bin/env bash
# Check that the Stop Slop skill is installed for OpenCode.

set -euo pipefail

NAME="stop-slop"
SKILLS_DIR="${1:-${OPENCODE_SKILLS_DIR:-$HOME/.config/opencode/skills}}"
TARGET="$SKILLS_DIR/$NAME"

if [[ ! -d "$TARGET" ]]; then
    echo "FAIL  $NAME is not installed at $TARGET"
    echo "      Run install.sh first."
    exit 1
fi

MISSING=0
for required in \
    "SKILL.md" \
    "references/phrases.md" \
    "references/structures.md" \
    "references/examples.md" \
    "LICENSE"
do
    if [[ ! -f "$TARGET/$required" ]]; then
        echo "FAIL  Missing $required"
        MISSING=1
    fi
done

if [[ "$MISSING" -ne 0 ]]; then
    echo "      The installation is incomplete. Re-run install.sh --force."
    exit 1
fi

if ! grep -Eq "^name:[[:space:]]*$NAME[[:space:]]*$" "$TARGET/SKILL.md"; then
    echo "FAIL  SKILL.md has an unexpected 'name' field."
    exit 1
fi

if ! grep -Eq "^description:[[:space:]]*[^[:space:]]" "$TARGET/SKILL.md"; then
    echo "FAIL  SKILL.md has no description, so OpenCode will not list the skill."
    exit 1
fi

FILE_COUNT="$(find "$TARGET" -type f | wc -l | tr -d ' ')"
echo "OK  $NAME is installed at $TARGET ($FILE_COUNT files)."
