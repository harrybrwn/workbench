local pax = require('pax')
local paxutil = require('misc.paxutil')

local M = {}

---@param repo string
---@param project pax.Project
function M.add_files(repo, project)
  local join = require('pax').path.join
  local base = join(repo, "extra")
  for _, o in pairs({
    { i = join(base, "man/alacritty.1.scd"),          o = "man1/alacritty.1" },
    { i = join(base, "man/alacritty-msg.1.scd"),      o = "man1/alacritty-msg.1" },
    { i = join(base, "man/alacritty.5.scd"),          o = "man5/alacritty.5" },
    { i = join(base, "man/alacritty-bindings.5.scd"), o = "man5/alacritty-bindings.5" },
  }) do
    project:scdoc({ input = o.i, output = o.o })
  end
  project:add_files({
    paxutil.bash_comp(join(base, "completions/alacritty.bash"), "alacritty"),
    paxutil.zsh_comp(join(base, "completions/_alacritty")),
    paxutil.fish_comp(join(base, "completions/alacritty.fish")),
    {
      src = join(base, "linux/Alacritty.desktop"),
      dst = "/usr/share/applications/Alacritty.desktop",
      mode = pax.octal("0644"),
    },
    {
      src = join(base, "linux/org.alacritty.Alacritty.appdata.xml"),
      dst = "/usr/share/metainfo/org.alacritty.Alacritty.appdata.xml",
      mode = pax.octal("0644"),
    },
    {
      src = join(base, "logo/alacritty-term.svg"),
      dst = "/usr/share/pixmaps/Alacritty.svg",
      mode = pax.octal("0644"),
    },
    {
      src = join(base, "logo/compat/alacritty-term.png"),
      dst = "/usr/share/pixmaps/Alacritty.png",
      mode = pax.octal("0644"),
    },
  })
end

return M
