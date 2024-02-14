local M = {}
local utils = require("csharp.utils")

--- @class OmnisharpMetadataSource
--- @field AssemblyName string
--- @field TypeName string
--- @field ProjectName string
--- @field VersionNumber string
--- @field Language string

--- @class OmnisharpMetadataResponse
--- @field Source string
--- @field SourceName string

--- @class GetMetadataParams
--- @field metadata_source OmnisharpMetadataSource

--- @class CreateMetadataBufferResult
--- @field buffer number
--- @field file_path string

--- @param file_path string
--- @return number|nil
local function get_buffer(file_path)
  local buffers = vim.api.nvim_list_bufs()
  for _, buffer in pairs(buffers) do
    local buffer_name = vim.api.nvim_buf_get_name(buffer)

    -- if we are looking for $metadata$ buffer, search for entire string anywhere
    -- in buffer name. On Windows nvim_buf_set_name might change the buffer name and include some stuff before.
    if buffer_name == file_path then
      return buffer
    elseif string.find(file_path, "^/%$metadata%$/.*$") then
      local normalized_buffer_name = string.gsub(buffer_name, "\\", "/")
      if string.find(normalized_buffer_name, file_path, 1, true) then
        return buffer
      end
    end
  end

  return nil
end

local function create_buffer(file_path, content)
  local buffer = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_name(buffer, file_path)
  vim.api.nvim_buf_set_option(buffer, "modifiable", true)
  vim.api.nvim_buf_set_option(buffer, "readonly", false)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, true, content)
  vim.api.nvim_buf_set_option(buffer, "modifiable", false)
  vim.api.nvim_buf_set_option(buffer, "readonly", true)
  vim.api.nvim_buf_set_option(buffer, "filetype", "cs")
  vim.api.nvim_buf_set_option(buffer, "modified", false)
  return buffer
end

--- @param metadata OmnisharpMetadataResponse
--- @return CreateMetadataBufferResult
local function create_metadata_buffer(metadata)
  -- normalize backwards slash to forwards slash
end

--- @param params GetMetadataParams
--- @return CreateMetadataBufferResult|nil
function M.execute(params)
  local buffer = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_active_clients({ buffer = buffer })
  local omnisharp_client = utils.get_omnisharp_client(buffer)

  if omnisharp_client == nil then
    vim.notify("Omnisharp not attached to buffer " .. buffer, vim.log.levels.DEBUG)
    return nil
  end

  ---@type LspRequestSyncResponse<OmnisharpMetadataResponse>
  local response = omnisharp_client.request_sync("o#/metadata", params.metadata_source, 1000, buffer)
  local metadata = response.result
  local normalized_source_name = string.gsub(metadata.SourceName, "\\", "/")
  local file_path = "/" .. normalized_source_name

  local buffer = get_buffer(file_path)

  if buffer == nil then
    metadata.Source = string.gsub(metadata.Source, "\r\n", "\n")
    local source_lines = vim.fn.split(metadata.Source, "\\n")
    buffer = create_buffer(file_path, source_lines)
  end

  return { buffer = buffer, file_path = file_path }
end

return M
