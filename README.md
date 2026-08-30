# Neovim 配置使用说明

> 基于 **NvChad v2.5** + **lazy.nvim**，主题 **catppuccin**（透明背景）。
> 面向 **C/C++**（clangd + codelldb + CMake）、**Python**（pyright + debugpy）、
> **Web**（html/css/json）与 **Lua** 开发，重点是 DAP 调试与 Git 工作流。

---

## 0. 必读：记不住键位怎么办

| 方式 | 按键 | 说明 |
|---|---|---|
| which-key 菜单 | 按一下 `<leader>`（空格）稍等 | 弹出当前可用键位分组菜单 |
| which-key 总览 | `<leader>wK` | 列出所有键位 |
| NvChad 键位速查表 | `<leader>ch` | 内置 cheatsheet（grid 布局，再按一次关闭） |
| 本文件 | — | 最全的速查表在文末第 14 节 |

**按键记号**：`<leader>` = 空格，`<C-x>` = Ctrl+x，`<A-x>` = Alt+x，`<S-x>` = Shift+x，`<CR>` = 回车。


---

## 1. 这套配置的结构（改配置时找这里）

```
init.lua                  入口：bootstrap lazy + NvChad + 加载各模块
lua/chadrc.lua            外观：主题 catppuccin、透明、边框/高亮配色
lua/options.lua           基础选项：Tab=4、显示 tab/行尾、行号、undo 持久化
lua/mappings.lua          NvChad 默认键位 + CMake 辅助命令注册
lua/autocmds.lua          LazyDone 后重新应用高亮
lua/myconfig.lua          启动时加载的通用模块汇总
lua/plugins/init.lua      插件清单（LSP/Mason/补全/Git/snacks…）
lua/plugins/dap.lua       调试插件组（懒加载，首次按 F5/F9 才加载）
lua/configs/keymaps.lua   ★ 你的通用键位（唯一出处，加键位改这里）
lua/configs/function-keymaps.lua  行尾加分号/删末尾字符
lua/configs/scrollpad.lua 自研非对称滚动（光标距底部 4 行自动滚屏）
lua/configs/lspconfig.lua LSP：启用 html / clangd / pyright（lua_ls 由 NvChad 默认启用）
lua/configs/dap.lua       DAP 核心：适配器、C/C++/Python 调试配置、断点符号
lua/configs/dap-ui.lua    DAP UI 布局（左侧栏 + 底部 REPL）
lua/configs/dap-keymaps.lua 调试键位（F 键 + <leader>d 系列）
lua/configs/cmake-dap-helper.lua  :CMakeDebug / :CMakeConfigure 命令
lua/configs/conform.lua   格式化：lua → stylua
lua/configs/gitsigns.lua  gitsigns 符号与行内 blame 样式
lua/configs/lazy.lua      lazy 性能设置（禁用 netrw 等内置插件）
```

---

## 2. 安装与维护

- **首次启动**：`nvim` 会自动 clone lazy.nvim 并安装全部插件（`lazy-lock.json` 锁定版本，跨机器一致）。
- **更新插件**：`:Lazy` 打开面板，按 `U` 全部更新，或 `:Lazy sync` 同步到 lock 文件。
- **更新 Mason 工具（LSP/格式化器/调试器）**：`:Mason` 面板内 `U`，或 `:MasonUpdate`。
- **健康检查**：`:checkhealth`。
- **换主题**：`<leader>th` 打开主题选择器（catppuccin 为当前主题，volt 支持实时切换）。

---

## 3. 基础编辑键位

