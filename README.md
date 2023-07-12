# csharp.nvim

`csharp.nvim` is a Neovim plugin written in Lua, powered by [omnisharp-roslyn](https://github.com/OmniSharp/omnisharp-roslyn), that aims to enhance the development experience for .NET developers.

##### NOTE

_This plugin is in early development stage._

## Prerequisites

- Install [fd](https://github.com/sharkdp/fd#installation) locally.

## Installation

Using lazy.nvim:

```lua
{
  "iabdelkareem/csharp.nvim",
  dependencies = {
    "williamboman/mason.nvim", -- Required, automatically installs omnisharp
    "Tastyep/structlog.nvim", -- Optional, but highly recommended for debugging
  },
  config = function ()
      require("csharp").setup()
  end
}
```

## Configuration

```lua
-- These are the default values
{
    lsp = {
        -- When set to true, csharp.nvim won't install omnisharp automatically and use it via mason.
        -- Instead, the omnisharp instance in the cmd_path will be used.
        cmd_path = nil,
        -- The default timeout when communicating with omnisharp
        default_timeout = 1000,
        -- Settings that'll be passed to the omnisharp server
        enable_editor_config_support = true,
        organize_imports = true,
        load_projects_on_demand = false,
        enable_analyzers_support = true,
        enable_import_completion = true,
        include_prerelease_sdks = true,
        analyze_open_documents_only = false,
        enable_package_auto_restore = true,
    },
    logging = {
        -- The minimum log level.
        level = "INFO",
    },
}
```

## Features

### Remove Unnecessary Using Statements

Removes all unnecessary using statements from a document. Trigger this feature via the Command `:CsharpFixUsings` or use the Lua function below.

```lua
require("csharp").fix_usings()
```

_TIP: You can run this feature automatically before a buffer is saved._

```lua
-- Listen to LSP Attach
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function (args)
    local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = augroup,
      buffer = args.buf,
      callback = function()

        -- Format the code before you run fix usings
        vim.lsp.buf.format({ timeout = 1000, async = false })

        -- If the file is C# then run fix usings
        if vim.bo[0].filetype == "cs" then
          require("csharp").fix_usings()
        end
      end,
    })
  end
})
```

### Fix All

This feature allows developers to efficiently resolve a specific problem across multiple instances in the codebase (e.g., a document, project, or solution) with a single command. You can run this feature using the Command `:CsharpFixAll` or the Lua function below. When the command runs, it'll launch a dropdown menu asking you to choose the scope in which you want the plugin to search for fixes before it presents the different options to you.

```lua
require("csharp").fix_all()
```

### Enhanced Go-To-Definition (Decompilation Support)

Similar to [omnisharp-extended-lsp.nvim](https://github.com/Hoffs/omnisharp-extended-lsp.nvim), this feature allows developers to navigate to the definition of a symbol in the codebase with decompilation support for external code.

```lua
require("csharp").go_to_definition()
```

## TODO

- [ ] Setup Debugger
- [ ] Solution Explorer
- [ ] Switching Solution
- [ ] Support Source Generator
- [ ] Support Razor
