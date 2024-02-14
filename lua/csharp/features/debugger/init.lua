local M = {}
local ui = require("csharp.ui")
local dap = require("dap")
local logger = require("csharp.log")
local utils = require("csharp.utils")
local notify = require("csharp.notify")
local next = next

--- @param debug_config table
--- @param launch_profile DotNetLaunchProfile
--- @return table
local function apply_launch_profile(debug_config, launch_profile)
  if launch_profile.environmentVariables then
    for key, value in pairs(launch_profile.environmentVariables) do
      debug_config.env[key] = value
    end
  end

  if launch_profile.commandLineArgs then
    vim.tbl_deep_extend("force", debug_config.args, vim.split(launch_profile.commandLineArgs, " ", { trimempty = true }))
  end

  if launch_profile.applicationUrl then
    table.insert(debug_config.args, "--urls=" .. launch_profile.applicationUrl)
  end

  return debug_config
end

--- @async
local function _execute()
  local debug_adapter = require("csharp.modules.dap").get_debug_adapter()
  if debug_adapter == nil then
    logger.error("Debug Adapter is not installed or configured.", { feature = "debugger" })
    return
  end

  if next(dap.sessions()) ~= nil then
    logger.debug("Debugging is already running, using dap.continue().", { feature = "debugger" })
    dap.continue()
    return
  end

  notify.info("Preparing debugger!")
  local debug_config_factory = require("csharp.features.debugger.config_factories").select_debug_config()
  local debug_config

  logger.debug("Selected debug config factory", { feature = "debugger", debug_config_factory = debug_config_factory })
  if debug_config_factory.request == "attach" then
    debug_config = debug_config_factory.create_config({})
  else
    local project_information = require("csharp.features.workspace-information").select_project()

    if project_information == nil then
      logger.error("No project selected", { feature = "debugger" })
      return
    end

    debug_config = debug_config_factory.create_config({ project_information = project_information })
    local project_folder_path = vim.fn.fnamemodify(project_information.Path, ":h")
    local launch_profile = require("csharp.modules.launch-settings").select_launch_profile(project_folder_path)

    if launch_profile then
      logger.debug("Applying launch profile to debug config.", { feature = "debugger", launch_profile = launch_profile, debug_config })
      debug_config = apply_launch_profile(debug_config, launch_profile)
    end
  end

  logger.debug("Starting debugger", { feature = "debugger", debug_config = debug_config })
  notify.info("Starting debugger!")
  dap.launch(debug_adapter, debug_config)
end

function M.execute()
  utils.run_async(_execute)
end

return M
