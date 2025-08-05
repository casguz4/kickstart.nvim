return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
  },
  config = function()
    local dap = require('dap')

    -- JavaScript/TypeScript Debug Adapter Configuration
    dap.adapters['pwa-node'] = {
      type = 'server',
      host = 'localhost',
      port = '${port}',
      executable = {
        command = 'node',
        args = {
          require('mason-registry').get_package('js-debug-adapter'):get_install_path()
            .. '/js-debug/src/dapDebugServer.js',
          '${port}',
        },
      },
    }

    dap.adapters['pwa-chrome'] = {
      type = 'server',
      host = 'localhost',
      port = '${port}',
      executable = {
        command = 'node',
        args = {
          require('mason-registry').get_package('js-debug-adapter'):get_install_path()
            .. '/js-debug/src/dapDebugServer.js',
          '${port}',
        },
      },
    }

    -- Configuration for debugging JavaScript/TypeScript files
    dap.configurations.javascript = {
      {
        type = 'pwa-node',
        request = 'launch',
        name = 'Launch file',
        program = '${file}',
        cwd = '${workspaceFolder}',
        sourceMaps = true,
        protocol = 'inspector',
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
        protocol = 'inspector',
        skipFiles = { '<node_internals>/**/*.js' },
      },
      {
        type = 'pwa-chrome',
        request = 'launch',
        name = 'Start Chrome with "localhost"',
        url = 'http://localhost:3000',
        webRoot = '${workspaceFolder}',
        userDataDir = '${workspaceFolder}/.vscode/vscode-chrome-debug-userdatadir',
      },
    }

    -- TypeScript uses the same configurations
    dap.configurations.typescript = dap.configurations.javascript
    dap.configurations.typescriptreact = dap.configurations.javascript
    dap.configurations.javascriptreact = dap.configurations.javascript
  end,
}
