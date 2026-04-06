#!/usr/bin/env bash

set -euo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Ejecuta este script como tu usuario normal, no como root."
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "Este script necesita sudo."
  exit 1
fi

require_fedora() {
  if [[ ! -r /etc/os-release ]]; then
    echo "No pude detectar la distribucion. Este script requiere Fedora."
    exit 1
  fi

  # shellcheck disable=SC1091
  . /etc/os-release

  if [[ "${ID:-}" != "fedora" ]]; then
    echo "Distribucion detectada: ${PRETTY_NAME:-desconocida}"
    echo "Este script esta pensado para Fedora y aborta para evitar cambios incompatibles."
    exit 1
  fi
}

USER_HOME="${HOME}"
SCRIPT_NAME="$(basename "$0")"
PROFILE_FILES=("${USER_HOME}/.bashrc" "${USER_HOME}/.zshrc")
SETUP_SSH=0
SETUP_GPG=0
SETUP_GH=0
SETUP_PODMAN=0
SETUP_POSTGRES=0
SETUP_ZSH=0
MAKE_ZSH_DEFAULT=0
SETUP_ALIASES=0
SIGN_COMMITS=0
PROFILE_MINIMAL=0
PROFILE_FULL=0
GIT_NAME="${GIT_NAME:-}"
GIT_EMAIL="${GIT_EMAIL:-}"
SSH_EMAIL="${SSH_EMAIL:-}"
SSH_KEY_PATH="${SSH_KEY_PATH:-${USER_HOME}/.ssh/id_ed25519}"
SSH_PASSPHRASE="${SSH_PASSPHRASE:-}"
GPG_NAME="${GPG_NAME:-}"
GPG_EMAIL="${GPG_EMAIL:-}"
GPG_PASSPHRASE="${GPG_PASSPHRASE:-}"
GENERATED_GPG_KEY=""
GH_PROTOCOL="${GH_PROTOCOL:-ssh}"

usage() {
  cat <<EOF
Uso:
  ./${SCRIPT_NAME} [opciones]

Que hace este script:
  - Actualiza Fedora con dnf.
  - Agrega el repositorio oficial RPM de Visual Studio Code.
  - Instala herramientas base para desarrollo web:
    git, gh, python, pip, pipx, node, npm, compiladores, ripgrep, fd, fzf, tmux y utilidades varias.
  - Configura npm para instalar paquetes globales en ~/.local/bin.
  - Habilita corepack y prepara pnpm y yarn.
  - Instala herramientas globales de Node:
    @openai/codex, npm-check-updates y typescript.
  - Configura Git con valores globales si le pasas nombre y email.
  - Opcionalmente genera una clave SSH para GitHub.
  - Opcionalmente genera una clave GPG para firmar commits.
  - Opcionalmente habilita firma de commits en Git.
  - Opcionalmente lanza autenticacion interactiva de GitHub CLI.
  - Opcionalmente instala Podman con compatibilidad para usar el comando docker.
  - Opcionalmente instala PostgreSQL local, inicializa la base y habilita el servicio.
  - Opcionalmente instala zsh y puede dejarlo como shell por defecto.
  - Opcionalmente agrega aliases utiles de terminal, git y codex.
  - Instala extensiones base de Visual Studio Code.
  - Muestra un resumen final con versiones y rutas de claves generadas.

Opciones:
  --minimal
  --full
  --git-name "Tu Nombre"
  --git-email "tu@email.com"
  --setup-ssh
  --ssh-email "tu@email.com"
  --ssh-key-path "/home/usuario/.ssh/id_ed25519"
  --ssh-passphrase "frase-secreta"
  --setup-gpg
  --gpg-name "Tu Nombre"
  --gpg-email "tu@email.com"
  --gpg-passphrase "frase-secreta"
  --setup-gh
  --gh-protocol ssh|https
  --setup-podman
  --setup-postgres
  --setup-zsh
  --make-zsh-default
  --setup-aliases
  --sign-commits
  --help

Tambien soporta estas variables de entorno:
  GIT_NAME, GIT_EMAIL, SSH_EMAIL, SSH_KEY_PATH, SSH_PASSPHRASE,
  GPG_NAME, GPG_EMAIL, GPG_PASSPHRASE, GH_PROTOCOL

Notas:
  - --minimal instala el entorno base de desarrollo web sin extras opcionales.
  - --full activa GitHub, SSH, GPG, firma de commits, Podman, PostgreSQL, zsh y aliases.
  - --setup-gh ejecuta 'gh auth login' de forma interactiva.
  - Si usas --setup-gh con --gh-protocol ssh, conviene combinarlo con --setup-ssh.
  - Si usas --sign-commits sin --setup-gpg, el script espera que ya exista una clave GPG configurada.
  - --setup-postgres inicializa y habilita PostgreSQL local para desarrollo.
  - --make-zsh-default requiere --setup-zsh y cambia tu shell con chsh.
  - El script esta pensado para correrse como usuario normal con sudo disponible.
EOF
}

