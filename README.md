# Fedora Dev Setup

Script para preparar una instalacion fresca de Fedora para desarrollo web y trabajo diario con GitHub.

## Archivos

- `fedora-dev-setup.sh`: script principal

## Requisitos

- Fedora Workstation o Fedora base
- usuario normal con `sudo`
- conexion a internet

El script detecta la distro leyendo `/etc/os-release` y aborta si no encuentra Fedora.

## Perfiles rapidos

Instalacion base:

```bash
./fedora-dev-setup.sh --minimal
```

Instalacion completa:

```bash
./fedora-dev-setup.sh \
  --full \
  --git-name "Tu Nombre" \
  --git-email "tu@email.com" \
  --ssh-passphrase "tu-passphrase-ssh" \
  --gpg-passphrase "tu-passphrase-gpg"
```

## Que incluye

Siempre instala:

- actualizacion del sistema con `dnf`
- repo oficial de Visual Studio Code
- `git`, `gh`, `python`, `pipx`, `node`, `npm`, compiladores y utilidades CLI
- `corepack`, `pnpm`, `yarn`
- `@openai/codex`, `npm-check-updates`, `typescript`
- extensiones base de VS Code

Opcionalmente puede configurar:

- SSH para GitHub
- GPG para firmar commits
- autenticacion con `gh`
- Podman con compatibilidad `docker`
- PostgreSQL local
- `zsh` como shell por defecto
- aliases utiles para shell

## Uso custom

```bash
./fedora-dev-setup.sh \
  --git-name "Tu Nombre" \
  --git-email "tu@email.com" \
  --setup-ssh \
  --ssh-passphrase "tu-passphrase-ssh" \
  --setup-gpg \
  --gpg-passphrase "tu-passphrase-gpg" \
  --sign-commits \
  --setup-gh \
  --gh-protocol ssh \
  --setup-podman \
  --setup-postgres \
  --setup-zsh \
  --make-zsh-default \
  --setup-aliases
```

Ayuda completa:

```bash
./fedora-dev-setup.sh --help
```

## Despues de correrlo

1. Reabrir la terminal.
2. Si activaste `zsh`, volver a iniciar sesion.
3. Subir la clave SSH publica a GitHub.
4. Si generaste GPG, subir la clave publica ASCII a GitHub.
5. Ejecutar `codex --login`.

## Notas

- `gh auth login` corre de forma interactiva.
- `--full` activa la mayoria de extras utiles para una maquina principal de desarrollo.
- Si no queres tocar shell, base de datos local o contenedores, usa `--minimal`.
