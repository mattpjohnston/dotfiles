# dotfiles

## Setup

Move existing configs aside before linking.

```sh
git clone https://github.com/mattpjohnston/dotfiles.git ~/repos/dotfiles
mkdir -p ~/.config
for d in ghostty zed nvim; do
  [ -e "$HOME/.config/$d" ] && [ ! -L "$HOME/.config/$d" ] && { echo "move ~/.config/$d aside first"; break; }
  ln -sfn "$HOME/repos/dotfiles/$d" "$HOME/.config/$d"
done
ln -s ~/repos/dotfiles/starship.toml ~/.config/starship.toml
ln -s ~/repos/dotfiles/Brewfile ~/.Brewfile
```

## Homebrew

```sh
brew bundle check --file="$HOME/.Brewfile" --no-upgrade
brew bundle --file="$HOME/.Brewfile" --no-upgrade
```

## Neovim

Requires Neovim 0.12+, git, ripgrep, Node/npm, tree-sitter CLI, and a C compiler.

```vim
:MasonInstall ty ruff tsc oxlint oxfmt clangd html-lsp css-lsp svelte-language-server astro-language-server
:TSInstall astro bash css diff gitcommit go html javascript json python rust svelte toml tsx typescript yaml
:checkhealth vim.provider mason vim.lsp
```

```sh
rustup component add rust-analyzer
go install golang.org/x/tools/gopls@latest
```

Update plugins and parsers, review the lockfile diff, then restart:

```vim
:lua vim.pack.update()
:TSUpdate
:Mason
```
