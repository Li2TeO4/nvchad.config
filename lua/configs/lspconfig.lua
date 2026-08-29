require("nvchad.configs.lspconfig").defaults()

-- 使用 Neovim 0.11+ 的 vim.lsp.enable 启动 LSP 服务器，
-- 服务器本体由 Mason 安装（见 plugins/init.lua 的 ensure_installed）。
-- 调整服务器选项见 :h vim.lsp.config
vim.lsp.enable({ "html", "clangd", "pyright" })
