-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}

M.base46 = {
	theme = "aquarium",
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
    },
}

M.nvdash = { load_on_startup = true }

M.ui = {
  tabufline = {
    lazyload = false
  }
}

return M
