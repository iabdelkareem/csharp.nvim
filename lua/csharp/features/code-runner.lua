local M = {}
local utils = require("csharp.utils")
local notify = require("csharp.notify")

--- @async
local function _execute()
  local project_information = require("csharp.features.workspace-information").select_project()

  if project_information == nil then
    logger.error("No project selected", { feature = "code-runner" })
    return
  end

  local project_folder_path = vim.fn.fnamemodify(project_information.Path, ":h")

  local launch_profile = require("csharp.modules.launch-settings").select_launch_profile(project_folder_path)

  local opt = {
    "--project",
    project_information.Path,
    "-c",
    "Debug",
  }

  if launch_profile then
    opt = vim.list_extend(opt, { "--launch-profile", launch_profile.name })
  end

  require("csharp.modules.dotnet-cli").run(opt)
end

function M.execute()
  utils.run_async(_execute)
end

return M
