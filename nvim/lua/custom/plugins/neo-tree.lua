return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    opts = function(_, opts)
      opts.filesystem = opts.filesystem or {}
      opts.filesystem.window = opts.filesystem.window or {}
      opts.filesystem.window.mappings = opts.filesystem.window.mappings or {}

      -- Replace the H key mapping to silently toggle hidden files (no vim.notify)
      opts.filesystem.window.mappings['H'] = function(state)
        local current = state.filtered_items and state.filtered_items.visible
        local new_val = not current
        state.filtered_items = state.filtered_items or {}
        state.filtered_items.visible = new_val
        require('neo-tree.sources.manager').refresh(state.name)
      end

      -- Your other config: close NeoTree with <leader>fe
      opts.filesystem.window.mappings['<leader>fe'] = 'close_window'

      -- Set window position if desired
      opts.filesystem.window.position = 'right'
    end,

    keys = {
      {
        '<leader>fe',
        '<cmd>Neotree toggle<CR>',
        desc = 'Toggle File Explorer (NeoTree)',
        silent = true,
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
