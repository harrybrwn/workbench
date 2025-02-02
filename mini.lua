-- A simplified version for my work computer

local pax = require("pax")

local p = pax.project({
  package  = "workbench-mini",
  version  = "0.0.1",
  section  = "devel",
  arch     = "amd64",
  author   = pax.git.username(),
  email    = "me@h3y.sh",
  homepage = "https://github.com/harrybrwn/workbench",
  priority = pax.Priority.Optional,
})

-- pax.git.clone("git@github.com:neovim/neovim.git")
pax.git.clone("git@github.com:alacritty/alacritty.git", {
  repo   = "git@github.com:alacritty/alacritty.git",
  branch = "v0.11.0",
  dest   = pax.path.join(p:dir(), "repos", "alacritty"),
})
p:cargo_build({ root = pax.path.join(p:dir(), "repos/alacritty") })

return { project = p }
