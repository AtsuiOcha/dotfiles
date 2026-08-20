return {
  { -- You can easily change to a different colorscheme.
    'EdenEast/nightfox.nvim',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    config = function()
      require('nightfox').setup {
        options = {
          styles = {
            comments = 'NONE', -- Disable italics in comments
          },
          colorblind = {
            enable = true,
            simulate_only = false,
            severity = {
              protan = 0.3,
              deutan = 0.9,
              tritan = 0,
            },
          },
        },
      }

      vim.cmd.colorscheme 'nightfox'
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
