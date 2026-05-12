-- ~/.config/nvim/lua/plugins/dap.lua
-- DAP 插件配置 (NvChad / lazy.nvim)

return {
  -- 核心 DAP 引擎
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio", -- nvim-dap-ui 依赖
    },
    config = function()
      require("configs.dap")
    end,
  },

  -- 调试 UI 面板
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
      require("configs.dap-ui")
    end,
  },

  -- 行内变量值显示
  {
    "theHamsta/nvim-dap-virtual-text",
    config = function()
      require("nvim-dap-virtual-text").setup({
        enabled = true,
        commented = false,
        virt_text_pos = "eol",
        highlight_changed_variables = true,
        highlight_new_as_changed = false,
        show_stop_reason = true,
      })
    end,
  },

  -- Telescope 集成（搜索断点、帧、命令）
  {
    "nvim-telescope/telescope-dap.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "mfussenegger/nvim-dap" },
    config = function()
      require("telescope").load_extension("dap")
    end,
  },

  -- Mason 自动安装 DAP 适配器
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "mfussenegger/nvim-dap",
    },
    config = function()
      require("mason-nvim-dap").setup({
        ensure_installed = { "codelldb", "debugpy" },
        automatic_installation = true,
        handlers = {}, -- 使用默认 handler，下方 configs/dap.lua 会覆盖
      })
    end,
  },
}
