-- 通用键位（非 DAP）的唯一出处，由 myconfig.lua 在启动时加载。
-- NvChad 默认键位由 lua/mappings.lua 中的 require("nvchad.mappings") 加载；
-- DAP 键位见 lua/configs/dap-keymaps.lua（随 nvim-dap 懒加载）。

local keymap = vim.keymap

-- 命令模式快捷入口 / 快速保存
keymap.set("n", ";", ":", { desc = "CMD enter command mode" })
keymap.set({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- 输入模式
keymap.set("i", "jk", "<ESC>")
keymap.set("i", "<C-h>", "<Left>")
keymap.set("i", "<C-l>", "<Right>")
keymap.set("i", "<C-j>", "<Down>")
keymap.set("i", "<C-k>", "<Up>")
keymap.set("i", "<C-o>", "<Esc>o")

-- 视觉模式
-- 单行或多行
keymap.set("v", "J", ":m '>+1<CR>gv=gv")
keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- 正常模式
-- 窗口
keymap.set("n", "<leader>sv", "<C-w>v") --左右分屏（垂直分割）
keymap.set("n", "<leader>sh", "<C-w>s") --上下分屏（水平分割）

keymap.set("n", "<C-h>", "<C-w>h")
keymap.set("n", "<C-l>", "<C-w>l")
keymap.set("n", "<C-j>", "<C-w>j")
keymap.set("n", "<C-k>", "<C-w>k")
-- 不覆盖 <C-u>：Neovim 没有 <C-w>u 命令，保留默认的半页上滚

keymap.set({ "n", "x" }, "wq", "<CMD>:wq<CR>")
keymap.set({ "n", "x" }, "<leader>q", "<CMD>:q<CR>")
keymap.set({ "n", "x" }, "ww", "<CMD>:w<CR>")
keymap.set({ "n", "x", "o" }, "<S-H>", "^", { desc = "Start of line" })
keymap.set({ "n", "x", "o" }, "<S-L>", "$", { desc = "End of line" })
-- 添加关闭当前标签页 (Buffer) 的快捷键
keymap.set("n", "<C-t>", function()
  require("nvchad.tabufline").close_buffer()
end, { desc = "Close current tab" })

keymap.set("n", "<leader>Q", "<CMD>:q!<CR>") --强制退出
keymap.set("n", "<leader>wq", "<CMD>:wq<CR>") --保存并退出
keymap.set("n", "<leader>ww", "<CMD>:w<CR>") --保存
keymap.set("n", "<leader>W", "<CMD>:w!<CR>") --强制保存
keymap.set("n", "<leader>to", "<CMD>:tabnew<CR>") --打开新标签页
keymap.set("n", "<leader>tx", "<CMD>:tabclose<CR>") --关闭当前标签页
keymap.set("n", "A-z", "<CMD>set wrap!<CR>", { desc = "Toggle line wrap" })
--取消高亮
keymap.set("n", "<leader>nh", ":nohl<CR>")

--打开Lazy
keymap.set("n", "<leader>L", "<CMD>Lazy<CR>", { desc = "[Lazy] Open Lazy.nvim" })

--打开nvim-tree
keymap.set("n", "<leader>e", "<CMD>:NvimTreeToggle<CR>")

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

-- 终端模式：jk / <Esc> 退出 insert 模式到 terminal-normal
-- 这样在任何时候打开终端，都能用 <leader>q 直接关闭终端窗口。
-- 注意：这两个映射必须在这里随启动加载，不能放在懒加载的 dap-keymaps 里。
keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Terminal: 退出 insert 模式到 normal" })
keymap.set("t", "jk", "<C-\\><C-n>", { desc = "Terminal: jk 退出 insert 模式" })
