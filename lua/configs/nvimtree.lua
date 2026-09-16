-- 文件树（nvim-tree）行号：开关 + 配色
--
-- 行为：
--   · 默认不显示行号
--   · <leader>n 一次性开关「绝对行号 + 相对行号」（开关状态在本次会话内保持）
--   · 数字用普通字形（不做上标缩小）
--
-- 配色：只改下面 COLORS 里的两个色号即可。
--   树里更关注目标文件，所以相对行号用浅色（显眼）、当前行行号用深色 —— 与编辑器相反。
--   nvim-tree 用 winhl 把窗口的 LineNr / CursorLineNr 映射到
--   NvimTreeLineNr / NvimTreeCursorLineNr，这里只负责给这两个组上色。

local M = {}

-- ┌───────────────────────────────────────────────────────────────┐
-- │  改色口                                                        │
-- │  浅色 = 相对行号（树中主要关注目标文件，要显眼）                │
-- │  深色 = 当前行行号                                              │
-- └───────────────────────────────────────────────────────────────┘
local COLORS = {
  relative = "#c1d9e6", -- 浅色 → 相对行号
  current = "#7592a1", -- 深色 → 当前行行号
}

local function apply_colors()
  vim.api.nvim_set_hl(0, "NvimTreeLineNr", { fg = COLORS.relative })
  vim.api.nvim_set_hl(0, "NvimTreeCursorLineNr", { fg = COLORS.current })
end

-- 会话内开关状态：默认关闭
local enabled = false

local function tree_wins()
  local wins = {}
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "NvimTree" then
      wins[#wins + 1] = w
    end
  end
  return wins
end

local function apply_numbers(win)
  vim.wo[win].number = enabled
  vim.wo[win].relativenumber = enabled
end

---开关文件树行号（绝对 + 相对一次性切换），由 <leader>n 调用
function M.toggle_numbers()
  enabled = not enabled

  -- 同步写回 nvim-tree 自己的配置：否则每次打开树窗口，
  -- 它都会用 config.view.number 的值（默认 false）重新设置窗口选项，把开关状态冲掉
  local conf = require("nvim-tree.config").g
  conf.view.number = enabled
  conf.view.relativenumber = enabled

  -- 已打开的树窗口立即生效
  for _, w in ipairs(tree_wins()) do
    apply_numbers(w)
  end

  if #tree_wins() == 0 then
    vim.notify(
      ("文件树未打开；树行号已设为「%s」，打开文件树后生效"):format(enabled and "显示" or "隐藏"),
      vim.log.levels.INFO
    )
  else
    vim.notify(
      ("文件树行号：%s（绝对 + 相对）"):format(enabled and "显示" or "隐藏"),
      vim.log.levels.INFO
    )
  end
end

function M.setup()
  apply_colors()

  -- 换主题 / base46 重载后重新上色
  vim.api.nvim_create_autocmd("User", {
    pattern = "NvThemeReload",
    callback = apply_colors,
  })

  -- 树窗口出现时套用当前开关状态（窗口级选项会随窗口销毁而丢失）
  local function on_tree_win(args)
    local win = vim.fn.bufwinid(args.buf)
    if win == -1 then
      return
    end
    -- 延后一帧再套用：nvim-tree 会在创建窗口的过程中用自身配置
    -- （view-state 在启动时拷贝的 view.number/relativenumber）覆盖窗口选项
    vim.schedule(function()
      if vim.api.nvim_win_is_valid(win) then
        apply_numbers(win)
      end
    end)
  end

  vim.api.nvim_create_autocmd("FileType", { pattern = "NvimTree", callback = on_tree_win })
  vim.api.nvim_create_autocmd("BufWinEnter", {
    callback = function(args)
      if vim.bo[args.buf].filetype == "NvimTree" then
        on_tree_win(args)
      end
    end,
  })
end

return M
