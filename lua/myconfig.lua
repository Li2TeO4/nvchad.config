-- 随启动加载的通用配置模块（说明见各文件头注释）
require("configs.keymaps")          -- 通用键位（唯一出处）
require("configs.function-keymaps") -- 行尾加分号 / 删末尾字符
require("configs.scrollpad")        -- 非对称 scrolloff

-- 以下模块由插件按需加载，不要在这里 require：
--   configs.dap-keymaps      → 由 plugins/dap.lua 在 nvim-dap 的 config 中懒加载
--   configs.cmake-dap-helper → 由 lua/mappings.lua 加载（注册 :CMakeDebug 等命令）
