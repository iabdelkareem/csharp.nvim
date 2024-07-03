local M = {}

---@param handler function
local function with_filtered_watchers(handler)
    return function(err, res, ctx, config)
        for _, reg in ipairs(res.registrations) do
            if reg.method == vim.lsp.protocol.Methods.workspace_didChangeWatchedFiles then
                local watchers = vim.tbl_filter(function(watcher)
                    if type(watcher.globPattern) == "table" then
                        local base_uri = nil ---@type string?
                        if type(watcher.globPattern.baseUri) == "string" then
                            base_uri = watcher.globPattern.baseUri
                            -- remove trailing slash if present
                            if base_uri:sub(-1) == "/" then
                                watcher.globPattern.baseUri = base_uri:sub(1, -2)
                            end
                        elseif type(watcher.globPattern.baseUri) == "table" then
                            base_uri = watcher.globPattern.baseUri.uri
                            -- remove trailing slash if present
                            if base_uri:sub(-1) == "/" then
                                watcher.globPattern.baseUri.uri = base_uri:sub(1, -2)
                            end
                        end

                        if base_uri ~= nil then
                            local base_dir = vim.uri_to_fname(base_uri)
                            -- use luv to check if baseDir is a directory
                            local stat = vim.loop.fs_stat(base_dir)
                            return stat ~= nil and stat.type == "directory"
                        end
                    end

                    return true
                end, reg.registerOptions.watchers)

                reg.registerOptions.watchers = true and watchers or {}
            end
        end
        return handler(err, res, ctx, config)
    end
end

---@param pipe string
---@param target string
local function lsp_start(pipe, target)
    local config = {}
    config.name = "roslyn"
    config.cmd = vim.lsp.rpc.connect(pipe)
    config.root_dir = vim.fs.dirname(target)
    config.on_init = function(client)
        vim.notify("Initializing Roslyn client for " .. target, vim.log.levels.INFO)
        client.notify("solution/open", {
            ["solution"] = vim.uri_from_fname(target),
        })
    end
    config.handlers = {
        ["client/registerCapability"] = with_filtered_watchers(
            vim.lsp.handlers["client/registerCapability"]
        ),
        ["workspace/projectInitializationComplete"] = function()
            vim.notify("Roslyn project initialization complete", vim.log.levels.INFO)
        end,
        ["workspace/_roslyn_projectHasUnresolvedDependencies"] = function()
            vim.notify("Detected missing dependencies. Run dotnet restore command.", vim.log.levels.ERROR)
            return vim.NIL
        end,
    }

    local client_id = vim.lsp.start(config)

    -- Handle the error in some way
    if not client_id then
        return
    end

    local client = vim.lsp.get_client_by_id(client_id)
    if not client then
        return
    end

    --  local commands = require("roslyn.commands")
    --commands.fix_all_code_action(client)
    --commands.nested_code_action(client)
end

---@param exe string
---@param target string
local function run_roslyn(exe, target)
    local cmd = {
        "dotnet",
        exe,
        "--logLevel=Information",
        "--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.get_log_path()),
    }

    vim.system(cmd, {
        detach = not vim.uv.os_uname().version:find("Windows"),
        stdout = function(_, data)
            if not data then
                return
            end

            -- try parse data as json
            local success, json_obj = pcall(vim.json.decode, data)
            if not success then
                return
            end

            local pipe_name = json_obj["pipeName"]
            if not pipe_name then
                return
            end

            vim.schedule(function()
                lsp_start(pipe_name, target)
            end)
        end,
        stderr_handler = function(_, chunk)
            local log = require("vim.lsp.log")
            if chunk and log.error() then
                log.error("rpc", "dotnet", "stderr", chunk)
            end
        end,
    })
end

function M.start_roslyn(root, exe)
   run_roslyn(exe, root)
end

return M
