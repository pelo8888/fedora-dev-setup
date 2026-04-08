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

log() {
  printf '\n[%s] %s\n' "$(date '+%H:%M:%S')" "$*"
}

append_if_missing() {
  local file="$1"
  local line="$2"

  mkdir -p "$(dirname "${file}")"
  touch "${file}"
  if ! grep -Fqx "${line}" "${file}"; then
    printf '%s\n' "${line}" >>"${file}"
  fi
}

upsert_block() {
  local file="$1"
  local start_marker="$2"
  local end_marker="$3"
  local content="$4"
  local tmp_file

  mkdir -p "$(dirname "${file}")"
  touch "${file}"
  tmp_file="$(mktemp)"

  awk -v start="${start_marker}" -v end="${end_marker}" '
    $0 == start { skip = 1; next }
    $0 == end { skip = 0; next }
    !skip { print }
  ' "${file}" >"${tmp_file}"

  mv "${tmp_file}" "${file}"

  {
    printf '\n%s\n' "${start_marker}"
    printf '%s\n' "${content}"
    printf '%s\n' "${end_marker}"
  } >>"${file}"
}

render_template() {
  local template_path="$1"
  local output_path="$2"

  mkdir -p "$(dirname "${output_path}")"

  sed \
    -e "s|__CONFIG_ROOT__|${CONFIG_ROOT}|g" \
    -e "s|__NVIM_EXTRAS__|${SETUP_NVIM_EXTRAS}|g" \
    "${template_path}" >"${output_path}"
}

require_commands() {
  local context="$1"
  shift

  local -a missing=()
  local cmd

  for cmd in "$@"; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
      missing+=("${cmd}")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    echo "La etapa ${context} requiere estos comandos y no los encontro: ${missing[*]}"
    echo "Corre primero './${SCRIPT_NAME} bootstrap' o usa './${SCRIPT_NAME} all'."
    exit 1
  fi
}

doctor_check_commands() {
  local label="$1"
  shift

  local -a missing=()
  local cmd

  for cmd in "$@"; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
      missing+=("${cmd}")
    fi
  done

  if (( ${#missing[@]} == 0 )); then
    printf '[ok] %s\n' "${label}"
    return 0
  fi

  printf '[missing] %s: %s\n' "${label}" "${missing[*]}"
  return 1
}

doctor_check_file() {
  local label="$1"
  local path="$2"

  if [[ -e "${path}" ]]; then
    printf '[ok] %s: %s\n' "${label}" "${path}"
    return 0
  fi

  printf '[missing] %s: %s\n' "${label}" "${path}"
  return 1
}
