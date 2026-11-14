-- C/C++ 专用注释操作：<leader>/、<leader>.、<leader>,
--
-- 设计说明（已与作者逐条确认）：
--   * 只对 c / cpp 生效，其它 filetype 全部回落到 Comment.nvim 原生行为
--   * 核心是 /* */ 局部注释；// 整行注释保留，行尾 // 永不删除
--   * <leader>/ 优先级：消本行所有 /* */  →  消整行 //  →  整行加 /* */
--   * <leader>. 优先级：消光标处 /* */  →  消本行所有 /* */  →  恢复上次删的 /* */
--                        →  消整行 //  →  整行加 /* */
--   * visual 一律「逐行块」：每行只包自己选区内的部分（每行都能单独取消）
--   * 严格只增删标记（/* */ 与 //），标记之间的内容一律保留
--
-- 扫描器不依赖 treesitter（本机没装解析器），自己按 C 词法跳过字符串/字符字面量。

local M = {}

local BLOCK_FT = { c = true, cpp = true }

-- 上一次删除的 /* */（供 <leader>. 恢复）。一次动作可能删多个，整组记住。
local last = { bufnr = nil, lnum = nil, items = {} }

local function c_like()
  return BLOCK_FT[vim.bo.filetype] == true
end

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO)
end

-- 非 c/cpp：保持原行为（整行 // toggle）
local function fallback_toggle()
  local ok, api = pcall(require, "Comment.api")
  if ok then
    api.toggle.linewise.current()
  end
end

