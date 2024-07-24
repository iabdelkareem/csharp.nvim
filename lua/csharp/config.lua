local M = {}

---@class CsharpConfig
local default_config = {
    ---@class CsharpConfig.Lsp
    lsp = {
        omnisharp = {
            enable = true,
            --- @type string?
            cmd_path = "",
        },
        roslyn = {
            enable = false,
            --- @type string?
            cmd_path = "",
        },
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

    return merge(default_config, user_config)
end

---@param user_config CsharpConfig
function M.save(user_config)
    if Csharp == nil then
        Csharp = {}
    end

    Csharp.config = user_config
end

---@return CsharpConfig
function M.get_config()
    return Csharp.config
end

return M
