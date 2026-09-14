require "nvchad.mappings"

-- 用户键位不放在这里：通用键位见 lua/configs/keymaps.lua（唯一出处），
-- DAP 键位由 plugins/dap.lua 懒加载（configs/dap-keymaps.lua）。
-- 这里只负责注册 CMake 辅助命令（:CMakeDebug / :CMakeConfigure）。
require("configs.cmake-dap-helper")

-- <leader>n：开关文件树行号（绝对 + 相对一次性切换）
-- 该键位必须写在 require "nvchad.mappings" 之后，才能覆盖 NvChad 默认的
-- <leader>n（原本是切换编辑器绝对行号）。
vim.keymap.set("n", "<leader>n", function()
  require("configs.nvimtree").toggle_numbers()
end, { desc = "文件树行号开关（绝对 + 相对）" })
