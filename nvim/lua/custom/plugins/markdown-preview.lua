return {
  { 'ellisonleao/glow.nvim', config = true, cmd = 'Glow' },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown' }, -- Load based on file type
    name = 'render-markdown',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('render-markdown').setup {
        pipe_table = { preset = 'double' },
      }
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
