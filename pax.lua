local pax = require('pax')
local util = require('util')


util.clone("git@github.com:harrybrwn/dots.git", {
  depth = 1,
})
util.clone("git@github.com:harrybrwn/govm.git", {
  depth = 1,
})
util.clone("git@github.com:BurntSushi/ripgrep.git", {
  dest   = "rg",
  depth  = 1,
  branch = "14.1.1",
})
util.clone("git@github.com:XAMPPRocky/tokei.git", {
  dest   = ".pax/repos/tokei",
  depth  = 1,
  branch = "v12.1.2",
})
util.clone("git@github.com:eza-community/eza.git", {
  depth  = 1,
  branch = "v0.20.18",
})
util.clone('git@github.com:neovim/neovim.git', {
  depth  = 1,
  branch = 'v0.10.3',
})
util.clone("git@github.com:alacritty/alacritty.git", {
  depth = 1,
  branch = "v0.15.0",
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

local project = pax.project({
  name         = "workbench",
  package      = "workbench",
  version      = "0.0.1",
  author       = pax.git.username(),
  email        = "me@h3y.sh",
  arch         = "amd64",
  dependencies = {
    "git",
    "curl",
    "tmux",
  },
  priority     = pax.Priority.Optional,
  files        = {
    {
      src  = "pax.lua",
      dst  = "/usr/share/workbench/pax.lua",
      mode = pax.octal("0644"),
    },
    {
      src  = "util.lua",
      dst  = "/usr/share/workbench/util.lua",
      mode = pax.octal("0644"),
    },
    {
      src  = "README.md",
      dst  = "/usr/share/workbench/README.md",
      mode = pax.octal("0644"),
    }
  },
})

project:merge_deb("./.pax/repos/neovim/build/nvim-linux64.deb")
project:download_kubectl()
-- project:download_yt_dlp({ release = "2025.1.15" })
project:add_binary(pax.path.join(project:dir(), "bin/yt-dlp"))
project:download_mc()

-- fonts
local fonts = util.download_fonts(project, {
  "RobotoMono",
  "LiberationMono",
  "FiraMono",
  "SourceCodePro",
})
project:add_files({
  src = fonts .. "/",
  dst = "/usr/share/fonts/truetype",
  mode = pax.octal("0644"),
})

-- k9s
pax.dl.fetch(
  "https://github.com/derailed/k9s/releases/download/v0.32.7/k9s_linux_amd64.deb",
  { out = pax.path.join(project:dir(), "k9s.deb") })
project:merge_deb(pax.path.join(project:dir(), "k9s.deb"))

-- k3d
pax.dl.fetch(
  "https://github.com/k3d-io/k3d/releases/download/v5.8.1/k3d-linux-amd64",
  { out = pax.path.join(project:dir(), "bin", "k3d") })
project:add_binary(pax.path.join(project:dir(), "bin", "k3d"))

-- nvm
pax.dl.fetch(
  "https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh",
  { out = pax.path.join(project:dir(), "bin", "install-nvm.sh") })
project:add_binary(pax.path.join(project:dir(), "bin", "install-nvm.sh"))

project:go_build({
  root     = "./.pax/repos/dots",
  generate = true,
})
project:go_build({
  root     = "./.pax/repos/govm",
  generate = true,
})
project:cargo_build({
  root      = "./.pax/repos/rg",
  verbosity = 1,
  features  = { "pcre2" },
})
util.ripgrep_assets(project, ".pax/repos/rg") -- build and add completion/man
project:cargo_build({
  root      = ".pax/repos/tokei",
  verbosity = 1,
})
project:cargo_build({
  root      = ".pax/repos/eza",
  verbosity = 1,
})

-- requires:
-- $ apt install cmake g++ pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3
project:cargo_build({
  root      = ".pax/repos/alacritty",
  verbosity = 1,
})
project:scdoc({
  input    = ".pax/repos/alacritty/extra/man/alacritty.1.scd",
  output   = "man1/alacritty.1",
  compress = false,
})
project:scdoc({
  input    = ".pax/repos/alacritty/extra/man/alacritty-msg.1.scd",
  output   = "man1/alacritty-msg.1",
  compress = false,
})
project:scdoc({
  input    = ".pax/repos/alacritty/extra/man/alacritty.5.scd",
  output   = "man5/alacritty.5",
  compress = false
})
project:scdoc({
  input    = ".pax/repos/alacritty/extra/man/alacritty-bindings.5.scd",
  output   = "man5/alacritty-bindings.5",
  compress = false
})

project:add_file(
-- govm
  {
    src  = ".pax/repos/govm/release/completion/bash/govm",
    dst  = "/usr/share/bash-completion/completions/govm",
    mode = pax.octal("0644"),
  },
  {
    src  = ".pax/repos/govm/release/completion/zsh/_govm",
    dst  = "/usr/share/zsh/vendor-completions/_govm",
    mode = pax.octal("0644"),
  },
  {
    src  = ".pax/repos/govm/release/completion/fish/govm.fish",
    dst  = "/usr/share/fish/vendor_completions.d/govm.fish",
    mode = pax.octal("0644"),
  },
  {
    src  = ".pax/repos/govm/release/man/",
    dst  = "/usr/share/man/man1/",
    mode = pax.octal("0644"),
  },
  -- dots
  {
    src  = ".pax/repos/dots/release/completion/bash/dots",
    dst  = "/usr/share/bash-completion/completions/dots",
    mode = pax.octal("0644"),
  },
  {
    src  = ".pax/repos/dots/release/completion/zsh/_dots",
    dst  = "/usr/share/zsh/vendor-completions/_dots",
    mode = pax.octal("0644"),
  },
  {
    src  = ".pax/repos/dots/release/completion/fish/dots.fish",
    dst  = "/usr/share/fish/vendor_completions.d/dots.fish",
    mode = pax.octal("0644"),
  },
  {
    src  = ".pax/repos/dots/release/man/",
    dst  = "/usr/share/man/man1/",
    mode = pax.octal("0644"),
  },
  -- eza
  {
    src  = ".pax/repos/eza/completions/bash/eza",
    dst  = "/usr/share/bash-completion/completions/eza",
    mode = pax.octal("0644"),
  },
  {
    src  = ".pax/repos/eza/completions/zsh/_eza",
    dst  = "/usr/share/zsh/vendor-completions/_eza",
    mode = pax.octal("0644"),
  },
  {
    src  = ".pax/repos/eza/completions/fish/eza.fish",
    dst  = "/usr/share/fish/vendor_completions.d/eza.fish",
    mode = pax.octal("0644"),
  },
  -- alacritty
  {
    src = ".pax/repos/alacritty/extra/completions/alacritty.bash",
    dst = "/usr/share/bash-completion/completions/alacritty",
    mode = pax.octal("0644"),
  },
  {
    src = ".pax/repos/alacritty/extra/completions/_alacritty",
    dst = "/usr/share/zsh/vendor-completions/_alacritty",
    mode = pax.octal("0644"),
  },
  {
    src = ".pax/repos/alacritty/extra/completions/alacritty.fish",
    dst = "/usr/share/fish/vendor_completions.d/alacritty.fish",
    mode = pax.octal("0644"),
  },
  {
    src = ".pax/repos/alacritty/extra/linux/Alacritty.desktop",
    dst = "/usr/share/applications/Alacritty.desktop",
    mode = pax.octal("0644"),
  },
  {
    src = ".pax/repos/alacritty/extra/linux/org.alacritty.Alacritty.appdata.xml",
    dst = "/usr/share/metainfo/org.alacritty.Alacritty.appdata.xml",
    mode = pax.octal("0644"),
  },
  {
    src = ".pax/repos/alacritty/extra/logo/alacritty-term.svg",
    dst = "/usr/share/pixmaps/Alacritty.svg",
    -- dst = "/usr/share/icons/hicolor/scalable/apps/Alacritty.svg",
    mode = pax.octal("0644"),
  },
  {
    src = ".pax/repos/alacritty/extra/logo/compat/alacritty-term.png",
    dst = "/usr/share/pixmaps/Alacritty.png",
    -- dst = "/usr/share/icons/hicolor/scalable/apps/Alacritty.png",
    mode = pax.octal("0644"),
  }
)

-- add ourselves
project:add_binary(pax.path.join(os.getenv("HOME"), ".cargo/bin/pax"))

project:finish()
