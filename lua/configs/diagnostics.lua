-- diagnostic 行尾虚拟文本「放不下就换行」的渲染器
--
-- 背景：Neovim 默认的 virtual_text 只能单行显示在行尾，行太长时会被窗口右侧裁掉，
-- 报错/警告内容看不全。这里注册一个自定义 handler：
--   * 这一行放得下 → 照旧显示在行尾（与默认行为一致，视觉上无变化）
--   * 放不下      → 用 virt_lines 在代码行下方换行显示（按窗口宽度自动折行，不会丢内容）
--
-- 生效方式：configs/lspconfig.lua 在 NvChad 的 defaults() 之后调用
-- require("configs.diagnostics").setup()，由它接管 virtual_text。

local M = {}

local SEV_NAME = {
  [vim.diagnostic.severity.ERROR] = "Error",
  [vim.diagnostic.severity.WARN] = "Warn",
  [vim.diagnostic.severity.INFO] = "Info",
  [vim.diagnostic.severity.HINT] = "Hint",
}

local function hl_of(diag)
  return "Diagnostic" .. (SEV_NAME[diag.severity] or "Error")
end

-- severity 过滤（min = 最严重级别；数字越小越严重）
local function pass_severity(diag, severity)
  if type(severity) ~= "table" or severity.min == nil then
    return true
  end
  return diag.severity <= severity.min
end

-- 按显示宽度把字符串切成若干块（考虑中文/emoji 等双宽字符）
local function wrap_text(text, width)
  width = math.max(10, width)
  local out, cur, cur_w = {}, {}, 0
  for _, ch in ipairs(vim.fn.split(text, "\\zs")) do
    local w = vim.fn.strdisplaywidth(ch)
    if cur_w + w > width and #cur > 0 then
      out[#out + 1] = table.concat(cur)
      cur, cur_w = {}, 0
    end
    cur[#cur + 1] = ch
    cur_w = cur_w + w
  end
  if #cur > 0 then
    out[#out + 1] = table.concat(cur)
  end
  return out
end

local function message_of(diag, opts)
  local msg = (diag.message or ""):gsub("%s*\n%s*", " ")
  return (opts.prefix or "") .. msg .. (opts.suffix or "")
end

-- 渲染：行尾放不下就走 virt_lines
local function render(namespace, bufnr, diagnostics, opts)
  opts = opts or {}
  vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)

  local win = vim.api.nvim_get_current_win()
  local avail = vim.api.nvim_win_get_width(win) - 1
  local spacing = opts.spacing or 4
  local hl_mode = opts.hl_mode or "combine"

  for line, line_diags in pairs(diagnostics) do
    local show = {}
    for _, d in ipairs(line_diags) do
      if pass_severity(d, opts.severity) then
        show[#show + 1] = d
      end
    end

    if #show > 0 then
      local line_text = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1] or ""
      local used = vim.fn.strdisplaywidth(line_text)

      -- 行尾需要占的宽度：spacing + 各条消息
      local need = 0
      local chunks = {}
      for _, d in ipairs(show) do
        local msg = message_of(d, opts)
        need = need + vim.fn.strdisplaywidth(msg) + spacing
        chunks[#chunks + 1] = { msg .. string.rep(" ", spacing), hl_of(d) }
      end

      if used + need <= avail then
        -- 放得下：照旧在行尾显示
        pcall(vim.api.nvim_buf_set_extmark, bufnr, namespace, line, 0, {
          hl_mode = hl_mode,
          virt_text = chunks,
          virt_text_pos = "eol",
        })
      else
        -- 放不下：在代码行下方换行显示（每条诊断按窗口宽度折行）
        local virt_lines = {}
        for _, d in ipairs(show) do
          local msg = message_of(d, opts)
          for _, piece in ipairs(wrap_text(msg, avail - 2)) do
            virt_lines[#virt_lines + 1] = { { piece, hl_of(d) } }
          end
        end
        pcall(vim.api.nvim_buf_set_extmark, bufnr, namespace, line, 0, {
          hl_mode = hl_mode,
          virt_lines = virt_lines,
        })
      end
    end
  end
end

-- 每个诊断 namespace 对应一个自己的渲染 namespace（缓存）
local own_ns = {}

local function render_ns(diag_ns)
  if not own_ns[diag_ns] then
    own_ns[diag_ns] = vim.api.nvim_create_namespace("wrapped_virtual_text_" .. diag_ns)
  end
  return own_ns[diag_ns]
end

function M.setup()
  if M.did_setup then
    return
  end
  M.did_setup = true

  vim.diagnostic.handlers.wrapped_virtual_text = {
    -- 注意 nvim 的契约：diagnostics 是**扁平列表**（已按 severity 过滤过），
    -- opts 是**整个**诊断配置（不是本 handler 的那一项）。
    show = function(namespace, bufnr, diagnostics, opts)
      bufnr = vim._resolve_bufnr(bufnr)
      local o = (opts and opts.wrapped_virtual_text) or {}
      local by_line = {}
      for _, d in ipairs(diagnostics) do
        by_line[d.lnum] = by_line[d.lnum] or {}
        table.insert(by_line[d.lnum], d)
      end
      render(render_ns(namespace), bufnr, by_line, o)
    end,
    hide = function(namespace, bufnr)
      bufnr = vim._resolve_bufnr(bufnr)
      vim.api.nvim_buf_clear_namespace(bufnr, render_ns(namespace), 0, -1)
    end,
  }

  -- 继承 NvChad 当前 virtual_text 的配置（prefix/suffix/severity 等），再接管渲染
  local cur = vim.diagnostic.config() or {}
  local vt = cur.virtual_text or {}
  vim.diagnostic.config({
    virtual_text = false, -- 关掉内置行尾渲染，由 wrapped_virtual_text 接管
    wrapped_virtual_text = {
      severity = vt.severity or { min = vim.diagnostic.severity.HINT },
      prefix = vt.prefix or "",
      suffix = vt.suffix or "",
      spacing = vt.spacing or 4,
      hl_mode = vt.hl_mode or "combine",
    },
  })

  -- 窗口尺寸变化时重新计算「放不放得下」
  vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
    group = vim.api.nvim_create_augroup("DiagWrapResize", { clear = true }),
    callback = function()
      pcall(vim.diagnostic.show)
    end,
  })
end

return M
