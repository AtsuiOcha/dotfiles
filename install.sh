#!/usr/bin/env bash
#
# install.sh - set up this dev environment on a new machine via SYMLINKS.
#
# Usage:
#   git clone https://github.com/AtsuiOcha/dotfiles ~/dotfiles
#   cd ~/dotfiles
#   ./install.sh
#
# Strategy: this repo is the single source of truth. Config files in $HOME are
# symlinked back into this repo, so editing e.g. ~/.zshrc edits the repo copy.
# Any pre-existing REAL file (not already the correct symlink) is backed up to
# <file>.bak before the symlink is created. Re-running is safe/idempotent.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Dotfiles repo: $DOTFILES_DIR"

# --- helper: symlink $2 -> $1, backing up an existing real $2 to $2.bak -------
link() {
  local src="$1" dest="$2"

  if [ ! -e "$src" ]; then
    echo "    !! source missing, skipping: $src"
    return
  fi

  # Already the correct symlink? nothing to do.
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "    ok  $dest -> $src"
    return
  fi

  mkdir -p "$(dirname "$dest")"

  # Existing real file/dir/other symlink: back it up.
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    echo "    backup existing $dest -> $dest.bak"
    rm -rf "$dest.bak"
    mv "$dest" "$dest.bak"
  fi

  ln -s "$src" "$dest"
  echo "    link $dest -> $src"
}

# --- 1. Homebrew -------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo "==> Homebrew not found. Install it first:"
  echo '    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  echo "    Then re-run this script."
  exit 1
fi

echo "==> Trusting third-party Homebrew taps used in the Brewfile..."
# Newer Homebrew refuses to load formulae/casks from untrusted taps, which would
# make 'brew bundle' skip terraform, tflint, and spacectl. Trust them up front.
# 'brew trust' is a no-op if the tap isn't tapped yet; brew bundle taps them,
# so we also fall back to HOMEBREW_NO_REQUIRE_TAP_TRUST for the bundle run.
for tap in hashicorp/tap terraform-linters/tap spacelift-io/spacelift; do
  brew trust "$tap" >/dev/null 2>&1 || true
done

echo "==> Installing CLI tools/casks from Brewfile (this may take a while)..."
# Don't let a single optional failure (e.g. a VSCode extension unavailable for
# this platform) abort the whole setup; the symlinks below are what matter most.
# HOMEBREW_NO_REQUIRE_TAP_TRUST lets bundle load from the taps it auto-adds.
if ! HOMEBREW_NO_REQUIRE_TAP_TRUST=1 brew bundle --file="$DOTFILES_DIR/Brewfile"; then
  echo "    !! brew bundle reported failures (see above). Continuing anyway;"
  echo "       re-run 'brew bundle --file=$DOTFILES_DIR/Brewfile' later to retry."
fi

# --- 1b. pipx packages (Python CLIs not in Homebrew or Mason) ----------------
# Some tools aren't Homebrew formulae and aren't in Mason's registry, so they
# can't be declared in the Brewfile or nvim's ensure_installed. Install them
# with pipx (provided by the Brewfile). Add future packages to the tuple below.
# pipx install is idempotent, so re-running is safe.
echo "==> Installing pipx packages..."
PIPX_PACKAGES=(
  pytest-language-server # nvim pytest_lsp: fixture go-to-definition (~/.local/bin)
)
for pkg in "${PIPX_PACKAGES[@]}"; do
  pipx install "$pkg" || echo "    !! pipx install $pkg failed; retry later"
done

# --- 2. Shell configs --------------------------------------------------------
echo "==> Linking shell configs..."
link "$DOTFILES_DIR/zsh/.zshrc"     "$HOME/.zshrc"
link "$DOTFILES_DIR/zsh/.zshenv"    "$HOME/.zshenv"
link "$DOTFILES_DIR/zsh/.p10k.zsh"  "$HOME/.p10k.zsh"
link "$DOTFILES_DIR/bash/.bashrc"   "$HOME/.bashrc"

# --- 3. Git config -----------------------------------------------------------
echo "==> Linking git config..."
link "$DOTFILES_DIR/git/.gitconfig"          "$HOME/.gitconfig"
link "$DOTFILES_DIR/git/.gitconfig-personal" "$HOME/.gitconfig-personal"

# --- 4. tmux -----------------------------------------------------------------
echo "==> Linking tmux config..."
link "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"

# Individual tmux scripts (keeps ~/.tmux/plugins/ out of the symlink surface).
for f in "$DOTFILES_DIR/tmux/.tmux/"*.sh; do
  [ -e "$f" ] || continue
  chmod +x "$f" 2>/dev/null || true
  link "$f" "$HOME/.tmux/$(basename "$f")"
done

# projects.yaml: prefer local (real, gitignored) definitions, else placeholder.
if [ -f "$DOTFILES_DIR/tmux/.tmux/projects.local.yaml" ]; then
  link "$DOTFILES_DIR/tmux/.tmux/projects.local.yaml" "$HOME/.tmux/projects.yaml"
else
  echo "    (no projects.local.yaml found; linking committed placeholder)"
  link "$DOTFILES_DIR/tmux/.tmux/projects.yaml" "$HOME/.tmux/projects.yaml"
