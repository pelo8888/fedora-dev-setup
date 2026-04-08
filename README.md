# Fedora Dev Setup

Script para preparar una instalacion fresca de Fedora para desarrollo web y trabajo diario con GitHub.

## Archivos

- `fedora-dev-setup.sh`: script principal
- `fedora-dev-setup-zsh.zsh`: variante nueva enfocada en `zsh` y terminal

## Requisitos

- Fedora Workstation o Fedora base
- usuario normal con `sudo`
- conexion a internet

El script detecta la distro leyendo `/etc/os-release` y aborta si no encuentra Fedora.

## Revision rapida del script actual

El script original resuelve bien la instalacion base, pero en `zsh` se queda corto para uso diario:

- instala `zsh`, pero no deja una configuracion real de prompt, completions, historial ni keybindings
- agrega aliases, pero no gestiona archivos dedicados para shell ni `tmux`
- mezcla setup de shell con extras de escritorio y backend, cuando el uso de terminal merece una variante propia

Por eso se agrega una segunda version orientada a `zsh`.

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

Instalacion orientada a `zsh` y terminal:

```bash
./fedora-dev-setup-zsh.zsh \
  all \
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

La variante `zsh` tambien:

- deja configurado `zsh` con historial, completions, `fzf`, aliases y funciones utiles
- escribe configuracion gestionada en `~/.config/fedora-dev-setup/`
- configura `tmux`, `git-delta`, `starship` y hooks para `zoxide`, `direnv` y `atuin` cuando estan disponibles
- puede instalar TPM y plugins de `tmux` como `tmux-resurrect` y `tmux-continuum`
- instala y deja accesible `lazygit` si el paquete existe en Fedora
- crea una configuracion modular de `neovim` en `lua/fedora/` y puede pasar a una variante opinionada con `lazy.nvim`, `telescope`, `treesitter`, `gitsigns`, `which-key` y `lualine`
- puede instalar `podman` y `postgresql` local con flags opcionales o con `--full`
- puede instalar herramientas de Kubernetes con `--setup-k8s`
- intenta instalar extras de terminal como `eza`, `bat`, `btop`, `htop`, `tealdeer` y `zoxide`

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

Ayuda de la variante `zsh`:

```bash
./fedora-dev-setup-zsh.zsh --help
```

Ejemplo custom de la variante `zsh`:

```bash
./fedora-dev-setup-zsh.zsh \
  all \
  --git-name "Tu Nombre" \
  --git-email "tu@email.com" \
  --setup-ssh \
  --setup-gpg \
  --sign-commits \
  --setup-gh \
  --setup-podman \
  --setup-postgres \
  --setup-tmux-plugins \
  --setup-nvim-extras \
  --setup-k8s \
  --make-zsh-default
```

Etapas disponibles en la variante `zsh`:

- `all`: corre todo el flujo
- `bootstrap`: actualiza Fedora e instala repos y paquetes base
- `devtools`: configura npm, corepack, Node global, Git, SSH, GPG, `gh` y extensiones
- `shell`: escribe `zsh`, `tmux` y `neovim`, y opcionalmente cambia el shell por defecto
- `services`: instala `podman`, `postgresql` y herramientas de Kubernetes segun flags
- `doctor`: no instala nada; revisa si el sistema ya cumple las precondiciones y si existen archivos/configs esperados

Precondiciones por etapa:

- `devtools` espera que ya existan `git`, `npm`, `pipx` y `python3`
- `shell` espera `zsh`, `tmux` y `nvim`
- `services` valida `sudo`, `dnf` y `systemctl`
- si corres una etapa aislada y falta algo, el script te indica usar `bootstrap` o `all`

Ejemplos por etapa:

```bash
./fedora-dev-setup-zsh.zsh bootstrap
./fedora-dev-setup-zsh.zsh devtools --setup-gh --setup-ssh --git-email "tu@email.com"
./fedora-dev-setup-zsh.zsh shell --setup-tmux-plugins --setup-nvim-extras --make-zsh-default
./fedora-dev-setup-zsh.zsh services --setup-podman --setup-postgres --setup-k8s
./fedora-dev-setup-zsh.zsh doctor --setup-gh --setup-podman --setup-tmux-plugins
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
- en la variante `zsh`, `--full` ahora tambien activa plugins de `tmux` y una configuracion opinionada de `neovim`
- la configuracion generada de `neovim` ya no queda en un unico `init.lua`; se separa en modulos para mantenimiento mas simple
- la configuracion de `zsh`, `tmux`, `starship` y `neovim` ahora sale de plantillas versionadas en `templates/`
- la logica del instalador `zsh` se reparte ahora en modulos dentro de `lib/fedora-dev-setup/`
- la variante `zsh` acepta subcomandos para correr solo una etapa del setup
- las etapas aisladas validan precondiciones minimas antes de correr
- `doctor` permite auditar el estado del equipo sin instalar nada
- `--setup-k8s` es opcional para no instalar herramientas de Kubernetes en maquinas donde no hacen falta
- Si no queres tocar shell, base de datos local o contenedores, usa `--minimal`.
