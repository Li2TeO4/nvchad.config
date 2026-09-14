-- 文件树（nvim-tree）行号样式
--
-- 需求：
--   1. 树中显示行号 + 相对行号，方便按相对行号快速跳到目标文件
--   2. 配色与编辑器里的行号同族但略有区别（见 chadrc.lua 的 hl_add）：
--        NvimTreeLineNr       = 相对行号 → 浅色（#B3D4DB），树中主要关注目标文件
--        NvimTreeCursorLineNr = 当前行号 → 深色（#56868F）
--      与编辑器的惯例相反（编辑器 CursorLineNr 浅、LineNr 深）
--   3. 字形比正文略小：TUI 无法改变字体大小，这里用上标数字（⁰¹²³…）模拟小字形
--
-- 实现：给树窗口设置 window-local 的 'statuscolumn'。
-- statuscolumn 里 %{...} 表达式的返回值不会被再次解析，所以高亮标记必须写在
-- 外层：用「高亮段 + 条件表达式」两段，当前行只让第一段出内容，其余行只让第二段出内容。

local M = {}

-- 上标数字：TUI 下唯一能"缩小"数字字形的手段
local SUPERSCRIPT = {
  ["0"] = "⁰", ["1"] = "¹", ["2"] = "²", ["3"] = "³", ["4"] = "⁴",
  ["5"] = "⁵", ["6"] = "⁶", ["7"] = "⁷", ["8"] = "⁸", ["9"] = "⁹",
}

local WIDTH = 2 -- 数字列宽（上标字形窄，2 列足够；超出会自动加宽）

local function format_num(num)
  local text = tostring(num):gsub("%d", SUPERSCRIPT)
  -- 注意：上标字形是 2~3 字节但只占 1 格，必须按显示宽度补位才对得齐
  local pad = math.max(0, WIDTH - vim.fn.strdisplaywidth(text))
  return string.rep(" ", pad) .. text .. " "
end

M._format_num = format_num -- 暴露给测试/调试用

-- 当前行：显示绝对行号（深色）
_G.NvimTreeNumCurrent = function()
  if vim.v.virtnum ~= 0 or vim.v.relnum ~= 0 then
    return ""
  end
  return format_num(vim.v.lnum)
end

-- 其余行：显示相对行号（浅色）
_G.NvimTreeNumRelative = function()
  if vim.v.virtnum ~= 0 or vim.v.relnum == 0 then
    return ""
  end
  return format_num(vim.v.relnum)
end

local STATUSCOLUMN = "%#NvimTreeCursorLineNr#%{v:lua.NvimTreeNumCurrent()}"
  .. "%#NvimTreeLineNr#%{v:lua.NvimTreeNumRelative()}"

-- windows 级选项，必须落在显示树的那个窗口上
local function apply(win)
  if win == -1 then
    return
  end
  vim.wo[win].statuscolumn = STATUSCOLUMN
  vim.wo[win].numberwidth = WIDTH
end

function M.setup()
  -- 树 buffer 初次建立 filetype 时
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "NvimTree",
    callback = function(args)
      apply(vim.fn.bufwinid(args.buf))
    end,
  })

  -- 树窗口重新打开时（窗口销毁后窗口级选项会丢失）
  vim.api.nvim_create_autocmd("BufWinEnter", {
    callback = function(args)
      if vim.bo[args.buf].filetype == "NvimTree" then
        apply(vim.fn.bufwinid(args.buf))
      end
    end,
  })
end

return M
