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
util.clone("git@github.com:antonmedv/fx.git", {
  depth = 1,
  branch = "35.0.0",
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
    "jq",

    -- alacritty deps
    --"libfontconfig1 (>= 2.12.6)",
    --"libfreetype6 (>= 2.8)",
    --"libgcc-s1 (>= 4.2)",
    --"libxcb1 (>= 1.11.1)",
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
project:download_yt_dlp({ release = "2025.01.15" })
project:download_mc()
util.download_kubeseal(project)

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
project:download_binary(
  "https://github.com/k3d-io/k3d/releases/download/v5.8.1/k3d-linux-amd64",
  "k3d"
)

-- nvm
project:download_binary(
  "https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh",
  "install-nvm.sh")

-- rust
project:download_binary("https://sh.rustup.rs", "install-rustup.sh")
project:download_binary(
"https://github.com/rust-lang/rust-analyzer/releases/download/2025-01-20/rust-analyzer-x86_64-unknown-linux-gnu.gz")

project:go_build({
  root     = "./.pax/repos/dots",
  generate = true,
})
project:go_build({
  root     = "./.pax/repos/govm",
  cmd      = "./cmd/govm",
  generate = true,
})
project:go_build({
  root     = ".pax/repos/fx",
  generate = false,
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
  util.bash_comp(".pax/repos/govm/release/completion/bash/govm"),
  util.zsh_comp(".pax/repos/govm/release/completion/zsh/_govm"),
  util.fish_comp(".pax/repos/govm/release/completion/fish/govm.fish"),
  {
    src  = ".pax/repos/govm/release/man/",
    dst  = "/usr/share/man/man1/",
    mode = pax.octal("0644"),
  },
  -- dots
  util.bash_comp(".pax/repos/dots/release/completion/bash/dots"),
  util.zsh_comp(".pax/repos/dots/release/completion/zsh/_dots"),
  util.fish_comp(".pax/repos/dots/release/completion/fish/dots.fish"),
  {
    src  = ".pax/repos/dots/release/man/",
    dst  = "/usr/share/man/man1/",
    mode = pax.octal("0644"),
  },
  -- eza
  util.bash_comp(".pax/repos/eza/completions/bash/eza"),
  util.zsh_comp(".pax/repos/eza/completions/zsh/_eza"),
  util.fish_comp(".pax/repos/eza/completions/fish/eza.fish"),
  -- alacritty
  util.bash_comp(".pax/repos/alacritty/extra/completions/alacritty.bash", "alacritty"),
  util.zsh_comp(".pax/repos/alacritty/extra/completions/_alacritty"),
  util.fish_comp(".pax/repos/alacritty/extra/completions/alacritty.fish"),
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
project:add_binary(pax.os.which("pax"))

project:finish()