fi

echo "==> Installing TPM (tmux plugin manager)..."
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
echo "    Once inside tmux, press 'prefix + I' to install the declared plugins."

# tmux-neolazygit hard-codes its editor to the plugin's own scripts/editor.sh
# and ignores $LAZYGIT_EDITOR, so overwrite it with our macOS-compatible version.
# This is re-applied on every run (and after 'prefix + I' installs the plugin).
NEOLG_DIR="$HOME/.tmux/plugins/tmux-neolazygit"
if [ -f "$NEOLG_DIR/scripts/editor.sh" ]; then
  echo "==> Patching tmux-neolazygit editor.sh for macOS..."
  cp "$DOTFILES_DIR/tmux/.tmux/scripts/neolazygit-editor.sh" "$NEOLG_DIR/scripts/editor.sh"
  chmod +x "$NEOLG_DIR/scripts/editor.sh"
else
  echo "    (tmux-neolazygit not installed yet; run 'prefix + I' then re-run this"
  echo "     script to patch its editor.sh for macOS.)"
fi

# --- 4b. Personal scripts (~/.local/bin) -------------------------------------
echo "==> Linking personal scripts into ~/.local/bin..."
mkdir -p "$HOME/.local/bin"
link "$DOTFILES_DIR/bin/ai-commit-msg" "$HOME/.local/bin/ai-commit-msg"

# --- 5. ~/.config apps -------------------------------------------------------
# IMPORTANT: ~/.config must be a REAL directory, not a symlink. If a previous
# setup symlinked all of ~/.config into this repo, per-app linking below would
# create self-referential symlinks. Convert it to a real dir first.
if [ -L "$HOME/.config" ]; then
  echo "==> ~/.config is a symlink; converting to a real directory..."
  rm "$HOME/.config"        # just a link into the repo; real data stays in repo
  mkdir -p "$HOME/.config"
fi
mkdir -p "$HOME/.config"

# lazygit on macOS auto-creates an EMPTY ~/Library/Application Support/lazygit/
# config.yml the first time it runs without XDG_CONFIG_HOME set. That empty file
# then SHADOWS our real ~/.config/lazygit/config.yml (lazygit reads whichever
# 'lazygit -cd' resolves to). Remove it ONLY if it exists and is empty so our
# custom commands (x = AI commit, P = pre-commit, o = open in browser) load.
LG_LEGACY="$HOME/Library/Application Support/lazygit/config.yml"
if [ -f "$LG_LEGACY" ] && [ ! -s "$LG_LEGACY" ]; then
  echo "==> Removing empty legacy lazygit config that would shadow ~/.config..."
  rm -f "$LG_LEGACY"
fi

echo "==> Linking app configs (btop, kitty, git, gh)..."
for d in "$DOTFILES_DIR/config/.config/"*; do
  [ -e "$d" ] || continue
  # Skip a nested nvim inside config/.config; nvim is linked from top-level below.
  [ "$(basename "$d")" = "nvim" ] && continue
  link "$d" "$HOME/.config/$(basename "$d")"
done

# --- 6. nvim -----------------------------------------------------------------
echo "==> Linking nvim config..."
link "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
echo "    Plugins auto-install via lazy.nvim + mason on first launch,"
echo "    pinned to the versions in lazy-lock.json."

# --- 7. Secrets --------------------------------------------------------------
if [ ! -f "$HOME/.secrets" ]; then
  echo "==> Creating ~/.secrets from template (fill in real values manually!)"
  cp "$DOTFILES_DIR/secrets.example" "$HOME/.secrets"
  chmod 600 "$HOME/.secrets"
else
  echo "==> ~/.secrets already exists, leaving it untouched."
fi

# --- 8. AWS config -----------------------------------------------------------
# ~/.aws/config holds SSO profile definitions (account IDs, org start URL). The
# real file is NOT tracked (public repo); only aws/config.example is committed.
if [ ! -f "$HOME/.aws/config" ]; then
  echo "==> Creating ~/.aws/config from template (fill in real values manually!)"
  mkdir -p "$HOME/.aws"
  cp "$DOTFILES_DIR/aws/config.example" "$HOME/.aws/config"
  chmod 600 "$HOME/.aws/config"
else
  echo "==> ~/.aws/config already exists, leaving it untouched."
fi

echo ""
echo "==> Done. Manual steps still required:"
echo "    1. Edit ~/.secrets and fill in real credential values, then 'exec zsh'."
echo "    1b. Edit ~/.aws/config, replace the <PLACEHOLDER> values, then run"
echo "        'aws sso login --profile corpeng' (opens a browser to authenticate)."
echo "    2. Open tmux and press 'prefix + I' to install tmux plugins via TPM,"
echo "       then RE-RUN ./install.sh once so the neolazygit editor.sh gets patched."
echo "    3. Launch nvim and let lazy.nvim/mason finish installing plugins."
echo "    4. First 'git push'/'git clone' over HTTPS will open a browser for"
echo "       Git Credential Manager OAuth (per host). Approve once; cached in Keychain."
