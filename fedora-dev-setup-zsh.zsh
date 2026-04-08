#!/usr/bin/env zsh

emulate -L zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

if (( EUID == 0 )); then
  echo "Ejecuta este script como tu usuario normal, no como root."
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "Este script necesita sudo."
  exit 1
fi

USER_HOME="${HOME}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="${0:t}"
CONFIG_ROOT="${XDG_CONFIG_HOME:-${USER_HOME}/.config}/fedora-dev-setup"
STAGE="all"
INTERACTIVE=0
SETUP_SSH=0
SETUP_GPG=0
SETUP_GH=0
SETUP_PODMAN=0
SETUP_POSTGRES=0
SETUP_K8S=0
SETUP_TMUX_PLUGINS=0
SETUP_NVIM_EXTRAS=0
MAKE_ZSH_DEFAULT=0
SIGN_COMMITS=0
INSTALL_VSCODE=1
INSTALL_VSCODE_EXTENSIONS=1
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
  ./${SCRIPT_NAME} [all|bootstrap|devtools|shell|services|doctor] [opciones]

Que hace este script:
  - Actualiza Fedora con dnf.
  - Instala zsh y lo deja listo como shell de trabajo.
  - Instala herramientas de terminal para desarrollo:
    git, gh, node, npm, pipx, neovim, tmux, ripgrep, fd, fzf, jq, delta y compiladores.
  - Intenta instalar extras de terminal si estan disponibles:
    eza, bat, zoxide, direnv, atuin, starship, btop, htop y tealdeer.
  - Configura npm global en ~/.local/bin.
  - Habilita corepack y prepara pnpm y yarn.
  - Instala herramientas globales de Node:
    @openai/codex, npm-check-updates y typescript.
  - Escribe configuracion gestionada para zsh, tmux, starship y Git.
  - Puede dejar listo neovim con una configuracion base orientada a terminal.
  - Puede instalar plugins de tmux y un setup mas completo de neovim.
  - Opcionalmente configura Git, SSH, GPG y GitHub CLI.
  - Opcionalmente instala Podman, PostgreSQL local y herramientas de Kubernetes.
  - Opcionalmente instala Visual Studio Code y extensiones base.

Opciones:
  all|bootstrap|devtools|shell|services|doctor
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
  --setup-k8s
  --setup-tmux-plugins
  --setup-nvim-extras
  --sign-commits
  --make-zsh-default
  --skip-vscode
  --skip-vscode-extensions
  --interactive
  --help

Tambien soporta estas variables de entorno:
  GIT_NAME, GIT_EMAIL, SSH_EMAIL, SSH_KEY_PATH, SSH_PASSPHRASE,
  GPG_NAME, GPG_EMAIL, GPG_PASSPHRASE, GH_PROTOCOL

Notas:
  - Si no indicas subcomando, usa all.
  - bootstrap instala repos y paquetes base.
  - devtools configura npm, corepack, herramientas globales, Git, SSH, GPG, gh y extensiones.
  - shell escribe la configuracion de zsh, tmux y neovim, y puede cambiar el shell por defecto.
  - services instala o configura Podman, PostgreSQL y herramientas de Kubernetes.
  - doctor no instala nada: inspecciona si el sistema ya cumple lo esperado.
  - --interactive pregunta por cada etapa y espera una respuesta y/n antes de ejecutarla.
  - Las etapas fuera de all validan precondiciones basicas y abortan si faltan binarios esperados.
  - --full activa SSH, GPG, firma de commits, GitHub CLI, Podman, PostgreSQL,
    neovim opinionado, plugins de tmux y deja zsh como shell por defecto.
  - --setup-k8s es opt-in y agrega kubectl, helm y k9s si hay paquetes disponibles.
  - La configuracion gestionada queda en ~/.config/fedora-dev-setup/.
  - --skip-vscode evita agregar el repo de VS Code e instalar el paquete code.
  - --skip-vscode-extensions solo evita la instalacion de extensiones.
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

is_valid_stage() {
  case "$1" in
    all|bootstrap|devtools|shell|services|doctor)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

