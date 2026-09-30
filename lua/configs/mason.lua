-- Mason 工具自动补齐
--
-- 背景：mason.nvim 的 setup() 并不支持 ensure_installed 选项，所以 plugins/init.lua
-- 里那份 ensure_installed 列表默认是「死配置」，不会自动装任何东西。
-- 这里用 mason-registry 的 API 自己实现：启动后在后台检查列表，缺失的自动安装。
-- 安装是异步的，失败只会提示，不影响正常使用（装好后重开会话即可生效）。

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

  local ok_load, err = pcall(function()
    require("lazy").load({ plugins = { "mason.nvim" } })
  end)
  if not ok_load then
    vim.notify("[mason] 加载失败：" .. tostring(err), vim.log.levels.WARN)
    return
  end

  local registry = require("mason-registry")
  registry.refresh(function()
    local missing = {}
    for _, name in ipairs(tools) do
      local ok_pkg, pkg = pcall(registry.get_package, name)
      if not ok_pkg then
        vim.notify("[mason] 注册表中没有该包：" .. name, vim.log.levels.WARN)
      elseif not pkg:is_installed() then
        missing[#missing + 1] = pkg
      end
    end

    if #missing == 0 then
      return
    end

    vim.notify(
      "[mason] 自动安装缺失工具：" .. table.concat(vim.tbl_map(function(p)
        return p.name
      end, missing), ", "),
      vim.log.levels.INFO
    )
    for _, pkg in ipairs(missing) do
      pkg:install({}, function(success)
        if not success then
          vim.notify("[mason] 安装失败：" .. pkg.name, vim.log.levels.WARN)
        end
      end)
    end
  end)
end

return M