require_value() {
  local flag="$1"
  local value="${2:-}"

  if [[ -z "${value}" ]]; then
    echo "Falta un valor para ${flag}"
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --minimal)
      PROFILE_MINIMAL=1
      shift
      ;;
    --full)
      PROFILE_FULL=1
      shift
      ;;
    --git-name)
      require_value "$1" "${2:-}"
      GIT_NAME="$2"
      shift 2
      ;;
    --git-email)
      require_value "$1" "${2:-}"
      GIT_EMAIL="$2"
      shift 2
      ;;
    --setup-ssh)
      SETUP_SSH=1
      shift
      ;;
    --ssh-email)
      require_value "$1" "${2:-}"
      SSH_EMAIL="$2"
      shift 2
      ;;
    --ssh-key-path)
      require_value "$1" "${2:-}"
      SSH_KEY_PATH="$2"
      shift 2
      ;;
    --ssh-passphrase)
      require_value "$1" "${2:-}"
      SSH_PASSPHRASE="$2"
      shift 2
      ;;
    --setup-gpg)
      SETUP_GPG=1
      shift
      ;;
    --gpg-name)
      require_value "$1" "${2:-}"
      GPG_NAME="$2"
      shift 2
      ;;
    --gpg-email)
      require_value "$1" "${2:-}"
      GPG_EMAIL="$2"
      shift 2
      ;;
    --gpg-passphrase)
      require_value "$1" "${2:-}"
      GPG_PASSPHRASE="$2"
      shift 2
      ;;
    --setup-gh)
      SETUP_GH=1
      shift
      ;;
    --gh-protocol)
      require_value "$1" "${2:-}"
      GH_PROTOCOL="$2"
      shift 2
      ;;
    --setup-podman)
      SETUP_PODMAN=1
      shift
      ;;
    --setup-postgres)
      SETUP_POSTGRES=1
      shift
      ;;
    --setup-zsh)
      SETUP_ZSH=1
      shift
      ;;
    --make-zsh-default)
      MAKE_ZSH_DEFAULT=1
      shift
      ;;
    --setup-aliases)
      SETUP_ALIASES=1
      shift
      ;;
    --sign-commits)
      SIGN_COMMITS=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Opcion no reconocida: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ "${PROFILE_MINIMAL}" -eq 1 && "${PROFILE_FULL}" -eq 1 ]]; then
  echo "No puedes usar --minimal y --full al mismo tiempo."
  exit 1
fi

if [[ "${PROFILE_FULL}" -eq 1 ]]; then
  SETUP_SSH=1
  SETUP_GPG=1
  SETUP_GH=1
  SETUP_PODMAN=1
  SETUP_POSTGRES=1
  SETUP_ZSH=1
  MAKE_ZSH_DEFAULT=1
  SETUP_ALIASES=1
  SIGN_COMMITS=1
fi

if [[ "${GH_PROTOCOL}" != "ssh" && "${GH_PROTOCOL}" != "https" ]]; then
  echo "Valor invalido para --gh-protocol: ${GH_PROTOCOL}. Usa ssh o https."
  exit 1
fi

if [[ "${MAKE_ZSH_DEFAULT}" -eq 1 && "${SETUP_ZSH}" -ne 1 ]]; then
  echo "Usa --make-zsh-default junto con --setup-zsh."
  exit 1
fi

require_fedora

log() {
  printf '\n[%s] %s\n' "$(date '+%H:%M:%S')" "$*"
}

append_if_missing() {
  local file="$1"
  local line="$2"

  touch "${file}"
  if ! grep -Fqx "${line}" "${file}"; then
    printf '%s\n' "${line}" >>"${file}"
  fi
}

