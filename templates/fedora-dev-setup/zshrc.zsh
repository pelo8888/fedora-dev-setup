setopt AUTO_CD
setopt APPEND_HISTORY
setopt COMPLETE_IN_WORD
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP
setopt NO_FLOW_CONTROL
setopt SHARE_HISTORY

HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

zmodload zsh/complist
autoload -Uz compinit colors
colors

mkdir -p "$HOME/.cache/zsh"
compinit -d "$HOME/.cache/zsh/zcompdump-$ZSH_VERSION"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

bindkey -e
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height=60% --layout=reverse --border'

if [[ -r /usr/share/fzf/shell/completion.zsh ]]; then
  source /usr/share/fzf/shell/completion.zsh
fi

if [[ -r /usr/share/fzf/shell/key-bindings.zsh ]]; then
  source /usr/share/fzf/shell/key-bindings.zsh
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

if command -v starship >/dev/null 2>&1; then
  export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/fedora-dev-setup/starship.toml"
  eval "$(starship init zsh)"
else
  PROMPT='%F{green}%n@%m%f %F{blue}%~%f %# '
fi

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -lah --group-directories-first --git --icons=auto'
  alias la='eza -a --group-directories-first --icons=auto'
  alias lt='eza --tree --level=2 --icons=auto'
else
  alias ll='ls -lah'
  alias la='ls -A'
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat --style=plain --paging=never'
  export MANPAGER='sh -c "col -bx | bat -l man -p"'
fi

alias c='clear'
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gca='git commit --amend'
alias gco='git checkout'
alias gd='git diff'
alias gl='git pull'
alias gp='git push'
alias lg='git lg'
alias d='docker'
alias dc='docker compose'
alias p='podman'
alias pc='podman compose'
alias lgit='lazygit'
alias psql-dev='psql postgres'
alias ta='tmux attach -t'
alias tls='tmux ls'
alias v='nvim'
alias cdx='codex'

mkcd() {
  mkdir -p -- "$1" && cd -- "$1"
}

extract() {
  local file="$1"

  case "$file" in
    *.tar.bz2) tar xjf "$file" ;;
    *.tar.gz) tar xzf "$file" ;;
    *.bz2) bunzip2 "$file" ;;
    *.gz) gunzip "$file" ;;
    *.tar) tar xf "$file" ;;
    *.tbz2) tar xjf "$file" ;;
    *.tgz) tar xzf "$file" ;;
    *.zip) unzip "$file" ;;
    *.xz) unxz "$file" ;;
    *.7z) 7z x "$file" ;;
    *) echo "No se como extraer: $file" ;;
  esac
}
