#!/usr/bin/env bash
# Install the free Stop Slop skill for OpenCode.
#
# Downloads the skill from the official hardikpandya/stop-slop repository
# and copies it to the OpenCode global skills directory, so OpenCode discovers
# it automatically. Nothing is vendored or re-hosted by this project.

set -euo pipefail

REPO="hardikpandya/stop-slop"
NAME="stop-slop"
REF="${STOP_SLOP_REF:-main}"
SKILLS_DIR="${OPENCODE_SKILLS_DIR:-$HOME/.config/opencode/skills}"
FORCE=0
if [[ "${STOP_SLOP_FORCE:-0}" == "1" ]]; then
    FORCE=1
fi

usage() {
    cat <<EOF
Usage: install.sh [options]

Options:
  --dir PATH    OpenCode skills root (default: ~/.config/opencode/skills)
  --ref REF     Branch, tag, or commit of the upstream repo (default: main)
  --force       Replace an existing installation
  -h, --help    Show this help

Environment:
  OPENCODE_SKILLS_DIR   Same as --dir
  STOP_SLOP_REF         Same as --ref
  STOP_SLOP_FORCE=1     Same as --force
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dir)
            [[ $# -ge 2 ]] || { echo "Missing value for --dir" >&2; exit 1; }
            SKILLS_DIR="$2"
            shift 2
            ;;
        --ref)
            [[ $# -ge 2 ]] || { echo "Missing value for --ref" >&2; exit 1; }
            REF="$2"
            shift 2
            ;;
        --force)
            FORCE=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

for cmd in curl tar; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: '$cmd' is required but was not found in PATH." >&2
        exit 1
    fi
done

TARGET="$SKILLS_DIR/$NAME"
if [[ "$(basename "$TARGET")" != "$NAME" ]]; then
    echo "Refusing to install to an unexpected path: $TARGET" >&2
    exit 1
fi

if [[ -d "$TARGET" ]]; then
    if [[ "$FORCE" -ne 1 ]]; then
        echo "!!  $NAME is already installed at:"
        echo "    $TARGET"
        echo "    Re-run with --force to update it."
        exit 0
    fi
    echo "==> Removing the existing installation"
    rm -rf -- "$TARGET"
fi

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/stop-slop.XXXXXX")"
cleanup() {
    rm -rf -- "$TMP_DIR"
}
trap cleanup EXIT

URL="https://codeload.github.com/$REPO/tar.gz/$REF"
ARCHIVE="$TMP_DIR/skill.tar.gz"

echo "==> Downloading $URL"
curl -fsSL "$URL" -o "$ARCHIVE"

echo "==> Extracting"
tar -xzf "$ARCHIVE" -C "$TMP_DIR"

SKILL_MD=""
while IFS= read -r candidate; do
    if grep -Eq "^name:[[:space:]]*$NAME[[:space:]]*$" "$candidate"; then
        SKILL_MD="$candidate"
        break
    fi
done < <(find "$TMP_DIR" -type f -name "SKILL.md")

if [[ -z "$SKILL_MD" ]]; then
    echo "Error: could not find $NAME/SKILL.md in the downloaded archive." >&2
    echo "The upstream layout may have changed." >&2
    exit 1
fi

if ! grep -Eq "^description:[[:space:]]*[^[:space:]]" "$SKILL_MD"; then
    echo "Error: SKILL.md has no description, so OpenCode will not list the skill." >&2
    exit 1
fi

SOURCE_DIR="$(dirname "$SKILL_MD")"

if [[ ! -d "$SOURCE_DIR/references" ]]; then
    echo "Error: the upstream archive has no references/ directory." >&2
    echo "The upstream layout may have changed." >&2
    exit 1
fi

if [[ ! -f "$SOURCE_DIR/LICENSE" ]]; then
    echo "Error: the upstream archive has no LICENSE file." >&2
    echo "The upstream layout may have changed." >&2
    exit 1
fi

echo "==> Installing to $TARGET"
mkdir -p -- "$SKILLS_DIR" "$TARGET"
cp -- "$SOURCE_DIR/SKILL.md" "$TARGET/"
cp -R -- "$SOURCE_DIR/references" "$TARGET/"
cp -- "$SOURCE_DIR/LICENSE" "$TARGET/"

for required in \
    "SKILL.md" \
    "references/phrases.md" \
    "references/structures.md" \
    "references/examples.md" \
    "LICENSE"
do
    if [[ ! -f "$TARGET/$required" ]]; then
        echo "Error: installation is incomplete: missing $required." >&2
        exit 1
    fi
done

FILE_COUNT="$(find "$TARGET" -type f | wc -l | tr -d ' ')"
echo "OK  Installed $FILE_COUNT files to $TARGET"

cat <<EOF

Start a new OpenCode session and ask it to draft, edit or review prose.
The skill is picked up automatically. Examples:
  - "Draft a launch note for my note-taking app without the usual AI tells."
  - "Edit this paragraph: cut the filler, the passive voice and the em dashes."
  - "Review this README and flag every predictable AI phrase."

Source and license: https://github.com/$REPO
EOF
