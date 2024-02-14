local dap = require("dap")

--- @async
--- @param args DebugConfigFactoryArgs
--- @return table
local function create_config(args)
  local project_folder_path = vim.fn.fnamemodify(args.project_information.Path, ":h")

  local build_succeded = require("csharp.modules.dotnet-cli").build(args.project_information.Path, { "-c Debug" })

  if not build_succeded then
    logger.debug("Skip debugging, build failed!", { feature = "debugger" })
    error("Skip debugging, build failed!")
  end

  return {
    name = "Launch - .NET",
    request = "launch",
    type = "coreclr",
    cwd = project_folder_path,
    program = args.project_information.TargetPath,
    args = {},
    env = {},
  }
end

return {
  name = "Launch - .NET",
  request = "launch",
  create_config = create_config,
}
