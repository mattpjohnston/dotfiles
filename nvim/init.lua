vim.g.mapleader = ' '
vim.opt.number = true
vim.opt.cursorline = true
vim.opt.signcolumn = 'yes'
vim.opt.clipboard = 'unnamedplus'
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.list = true
vim.opt.listchars = { tab = '  ', trail = '·', nbsp = '␣' }
vim.opt.winborder = 'rounded'
vim.opt.inccommand = 'split'
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.foldtext = ''
vim.opt.foldlevel = 99

-- Full messages under the cursor line, end-of-line text elsewhere.
vim.diagnostic.config({
  virtual_text = { current_line = false },
  virtual_lines = { current_line = true },
  severity_sort = true,
})

vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function() vim.hl.on_yank() end,
})

-- Plugins

vim.pack.add({
  'https://github.com/mason-org/mason.nvim',
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/nvim-treesitter/nvim-treesitter',
  'https://github.com/nvim-mini/mini.completion',
  'https://github.com/nvim-mini/mini.pick',
  'https://github.com/lewis6991/gitsigns.nvim',
  'https://github.com/folke/which-key.nvim',
  'https://github.com/nvim-mini/mini.icons',
  'https://github.com/nvim-mini/mini.indentscope',
  'https://github.com/HiPhish/rainbow-delimiters.nvim',
  'https://github.com/nvim-treesitter/nvim-treesitter-context',
})

-- Before vim.lsp.enable(): puts Mason's bin directory on PATH.
require('mason').setup()

-- LSP

-- TypeScript 7's own server (Mason's tsc, or the project's if it is 7+).
-- Oxfmt formats.
vim.lsp.config('tsc', {
  on_init = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
})

-- Upstream only attaches when the project has an Oxc config or dependency.
local function oxc_root(config_files)
  return function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { config_files, { 'package.json', '.git' } })
    on_dir(root or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)))
  end
end

vim.lsp.config('oxlint', {
  root_dir = oxc_root({ '.oxlintrc.json', '.oxlintrc.jsonc', 'oxlint.config.ts' }),
})

vim.lsp.config('oxfmt', {
  root_dir = oxc_root({ '.oxfmtrc.json', '.oxfmtrc.jsonc', 'oxfmt.config.ts' }),
  filetypes = {
    'javascript', 'javascriptreact', 'typescript', 'typescriptreact',
    'json', 'jsonc', 'css', 'html', 'markdown', 'yaml', 'toml',
  },
})

vim.lsp.config('html', { init_options = { provideFormatter = false } })
vim.lsp.config('cssls', { init_options = { provideFormatter = false } })

vim.lsp.config('rust_analyzer', {
  settings = { ['rust-analyzer'] = { check = { command = 'clippy' } } },
})

vim.lsp.enable({
  'ty', 'ruff', 'tsc', 'oxlint', 'oxfmt', 'gopls',
  'clangd', 'rust_analyzer', 'html', 'cssls', 'svelte', 'astro',
})

-- Inlay hints on where the server's own editor client enables them.
local inlay_hint_servers = { rust_analyzer = true, clangd = true, ty = true }

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and inlay_hint_servers[client.name] then
      vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
    end
  end,
})

local function formatters(buf)
  return vim.lsp.get_clients({ bufnr = buf, method = 'textDocument/formatting' })
end

local function format()
  if #formatters(0) == 0 then
    return vim.notify('No formatter configured for this buffer', vim.log.levels.WARN)
  end
  vim.lsp.buf.format()
end

vim.api.nvim_create_user_command('Format', format, {})

-- Synchronous, so the edits land before the buffer is written.
local function organize_imports(buf)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf, method = 'textDocument/codeAction' })) do
    local params = {
      textDocument = vim.lsp.util.make_text_document_params(buf),
      range = { start = { line = 0, character = 0 }, ['end'] = { line = 0, character = 0 } },
      context = { only = { 'source.organizeImports' }, diagnostics = {} },
    }
    local response = client:request_sync('textDocument/codeAction', params, 1000, buf)
    for _, action in ipairs(response and response.result or {}) do
      if not action.edit and client:supports_method('codeAction/resolve') then
        local resolved = client:request_sync('codeAction/resolve', action, 1000, buf)
        action = resolved and resolved.result or action
      end
      if action.edit then vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding) end
    end
  end
end

