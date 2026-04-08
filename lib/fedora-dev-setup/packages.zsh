install_vscode_repo() {
  if [[ "${INSTALL_VSCODE}" -ne 1 ]]; then
    return
  fi

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
  export PATH="${USER_HOME}/.local/bin:${PATH}"
}

install_mandatory_packages() {
  local -a packages=(
    bash-completion
    bzip2
    bzip2-devel
    ca-certificates
    curl
    fd-find
    fzf
    gcc
    gcc-c++
    gh
    git
    git-delta
    gnupg2
    jq
    libffi-devel
    make
    neovim
    nodejs
    npm
    openssh-clients
    openssl-devel
    patch
    pipx
    python3
    python3-devel
    python3-pip
    python3-virtualenv
    readline-devel
    ripgrep
    rsync
    shellcheck
    sqlite-devel
    tmux
    tree
    unzip
    util-linux-user
    wget
    xz
    xz-devel
    zlib-devel
    zsh
  )

  log "Instalando paquetes base para zsh y desarrollo"
  sudo dnf install -y "${packages[@]}"
}

install_optional_packages() {
  local -a packages=(
    atuin
    bat
    btop
    code
    direnv
    eza
    htop
    lazygit
    p7zip
    starship
    tealdeer
    wl-clipboard
    xclip
    zoxide
  )
  local -a unavailable=()
  local package

  log "Intentando instalar herramientas extra de terminal"
  for package in "${packages[@]}"; do
    if [[ "${package}" == "code" && "${INSTALL_VSCODE}" -ne 1 ]]; then
      continue
    fi

    if rpm -q "${package}" >/dev/null 2>&1; then
      continue
    fi

    if sudo dnf install -y "${package}"; then
      continue
    fi

    unavailable+=("${package}")
  done

  if (( ${#unavailable[@]} > 0 )); then
    log "No pude instalar estos extras opcionales: ${unavailable[*]}"
  fi
}

install_first_available_package() {
  local label="$1"
  shift

  local package
  for package in "$@"; do
    if rpm -q "${package}" >/dev/null 2>&1; then
      log "${label}: usando paquete ya instalado ${package}"
      return 0
    fi

    if sudo dnf info "${package}" >/dev/null 2>&1; then
      log "${label}: instalando ${package}"
      sudo dnf install -y "${package}"
      return 0
    fi
  done

  log "${label}: no encontre un paquete compatible en los repos configurados"
  return 1
}

install_vscode_extensions() {
  if [[ "${INSTALL_VSCODE_EXTENSIONS}" -ne 1 ]]; then
    return
  fi

  if ! command -v code >/dev/null 2>&1; then
    log "Saltando extensiones de VS Code porque 'code' no quedo disponible en PATH"
    return
  fi

  local -a extensions=(
    bradlc.vscode-tailwindcss
    dbaeumer.vscode-eslint
    eamodio.gitlens
    esbenp.prettier-vscode
    ms-python.python
    ms-python.vscode-pylance
    tamasfe.even-better-toml
  )
  local extension

  log "Instalando extensiones base de VS Code"
  for extension in "${extensions[@]}"; do
    code --install-extension "${extension}" --force >/dev/null || true
  done
}
