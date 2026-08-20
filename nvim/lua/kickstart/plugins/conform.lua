return {
  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = { c = true, cpp = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then
          return nil
        else
          return {
            timeout_ms = 1000,
            lsp_format = 'fallback',
          }
        end
      end,
      formatters_by_ft = {
        python = { 'ruff_organize_imports', 'ruff_format' },
        lua = { 'stylua' },
        json = { 'fixjson', 'jq' },
        sql = { 'sqlfmt' },
        -- Conform can also run multiple formatters sequentially
        --
        -- You can use 'stop_after_first' to run the first available formatter from the list
        javascript = { 'prettierd', 'prettier', 'eslint_d', stop_after_first = true },
        typescript = { 'prettierd', 'prettier', 'eslint_d', stop_after_first = true },
        javascriptreact = { 'prettierd', 'prettier', 'eslint_d', stop_after_first = true },
        typescriptreact = { 'prettierd', 'prettier', 'eslint_d', stop_after_first = true },
      },
      formatters = {
        ruff_organize_imports = {
          command = 'ruff',
          args = {
            'check',
            '--select',
            'I001,F401',
            '--fix',
            '--stdin-filename',
            '$FILENAME',
            '-',
          },
          stdin = true,
        },
        ruff_format = {
          command = 'ruff',
          args = { 'format', '-' },
          stdin = true,
        },
        sqlfmt = {
          command = 'sqlfmt',
          args = { '-' },
          stdin = true,
          timeout = 5000, -- or higher if needed
        },
        -- Configure eslint_d
        eslint_d = {
          command = 'eslint_d',
          args = { '--fix-to-stdout', '--stdin', '--stdin-filename', '$FILENAME' },
          stdin = true,
        },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
