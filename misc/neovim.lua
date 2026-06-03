local pax = require('pax')
local util = require('util')

local M = {}

function M.build(version)
  local v = version or "0.10.4"
  util.clone({
    repo   = "git@github.com:neovim/neovim.git",
    depth  = 1,
    branch = "v" .. v, -- "v0.10.4" .. version,
  })

  -- TODO make sure the host has neovim's build dependancies
  --
  --  $ sudo apt install ninja-build gettext cmake curl build-essential
  --
  -- See BUILD.md
  pax.in_dir("./.pax/repos/neovim", function()
    if pax.fs.exists("build/nvim-linux64.deb") then
      return
    end
    pax.log("building neovim")
    pax.sh [[ make CMAKE_BUILD_TYPE=Release ]]
    pax.in_dir("./build", function()
      pax.log("packaging neovim for debian")
      pax.sh("cpack -G DEB")
    end)
  end)
end

---@param release table|nil
---@return string
function M.min_libc_version(release)
  if release == nil then
    release = util.os_release()
  end
  if
      (release["ID"] == "debian" and release['VERSION_ID'] == "13") or
      (release["ID"] == "ubuntu" and release["VERSION_ID"] == "26.04")
  then
    return "2.38"
  end
  return "2.36"
end

return M
