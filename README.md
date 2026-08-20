# dotfiles

Personal macOS dev environment. The repo is the single source of truth: configs
in `$HOME` are **symlinked** back into this repo, so editing e.g. `~/.zshrc`
edits the tracked copy directly.

## What's in here

| Path | Symlinked to | Purpose |
|------|--------------|---------|
| `zsh/.zshrc`, `zsh/.p10k.zsh` | `~/.zshrc`, `~/.p10k.zsh` | zsh + powerlevel10k |
| `bash/.bashrc` | `~/.bashrc` | bash fallback |
| `git/.gitconfig` | `~/.gitconfig` | git config (identity split + credentials) |
| `git/.gitconfig-personal` | `~/.gitconfig-personal` | personal identity (included for `~/dotfiles/`) |
| `tmux/.tmux.conf` | `~/.tmux.conf` | tmux config |
| `tmux/.tmux/*.sh` | `~/.tmux/*.sh` | tmux project launcher scripts |
| `tmux/.tmux/projects.yaml` | `~/.tmux/projects.yaml` | **placeholder** project defs (committed) |
| `tmux/.tmux/projects.local.yaml` | `~/.tmux/projects.yaml` | **real** project defs (gitignored, local only) |
| `config/.config/*` | `~/.config/*` | btop, kitty, git, gh |
| `nvim/` | `~/.config/nvim` | Neovim (kickstart-modular based) |
| `Brewfile` | — | brew formulae/casks/vscode/npm |
| `secrets.example` | — | template for `~/.secrets` (names only) |

## New machine setup

```sh
# 1. Install Homebrew if missing:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Clone and install:
git clone https://github.com/AtsuiOcha/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` is idempotent. It:

1. Runs `brew bundle` from the `Brewfile`.
2. Symlinks every config into `$HOME`, backing up any pre-existing real file to
   `<file>.bak` first.
3. Links `~/.tmux/projects.yaml` to `projects.local.yaml` if present, else the
   committed placeholder.
4. Clones TPM (tmux plugin manager).
5. Creates `~/.secrets` from `secrets.example` (chmod 600) if it doesn't exist.

### Manual steps after install

1. **Secrets** — edit `~/.secrets` and fill in real values, then `exec zsh`.
   `~/.secrets` is sourced by `.zshrc` and is **never** committed. Variables:
   - `VAST_ANTHROPIC_DEV_BASE_URL`, `VAST_ANTHROPIC_DEV_TOKEN` (used by Neovim parrot.nvim)
   - `VAST_ANTHROPIC_PRD_BASE_URL`, `VAST_ANTHROPIC_PRD_TOKEN`
   - `UV_INDEX_VAST_PYPY_USERNAME`, `UV_INDEX_VAST_PYPY_PASSWORD` (uv index auth)
2. **tmux plugins** — open tmux, press `prefix + I`.
3. **Neovim** — launch `nvim`, let lazy.nvim + mason finish installing.
4. **Real tmux projects** — recreate `tmux/.tmux/projects.local.yaml` with your
   actual project paths (see `projects.yaml` for the format), then re-run
   `./install.sh` to point `~/.tmux/projects.yaml` at it.

## Git identity & credentials

- **Default (global) identity** is Vast: `oskar@vastspace.com`.
- Anything under `~/dotfiles/` uses the **personal** identity
  (`oskadez@gmail.com`) via an `includeIf "gitdir:~/dotfiles/"` rule pointing at
  `~/.gitconfig-personal`.
- **Credentials** use [Git Credential Manager](https://github.com/git-ecosystem/git-credential-manager)
  (cask `git-credential-manager`). The first HTTPS `git push`/`clone` per host
  opens a browser for OAuth; the token is cached in the macOS Keychain and
  routed per host (github.com = personal, code.vastspace.com = Vast). `lazygit`
  inherits this automatically.

## Leaving Vast — offboarding checklist

Do this **before** losing access, on your personal accounts:

1. Enable **2FA** on your personal GitHub account (github.com).
2. Confirm you can still push to this repo with the personal identity/credentials.
3. Revoke the **Git Credential Manager OAuth grant** for any Vast host from the
   browser (the provider's "authorized apps" settings).
4. Purge cached credentials from the Keychain:
   ```sh
   printf 'protocol=https\nhost=code.vastspace.com\n\n' | git credential-manager erase
   printf 'protocol=https\nhost=github.com\n\n'         | git credential-manager erase
   ```
5. Delete any Vast tokens from `~/.secrets` (or recreate it from
   `secrets.example`).
6. Update the global git identity if you no longer want the Vast email as
   default:
   ```sh
   git config --global user.email "oskadez@gmail.com"
   ```
