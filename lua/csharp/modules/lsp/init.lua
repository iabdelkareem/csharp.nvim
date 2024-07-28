local M = {}
local config_store = require("csharp.config")

function M.setup()
  require("csharp.modules.lsp.omnisharp").setup()
  require("csharp.modules.lsp.roslyn").setup()
end

return M
