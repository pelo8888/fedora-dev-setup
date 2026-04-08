configure_git_if_requested() {
  if [[ -n "${GIT_NAME:-}" ]]; then
    git config --global user.name "${GIT_NAME}"
  fi

  if [[ -n "${GIT_EMAIL:-}" ]]; then
    git config --global user.email "${GIT_EMAIL}"
  fi
}

configure_terminal_git() {
  log "Aplicando configuracion de Git orientada a terminal"
  git config --global init.defaultBranch main
  git config --global fetch.prune true
  git config --global pull.rebase false
  git config --global merge.conflictStyle zdiff3
  git config --global rerere.enabled true
  git config --global core.editor nvim
  git config --global diff.colorMoved default
  git config --global alias.st "status -sb"
  git config --global alias.lg "log --graph --oneline --decorate --all"
  git config --global alias.last "log -1 HEAD --stat"

  if command -v delta >/dev/null 2>&1; then
    git config --global core.pager delta
    git config --global interactive.diffFilter "delta --color-only"
    git config --global delta.navigate true
    git config --global delta.line-numbers true
    git config --global delta.side-by-side true
  fi
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

  upsert_block \
    "${USER_HOME}/.ssh/config" \
    "# >>> fedora-dev-setup github ssh >>>" \
    "# <<< fedora-dev-setup github ssh <<<" \
    "Host github.com
  HostName github.com
  User git
  IdentityFile ${SSH_KEY_PATH}
  IdentitiesOnly yes"
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
  mkdir -p "$(dirname "${pub_file}")"
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
