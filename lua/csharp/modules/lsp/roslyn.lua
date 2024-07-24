local M = {}
local config_store = require("csharp.config")

---@param file_paths string[]
---@param search_string string
---@return string?
local function get_filepath_containing_string(file_paths, search_string)
    for _, file_path in ipairs(file_paths) do
        local file = io.open(file_path, "r")

        if not file then
            return nil
        end

        local content = file:read("*a")
        file:close()

        if content:find(search_string, 1, true) then
            return file_path
        end
    end

    return nil
end

---@param buffer integer
---@return string?
local function get_sln_directory(buffer)
    return vim.fs.root(buffer, function(name)
        return name:match("%.sln$") ~= nil
    end)
end

---@param buffer integer
---@return string[]?
local function get_all_sln_files(buffer)
    local sln_dir = get_sln_directory(buffer)
    if not sln_dir then
        return nil
    end

    return vim.fn.glob(vim.fs.joinpath(sln_dir, "*.sln"), true, true)
end

--- Find a path to sln file that is likely to be the one that the current buffer
--- belongs to. Ability to predict the right sln file automates the process of starting
--- LSP, without requiring the user to invoke CSTarget each time the solution is open.
--- The prediction assumes that the nearest csproj file (in one of parent dirs from buffer)
--- should be a part of the sln file that the user intended to open.
---@param buffer integer
---@return string?
local function predict_sln_file(buffer)
    local sln_files = get_all_sln_files(buffer)

    if not sln_files then
        return nil
    end

    local csproj_dir = vim.fs.root(buffer, function(name)
        return name:match("%.csproj$") ~= nil
    end)

    if not csproj_dir then
        return nil
    end

    local csproj_files = vim.fn.glob(vim.fs.joinpath(csproj_dir, "*.csproj"), true, true)

    if #csproj_files > 1 then
        return nil
    end

    local csproj_filename = vim.fn.fnamemodify(csproj_files[1], ":t")

    return get_filepath_containing_string(sln_files, csproj_filename)
end

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
        -- none windows platform is better to attach apparently but this is subjective and a bit untested
        detach = not vim.uv.os_uname().version:find("Windows"),
        stdout = function(_, data)
            -- process didn't return a reponse correctly so fail out.
            if not data then
                return
            end

            -- try parse data as json so we can get the pipename
            local success, json_obj = pcall(vim.json.decode, data)
            if not success then
                return
            end

            -- where we given a pipe to attach to
            local pipe_name = json_obj["pipeName"]
            if not pipe_name then
                return
            end

            -- lets attach to the process as start using the lsp
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

function M.start_roslyn(buffer)
    local config = config_store.get_config().lsp.roslyn
    local solution_or_root_dir = predict_sln_file(buffer)
    run_roslyn(config.cmd_path, solution_or_root_dir)
end

return M
