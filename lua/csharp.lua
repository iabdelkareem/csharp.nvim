---@param user_config CsharpConfig?
local function setup(user_config)
  local config = require("csharp.config")
  user_config = config.set_defaults(user_config)
  config.save(user_config)

  require("csharp.commands").setup()
  require("csharp.lsp").setup()
  require("csharp.log").setup()
end

return {
  setup = setup,
  fix_usings = require("csharp.features.fix-usings").execute,
  fix_all = require("csharp.features.fix-all").select_scope_and_execute,
  go_to_definition = require("csharp.features.go-to-definition").execute,
}