| 按键 | 模式 | 功能 |
|---|---|---|
| `jk` | i | 退出插入模式 |
| `<C-h/j/k/l>` | i | 插入模式方向键 |
| `<C-b>` / `<C-e>` | i | 行首 / 行尾（NvChad） |
| `<C-o>` | i | 换行插入（等价 `o`） |
| `<S-H>` / `<S-L>` | n/x/o | 跳到行首 `^` / 行尾 `$` |
| `J` / `K` | v | 整行下移 / 上移（保持缩进） |
| `<A-.>` | n/i | 在行尾追加分号 `;`（不移动光标） |
| `<C-x>` | n/i | 删除行尾最后一个字符（不移动光标） |
| `<C-s>` | n/i/v | 保存 |
| `ww` / `wq` | n/x | 保存 / 保存退出 |
| `<leader>q` / `<leader>Q` | n/x | 退出 / 强制退出 |
| `<leader>ww` / `<leader>wq` / `<leader>W` | n | 保存 / 保存退出 / 强制保存 |
| `<A-z>` | n | 切换自动换行 wrap |
| `<leader>nh` 或 `<Esc>` | n | 取消搜索高亮 |
| `<C-c>` | n | 复制整个文件到系统剪贴板（NvChad） |
| `<leader>n` / `<leader>rn` | n | 开关绝对行号 / 相对行号 |
| `u` / `<C-r>` | n | 撤销 / 重做（undo 持久化，跨重启有效） |

---

## 4. 窗口、分屏、Buffer 与终端

| 按键 | 功能 |
|---|---|
| `<C-h/j/k/l>` | 在窗口间移动（左/下/上/右） |
| `<leader>sv` | 左右分屏（垂直分割） |
| `<leader>sh` | 上下分屏（水平分割） |
| `<Tab>` / `<S-Tab>` | 切换到下一个 / 上一个 buffer |
| `<C-t>` | 关闭当前 buffer（tabufline 的标签） |
| `<leader>x` | 关闭当前 buffer（NvChad 默认） |
| `<leader>b` | 新建空 buffer |
| `<leader>to` / `<leader>tx` | 新建 / 关闭 Vim 标签页 |
| `<C-n>` | 开关文件树 nvim-tree |
| `<leader>e` | 聚焦文件树（NvChad 默认覆盖了自定义的 Toggle，见第 13 节） |
| `<leader>h` / `<leader>v` | 新开横向 / 纵向终端 |
| `<A-i>` | 开关浮动终端 |
| `<A-h>` / `<A-v>` | 开关横向 / 纵向侧边终端 |
| `<Esc>` / `jk` / `<C-x>` | 终端模式（t）：退出 insert → normal |
| `<leader>q` | 关闭终端窗口（终端退出 insert 后使用） |

**nvim-tree 面板内**：`<CR>` 打开文件，`a` 新建，`d` 删除，`r` 重命名，`R` 刷新，`c`/`x`/`p` 复制/剪切/粘贴。

---

## 5. 搜索与文件查找（Telescope）

| 按键 | 功能 |
|---|---|
| `<leader>ff` | 查找文件（忽略 .gitignore） |
| `<leader>fa` | 查找所有文件（含隐藏/忽略） |
| `<leader>fw` | 全项目文本搜索（live grep） |
| `<leader>fb` | 打开的 buffer 列表 |
| `<leader>fo` | 最近打开过的文件 |
| `<leader>fz` | 当前 buffer 内模糊查找 |
| `<leader>fh` | 帮助文档搜索 |
| `<leader>ma` | 跳转标记 marks |
| `<leader>pt` | 切换隐藏终端 |
| `<leader>gt` | git status（Telescope） |
| `<leader>cm` | git commits（Telescope） |

**Telescope 列表内**：`<C-j/k>` 上下移动，`<CR>` 打开，`<C-x>` 水平分屏打开，`<C-v>` 垂直分屏打开，`<C-t>` 新标签页打开，`<Esc>` 退出。

> snacks.nvim 的 picker / explorer 模块已启用但**未绑定键位**（无默认键），
> 需要时可用 Lua 调用（如 `:lua require("snacks.picker").files()`）；
> 其余模块（bigfile 大文件保护、notifier 通知、scroll 平滑滚动、scope、words、
> quickfile 快速恢复上次文件等）随事件自动生效，无需操作。

---

## 6. LSP（语言服务器）

### 6.1 已启用服务器

