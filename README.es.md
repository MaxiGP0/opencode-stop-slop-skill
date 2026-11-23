# opencode-stop-slop-skill

[![CI](https://github.com/MaxiGP0/opencode-stop-slop-skill/actions/workflows/ci.yml/badge.svg)](https://github.com/MaxiGP0/opencode-stop-slop-skill/actions/workflows/ci.yml)

[English](README.md) | [Español](README.es.md)

Instalador de un solo comando que deja disponible en [OpenCode](https://opencode.ai) el skill gratuito **[Stop Slop](https://github.com/hardikpandya/stop-slop)**.

El skill original documenta Claude Code y Claude Projects. OpenCode lee los skills globales desde `~/.config/opencode/skills/<nombre>/`, así que este repositorio agrega un instalador y un verificador chicos, sin dependencias, para esa ruta. **Descarga el skill desde el repositorio oficial al instalar**; no lo reempaqueta ni modifica su contenido.

> Este es un instalador no oficial. No está afiliado a Hardik Pandya.

## Qué hace el skill

Stop Slop le enseña a un LLM a encontrar y eliminar patrones predecibles de escritura con IA. Se aplica al redactar, editar o revisar prosa, y apunta a las señales que hacen que un texto suene generado:

- **Muletillas y relleno:** aperturas que no dicen nada, apoyos enfáticos, jerga de negocios, adverbios, declaraciones vagas, metacomentario.
- **Clichés estructurales:** contrastes binarios, listas negativas, fragmentación dramática, planteos retóricos, falsa agencia, voz de narrador a distancia, voz pasiva.
- **Reglas a nivel de oración:** sin aperturas con palabras Wh-, sin guiones largos, sin fragmentación staccato, sin extremos perezosos.
- **Una rúbrica de 50 puntos** sobre franqueza, ritmo, confianza, autenticidad y densidad.
- **Ejemplos de antes y después** que muestran la reescritura, no solo la regla.

El skill viene como `SKILL.md` más tres archivos de referencia (`phrases.md`, `structures.md`, `examples.md`) que OpenCode carga cuando los necesita.

## Requisitos

- [OpenCode](https://opencode.ai) con soporte de skills.
- **Windows:** PowerShell 5.1 o superior (viene con Windows 10/11).
- **macOS / Linux:** `bash`, `curl` y `tar`.
- Sin otras dependencias.

## Instalación

### Windows (PowerShell)

Descargá, revisá y ejecutá:

```powershell
Invoke-WebRequest https://raw.githubusercontent.com/MaxiGP0/opencode-stop-slop-skill/main/install.ps1 -OutFile install.ps1
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

O ejecutalo directamente:

```powershell
irm https://raw.githubusercontent.com/MaxiGP0/opencode-stop-slop-skill/main/install.ps1 | iex
```

Para actualizar:

```powershell
# Si guardaste install.ps1:
.\install.ps1 -Force

# O sin guardarlo:
$env:STOP_SLOP_FORCE=1; irm https://raw.githubusercontent.com/MaxiGP0/opencode-stop-slop-skill/main/install.ps1 | iex
```

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/MaxiGP0/opencode-stop-slop-skill/main/install.sh | bash
```

Para actualizar:

```bash
curl -fsSL https://raw.githubusercontent.com/MaxiGP0/opencode-stop-slop-skill/main/install.sh | bash -s -- --force
```

Si preferís leer el script antes:

```bash
curl -fsSL https://raw.githubusercontent.com/MaxiGP0/opencode-stop-slop-skill/main/install.sh -o install.sh
bash install.sh
```

### Opciones

| PowerShell | Bash | Descripción |
| --- | --- | --- |
| `-SkillDir PATH` | `--dir PATH` | Raíz de skills de OpenCode. Por defecto: `~/.config/opencode/skills` |
| `-Ref REF` | `--ref REF` | Rama, tag o commit del repo original. Por defecto: `main` |
| `-Force` | `--force` | Reemplaza una instalación existente |

También funcionan las variables de entorno `OPENCODE_SKILLS_DIR`, `STOP_SLOP_REF` y `STOP_SLOP_FORCE=1`.

El skill se instala en:

- Windows: `%USERPROFILE%\.config\opencode\skills\stop-slop`
- macOS / Linux: `~/.config/opencode/skills/stop-slop`

## Verificar la instalación

```powershell
.\verify.ps1
```

```bash
bash verify.sh
```

O comprobá a mano:

```bash
ls ~/.config/opencode/skills/stop-slop/SKILL.md
```

Después de instalar, **abrí una sesión nueva de OpenCode** para que tome el skill.

## Cómo usarlo

Pedile a OpenCode que redacte, edite o revise prosa. El skill se activa automáticamente:

- *"Draft a release note for my CLI and keep the prose direct."*
- *"Edit this paragraph: cut the filler, the passive voice, and the em dashes."*
- *"Review this README and flag every predictable AI phrase."*
- *"Rewrite this landing page copy in plain English."*
- *"Reescribí este párrafo sin muletillas, sin voz pasiva y sin guiones largos."*

Funciona en documentación, correos, posts, release notes, landing pages y cualquier otro texto que le pases.

## Cómo funciona

1. Descarga el archivo del repositorio original desde `codeload.github.com` (rama, tag o commit).
2. Lo extrae en un directorio temporal.
3. Valida `SKILL.md` (nombre y descripción) y ubica `references/` y `LICENSE`.
4. Copia solo `SKILL.md`, `references/` y `LICENSE` a la carpeta global de skills de OpenCode.

En este repositorio no se guarda una copia del skill: el instalador es un descargador fino más un verificador.

## Actualizar y desinstalar

Actualizá volviendo a ejecutar el instalador con `-Force` / `--force`. El instalador siempre baja la revisión actual del repo original, así que las actualizaciones llegan apenas Hardik Pandya las publica.

Desinstalar:

```powershell
Remove-Item -Recurse -Force "$HOME\.config\opencode\skills\stop-slop"
```

```bash
rm -rf ~/.config/opencode/skills/stop-slop
```

## Instalación manual

Si preferís no ejecutar un instalador:

```bash
git clone --depth 1 https://github.com/hardikpandya/stop-slop.git
mkdir -p ~/.config/opencode/skills/stop-slop
cp stop-slop/SKILL.md stop-slop/LICENSE ~/.config/opencode/skills/stop-slop/
cp -R stop-slop/references ~/.config/opencode/skills/stop-slop/
```

En Windows, reemplazá `~/.config/opencode/skills` por `%USERPROFILE%\.config\opencode\skills`.

## Licencias y atribución

- **Este instalador:** MIT. Ver [LICENSE](LICENSE).
- **Stop Slop:** MIT, Copyright (c) 2025 Hardik Pandya. Ver la [licencia original](https://github.com/hardikpandya/stop-slop/blob/main/LICENSE).
- **Stop Slop** lo creó [Hardik Pandya](https://hvpandya.com). Este proyecto es no oficial y no está afiliado al autor.

Si el skill te resulta útil, dale una estrella al repositorio original: [hardikpandya/stop-slop](https://github.com/hardikpandya/stop-slop).

## Solución de problemas

**El skill no aparece en OpenCode.** Confirmá la ruta con `verify.ps1` / `verify.sh` y abrí una sesión nueva. OpenCode lee la carpeta de skills al iniciar la sesión.

**PowerShell bloquea el script.** Usá `powershell -ExecutionPolicy Bypass -File .\install.ps1`.

**Falta `curl` en Linux.** Instalalo (`sudo apt install curl`, `sudo dnf install curl` o el equivalente de tu distribución).

**La descarga falla.** El instalador necesita acceso a `github.com` y `codeload.github.com`. Revisá el proxy o el firewall.

**El instalador dice que el skill ya está instalado.** Volvé a ejecutarlo con `-Force` / `--force` para reemplazar la copia existente.

**Una rama o un tag no existe.** Revisá el nombre, o pasá un commit SHA con `-Ref` / `--ref`.
