-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}

M.base46 = {
	theme = "catppuccin",
	transparency = true,

	hl_override = {
		        -- === 1. Tabufline ===
        TbBufOn         = { fg = "#89b4fa", bold = true },
        TbBufOnModified = { fg = "#f9e2af" },
        TbBufOff        = { fg = "#cdd6f4" },
        TbFill          = { bg = "none" },

        -- === 2. NvDash ===
        NvDashAscii   = { fg = "#b4befe" },   -- 大 N Logo
        NvDashButtons = { fg = "#cdd6f4" },   -- 按钮文字
        NvDashFooter  = { fg = "#7f849c" },   -- 底部文字（原 NvChadStatus 位置）

		Comment			= { italic = true, fg = "#7f849c" },
		LineNr			= { fg = "#6c7086" },
		CursorLineNr	= { bold = true, fg = "#b4befe" },
		["@comment"]	= { italic = true, fg = "#7f849c" },

		CmpBorder    = { fg = "#FEB1D4" },
		CmpDocBorder = { fg = "#FEB1D4" },
	},
	   -- hl_add 用于新增或强制覆盖任意高亮组
    hl_add = {
		FloatBorder  = { fg = "#00ffff" },
		TelescopeBorder = { fg = "#00ffff" },
		MasonHeader          = { fg = "#00ffff" },
		MasonHeaderSecondary = { fg = "#00ffff" },
		DapUIFloatBorder = { fg = "#00ffff" },
		NvimTreeWindowPicker = { fg = "#00ffff", bold = true },

		-- 文件树行号：由主行号配色同族演化 —— 色相偏向青绿（H≈190°），
		-- 适当降低饱和度抬高灰度，再用明度拉开深浅两级。
		-- 与编辑器相反：树中更关注目标文件，所以相对行号用浅色、当前行行号用深色。
		NvimTreeLineNr       = { fg = "#B3D4DB" }, -- 相对行号：浅（H190 S35 L78）
		NvimTreeCursorLineNr = { fg = "#56868F" }, -- 当前行号：深（H190 S25 L45）
    },
}

M.nvdash = { load_on_startup = true }

M.ui = {
  tabufline = {
    lazyload = false
  }
}

return M
