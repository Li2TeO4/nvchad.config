-- ~/.config/nvim/lua/plugins/dap.lua
-- DAP 插件配置 (NvChad / lazy.nvim)

return {
  -- 核心 DAP 引擎
  {
    "mfussenegger/nvim-dap",
    -- 第一次按这些键时才加载 DAP，不再随 Neovim 启动加载
    keys = {
      { "<F5>", mode = "n" },
      { "<F9>", mode = "n" },
      { "<F10>", mode = "n" },
      { "<F11>", mode = "n" },
      { "<F12>", mode = "n" },
      { "<leader>d", mode = { "n", "v" } },
    },
    dependencies = {
      "jay-babu/mason-nvim-dap.nvim", -- DAP 首次加载时初始化 Mason 适配器安装
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio", -- nvim-dap-ui 依赖
    },
    config = function()
      require("configs.dap")
      require("configs.dap-keymaps")
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
    cmd = { "DapInstall", "DapUninstall" },
    dependencies = {
      "williamboman/mason.nvim",
      "mfussenegger/nvim-dap",
    },
    config = function()
      require("mason-nvim-dap").setup({
        ensure_installed = { "codelldb", "debugpy" },
        automatic_installation = true,
        -- 只保留 Mason 安装/卸载能力，不让它重复注册 adapter/config，
        -- 避免和 configs/dap.lua 里手写的配置打架
        handlers = { function() end },
      })
    end,
  },
}
