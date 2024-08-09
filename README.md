# csharp.nvim

`csharp.nvim` is a Neovim plugin written in Lua, powered by [omnisharp-roslyn](https://github.com/OmniSharp/omnisharp-roslyn), that aims to enhance the development experience for .NET developers.

**🚧 NOTE: This plugin is in early development stage.**

## Prerequisites

- Locally Install [fd](https://github.com/sharkdp/fd#installation).

### Roslyn LSP Specific Prerequisites

If your going to use Roslyn the LSP needs to be installed manually.

1. Navigate to https://dev.azure.com/azure-public/vside/_artifacts/feed/vs-impl to see the latest package feed for `Microsoft.CodeAnalysis.LanguageServer`
2. Locate the version matching your OS + Arch and click to open it. For example, `Microsoft.CodeAnalysis.LanguageServer.linux-x64` matches Linux-based OS in x64 architecture. Note that some OS/Arch specific packages may have an extra version ahead of the "core" non specific package.
3. On the package page, click the "Download" button to begin downloading its `.nupkg`
4. Unzip the `.nupkg` file.
5. Copy the contents of `<zip root>/content/LanguageServer/<yourArch/*` to a folder of your choice (e.g., the nvim data directory `$XDG_DATA_HOME/csharp/roslyn-lsp/`)
6. To test it is working, `cd` into the aforementioned roslyn directory and invoke `dotnet Microsoft.CodeAnalysis.LanguageServer.dll --version`. It should output server's version.

## 🚀 Installation

Using lazy.nvim:

```lua
{
  "iabdelkareem/csharp.nvim",
  dependencies = {
    "williamboman/mason.nvim", -- Required, automatically installs omnisharp
    "mfussenegger/nvim-dap",
    "Tastyep/structlog.nvim", -- Optional, but highly recommended for debugging
  },
  config = function ()
      require("mason").setup() -- Mason setup must run before csharp, only if you want to use omnisharp
      require("csharp").setup()
  end
}
```

## ⚙ Configuration

```lua
-- These are the default values
{
    lsp = {
        -- Sets if you want to use omnisharp as your LSP
        omnisharp = {
        -- When set to false, csharp.nvim won't launch omnisharp automatically.
            enable = true,
            -- When set, csharp.nvim won't install omnisharp automatically. Instead, the omnisharp instance in the cmd_path will be used.
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
            -- Launches omnisharp in debug mode
            debug = false,
        }
        -- Sets if you want to use roslyn as your LSP
        roslyn = {
            -- When set to true, csharp.nvim will launch roslyn automatically.
            enable = false,
            -- Path to the roslyn LSP see 'Roslyn LSP Specific Prerequisites' above.
            cmd_path = nil,
        }
        -- The capabilities to pass to the omnisharp server
        capabilities = nil,
        -- on_attach function that'll be called when the LSP is attached to a buffer
        on_attach = nil
    },
    logging = {
        -- The minimum log level.
        level = "INFO",
    },
    dap = {
        -- When set, csharp.nvim won't launch install and debugger automatically. Instead, it'll use the debug adapter specified.
        --- @type string?
        adapter_name = nil,
    }
}
```

## 🌟 Features

### Automatically Installs and Configures LSP

The plugin will automatically install the LSP `omnisharp` and configure it for use.

_:warning: Remove omnisharp configuration from lspconfig as the plugin handles configuring and running omnisharp. If you prefer configuring omnisharp manually using lspconfig, disable this feature by setting lsp.enable = false in the configuration._

<hr>

### Effortless Debugging

The plugin will automatically install the debugger `netcoredbg` and configure it for use. The goal of this functionality is to provide an effortless debugging experience to .NET developers, all you need to do is install the plugin and execute `require("csharp").debug_project()` and the plugin will take care of the rest. To make this possible the debugger supports the following features:

- Automatically detects the executable project in the solution, or let you select if there are multiple executable projects.
- Supports [launch settings](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/environments?view=aspnetcore-8.0#lsj) to configure `environmentVariables`, `applicationUrl`, and `commandLineArgs`.
  - _Support is limited to launch profiles with `CommandName == Project`._
- Uses .NET CLI to build the debugee project.

![debugging](https://github.com/iabdelkareem/csharp.nvim/assets/13891133/d4a18920-c7b0-4960-b6d2-2cb01673a29a)

_In the illustration above, there's a solution with 3 projects, 2 of which are executable, and only one has launch settings file._

<hr>

### Run Project

Similar to the debugger, the plugin exposes the function `require("csharp").run_project()` that supports selection of an executable project, launch profile, builds and runs the project.

![run](https://github.com/iabdelkareem/csharp.nvim/assets/13891133/aa1df4e3-d3ce-43b8-a0d5-476e1b567125)

<hr>


### View & Edit User Secrets

You can use the `require("csharp").view_user_secrets()` to view and edit [user secrets](https://learn.microsoft.com/en-us/aspnet/core/security/app-secrets).
Similar to the debugger, the plugin exposes the function `require("csharp").run_project()` that supports selection of an executable project, launch profile, builds and runs the project.

<hr>

### Remove Unnecessary Using Statements (Omnisharp only)

Removes all unnecessary using statements from a document. Trigger this feature via the Command `:CsharpFixUsings` or use the Lua function below.

```lua
require("csharp").fix_usings()
```

![csharp_fix_usings](https://github.com/iabdelkareem/csharp.nvim/assets/13891133/3902ef06-b2a0-4be8-b138-222c820cf4d6)

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

<hr>

### Fix All (Omnisharp only)

This feature allows developers to efficiently resolve a specific problem across multiple instances in the codebase (e.g., a document, project, or solution) with a single command. You can run this feature using the Command `:CsharpFixAll` or the Lua function below. When the command runs, it'll launch a dropdown menu asking you to choose the scope in which you want the plugin to search for fixes before it presents the different options to you.

```lua
require("csharp").fix_all()
```

![csharp_fix_all](https://github.com/iabdelkareem/csharp.nvim/assets/13891133/5d815ce4-b9b1-40b9-a049-df1570bea100)

<hr>

### Enhanced Go-To-Definition (Decompilation Support)

Similar to [omnisharp-extended-lsp.nvim](https://github.com/Hoffs/omnisharp-extended-lsp.nvim), this feature allows developers to navigate to the definition of a symbol in the codebase with decompilation support for external code.

```lua
-- Not needed with roslyn LSP, use vim.lsp.buf.definition()
require("csharp").go_to_definition()
```

![csharp_go_to_definition](https://github.com/iabdelkareem/csharp.nvim/assets/13891133/1b8ea6fa-6d6b-4cab-a060-2123247b0d74)

<hr>

## :beetle: Reporting Bugs

1. Set debug level to TRACE via the configurations.
2. Reproduce the issue.
3. Open an issue in [GitHub](https://github.com/iabdelkareem/csharp.nvim/issues) with the following details:
   - Description of the bug.
   - How to reproduce.
   - Relevant logs, if possible.

## :heart_eyes: Contributing & Feature Suggestions

I'd love to hear your ideas and suggestions for new features! Feel free to create an issue and share your thoughts. We can't wait to discuss them and bring them to life!
