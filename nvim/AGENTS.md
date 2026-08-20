# AGENTS.md - Neovim Configuration

This is a Lua-based Neovim configuration built on kickstart-modular.nvim using lazy.nvim as the plugin manager.

## Project Structure

```
~/.config/nvim/
├── init.lua                 # Entry point: loads options, keymaps, lazy-bootstrap, lazy-plugins
├── lua/
│   ├── options.lua          # Vim options (line numbers, tabs, clipboard, etc.)
│   ├── keymaps.lua          # Key mappings and autocommands
│   ├── lazy-bootstrap.lua   # lazy.nvim plugin manager bootstrap
│   ├── lazy-plugins.lua     # Main plugin loading configuration
│   ├── kickstart/           # Core plugin configurations
│   │   ├── health.lua       # Health check module (:checkhealth kickstart)
│   │   └── plugins/         # Plugin specs (lspconfig, telescope, treesitter, etc.)
│   └── custom/              # User customizations
│       └── plugins/         # Custom plugin specs
├── .stylua.toml             # Lua formatter configuration
└── lazy-lock.json           # Plugin version lock file
```

## Build/Lint/Test Commands

### Formatting

```bash
# Check Lua formatting (CI uses this)
stylua --check .

# Format all Lua files
stylua .

# Format a single file
stylua lua/path/to/file.lua
```

### Health Check

Run inside Neovim:
```vim
:checkhealth kickstart
```

Checks Neovim version (requires 0.10+) and external dependencies: `git`, `make`, `unzip`, `rg`.

### Plugin Management

Run inside Neovim:
```vim
:Lazy              " View plugin status
:Lazy update       " Update all plugins
:Lazy sync         " Sync plugins with lock file
:Lazy check        " Check for updates
```

### LSP Tools

```vim
:Mason             " View/install LSP servers, formatters, linters
:LspInfo           " Check active LSP clients for current buffer
:ConformInfo       " Check formatter configuration
```

## Code Style Guidelines

### StyLua Configuration (.stylua.toml)

```toml
column_width = 160
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferSingle"
call_parentheses = "None"
```

### Formatting Rules

- **Indentation**: 2 spaces (no tabs)
- **Line width**: 160 characters max
- **Quotes**: Prefer single quotes (`'string'`)
- **Function calls**: Omit parentheses for single string/table arguments
  ```lua
  -- Good
  require 'module'
  vim.cmd 'command'
  setup { opts = true }
  
  -- Avoid
  require('module')
  vim.cmd('command')
  setup({ opts = true })
  ```
- **Line endings**: Unix (LF)

### File Structure Conventions

- Each file ends with a modeline: `-- vim: ts=2 sts=2 sw=2 et`
- Plugin specs return a table (single plugin) or array of tables (multiple plugins)
- Use `return { ... }` pattern for plugin files

### Plugin Spec Pattern

```lua
-- lua/kickstart/plugins/example.lua
return {
  {
    'author/plugin-name',
    event = { 'BufReadPre', 'BufNewFile' },  -- Lazy loading
    dependencies = { 'dep/plugin' },
    opts = {
      -- Plugin options passed to setup()
    },
    config = function()
      -- Complex configuration
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
```

### Naming Conventions

- **Variables/Functions**: `snake_case`
- **Local functions**: Prefix with `local`
- **Augroup names**: Use descriptive names like `kickstart-lsp-attach`
- **Keymap descriptions**: Use `[B]racket` notation for which-key: `'[S]earch [H]elp'`

### Keymapping Style

```lua
-- Standard keymap
vim.keymap.set('n', '<leader>key', function()
  -- action
end, { desc = 'Description for which-key' })

-- LSP-specific (in LspAttach callback)
local map = function(keys, func, desc, mode)
  mode = mode or 'n'
  vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
end
map('grd', vim.lsp.buf.definition, '[G]oto [D]efinition')
```

### Autocommand Pattern

```lua
vim.api.nvim_create_autocmd('EventName', {
  desc = 'Description of what this does',
  group = vim.api.nvim_create_augroup('unique-group-name', { clear = true }),
  callback = function(event)
    -- handler
  end,
})
```

### Error Handling

- Use `vim.health.ok()`, `vim.health.warn()`, `vim.health.error()` for health checks
- Check capabilities before using LSP features: `client:supports_method(method, bufnr)`
- Use `pcall` or `xpcall` for potentially failing operations

### Type Annotations

Use LuaLS annotations for complex functions:
```lua
---@param client vim.lsp.Client
---@param method vim.lsp.protocol.Method
---@param bufnr? integer
---@return boolean
local function client_supports_method(client, method, bufnr)
  -- implementation
end
```

## Key Configuration Values

- **Leader key**: Space (`vim.g.mapleader = ' '`)
- **Local leader**: Space (`vim.g.maplocalleader = ' '`)
- **Nerd Font**: Enabled (`vim.g.have_nerd_font = true`)
- **Color column**: 120 characters
- **Tab settings**: tabstop=2, shiftwidth=4, expandtab=true

## Formatters by Language

| Language   | Formatters                           |
|------------|--------------------------------------|
| Lua        | stylua                               |
| Python     | ruff_organize_imports, ruff_format   |
| JavaScript | prettierd, prettier, eslint_d        |
| TypeScript | prettierd, prettier, eslint_d        |
| JSON       | fixjson, jq                          |
| SQL        | sqlfmt                               |

## Adding New Plugins

1. Create a new file in `lua/custom/plugins/`
2. Return a plugin spec table
3. Restart Neovim or run `:Lazy`

Example:
```lua
-- lua/custom/plugins/my-plugin.lua
return {
  'author/my-plugin',
  opts = {},
}
-- vim: ts=2 sts=2 sw=2 et
```

## Dependencies

External tools (check with `:checkhealth kickstart`):
- `git` - Version control
- `make` - Build tool
- `unzip` - Archive extraction
- `rg` (ripgrep) - Fast search
