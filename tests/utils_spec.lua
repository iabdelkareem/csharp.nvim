local utils = require("csharp.utils")
local mock = require("luassert.mock")
local spy = require("luassert.spy")
local stub = require("luassert.stub")
local match = require("luassert.match")

describe("get_omnisharp_client", function()
  local snapshot

  before_each(function()
    snapshot = assert:snapshot()
  end)

  after_each(function()
    snapshot:revert()
  end)

  it("should return the omnisharp client for the buffer, if it's active", function()
    -- Arrange
    local expected = { id = "omnisharp-client-1", name = "omnisharp" }
    stub.new(vim.lsp, "get_active_clients", function()
      return { { name = "other-client" }, expected, { name = "other-client-2" } }
    end)

    -- Act
    local result = utils.get_omnisharp_client(5)

    -- Assert
    assert.stub(vim.lsp.get_active_clients).was_called_with({ buffer = 5 })
    assert.same(expected, result)
  end)

  it("should return null if there is no omnisharp client active for the buffer", function()
    -- Arrange
    stub.new(vim.lsp, "get_active_clients", function()
      return { { name = "other-client" }, expected, { name = "other-client-2" } }
    end)

    -- Act
    local result = utils.get_omnisharp_client(5)

    -- Assert
    assert.stub(vim.lsp.get_active_clients).was_called_with({ buffer = 5 })
    assert.equals(nil, result)
  end)
end)

describe("omnisharp_text_changes_to_text_edits", function()
  it("Should convert omnisharp text change to lsp text edits", function()
    -- Arrange
    local input = {
      {
        NewText = "new test",
        StartLine = 1,
        StartColumn = 1,
        EndLine = 6,
        EndColumn = 8,
      },
      {
        NewText = "other new test",
        StartLine = 9,
        StartColumn = 2,
        EndLine = 11,
        EndColumn = 6,
      },
    }

    local expected = {
      {
        newText = "new test",
        range = {
          start = {
            line = 1,
            character = 1,
          },
          ["end"] = {
            line = 6,
            character = 8,
          },
        },
      },
      {
        newText = "other new test",
        range = {
          start = {
            line = 9,
            character = 2,
          },
          ["end"] = {
            line = 11,
            character = 6,
          },
        },
      },
    }

    -- Act
    local result = utils.omnisharp_text_changes_to_text_edits(input)

    -- Assert
    assert.are.same(expected, result)
  end)
end)
