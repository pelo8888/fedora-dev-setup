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

setup_k8s_tools() {
  log "Instalando herramientas de Kubernetes"
  install_first_available_package "kubectl" kubernetes-client kubectl || true
  install_first_available_package "helm" helm || true
  install_first_available_package "k9s" k9s || true
}

setup_tmux_plugins() {
  local plugin_root="${USER_HOME}/.tmux/plugins/tpm"

  log "Configurando plugins de tmux"
  if [[ -d "${plugin_root}/.git" ]]; then
    git -C "${plugin_root}" pull --ff-only >/dev/null 2>&1 || true
  else
    mkdir -p "${USER_HOME}/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "${plugin_root}" >/dev/null 2>&1 || true
  fi

  if [[ -x "${plugin_root}/bin/install_plugins" ]]; then
    TMUX_PLUGIN_MANAGER_PATH="${USER_HOME}/.tmux/plugins" "${plugin_root}/bin/install_plugins" >/dev/null 2>&1 || true
  fi
}

write_managed_configs() {
  log "Escribiendo configuracion gestionada para zsh y tmux"
  mkdir -p "${CONFIG_ROOT}"
  local nvim_root="${XDG_CONFIG_HOME:-${USER_HOME}/.config}/nvim"
  local nvim_lua_root="${nvim_root}/lua/fedora"
  mkdir -p "${nvim_lua_root}"

  render_template "${SCRIPT_DIR}/templates/fedora-dev-setup/zprofile.zsh" "${CONFIG_ROOT}/zprofile.zsh"
  render_template "${SCRIPT_DIR}/templates/fedora-dev-setup/zshrc.zsh" "${CONFIG_ROOT}/zshrc.zsh"
  render_template "${SCRIPT_DIR}/templates/fedora-dev-setup/starship.toml" "${CONFIG_ROOT}/starship.toml"
  render_template "${SCRIPT_DIR}/templates/fedora-dev-setup/tmux.conf" "${CONFIG_ROOT}/tmux.conf"
  render_template "${SCRIPT_DIR}/templates/nvim/init.lua" "${nvim_root}/init.lua"
  render_template "${SCRIPT_DIR}/templates/nvim/lua/fedora/init.lua" "${nvim_lua_root}/init.lua"
  render_template "${SCRIPT_DIR}/templates/nvim/lua/fedora/options.lua" "${nvim_lua_root}/options.lua"
  render_template "${SCRIPT_DIR}/templates/nvim/lua/fedora/keymaps.lua" "${nvim_lua_root}/keymaps.lua"
  render_template "${SCRIPT_DIR}/templates/nvim/lua/fedora/autocmds.lua" "${nvim_lua_root}/autocmds.lua"
  render_template "${SCRIPT_DIR}/templates/nvim/lua/fedora/lazy.lua" "${nvim_lua_root}/lazy.lua"
  render_template "${SCRIPT_DIR}/templates/nvim/lua/fedora/profile.lua" "${nvim_lua_root}/profile.lua"

  upsert_block \
    "${USER_HOME}/.zprofile" \
    "# >>> fedora-dev-setup zprofile >>>" \
    "# <<< fedora-dev-setup zprofile <<<" \
    "[[ -r \"${CONFIG_ROOT}/zprofile.zsh\" ]] && source \"${CONFIG_ROOT}/zprofile.zsh\""

  upsert_block \
    "${USER_HOME}/.zshrc" \
    "# >>> fedora-dev-setup zshrc >>>" \
    "# <<< fedora-dev-setup zshrc <<<" \
    "[[ -r \"${CONFIG_ROOT}/zshrc.zsh\" ]] && source \"${CONFIG_ROOT}/zshrc.zsh\""

  upsert_block \
    "${USER_HOME}/.tmux.conf" \
    "# >>> fedora-dev-setup tmux >>>" \
    "# <<< fedora-dev-setup tmux <<<" \
    "source-file ${CONFIG_ROOT}/tmux.conf"
}

setup_zsh_shell() {
  if [[ "${MAKE_ZSH_DEFAULT}" -ne 1 ]]; then
    return
  fi

  local zsh_path
  zsh_path="$(command -v zsh)"

  if [[ -n "${zsh_path}" && "${SHELL}" != "${zsh_path}" ]]; then
    log "Cambiando shell por defecto a zsh"
    chsh -s "${zsh_path}"
  fi
}

refresh_terminal_caches() {
  if command -v tldr >/dev/null 2>&1; then
    log "Actualizando cache de tealdeer"
    tldr --update >/dev/null || true
  fi
}

print_summary() {
  log "Resumen"
  printf 'shell actual: %s\n' "${SHELL}"
  printf 'git: %s\n' "$(git --version)"
  printf 'zsh: %s\n' "$(zsh --version 2>/dev/null || echo 'no disponible')"
  printf 'tmux: %s\n' "$(tmux -V 2>/dev/null || echo 'no disponible')"
  printf 'nvim: %s\n' "$(nvim --version | head -n 1 2>/dev/null || echo 'no disponible')"
  printf 'lazygit: %s\n' "$(lazygit --version 2>/dev/null | head -n 1 || echo 'no disponible')"
  printf 'node: %s\n' "$(node --version 2>/dev/null || echo 'no disponible')"
  printf 'npm: %s\n' "$(npm --version 2>/dev/null || echo 'no disponible')"
  printf 'pnpm: %s\n' "$(pnpm --version 2>/dev/null || echo 'no disponible')"
  printf 'codex: %s\n' "$(codex --version 2>/dev/null || echo 'no disponible')"
  printf 'eza: %s\n' "$(eza --version 2>/dev/null | head -n 1 || echo 'no disponible')"
  printf 'bat: %s\n' "$(bat --version 2>/dev/null || echo 'no disponible')"
  printf 'zoxide: %s\n' "$(zoxide --version 2>/dev/null || echo 'no disponible')"
  printf 'starship: %s\n' "$(starship --version 2>/dev/null || echo 'no disponible')"
  printf 'config root: %s\n' "${CONFIG_ROOT}"
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
  if [[ "${SETUP_K8S}" -eq 1 ]]; then
    printf 'kubectl: %s\n' "$(kubectl version --client --output=yaml 2>/dev/null | awk '/gitVersion:/ {print $2; exit}' || echo 'no disponible')"
    printf 'helm: %s\n' "$(helm version --short 2>/dev/null || echo 'no disponible')"
    printf 'k9s: %s\n' "$(k9s version -s 2>/dev/null || echo 'no disponible')"
  fi
  if [[ "${INSTALL_VSCODE}" -eq 1 ]]; then
    printf 'code: %s\n' "$(code --version | head -n 1 2>/dev/null || echo 'no disponible')"
  fi

  cat <<'EOF'

Siguiente paso:
  1. Cierra y vuelve a abrir la terminal.
  2. Si activaste zsh por defecto, vuelve a iniciar sesion.
  3. Autentica Codex con: codex --login
     o exporta OPENAI_API_KEY en tu shell.
  4. Sube tu clave SSH publica a GitHub desde ~/.ssh/*.pub si la generaste.
  5. Si generaste GPG, sube ~/.gnupg/github-signing-key.asc a GitHub como signing key.
EOF
}
