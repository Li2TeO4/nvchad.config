require "nvchad.autocmds"

-- 在所有插件 setup() 完成后，重新应用 hl_add 高亮
-- 这样可以防止被插件的 setup() 覆盖
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyDone",
  once = true,
  callback = function()
    -- 重新编译并加载所有 base46 高亮（包含 hl_add）
    require("base46").load_all_highlights()
  end,
})
