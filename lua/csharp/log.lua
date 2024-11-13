local queue = {}
local M = {}

---Queue a log message until logging is initialized
---@param level string
---@param message string
---@param data table?
function M.queue(level, message, data)
  table.insert(queue, {level = level, message = message, data = data})
end

---@param level string
---@param message string
---@param data table?
function M.log(level, message, data)
  local config = require("csharp.config").get_config()
  if config == nil then
    M.queue(level, message, data)
    return
  end
  config = config.logging
  local logger = require("structlog").get_logger("csharp_logger")
  if logger == nil or vim.log.levels[level] < vim.log.levels[config.level] then
    return
  end

  logger:log(vim.log.levels[level] + 1, message, data)
end

---@param message string
---@param data table?
function M.trace(message, data)
  M.log("TRACE", message, data)
end

---@param message string
---@param data table?
function M.debug(message, data)
  M.log("DEBUG", message, data)
end

---@param message string
---@param data table?
function M.info(message, data)
  M.log("INFO", message, data)
end

---@param message string
---@param data table?
function M.warn(message, data)
  M.log("WARN", message, data)
end

---@param message string
---@param data table?
function M.error(message, data)
  M.log("ERROR", message, data)
end

function M.setup()
  local ok, structlog = pcall(require, "structlog")

  if not ok then
    vim.notify("csharp.nvim: structlog.nvim dependency is not installed. This won't prevent the plugin from working, but it's recommended to install it.", vim.log.levels.WARN)
    return
  end

  structlog.configure({
    csharp_logger = {
      pipelines = {
        {
          level = structlog.level.TRACE,
          processors = {
            structlog.processors.StackWriter({ "line", "file" }, { max_parents = 3 }),
            structlog.processors.Timestamper("%H:%M:%S"),
            function(log)
              log["buffer"] = vim.api.nvim_get_current_buf()
              return log
            end,
          },
          formatter = structlog.formatters.Format( --
            "%s [%s] %s: %-30s buffer=%s",
            { "timestamp", "level", "logger_name", "msg", "buffer" }
          ),
          sink = structlog.sinks.File(vim.fn.stdpath("log") .. "/csharp.log"),
        },
      },
    },
  })

  for _, msg in pairs(queue) do 
    M.log(msg.level, msg.message, msg.data)
  end
end

return M
