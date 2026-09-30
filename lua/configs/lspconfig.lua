require("nvchad.configs.lspconfig").defaults()

-- 使用 Neovim 0.11+ 的 vim.lsp.enable 启动 LSP 服务器。
--
-- ⚠ 这里的名字必须是「lspconfig 的服务器名」，不是 Mason 的包名，写错不会报错，
--   但服务器永远不会启动（vim.lsp.enable 对未知名字静默忽略）。对照表：
--     Markdown → marksman；harper_ls（不是 harper-ls）
--     Bash/Sh  → bashls（Mason 包名是 bash-language-server）
--     Lua      → lua_ls（NvChad 默认已启用，无需在此重复）
--   服务器本体由 Mason 安装，见 plugins/init.lua 的 ensure_installed 列表
--   （那份列表由 configs/mason.lua 在启动后补齐缺失项）。
-- 调整服务器选项见 :h vim.lsp.config
vim.lsp.enable({
	"html",
	"clangd",
	"pyright",
	"marksman", -- Markdown
	"harper_ls", -- Markdown 语法/文风检查（注意是下划线）
	"bashls", -- Bash / Sh（配合 shellcheck 出诊断）
})
