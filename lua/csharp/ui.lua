local M = {}

---@async
---@generic T: any
---@param items T[] Arbitrary items
---@param opts table Additional options
---     - prompt (string|nil)
---               Text of the prompt. Defaults to `Select one of:`
---     - format_item (function item -> text)
---               Function to format an
---               individual item from `items`. Defaults to `tostring`.
---     - kind (string|nil)
---               Arbitrary hint string indicating the item shape.
---               Plugins reimplementing `vim.ui.select` may wish to
---               use this to infer the structure or semantics of
---               `items`, or the context in which select() was called.
--- @return T
function M.select_sync(items, opts)
  local co = assert(coroutine.running())
  vim.schedule(function()
    vim.ui.select(items, opts, function(selected)
      coroutine.resume(co, selected)
    end)
  end)

  return coroutine.yield()
end

return M
