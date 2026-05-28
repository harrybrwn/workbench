local pax = require('pax')

local M = {}

---Add a man page file to the given project.
---@param src string file path of the man page (relative to the pax repos folder)
function M.manpage(src)
  local dstname = pax.path.basename(src)
  return {
    src = pax.path.join(".pax/repos", src),
    dst = pax.path.join("/usr/share/man/man1", dstname),
    mode = pax.octal("0644"),
  }
  -- project:add_file({
  --   src = pax.path.join(".pax/repos", src),
  --   dst = pax.path.join("/usr/share/man/man1", dstname),
  --   mode = pax.octal("0644"),
  -- })
end

---Put a list of filenames into the doc directory.
---@param name string
---@param filenames table<string> A list of filenames.
function M.doc_files(name, filenames)
  local files = {}
  for _, filename in pairs(filenames) do
    local base = pax.path.basename(filename)
    table.insert(files, {
      src = pax.path.join(".pax/repos", name, filename),
      dst = pax.path.join("/usr/share/doc", name, base),
      mode = pax.octal("0644"),
    })
  end
  return files
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
