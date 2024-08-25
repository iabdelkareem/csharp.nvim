local M = {}
local logger = require("csharp.log")

local function execute_command(cmd)
  local file = io.popen(cmd .. " 2>&1")
  local output = file:read("*all")

  local success, _, exit_code = file:close()
  return output, success and 0 or exit_code
end

--- @param target string File path to solution or project
--- @param options string[]?
--- @return boolean
function M.build(target, options)
  local command = "dotnet build " .. target

  if options then
    command = command .. " " .. table.concat(options, " ")
  end

  logger.debug("Executing: " .. command, { feature = "dotnet-cli" })

  local output, exit_code = execute_command(command)

  --- @type boolean
  local build_succeded = exit_code == 0

  if build_succeded then
  else
    logger.debug("Build failed", { feature = "dotnet-cli" })
  end

  return build_succeded
end

--- @param options string[]?
function M.run(options)
  local command = "dotnet run"

  if options then
    command = command .. " " .. table.concat(options, " ")
  end

  logger.debug("Executing: " .. command, { feature = "dotnet-cli" })
  local current_window = vim.api.nvim_get_current_win()
  vim.cmd("split | term " .. command)
  vim.api.nvim_set_current_win(current_window)
end

--- Paramters:
--  • {command} Command that you want to execute, available commands are:
--
--    • `clear`  ~ Deletes all the application secrets
--    • `init`   ~ Set a user secrets ID to enable secret storage
--    • `list`   ~ Lists all the application secrets
--    • `remove` ~ Removes the specified user secret
--    • `set`    ~ Sets the user secret to the specified value
--
--  • {project_path} Path to project.
--- @param command string
--- @param project_path string
--- @return string | nil
function M.user_secrets(command, project_path)
  local command_to_run = "dotnet user-secrets"

  if not command then
    logger.error("command" .. required_arg_message, { feature = "dotnet-cli" })
    return
  end

  command_to_run = command_to_run .. " -p " .. project_path .. " " .. command

  logger.debug("Executing: " .. command_to_run, { feature = "dotnet-cli" })
  local user_secret_id, _ = execute_command(command_to_run)
  return user_secret_id
end

return M
