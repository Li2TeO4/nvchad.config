-- ~/.config/nvim/lua/configs/dap-keymaps.lua

local map = vim.keymap.set
local dap = require("dap")
local dapui = require("dapui")

-- 执行控制（F 键）
map("n", "<F5>",  dap.continue,          { desc = "DAP: Continue" })
map("n", "<F9>",  dap.toggle_breakpoint, { desc = "DAP: Toggle Breakpoint" })
map("n", "<F10>", dap.step_over,         { desc = "DAP: Step Over" })
map("n", "<F11>", dap.step_into,         { desc = "DAP: Step Into" })
map("n", "<F12>", dap.step_out,          { desc = "DAP: Step Out" })

-- <leader>d 前缀
map("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP: Toggle Breakpoint" })
map("n", "<leader>dB", function()
  dap.set_breakpoint(vim.fn.input("断点条件: "))
end, { desc = "DAP: Conditional Breakpoint" })
map("n", "<leader>dl", function()
  dap.set_breakpoint(nil, nil, vim.fn.input("日志消息: "))
end, { desc = "DAP: Log Point" })

map("n", "<leader>dc", dap.continue,         { desc = "DAP: Continue" })
map("n", "<leader>dn", dap.step_over,         { desc = "DAP: Step Over" })
map("n", "<leader>di", dap.step_into,         { desc = "DAP: Step Into" })
map("n", "<leader>do", dap.step_out,          { desc = "DAP: Step Out" })
map("n", "<leader>dr", dap.repl.open,         { desc = "DAP: Open REPL" })
map("n", "<leader>dR", dap.run_last,          { desc = "DAP: Run Last" })
map("n", "<leader>dq", dap.terminate,         { desc = "DAP: Terminate" })
map("n", "<leader>dx", dap.clear_breakpoints, { desc = "DAP: Clear All Breakpoints" })
map("n", "<leader>dC", dap.run_to_cursor,     { desc = "DAP: Run to Cursor" })

map("n", "<leader>dh", function()
  require("dap.ui.widgets").hover()
end, { desc = "DAP: Hover (变量值)" })
map({ "n", "v" }, "<leader>dp", function()
  require("dap.ui.widgets").preview()
end, { desc = "DAP: Preview" })
map("n", "<leader>df", function()
  local w = require("dap.ui.widgets")
  w.centered_float(w.frames)
end, { desc = "DAP: Stack Frames" })
map("n", "<leader>ds", function()
  local w = require("dap.ui.widgets")
  w.centered_float(w.scopes)
end, { desc = "DAP: Scopes" })

-- DAP UI
map("n", "<leader>du", dapui.toggle, { desc = "DAP: Toggle UI" })
map("n", "<leader>de", dapui.eval,   { desc = "DAP: Eval expression" })
map("v", "<leader>de", dapui.eval,   { desc = "DAP: Eval selection" })

-- Telescope DAP
map("n", "<leader>dtb", "<cmd>Telescope dap list_breakpoints<CR>", { desc = "DAP: List Breakpoints" })
map("n", "<leader>dtf", "<cmd>Telescope dap frames<CR>",           { desc = "DAP: Frames" })
map("n", "<leader>dtc", "<cmd>Telescope dap commands<CR>",         { desc = "DAP: Commands" })
map("n", "<leader>dtv", "<cmd>Telescope dap variables<CR>",        { desc = "DAP: Variables" })

-- ─────────────────────────────────────────────
--  【修复3】integratedTerminal（DAP terminal buffer）的 Esc 映射
--
--  terminal buffer 进入 insert 模式后，<Esc> 被 terminal 本身捕获，
--  无法通过普通 <Esc> 退到 normal 模式。
--  解决方案：在 terminal 模式下映射 <Esc> → <C-\><C-n>（terminal 的标准退出序列）
--
--  注意：这会影响所有 terminal buffer（包括非 DAP 的）。
--  如只想作用于 DAP terminal，可在 dap.listeners 里用 buf-local 映射。
-- ─────────────────────────────────────────────
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Terminal: 退出 insert 模式到 normal" })

-- 如果你有自定义的 insert→normal 快捷键（比如 jk），也加一条：
map("t", "jk", "<C-\\><C-n>", { desc = "Terminal: jk 退出 insert 模式" })
