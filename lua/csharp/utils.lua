local M = {}

--- @param changes OmnisharpTextChange[]
--- @return LspTextEdit[]
function M.omnisharp_text_changes_to_text_edits(changes)
  local textEdits = {}
  for _, change in pairs(changes) do
    --- @type LspTextEdit
    local textEdit = {
      newText = change.NewText,
      range = {
        start = {
          line = change.StartLine,
          character = change.StartColumn,
        },
        ["end"] = {
          line = change.EndLine,
          character = change.EndColumn,
        },
      },
    }

    table.insert(textEdits, textEdit)
  end

  return textEdits
end

--- @param buffer number
--- @return table|nil
function M.get_omnisharp_client(buffer)
  local clients = vim.lsp.get_active_clients({ buffer = buffer })
  local omnisharp_client = nil
  for _, client in ipairs(clients) do
    if client.name == "omnisharp" then
      return client
    end
  end
end

return M
