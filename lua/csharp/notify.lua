local M = {}

---@param level string
---@param message string
function M.notify(level, message)
  vim.schedule(function()
    vim.notify(message, vim.log.levels[level], nil)
  end)
end

---@param message string
function M.info(message)
  M.notify("INFO", message)
end

---@param message string
function M.warn(message)
  M.notify("WARN", message)
end

---@param message string
function M.error(message)
  M.notify("ERROR", message)
end

return M
