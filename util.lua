local pax = require("pax")

local function basename(str)
	-- local name = string.gsub(str, "(.*/)(.*)", "%2")
	local name = pax.path.basename(str)
	if name == nil then
		return ""
	end
	return name
end

--- @param repo string
--- @param opts? pax.GitCloneOpts
--- @return pax.GitCloneOpts
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
	if not pax.fs.exists(man) and not pax.fs.exists(bash) and not pax.fs.exists(zsh) then
		-- pax.sh(table.concat({
		-- 	bin .. " --generate complete-bash > " .. bash,
		-- 	bin .. " --generate complete-zsh > " .. zsh,
		-- 	bin .. " --generate complete-fish > " .. fish,
		-- 	bin .. " --generate man > " .. man,
		-- }, "\n"))
		pax.os.exec(bin, { "--generate", "complete-bash" }, { stdout_file = bash })
		pax.os.exec(bin, { "--generate", "complete-zsh" }, { stdout_file = zsh })
		pax.os.exec(bin, { "--generate", "complete-fish" }, { stdout_file = fish })
		pax.os.exec(bin, { "--generate", "man" }, { stdout_file = man })
	end

	project:add_files(
		M.bash_comp(bash),
		M.zsh_comp(zsh),
		M.fish_comp(fish),
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
	project:add_file({
		src = dir .. "/",
		dst = "/usr/share/fonts/truetype",
		mode = pax.octal("0644"),
	})
end

function M.download_kubeseal(project, version)
	local v = version or "0.28.0"
	local url = "https://github.com/bitnami-labs/sealed-secrets/releases/download/v" ..
			v .. "/kubeseal-" .. v .. "-linux-amd64.tar.gz"
	local dir = pax.path.join(project:dir(), "kubeseal", v)
	pax.fs.mkdir_all(dir)
	pax.dl.fetch(url, { out = pax.path.join(dir, "kubeseal.tar.gz") })
	pax.os.exec(
		"tar",
		{
			"-C", pax.path.join(project:dir(), "bin/"),
			"-xvzf",
			pax.path.join(dir, "kubeseal.tar.gz"),
			"kubeseal"
		}
	)
	project:add_binary(pax.path.join(project:dir(), "bin", "kubeseal"))
end

function M.download_rust_analyzer(project)
	local v = "2025-01-20"
	local url =
			"https://github.com/rust-lang/rust-analyzer/releases/download/" ..
			v .. "/rust-analyzer-x86_64-unknown-linux-gnu.gz"
	local base = pax.path.basename(url);
	if base == nil then
		error("could not get basename")
	end
	local blob = pax.path.join(project:dir(), "bin", string.gsub(base, "%.gz", ""))
	pax.dl.fetch(url, { out = blob, compression = 1 })
	project:add_binary(pax.path.join(project:dir(), "bin", "rust-analyzer"))
end

function M.download_sccache(project)
	local v = "0.9.1"
	local url =
			"https://github.com/mozilla/sccache/releases/download/v" ..
			v .. "/sccache-v" .. v .. "-x86_64-unknown-linux-musl.tar.gz"
	local out = pax.path.join(project:dir(), "sccache.tar.gz")
	pax.dl.fetch(url, { out = out })
	local dst = "sccache-v" .. v .. "-x86_64-unknown-linux-musl/sccache"
	pax.os.exec("tar", { "-C", project:dir(), "-xzf", out, dst })
	project:add_binary(pax.path.join(project:dir(), dst))
end

local bash_comp_dir = "/usr/share/bash-completion/completions"
local zsh_comp_dir = "/usr/share/zsh/vendor-completions"
local fish_comp_dir = "/usr/share/fish/vendor_completions.d"

--- @param src string
--- @param dst string
--- @param dstname? string
--- @return pax.File
local function comp(src, dst, dstname)
	if dstname == nil then
		dstname = pax.path.basename(src)
	end
	return {
		src = src,
		dst = pax.path.join(dst, dstname),
		mode = pax.octal("0644"),
	}
end

--- @param path string
--- @param dstname? string
--- @return pax.File
function M.bash_comp(path, dstname) return comp(path, bash_comp_dir, dstname) end

--- @param path string
--- @param dstname? string
--- @return pax.File
function M.zsh_comp(path, dstname) return comp(path, zsh_comp_dir, dstname) end

--- @param path string
--- @param dstname? string
--- @return pax.File
function M.fish_comp(path, dstname) return comp(path, fish_comp_dir, dstname) end

return M
