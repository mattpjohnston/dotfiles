# dotfiles

ghostty, zed, nvim.

```bash
git clone https://github.com/mattpjohnston/dotfiles.git ~/repos/dotfiles
cd ~/.config
for d in ghostty zed nvim; do
  [ -e "$d" ] && [ ! -L "$d" ] && { echo "refusing to replace non-symlink $d"; exit 1; }
  ln -sfn ~/repos/dotfiles/$d "$d"
done
```

## nvim

Neovim 0.12+. Plugins come from `vim.pack` and `nvim/nvim-pack-lock.json`;
the first start restores them at the locked revisions. Once per machine:

```vim
:MasonInstall ty ruff tsc oxlint oxfmt clangd html-lsp css-lsp svelte-language-server astro-language-server
:TSInstall astro bash css diff gitcommit go html javascript json python rust svelte toml tsx typescript yaml
:checkhealth vim.provider mason vim.lsp
```

```sh
rustup component add rust-analyzer  # toolchain-matched, not Mason
go install golang.org/x/tools/gopls@latest
```

Prerequisites: git, `rg`, Node/npm (Mason's npm packages), the tree-sitter CLI
and a C compiler (parsers). On the work Mac, check that policy permits Mason
downloads; if not, install the same tools by the approved route and put
them on PATH.

Updates: `:lua vim.pack.update()`, review the lockfile diff, `:TSUpdate`,
restart. Mason tool versions are not in the lockfile; `:Mason` updates them.

A project's own `node_modules/.bin` copy of a Node-based server (TypeScript 7+,
oxlint, oxfmt, html, cssls, svelte, astro) takes precedence over Mason's. clangd is only as
good as the project's `compile_commands.json`.
