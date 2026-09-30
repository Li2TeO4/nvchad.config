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

-- ── LSP 相关快捷操作 ──

-- harper_ls（Markdown 语法/文风检查）一键开关：
-- 关闭时停掉所有 harper_ls 客户端；再按一次重新启用
-- （vim.lsp.enable(name, true) 会给已打开的 buffer 重新挂载）
local function toggle_harper()
  local name = "harper_ls"
  if vim.lsp.is_enabled(name) then
    vim.lsp.enable(name, false)
    vim.notify("harper_ls：已关闭（Markdown 语法/文风检查静默）", vim.log.levels.INFO)
  else
    vim.lsp.enable(name, true)
    vim.notify("harper_ls：已开启", vim.log.levels.INFO)
  end
end

keymap.set("n", "<leader>H", toggle_harper, { desc = "harper_ls 语法/文风检查开关" })

-- 把某 buffer 上的 LSP 客户端摘掉（不影响其它 buffer 上的同一服务器）
local function detach_lsp(buf)
  for _, client in ipairs(vim.lsp.get_clients { bufnr = buf }) do
    vim.lsp.buf_detach_client(buf, client.id)
  end
end

-- 文档阅读模式（<leader>?）下不挂任何 LSP：
-- 给 buffer 打标记后，不仅立刻摘掉已有客户端，之后新来的（例如重新启用
-- harper_ls 触发的 FileType 重挂）也会被摘掉。
-- 注意：LspAttach 触发时客户端还在挂载过程中，此刻直接 detach 无效，
-- 需要延后一帧等挂载完成再摘。
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    if not vim.b[args.buf].doc_readonly then
      return
    end
    local buf, client_id = args.buf, args.data.client_id
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(buf) and vim.b[buf].doc_readonly then
        pcall(vim.lsp.buf_detach_client, buf, client_id)
      end
    end)
  end,
})

-- 快速查看本配置的 README 使用说明：
-- 未打开时在新标签页打开；已打开则直接聚焦对应窗口，避免重复开页
-- 打开后以只读模式查看（render-markdown 直接渲染），并且不挂 LSP
local function open_readme()
  local path = vim.fn.stdpath("config") .. "/README.md"
  local buf = vim.fn.bufnr(path)
  if buf == -1 then
    vim.cmd("tabnew " .. vim.fn.fnameescape(path))
    buf = vim.api.nvim_get_current_buf()
  else
    -- bufwinid 只搜当前标签页，用 win_findbuf 跨标签页找窗口
    local wins = vim.fn.win_findbuf(buf)
    if #wins > 0 then
      vim.api.nvim_set_current_win(wins[1])
    else
      vim.cmd "tabnew"
      vim.api.nvim_set_current_buf(buf)
    end
  end
  -- 只读模式：禁止修改，防止误编辑配置文档
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
  -- 纯阅读：不挂 LSP（避免语法/文风提示干扰阅读）
  vim.b[buf].doc_readonly = true
  detach_lsp(buf)
end

keymap.set("n", "<leader>?", open_readme, { desc = "打开配置 README（只读渲染）" })
