local M = {}
local utils = require("csharp.utils")
local get_metadata = require("csharp.features.get-metadata").execute

--- @class OmnisharpDefinition
--- @field Location OmnisharpLocation
--- @field MetadataSource OmnisharpMetadataSource?

--- @class GoToDefinitionResponse
--- @field Definitions OmnisharpDefinition[]?

--- @param definition OmnisharpDefinition
--- @return LspDefinition
local function omnisharp_definition_to_lsp(definition)
  return {
    uri = vim.uri_from_fname(definition.Location.FileName),
    range = {
      start = {
        line = definition.Location.Range.Start.Line,
        character = definition.Location.Range.Start.Column,
      },
      ["end"] = {
        line = definition.Location.Range.End.Line,
        character = definition.Location.Range.End.Column,
      },
    },
  }
end

--- @param error LspError?
--- @param response GoToDefinitionResponse?
--- @param ctx LspHandlerContext<GetFixAllRequest>
local function handle(error, response, ctx)
  if error ~= nil then
    -- Log Error
    return
  end

  if response == nil then
    -- Log Error
    return
  end

  if vim.tbl_isempty(response.Definitions) then
    return
  end

  local omnisharp_client = vim.lsp.get_client_by_id(ctx.client_id)

  local lsp_definitions = {}
  for _, definition in pairs(response.Definitions) do
    local lsp_definition = omnisharp_definition_to_lsp(definition)
    if definition.MetadataSource ~= nil then
      local metadata = get_metadata({ metadata_source = definition.MetadataSource })
      lsp_definition.uri = vim.uri_from_fname(metadata.file_path)
    end
    table.insert(lsp_definitions, lsp_definition)
  end

  vim.lsp.handlers["textDocument/definition"](error, lsp_definitions, ctx)
end

function M.execute()
  local buffer = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_active_clients({ buffer = buffer })
  local omnisharp_client = utils.get_omnisharp_client(buffer)

  if omnisharp_client == nil then
    vim.notify("Omnisharp not attached to buffer " .. buffer, vim.log.levels.DEBUG)
    return
  end

  local position_params = vim.lsp.util.make_position_params(0, "utf-8")

  local request = {
    Column = position_params.position.character,
    Line = position_params.position.line,
    FileName = vim.uri_to_fname(position_params.textDocument.uri),
    WantMetadata = true,
  }

  if string.find(request.FileName, "metadata") then
    request.FileName = string.sub(request.FileName, 2)
  end

  omnisharp_client.request("o#/v2/gotodefinition", request, handle, buffer)
end

return M
