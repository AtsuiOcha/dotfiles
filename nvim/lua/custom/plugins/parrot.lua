-- File: lua/custom/plugins/parrot.lua
return {
  'frankroeder/parrot.nvim',
  dependencies = {
    'ibhagwan/fzf-lua',
    'nvim-lua/plenary.nvim',
  },
  lazy = false,

  config = function()
    local parrot = require 'parrot'

    parrot.setup {
      providers = {
        anthropic = {
          name = 'anthropic',

          -- Build correct GOV endpoint.
          -- Base URL comes from ~/.secrets (VAST_ANTHROPIC_DEV_BASE_URL).
          endpoint = (function()
            local base = os.getenv 'VAST_ANTHROPIC_DEV_BASE_URL' or os.getenv 'ANTHROPIC_BASE_URL'
            if base and not base:match '/v1/messages$' then
              return base:gsub('/$', '') .. '/v1/messages'
            end
            return base or 'https://api.anthropic.com/v1/messages'
          end)(),

          model_endpoint = (function()
            local base = os.getenv 'ANTHROPIC_MODEL_ENDPOINT'
            if base then
              return base
            end

            local base2 = os.getenv 'VAST_ANTHROPIC_DEV_BASE_URL' or os.getenv 'ANTHROPIC_BASE_URL'
            if base2 then
              return base2:gsub('/$', '') .. '/v1/models'
            end

            return 'https://api.anthropic.com/v1/models'
          end)(),

          -- Auth token comes from ~/.secrets (VAST_ANTHROPIC_DEV_TOKEN).
          api_key = os.getenv 'VAST_ANTHROPIC_DEV_TOKEN' or os.getenv 'ANTHROPIC_API_KEY' or os.getenv 'ANTHROPIC_AUTH_TOKEN',

          -------------------------------------------------------------------
          -- Explicit model selection (override via $ANTHROPIC_MODEL)
          -------------------------------------------------------------------
          params = {
            chat = {
              max_tokens = 4096,
              model = 'vertex_ai/claude-haiku-4-5@20251001',
            },
            command = {
              max_tokens = 4096,
              model = 'vertex_ai/claude-haiku-4-5@20251001',
            },
          },

          topic = false,

          headers = function(self)
            return {
              ['Content-Type'] = 'application/json',
              ['x-api-key'] = self.api_key,
              ['anthropic-version'] = '2023-06-01',
            }
          end,

          models = {
            'vertex_ai/claude-haiku-4-5@20251001',
            'vertex_ai/claude-sonnet-5',
            'vertex_ai/claude-opus-4-8',
            'vertex_ai/claude-opus-5',
          },

          -------------------------------------------------------------------
          -- Anthropic Gov FIXES:
          -- 1. Move system messages to top-level
          -- 2. Strip empty messages (Gov rejects them)
          -------------------------------------------------------------------
          preprocess_payload = function(payload)
            -- Trim whitespace
            for _, message in ipairs(payload.messages) do
              if type(message.content) == 'string' then
                message.content = message.content:gsub('^%s*(.-)%s*$', '%1')
              end
            end

            -- Move system messages out of messages[]
            local msgs = {}
            for _, msg in ipairs(payload.messages) do
              if msg.role == 'system' then
                payload.system = msg.content
              else
                table.insert(msgs, msg)
              end
            end
            payload.messages = msgs

            -- Remove ANY empty messages (Anthropic GOV requirement)
            local cleaned = {}
            for _, msg in ipairs(payload.messages) do
              if msg.content and msg.content ~= '' and msg.content ~= {} then
                table.insert(cleaned, msg)
              end
            end
            payload.messages = cleaned

            return payload
          end,
        },
      },

      toggle_target = 'popup',
      user_input_ui = 'native',
      enable_spinner = true,

      -- In-chat buffer shortcuts (override awkward <C-g>* defaults).
      -- <C-g> collides with Neovim built-ins (normal: file info; insert: prefix commands).
      chat_shortcut_respond = { modes = { 'n', 'i', 'v', 'x' }, shortcut = '<C-e>' },
      chat_shortcut_stop = { modes = { 'n', 'i', 'v', 'x' }, shortcut = '<C-c>' },
      chat_shortcut_new = { modes = { 'n', 'i', 'v', 'x' }, shortcut = '<C-n>' },
      chat_shortcut_delete = { modes = { 'n', 'i', 'v', 'x' }, shortcut = '<C-d>' },
    }

    -----------------------------------------------------------------------
    -- Disable markdown linting in Parrot popup window
    -----------------------------------------------------------------------
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('parrot-markdown-lint', { clear = true }),
      pattern = 'markdown',
      callback = function(ev)
        local buf = ev.buf
        local name = vim.api.nvim_buf_get_name(buf)

        -- Parrot chat buffers always have "parrot" somewhere in the name
        if name:match 'parrot' then
          -- Disable nvim-lint, ALE, Vale, and LSP diagnostics
          vim.b[buf].lint_disabled = true
          vim.b[buf].ale_enabled = 0
          vim.b[buf].vale_disable = true
          vim.diagnostic.enable(false, { bufnr = buf })

          -- Clear any warnings already displayed
          pcall(vim.diagnostic.reset, nil, buf)
        end
      end,
    })

    -----------------------------------------------------------------------
    -- KEYMAPS
    -----------------------------------------------------------------------
    local map = vim.keymap.set

    -- Toggle chat with "…" (Option+; on macOS)
    map({ 'n', 'i', 'v' }, '…', function()
      vim.cmd 'PrtChatToggle popup'
    end, { noremap = true, silent = true, desc = 'AI Chat Toggle' })

    -- Visual selection → rewrite
    map('v', '<leader>ar', ':PrtRewrite<CR>', {
      noremap = true,
      silent = true,
      desc = 'AI Rewrite selection',
    })

    -- Visual selection → append
    map('v', '<leader>aa', ':PrtAppend<CR>', {
      noremap = true,
      silent = true,
      desc = 'AI Append after selection',
    })

    -- Visual selection → prepend
    map('v', '<leader>ap', ':PrtPrepend<CR>', {
      noremap = true,
      silent = true,
      desc = 'AI Prepend before selection',
    })

    -- Stop generation
    map({ 'n', 'v' }, '<leader>as', '<cmd>PrtStop<CR>', {
      noremap = true,
      silent = true,
      desc = 'AI Stop generation',
    })

    -- Visual selection → send into chat input (PrtChatPaste)
    map('v', '<leader>ai', ':PrtChatPaste<CR>', {
      noremap = true,
      silent = true,
      desc = 'AI Chat Paste (send selection to chat)',
    })

    -- New chat (reset context)
    map({ 'n', 'v' }, '<leader>an', function()
      vim.cmd 'PrtChatNew popup'
    end, { noremap = true, silent = true, desc = 'AI New chat (reset context)' })

    -----------------------------------------------------------------------
    -- Cheat-sheet: floating window listing AI keybinds (<leader>a?)
    -----------------------------------------------------------------------
    map('n', '<leader>a?', function()
      local lines = {
        ' AI / Parrot keybinds ',
        '',
        ' Global',
        '   <space>ai   send visual selection to chat',
        '   <space>an   new chat (reset context)',
        '   <space>ar   rewrite selection',
        '   <space>aa   append after selection',
        '   <space>ap   prepend before selection',
        '   <space>as   stop generation',
        '   …           toggle chat popup (Option+;)',
        '',
        ' Inside chat buffer',
        '   <C-e>   send / respond  (Execute)',
        '   <C-c>   stop',
        '   <C-n>   new chat',
        '   <C-d>   delete chat',
        '',
        ' Press q or <Esc> to close ',
      }

      local width = 0
      for _, line in ipairs(lines) do
        width = math.max(width, vim.fn.strdisplaywidth(line))
      end
      width = width + 2

      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.bo[buf].modifiable = false
      vim.bo[buf].bufhidden = 'wipe'
      vim.bo[buf].filetype = 'markdown'

      local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = #lines,
        row = math.floor((vim.o.lines - #lines) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        style = 'minimal',
        border = 'rounded',
        title = ' AI keybinds ',
        title_pos = 'center',
      })
      vim.wo[win].cursorline = true

      local close = function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
      end
      map('n', 'q', close, { buffer = buf, nowait = true, silent = true })
      map('n', '<Esc>', close, { buffer = buf, nowait = true, silent = true })
    end, { noremap = true, silent = true, desc = 'AI Keybind cheat-sheet' })
  end,
}
-- vim: ts=2 sts=2 sw=2 et
