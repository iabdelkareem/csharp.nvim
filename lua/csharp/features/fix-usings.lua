local M = {}
local config_store = require("csharp.config")
local utils = require("csharp.utils")
local logger = require("csharp.log")

local function handle(response, buffer)
  if response.err ~= nil then
    logger.error("LSP client responded with error", { feature = "fix-usings", error = response.err })
    return
  end

  if vim.tbl_isempty(response.result.Changes) then
    logger.info("No changes found", { feature = "fix-usings" })
    return
  end

  local text_edits = utils.omnisharp_text_changes_to_text_edits(response.result.Changes)
  vim.lsp.util.apply_text_edits(text_edits, buffer, "utf-8")
  logger.info("Applied changes.", { feature = "fix-usings" })
end

function M.execute()
  local buffer = vim.api.nvim_get_current_buf()
  local omnisharp_client = utils.get_omnisharp_client(buffer)
  local config = config_store.get_config()

  if omnisharp_client == nil then
    vim.notify("This feature is enabled only for Omnisharp." .. buffer, vim.log.levels.ERROR)
    return
  end

  local position_params = vim.lsp.util.make_position_params(0, "utf-8")

  local request = {
    Column = position_params.position.character,
    Line = position_params.position.line,
    FileName = vim.uri_to_fname(position_params.textDocument.uri),
    WantsTextChanges = true,
    ApplyTextChanges = false,
  }

  logger.info("Sending request to LSP Server", { feature = "fix-usings" })
  local response = omnisharp_client.request_sync("o#/fixusings", request, config.lsp.default_timeout, buffer)
  handle(response, buffer)
end

return M
