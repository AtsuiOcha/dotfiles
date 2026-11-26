# dotfiles

Personal macOS dev environment. The repo is the single source of truth: configs
in `$HOME` are **symlinked** back into this repo, so editing e.g. `~/.zshrc`
edits the tracked copy directly.

## What's in here

| Path | Symlinked to | Purpose |
|------|--------------|---------|
| `zsh/.zshrc`, `zsh/.p10k.zsh` | `~/.zshrc`, `~/.p10k.zsh` | zsh + powerlevel10k |
| `zsh/.zshenv` | `~/.zshenv` | env vars for all zsh invocations: sources `~/.secrets`, sets `XDG_CONFIG_HOME=~/.config`, adds `~/.local/bin` to `PATH` |
| `bash/.bashrc` | `~/.bashrc` | bash fallback |
| `git/.gitconfig` | `~/.gitconfig` | git config (identity split + credentials) |
| `git/.gitconfig-personal` | `~/.gitconfig-personal` | personal identity (included for `~/dotfiles/`) |
| `tmux/.tmux.conf` | `~/.tmux.conf` | tmux config |
| `tmux/.tmux/*.sh` | `~/.tmux/*.sh` | tmux project launcher scripts |
| `tmux/.tmux/projects.yaml` | `~/.tmux/projects.yaml` | **placeholder** project defs (committed) |
| `tmux/.tmux/projects.local.yaml` | `~/.tmux/projects.yaml` | **real** project defs (gitignored, local only) |
| `config/.config/*` | `~/.config/*` | btop, kitty, git, gh, lazygit, opencode, uv |
| `nvim/` | `~/.config/nvim` | Neovim (kickstart-modular based) |
| `bin/ai-commit-msg` | `~/.local/bin/ai-commit-msg` | AI commit-subject generator (used by lazygit) |
| `Brewfile` | — | brew formulae/casks/npm |
| `secrets.example` | — | template for `~/.secrets` (names only) |
| `aws/config.example` | — | template for `~/.aws/config` (placeholders only) |

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

1. Adds and trusts the third-party taps (`anomalyco/tap`, `hashicorp/tap`,
   `terraform-linters/tap`, `spacelift-io/spacelift`) and runs `brew bundle`
   from the `Brewfile`.
   Compatible external Node/npm, tree-sitter, and Java/JDK installations are reused
   via `HOMEBREW_BUNDLE_BREW_SKIP`; Homebrew-managed tools still receive upgrades.
   There is no macOS version gate. A missing `tree-sitter` executable gets an npm
   fallback. npm CLIs (Claude Code, corepack, markdownlint-cli) are installed
   directly with the active Node/npm environment and strict engine checks.
   External Node must be 22.22.2+, 24.15+, or 26+ (within those release lines).
   pipx installs
   `pytest-language-server` and checks its PATH entry. `tlrc` provides `tldr`;
   the upstream-disabled `bdinfo` cask is excluded.
2. Symlinks every config into `$HOME`, backing up any pre-existing real file to
   `<file>.bak` first.
3. Links `~/.tmux/projects.yaml` to `projects.local.yaml` if present, else the
   committed placeholder.
4. Clones TPM (tmux plugin manager) and patches `tmux-neolazygit`'s `editor.sh`
   for macOS (only once the plugin has been installed via `prefix + I`).
5. Symlinks personal scripts (e.g. `ai-commit-msg`) into `~/.local/bin`.
6. Creates `~/.secrets` from `secrets.example` (chmod 600) if it doesn't exist.
7. Creates `~/.aws/config` from `aws/config.example` (chmod 600) if it doesn't exist.

Package failures do not prevent config linking, but the installer lists failures
at the end and exits nonzero when setup is incomplete. Full logs are saved under
`${XDG_STATE_HOME:-~/.local/state}/dotfiles/`. Use Xcode/Command Line Tools
compatible with your macOS release before running package installation.

### Manual steps after install

1. **Secrets** — edit `~/.secrets` and fill in real values, then `exec zsh`.
   `~/.secrets` is sourced by `.zshrc` and is **never** committed. Variables:
   - `VAST_ANTHROPIC_DEV_BASE_URL`, `VAST_ANTHROPIC_DEV_TOKEN` (if using the Vast dev proxy)
   - `VAST_ANTHROPIC_PRD_BASE_URL`, `VAST_ANTHROPIC_PRD_TOKEN`
   - `UV_INDEX_VAST_USERNAME`, `UV_INDEX_VAST_PASSWORD` (uv index auth)
 2. **AWS** — edit `~/.aws/config` and replace the `<PLACEHOLDER>` values (account
    IDs and the SSO directory id), then run `aws sso login --profile corpeng`
    (opens a browser). `~/.aws/config` is **never** committed; only
    `aws/config.example` (placeholders) is tracked. Profiles: `corpeng`,
    `infosys-software`. Requires the AWS CLI (`awscli`, provisioned by the
    Brewfile) — it provides the `aws` command used by `aws sso login` and the
    `asp` profile switcher.
3. **tmux plugins** — open tmux, press `prefix + I`, then **re-run `./install.sh`
   once** so the `tmux-neolazygit` `editor.sh` gets patched for macOS.
4. **Neovim** — launch `nvim`, let lazy.nvim + mason finish installing.
5. **Real tmux projects** — recreate `tmux/.tmux/projects.local.yaml` with your
   actual project paths (see `projects.yaml` for the format), then re-run
   `./install.sh` to point `~/.tmux/projects.yaml` at it.

## lazygit

Config lives at `config/.config/lazygit/config.yml`, read from `~/.config/lazygit`
because `XDG_CONFIG_HOME=~/.config` is exported in **both** `~/.zshenv` (for
shells) and `~/.tmux.conf` via `set-environment -g` (for the tmux server, so
every pane/nvim/lazygit child inherits it). Without the tmux one, lazygit falls
back to an empty `~/Library/Application Support/lazygit/config.yml` and none of
the custom commands load; `install.sh` also deletes that empty file if present.

Both entry points read this same config, so the keys below work identically in:
- **`prefix + G`** (tmux-neolazygit) and
- **`<leader>gg`** (lazygit.nvim, inside Neovim).

Custom keybindings:

| Key | Context | Action |
|-----|---------|--------|
| `o` | commits | Open the selected commit on the remote in the browser |
| `o` | remote branches | Open the selected remote branch in the browser |
| `o` | local branches | Open the selected local branch in the browser |
| `P` | files | `pre-commit run --all-files` |
| `x` | files | Generate an **AI commit subject**, shown in an editable prompt |

The `x` command runs `ai-commit-msg`, which sends the **staged** diff to the
connected LiteLLM model through OpenCode for a single-line Conventional Commits
subject (needs `opencode`, `jq`, and LiteLLM connected via `/connect`). The
result pre-fills an editable input box — press Enter to commit or Esc to cancel.
If generation fails or the subject is invalid, the command stops instead of
committing a generic fallback. Do not stage secrets when using this command.

### tmux + lazygit (neolazygit)

`prefix + G` opens lazygit in a popup via
[`tmux-neolazygit`](https://github.com/AngryMorrocoy/tmux-neolazygit). Opening a
file from lazygit routes into your existing Neovim instance in the origin pane
(macOS-compatible `editor.sh`, patched by `install.sh`). This is independent of
Neovim's own `<leader>gg` (lazygit.nvim) — different layers, no collision.

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
