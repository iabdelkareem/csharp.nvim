local M = {}
local ui = require("csharp.ui")
local utils = require("csharp.utils")
local logger = require("csharp.log")
local notify = require("csharp.notify")
local config_store = require("csharp.config")

--- @class OmnisharpWorkspaceInformation
--- @field MsBuild OmnisharpMsBuildProjects

--- @class OmnisharpMsBuildProjects
--- @field Projects OmnisharpProjectInformation[]

--- @class OmnisharpProjectInformation
--- @field AssemblyName string
--- @field IsExe boolean
--- @field OutputPath string The output relative path
--- @field Path string the project absolute path
--- @field TargetPath string The target dll absolute path

--- @class GetProjectsRequest
--- @field ExcludeSourceFiles boolean

--- @async
--- @return OmnisharpWorkspaceInformation|nil
local function get_workspace_information()
  local buffer = vim.api.nvim_get_current_buf()
  local omnisharp_client = utils.get_omnisharp_client(buffer)

  if omnisharp_client == nil then
    logger.error("Omnisharp isn't attached to buffer.", { feature = "get-projects" })
    return
  end

  local config = config_store.get_config()

  local request_method = "o#/projects"
  --- @type GetProjectsRequest
  local request = {
    ExcludeSourceFiles = true,
  }

  logger.debug("Sending request to LSP Server", { feature = "get-workspace-information", request = request, method = request_method })

  --- @type LspRequestSyncResponse<OmnisharpWorkspaceInformation>
  local response = omnisharp_client.request_sync(request_method, request, config.lsp.default_timeout, buffer)

  if response.err ~= nil then
    logger.error("LSP client responded with error!", { feature = "get-workspace-information", error = response.err, request = request, method = request_method })
    return
  end
  return response.result
end

--- @async
--- @return OmnisharpProjectInformation|nil
function M.select_project()
  local workspace_information = get_workspace_information()

  if workspace_information == nil then
    logger.error("Workspace information couldn't be fetched.")
    return
  end

  --- @type OmnisharpProjectInformation[]
  local executable_projects = {}

  for _, project in ipairs(workspace_information.MsBuild.Projects) do
    if project.IsExe then
      table.insert(executable_projects, project)
    end
  end

  if #executable_projects == 0 then
    logger.error("No executable projects")
    return
  elseif #executable_projects == 1 then
    local selected_project = executable_projects[1]
    logger.debug("Found only one executable project", { feature = "select-project", project = selected_project, workspace_information = workspace_information })
    notify.info(string.format("Found only one executable project %s, using it.", selected_project.AssemblyName))
    return selected_project
  else
    logger.debug("Found multiple projects! Selecting one", { feature = "select-project", executable_projects = executable_projects, workspace_information = workspace_information })

    local selected_project = ui.select_sync(executable_projects, {
      prompt = "Select Project:",
      format_item = function(item)
        return item.AssemblyName
      end,
    })

    logger.debug("Selected project", { feature = "select-project", project = selected_project })
    return selected_project
  end
end

return M