-- Format on save where each language's tooling expects it. C/C++ only when
-- the project defines its style, otherwise clangd imposes LLVM style.
local format_on_save = {
  go = true, rust = true, python = true, astro = true, svelte = true,
  javascript = true, javascriptreact = true, typescript = true, typescriptreact = true,
  json = true, jsonc = true, css = true, html = true,
}
local organize_on_save = { go = true, python = true }

vim.api.nvim_create_autocmd('BufWritePre', {
  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    local clang = (ft == 'c' or ft == 'cpp') and vim.fs.root(args.buf, '.clang-format')
    if not (format_on_save[ft] or clang) then return end
    if organize_on_save[ft] then organize_imports(args.buf) end
    if #formatters(args.buf) > 0 then vim.lsp.buf.format({ bufnr = args.buf }) end
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  callback = function(args) pcall(vim.treesitter.start, args.buf) end,
})

require('mini.icons').setup()
MiniIcons.tweak_lsp_kind()
require('mini.completion').setup()
require('mini.pick').setup()
require('mini.indentscope').setup({
  draw = { animation = require('mini.indentscope').gen_animation.none() },
  symbol = '▏',
})
require('treesitter-context').setup({ max_lines = 3 })

require('gitsigns').setup({
  on_attach = function(bufnr)
    local gitsigns = require('gitsigns')
    local function map(lhs, rhs, desc)
      vim.keymap.set('n', lhs, rhs, { buffer = bufnr, desc = desc })
    end
    map(']c', function()
      if vim.wo.diff then vim.cmd.normal({ ']c', bang = true }) else gitsigns.nav_hunk('next') end
    end, 'Next Git hunk')
    map('[c', function()
      if vim.wo.diff then vim.cmd.normal({ '[c', bang = true }) else gitsigns.nav_hunk('prev') end
    end, 'Previous Git hunk')
    map('<leader>gp', gitsigns.preview_hunk, 'Preview hunk')
    map('<leader>gb', function() gitsigns.blame_line({ full = true }) end, 'Blame line')
  end,
})

require('which-key').setup()
require('which-key').add({ { '<leader>g', group = 'Git' } })

-- Mappings

local pick = require('mini.pick').builtin
vim.keymap.set('n', '<leader>f', pick.files, { desc = 'Find file' })
vim.keymap.set('n', '<leader>/', pick.grep_live, { desc = 'Search project' })
vim.keymap.set('n', '<leader>b', pick.buffers, { desc = 'Buffers' })
vim.keymap.set('n', '<leader>d', vim.diagnostic.setloclist, { desc = 'Buffer diagnostics' })
vim.keymap.set('n', '<leader>D', vim.diagnostic.setqflist, { desc = 'All diagnostics' })
vim.keymap.set('n', '<leader>F', format, { desc = 'Format' })
vim.keymap.set('n', '<leader>h', function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
end, { desc = 'Toggle inlay hints' })

-- Theme (keep one pair active)

-- vim.pack.add({ 'https://github.com/EdenEast/nightfox.nvim' })
-- local theme = { light = 'dayfox', dark = 'nightfox' }

-- vim.pack.add({ 'https://github.com/folke/tokyonight.nvim' })
-- local theme = { light = 'tokyonight-day', dark = 'tokyonight-moon' }

vim.pack.add({ { src = 'https://github.com/rose-pine/neovim', name = 'rose-pine' } })
local theme = { light = 'rose-pine-dawn', dark = 'rose-pine-moon' }

-- macOS appearance, or the mode file written by theme-switch.
local function os_mode()
  if vim.fn.has('mac') == 1 then
    local result = vim.system({ 'defaults', 'read', '-g', 'AppleInterfaceStyle' }, { text = true }):wait()
    return vim.trim(result.stdout or '') == 'Dark' and 'dark' or 'light'
  end
  local state = vim.env.XDG_STATE_HOME
  if not state or state == '' then state = vim.fs.joinpath(vim.env.HOME, '.local', 'state') end
  local file = io.open(vim.fs.joinpath(state, 'theme-mode'))
  if file then
    local value = vim.trim(file:read('*a') or '')
    file:close()
    if value == 'light' or value == 'dark' then return value end
  end
  return vim.o.background
end

local mode = os_mode()
vim.cmd.colorscheme(theme[mode])

vim.api.nvim_create_autocmd('FocusGained', {
  callback = function()
    local new_mode = os_mode()
    if new_mode ~= mode then
      mode = new_mode
      vim.cmd.colorscheme(theme[mode])
    end
  end,
})