| 语言 | 服务器 | 来源 |
|---|---|---|
| Lua | lua_ls | NvChad 默认启用 |
| C/C++ | clangd | `lua/configs/lspconfig.lua` |
| Python | pyright | 同上 |
| HTML | html-lsp | 同上 |

（Mason 里还装了 json-lsp、neocmakelsp、stylua，可按需在 lspconfig.lua 中追加。）

### 6.2 键位（LSP attach 到 buffer 后生效）

| 按键 | 功能 |
|---|---|
| `gd` | 跳转到定义 |
| `gD` | 跳转到声明 |
| `<leader>D` | 跳转到类型定义 |
| `<leader>ra` | 重命名（NvRenamer 浮动窗口） |
| `<leader>wa` / `<leader>wr` / `<leader>wl` | 添加 / 移除 / 列出 workspace 目录 |
| `[d` / `]d` | 上一个 / 下一个诊断（Neovim 0.12 内置） |
| `<C-w>d` | 悬浮显示光标处诊断详情（内置） |
| `<leader>ds` | 诊断列表（loclist）——⚠ DAP 加载后此键被 DAP 的"查看作用域"覆盖，见 10.3 |

> ⚠ NvChad v2.5 没有绑定 `K`（悬浮文档）、`gr`（引用）、`gi`（实现）。
> 需要时自行映射或在命令里用：
> `:lua vim.lsp.buf.hover()` / `vim.lsp.buf.references()` / `vim.lsp.buf.implementation()`。

### 6.3 管理服务器

- `:Mason` 打开安装面板：`i` 安装、`X` 卸载、`U` 更新、`g?` 查看全部操作。
- 新增语言：先在 `lua/configs/lspconfig.lua` 的 `vim.lsp.enable({...})` 列表中加入服务器名，再用 Mason 安装对应工具。

### 6.4 clangd 特别说明

clangd 依赖 `compile_commands.json` 才能正确解析头文件路径：
- CMake 项目用 `:CMakeConfigure` 会自动生成并**软链到项目根目录**（见第 11 节）；
- 报"找不到头文件"时优先检查项目根目录有没有 `compile_commands.json`。

---

## 7. 补全（nvim-cmp + LuaSnip + autopairs）

- 输入时自动弹出补全菜单，来源：LSP、buffer、路径、Lua API、snippets。
- `()[]{}""''` 等自动配对（autopairs）。

| 按键 | 功能 |
|---|---|
| `<CR>` / `<Tab>` | 确认选中的补全项 |
| `<S-Tab>` | 菜单可见时选上一项；确认后跳回上一个 snippet 占位符 |
| `<A-j>` / `<A-k>` | 下一个 / 上一个候选项 |
| `<C-n>` / `<C-p>` | 下一个 / 上一个候选项 |
| `<Tab>`（确认后） | 跳到下一个 snippet 占位符 |

---

## 8. 格式化（conform）

| 按键 | 功能 |
|---|---|
| `<leader>fm` | 格式化当前文件（n/x，LSP fallback） |

- 当前只对 **lua** 启用了 stylua（Mason 已装）；
- css/html 的 prettier 配置被注释掉了，需要时取消 `lua/configs/conform.lua` 中的注释并安装 prettier。

---

## 9. Git 工作流

### 9.1 gitsigns（行内改动标记）

| 按键 | 功能 |
|---|---|
| `]h` / `[h` | 下一个 / 上一个 hunk |
| `<leader>hs` | 暂存当前 hunk（v 模式：暂存选中行） |
| `<leader>hr` | 重置当前 hunk（v 模式：重置选中行） |
| `<leader>hS` / `<leader>hR` | 暂存 / 重置整个 buffer |
| `<leader>hu` | 撤销暂存 |
| `<leader>hp` | 预览 hunk |
| `<leader>gb` | 开关当前行 blame |
| `<leader>gB` | 完整 blame（提交详情窗口） |
| `<leader>gd` / `<leader>gD` | 与 HEAD 的 diff / 与 HEAD~ 的 diff |
| `ih` | hunk 文本对象（如 `vih` 选中 hunk） |

