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

-- ── 绝对行号跳转：复用标记键（数字在前，走 Vim 原生 count）──
--   42`  → 跳到第 42 行第 0 列（对应 ` 的「精确列」语义）
--   42'  → 跳到第 42 行行首非空字符（对应 ' 的「行首」语义）
-- 不带数字时完全保持原标记跳转：`a / 'a / `' / '' / '. / '< / '[ …
-- 数字标记（'0 – '9）按需求砍掉：在键后输入数字会提示改成「数字在前」的写法。
local function jump_line_or_mark(key)
  local n = vim.v.count

  -- 有数字前缀 → 跳行
  if n > 0 then
    n = math.max(1, math.min(n, vim.fn.line "$"))
    if key == "'" then
      vim.cmd("normal! " .. n .. "G^") -- 行首非空
    else
      vim.api.nvim_win_set_cursor(0, { n, 0 }) -- 列 0
    end
    return
  end

  -- 无数字 → 按原样跳标记：读一个字符交给 :normal! 执行
  local c = vim.fn.getcharstr()
  if c == "" or c == "\27" then
    return -- ESC / 无输入：取消
  end
  if c:match "^%d$" then
    vim.notify('行号请写在按键前面，例如 42' .. key, vim.log.levels.WARN)
    return
  end
  pcall(vim.cmd, "normal! " .. key .. c)
end

keymap.set("n", "`", function()
  jump_line_or_mark "`"
end, { desc = "跳转：42` 跳行 / `a 跳标记" })

keymap.set("n", "'", function()
  jump_line_or_mark "'"
end, { desc = "跳转：42' 跳行首 / 'a 跳标记" })

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

-- 诊断提示一键静音（黄色警告 / 紫色提示 / 绿色信息）
--
-- 只改「显示」：把以下三项的 severity 下限提到 ERROR，于是黄色(WARN)、紫色(HINT)、
-- 绿色(INFO) 的行内文字、下划线和行号旁标记都不再渲染，只留红色 ERROR。
-- LSP 服务与诊断数据完全不受影响：[d/]d 跳转、<leader>ds 诊断列表、<C-w>d 悬浮详情照常可用。
-- 再按一次恢复原样（恢复的是切换前保存的配置，因此 NvChad 的图标/前缀都保留）。
local diag_quiet = false
local diag_saved = nil

local function with_min_severity(orig, min_sev)
  if orig == false then
    return false -- 原本就关闭，保持关闭
  end
  local base = type(orig) == "table" and orig or {}
  return vim.tbl_extend("force", base, { severity = { min = min_sev } })
end

local function toggle_diagnostic_display()
  local x = vim.diagnostic.severity

  if not diag_quiet then
    local cur = vim.diagnostic.config() or {}
    diag_saved = {
      virtual_text = cur.virtual_text,
      signs = cur.signs,
      underline = cur.underline,
    }
    vim.diagnostic.config({
      virtual_text = with_min_severity(diag_saved.virtual_text, x.ERROR),
      signs = with_min_severity(diag_saved.signs, x.ERROR),
      underline = with_min_severity(diag_saved.underline, x.ERROR),
    })
    vim.notify("已静音诊断提示：只保留红色 ERROR（LSP 服务照常运行）", vim.log.levels.INFO)
  else
    vim.diagnostic.config({
      virtual_text = diag_saved.virtual_text,
      signs = diag_saved.signs,
      underline = diag_saved.underline,
    })
    vim.notify("已恢复诊断提示（黄色警告 / 紫色提示重新显示）", vim.log.levels.INFO)
  end

  diag_quiet = not diag_quiet
end

keymap.set("n", "<leader>ls", toggle_diagnostic_display, { desc = "静音诊断提示（黄/紫，保留 ERROR）" })

-- 把某 buffer 上的 LSP 客户端摘掉（不影响其它 buffer 上的同一服务器）
local function detach_lsp(buf)
  for _, client in ipairs(vim.lsp.get_clients { bufnr = buf }) do
    vim.lsp.buf_detach_client(buf, client.id)
  end
end

-- 清空某 buffer 的所有「提示」：
--   · 诊断（黄/紫/红行内文字、下划线、行号旁图标）
--   · inlay hints（行内参数/类型提示）
-- 注意：reset 自身会再触发 DiagnosticChanged，所以用防重入标记避免死循环；
-- 标记释放时若仍有残留则再清一次（自愈）。
local clearing = {}

local function clear_hints_now(buf)
  if clearing[buf] then
    return
  end
  clearing[buf] = true
  pcall(vim.diagnostic.reset, nil, buf)
  pcall(function()
    vim.lsp.inlay_hint.enable(false, { bufnr = buf })
  end)
  vim.defer_fn(function()
    clearing[buf] = nil
    if
      vim.api.nvim_buf_is_valid(buf)
      and vim.b[buf].doc_readonly
      and #vim.diagnostic.get(buf) > 0
    then
      clear_hints_now(buf)
    end
  end, 100)
end

-- 阅读模式下任何后到的诊断都立刻清掉（客户端摘除是异步的，推送可能在摘除之后才到）
vim.api.nvim_create_autocmd("DiagnosticChanged", {
  callback = function(args)
    if vim.b[args.buf].doc_readonly then
      clear_hints_now(args.buf)
    end
  end,
})

-- 打开 / 重新聚焦阅读窗口时也主动清一次（并延迟补几轮，覆盖慢速推送）
local function clear_hints(buf)
  clear_hints_now(buf)
  for i = 1, 4 do
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(buf) and vim.b[buf].doc_readonly then
        clear_hints_now(buf)
      end
    end, 200 * i)
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
        clear_hints(buf) -- 客户端可能已经推了诊断，摘掉后再清一次
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
  -- 纯阅读：不挂 LSP，并清空所有提示（诊断 + inlay hints）
  vim.b[buf].doc_readonly = true
  detach_lsp(buf)
  clear_hints(buf)
end

keymap.set("n", "<leader>?", open_readme, { desc = "打开配置 README（只读渲染）" })
