local pax = require('pax')
local util = require('util')
local versions = require('versions')

local repos = {
  { repo = "git@github.com:harrybrwn/dots.git",                 branch = "main" },
  { repo = "git@github.com:harrybrwn/govm.git",                 branch = "main" },
  { repo = "git@github.com:BurntSushi/ripgrep.git",             branch = versions.rg,               dest = "rg" },
  { repo = "git@github.com:XAMPPRocky/tokei.git",               branch = "v" .. versions.tokei },
  { repo = "git@github.com:eza-community/eza.git",              branch = "v" .. versions.eza },
  { repo = "git@github.com:neovim/neovim.git",                  branch = 'v' .. versions.neovim },
  { repo = "git@github.com:alacritty/alacritty.git",            branch = "v" .. versions.alacritty },
  { repo = "git@github.com:antonmedv/fx.git",                   branch = versions.fx },
  { repo = "git@github.com:dandavison/delta.git",               branch = versions.delta },
  { repo = "git@github.com:cykerway/complete-alias.git",        branch = "master" },
  { repo = "git@github.com:Syllo/nvtop.git",                    branch = versions.nvtop },
  { repo = "https://codeberg.org/explosion-mental/wallust.git", branch = versions.wallust },
  { repo = "git@github.com:tree-sitter/tree-sitter.git",        branch = 'v' .. versions.treesitter },
  -- { repo = "git@github.com:sharkdp/hyperfine.git",              branch = versions.hyperfine },
  -- { repo = "git@github.com:sharkdp/fd.git",                     branch = "v" .. versions.fd },
}

for _, spec in pairs(repos) do
  spec.depth = 1
  spec.dest = util.clone_dest(spec)
  util.clone(spec)
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
  pax.log("building neovim")
  pax.sh [[ make CMAKE_BUILD_TYPE=Release ]]
  pax.in_dir("./build", function()
    pax.log("packaging neovim for debian")
    pax.sh("cpack -G DEB")
  end)
end)

-- local version = string.gsub(pax.git.version(), "^v", "")
local version = "0.0.1-alpha3"

local project = pax.project({
  package      = "workbench",
  version      = version,
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
    "shellcheck",
    "rsync",
    "htop",
    "btop",
    "sqlite3",
    "dnsutils", -- dig
    "fd-find",
    "hyperfine",
    -- alacritty deps
    "libfontconfig1 (>= 2.12.6)",
    "libfreetype6 (>= 2.8)",
    "libxcb1 (>= 1.11.1)",
    string.format("libc6 (>= %s)", require('misc.neovim').min_libc_version()),
  },

  provides     = {
    string.format("neovim (= %s)", versions.neovim),
    string.format("alacritty (= %s)", versions.alacritty),
    string.format("ripgrep (= %s)", versions.rg),
    string.format("eza (= %s)", versions.eza),
    string.format("k9s (= %s)", versions.k9s),
    string.format("tokei (= %s)", versions.tokei),
    string.format("kubectx (= %s)", versions.kubectx),
    string.format("nvtop (= %s)", versions.nvtop),
    string.format("wallust (= %s)", versions.wallust),
  },
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
    -- preinst  = util.readfile("scripts/maintainer/preinst"),
    postinst = util.readfile("scripts/maintainer/postinst"),
    postrm   = util.readfile("scripts/maintainer/postrm"),
  }
})

project:merge_deb("./.pax/repos/neovim/build/nvim-linux-x86_64.deb")
project:download_kubectl()
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
  string.format("https://github.com/derailed/k9s/releases/download/v%s/k9s_linux_amd64.deb", versions.k9s),
  { out = pax.path.join(project:dir(), "k9s.deb") })
project:merge_deb(pax.path.join(project:dir(), "k9s.deb"))
pax.log("downloading kubectx")
project:download_binary(
  string.format("https://github.com/ahmetb/kubectx/releases/download/v%s/kubectx", versions.kubectx))
project:download_binary(
  string.format("https://github.com/ahmetb/kubectx/releases/download/v%s/kubens", versions.kubectx))
pax.dl.fetch(
  string.format(
    "https://github.com/bootandy/dust/releases/download/v%s/du-dust_%s-1_amd64.deb",
    versions.dust, versions.dust),
  { out = pax.path.join(project:dir(), "tmp", "dust.deb") })
project:merge_deb(pax.path.join(project:dir(), "tmp", "dust.deb"))
-- k3d
project:download_binary(
  string.format("https://github.com/k3d-io/k3d/releases/download/v%s/k3d-linux-amd64", versions.k3d),
  "k3d")
-- uv (python) https://docs.astral.sh/uv/
--project:download_binary("https://astral.sh/uv/install.sh", "install-uv.sh")
util.add_fzf(project, versions.fzf)

project:go_build({ root = "./.pax/repos/dots", cmd = "./cmd/dots", generate = true })
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
project:cargo_build({ root = ".pax/repos/wallust" })
project:cargo_build({ root = ".pax/repos/tree-sitter", profile = "optimize" })

-- Alacritty
-- requires:
-- $ apt install cmake g++ pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3
project:cargo_build({ root = ".pax/repos/alacritty" })
require('misc.alacritty').add_files(".pax/repos/alacritty", project)

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
  -- wallust
  {
    src  = ".pax/repos/wallust/schema.json",
    dst  = "/usr/share/wallust/schema.json",
    mode = pax.octal("0644"),
  },
  {
    src  = ".pax/repos/wallust/wallust.toml",
    dst  = "/usr/share/wallust/wallust.toml",
    mode = pax.octal("0644"),
  },
  {
    src  = ".pax/repos/wallust/man",
    dst  = "/usr/share/man/man1/",
    mode = pax.octal("0644"),
  },
  util.bash_comp(".pax/repos/wallust/completions/wallust.bash", "wallust"),
  util.zsh_comp(".pax/repos/wallust/completions/_wallust"),
  util.bash_comp(".pax/repos/wallust/completions/wallust.fish"),
})

project:finish()
