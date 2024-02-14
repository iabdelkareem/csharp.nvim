local M = {}
local ui = require("csharp.ui")

--- @class DebugConfigFactoryArgs
--- @field project_information OmnisharpProjectInformation?

--- @class DebugConfigFactory
--- @field name string
--- @field request "launch"|"attach"
--- @field create_config fun(args: DebugConfigFactoryArgs): table

--- @type DebugConfigFactory[]
local debug_config_factories = {
  require("csharp.features.debugger.config_factories.launch-debugger"),
  require("csharp.features.debugger.config_factories.attach-debugger"),
}

--- @async
--- @return DebugConfigFactory
function M.select_debug_config()
  return ui.select_sync(debug_config_factories, {
    prompt = "Start Debugging:",
    format_item = function(item)
      return item.name
    end,
  })
end

return M
