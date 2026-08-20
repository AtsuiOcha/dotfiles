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
          -- Explicit model selection (Anthropic Gov REQUIRED)
          -------------------------------------------------------------------
          params = {
            chat = {
              max_tokens = 4096,
              model = os.getenv 'ANTHROPIC_MODEL' or 'us-gov.anthropic.claude-sonnet-4-5-20250929-v1:0',
            },
            command = {
              max_tokens = 4096,
              model = os.getenv 'ANTHROPIC_MODEL' or 'us-gov.anthropic.claude-sonnet-4-5-20250929-v1:0',
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
            os.getenv 'ANTHROPIC_MODEL' or 'us-gov.anthropic.claude-sonnet-4-5-20250929-v1:0',
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
  end,
}
-- vim: ts=2 sts=2 sw=2 et
