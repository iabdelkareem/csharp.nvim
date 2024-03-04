local M = {}
local config_store = require("csharp.config")
local logger = require("csharp.log")

function M.start_roslyn(buffer, root)
  vim.lsp.set_log_level(vim.log.levels.DEBUG)
  local config = config_store.get_config().lsp

  local cmd = {
    "dotnet",
    config.cmd_path,
    "--logLevel",
    "Debug",
    "--extensionLogDirectory",
    "/home/ibrahim",
  }

  logger.debug("Starting roslyn: ", { feature = "roslyn", cmd = cmd, buffer = buffer, root = root })

  local client_id = vim.lsp.start({
    name = "roslyn",
    cmd = cmd,
    root_dir = vim.fs.dirname(root),
    capabilities = config.capabilities,
    on_init = function(client)
      local solution = vim.uri_from_fname(root)
      logger.debug("Roslyn: Executing on_init", { solution = solution })
      client.notify("solution/open", { solution = solution })
    end,
    on_error = function(code, ...)
      logger.error("Error launch roslyn", { code = code, ... })
    end,
    on_attach = function(client, buffer)
      logger.debug("Attaching to roslyn", { buffer = buffer })
    end,
    handlers = {
      ["workspace/projectInitializationComplete"] = function()
        logger.debug("Roslyn project initialization complete")
      end,
      ["workspace/_roslyn_projectHasUnresolvedDependencies"] = function()
        logger.debug("Roslyn project has unresolved dependencies")
      end,
    },
  }, {
    bufnr = buffer,
  })

  logger.debug("Roslyn launched client", { client_id = client_id })
end

return M