--------------------------------------------------------------------------------
-- 扫描：把 buffer 前 upto 行的注释段找出来
-- 返回 { blocks = { {sl, sc, el, ec} ... }, line_comments = { [lnum] = sc }, lines = {...} }
--   列号 0-based；ec 为半开区间，即 line:sub(sc + 1, ec) 是该行上要删掉的文本
--   跨行块：sl/el 不同，ec 只对 el 行有意义
--------------------------------------------------------------------------------
local function scan(bufnr, upto)
  local total = vim.api.nvim_buf_line_count(bufnr)
  upto = math.min(upto, total)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, upto, false)
  local blocks, line_comments = {}, {}
  local open = nil

  local function add(sl, sc, el, ec)
    blocks[#blocks + 1] = { sl = sl, sc = sc, el = el, ec = ec }
  end

  for i = 1, #lines do
    local line = lines[i]
    local n = #line
    local j = 1

    -- 进入本行时若仍在跨行块里
    if open then
      local e = line:find("*/", 1, true)
      if e then
        add(open.sl, open.sc, i, e + 1)
        open = nil
        j = e + 2
      else
        j = n + 1
      end
    end

    while j <= n do
      local c = line:sub(j, j)
      if c == "/" and line:sub(j + 1, j + 1) == "*" then
        -- 块注释开始
        local e = line:find("*/", j + 2, true)
        if e then
          add(i, j - 1, i, e + 1)
          j = e + 2
        else
          open = { sl = i, sc = j - 1 }
          j = n + 1
        end
      elseif c == "/" and line:sub(j + 1, j + 1) == "/" then
        line_comments[i] = j - 1
        -- // 文本里的 /* */（只可能是单行）
        local k = j + 2
        while true do
          local s2 = line:find("/*", k, true)
          if not s2 then
            break
          end
          local e2 = line:find("*/", s2 + 2, true)
          if not e2 then
            break
          end
          add(i, s2 - 1, i, e2 + 1)
          k = e2 + 2
        end
        j = n + 1
      elseif c == '"' or c == "'" then
        -- 跳过字符串 / 字符字面量（处理反斜杠转义）
        local q = c
        j = j + 1
        while j <= n do
          local ch = line:sub(j, j)
          if ch == "\\" then
            j = j + 2
          elseif ch == q then
            j = j + 1
            break
          else
            j = j + 1
          end
        end
      else
        j = j + 1
      end
    end
  end

  -- 光标行落在未闭合的块里：继续往后找到块的结尾（供跨行块整体删除/恢复）
  if open then
    local i = #lines
    while i < total do
      i = i + 1
      local l = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
      lines[i] = l
      local e = l:find("*/", 1, true)
      if e then
        add(open.sl, open.sc, i, e + 1)
        open = nil
        break
      end
    end
    if open then
      -- 一直到文件末尾都没闭合
      add(open.sl, open.sc, total, #(lines[total] or ""))
    end
  end

  return { blocks = blocks, line_comments = line_comments, lines = lines }
end

-- 与某行相交的块
local function blocks_on(scan_data, lnum)
  local out = {}
  for _, b in ipairs(scan_data.blocks) do
    if b.sl <= lnum and lnum <= b.el then
      out[#out + 1] = b
    end
  end
  return out
end

-- 光标是否落在某个块内（0-based 列）
local function cursor_in_block(b, lnum, col0)
  if lnum < b.sl or lnum > b.el then
    return false
  end
  if b.sl == b.el then
    return col0 >= b.sc and col0 < b.ec
  elseif lnum == b.sl then
    return col0 >= b.sc
  elseif lnum == b.el then
    return col0 < b.ec
  end
  return true
end

-- 块的原始文本（可能跨行）
local function block_text(scan_data, b)
  local lines = scan_data.lines
  if b.sl == b.el then
    return lines[b.sl]:sub(b.sc + 1, b.ec)
  end
  local parts = { lines[b.sl]:sub(b.sc + 1) }
  for i = b.sl + 1, b.el - 1 do
    parts[#parts + 1] = lines[i]
  end
  parts[#parts + 1] = lines[b.el]:sub(1, b.ec)
  return table.concat(parts, "\n")
end

-- 去掉行尾空白（返回 去掉后的长度，0-based 的半开位置）
local function rstrip_len(line)
  return #(line:gsub("%s+$", ""))
end

-- 第一个非空白列的 0-based 偏移
local function indent_len(line)
  return #(line:match("^%s*") or "")
end

-- 整行是否是「整行 // 注释」（首个非空白即 //）
local function is_line_comment(line)
  return line:match "^%s*//" ~= nil
end

--------------------------------------------------------------------------------
-- 删除若干块（一次 nvim_buf_set_lines，单步撤销）
-- 返回删除前的记忆项列表（供恢复）
--------------------------------------------------------------------------------
-- 去掉块注释的「标记」（/* 与 */，连同一个格式空格），**保留标记之间的内容**
-- 例：for (...i++/*, j++*/);        → for (...i++, j++);   （内容变成可执行代码）
--     /* int tmp = 9; */           → int tmp = 9;
--     printf("x"); /*note*/ // x   → printf("x"); note // x
-- 返回记忆项（整行原件），供 <leader>. 原样恢复
local function strip_blocks(bufnr, scan_data, blocks)
  if #blocks == 0 then
    return {}
  end

  local lines = scan_data.lines
  local first, last = math.huge, -1
  local touched = {}
  for _, b in ipairs(blocks) do
    first = math.min(first, b.sl)
    last = math.max(last, b.el)
    for i = b.sl, b.el do
      touched[i] = lines[i]
    end
  end

  local region = {}
  for i = first, last do
    region[#region + 1] = lines[i]
  end
  local text = table.concat(region, "\n")
  local prefix = { [first] = 0 }
  for i = first, last - 1 do
    prefix[i + 1] = prefix[i] + #lines[i] + 1
  end

  -- 严格只删开/闭标记（连同一个格式空格），标记之间的内容一律原样保留，
  -- 包括 // 行注释里内嵌的块（例：// for(i = 0/*i = 1*/; ...) → // for(i = 0i = 1; ...)）
  local removals = {}
  for _, b in ipairs(blocks) do
    local s_off = prefix[b.sl] + b.sc
    local btext = block_text(scan_data, b)
    local e_off = s_off + #btext
    local open_len = (btext:sub(1, 3) == "/* ") and 3 or 2
    local close_len = (btext:sub(-3) == " */") and 3 or 2
    removals[#removals + 1] = { s_off, s_off + open_len }
    removals[#removals + 1] = { e_off - close_len, e_off }
  end

  -- 从后往前删，偏移保持有效
  table.sort(removals, function(a, b)
    return a[1] > b[1]
  end)
  for _, r in ipairs(removals) do
    text = text:sub(1, r[1]) .. text:sub(r[2] + 1)
  end

  vim.api.nvim_buf_set_lines(bufnr, first - 1, last, false, vim.split(text, "\n", { plain = true }))

  -- 记住受影响行的原件：<leader>. 再次按下可原样包回去
  local items = {}
  for i = first, last do
    if touched[i] then
      items[#items + 1] = { kind = "line", sl = i, sc = 0, el = i, text = touched[i] }
    end
  end
  return items
end

--------------------------------------------------------------------------------
-- 包裹 / 解包（在指定列插 /* 与 */）
--------------------------------------------------------------------------------
-- 把 [s0, e0) 这一段包成 /* ... */（e0 省略表示到行尾）
local function wrap_range(line, s0, e0)
  local endpos = e0 or #line
  local pre = line:sub(1, s0)
  local raw = line:sub(s0 + 1, endpos)
  local content = raw:match "^%s*(.-)%s*$"
  local pad = (raw:match "%s*$" or "") ~= "" and " " or "" -- 区间末尾空白：折叠成一个空格
  local tail = line:sub(endpos + 1)
  if content == "" then
    -- 空行/纯缩进行：直接一对 /* */，丢掉尾部空白
    return pre .. "/* */"
  end
  return pre .. "/* " .. content .. " */" .. pad .. tail
end

-- s0 之后第一个非空白是否正好是 /* ... */；是则返回 /* 的 0-based 位置
-- （这样"行内其它位置有块注释"（如 for (...) 里的 /*x*/）不会被误判成"已包裹"）
local function wrapped_at(line, s0)
  local pre = line:sub(s0 + 1)
  local lead = pre:match "^%s*"
  local p = s0 + #lead
  if line:sub(p + 1, p + 2) ~= "/*" then
    return nil
  end
  if not line:find("*/", p + 3, true) then
    return nil
  end
  return p
end

-- 解包：去掉落 s0 处的 "/* "（或 "/*"）与其后第一个 "*/"（含前面一个空格）
local function strip_wrap(line, s0)
  local pre = line:sub(1, s0)
  local rest = line:sub(s0 + 1)
  local body
  if rest:sub(1, 3) == "/* " then
    body = rest:sub(4)
  elseif rest:sub(1, 2) == "/*" then
    body = rest:sub(3)
  else
    return nil
  end
  local p = body:find("*/", 1, true)
  if not p then
    return nil
  end
  local before = body:sub(p - 1, p - 1)
  local after = body:sub(p + 2)
  local kept = before == " " and body:sub(1, p - 2) or body:sub(1, p - 1)
  return pre .. kept .. after
end

--------------------------------------------------------------------------------
-- 对外操作
--------------------------------------------------------------------------------

-- 记忆：记录本次删除（供 <leader>. 恢复）
local function remember(bufnr, lnum, items)
  if #items == 0 then
    return
  end
  last.bufnr = bufnr
  last.lnum = lnum
  last.items = items
end

-- 恢复上次删除（同 buffer、同起始行）
local function restore(bufnr, lnum)
  if last.bufnr ~= bufnr or last.lnum ~= lnum or #last.items == 0 then
    return false
  end

  local line_delta = 0
  for _, it in ipairs(last.items) do
    local target = it.sl + line_delta

    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local sl = math.max(1, math.min(target, #lines))
    local sline = lines[sl]
    local sc = math.min(it.sc, #sline)
    if sc ~= it.sc then
      notify("注释恢复位置已夹住（行内容有变动）", vim.log.levels.WARN)
    end

    local pieces
    if it.kind == "line" then
      -- 整行还原（可视解包用：插入会重复内容，所以整行替换）
      pieces = vim.split(it.text, "\n", { plain = true })
    else
      local merged = sline:sub(1, sc) .. it.text .. sline:sub(sc + 1)
      pieces = vim.split(merged, "\n", { plain = true })
    end
    vim.api.nvim_buf_set_lines(bufnr, sl - 1, sl, false, pieces)

    line_delta = line_delta + (#pieces - 1)
  end

  last = { bufnr = nil, lnum = nil, items = {} }
  return true
end

-- normal <leader>/
function M.slash_normal()
  if not c_like() then
    return fallback_toggle()
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local sd = scan(bufnr, lnum)
  local blocks = blocks_on(sd, lnum)

  -- 1) 有 /* */ → 全删
  if #blocks > 0 then
    local items = strip_blocks(bufnr, sd, blocks)
    remember(bufnr, lnum, items)
    return
  end

  -- 2) 整行 // → 去掉 //
  local line = sd.lines[lnum]
  if is_line_comment(line) then
    local new = line:gsub("^(%s*)//%s?", "%1", 1)
    vim.api.nvim_buf_set_lines(bufnr, lnum - 1, lnum, false, { new })
    return
  end

  -- 3) 整行加 /* */（行尾 // 只包它之前的部分）
  local lc = sd.line_comments[lnum]
  local ind = indent_len(line)
  local e0 = lc and lc > ind and lc or rstrip_len(line)
  local new = wrap_range(line, ind, e0)
  vim.api.nvim_buf_set_lines(bufnr, lnum - 1, lnum, false, { new })
end

-- normal <leader>.
function M.dot_normal()
  if not c_like() then
    return fallback_toggle()
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local col0 = vim.api.nvim_win_get_cursor(0)[2]
  local sd = scan(bufnr, lnum)
  local blocks = blocks_on(sd, lnum)

  -- 1) 光标落在某个块内 → 只删它
  for _, b in ipairs(blocks) do
    if cursor_in_block(b, lnum, col0) then
      local items = strip_blocks(bufnr, sd, { b })
      remember(bufnr, lnum, items)
      return
    end
  end

  -- 2) 本行有块 → 全删
  if #blocks > 0 then
    local items = strip_blocks(bufnr, sd, blocks)
    remember(bufnr, lnum, items)
    return
  end

  -- 3) 恢复上次删的（同 buffer 同起始行）
  if restore(bufnr, lnum) then
    return
  end

  -- 4) 整行 // → 去掉 //（走到这里说明本行既无 /* */ 也无可恢复记忆）
  local line = sd.lines[lnum]
  if is_line_comment(line) then
    local new = line:gsub("^(%s*)//%s?", "%1", 1)
    vim.api.nvim_buf_set_lines(bufnr, lnum - 1, lnum, false, { new })
    return
  end

  -- 5) 整行加 /* */
  local lc = sd.line_comments[lnum]
  local ind = indent_len(line)
  local e0 = lc and lc > ind and lc or rstrip_len(line)
  local new = wrap_range(line, ind, e0)
  vim.api.nvim_buf_set_lines(bufnr, lnum - 1, lnum, false, { new })
end

--------------------------------------------------------------------------------
-- visual：逐行块（D2 选项 2）
--------------------------------------------------------------------------------
-- 可视模式下取选区：先记 mode，再退出可视模式（'< '> 这时才生效），最后读标记
-- 注意：必须用 mode()（当前真实模式）而不是 visualmode()——后者返回「上一次」的可视模式，
-- 每个会话的第一次可视操作会返回空串，导致第一次按键被当成「不支持」而失败。
local function visual_capture()
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
    mode = vim.fn.visualmode() -- 兜底（例如从脚本里调用）
  end
  vim.cmd "normal! \27"
  local s, e = vim.fn.getpos "'<", vim.fn.getpos "'>"
  return mode, s[2], s[3], e[2], e[3]
end

-- 计算一行在选区里需要包住的区间 [s0, e0)（0-based）
local function per_line_range(line, lnum, sl, sc, el, ec, mode)
  local ind = indent_len(line)
  if mode == "V" then
    return ind, rstrip_len(line)
  end
  -- charwise：列号是 1-based 闭区间（实测 getpos 返回的正是该字符）
  local start0, end0
  if lnum == sl and lnum == el then
    start0, end0 = sc - 1, ec -- 1-based 闭 → 0-based 半开
  elseif lnum == sl then
    start0, end0 = sc - 1, rstrip_len(line)
  elseif lnum == el then
    start0, end0 = ind, ec
  else
    start0, end0 = ind, rstrip_len(line)
  end
  return start0, math.max(start0, end0)
end

function M.visual()
  if not c_like() then
    return fallback_toggle()
  end
  local mode, sl, sc, el, ec = visual_capture()
  if mode ~= "v" and mode ~= "V" then
    notify("暂不支持块选区（<C-v>）", vim.log.levels.WARN)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  if sl > el then
    sl, el = el, sl
  end
  sl = math.max(1, math.min(sl, #lines))
  el = math.max(1, math.min(el, #lines))

  -- 判断是否整段都已包裹（都包裹 → toggle 取消）
  local all_wrapped, any_content = true, false
  for i = sl, el do
    local line = lines[i]
    if not line:match "^%s*$" then
      any_content = true
      local s0 = per_line_range(line, i, sl, sc, el, ec, mode)
      if not (wrapped_at(line, s0) or wrapped_at(line, indent_len(line))) then
        all_wrapped = false
        break
      end
    end
  end

  if all_wrapped and any_content then
    -- 解包：从后往前，记下每行去掉的 /* */ 原文，供 <leader>. 恢复
    local items = {}
    for i = el, sl, -1 do
      local line = lines[i]
      if not line:match "^%s*$" then
        local s0 = per_line_range(line, i, sl, sc, el, ec, mode)
        local use0 = wrapped_at(line, s0) or wrapped_at(line, indent_len(line)) or s0
        local new = strip_wrap(line, use0)
        if new then
          -- 记下整行原件：恢复时整行还原（插入语义会重复内容）
          items[#items + 1] = { kind = "line", sl = i, sc = 0, el = i, text = line }
          vim.api.nvim_buf_set_lines(bufnr, i - 1, i, false, { new })
        end
      end
    end
    table.sort(items, function(a, b)
      return a.sl < b.sl or (a.sl == b.sl and a.sc < b.sc)
    end)
    remember(bufnr, sl, items)
    return
  end

  -- 包裹：逐行，只包该行选区内的部分；已有块注释的行跳过（避免 /* 嵌套）
  local skipped = 0
  for i = el, sl, -1 do
    local line = lines[i]
    if not line:match "^%s*$" then
      local s0, e0 = per_line_range(line, i, sl, sc, el, ec, mode)
      if wrapped_at(line, s0) then
        skipped = skipped + 1
      else
        vim.api.nvim_buf_set_lines(bufnr, i - 1, i, false, { wrap_range(line, s0, e0) })
      end
    end
  end
  if skipped > 0 then
    notify(("跳过 %d 行：已含 /* */ 注释"):format(skipped), vim.log.levels.WARN)
  end
end

--------------------------------------------------------------------------------
-- <leader>,  // 整行开关
--------------------------------------------------------------------------------
local function toggle_slash_line(line)
  if is_line_comment(line) then
    return (line:gsub("^(%s*)//%s?", "%1", 1))
  end
  local ind = indent_len(line)
  return line:sub(1, ind) .. "// " .. line:sub(ind + 1)
end

function M.line_comment_normal()
  if not c_like() then
    return fallback_toggle()
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1]
  vim.api.nvim_buf_set_lines(bufnr, lnum - 1, lnum, false, { toggle_slash_line(line) })
end

function M.line_comment_visual()
  if not c_like() then
    return fallback_toggle()
  end
  local _mode, sl, sc, el, ec = visual_capture()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  if sl > el then
    sl, el = el, sl
  end
  sl = math.max(1, math.min(sl, #lines))
  el = math.max(1, math.min(el, #lines))

  -- 全都有 // 则全删，否则全加（跳过空行）
  local all = true
  for i = sl, el do
    local line = lines[i]
    if not line:match "^%s*$" and not is_line_comment(line) then
      all = false
      break
    end
  end

  local new = {}
  for i = sl, el do
    local line = lines[i]
    if line:match "^%s*$" then
      new[#new + 1] = line
    elseif all then
      new[#new + 1] = (line:gsub("^(%s*)//%s?", "%1", 1))
    elseif is_line_comment(line) then
      new[#new + 1] = line
    else
      local ind = indent_len(line)
      new[#new + 1] = line:sub(1, ind) .. "// " .. line:sub(ind + 1)
    end
  end
  vim.api.nvim_buf_set_lines(bufnr, sl - 1, el, false, new)
end

--------------------------------------------------------------------------------
-- 键位注册
--------------------------------------------------------------------------------
function M.setup()
  local km = vim.keymap
  km.set("n", "<leader>/", M.slash_normal, { desc = "注释：/* */ 优先 → 整行 // → 整行加 /* */" })
  km.set("n", "<leader>.", M.dot_normal, { desc = "注释：/* */ → 恢复上次删除 → 整行 // → 整行加 /* */" })
  km.set("v", "<leader>/", M.visual, { desc = "注释选区（C/C++ 逐行 /* */）" })
  km.set("v", "<leader>.", M.visual, { desc = "注释选区（C/C++ 逐行 /* */）" })
  km.set("n", "<leader>,", M.line_comment_normal, { desc = "整行 // 开关" })
  km.set("v", "<leader>,", M.line_comment_visual, { desc = "选中行 // 开关" })
end

return M
