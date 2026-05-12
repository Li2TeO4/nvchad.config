-- ~/.config/nvim/lua/configs/dap-ui.lua
-- nvim-dap-ui 布局与外观配置

local dapui = require("dapui")

dapui.setup({
  icons = {
    expanded  = "▾",
    collapsed = "▸",
    current_frame = "▶",
  },
  mappings = {
    expand        = { "<CR>", "<2-LeftMouse>" },
    open          = "o",
    remove        = "d",
    edit          = "e",
    repl          = "r",
    toggle        = "t",
  },
  -- 展开时使用 floating window
  expand_lines = vim.fn.has("nvim-0.7") == 1,
  -- 侧边栏布局
  layouts = {
    {
      elements = {
        { id = "scopes",      size = 0.35 },
        { id = "breakpoints", size = 0.15 },
        { id = "stacks",      size = 0.25 },
        { id = "watches",     size = 0.25 },
      },
      size     = 40,   -- 列宽（字符数）
      position = "left",
    },
    {
      elements = {
        { id = "repl",    size = 0.5 },
        { id = "console", size = 0.5 },
      },
      size     = 10,   -- 行高（百分比）
      position = "bottom",
    },
  },
  controls = {
    -- 在底部 REPL 面板显示控制按钮
    enabled = true,
    element = "repl",
    icons = {
      pause         = "⏸",
      play          = "▶",
      step_into     = "⬇",
      step_over     = "⤵",
      step_out      = "⬆",
      step_back     = "◀",
      run_last      = "↺",
      terminate     = "⏹",
      disconnect    = "⏏",
    },
  },
  floating = {
    max_height  = 0.9,
    max_width   = 0.5,
    border      = "rounded",
    mappings    = { close = { "q", "<Esc>" } },
  },
  windows = { indent = 1 },
  render = {
    max_type_length = nil,
    max_value_lines = 100,
  },
})
