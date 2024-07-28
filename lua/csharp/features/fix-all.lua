local M = {}
local utils = require("csharp.utils")
local logger = require("csharp.log")

--- @enum FixAllScope
M.scope = {
  Document = 0,
  Project = 1,
  Solution = 2,
}

--- @class FixAllItem
--- @field Id string
--- @field Message string

--- @class GetFixAllParams
--- @field scope "Document" | "Project" | "Solution" 

--- @class GetFixAllRequest
--- @field Scope FixAllScope
--- @field FileName string
--- @field Line number
--- @field Column number

--- @class GetFixAllResponse
--- @field Items FixAllItem[]

--- @class RunFixAllParams
--- @field items FixAllItem[]
--- @field scope FixAllScope
--- @field fileName string

--- @class RunFixAllChange
--- @field FileName string
--- @field ModificationType number
--- @field Changes OmnisharpTextChange[]

--- @class RunFixAllResponse
--- @field Changes RunFixAllChange[]

--- @param error LspError
--- @param response RunFixAllResponse
--- @param ctx LspHandlerContext<table>
local function handle_run_fix_all(error, response, ctx)
  --- @type LspWorkspaceEdit
  local workspace_edits = { changes = {} }

  for _, change in pairs(response.Changes) do
    if change.ModificationType ~= 0 then
      logger.error("Unsupported modification type.", { feature = "fix-all", change = change })
      goto continue
    end

    local file_uri = vim.uri_from_fname(change.FileName)
    local text_edits = utils.omnisharp_text_changes_to_text_edits(change.Changes)
    workspace_edits.changes[file_uri] = text_edits

    ::continue::
  end

  vim.lsp.util.apply_workspace_edit(workspace_edits, "utf-8")
end

--- @param client_id number
--- @param buffer number
--- @param params RunFixAllParams
local function run_fix_all(client_id, buffer, params)
  local omnisharp_client = vim.lsp.get_client_by_id(client_id)

  local request = {
    FileName = params.fileName,
    Scope = params.scope,
    FixAllFilter = params.items,
    WantsAllCodeActionOperations = true,
    WantsTextChanges = true,
    ApplyChanges = false,
  }

  logger.info("Sending runfixall request to LSP Server", { feature = "fix-all", request = request })
  omnisharp_client.request("o#/runfixall", request, handle_run_fix_all, buffer)
end

--- @param error LspError
--- @param response GetFixAllResponse
--- @param ctx LspHandlerContext<GetFixAllRequest>
local function handle_get_fix_all(error, response, ctx)
  vim.ui.select(response.Items, {
    prompt = "Fix All:",
    format_item = function(item)
      return item.Id .. ": " .. item.Message
    end,
  }, function(choice, choice_index)
    local params = { items = { choice }, scope = ctx.params.Scope, fileName = ctx.params.FileName }
    run_fix_all(ctx.client_id, ctx.bufnr, params)
  end)
end

--- @param params GetFixAllParams
function M.execute(params)

  if not M.scope[params.scope] then
    logger.error("Invalid scope. Scope must be Document, Project or Solution", { feature = "fix-all", })
    return
  end

  local buffer = vim.api.nvim_get_current_buf()
  local omnisharp_client = utils.get_omnisharp_client(buffer)

  if omnisharp_client == nil then
    vim.notify("This feature is enabled only for Omnisharp." .. buffer, vim.log.levels.ERROR)
    return
  end

  local position_params = vim.lsp.util.make_position_params(1000, "utf-8")

  --- @type GetFixAllRequest
  local request = {
    Column = position_params.position.character,
    Line = position_params.position.line,
    FileName = vim.uri_to_fname(position_params.textDocument.uri),
    Scope = params.scope,
  }

  logger.info("Sending getfixall request to LSP Server", { feature = "fix-all", request = request, })
  omnisharp_client.request("o#/getfixall", request, handle_get_fix_all, buffer)
end

function M.select_scope_and_execute()
  vim.ui.select({ "Document", "Project", "Solution" }, { prompt = "Fix All:" }, function(selected)
    if selected then
      M.execute({ scope = selected })
    end
  end)
end

return M
