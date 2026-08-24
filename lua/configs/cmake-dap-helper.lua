-- ~/.config/nvim/lua/configs/cmake-dap-helper.lua
-- CMake 项目调试辅助：自动解析 compile_commands.json 并触发构建

local M = {}

-- 查找项目根目录（含 CMakeLists.txt）
function M.find_cmake_root()
  local path = vim.fn.expand("%:p:h")
  while path ~= "/" do
    if vim.fn.filereadable(path .. "/CMakeLists.txt") == 1 then
      return path
    end
    path = vim.fn.fnamemodify(path, ":h")
  end
  return vim.fn.getcwd()
end

-- 获取 CMake 构建目录（按优先级查找）
function M.get_build_dir(root)
  local candidates = {
    root .. "/build/Debug",
    root .. "/build/debug",
    root .. "/build",
    root .. "/.build",
  }
  for _, dir in ipairs(candidates) do
    if vim.fn.isdirectory(dir) == 1 then
      return dir
    end
  end
  return root .. "/build"
end

-- 配置 cmake: 生成 Debug 构建系统（需要 cmake 在 PATH 中）
-- 使用列表形式的命令，路径包含空格或特殊字符也不会被 shell 拆坏
function M.cmake_configure(root, build_dir)
  local cmd = {
    "cmake",
    "-S", root,
    "-B", build_dir,
    "-DCMAKE_BUILD_TYPE=Debug",
    "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
  }
  vim.notify("CMake configure: " .. table.concat(cmd, " "), vim.log.levels.INFO)

  local output = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("CMake configure 失败:\n" .. vim.trim(output), vim.log.levels.ERROR)
    return false
  end

  -- 软链 compile_commands.json 到项目根目录（供 clangd 使用）
  local cc = build_dir .. "/compile_commands.json"
  local cc_root = root .. "/compile_commands.json"
  if vim.fn.filereadable(cc) == 1 and vim.fn.filereadable(cc_root) == 0 then
    local link_cmd = { "ln", "-sf", cc, cc_root }
    vim.fn.system(link_cmd)
    if vim.v.shell_error ~= 0 then
      vim.notify("创建 compile_commands.json 软链失败", vim.log.levels.WARN)
    end
  end

  return true
end

-- 触发 cmake --build（异步）并在完成后启动调试
function M.build_and_debug(callback)
  local root      = M.find_cmake_root()
  local build_dir = M.get_build_dir(root)

  -- 若 build 目录不存在则先 configure，配置失败就不继续构建
  if vim.fn.isdirectory(build_dir) == 0 then
    if not M.cmake_configure(root, build_dir) then
      return
    end
  end

  local build_cmd = {
    "cmake",
    "--build", build_dir,
    "--config", "Debug",
    "-j" .. tostring(math.max(1, vim.uv.available_parallelism() or 4)),
  }

  vim.notify("构建中: " .. table.concat(build_cmd, " "), vim.log.levels.INFO)

  -- 使用 vim.fn.jobstart 异步执行（列表形式，避免 shell 拆词）
  local jobid = vim.fn.jobstart(build_cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        vim.notify("构建成功，启动调试器…", vim.log.levels.INFO)
        if callback then
          vim.schedule(callback)
        end
      else
        vim.notify("构建失败 (exit " .. exit_code .. ")", vim.log.levels.ERROR)
      end
    end,
  })

  if jobid <= 0 then
    vim.notify("无法启动构建进程", vim.log.levels.ERROR)
  end
end

-- 快捷命令：构建 + 调试
vim.api.nvim_create_user_command("CMakeDebug", function()
  M.build_and_debug(function()
    require("dap").continue()
  end)
end, { desc = "CMake build (Debug) then launch DAP" })

-- 快捷命令：仅配置
vim.api.nvim_create_user_command("CMakeConfigure", function()
  local root      = M.find_cmake_root()
  local build_dir = M.get_build_dir(root)
  if M.cmake_configure(root, build_dir) then
    vim.notify("CMake configure 完成: " .. build_dir, vim.log.levels.INFO)
  end
end, { desc = "CMake configure (Debug + compile_commands)" })

return M
