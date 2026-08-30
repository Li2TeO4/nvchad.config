require "nvchad.options"

-- add yours here!

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.numberwidth = 4
vim.opt.listchars		= { tab = ">-", trail = "-" }
vim.opt.list			= true

vim.opt.expandtab		= false
vim.opt.tabstop			= 4
vim.opt.shiftwidth		= 4
vim.opt.softtabstop		= 4

local o = vim.o
o.cursorlineopt			='both' -- to enable cursorline!
o.number				= true
o.relativenumber		= true
o.numberwidth			= 4
o.undofile				= true
