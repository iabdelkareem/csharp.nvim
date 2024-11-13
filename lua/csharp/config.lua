local M = {}
---@class CsharpConfig
local config

---@class CsharpConfig
local default_config = {
  ---@class CsharpConfig.Lsp
  lsp = {
    --- @class CsharpConfig.Lsp.Omnisharp
    omnisharp = {
      enable = true,
      enable_editor_config_support = true,
      organize_imports = true,
      load_projects_on_demand = false,
      enable_analyzers_support = true,
      enable_import_completion = true,
      include_prerelease_sdks = true,
      analyze_open_documents_only = false,
      default_timeout = 1000,
      enable_package_auto_restore = true,
      debug = false,
      --- @type string?
      cmd_path = "",
    },
    --- @class CsharpConfig.Lsp.Roslyn
    roslyn = {
      enable = false,
      --- @type string?
      cmd_path = "",
    },
    --- @type boolean?
    --- @deprecated please use lsp.omnisharp.enable
    enable = nil,
    --- @type boolean?
    --- @deprecated please use lsp.omnisharp.enable_editor_config_support
    enable_editor_config_support = nil,
    --- @type boolean?
    --- @deprecated please use lsp.omnisharp.organize_imports
    organize_imports = nil,
    --- @type boolean?
    --- @deprecated please use lsp.omnisharp.load_projects_on_demand
    load_projects_on_demand = nil,
    --- @type boolean?
    --- @deprecated please use lsp.omnisharp.enable_analyzers_support
    enable_analyzers_support = nil,
    --- @type boolean?
    --- @deprecated please use lsp.omnisharp.enable_import_completion
    enable_import_completion = nil,
    --- @type boolean?
    --- @deprecated please use lsp.omnisharp.include_prerelease_sdks
    include_prerelease_sdks = nil,
    --- @type boolean?
    --- @deprecated please use lsp.omnisharp.analyze_open_documents_only
    analyze_open_documents_only = nil,
    --- @type number?
    --- @deprecated please use lsp.omnisharp.default_timeout
    default_timeout = nil,
    --- @type boolean?
    --- @deprecated please use lsp.omnisharp.enable_package_auto_restore
    enable_package_auto_restore = nil,
    --- @type boolean?
    --- @deprecated please use lsp.omnisharp.debug
    debug = false,
    --- @type boolean?
    --- @type table<string, any>|nil
    capabilities = nil,
    ---@type fun(client: lsp.Client, bufnr: number)|nil
    on_attach = nil,
  },
  --- @class CsharpConfig.Dap
  dap = {
    --- @type string?
    adapter_name = nil,
  },
  ---@class CsharpConfig.Logging
  logging = {
    level = "INFO",
  },
}

---@param default_config table
---@param user_config table
---@return table
local function merge(default_config, user_config)
  return vim.tbl_deep_extend("force", default_config, user_config)
end

function M.get_defaults()
  return vim.tbl_deep_extend("force", default_config, {})
end

---@param user_config CsharpConfig?
---@return CsharpConfig
function M.set_defaults(user_config)
  if user_config == nil or vim.tbl_isempty(user_config) then
    return M.get_defaults()
  end

  --- @type CsharpConfig
  local merged_config = merge(default_config, user_config)

  local deprecated_omnisharp_keys = {
    "enable",
    "enable_editor_config_support",
    "organize_imports",
    "load_projects_on_demand",
    "enable_analyzers_support",
    "enable_import_completion",
    "include_prerelease_sdks",
    "analyze_open_documents_only",
    "default_timeout",
    "enable_package_auto_restore",
    "debug",
  }

  for index, key in ipairs(deprecated_omnisharp_keys) do
    if merged_config.lsp[key] ~= nil then
      merged_config.lsp[key] = nil
      require("csharp.log").error("Use of deprecated key 'lsp."..key.."'. Use 'lsp.omnisharp."..key.."' instead.")
    end
  end

  return merged_config
end

---@param user_config CsharpConfig
function M.save(user_config)
  config = user_config
end

---@return CsharpConfig
function M.get_config()
  return config
end

return M
