-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  -- NOTE: vim-surround removed in favor of mini.surround (lua/kickstart/plugins/mini.lua)
  -- NOTE: Comment.nvim removed in favor of Neovim's built-in commenting (gcc/gc).
  --       The pinned Comment.nvim (unmaintained since 2024) crashed on Neovim 0.12
  --       for filetypes without an installed treesitter parser (env/conf/ini/...),
  --       because vim.treesitter.get_parser now returns nil instead of erroring.
}
-- vim: ts=2 sts=2 sw=2 et
