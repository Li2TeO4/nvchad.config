require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- DAP 键位不再在启动时加载：由 plugins/dap.lua 里的 keys 触发，
-- nvim-dap 加载后会在它的 config 中 require("configs.dap-keymaps")。
require("configs.cmake-dap-helper")

