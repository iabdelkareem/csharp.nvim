# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Automatic debugger installation
- Enhanced experience to select and launch debugging target
- Commands to build and run dotnet projects

## [0.1.0] - 2024-02-14

### Added

- Configuration option to enable/disable automatic installation and launch of omnisharp.
- Option to launch omnisharp server in debug mode.
- Allow passing capabilities and on_attach to the LSP client.

### Changed

- Replaces custom logic that merges user configuration and default configuration with simple table merge.

### Fixed

- Configuration option `lsp.cmd_path` doesn't work as intended.

## [0.0.1] - 2024-02-05

### Added

- Initial plugin release [csharp.nvim](https://github.com/iabdelkareem/csharp.nvim)
- Automatic installation and launch of omnisharp
- Remove unused using statements
- Fix All
- Enhanced Go-To-Definition (Decompilation Support)
