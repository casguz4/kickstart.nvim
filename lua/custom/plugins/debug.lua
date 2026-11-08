-- Debugging: nvim-dap with dap-ui, js-debug (Node + Chrome) and Go (delve).
-- Debug adapters come from the Mason install list; Mason's bin dir is first
-- on PATH, so `js-debug-adapter` and `dlv` resolve to its shims.
-- `.vscode/launch.json` configurations load on top of these.

-- One js-debug server serves both pwa-node and pwa-chrome.
local js_debug = {
  type = 'server',
  host = 'localhost',
  port = '${port}',
  executable = {
    command = 'js-debug-adapter',
    args = { '${port}' },
  },
}

return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
    'leoluz/nvim-dap-go',
  },
  keys = {
    {
      '<F5>',
      function()
        require('dap').continue()
      end,
      desc = 'Debug: Start/Continue',
    },
    {
      '<F1>',
      function()
        require('dap').step_into()
      end,
      desc = 'Debug: Step Into',
    },
    {
      '<F2>',
      function()
        require('dap').step_over()
      end,
      desc = 'Debug: Step Over',
    },
    {
      '<F3>',
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: Step Out',
    },
    {
      '<leader>db',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Debug: Toggle [B]reakpoint',
    },
    {
      '<leader>dB',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Debug: Conditional [B]reakpoint',
    },
    -- Shows the last session's output, e.g. after an unhandled exception.
    {
      '<F7>',
      function()
        require('dapui').toggle()
      end,
      desc = 'Debug: See last session result.',
    },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    dapui.setup {
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- JavaScript / TypeScript
    dap.adapters['pwa-node'] = js_debug
    dap.adapters['pwa-chrome'] = js_debug

    local js_configurations = {
      {
        type = 'pwa-node',
        request = 'launch',
        name = 'Launch file',
        program = '${file}',
        cwd = '${workspaceFolder}',
        sourceMaps = true,
        console = 'integratedTerminal',
        resolveSourceMapLocations = {
          '${workspaceFolder}/dist/**/*.js',
          '${workspaceFolder}/**',
          '!**/node_modules/**',
        },
      },
      {
        type = 'pwa-node',
        request = 'attach',
        name = 'Attach',
        processId = require('dap.utils').pick_process,
        cwd = '${workspaceFolder}',
        sourceMaps = true,
        skipFiles = { '<node_internals>/**/*.js' },
      },
      {
        type = 'pwa-chrome',
        request = 'launch',
        name = 'Start Chrome with "localhost"',
        url = 'http://localhost:3000',
        webRoot = '${workspaceFolder}',
      },
    }
    for _, ft in ipairs { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' } do
      dap.configurations[ft] = js_configurations
    end

    -- Go (delve). On Windows delve must run attached or it crashes.
    require('dap-go').setup {
      delve = { detached = vim.fn.has 'win32' == 0 },
    }
  end,
}
