local M = {}
local config_store = require("csharp.config")

--- @return string
--- @param buffer number
local function get_root_dir(buffer)
  local file_name = vim.api.nvim_buf_get_name(buffer)

  if file_name:sub(-#"csx") == "csx" then
    return file_name:match(".*/")
  end

  local root_dir = vim.fn.systemlist("fd -e sln . " .. vim.loop.cwd())[1]

  if root_dir == nil then
    root_dir = vim.loop.cwd()
  end

  return root_dir
end

function M.setup()
  local config = config_store.get_config().lsp
  if not config.enable then
    return
  end

  local lsp_group = vim.api.nvim_create_augroup("CsharpNvim", { clear = false })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "cs",
    callback = function(args)
      local solution_or_root_dir = get_root_dir(args.buf)
      if config.use_omnisharp then
        require("csharp.modules.lsp.omnisharp").start_omnisharp(args.buf, solution_or_root_dir)
      else
        require("csharp.modules.lsp.roslyn").start_roslyn(args.buf, solution_or_root_dir)
      end
    end,
    group = lsp_group,
    desc = "Starts omnisharp for c# files",
  })
end

if _TEST then
  M._get_root_dir = get_root_dir
  M._start_omnisharp = require("csharp.modules.lsp.omnisharp")._start_omnisharp
  M._get_omnisharp_cmd = require("csharp.modules.lsp.omnisharp")._get_omnisharp_cmd
end

return M
