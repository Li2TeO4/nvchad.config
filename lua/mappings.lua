require "nvchad.mappings"

-- 用户键位不放在这里：通用键位见 lua/configs/keymaps.lua（唯一出处），
-- DAP 键位由 plugins/dap.lua 懒加载（configs/dap-keymaps.lua）。
-- 这里只负责注册 CMake 辅助命令（:CMakeDebug / :CMakeConfigure）。
require("configs.cmake-dap-helper")
