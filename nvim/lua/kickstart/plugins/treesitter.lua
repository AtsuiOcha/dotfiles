return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    branch = 'main', -- the old `master` branch is archived and breaks on Neovim 0.12+
    lazy = false, -- the `main` branch does NOT support lazy-loading
    build = ':TSUpdate',
    config = function()
      local ts = require 'nvim-treesitter'

      -- Defaults are fine (install_dir = stdpath('data') .. '/site').
      ts.setup {}

      -- Parsers we always want available.
      local ensure = {
        'bash',
        'c',
        'diff',
        'html',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'query',
        'vim',
        'vimdoc',
        'python',
      }
      -- Async no-op if already installed.
      ts.install(ensure)

      -- Filetypes that should keep vim's regex highlighting instead of treesitter.
      local regex_highlight = { ruby = true }
      -- Filetypes where treesitter indent is disabled (kept from previous config).
      local indent_disabled = { ruby = true, python = true, typescript = true, sql = true }

      -- Languages that have an installable parser (the full installable universe).
      local installable = {}
      for _, lang in ipairs(ts.get_available()) do
        installable[lang] = true
      end

      -- Languages whose parser is actually installed on disk.
      local installed = {}
      for _, lang in ipairs(ts.get_installed 'parsers') do
        installed[lang] = true
      end

      -- Apply highlighting + indent to a buffer (assumes parser is present).
      local function enable_buffer(buf, ft)
        -- Highlighting is opt-in on the `main` branch: start it ourselves.
        if not regex_highlight[ft] then
          pcall(vim.treesitter.start, buf)
        end
        -- Treesitter indent (experimental) except for disabled filetypes.
        if not indent_disabled[ft] then
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end

      vim.api.nvim_create_autocmd('FileType', {
        desc = 'Enable treesitter highlighting/indent (auto-install missing parsers)',
        group = vim.api.nvim_create_augroup('kickstart-treesitter', { clear = true }),
        callback = function(args)
          local buf = args.buf
          local ft = vim.bo[buf].filetype
          if ft == '' then
            return
          end

          -- Ruby (and other regex-highlight fts) still get indent handling, but
          -- never a treesitter parser start. Indent is disabled for ruby anyway.
          if regex_highlight[ft] then
            enable_buffer(buf, ft)
            return
          end

          -- Map filetype -> parser language name.
          local lang = vim.treesitter.language.get_lang(ft) or ft

          if installed[lang] then
            enable_buffer(buf, ft)
          elseif installable[lang] then
            -- Auto-install the missing parser, then enable once ready
            -- (replicates the old `auto_install = true`).
            ts.install(lang):await(function(err)
              if err then
                return
              end
              installed[lang] = true
              -- Buffer may have changed; guard with validity + still-matching ft.
              if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == ft then
                enable_buffer(buf, ft)
              end
            end)
          end
        end,
      })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
