---@class Edit
---@field get_node fun(self: Ctx, type: string, node?: TSNode|nil, predicate?: fun(node: TSNode): boolean| nil): TSNode|nil, table <number, number, number, number>|nil
---@field get_lines fun(self: Ctx, l_start?: number, l_end?: number): string[]
---@field set_lines fun(self: Ctx, lines: string[], l_start?: number, l_end?: number)
---@field get_range fun(self: Ctx): string[]
---@field set_range fun(self: Ctx, lines: string[])

---@type Edit
local M = {}

---Traverses up the tree to find the first node of the specified type
---@param type string
---@param node? TSNode|nil
---@param predicate? fun(node: TSNode): boolean| nil
---@return TSNode|nil
---@return table <number, number, number, number>|nil
M.get_node = function(_, type, node, predicate)
  local ts = vim.treesitter
  predicate = predicate or function()
    return true
  end

  node = node or ts.get_node()
  if not node then return end

  if node:type() == type and predicate(node) then return node, { node:range() } end
  if node:type() == "chunk" then return end

  return M.get_node(_, type, node:parent(), predicate)
end

---Get the lines in the buffer
---@param ctx Ctx
---@param l_start? number
---@param l_end? number
---@return string[]
M.get_lines = function(ctx, l_start, l_end)
  return vim.api.nvim_buf_get_lines(ctx.buf, l_start or ctx.range.rc[1], l_end or ctx.range.rc[3] + 1, false)
end

---Set lines in the buffer
---@param ctx Ctx
---@param lines string[]
---@param l_start? number
---@param l_end? number
M.set_lines = function(ctx, lines, l_start, l_end)
  vim.api.nvim_buf_set_lines(ctx.buf, l_start or ctx.range.rc[1], l_end or ctx.range.rc[3] + 1, false, lines)
end

---Get the lines in the range of the buffer
---@param ctx Ctx
M.get_range = function(ctx)
  return vim.api.nvim_buf_get_text(ctx.buf, ctx.range.rc[1], ctx.range.rc[2], ctx.range.rc[3], ctx.range.rc[4], {})
end

---Set the lines range of the buffer
---@param ctx Ctx
---@param lines string[]
M.set_range = function(ctx, lines)
  vim.api.nvim_buf_set_text(ctx.buf, ctx.range.rc[1], ctx.range.rc[2], ctx.range.rc[3], ctx.range.rc[4], lines)
end

return M
