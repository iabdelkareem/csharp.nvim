local M = {}
local logger = require("csharp.log")
local csharp = require("csharp")

local function create_fix_usings_command(buffer)
  vim.api.nvim_buf_create_user_command(buffer, "CsharpFixUsings", csharp.fix_usings, { desc = "Csharp: Remove unneccessary usings" })
end

local function create_fix_all_command(buffer)
  vim.api.nvim_buf_create_user_command(buffer, "CsharpFixAll", csharp.fix_all, { desc = "Csharp: Fix all" })
end

function M.setup()
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)

      if client.name ~= "omnisharp" then
        return
      end

      logger.info("Registering csharp commands to buffer " .. args.buf)

      create_fix_usings_command(args.buf)
      create_fix_all_command(args.buf)
    end,
  })
end

return M
