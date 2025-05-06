local Config = require("dev-tools.config")
local Logger = require("dev-tools.logger")
local Utils = require("dev-tools.utils")

---@class Actions
---@field category string|nil - category of actions
---@field filetype string[]|nil - filetype to limit the actions category to
---@field actions Action[] - list of actions

---@class Action
---@field title string - title of the action
---@field category string|nil - category of the action
---@field filter string|nil|fun(ctx: Ctx): boolean - filter to limit the action to
---@field filetype string[]|nil - filetype to limit the action to
---@field keymap string|nil - acton keymap
---@field fn fun(action: ActionCtx) - function to execute the action

---@class ActionCtx: Action
---@field ctx Ctx - context of the action

local M = {}

local function pcall_wrap(title, fn)
  return function(...)
    local status, error = xpcall(fn, debug.traceback, ...)
    if not status then return Logger.error("Error executing " .. title .. ":\n" .. error, 2) end
  end
end

local validate_action = function(action)
  local status, error = pcall(function()
    vim.validate("title", action.title, { "string" })
    vim.validate("category", action.category, { "string" }, true)
    vim.validate("filter", action.filter, { "function", "string" }, true)
    vim.validate("filetype", action.filetype, "table", true)
    vim.validate("keymap", action.keymap, "string", true)
    vim.validate("fn", action.fn, "function")
  end)

  if not status then return Logger.error("Invalid action: " .. error, 2) end

  return true
end

local function make_action(module, action)
  if not validate_action(action) then return end

  action = vim.deepcopy(action)

  action.category = action.category or module.category
  action.command = action.title:gsub("%W", "_"):lower()
  action._title = action.title -- original title
  action.title = action.title .. " (" .. action.category:lower() .. ")" -- formatted title

  action.fn = pcall_wrap(action.title, action.fn)

  action.filter = action.filter or module.filter
  action.filetype = action.filetype or module.filetype

  action.filter = not (action.filter or action.filetype) and ".*" or action.filter

  return action
end

M.built_in = function()
  local builtin = Config.builtin_actions
  if builtin.exclude == true then return {} end

  local actions_path = Utils.get_plugin_path("actions")

  local modules = vim
    .iter(vim.fn.glob(actions_path .. "/**/*", false, true))
    :filter(function(path)
      return not path:find("init.lua") and vim.fn.isdirectory(path) ~= 1
    end)
    :totable()

  return vim.iter(modules):fold({}, function(acc, path)
    local module = loadfile(path)()
    if not module or not type(module.actions) == "table" then return acc end

    vim.iter(module.actions):each(function(action)
      local tags = { action.category or module.category, action.title, unpack(action.filetype or {}) }

      if vim.tbl_contains(builtin.exclude or {}, function(v)
        return vim.tbl_contains(tags, v)
      end, { predicate = true }) then return end

      if
        (builtin.include == nil or #builtin.include == 0)
        or vim.tbl_contains(builtin.include, function(v)
          return vim.tbl_contains(tags, v)
        end, { predicate = true })
      then
        acc = vim.list_extend(acc, { make_action(module, action) })
      end
    end)

    return acc
  end)
end

M.custom = function()
  return vim.iter(Config.actions):fold({}, function(acc, action)
    return vim.list_extend(acc, { make_action({ category = "Custom" }, action) })
  end)
end

M.register = function(action)
  local cache = Config.cache

  Config.actions = vim.list_extend(Config.actions, { action })
  require("dev-tools.lsp"):code_actions()

  Config.cache = cache
end

return M
