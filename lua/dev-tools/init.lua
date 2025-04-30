local Actions = require("dev-tools.actions")
local Config = require("dev-tools.config")
local Lsp = require("dev-tools.lsp")

local M = {}

local function init()
  vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
    group = vim.api.nvim_create_augroup("Dev-tools filetype setup", { clear = true }),
    callback = function(ev)
      Lsp.start(ev.buf, ev.match)
    end,
  })
end

---@param action Action
M.register_action = function(action)
  Actions.register(action)
end

---@param action Config
M.setup = function(opts)
  Config.setup(opts)
  init()
end

return M