append_block_if_missing() {
  local file="$1"
  local marker="$2"
  local content="$3"

  touch "${file}"
  if ! grep -Fq "${marker}" "${file}"; then
    printf '\n%s\n' "${content}" >>"${file}"
  fi
}

install_vscode_repo() {
  log "Configurando el repo oficial de Visual Studio Code"
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
}

configure_npm_prefix() {
  log "Configurando npm global en ~/.local"
  mkdir -p "${USER_HOME}/.local/bin" "${USER_HOME}/.npm-global"
  npm config set prefix "${USER_HOME}/.local"
  append_if_missing "${USER_HOME}/.profile" 'export PATH="$HOME/.local/bin:$PATH"'

  for profile in "${PROFILE_FILES[@]}"; do
    append_if_missing "${profile}" 'export PATH="$HOME/.local/bin:$PATH"'
  done

  export PATH="${USER_HOME}/.local/bin:${PATH}"
}

install_vscode_extensions() {
  if ! command -v code >/dev/null 2>&1; then
    log "Saltando extensiones de VS Code porque 'code' no quedo disponible en PATH"
    return
  fi

  local extensions=(
    "dbaeumer.vscode-eslint"
    "esbenp.prettier-vscode"
    "ms-python.python"
    "ms-python.vscode-pylance"
    "bradlc.vscode-tailwindcss"
    "ms-azuretools.vscode-docker"
    "eamodio.gitlens"
  )

  log "Instalando extensiones base de VS Code"
  for ext in "${extensions[@]}"; do
    code --install-extension "${ext}" --force >/dev/null || true
  done
}

configure_git_if_requested() {
  if [[ -n "${GIT_NAME:-}" ]]; then
    git config --global user.name "${GIT_NAME}"
  fi

  if [[ -n "${GIT_EMAIL:-}" ]]; then
    git config --global user.email "${GIT_EMAIL}"
  fi

  git config --global init.defaultBranch main
  git config --global pull.rebase false
}

setup_ssh_key() {
  local ssh_email="${SSH_EMAIL:-${GIT_EMAIL:-}}"

  if [[ -z "${ssh_email}" ]]; then
    echo "Para --setup-ssh necesitas --ssh-email o --git-email."
    exit 1
  fi

  log "Configurando clave SSH"
  mkdir -p "$(dirname "${SSH_KEY_PATH}")"
  chmod 700 "$(dirname "${SSH_KEY_PATH}")"

  if [[ -f "${SSH_KEY_PATH}" ]]; then
    log "La clave SSH ya existe en ${SSH_KEY_PATH}; no se regenera"
  else
    ssh-keygen -t ed25519 -C "${ssh_email}" -f "${SSH_KEY_PATH}" -N "${SSH_PASSPHRASE}"
    if [[ -z "${SSH_PASSPHRASE}" ]]; then
      log "La clave SSH se genero sin passphrase. Si no quieres eso, rerun con --ssh-passphrase."
    fi
  fi

  if [[ ! -f "${USER_HOME}/.ssh/config" ]]; then
    touch "${USER_HOME}/.ssh/config"
    chmod 600 "${USER_HOME}/.ssh/config"
  fi

  if ! grep -Fq "IdentityFile ${SSH_KEY_PATH}" "${USER_HOME}/.ssh/config"; then
    cat >>"${USER_HOME}/.ssh/config" <<EOF
Host github.com
  HostName github.com
  User git
  IdentityFile ${SSH_KEY_PATH}
  IdentitiesOnly yes
EOF
  fi
}

