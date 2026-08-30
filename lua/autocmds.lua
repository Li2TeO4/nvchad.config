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

-- nvdash 启动仪表盘会通过 winopts 把窗口的 number/relativenumber 关掉，
-- 从仪表盘打开普通文件后该窗口设置仍会保留，导致行号消失。
-- 这里在普通文件的 filetype 建立时恢复行号显示。
vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev)
    if ev.match ~= "nvdash" and vim.bo.buftype == "" then
      vim.wo.number = true
      vim.wo.relativenumber = true
    end
  end,
})
