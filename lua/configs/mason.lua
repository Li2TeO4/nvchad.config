-- Mason 工具自动补齐
--
-- 背景：mason.nvim 的 setup() 并不支持 ensure_installed 选项，所以 plugins/init.lua
-- 里那份 ensure_installed 列表默认是「死配置」，不会自动装任何东西。
-- 这里用 mason-registry 的 API 自己实现：启动后在后台检查列表，缺失的尝试安装。
--
-- 注意：不要在这里强制 registry.refresh()。mason 更新 registry 需要 wget/gh 之类的
-- 下载工具，本机可能没有，强刷失败只会在 mason.log 里反复刷错误、并拖慢启动。
-- 这里只用本地缓存的 registry；查不到包或安装失败都安静跳过（可随时手动 :Mason 安装）。

local M = {}

function M.ensure_installed()
  -- 从 lazy 的插件规格里读取列表，保证与 plugins/init.lua 单一来源
  local ok_spec, spec = pcall(function()
    return require("lazy.core.config").plugins["mason.nvim"]
  end)
  local tools = ok_spec and spec and spec.opts and spec.opts.ensure_installed
  if type(tools) ~= "table" or #tools == 0 then
    return
  end

  -- 加载 mason（顺带把 mason 的 bin 目录加进 PATH）
  if not pcall(function()
    require("lazy").load({ plugins = { "mason.nvim" } })
  end) then
    return
  end

  -- 只用本地 registry 缓存，不联网刷新
  local ok_reg, registry = pcall(require, "mason-registry")
  if not ok_reg then
    return
  end

  local missing = {}
  for _, name in ipairs(tools) do
    local ok_pkg, pkg = pcall(registry.get_package, name)
    if ok_pkg and not pkg:is_installed() then
      missing[#missing + 1] = pkg
    end
  end
  if #missing == 0 then
    return
  end

  vim.notify(
    "[mason] 尝试安装缺失工具：" .. table.concat(vim.tbl_map(function(p)
      return p.name
    end, missing), ", "),
    vim.log.levels.INFO
  )
  for _, pkg in ipairs(missing) do
    pkg:install({}, function(success)
      if not success then
        vim.notify("[mason] 安装失败：" .. pkg.name .. "（可稍后用 :Mason 手动安装）", vim.log.levels.WARN)
      end
    end)
  end
end

return M
