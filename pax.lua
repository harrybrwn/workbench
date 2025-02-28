local pax = require('pax')
local util = require('util')

for _, spec in pairs({
  { repo = "git@github.com:harrybrwn/dots.git",          branch = "main" },
  { repo = "git@github.com:harrybrwn/govm.git",          branch = "main" },
  { repo = "git@github.com:BurntSushi/ripgrep.git",      branch = "14.1.1",  dest = "rg" },
  { repo = "git@github.com:XAMPPRocky/tokei.git",        branch = "v12.1.2" },
  { repo = "git@github.com:eza-community/eza.git",       branch = "v0.20.22" },
  { repo = "git@github.com:neovim/neovim.git",           branch = 'v0.10.4' },
  { repo = "git@github.com:alacritty/alacritty.git",     branch = "v0.15.1" },
  { repo = "git@github.com:antonmedv/fx.git",            branch = "35.0.0" },
  { repo = "git@github.com:dandavison/delta.git",        branch = "0.18.2" },
  { repo = "git@github.com:cykerway/complete-alias.git", branch = "master" },
}) do
  util.clone({
    repo   = spec.repo,
    depth  = 1,
    branch = spec.branch,
    dest   = spec.dest,
  })
end

-- TODO make sure the host has neovim's build dependancies
--
--  $ sudo apt install ninja-build gettext cmake curl build-essential
--
-- See BUILD.md
pax.in_dir("./.pax/repos/neovim", function()
  if pax.fs.exists("build/nvim-linux64.deb") then
    pax.log("neovim already built")
    return
  end
  pax.sh [[ make CMAKE_BUILD_TYPE=Release ]]
  pax.in_dir("./build", function()
    pax.log("building neovim")
    pax.sh("cpack -G DEB")
  end)
end)

local project = pax.project({
  package      = "workbench",
  version      = "0.0.1~alpha1",
  section      = "devel",
  author       = pax.git.username(),
  email        = "me@h3y.sh",
  arch         = "amd64",
  description  = "Harry's basic workbench tools.",
  homepage     = "https://github.com/harrybrwn/workbench",
  priority     = pax.Priority.Optional,
  dependencies = {
    "git",
    "curl",
    "tmux",
    "jq",
    "build-essential",
    "rsync",
    "htop",
    "dnsutils", -- dig
    -- alacritty deps
    "libfontconfig1 (>= 2.12.6)",
    "libfreetype6 (>= 2.8)",
    "libxcb1 (>= 1.11.1)",
    string.format("libc6 (>= %s)", util.libc()),
  },
  provides     = {
    "neovim (= 0.10.3)",
    "alacritty (= 0.15.0)"
  },
  conflicts    = { "golangci-lint" },
  suggests     = {
    "helm",
    "docker-ce",
    "docker-ce-cli",
    "containerd.io",
    "docker-buildx-plugin",
    "docker-compose-plugin",
  },
  files        = {
    { src = "pax.lua",   dst = "/usr/share/workbench/pax.lua",   mode = pax.octal("0644") },
    { src = "util.lua",  dst = "/usr/share/workbench/util.lua",  mode = pax.octal("0644") },
    { src = "mini.lua",  dst = "/usr/share/workbench/mini.lua",  mode = pax.octal("0644") },
    { src = "README.md", dst = "/usr/share/workbench/README.md", mode = pax.octal("0644") },
    {
      src = "./scripts/install-nvm.sh",
      dst = "/usr/local/bin/install-nvm",
      mode = pax.octal("0755"),
    },
    {
      src = "./scripts/install-rustup.sh",
      dst = "/usr/local/bin/install-rustup",
      mode = pax.octal("0755"),
    },
  },
  scripts      = {
    preinst = util.readfile("scripts/maintainer/preinst"),
    postrm  = util.readfile("scripts/maintainer/postrm"),
  }
})

project:merge_deb("./.pax/repos/neovim/build/nvim-linux-x86_64.deb")
project:download_kubectl()
project:download_yt_dlp({ release = "2025.02.19" })
project:download_mc()
util.download_sccache(project)
util.download_kubeseal(project)
util.download_fonts(project, {
  "RobotoMono",
  "LiberationMono",
  "FiraMono",
  "SourceCodePro",
})

-- k9s
pax.dl.fetch(
  "https://github.com/derailed/k9s/releases/download/v0.40.5/k9s_linux_amd64.deb",
  { out = pax.path.join(project:dir(), "k9s.deb") })
project:merge_deb(pax.path.join(project:dir(), "k9s.deb"))
util.add_golangci_lint(project, "1.64.5")
pax.log("downloading kubectx")
project:download_binary("https://github.com/ahmetb/kubectx/releases/download/v0.9.5/kubectx")
project:download_binary("https://github.com/ahmetb/kubectx/releases/download/v0.9.5/kubens")
pax.dl.fetch(
  "https://github.com/bootandy/dust/releases/download/v1.1.1/du-dust_1.1.1-1_amd64.deb",
  { out = pax.path.join(project:dir(), "tmp", "dust.deb") })
project:merge_deb(pax.path.join(project:dir(), "tmp", "dust.deb"))
-- k3d
project:download_binary(
  "https://github.com/k3d-io/k3d/releases/download/v5.8.3/k3d-linux-amd64",
  "k3d")
-- uv (python) https://docs.astral.sh/uv/
--project:download_binary("https://astral.sh/uv/install.sh", "install-uv.sh")
util.add_fzf(project, "0.60.2")

project:go_build({ root = "./.pax/repos/dots", generate = true })
project:go_build({ root = ".pax/repos/fx", generate = false })
project:go_build({
  root            = "./.pax/repos/govm",
  generate        = true,
  cmd             = "./cmd/govm",
  bin_access_mode = pax.octal("4755"), -- probably a security issue but oh well lol
})
project:cargo_build({ root = "./.pax/repos/rg", features = { "pcre2" } })
util.ripgrep_assets(project, ".pax/repos/rg") -- build and add completion/man
project:cargo_build({ root = ".pax/repos/tokei" })
project:cargo_build({ root = ".pax/repos/eza" })
project:cargo_build({ root = ".pax/repos/delta" })

-- requires:
-- $ apt install cmake g++ pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3
project:cargo_build({ root = ".pax/repos/alacritty" })
for _, o in pairs({
  { i = ".pax/repos/alacritty/extra/man/alacritty.1.scd",          o = "man1/alacritty.1" },
  { i = ".pax/repos/alacritty/extra/man/alacritty-msg.1.scd",      o = "man1/alacritty-msg.1" },
  { i = ".pax/repos/alacritty/extra/man/alacritty.5.scd",          o = "man5/alacritty.5" },
  { i = ".pax/repos/alacritty/extra/man/alacritty-bindings.5.scd", o = "man5/alacritty-bindings.5" },
}) do
  project:scdoc({ input = o.i, output = o.o })
end

-- add ourselves
util.add_pax(project)

project:add_files({
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
  },
  -- delta
  util.bash_comp(".pax/repos/delta/etc/completion/completion.bash", "delta"),
  util.zsh_comp(".pax/repos/delta/etc/completion/completion.zsh", "_delta"),
  util.fish_comp(".pax/repos/delta/etc/completion/completion.fish", "delta.fish"),
  -- complete-alias
  {
    src  = ".pax/repos/complete-alias/complete_alias",
    dst  = "/usr/share/complete-alias/complete_alias",
    mode = pax.octal("0644"),
  },
})

project:finish()
