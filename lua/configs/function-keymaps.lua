local keymap = vim.keymap

-- 在行尾插入分号，不改变光标位置
local function append_semicolon()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_buf_set_text(0, row - 1, #line, row - 1, #line, { ";" })
  vim.api.nvim_win_set_cursor(0, { row, col })
end

vim.keymap.set("n", "<A-.>", append_semicolon, { desc = "Append semicolon at end of line" })
vim.keymap.set("i", "<A-.>", append_semicolon, { desc = "Append semicolon at end of line (insert)" })

-- 删除行尾最后一个字符，不改变光标位置
local function delete_line_end()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  if #line > 0 then
    vim.api.nvim_buf_set_text(0, row - 1, #line - 1, row - 1, #line, { "" })
    local new_len = #line - 1
    vim.api.nvim_win_set_cursor(0, { row, math.min(col, math.max(0, new_len - 1)) })
  end
end

vim.keymap.set("n", "<C-x>", delete_line_end, { desc = "Delete last char of line" })
vim.keymap.set("i", "<C-x>", delete_line_end, { desc = "Delete last char of line (insert)" })


-- ── 标记（marks）快捷删除 ──
-- 删除指定标记：按下后直接输入标记字母（a-zA-Z0-9）
keymap.set("n", "<leader>md", function()
  vim.api.nvim_echo({ { "删除哪个标记? ", "Question" } }, false, {})
  local m = vim.fn.getcharstr()
  if m:match "^%w$" then
    vim.cmd("silent delmarks " .. m)
    vim.notify("已删除标记 " .. m, vim.log.levels.INFO)
  else
    vim.notify("无效的标记字符（仅支持 a-zA-Z0-9）", vim.log.levels.WARN)
  end
end, { desc = "删除指定标记（随后按标记字母）" })

-- 删除当前行标记：数字前缀指定行数，3<leader>ml = 当前行起共 3 行（同 3yy 语义）
keymap.set("n", "<leader>ml", function()
  local first = vim.fn.line "."
  local last = math.min(first + vim.v.count1 - 1, vim.fn.line "$")
  local marks = {}
  for _, entry in ipairs(vim.fn.getmarklist(vim.api.nvim_get_current_buf())) do
    local m = entry.mark:gsub("^'", "")
    if m:match("^%w$") and entry.pos[2] >= first and entry.pos[2] <= last then
      marks[#marks + 1] = m
    end
  end
  if #marks == 0 then
    vim.notify("第 " .. first .. "-" .. last .. " 行没有可删除的标记", vim.log.levels.INFO)
  else
    vim.cmd("silent delmarks " .. table.concat(marks))
    vim.notify("已删除标记: " .. table.concat(marks, " "), vim.log.levels.INFO)
  end
end, { desc = "删除当前行标记（数字前缀=行数）" })

-- 删除全部标记（a-zA-Z0-9）
keymap.set("n", "<leader>mD", function()
  vim.cmd "silent delmarks!"
  vim.notify("已删除全部标记", vim.log.levels.INFO)
end, { desc = "删除全部标记" })