### 9.2 diffview（文件树式 diff 与历史）

| 按键 | 功能 |
|---|---|
| `<leader>gv` | 打开工作区 diff 视图（左右对比所有改动文件） |
| `<leader>gV` | 关闭 diff 视图 |
| `<leader>gh` | 当前文件的提交历史 |
| `<leader>gH` | 整个仓库的提交历史 |
| 或 `:DiffviewOpen` / `:DiffviewFileHistory` | 同上（命令形式） |

### 9.3 lazygit（全功能 Git TUI）

| 按键 | 功能 |
|---|---|
| `<leader>gg` | 打开 lazygit（仓库级别） |
| `<leader>gf` | 打开 lazygit（当前文件） |

> ⚠ **本机尚未安装 lazygit 命令**，这两个键会报错。安装后即可使用：
> Arch: `sudo pacman -S lazygit`；Debian/Ubuntu: `sudo apt install lazygit`；macOS: `brew install lazygit`。

---

## 10. 调试（DAP）——本配置的重头戏

### 10.1 前提

- 调试器已由 Mason 装好：**codelldb**（C/C++）、**debugpy**（Python），随 DAP 插件自动安装；
- DAP 插件懒加载：**第一次按 F5 / F9 或任何 `<leader>d` 前缀键时才加载**。

### 10.2 C/C++ 调试流程

```text
:CMakeConfigure    ① 配置：cmake -S . -B build/Debug（Debug 构建，
                      并软链 compile_commands.json 到项目根目录喂给 clangd）
:CMakeDebug        ② 构建 + 调试：异步 cmake --build 成功后自动启动调试器
    （或直接 F5）  ③ 选调试配置、输入程序参数
```

`F5` 弹出的 **C/C++ 配置**：

| 配置名 | 用途 |
|---|---|
| Launch (CMake Debug build，自动查找) | 在 `bin/`、`bin/Debug`、`build/Debug`、`build` 等 7 个候选目录自动找可执行文件；多个时弹列表选择 |
| Launch (integratedTerminal，有 scanf 的程序) | 用集成终端跑，支持 stdin 交互输入（见下方注意事项） |
| Launch (手动输入可执行文件) | 手动指定路径 |
| Attach to process | 附加到正在运行的进程（弹进程列表） |

- **程序参数输入**支持空格分隔、双引号/单引号包裹、反斜杠转义（如 `"hello world" 'a b'`），直接回车 = 无参数；
- `:CMakeDebug` 构建失败不会启动调试器；构建过程在后台异步执行，不卡编辑器。

### 10.3 调试键位

**F 键（n 模式）**：

| 按键 | 功能 |
|---|---|
| `F5` | 继续 / 启动 |
| `F9` | 切换断点 |
| `F10` | 单步跳过（step over） |
| `F11` | 单步进入（step into） |
| `F12` | 单步跳出（step out） |

**`<leader>d` 前缀（n 模式，`v` 模式仅 dp/de）**：

| 按键 | 功能 |
|---|---|
| `<leader>db` | 切换断点 |
| `<leader>dB` | 条件断点（输入条件表达式） |
| `<leader>dl` | 日志断点（log point，不中断只打印） |
| `<leader>dc` | 继续 |
| `<leader>dn` / `<leader>di` / `<leader>do` | 单步跳过 / 进入 / 跳出 |
| `<leader>dr` | 打开 REPL |
| `<leader>dR` | 重复上次调试配置 |
| `<leader>dq` | 终止调试 |
| `<leader>dx` | 清除所有断点 |
| `<leader>dC` | 运行到光标处 |
| `<leader>dh` | 悬浮显示光标处变量值 |
| `<leader>dp` | 预览表达式（v 模式：预览选中内容） |
| `<leader>df` | 调用栈（浮动窗口） |
| `<leader>ds` | 查看作用域变量（浮动窗口）⚠ 覆盖了 NvChad 的"诊断列表" |
| `<leader>du` | 开关 DAP UI 面板 |
| `<leader>de` | 求值表达式（v 模式：求值选中文本） |

