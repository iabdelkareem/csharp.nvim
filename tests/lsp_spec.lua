local mock = require("luassert.mock")
local spy = require("luassert.spy")
local stub = require("luassert.stub")
local match = require("luassert.match")
local config = require("csharp.config")
local mason = require("mason-registry")
local lsp

describe("get_root_dir", function()
  before_each(function()
    _G._TEST = true
    snapshot = assert:snapshot()
    lsp = require("csharp.modules.lsp")
  end)

  after_each(function()
    snapshot:revert()
  end)

  it("should return the directory of the buffer, when the file is csx", function()
    -- Arrange
    stub.new(vim.api, "nvim_buf_get_name", function(buf_nr)
      return "/path/to/file.csx"
    end)

    -- Act
    local result = lsp._get_root_dir(5)

    -- Assert
    assert.stub(vim.api.nvim_buf_get_name).was_called_with(5)
    assert.same("/path/to/", result)
  end)

  it("should return the path to the first solution in the current working directory, if exists", function()
    -- Arrange
    stub.new(vim.api, "nvim_buf_get_name", function(buf_nr)
      return "/path/to/some/repo/and/nested/file.cs"
    end)

    stub.new(vim.fn, "systemlist", function(cmd)
      return {
        "/path/to/some/repo/solution.sln",
        "/path/to/some/repo/solution2.sln",
      }
    end)

    stub.new(vim.loop, "cwd", function()
      return "/path/to/some/repo"
    end)

    -- Act
    local result = lsp._get_root_dir(5)

    -- Assert
    assert.stub(vim.api.nvim_buf_get_name).was_called_with(5)
    assert.stub(vim.fn.systemlist).was_called_with("fd -e sln . /path/to/some/repo")
    assert.stub(vim.loop.cwd).was_called()
    assert.same("/path/to/some/repo/solution.sln", result)
  end)

  it("should return vim root directory, when no solutions exist", function()
    -- Arrange
    stub.new(vim.api, "nvim_buf_get_name", function(buf_nr)
      return "/path/to/some/repo/and/nested/file.cs"
    end)

    stub.new(vim.fn, "systemlist", function(cmd)
      return {}
    end)

    stub.new(vim.loop, "cwd", function()
      return "/path/to/some/repo"
    end)

    -- Act
    local result = lsp._get_root_dir(5)

    -- Assert
    assert.stub(vim.api.nvim_buf_get_name).was_called_with(5)
    assert.stub(vim.fn.systemlist).was_called_with("fd -e sln . /path/to/some/repo")
    assert.stub(vim.loop.cwd).was_called()
    assert.same("/path/to/some/repo", result)
  end)
end)

describe("get_omnisharp_cmd", function()
  before_each(function()
    _G._TEST = true
    snapshot = assert:snapshot()
    lsp = require("csharp.modules.lsp")
  end)

  after_each(function()
    snapshot:revert()
  end)

  it("should return the path to the omnisharp executable from the config, if it's set", function()
    -- Arrange
    stub.new(config, "get_config", function()
      return {
        lsp = {
          cmd_path = "/path/to/omnisharp",
        },
      }
    end)

    -- Act
    local result = lsp._get_omnisharp_cmd()

    -- Assert
    assert.stub(config.get_config).was_called()
    assert.same("/path/to/omnisharp", result)
  end)

  it("should return the path to the omnisharp executable from the config, if it's set", function()
    -- Arrange
    stub.new(config, "get_config", function()
      return {
        lsp = {
          cmd_path = "/path/to/omnisharp",
        },
      }
    end)

    -- Act
    local result = lsp._get_omnisharp_cmd()

    -- Assert
    assert.stub(config.get_config).was_called()
    assert.same("/path/to/omnisharp", result)
  end)

  it("should install omnisharp if it's not installed", function()
    -- Arrange
    stub.new(config, "get_config", function()
      return {
        lsp = {
          cmd_path = nil,
        },
      }
    end)

    local package_metatable = {
      __index = {
        get_package = function(package_name) end,
        is_installed = function(_)
          return true
        end,
        install = function() end,
        get_install_path = function()
          return "/path/to/omnisharp"
        end,
      },
    }
    local package = {}
    setmetatable(package, package_metatable)

    stub.new(mason, "get_package", function(package_name)
      return package
    end)

    -- Act
    local result = lsp._get_omnisharp_cmd()

    -- Assert
    assert.stub(config.get_config).was_called()
    assert.same("/path/to/omnisharp", result)
  end)
end)
