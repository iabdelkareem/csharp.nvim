local M = {}
local config_store = require("csharp.config")

function M.setup()
    local config = config_store.get_config().lsp
    if not config.omnisharp.enable and not config.roslyn.enable then
        return
    end

    local lsp_group = vim.api.nvim_create_augroup("CsharpNvim", { clear = false })

    vim.api.nvim_create_autocmd("FileType", {
        pattern = "cs",
        callback = function(args)
            if config.omnisharp.enable then
                require("csharp.modules.lsp.omnisharp").start_omnisharp(args.buf)
            else
                require("csharp.modules.lsp.roslyn").start_roslyn(args.buf)
            end
        end,
        group = lsp_group,
        desc = "Starts LSP for c# files",
    })
end

return M
