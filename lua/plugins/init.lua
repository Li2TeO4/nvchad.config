return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

 "nvim-lua/plenary.nvim",
 { "nvim-tree/nvim-web-devicons", lazy = true },

 {
   "nvchad/ui",
    config = function()
      require "nvchad"
    end
 },

 {
    "nvchad/base46",
    lazy = true,
    build = function()
      require("base46").load_all_highlights()
    end,
 },
 {
    "nvim-tree/nvim-tree.lua",
    opts = {
    view = {
       width = {
         min = 10,
         max = 50,
         padding = 2,
       },
      },
    },
  },

  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "lua-language-server",
        "stylua",
        "html-lsp",
        "css-lsp",
        "pyright",
        "typescript-language-server",
        "clangd",
      },
    },
  },

	{
		"HiPhish/rainbow-delimiters.nvim",
		event = "BufReadPost",
		submodules = false,
		config = true,
		main = "rainbow-delimiters.setup",
	},

{
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    bigfile = { enabled = true },
    dashboard = { enabled = false },
    explorer = { enabled = true },
    indent = { enabled = false }, -- NvChad 已启用 indent-blankline，避免重复画缩进线
    input = { enabled = true },
    picker = { enabled = true },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
  },
},
{
	"cappyzawa/trim.nvim",
	event = "BufWritePre",
	opts = {},
	config = function(_, opts)
		require("trim").setup(opts)
	end,
},

	{
	  "hrsh7th/nvim-cmp",
	  opts = function()
	    local cmp = require "cmp"
	    local conf = require "nvchad.configs.cmp" -- 加载 NvChad 默认配置

    -- 冲突处理：如果自定义了快捷键，可能需要调整默认的 Tab 行为
    conf.mapping = cmp.mapping.preset.insert {
      -- 1. 回车确认补全
      ["<CR>"] = cmp.mapping.confirm { select = true },

      -- 2. Tab：补全菜单可见时确认；确认后/展开 snippet 后跳到下一个占位符
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.confirm { select = true }
        elseif require("luasnip").expand_or_jumpable() then
          require("luasnip").expand_or_jump()
        else
          fallback()
        end
      end, { "i", "s" }),

      -- 3. Shift+Tab：跳到上一个 snippet 占位符
      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif require("luasnip").jumpable(-1) then
          require("luasnip").jump(-1)
        else
          fallback()
        end
      end, { "i", "s" }),

      -- 4. 使用 Alt + j/k 上下选择
      ["<A-j>"] = cmp.mapping.select_next_item(),
      ["<A-k>"] = cmp.mapping.select_prev_item(),

      -- 保留原有的上下箭头或 Ctrl-n/p 支持（可选）
      ["<C-p>"] = cmp.mapping.select_prev_item(),
      ["<C-n>"] = cmp.mapping.select_next_item(),
    }

	    return conf
	  end,
	},
	  {
    "numToStr/Comment.nvim",
    -- stylua: ignore
    keys = {
      { "<leader>/", function() require("Comment.api").toggle.linewise.current() end,	mode = "n", desc = "[Comment] Comment current line", },
      { "<leader>/", "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>", mode = "v", desc = "Comment current line",           },
      -- control + / keymappings
      { "<C-_>",     function() require("Comment.api").toggle.linewise.current() end,	mode = "n", desc = "[Comment] Comment current line", },
      { "<C-_>",     "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>", mode = "v", desc = "Comment current line",           },
    },
    config = true,
  },
 "nvchad/volt", -- optional, needed for theme switcher
 -- or just use Telescope themes

  -- ╭─────────────────────────────────────────╮
  -- │              Git 工具                    │
  -- ╰─────────────────────────────────────────╯

  -- gitsigns: 行号旁显示增删改标记、blame、hunk 操作
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = require("configs.gitsigns").opts,
    config = function(_, opts)
      local gs = require("gitsigns")
      gs.setup(opts)

      -- Hunk 导航
      vim.keymap.set("n", "]h", function()
        if vim.wo.diff then vim.cmd.normal({ "]c", bang = true })
        else gs.nav_hunk("next") end
      end, { desc = "[Git] Next hunk" })

      vim.keymap.set("n", "[h", function()
        if vim.wo.diff then vim.cmd.normal({ "[c", bang = true })
        else gs.nav_hunk("prev") end
      end, { desc = "[Git] Prev hunk" })

      -- Hunk 操作
      vim.keymap.set("n", "<leader>hs", gs.stage_hunk,        { desc = "[Git] Stage hunk" })
      vim.keymap.set("n", "<leader>hr", gs.reset_hunk,        { desc = "[Git] Reset hunk" })
      vim.keymap.set("n", "<leader>hS", gs.stage_buffer,      { desc = "[Git] Stage buffer" })
      vim.keymap.set("n", "<leader>hR", gs.reset_buffer,      { desc = "[Git] Reset buffer" })
      vim.keymap.set("n", "<leader>hu", gs.undo_stage_hunk,   { desc = "[Git] Undo stage hunk" })
      vim.keymap.set("n", "<leader>hp", gs.preview_hunk,      { desc = "[Git] Preview hunk" })
      vim.keymap.set("v", "<leader>hs", function()
        gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, { desc = "[Git] Stage selected hunk" })
      vim.keymap.set("v", "<leader>hr", function()
        gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, { desc = "[Git] Reset selected hunk" })

      -- Blame
      vim.keymap.set("n", "<leader>gb", gs.toggle_current_line_blame, { desc = "[Git] Toggle line blame" })
      vim.keymap.set("n", "<leader>gB", function() gs.blame_line({ full = true }) end, { desc = "[Git] Blame line (full)" })

      -- Diff
      vim.keymap.set("n", "<leader>gd", gs.diffthis,          { desc = "[Git] Diff this" })
      vim.keymap.set("n", "<leader>gD", function() gs.diffthis("~") end, { desc = "[Git] Diff this ~" })

      -- Text object: ih = inner hunk
      vim.keymap.set({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "[Git] Select hunk" })
    end,
  },

  -- diffview: 文件树 diff 视图 + Git 历史
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles" },
    keys = {
      { "<leader>gv", "<CMD>DiffviewOpen<CR>",             desc = "[Git] Diff view (working tree)" },
      { "<leader>gV", "<CMD>DiffviewClose<CR>",            desc = "[Git] Close diff view" },
      { "<leader>gh", "<CMD>DiffviewFileHistory %<CR>",    desc = "[Git] File history (current)" },
      { "<leader>gH", "<CMD>DiffviewFileHistory<CR>",      desc = "[Git] File history (repo)" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        default = { layout = "diff2_horizontal" },
        merge_tool = { layout = "diff3_horizontal", disable_diagnostics = true },
      },
      file_panel = {
        listing_style = "tree",
        win_config = { width = 35 },
      },
      hooks = {
        diff_buf_read = function(bufnr)
          vim.opt_local.wrap = false
          vim.opt_local.list = false
        end,
      },
    },
  },

  -- lazygit: 全功能 Git TUI（需本机已安装 lazygit）
  {
    "kdheepak/lazygit.nvim",
    cmd = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile", "LazyGitFilter" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>gg", "<CMD>LazyGit<CR>",            desc = "[Git] Open LazyGit" },
      { "<leader>gf", "<CMD>LazyGitCurrentFile<CR>", desc = "[Git] LazyGit (current file)" },
    },
    config = function()
      vim.g.lazygit_floating_window_winblend = 0
      vim.g.lazygit_floating_window_scaling_factor = 0.9
      vim.g.lazygit_floating_window_border_chars = { "╭","─","╮","│","╯","─","╰","│" }
      vim.g.lazygit_use_neovim_remote = 0
    end,
  },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  -- {
  -- 	"nvim-treesitter/nvim-treesitter",
  -- 	opts = {
  -- 		ensure_installed = {
  -- 			"vim", "lua", "vimdoc",
  --      "html", "css"
  -- 		},
  -- 	},
  -- },
}
