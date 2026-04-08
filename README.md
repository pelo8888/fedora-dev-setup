# Fedora Dev Setup

Scripts to prepare a fresh Fedora installation for web development and day-to-day GitHub work.

## Files

- `fedora-dev-setup.sh`: `bash` entrypoint
- `fedora-dev-setup-zsh.zsh`: `zsh` entrypoint

## Requirements

- Fedora Workstation or a Fedora base install
- a regular user with `sudo`
- an internet connection

Both scripts detect the distribution by reading `/etc/os-release` and abort if Fedora is not found.

## Entrypoints

Both files now have feature parity:

- they support the `all`, `bootstrap`, `devtools`, `shell`, `services`, and `doctor` stages
- they share the same modular logic under `lib/fedora-dev-setup/`
- they use the same versioned templates under `templates/`
- they prepare a terminal-focused environment with `zsh`, `tmux`, `git`, `neovim`, and optional extras

The main difference is the shell used to run the entrypoint:

- `fedora-dev-setup.sh`: meant to run from `bash`
- `fedora-dev-setup-zsh.zsh`: meant to run from `zsh`

## Quick Starts

Base installation:

```bash
./fedora-dev-setup.sh --minimal
```

Full installation:

```bash
./fedora-dev-setup.sh \
  --full \
  --git-name "Your Name" \
  --git-email "your@email.com" \
  --ssh-passphrase "your-ssh-passphrase" \
  --gpg-passphrase "your-gpg-passphrase"
```

Full installation from `bash`:

```bash
./fedora-dev-setup.sh \
  all \
  --full \
  --git-name "Your Name" \
  --git-email "your@email.com" \
  --ssh-passphrase "your-ssh-passphrase" \
  --gpg-passphrase "your-gpg-passphrase"
```

Full installation from `zsh`:

```bash
./fedora-dev-setup-zsh.zsh \
  all \
  --full \
  --git-name "Your Name" \
  --git-email "your@email.com" \
  --ssh-passphrase "your-ssh-passphrase" \
  --gpg-passphrase "your-gpg-passphrase"
```

## What They Include

Always installed:

- system update with `dnf`
- the official Visual Studio Code repository
- `git`, `gh`, `python`, `pipx`, `node`, `npm`, compilers, and terminal utilities
- `corepack`, `pnpm`, `yarn`
- `@openai/codex`, `npm-check-updates`, `typescript`
- base VS Code extensions

Both entrypoints also:

- configure `zsh` with history, completions, `fzf`, aliases, and useful functions
- write managed configuration under `~/.config/fedora-dev-setup/`
- configure `tmux`, `git-delta`, `starship`, and hooks for `zoxide`, `direnv`, and `atuin` when available
- can install TPM and `tmux` plugins such as `tmux-resurrect` and `tmux-continuum`
- install and expose `lazygit` when the package is available on Fedora
- create a modular `neovim` configuration under `lua/fedora/`, with an optional opinionated variant using `lazy.nvim`, `telescope`, `treesitter`, `gitsigns`, `which-key`, and `lualine`
- can install local `podman` and `postgresql` with optional flags or with `--full`
- can install Kubernetes tools with `--setup-k8s`
- try to install terminal extras such as `eza`, `bat`, `btop`, `htop`, `tealdeer`, and `zoxide`

Optionally configured:

- SSH for GitHub
- GPG for commit signing
- authentication with `gh`
- Podman with `docker` compatibility
- local PostgreSQL
- `zsh` as the default shell
- useful shell aliases

## Custom Usage

```bash
./fedora-dev-setup.sh \
  all \
  --git-name "Your Name" \
  --git-email "your@email.com" \
  --setup-ssh \
  --ssh-passphrase "your-ssh-passphrase" \
  --setup-gpg \
  --gpg-passphrase "your-gpg-passphrase" \
  --sign-commits \
  --setup-gh \
  --gh-protocol ssh \
  --setup-podman \
  --setup-postgres \
  --setup-tmux-plugins \
  --setup-nvim-extras \
  --setup-k8s \
  --make-zsh-default \
  --skip-vscode
```

Full help:

```bash
./fedora-dev-setup.sh --help
```

`zsh` variant help:

```bash
./fedora-dev-setup-zsh.zsh --help
```

Custom example for the `zsh` variant:

```bash
./fedora-dev-setup-zsh.zsh \
  all \
  --git-name "Your Name" \
  --git-email "your@email.com" \
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

Stages available in both entrypoints:

- `all`: runs the full workflow
- `bootstrap`: updates Fedora and installs repositories and base packages
- `devtools`: configures npm, corepack, global Node tools, Git, SSH, GPG, `gh`, and extensions
- `shell`: writes `zsh`, `tmux`, and `neovim` configuration, and can optionally change the default shell
- `services`: installs `podman`, `postgresql`, and Kubernetes tooling depending on the flags used
- `doctor`: installs nothing; checks whether the system already satisfies the expected prerequisites and whether expected files/configs exist

Stage preconditions:

- `devtools` expects `git`, `npm`, `pipx`, and `python3` to already exist
- `shell` expects `zsh`, `tmux`, and `nvim`
- `services` validates `sudo`, `dnf`, and `systemctl`
- if you run an isolated stage and something is missing, the script will tell you to use `bootstrap` or `all`

Examples by stage:

```bash
./fedora-dev-setup.sh bootstrap
./fedora-dev-setup.sh doctor --setup-gh --setup-podman --setup-tmux-plugins
./fedora-dev-setup-zsh.zsh bootstrap
./fedora-dev-setup-zsh.zsh devtools --setup-gh --setup-ssh --git-email "your@email.com"
./fedora-dev-setup-zsh.zsh shell --setup-tmux-plugins --setup-nvim-extras --make-zsh-default
./fedora-dev-setup-zsh.zsh services --setup-podman --setup-postgres --setup-k8s
./fedora-dev-setup-zsh.zsh doctor --setup-gh --setup-podman --setup-tmux-plugins
```

## After Running

1. Reopen the terminal.
2. If you enabled `zsh`, log in again.
3. Upload your public SSH key to GitHub.
4. If you generated GPG, upload the ASCII-armored public key to GitHub.
5. Run `codex --login`.

## Notes

- `gh auth login` runs interactively.
- `--full` enables most useful extras for a primary development machine.
- in both `.sh` and `.zsh`, `--full` also enables `tmux` plugins and an opinionated `neovim` setup
- generated `neovim` configuration no longer lives in a single `init.lua`; it is split into modules for easier maintenance
- `zsh`, `tmux`, `starship`, and `neovim` configuration now come from versioned templates under `templates/`
- installer logic is now split into modules under `lib/fedora-dev-setup/`
- both entrypoints accept subcommands so you can run only one setup stage
- isolated stages validate minimal preconditions before they run
- `doctor` lets you audit the machine state without installing anything
- `--setup-k8s` is optional so Kubernetes tooling is not installed on machines that do not need it
- if you do not want to touch the shell, local database, or containers, use `--minimal`
