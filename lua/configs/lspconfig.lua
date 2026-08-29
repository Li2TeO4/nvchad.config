require("nvchad.configs.lspconfig").defaults()

-- 使用 Neovim 0.11+ 的 vim.lsp.enable 启动 LSP 服务器，
-- 服务器本体由 Mason 安装（见 plugins/init.lua 的 ensure_installed）。
-- 调整服务器选项见 :h vim.lsp.config
vim.lsp.enable({ "html", "clangd", "pyright" })

-- 补充 NvChad v2.5 默认没有绑定的 LSP 键位（buffer-local，LSP attach 后生效）
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = "LSP " .. desc })
    end
    map("K", vim.lsp.buf.hover, "悬浮文档")
    map("gr", vim.lsp.buf.references, "查看引用")
    map("gi", vim.lsp.buf.implementation, "跳转实现")
  end,
})
