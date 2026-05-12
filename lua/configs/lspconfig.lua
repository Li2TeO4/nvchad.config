require("nvchad.configs.lspconfig").defaults()

-- local servers = { "html", "cssls" }
-- vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers 

local on_attach = require("nvchad.configs.lspconfig").on_attach
local on_init = require("nvchad.configs.lspconfig").on_init
local capabilities = require("nvchad.configs.lspconfig").capabilities

local servers = { "html", "clangd", "pyright" }

-- for _, lsp in ipairs(servers) do
--   local status_ok, lspconfig = pcall(require, "lspconfig")
--   if status_ok then
--     lspconfig[lsp].setup {
--       on_attach = on_attach,
--       on_init = on_init,
--       capabilities = capabilities,
--     }
--   end
-- end

vim.lsp.enable(servers)
