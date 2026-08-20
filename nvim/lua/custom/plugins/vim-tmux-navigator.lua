return {
  {
    'christoomey/vim-tmux-navigator',
    cmd = {
      'TmuxNavigateLeft',
      'TmuxNavigateDown',
      'TmuxNavigateUp',
      'TmuxNavigateRight',
      'TmuxNavigatePrevious',
      'TmuxNavigatorProcessList',
    },
    keys = {
      { '<c-h>', '<cmd>TmuxNavigateLeft<cr>', desc = 'Navigate Left (tmux)' },
      { '<c-j>', '<cmd>TmuxNavigateDown<cr>', desc = 'Navigate Down (tmux)' },
      { '<c-k>', '<cmd>TmuxNavigateUp<cr>', desc = 'Navigate Up (tmux)' },
      { '<c-l>', '<cmd>TmuxNavigateRight<cr>', desc = 'Navigate Right (tmux)' },
      { '<c-\\>', '<cmd>TmuxNavigatePrevious<cr>', desc = 'Navigate Previous (tmux)' },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
