-- scrollpad.lua
-- 非对称视觉行 scrolloff：
--   下方：始终保留 4 行（硬性，即使到文件末尾也强制滚动）
--   上方：尽量保留 4 行，但允许光标抵近文件顶端时少于 4 行
--
-- 所有行数均以 TUI 可见行（考虑 wrap 折行）为准。

local PAD_BELOW = 4   -- 光标下方始终保留的视觉行数
local PAD_ABOVE = 4   -- 光标上方尽量保留的视觉行数（到文件顶端时可少于此值）

-- 获取某 buffer-line（1-indexed）在指定窗口中占用的视觉行数
local function visual_lines_of(winid, bufnr, lnum)
  local width = vim.api.nvim_win_get_width(winid)
  -- 减去 numberwidth 和 signcolumn 等占用的宽度
  local info = vim.fn.getwininfo(winid)[1]
  local textoff = info and info.textoff or 0
  local effective_width = width - textoff
  if effective_width <= 0 then effective_width = 1 end

  local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
  local line_len = vim.fn.strdisplaywidth(line)
  if line_len == 0 then return 1 end
  return math.max(1, math.ceil(line_len / effective_width))
end

-- 计算从 buf-line start_lnum 到 end_lnum（含）的视觉行总数
local function count_visual_lines(winid, bufnr, start_lnum, end_lnum)
  if start_lnum > end_lnum then return 0 end
  local total = 0
  for l = start_lnum, end_lnum do
    total = total + visual_lines_of(winid, bufnr, l)
  end
  return total
end

local function adjust_scroll()
  local winid = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_get_current_buf()

  -- 当前光标所在 buffer-line（1-indexed）
  local cursor_lnum = vim.api.nvim_win_get_cursor(winid)[1]
  -- 窗口高度（可显示的视觉行数）
  local win_height = vim.api.nvim_win_get_height(winid)
  -- 总 buffer 行数
  local total_lines = vim.api.nvim_buf_line_count(bufnr)

  -- 当前窗口第一个可见的 buffer-line（topline，1-indexed）
  local topline = vim.fn.line("w0")

  -- 光标这一行本身占用的视觉行数
  local cursor_vlines = visual_lines_of(winid, bufnr, cursor_lnum)

  -- 光标所在行在窗口内的起始视觉偏移（相对于 topline，0-indexed）
  -- 即 topline 到 cursor_lnum-1 之间所有行的视觉行之和
  local cursor_vis_top = count_visual_lines(winid, bufnr, topline, cursor_lnum - 1)
  -- 光标行结束后（含光标行）的视觉偏移
  local cursor_vis_bot = cursor_vis_top + cursor_vlines

  -- 光标下方还有多少可见视觉行（不含光标行）
  local below_available = win_height - cursor_vis_bot
  -- 光标上方还有多少可见视觉行（不含光标行）
  local above_available = cursor_vis_top

  -- ── 处理下方不足 PAD_BELOW ──
  if below_available < PAD_BELOW then
    -- 需要向下滚动，使光标上方恰好留出 (win_height - PAD_BELOW - cursor_vlines) 视觉行
    -- 即从 cursor_lnum 往上数，直到累积视觉行 = win_height - PAD_BELOW - cursor_vlines
    local target_above = win_height - PAD_BELOW - cursor_vlines
    if target_above < 0 then target_above = 0 end

    -- 从光标行往上找新的 topline
    local new_topline = cursor_lnum
    local accumulated = 0
    while new_topline > 1 do
      local prev_vl = visual_lines_of(winid, bufnr, new_topline - 1)
      if accumulated + prev_vl > target_above then break end
      accumulated = accumulated + prev_vl
      new_topline = new_topline - 1
    end

    if new_topline ~= topline then
      vim.fn.winrestview({ topline = new_topline, lnum = cursor_lnum })
    end
    return
  end

  -- ── 处理上方不足 PAD_ABOVE（允许文件顶端时少于 PAD_ABOVE）──
  if above_available < PAD_ABOVE and topline > 1 then
    -- 需要向上滚动
    -- 理想 topline：光标上方恰好 PAD_ABOVE 视觉行
    -- 即从 cursor_lnum 往上数 PAD_ABOVE 个视觉行对应的 buffer-line
    local new_topline = cursor_lnum
    local accumulated = 0
    while new_topline > 1 do
      local prev_vl = visual_lines_of(winid, bufnr, new_topline - 1)
      if accumulated + prev_vl > PAD_ABOVE then break end
      accumulated = accumulated + prev_vl
      new_topline = new_topline - 1
    end
    -- new_topline 是理想的 topline，最小为 1
    new_topline = math.max(1, new_topline)

    if new_topline < topline then
      vim.fn.winrestview({ topline = new_topline, lnum = cursor_lnum })
    end
  end
end

-- 禁用原生 scrolloff，完全由本模块接管
vim.opt.scrolloff = 0

vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
  group = vim.api.nvim_create_augroup("ScrollPad", { clear = true }),
  callback = adjust_scroll,
})
