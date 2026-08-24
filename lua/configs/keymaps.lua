-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.g.mapleader = " "

local keymap = vim.keymap

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
keymap.set("n", "<leader>sv", "<C-w>v") --水平新增窗口
keymap.set("n", "<leader>sh", "<C-w>s") --垂直新增窗口

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
keymap.set("n", "<leader>q", "<CMD>:q<CR>") --退出
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

-- 终端模式：jk / <Esc> 退出 insert 模式到 terminal-normal
-- 这样在任何时候打开终端，都能用 <leader>q 直接关闭终端窗口。
-- 注意：这两个映射必须在这里随启动加载，不能放在懒加载的 dap-keymaps 里。
keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Terminal: 退出 insert 模式到 normal" })
keymap.set("t", "jk", "<C-\\><C-n>", { desc = "Terminal: jk 退出 insert 模式" })
