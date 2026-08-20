return {
  'akinsho/bufferline.nvim',
  version = '*',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    require('bufferline').setup {
      options = {
        mode = 'buffers', -- show buffer list, not tabpages
        diagnostics = 'nvim_lsp',
        show_buffer_close_icons = false,
        show_close_icon = false,
        separator_style = 'slant',
        offsets = {
          {
            filetype = 'neo-tree',
            text = 'File Explorer',
            highlight = 'Directory',
            text_align = 'left',
          },
        },
      },
    }

    -- Buffer navigation mappings (optional but highly recommended)
    vim.keymap.set('n', '<Tab>', '<cmd>BufferLineCycleNext<CR>', { desc = 'Next buffer' })
    vim.keymap.set('n', '<S-Tab>', '<cmd>BufferLineCyclePrev<CR>', { desc = 'Previous buffer' })
  end,
}
-- vim: ts=2 sts=2 sw=2 et
