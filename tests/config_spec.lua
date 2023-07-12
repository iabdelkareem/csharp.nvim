local mock = require("luassert.mock")
local match = require("luassert.match")

describe("get_config", function()
  it("should return the config from a global variable", function()
    -- Arrange
    local expected_config = {
      lsp = {
        enable_editor_config_support = true,
        organize_imports = false,
      },
    }
    Csharp = {
      config = expected_config,
    }
    local config_store = require("csharp.config")

    -- Act
    local actual_config = config_store.get_config()

    -- Assert
    assert.are.same(expected_config, actual_config)
  end)
end)

describe("set_defaults", function()
  local config_store = require("csharp.config")
  local snapshot

  before_each(function()
    snapshot = assert:snapshot()
  end)

  after_each(function()
    snapshot:revert()
  end)

  it("should set default values for all unset settings.", function()
    -- Arrange
    local expected_config = config_store.get_defaults()
    expected_config.lsp.organize_imports = false

    -- Act
    local actual_config = config_store.set_defaults({
      lsp = {
        organize_imports = false,
      },
    })

    -- Assert
    assert.are.same(expected_config, actual_config)
  end)

  it("should return default values, if the input is null or empty.", function()
    -- Arrange
    local expected_config = config_store.get_defaults()

    for _, user_config in ipairs({ nil, {} }) do
      -- Act
      local actual_config = config_store.set_defaults(user_config)

      -- Assert
      assert.are.same(expected_config, actual_config)
    end
  end)

  it("should ignore user settings if it's the wrong type.", function()
    -- Arrange
    local expected_config = config_store.get_defaults()

    -- Act
    local actual_config = config_store.set_defaults({
      lsp = {
        organize_imports = "Invalid",
      },
    })

    -- Assert
    assert.are.same(expected_config, actual_config)
  end)
end)

describe("save", function()
  it("should save the config in global variable", function()
    -- Arrange
    local config_store = require("csharp.config")
    local expected_config = config_store.get_defaults()
    expected_config.lsp.organize_imports = false

    -- Act
    config_store.save(expected_config)

    -- Assert
    assert.are.same(expected_config, Csharp.config)
  end)
end)
