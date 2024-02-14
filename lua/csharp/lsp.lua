local M = {}
local config_store = require("csharp.config")

--- @return string
--- @param buffer number
local function get_root_dir(buffer)
  local file_name = vim.api.nvim_buf_get_name(buffer)

  if file_name:sub(-#"csx") == "csx" then
    return file_name:match(".*/")
  end

  local root_dir = vim.fn.systemlist("fd -e sln . " .. vim.loop.cwd())[1]

  if root_dir == nil then
    root_dir = vim.loop.cwd()
  end

  return root_dir
end

--- @return string
local function get_omnisharp_cmd()
  local config = config_store.get_config().lsp

  if config.cmd_path ~= "" then
    return config.cmd_path
  end

  local mason = require("mason-registry")
  local package = mason.get_package("omnisharp")

  if not package:is_installed() then
    package:install()
  end

  return package:get_install_path() .. "/omnisharp"
end

local function start_omnisharp(args)
  local buffer = args.buf
  local root_dir = get_root_dir(buffer)
  local omnisharp_cmd = get_omnisharp_cmd()
  local config = config_store.get_config().lsp

  local cmd = {
    omnisharp_cmd,
    "-s",
    root_dir,
    "--hostPID",
    tostring(vim.fn.getpid()),
    "--encoding",
    "utf-8",
    "--languageserver",
    "FormattingOptions:EnableEditorConfigSupport=" .. tostring(config.enable_editor_config_support),
    "FormattingOptions:OrganizeImports=" .. tostring(config.organize_imports),
    "RoslynExtensionsOptions:EnableAnalyzersSupport=" .. tostring(config.enable_analyzers_support),
    "RoslynExtensionsOptions:EnableImportCompletion=" .. tostring(config.enable_import_completion),
    "Sdk:IncludePrereleases=" .. tostring(config.include_prerelease_sdks),
    "RoslynExtensionsOptions:AnalyzeOpenDocumentsOnly=" .. tostring(config.analyze_open_documents_only),
    "MsBuild:LoadProjectsOnDemand=" .. tostring(config.load_projects_on_demand),
    "MsBuild:EnablePackageAutoRestore=" .. tostring(config.enable_package_auto_restore),
  }

  if config.debug then
    table.insert(cmd, 2, "-d")
  end

  vim.lsp.start({
    name = "omnisharp",
    cmd = cmd,
    root_dir = root_dir,
  }, {
    bufnr = buffer,
  })
end

function M.setup()
  if not config_store.get_config().lsp.enable then
    return
  end

  local lsp_group = vim.api.nvim_create_augroup("CsharpNvim", { clear = false })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "cs",
    callback = start_omnisharp,
    group = lsp_group,
    desc = "Starts omnisharp for c# files",
  })
end

if _TEST then
  M._get_root_dir = get_root_dir
  M._start_omnisharp = start_omnisharp
  M._get_omnisharp_cmd = get_omnisharp_cmd
end

return M
