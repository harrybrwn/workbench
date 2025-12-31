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
      src = pax.path.join(".pax/repos", name, filename)
      dst = pax.path.join("/usr/share/doc", name, base),
      mode = pax.octal("0644"),
    })
  end
  return files
end

return M