if [[ $# -gt 0 && "$1" != --* ]]; then
  if is_valid_stage "$1"; then
    STAGE="$1"
    shift
  else
    echo "Subcomando no reconocido: $1"
    usage
    exit 1
  fi
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --full)
      SETUP_SSH=1
      SETUP_GPG=1
      SETUP_GH=1
      SETUP_PODMAN=1
      SETUP_POSTGRES=1
      SETUP_TMUX_PLUGINS=1
      SETUP_NVIM_EXTRAS=1
      SIGN_COMMITS=1
      MAKE_ZSH_DEFAULT=1
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
    --setup-k8s)
      SETUP_K8S=1
      shift
      ;;
    --setup-tmux-plugins)
      SETUP_TMUX_PLUGINS=1
      shift
      ;;
    --setup-nvim-extras)
      SETUP_NVIM_EXTRAS=1
      shift
      ;;
    --sign-commits)
      SIGN_COMMITS=1
      shift
      ;;
    --make-zsh-default)
      MAKE_ZSH_DEFAULT=1
      shift
      ;;
    --skip-vscode)
      INSTALL_VSCODE=0
      INSTALL_VSCODE_EXTENSIONS=0
      shift
      ;;
    --skip-vscode-extensions)
      INSTALL_VSCODE_EXTENSIONS=0
      shift
      ;;
    --interactive)
      INTERACTIVE=1
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

if [[ "${GH_PROTOCOL}" != "ssh" && "${GH_PROTOCOL}" != "https" ]]; then
  echo "Valor invalido para --gh-protocol: ${GH_PROTOCOL}. Usa ssh o https."
  exit 1
fi

source_lib() {
  local lib_path="$1"

  if [[ ! -r "${lib_path}" ]]; then
    echo "Falta el modulo requerido: ${lib_path}"
    exit 1
  fi

  # shellcheck disable=SC1090
  . "${lib_path}"
}

source_lib "${SCRIPT_DIR}/lib/fedora-dev-setup/common.zsh"
source_lib "${SCRIPT_DIR}/lib/fedora-dev-setup/packages.zsh"
source_lib "${SCRIPT_DIR}/lib/fedora-dev-setup/auth.zsh"
source_lib "${SCRIPT_DIR}/lib/fedora-dev-setup/workstation.zsh"

run_bootstrap_stage() {
  log "Etapa bootstrap"
  log "Actualizando Fedora"
  sudo dnf -y upgrade --refresh

  install_vscode_repo
  install_mandatory_packages
  install_optional_packages
}

run_devtools_stage() {
  log "Etapa devtools"
  require_commands "devtools" git npm pipx python3

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
  configure_terminal_git

  if [[ "${SETUP_SSH}" -eq 1 ]]; then
    setup_ssh_key
  fi

  if [[ "${SETUP_GPG}" -eq 1 ]]; then
    setup_gpg_key
  fi

  if [[ "${SETUP_GH}" -eq 1 ]]; then
    setup_github_cli_auth
  fi

  install_vscode_extensions
}

run_shell_stage() {
  log "Etapa shell"
  require_commands "shell" zsh tmux nvim

  write_managed_configs
  setup_zsh_shell

  if [[ "${SETUP_TMUX_PLUGINS}" -eq 1 ]]; then
    setup_tmux_plugins
  fi

  refresh_terminal_caches
}

run_services_stage() {
  log "Etapa services"
  require_commands "services" sudo dnf systemctl
  if [[ "${SETUP_K8S}" -eq 1 ]]; then
    require_commands "services" rpm
  fi

  if [[ "${SETUP_PODMAN}" -eq 1 ]]; then
    setup_podman_stack
  fi

  if [[ "${SETUP_POSTGRES}" -eq 1 ]]; then
    setup_postgres_local
  fi

  if [[ "${SETUP_K8S}" -eq 1 ]]; then
    setup_k8s_tools
  fi
}

