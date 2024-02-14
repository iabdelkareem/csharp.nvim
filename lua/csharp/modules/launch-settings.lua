local M = {}
local logger = require("csharp.log")
local ui = require("csharp.ui")

--- @class DotNetLaunchProfile
--- @field name string
--- @field commandName string
--- @field environmentVariables table<string, string>
--- @field applicationUrl string
--- @field commandLineArgs string

--- @class DotNetLaunchSettings
--- @field profiles table<string,DotNetLaunchProfile>?

--- @param file_name string
--- @return DotNetLaunchSettings|nil
local function readFileWithoutBom(file_name)
  local file = io.open(file_name, "rb")
  if file then
    local content = file:read("*all")
    file:close()
    -- Check if the content starts with the UTF-8 BOM and exclude it if present
    if content:sub(1, 3) == "\xEF\xBB\xBF" then
      content = content:sub(4)
    end
    return vim.json.decode(content)
  else
    return nil
  end
end

--- @param project_folder string
--- @return DotNetLaunchProfile[]
local function get_launch_profiles(project_folder)
  local file_name = project_folder .. "/Properties/launchSettings.json"
  local launch_settings = readFileWithoutBom(file_name)

  if launch_settings == nil then
    logger.warn("Launch profile file could not be opened, or it doesn't exist. Skipping it.", { feature = "get-launch-profiles", file_name = file_name })
    return {}
  end

  --- @type DotNetLaunchProfile[]
  local profiles = {}
  for profile_name, profile in pairs(launch_settings.profiles) do
    if profile.commandName ~= "Project" then
      logger.debug("Skipping profile.", { feature = "get-launch-profiles", profile_name = profile_name, profile = profile, file_name = file_name })
      goto continue
    end

    profile.name = profile_name
    table.insert(profiles, profile)
    ::continue::
  end

  logger.debug("Found profiles.", { feature = "get-launch-profiles", profiles = profiles, file_name = file_name })
  return profiles
end

--- @async
--- @param project_folder string
--- @return DotNetLaunchProfile|nil
function M.select_launch_profile(project_folder)
  local launch_profiles = get_launch_profiles(project_folder)

  if #launch_profiles == 0 then
    return
  elseif #launch_profiles == 1 then
    return launch_profiles[1]
  end

  return ui.select_sync(launch_profiles, {
    prompt = "Select Launch Profile:",
    format_item = function(item)
      return item.name
    end,
  })
end

return M