setup_gpg_key() {
  local gpg_name="${GPG_NAME:-${GIT_NAME:-}}"
  local gpg_email="${GPG_EMAIL:-${GIT_EMAIL:-}}"
  local uid existing_key batch_file pub_file

  if [[ -z "${gpg_name}" || -z "${gpg_email}" ]]; then
    echo "Para --setup-gpg necesitas nombre y email. Usa --gpg-name/--gpg-email o --git-name/--git-email."
    exit 1
  fi

  uid="${gpg_name} <${gpg_email}>"
  existing_key="$(gpg --list-secret-keys --with-colons "${uid}" 2>/dev/null | awk -F: '/^fpr:/ {print $10; exit}')"

  if [[ -n "${existing_key}" ]]; then
    GENERATED_GPG_KEY="${existing_key}"
    log "Ya existe una clave GPG para ${uid}; se reutiliza"
  else
    log "Generando clave GPG para firma de commits"
    batch_file="$(mktemp)"
    {
      echo "Key-Type: eddsa"
      echo "Key-Curve: ed25519"
      echo "Subkey-Type: ecdh"
      echo "Subkey-Curve: cv25519"
      echo "Name-Real: ${gpg_name}"
      echo "Name-Email: ${gpg_email}"
      echo "Expire-Date: 0"
      if [[ -n "${GPG_PASSPHRASE}" ]]; then
        echo "Passphrase: ${GPG_PASSPHRASE}"
      else
        echo "%no-protection"
      fi
      echo "%commit"
    } >"${batch_file}"

    gpg --batch --generate-key "${batch_file}"
    rm -f "${batch_file}"
    GENERATED_GPG_KEY="$(gpg --list-secret-keys --with-colons "${uid}" 2>/dev/null | awk -F: '/^fpr:/ {print $10; exit}')"
  fi

  if [[ -z "${GENERATED_GPG_KEY}" ]]; then
    echo "No pude obtener el fingerprint de la clave GPG."
    exit 1
  fi

  git config --global user.signingkey "${GENERATED_GPG_KEY}"
  git config --global gpg.format openpgp

  if [[ "${SIGN_COMMITS}" -eq 1 ]]; then
    git config --global commit.gpgsign true
  fi

  pub_file="${USER_HOME}/.gnupg/github-signing-key.asc"
  gpg --armor --export "${GENERATED_GPG_KEY}" >"${pub_file}"

  if [[ -z "${GPG_PASSPHRASE}" ]]; then
    log "La clave GPG se genero sin passphrase. Si no quieres eso, rerun con --gpg-passphrase."
  fi
}

setup_github_cli_auth() {
  log "Configurando autenticacion de GitHub CLI"

  if gh auth status >/dev/null 2>&1; then
    log "GitHub CLI ya esta autenticado"
  else
    gh auth login --git-protocol "${GH_PROTOCOL}" --web
  fi

  gh auth setup-git >/dev/null 2>&1 || true
}

setup_podman_stack() {
  log "Instalando stack de contenedores con Podman"
  sudo dnf install -y podman podman-compose buildah skopeo podman-docker
}

setup_postgres_local() {
  log "Instalando PostgreSQL local"
  sudo dnf install -y postgresql postgresql-server postgresql-contrib libpq-devel

  if [[ ! -f /var/lib/pgsql/data/PG_VERSION ]]; then
    log "Inicializando cluster local de PostgreSQL"
    sudo postgresql-setup --initdb
  else
    log "PostgreSQL ya estaba inicializado"
  fi

  sudo systemctl enable --now postgresql
}

setup_zsh_shell() {
  log "Instalando zsh"
  sudo dnf install -y zsh

  if [[ "${MAKE_ZSH_DEFAULT}" -eq 1 ]]; then
    local zsh_path
    zsh_path="$(command -v zsh)"
    if [[ -n "${zsh_path}" && "${SHELL}" != "${zsh_path}" ]]; then
      log "Cambiando shell por defecto a zsh"
      chsh -s "${zsh_path}"
    fi
  fi
}

setup_shell_aliases() {
  local alias_block
  alias_block=$(cat <<'EOF'
# >>> fedora-webdev-bootstrap aliases >>>
alias ll='ls -lah'
alias la='ls -A'
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gco='git checkout'
alias gb='git branch'
alias k='kubectl'
alias cdx='codex'
# <<< fedora-webdev-bootstrap aliases <<<
EOF
)

  log "Agregando aliases utiles al shell"
  append_block_if_missing "${USER_HOME}/.bashrc" "# >>> fedora-webdev-bootstrap aliases >>>" "${alias_block}"
  append_block_if_missing "${USER_HOME}/.zshrc" "# >>> fedora-webdev-bootstrap aliases >>>" "${alias_block}"
}

log "Actualizando Fedora"
sudo dnf -y upgrade --refresh

install_vscode_repo

