local pax = require("pax")

local function basename(str)
  local name = string.gsub(str, "(.*/)(.*)", "%2")
  return name
end

local function cloneopts(repo, opts)
  if opts == nil then
    opts = {}
  end
  if opts.dest ~= nil then
    if not string.find(opts.dest, "^(%.?/?)(%.pax/repos)") then
      opts.dest = pax.path.join(".pax/repos", opts.dest)
    end
  else
    local name = string.gsub(basename(repo), ".git", "")
    opts.dest = pax.path.join(".pax/repos", name)
  end
  return opts
end

local M = {}

function M.ripgrep_assets(project, dir)
  local bin  = pax.path.join(dir, "target/release/rg")
  local bash = pax.path.join(dir, "deployment/deb/complete/rg.bash")
  local zsh  = pax.path.join(dir, "deployment/deb/complete/_rg")
  local fish = pax.path.join(dir, "deployment/deb/complete/rg.fish")
  local man  = pax.path.join(dir, "deployment/deb/rg.1")
  pax.fs.mkdir_all(pax.path.join(dir, "deployment/deb/complete"))
  -- pax.exec(bin, { "--generate", "complete-bash" })
  if not pax.fs.exists(man) and not pax.fs.exists(bash) and not pax.fs.exists(zsh) then
    pax.sh(table.concat({
      bin .. " --generate complete-bash > " .. bash,
      bin .. " --generate complete-zsh > " .. zsh,
      bin .. " --generate complete-fish > " .. fish,
      -- bin .. " --generate man > " .. man,
    }, "\n"))
    pax.os.exec(bin, { "--generate", "man" }, { stdout_file = man })
  end

  project:add_files(
    {
      src  = bash,
      dst  = "/usr/share/bash-completion/completions/rg",
      mode = pax.octal("0644"),
    },
    {
      src  = zsh,
      dst  = "/usr/share/zsh/vendor-completions/_rg",
      mode = pax.octal("0644"),
    },
    {
      src  = fish,
      dst  = "/usr/share/fish/vendor_completions.d/rg.fish",
      mode = pax.octal("0644"),
    },
    {
      src  = man,
      dst  = "/usr/share/man/man1/rg.1",
      mode = pax.octal("0644"),
    },
    {
      src  = pax.path.join(dir, "README.md"),
      dst  = "/usr/share/doc/ripgrep/README",
      mode = pax.octal("0644"),
    },
    {
      src  = pax.path.join(dir, "LICENSE-MIT"),
      dst  = "/usr/share/doc/ripgrep/LICENSE-MIT",
      mode = pax.octal("0644"),
    },
    {
      src  = pax.path.join(dir, "CHANGELOG.md"),
      dst  = "/usr/share/doc/ripgrep/CHANGELOG",
      mode = pax.octal("0644"),
    },
    {
      src  = pax.path.join(dir, "COPYING"),
      dst  = "/usr/share/doc/ripgrep/COPYING",
      mode = pax.octal("0644"),
    },
    {
      src  = pax.path.join(dir, "FAQ.md"),
      dst  = "/usr/share/doc/ripgrep/FAQ",
      mode = pax.octal("0644"),
    }
  )
end

function M.clone(repo, opts)
  local o = cloneopts(repo, opts)
  if pax.fs.exists(opts.dest) then
    return
  end
  pax.git.clone(repo, o)
end

function M.download_fonts(project, names)
  local dir = pax.path.join(project:dir(), "fonts")
  local tmp = pax.path.join(project:dir(), "fonts-tmp")
  for _, name in pairs(names) do
    pax.fs.mkdir_all(dir)
    pax.fs.mkdir_all(tmp)
    local zipfile = pax.path.join(tmp, name .. ".zip")
    if pax.fs.exists(zipfile) then
      goto continue
    end
    local url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/" .. name .. ".zip"
    pax.dl.fetch(url, { out = zipfile })
    pax.exec("unzip", { "-o", "-d", dir, zipfile })
    ::continue::
  end
  return dir
end

function M.test()
  local repo = "git@github.com:eza-community/eza.git"
  local opts = cloneopts(repo, {
    dest   = ".pax/repos/eeeza",
    depth  = 1,
    branch = "v0.20.18",
  })
  pax.print(opts)
  pax.print(cloneopts(repo))
  pax.print(cloneopts(repo, {
    -- dest = "./.pax/repos/easya",
    -- dest = ".pax/repos/easya",
    dest = "easy"
  }))
end

return M
