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

-- C/C++ 专用注释键位：<leader>/、<leader>.、<leader>,
-- 必须写在 require "nvchad.mappings" 之后：NvChad 默认把 <leader>/ 映射成 gcc/gc，
-- 而 mappings.lua 是在 vim.schedule 里加载的，晚于 configs/keymaps.lua，
-- 所以只能在这里覆盖。
-- 逻辑见 lua/configs/c-comment.lua（非 c/cpp 自动回落到 Comment.nvim）
require("configs.c-comment").setup()