log "Instalando paquetes base para desarrollo web"
sudo dnf install -y \
  bash-completion \
  ca-certificates \
  code \
  curl \
  fd-find \
  fzf \
  gcc \
  gcc-c++ \
  gh \
  git \
  git-delta \
  gnupg2 \
  jq \
  make \
  nodejs \
  npm \
  openssh-clients \
  openssl \
  openssl-devel \
  patch \
  pipx \
  pinentry-gnome3 \
  python-unversioned-command \
  python3 \
  python3-devel \
  python3-pip \
  python3-virtualenv \
  readline-devel \
  ripgrep \
  rsync \
  shellcheck \
  sqlite \
  sqlite-devel \
  tmux \
  unzip \
  util-linux-user \
  wget \
  xz \
  xz-devel \
  zlib-devel \
  bzip2 \
  bzip2-devel \
  libffi-devel

configure_npm_prefix

log "Habilitando gestores JS comunes"
corepack enable || true
corepack prepare pnpm@latest --activate || true
corepack prepare yarn@stable --activate || true

log "Instalando herramientas globales de Node"
npm install -g @openai/codex npm-check-updates typescript

log "Asegurando pipx en PATH"
pipx ensurepath >/dev/null || true

log "Configurando Git"
configure_git_if_requested

if [[ "${SETUP_SSH}" -eq 1 ]]; then
  setup_ssh_key
fi

if [[ "${SETUP_GPG}" -eq 1 ]]; then
  setup_gpg_key
fi

if [[ "${SETUP_GH}" -eq 1 ]]; then
  setup_github_cli_auth
fi

if [[ "${SETUP_PODMAN}" -eq 1 ]]; then
  setup_podman_stack
fi

if [[ "${SETUP_POSTGRES}" -eq 1 ]]; then
  setup_postgres_local
fi

if [[ "${SETUP_ZSH}" -eq 1 ]]; then
  setup_zsh_shell
fi

if [[ "${SETUP_ALIASES}" -eq 1 ]]; then
  setup_shell_aliases
fi

install_vscode_extensions

log "Resumen"
if [[ "${PROFILE_MINIMAL}" -eq 1 ]]; then
  printf 'profile: %s\n' "minimal"
elif [[ "${PROFILE_FULL}" -eq 1 ]]; then
  printf 'profile: %s\n' "full"
else
  printf 'profile: %s\n' "custom"
fi
printf 'git: %s\n' "$(git --version)"
printf 'python: %s\n' "$(python --version)"
printf 'pip: %s\n' "$(python -m pip --version)"
printf 'node: %s\n' "$(node --version)"
printf 'npm: %s\n' "$(npm --version)"
printf 'pnpm: %s\n' "$(pnpm --version 2>/dev/null || echo 'no disponible')"
printf 'code: %s\n' "$(code --version | head -n 1 2>/dev/null || echo 'no disponible')"
printf 'codex: %s\n' "$(codex --version 2>/dev/null || echo 'no disponible')"
if [[ "${SETUP_SSH}" -eq 1 ]]; then
  printf 'ssh pubkey: %s\n' "${SSH_KEY_PATH}.pub"
fi
if [[ -n "${GENERATED_GPG_KEY}" ]]; then
  printf 'gpg fingerprint: %s\n' "${GENERATED_GPG_KEY}"
  printf 'gpg public key: %s\n' "${USER_HOME}/.gnupg/github-signing-key.asc"
fi
if [[ "${SETUP_GH}" -eq 1 ]]; then
  printf 'gh protocol: %s\n' "${GH_PROTOCOL}"
fi
if [[ "${SETUP_PODMAN}" -eq 1 ]]; then
  printf 'podman: %s\n' "$(podman --version 2>/dev/null || echo 'no disponible')"
fi
if [[ "${SETUP_POSTGRES}" -eq 1 ]]; then
  printf 'psql: %s\n' "$(psql --version 2>/dev/null || echo 'no disponible')"
fi
if [[ "${SETUP_ZSH}" -eq 1 ]]; then
  printf 'zsh: %s\n' "$(zsh --version 2>/dev/null || echo 'no disponible')"
fi

cat <<'EOF'

Siguiente paso:
  1. Cierra y vuelve a abrir la terminal para refrescar PATH.
  2. Autentica Codex con: codex --login
     o exporta OPENAI_API_KEY en tu shell.
  3. Sube tu clave SSH publica a GitHub desde ~/.ssh/*.pub
  4. Si generaste GPG, sube ~/.gnupg/github-signing-key.asc a GitHub como signing key.
  5. Si activaste zsh por defecto, vuelve a iniciar sesion.
EOF
