local pax = require('pax')
local util = require('util')

local function build(version)
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
    pax.sh [[ make CMAKE_BUILD_TYPE=Release ]]
    pax.in_dir("./build", function()
      pax.sh("cpack -G DEB")
    end)
  end)
end

return { build = build }
