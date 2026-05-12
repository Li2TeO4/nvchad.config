local M = {}

M.opts = {
  signs = {
    add          = { text = "▎" },
    change       = { text = "▎" },
    delete       = { text = "" },
    topdelete    = { text = "" },
    changedelete = { text = "▎" },
    untracked    = { text = "▎" },
  },
  signs_staged = {
    add          = { text = "▎" },
    change       = { text = "▎" },
    delete       = { text = "" },
    topdelete    = { text = "" },
    changedelete = { text = "▎" },
  },
  signs_staged_enable = true,
  signcolumn = true,
  numhl = false,
  linehl = false,
  word_diff = false,
  watch_gitdir = { follow_files = true },
  auto_attach = true,
  attach_to_untracked = false,
  current_line_blame = false, -- 用 <leader>gb 手动切换
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = "eol",
    delay = 500,
    ignore_whitespace = false,
  },
  current_line_blame_formatter = "  <author>, <author_time:%Y-%m-%d> · <summary>",
  preview_config = {
    border = "rounded",
    style = "minimal",
    relative = "cursor",
    row = 0,
    col = 1,
  },
}

return M
