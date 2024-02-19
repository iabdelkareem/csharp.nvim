--- @meta
--- @class OmnisharpPoint
--- @field Line number
--- @field Column number

--- @class OmnisharpRange
--- @field Start OmnisharpPoint
--- @field End OmnisharpPoint
---
--- @class OmnisharpLocation
--- @field FileName string
--- @field Range OmnisharpRange

--- @class OmnisharpTextChange
--- @field NewText string
--- @field StartLine number
--- @field StartColumn number
--- @field EndLine number
--- @field EndColumn number

--- @class LspTextEdit
--- @field newText string
--- @field start LspRange
--- @field end LspRange

--- @class LspDefinition
--- @field uri string
--- @field start LspRange
--- @field end LspRange
--
--- @class LspRange
--- @field line number
--- @field character number

--- @class LspError
--- @field message string
--- @field code number
--- @field data any|nil

--- @class LspHandlerContext<T>: {["params"]: T, ["client_id"]: number, ["bufnr"]: number, ["method"]: string}

--- @class LspRequestSyncResponse<T>: {["result"]: T, ["err"]: LspError|nil}

--- @class LspWorkspaceEdit
--- @field changes table<string, LspTextEdit[]>