**Telescope DAP**：

| 按键 | 功能 |
|---|---|
| `<leader>dtb` | 搜索所有断点 |
| `<leader>dtf` | 搜索调用栈帧 |
| `<leader>dtc` | 搜索 DAP 命令 |
| `<leader>dtv` | 搜索变量 |

### 10.4 DAP UI 面板

- 启动调试时**自动打开**，结束时自动关闭；`<leader>du` 手动开关；
- 布局：左侧栏（**Scopes** 变量作用域 / **Breakpoints** 断点 / **Stacks** 调用栈 / **Watches** 监视），底部（**REPL** / **Console**）；
- 面板内操作：`<CR>` 展开折叠，`o` 打开，`d` 移除（如移除监视项），`e` 编辑（条件断点等），`r` 进入 REPL，`t` 切换；
- 底部 REPL 栏自带控制按钮（⏸ ▶ ⬇ ⤵ ⬆ ↺ ⏹ 等）；
- **行内变量**：暂停时行尾直接显示变量值（dap-virtual-text），变化过的变量高亮。

### 10.5 断点符号图例

| 符号 | 含义 |
|---|---|
| ● | 普通断点 |
| ◆ | 条件断点 |
| ●（灰） | 被拒绝的断点 |
| ◉ | 日志断点 |
| ▶ | 当前暂停位置 |

### 10.6 Python 调试

`F5` 弹配置选择：

| 配置名 | 用途 |
|---|---|
| Launch (当前文件) | 调试当前打开的 .py |
| Launch with args | 调试当前文件 + 输入参数 |
| pytest (当前文件) | 用 pytest 跑当前文件（`-v`） |
| Attach to remote (debugpy) | 附加远程 debugpy（127.0.0.1:5678） |

- Python 解释器**自动探测**：`VIRTUAL_ENV` → `CONDA_PREFIX` → 项目 `.venv` → 系统 python3。

### 10.7 用 integratedTerminal 跑 scanf 类程序的注意

- 启动调试后会自动在底部打开 `dap-terminal` 终端并进入 insert 模式（可直接输入）；
- 在终端里按 `<Esc>` / `jk` 退出 insert 回到 normal，此时可用 `<C-h/j/k/l>` 在编辑器与终端间切换；
- 不需要时 `<leader>q` 关闭终端窗口。

---

## 11. CMake 辅助命令

| 命令 | 功能 |
|---|---|
| `:CMakeConfigure` | 在 `build/Debug`（优先，其次 `build/debug`、`build`、`.build`）执行 `cmake -S <根> -B <dir> -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON`，并把 `compile_commands.json` 软链到项目根目录（供 clangd） |
| `:CMakeDebug` | 若 build 目录不存在先自动 configure；然后 `cmake --build -j<CPU核数>` 异步构建，成功后自动 `dap.continue()` 启动调试 |

- 项目根目录 = 向上查找最近的 `CMakeLists.txt`；
- 构建使用列表形式的命令，路径含空格也安全。

---

## 12. 滚动行为（scrollpad 自定义模块）

- 原生 `scrolloff` 已禁用，由 `lua/configs/scrollpad.lua` 接管；
- **下方**：光标距窗口底部不足 **4 个视觉行**时强制滚动，即使到文件末尾也保证留 4 行；
- **上方**：尽量保留 4 行，但光标接近文件顶部时允许不足；
- 所有行数按**折行后的视觉行**计算，长行 wrap 场景也准确；
- 如需调整余量，改 `scrollpad.lua` 顶部的 `PAD_BELOW` / `PAD_ABOVE`。

---

## 13. 常见问题与已知事项

