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
function M.get_sln_directory(buffer)
    return vim.fs.root(buffer, function(name)
        return name:match("%.sln$") ~= nil
    end)
end

---@param buffer integer
---@return string[]?
function M.get_all_sln_files(buffer)
    local sln_dir = M.get_sln_directory(buffer)
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
function M.predict_sln_file(buffer)
    local sln_files = M.get_all_sln_files(buffer)

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

function M.setup()
  local config = config_store.get_config().lsp
  if not config.enable then
    return
  end

  local lsp_group = vim.api.nvim_create_augroup("CsharpNvim", { clear = false })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "cs",
    callback = function(args)
      local solution_or_root_dir = M.predict_sln_file(args.buf)
      if config.use_omnisharp then
        require("csharp.modules.lsp.omnisharp").start_omnisharp(args.buf, solution_or_root_dir)
      else
        require("csharp.modules.lsp.roslyn").start_roslyn(solution_or_root_dir, config.cmd_path)
      end
    end,
    group = lsp_group,
    desc = "Starts omnisharp for c# files",
  })
end

if _TEST then
  M._get_root_dir = get_root_dir
  M._start_omnisharp = require("csharp.modules.lsp.omnisharp")._start_omnisharp
  M._get_omnisharp_cmd = require("csharp.modules.lsp.omnisharp")._get_omnisharp_cmd
end

return M