run_doctor_stage() {
  local failures=0
  local nvim_root="${XDG_CONFIG_HOME:-${USER_HOME}/.config}/nvim"

  log "Etapa doctor"
  echo "No se realizaran cambios. Solo se inspecciona el estado actual."
  printf 'stage: %s\n' "${STAGE}"
  printf 'config root: %s\n' "${CONFIG_ROOT}"
  printf 'shell actual: %s\n' "${SHELL}"

  echo
  echo "Precondiciones por etapa"
  doctor_check_commands "bootstrap" sudo dnf rpm || ((failures += 1))
  doctor_check_commands "devtools" git npm pipx python3 || ((failures += 1))
  doctor_check_commands "shell" zsh tmux nvim || ((failures += 1))
  doctor_check_commands "services" sudo dnf systemctl || ((failures += 1))

  echo
  echo "Configuracion gestionada"
  doctor_check_file "zprofile gestionado" "${CONFIG_ROOT}/zprofile.zsh" || ((failures += 1))
  doctor_check_file "zshrc gestionado" "${CONFIG_ROOT}/zshrc.zsh" || ((failures += 1))
  doctor_check_file "tmux gestionado" "${CONFIG_ROOT}/tmux.conf" || ((failures += 1))
  doctor_check_file "starship gestionado" "${CONFIG_ROOT}/starship.toml" || ((failures += 1))
  doctor_check_file "nvim init" "${nvim_root}/init.lua" || ((failures += 1))
  doctor_check_file "nvim profile" "${nvim_root}/lua/fedora/profile.lua" || ((failures += 1))

  echo
  echo "Extras segun flags"
  if [[ "${SETUP_SSH}" -eq 1 ]]; then
    doctor_check_file "ssh public key" "${SSH_KEY_PATH}.pub" || ((failures += 1))
  fi
  if [[ "${SETUP_GPG}" -eq 1 ]]; then
    doctor_check_file "gpg public key" "${USER_HOME}/.gnupg/github-signing-key.asc" || ((failures += 1))
  fi
  if [[ "${SETUP_GH}" -eq 1 ]]; then
    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
      echo "[ok] gh auth"
    else
      echo "[missing] gh auth"
      ((failures += 1))
    fi
  fi
  if [[ "${SETUP_PODMAN}" -eq 1 ]]; then
    doctor_check_commands "podman" podman || ((failures += 1))
  fi
  if [[ "${SETUP_POSTGRES}" -eq 1 ]]; then
    doctor_check_commands "postgres" psql || ((failures += 1))
  fi
  if [[ "${SETUP_K8S}" -eq 1 ]]; then
    doctor_check_commands "k8s" kubectl helm k9s || ((failures += 1))
  fi
  if [[ "${SETUP_TMUX_PLUGINS}" -eq 1 ]]; then
    doctor_check_file "tmux plugin manager" "${USER_HOME}/.tmux/plugins/tpm/tpm" || ((failures += 1))
  fi
  if [[ "${SETUP_NVIM_EXTRAS}" -eq 1 ]]; then
    doctor_check_file "nvim lazy config" "${nvim_root}/lua/fedora/lazy.lua" || ((failures += 1))
  fi

  echo
  if (( failures == 0 )); then
    echo "Doctor: OK"
    return 0
  fi

  echo "Doctor: faltan ${failures} comprobaciones"
  return 1
}

require_fedora

case "${STAGE}" in
  all)
    run_stage_with_confirmation "bootstrap" run_bootstrap_stage
    run_stage_with_confirmation "devtools" run_devtools_stage
    run_stage_with_confirmation "shell" run_shell_stage
    run_stage_with_confirmation "services" run_services_stage
    ;;
  bootstrap)
    run_stage_with_confirmation "bootstrap" run_bootstrap_stage
    ;;
  devtools)
    run_stage_with_confirmation "devtools" run_devtools_stage
    ;;
  shell)
    run_stage_with_confirmation "shell" run_shell_stage
    ;;
  services)
    run_stage_with_confirmation "services" run_services_stage
    ;;
  doctor)
    run_stage_with_confirmation "doctor" run_doctor_stage
    exit $?
    ;;
esac

print_summary
