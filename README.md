# opencode-stop-slop-skill

[![CI](https://github.com/MaxiGP0/opencode-stop-slop-skill/actions/workflows/ci.yml/badge.svg)](https://github.com/MaxiGP0/opencode-stop-slop-skill/actions/workflows/ci.yml)

[English](README.md) | [Español](README.es.md)

One-command installer that makes the free **[Stop Slop](https://github.com/hardikpandya/stop-slop)** skill available in [OpenCode](https://opencode.ai).

The upstream skill documents Claude Code and Claude Projects. OpenCode reads global skills from `~/.config/opencode/skills/<name>/`, so this repository adds a small, dependency-free installer and verifier for that layout. It **downloads the skill from the official repository at install time**; it does not re-host or modify the skill's content.

> This is an unofficial installer. It is not affiliated with Hardik Pandya.

## What the skill does

Stop Slop teaches an LLM to find and remove predictable AI writing patterns. It applies while drafting, editing, or reviewing prose, and it targets the tells that make text sound generated:

- **Filler phrases:** throat-clearing openers, emphasis crutches, business jargon, adverbs, vague declaratives, meta-commentary.
- **Structural clichés:** binary contrasts, negative listings, dramatic fragmentation, rhetorical setups, false agency, narrator-from-a-distance voice, passive voice.
- **Sentence-level rules:** no Wh- sentence starters, no em dashes, no staccato fragmentation, no lazy extremes.
- **A 50-point scoring rubric** across directness, rhythm, trust, authenticity, and density.
- **Before/after examples** that show the rewrite, not just the rule.

The skill ships as `SKILL.md` plus three reference files (`phrases.md`, `structures.md`, `examples.md`) that OpenCode loads on demand.

## Requirements

- [OpenCode](https://opencode.ai) with skills support.
- **Windows:** PowerShell 5.1 or newer (built into Windows 10/11).
- **macOS / Linux:** `bash`, `curl`, and `tar`.
- No other dependencies.

## Install

### Windows (PowerShell)

Download, inspect, and run:

```powershell
Invoke-WebRequest https://raw.githubusercontent.com/MaxiGP0/opencode-stop-slop-skill/main/install.ps1 -OutFile install.ps1
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Or run it directly:

```powershell
irm https://raw.githubusercontent.com/MaxiGP0/opencode-stop-slop-skill/main/install.ps1 | iex
```

To update:

```powershell
# If you saved install.ps1:
.\install.ps1 -Force

# Or without saving it:
$env:STOP_SLOP_FORCE=1; irm https://raw.githubusercontent.com/MaxiGP0/opencode-stop-slop-skill/main/install.ps1 | iex
```

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/MaxiGP0/opencode-stop-slop-skill/main/install.sh | bash
```

To update:

```bash
curl -fsSL https://raw.githubusercontent.com/MaxiGP0/opencode-stop-slop-skill/main/install.sh | bash -s -- --force
```

Read the script first if you prefer:

```bash
curl -fsSL https://raw.githubusercontent.com/MaxiGP0/opencode-stop-slop-skill/main/install.sh -o install.sh
bash install.sh
```

### Options

| PowerShell | Bash | Description |
| --- | --- | --- |
| `-SkillDir PATH` | `--dir PATH` | OpenCode skills root. Default: `~/.config/opencode/skills` |
| `-Ref REF` | `--ref REF` | Branch, tag, or commit of the upstream repo. Default: `main` |
| `-Force` | `--force` | Replace an existing installation |

Environment variables `OPENCODE_SKILLS_DIR`, `STOP_SLOP_REF`, and `STOP_SLOP_FORCE=1` work too.

The skill is installed to:

- Windows: `%USERPROFILE%\.config\opencode\skills\stop-slop`
- macOS / Linux: `~/.config/opencode/skills/stop-slop`

## Verify the installation

```powershell
.\verify.ps1
```

```bash
bash verify.sh
```

Or check manually:

```bash
ls ~/.config/opencode/skills/stop-slop/SKILL.md
```

After installing, **start a new OpenCode session** so it picks up the skill.

## Use it

Ask OpenCode to draft, edit, or review prose. The skill triggers automatically:

- *"Draft a release note for my CLI and keep the prose direct."*
- *"Edit this paragraph: cut the filler, the passive voice, and the em dashes."*
- *"Review this README and flag every predictable AI phrase."*
- *"Rewrite this landing page copy in plain English."*
- *"Reescribí este párrafo sin muletillas, sin voz pasiva y sin guiones largos."*

It works on documentation, emails, blog posts, release notes, landing pages, and any other prose you hand it.

## How it works

1. Download the upstream repository archive from `codeload.github.com` (default branch, tag, or commit).
2. Extract it to a temporary directory.
3. Validate `SKILL.md` (name and description) and locate `references/` and `LICENSE`.
4. Copy only `SKILL.md`, `references/`, and `LICENSE` into the OpenCode global skills folder.

Nothing is vendored in this repository: the installer is a thin downloader plus a verifier.

## Update and uninstall

Update by re-running the installer with `-Force` / `--force`. The installer always fetches the current upstream revision, so updates arrive as soon as Hardik Pandya publishes them.

Uninstall:

```powershell
Remove-Item -Recurse -Force "$HOME\.config\opencode\skills\stop-slop"
```

```bash
rm -rf ~/.config/opencode/skills/stop-slop
```

## Manual installation

If you prefer not to run an installer:

```bash
git clone --depth 1 https://github.com/hardikpandya/stop-slop.git
mkdir -p ~/.config/opencode/skills/stop-slop
cp stop-slop/SKILL.md stop-slop/LICENSE ~/.config/opencode/skills/stop-slop/
cp -R stop-slop/references ~/.config/opencode/skills/stop-slop/
```

On Windows, replace `~/.config/opencode/skills` with `%USERPROFILE%\.config\opencode\skills`.

## Licenses and attribution

- **This installer:** MIT. See [LICENSE](LICENSE).
- **Stop Slop:** MIT, Copyright (c) 2025 Hardik Pandya. See the [upstream license](https://github.com/hardikpandya/stop-slop/blob/main/LICENSE).
- **Stop Slop** is created by [Hardik Pandya](https://hvpandya.com). This project is unofficial and not affiliated with the author.

If you find the skill useful, star the original repository: [hardikpandya/stop-slop](https://github.com/hardikpandya/stop-slop).

## Troubleshooting

**The skill does not appear in OpenCode.** Confirm the path with `verify.ps1` / `verify.sh`, then start a new session. OpenCode reads the skills folder when a session starts.

**PowerShell blocks the script.** Use `powershell -ExecutionPolicy Bypass -File .\install.ps1`.

**`curl` is missing on Linux.** Install it (`sudo apt install curl`, `sudo dnf install curl`, or your distribution's equivalent).

**The download fails.** The installer needs access to `github.com` and `codeload.github.com`. Check your proxy or firewall.

**The installer says the skill is already installed.** Re-run it with `-Force` / `--force` to replace the existing copy.

**A branch or tag does not exist.** Check the name, or pass a commit SHA with `-Ref` / `--ref`.
