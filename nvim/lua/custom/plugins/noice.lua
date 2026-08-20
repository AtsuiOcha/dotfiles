return {
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    opts = {
      lsp = {
        -- Disable LSP progress (use fidget.nvim instead)
        progress = { enabled = false },
        -- Override markdown rendering for better compatibility
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
        },
      },
      presets = {
        bottom_search = false, -- Use centered popup for search
        command_palette = false, -- Cmdline appears in center of screen
        long_message_to_split = false, -- Keep long messages in notification area
      },
    },
    dependencies = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      'MunifTanjim/nui.nvim',
      -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      'rcarriga/nvim-notify',
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
