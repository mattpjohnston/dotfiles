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

Install Homebrew using its [official installer](https://brew.sh), reviewing the
script before running it. The supported prefixes are `/opt/homebrew` on the Mac
and `/home/linuxbrew/.linuxbrew` on Atlas. Follow `brew shellenv` instructions
before installing the shared CLI/dev baseline:

```sh
brew bundle check --file="$HOME/.Brewfile" --no-upgrade
brew bundle --file="$HOME/.Brewfile" --no-upgrade
```

## Runtimes and editor tools

Homebrew owns pnpm, uv and rustup. pnpm owns Node LTS, npm/npx, native TypeScript
and Pi. uv owns Python interpreters/environments and the Ruff/ty tools. rustup
owns Rust toolchains, rust-analyzer, Clippy, rustfmt and rust-src. LLVM/clangd and
Tombi are Brew packages. Mason is not used.

After Brew Bundle, provision the ecosystem tools explicitly:

```sh
./scripts/setup-editor-tools
```

The setup script does not change application projects or their lockfiles. The
central web-tool manifest and lockfile are in `editor-tools/`. Its TypeScript 6
package is an Astro language-server SDK, while pnpm's separate global TypeScript
7 package supplies the native `tsc` language server. The pnpm workspace explicitly skips core-js's
funding-only postinstall script; it does not approve dependency builds broadly. Keep `PNPM_HOME/bin` before
`editor-tools/node_modules/.bin` so the SDK's compiler cannot shadow native TS7.
Astro's SDK is deliberately kept within the 6.x range during editor-tool updates.

Configure these executable directories in shell and desktop/service environments:

- Homebrew bin/sbin (`/opt/homebrew` on Mac; `/home/linuxbrew/.linuxbrew` on Atlas).
- `~/.local/bin` for uv tools and user scripts.
- `PNPM_HOME/bin`: `~/Library/pnpm/bin` on Mac; `~/.local/share/pnpm/bin` on Atlas.
- `$(brew --prefix rustup)/bin` for the rustup-managed Rust commands.
- `~/repos/dotfiles/editor-tools/node_modules/.bin` for the central web tools,
  after pnpm's global bin directory.

Use `pnpm bin -g` and `command -v` to verify actual ownership. Do not self-update
Brew-owned pnpm/uv/rustup or introduce a second Homebrew Node installation.
Retain npm/npx for compatibility; there are no npm-to-pnpm aliases.

Pi remains installed with pnpm. Set `"npmCommand": ["pnpm"]` in
`~/.pi/agent/settings.json` for its extension packages and retain `npm:` source
references. Codex, Claude, Copilot and Grok retain their Brew cask owners; Hermes
retains its existing upstream/private-environment installation and updater.
Existing application settings, credentials and sessions remain in place.

## Neovim

Neovim uses its built-in LSP client and nvim-lspconfig, without Mason. The active
configuration covers C/C++, Rust, Python, native TypeScript/JavaScript, Astro,
HTML/CSS, JSON, YAML and TOML. Svelte and Go language-server configuration are
excluded. Project-local tools are preferred by the upstream server configs where
supported; central installations provide fallbacks for loose files and projects
without their own tools. Central Ruff/ty use the project's configuration and
Python environment. Project dependencies are not automatically upgraded.

| Files | Language tools | Formatter |
| --- | --- | --- |
| C/C++ | Brew LLVM clangd with clang-tidy | clangd; automatic only with .clang-format |
| Rust | rustup rust-analyzer and Clippy | rustfmt |
| Python | uv ty and Ruff | Ruff |
| JS/TS | pnpm native TypeScript and Oxlint | Oxfmt |
| HTML/CSS/JSON | pnpm VS Code language servers | Oxfmt |
| YAML | pnpm YAML language server | Oxfmt |
| TOML / pyproject.toml | Brew Tombi | Tombi |
| Astro | pnpm Astro server and compatible SDK | Oxfmt with Astro support |
| Markdown | Existing syntax support | Oxfmt |

Only one formatter owns each filetype. LLVM's clangd path is explicit; native
compiler/debugger defaults remain unchanged. Oxfmt uses the project configuration
where present, or `editor-tools/oxfmt.json` (enabling Astro) otherwise. A project
Oxfmt configuration must enable Astro itself if it formats .astro files. The
central compiler companion is installed alongside Oxfmt; no global Prettier
installation or upstream source patches are required.

Install syntax parsers once on each machine, using Brew's tree-sitter CLI and
the native C compiler:

```vim
:TSInstall c cpp rust python typescript tsx javascript astro html css json yaml toml markdown markdown_inline bash lua vim vimdoc query diff gitcommit
```

Update Neovim plugins/parsers explicitly, reviewing the plugin lockfile diff:

```vim
:lua vim.pack.update()
:TSUpdate
:checkhealth vim.lsp vim.provider
```

## Updates

Run `update` in a fresh shell for the shared CLI/editor updater; `updateall`
retains the platform's additional application/service update stage. The shared
implementation is `scripts/update-tools`:

1. Brew update and Bundle upgrade for the CLI manifest.
2. pnpm Node LTS and global CLI updates, excluding Node/pnpm from package updates.
3. pnpm editor-tool updates, preserving the Astro SDK's TypeScript 6 constraint.
4. uv Python/tool updates, including Ruff/ty.
5. rustup toolchain/component updates without rustup self-update.

The explicit pnpm `--latest` steps deliberately advance ordinary tools across
major versions. The editor SDK is excluded and updated within its declared range.
This changes the central editor lockfile; it does not scan application repositories
or change their manifests/lockfiles. Copilot's cask uses `greedy: true` so Bundle
includes it despite upstream auto-update support. Keep Brew-owned agent updates
under Brew rather than invoking separate downloaders.

Atlas's wrapper also updates Fedora and system Flatpak packages. Its existing
explicit service/Hermes update stage remains separate from the shared script;
Mac updateall also runs Hermes's updater when installed. Firmware, reboots and
Neovim plugin/parser updates are separate operations.

Shell startup files do not configure Atlas desktop/user-service launches. Keep
`~/.config/environment.d/60-pnpm.conf` aligned with the directories above, run
`systemctl --user daemon-reload`, and inspect `systemctl --user show-environment`.
An already imported PATH can override the generator in a running session. From
a fresh configured shell, refresh it with
`systemctl --user import-environment PATH PNPM_HOME` and verify the result again.
For a live tmux server, refresh its global environment from a fresh shell; do not
restart attached sessions simply to change PATH. Existing graphical applications
may need reopening to inherit an updated environment.

Keep Fedora OS components, native build tools and required integration dependencies.
Do not force-remove dependency packages or run broad Bundle cleanup/autoremove.
Syncthing is explicitly outside this migration: do not change its installation,
configuration or service. Desktop applications/fonts remain outside the shared
CLI baseline. No backups or automatic commits/pushes are made by the setup/update
scripts.
