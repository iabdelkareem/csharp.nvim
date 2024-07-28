local M = {}
local logger = require("csharp.log")
local utils = require("csharp.utils")
local dotnet_cli = require("csharp.modules.dotnet-cli")
local _feature_name = "user-secrets"
local _lua_pattern_guid = "%w+-%w+-%w+-%w+-%w+"

-- Creates the user secret file if the same
-- doesn't exists
local function _ensure_secret_exists(user_secret_folder_path)
  local full_file_path = user_secret_folder_path .. "/secrets.json"
  local file, _ = io.open(full_file_path, "r+")

  if not file then
    os.execute("mkdir -p " .. user_secret_folder_path)
    os.execute("echo \"{\n}\" > " .. full_file_path)
  end

  return full_file_path
end

-- Paramter:
-- • {output_init_command} Output from init command
--
-- Returns a string with the user id or nil.
--- @param input string
--- @return string | nil
local function _extract_user_secret_id_from_input(input)
  return string.match(input, _lua_pattern_guid)
end

local function _extract_user_id_from_project(project_path)
  local project_file = io.open(project_path, "r")
  local user_id

  if not project_file then
    logger.error("Something went wrong during read the project file", { feature = _feature_name })
    return
  end

  for line in project_file:lines() do
    user_id = _extract_user_secret_id_from_input(line)

    if user_id then
      break
    end
  end

  project_file:close()

  if not user_id then
    return user_id
  end

  return tostring(user_id)
end

--
-- Paramter:
-- • {project_path} Path to project.
--- @param project_path string
--- @return string | nil
local function _init_secret(project_path)
  local output, _ = dotnet_cli.user_secrets("init", project_path)

  if output then
    return _extract_user_secret_id_from_input(output)
  end
end

local function _open_secret_in_buffer(user_secret_id)
  local secret_folder_path = os.getenv("HOME") .. "/.microsoft/usersecrets/" .. user_secret_id
  local file_path = _ensure_secret_exists(secret_folder_path)

  vim.cmd.edit(file_path)
end

local function _open_secret()
  local project_information = require("csharp.features.workspace-information").select_project()

  if not project_information then
    logger.error("No project selected", { feature = _feature_name })
    return
  end

  local user_secret_id = _extract_user_id_from_project(project_information.Path)

  if not user_secret_id then
    logger.warn("User Secret Id not found in project, creating...", { feature = _feature_name })

    user_secret_id = _init_secret(project_information.Path)

    if not user_secret_id then
      logger.error("Something went wrong during user secrets creation", { feature = _feature_name })
      return
    end
  end

  logger.info("Opening user secret " .. user_secret_id, { feature = _feature_name })

  _open_secret_in_buffer(user_secret_id)
end

-- Will try to open the secret from a project if exists,
-- if not It will create a new one.
function M.view_user_secrets()
  utils.run_async(_open_secret)
end

return M