| 现象 | 原因与处理 |
|---|---|
| 按 `<leader>gg` 报 lazygit 不存在 | 本机未安装 lazygit，见 9.3 |
| `<leader>e` 不是开关而是聚焦 | NvChad 默认映射（后加载）覆盖了你自定义的 `NvimTreeToggle`；开关请用 `<C-n>`，想要 Toggle 行为可改 `lua/mappings.lua` 或 keymaps 顺序 |
| `<leader>ds` 调试后变成查看作用域 | DAP 加载后覆盖了 NvChad 的"诊断列表"；看诊断列表可用 `:lua vim.diagnostic.setloclist()` |
| clangd 报找不到头文件 | 缺 `compile_commands.json`，CMake 项目执行 `:CMakeConfigure` |
| 想用 K 悬浮文档 / gr 引用 / gi 实现 | NvChad v2.5 未绑定，需自行映射（见 6.2） |
| 首次打开新语言没有高亮/补全 | treesitter 解析器自动装 vim/lua 等；其他语言 `:TSInstall <lang>`，LSP 用 `:Mason` 装 |
| 换机器恢复配置 | `git clone` 后启动 nvim 自动装插件；Mason 工具需 `:Mason` 手动装（列表见 6.3） |
| 更新后界面/键位变化 | 先 `:Lazy sync`；主题高亮问题按 `<leader>th` 重选主题 |

---

## 14. 键位速查总表

| 分类 | 按键 | 功能 |
|---|---|---|
| 编辑 | `jk` | 退出插入 |
| 编辑 | `<A-.>` | 行尾加分号 |
| 编辑 | `<C-x>` | 删行尾字符 |
| 编辑 | `<C-s>` / `ww` / `<leader>ww` | 保存 |
| 编辑 | `<leader>fm` | 格式化 |
| 文件 | `<leader>ff` / `<leader>fa` / `<leader>fo` | 找文件 / 全部 / 最近 |
| 文件 | `<leader>fw` / `<leader>fz` / `<leader>fb` | 全文搜索 / buffer 内 / buffer 列表 |
| 文件 | `<C-n>` | 文件树开关 |
| 窗口 | `<C-h/j/k/l>` | 窗口间移动 |
| 窗口 | `<leader>sv` / `<leader>sh` | 左右 / 上下分屏 |
| Buffer | `<Tab>` / `<S-Tab>` | 上下一个 buffer |
| Buffer | `<C-t>` / `<leader>x` | 关闭 buffer |
| 终端 | `<leader>h` / `<leader>v` / `<A-i>` | 横 / 纵 / 浮动终端 |
| LSP | `gd` / `gD` / `<leader>D` | 定义 / 声明 / 类型定义 |
| LSP | `<leader>ra` | 重命名 |
| LSP | `[d` / `]d` / `<C-w>d` | 诊断导航 / 悬浮诊断 |
| 补全 | `<CR>` / `<Tab>` / `<S-Tab>` | 确认 / 确认 / 上一项 |
| Git | `]h` / `[h` / `<leader>hs` / `<leader>hr` | hunk 导航 / 暂存 / 重置 |
| Git | `<leader>gb` / `<leader>gd` | blame / diff |
| Git | `<leader>gv` / `<leader>gh` | diff 视图 / 文件历史 |
| Git | `<leader>gg`（需 lazygit） | lazygit TUI |
| CMake | `:CMakeConfigure` / `:CMakeDebug` | 配置 / 构建+调试 |
| 调试 | `F5` / `F9` / `F10` / `F11` / `F12` | 继续 / 断点 / 跳过 / 进入 / 跳出 |
| 调试 | `<leader>dc` / `dn` / `di` / `do` / `dq` | 继续 / 跳过 / 进入 / 跳出 / 终止 |
| 调试 | `<leader>db` / `dB` / `dl` / `dx` | 断点 / 条件 / 日志 / 清除 |
| 调试 | `<leader>dr` / `du` / `dh` / `dp` | REPL / UI / hover / 预览 |
| 调试 | `<leader>dR` / `dC` / `de` | 重复上次 / 到光标 / 求值 |
| 主题 | `<leader>th` | 主题切换 |
| 帮助 | `<leader>ch` / `<leader>wK` | 键位速查表 / which-key 总览 |
