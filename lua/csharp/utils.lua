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
  local clients = vim.lsp.get_clients({ buffer = buffer })

  for _, client in ipairs(clients) do
    if client.name == "omnisharp" then
      return client
    end
  end
end

function M.run_async(fn)
  local co = coroutine.create(fn)
  local success, result = coroutine.resume(co)

  if not success then
    require("csharp.log").error("Error has occurred!",
      { feature = "run-async", error_message = result, stack_trace = debug.traceback(co) })
  end
end

return M
