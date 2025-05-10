local opts = require("dev-tools.config").get_action_opts("Debugging", "Log vars under cursor")
DevTools = opts.logger or require("dev-tools.log")

local function insert_log(action, method)
  local ctx = action.ctx
  local var = ctx.edit:get_range()[1]
  var = var ~= "" and var or ctx.word

  vim.fn.append(ctx.row + 1, ('%s("%s: ", %s)'):format(method, var:gsub('"', ""), var))
  ctx.edit:indent()
  ctx.edit:set_cursor(ctx.row + 1)
end

---@type Actions
return {
  category = "Debugging",
  filetype = { "lua" },
  actions = {
    {
      title = "Log vars under cursor",
      fn = function(action)
        insert_log(action, "DevTools.log")
      end,
      desc = "Log var/selection",
    },
    {
      title = "Log trace vars under cursor",
      fn = function(action)
        insert_log(action, "DevTools.trace")
      end,
      desc = "Log with trace",
    },
    {
      title = "Log on condition",
      fn = function(action)
        insert_log(action, "DevTools.iff")
      end,
    },
    {
      title = "Log in spec",
      fn = function(action)
        insert_log(action, "DevTools.spec")
      end,
      desc = "Log showing running spec",
    },
  },
}
