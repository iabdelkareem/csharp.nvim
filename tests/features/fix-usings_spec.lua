local mock = require("luassert.mock")
local spy = require("luassert.spy")
local stub = require("luassert.stub")
local match = require("luassert.match")

describe("execute", function()
  local logger = require("csharp.log")
  local utils = require("csharp.utils")
  local config = require("csharp.config")
  local snapshot

  before_each(function()
    snapshot = assert:snapshot()

    mock.new(logger)
    stub.new(vim.api, "nvim_get_current_buf", 5)
    stub.new(config, "get_config", function()
      return { lsp = { default_timeout = 500 } }
    end)
  end)

  after_each(function()
    snapshot:revert()
  end)

  it("Should log error and return if LSP client is not attached", function()
    -- Arrange
    stub.new(utils, "get_omnisharp_client", nil)
    stub.new(vim.lsp.util, "make_position_params")

    -- Act
    require("csharp.features.fix-usings").execute()

    -- Assert
    assert.stub(logger.error).was_called(1)
    assert.stub(config.get_config).was_called(2)
    assert.stub(vim.lsp.util.make_position_params).was_not_called()
  end)

  it("Should log error and return when LSP client returns error", function()
    -- Arrange
    local mock_omnisharp = {
      request_sync = spy.new(function(method, request, timeout, buffer)
        return { err = { code = 1, message = "error" } }
      end),
    }

    local apply_text_edits_spy = spy.new(vim.lsp.util.apply_text_edits)
    stub.new(utils, "get_omnisharp_client", mock_omnisharp)
    stub.new(vim.lsp.util, "make_position_params", {
      position = {
        character = 32,
        line = 7,
      },
      textDocument = {
        uri = "file:///path/to/file",
      },
    })

    -- Act
    require("csharp.features.fix-usings").execute()

    -- Assert
    assert.stub(logger.info).was_called(1)
    assert.stub(config.get_config).was_called(3)
    assert.stub(vim.lsp.util.make_position_params).was_called(1)
    assert.spy(mock_omnisharp.request_sync).was_called_with("o#/fixusings", {
      Column = 32,
      Line = 7,
      FileName = "/path/to/file",
      WantsTextChanges = true,
      ApplyTextChanges = false,
    }, 500, 5)
    assert.stub(logger.error).was_called(1)
    assert.spy(apply_text_edits_spy).was_not_called()
  end)

  it("Should log info and return when LSP client returns empty changes", function()
    -- Arrange
    local mock_omnisharp = {
      request_sync = spy.new(function(method, request, timeout, buffer)
        return { result = { Changes = {} } }
      end),
    }

    local apply_text_edits_spy = spy.new(vim.lsp.util.apply_text_edits)
    stub.new(utils, "get_omnisharp_client", mock_omnisharp)
    stub.new(vim.lsp.util, "make_position_params", {
      position = {
        character = 32,
        line = 7,
      },
      textDocument = {
        uri = "file:///path/to/file",
      },
    })

    -- Act
    require("csharp.features.fix-usings").execute()

    -- Assert
    assert.stub(logger.info).was_called(2)
    assert.stub(logger.error).was_not_called()
    assert.stub(config.get_config).was_called(3)
    assert.stub(vim.lsp.util.make_position_params).was_called(1)
    assert.spy(mock_omnisharp.request_sync).was_called_with("o#/fixusings", {
      Column = 32,
      Line = 7,
      FileName = "/path/to/file",
      WantsTextChanges = true,
      ApplyTextChanges = false,
    }, 500, 5)
    assert.spy(apply_text_edits_spy).was_not_called()
  end)

  it("Should apply text edits on the buffer", function()
    -- Arrange
    local mock_omnisharp = {
      request_sync = spy.new(function(method, request, timeout, buffer)
        return { result = { Changes = { "some-omnisharp-change" } } }
      end),
    }

    stub.new(utils, "get_omnisharp_client", mock_omnisharp)
    stub.new(vim.lsp.util, "make_position_params", {
      position = {
        character = 32,
        line = 7,
      },
      textDocument = {
        uri = "file:///path/to/file",
      },
    })
    stub.new(utils, "omnisharp_text_changes_to_text_edits", "some-lsp-change")
    stub.new(vim.lsp.util, "apply_text_edits")

    -- Act
    require("csharp.features.fix-usings").execute()

    -- Assert
    assert.stub(logger.info).was_called(2)
    assert.stub(logger.error).was_not_called()
    assert.stub(config.get_config).was_called(3)
    assert.stub(vim.lsp.util.make_position_params).was_called(1)
    assert.spy(mock_omnisharp.request_sync).was_called_with("o#/fixusings", {
      Column = 32,
      Line = 7,
      FileName = "/path/to/file",
      WantsTextChanges = true,
      ApplyTextChanges = false,
    }, 500, 5)

    assert.stub(utils.omnisharp_text_changes_to_text_edits).was_called_with({ "some-omnisharp-change" })
    assert.stub(vim.lsp.util.apply_text_edits).was_called_with("some-lsp-change", 5, "utf-8")
  end)
end)
